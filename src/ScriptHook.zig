//! ScriptHook Zig bindings
//!
//! Bindings for ScriptHookV (GTA V) and ScriptHookRDR2 (Red Dead Redemption 2).
//!
//! All public functions that interact with the ScriptHook DLL return errors instead of panicking,
//! allowing callers to handle failures gracefully.
//!
//! ## Thread Safety
//!
//! These bindings follow ScriptHook's threading model:
//! - Initialization is thread-safe (uses `std.once`)
//! - After initialization, functions should be called from the script thread only
//!   (this matches ScriptHook's requirement that natives be called from the script thread)

const std = @import("std");
const windows = std.os.windows;

const Types = @import("types.zig");

/// Errors that can occur during ScriptHook operations.
pub const Error = error{
    /// Failed to retrieve the module file name from the system.
    GetModuleFileNameFailed,
    /// Failed to convert a short path to a long path.
    GetLongPathNameFailed,
    /// The game executable is not recognized (must be GTA5, GTA5_Enhanced, or RDR2).
    UnsupportedGame,
    /// Failed to load the ScriptHook DLL (ScriptHookV.dll or ScriptHookRDR2.dll).
    DllLoadFailed,
    /// Failed to resolve a function from the ScriptHook DLL.
    FunctionResolutionFailed,
    /// Memory allocation failed.
    OutOfMemory,
};

const Game = enum {
    GTAV,
    RDR2,
};

inline fn getLibraryName(kind: Game) [:0]const u8 {
    return switch (kind) {
        .GTAV => "ScriptHookV.dll",
        .RDR2 => "ScriptHookRDR2.dll",
    };
}

/// Internal state for ScriptHook bindings.
/// Initialization is thread-safe via `std.once`.
/// Post-initialization access assumes single-threaded usage (script thread).
const State = struct {
    dll: ?std.DynLib = null,
    resolved: std.StringHashMap(windows.FARPROC) = .init(std.heap.page_allocator),
    game: ?Game = null,
    init_error: ?Error = null,
};

var state: State = .{};

fn doInit() void {
    const allocator = std.heap.page_allocator;

    const module_filename = getModulePathZ(allocator, null) catch {
        state.init_error = Error.GetModuleFileNameFailed;
        return;
    };
    defer allocator.free(module_filename);

    const module_name = std.fs.path.stem(module_filename);

    if (std.mem.eql(u8, module_name, "GTA5") or
        std.mem.eql(u8, module_name, "GTA5_Enhanced"))
    {
        state.game = .GTAV;
    } else if (std.mem.eql(u8, module_name, "RDR2")) {
        state.game = .RDR2;
    } else {
        state.init_error = Error.UnsupportedGame;
    }
}

var init_once = std.once(doInit);

fn ensureInitialized() Error!void {
    init_once.call();
    if (state.init_error) |err| return err;
}

fn resolve(comptime T: type, comptime name: [:0]const u8) Error!T {
    try ensureInitialized();

    if (state.dll == null) {
        const lib = getLibraryName(state.game.?);
        state.dll = std.DynLib.open(lib) catch {
            return Error.DllLoadFailed;
        };
    }

    if (state.resolved.get(name)) |func| {
        return @ptrCast(@constCast(func));
    }

    var lib = state.dll.?;
    if (lib.lookup(T, name)) |func| {
        state.resolved.put(name, @ptrCast(@constCast(func))) catch {
            return Error.OutOfMemory;
        };

        return func;
    }

    return Error.FunctionResolutionFailed;
}

// Texture

/// Creates a texture.
///
/// Returns internal texture ID, or an error if the function could not be resolved.
///
/// Texture deletion is performed automatically when game reloads scripts.\
/// Can be called only in the same thread as natives.
///
/// GTAV specific
pub fn createTexture(
    /// Full path to location of the texture file.
    filepath: [*:0]const u8,
) Error!c_int {
    const func = try resolve(
        *const fn ([*:0]const u8) callconv(.c) c_int,
        "?createTexture@@YAHPEBD@Z",
    );

    return func(filepath);
}

/// Draws a texture on screen.\
/// Can be called only in the same thread as natives.
///
/// Texture instance draw parameters are updated each time script performs corresponding call to `drawTexture()`
///
/// You should always check your textures layout for 16:9, 16:10 and 4:3 screen aspects,\
/// for ex. in 1280x720, 1440x900 and 1024x768 screen resolutions, use windowed mode for this
///
/// GTAV specific
pub fn drawTexture(
    /// Texture ID returned by `createTexture()`.
    id: c_int,
    /// The instance index. Each texture can have up to 64 different instances on screen at a time.
    index: c_int,
    /// Texture instance with low levels draw first.
    level: c_int,
    /// How long in milliseconds the texture instance should stay on screen.
    time: c_int,
    /// Width in screen space [0,1].
    size_x: f32,
    /// Height in screen space [0,1].
    size_y: f32,
    /// Center position in texture space [0,1].
    center_x: f32,
    /// Center position in texture space [0,1].
    center_y: f32,
    /// Position in screen space [0,1].
    pos_x: f32,
    /// Position in screen space [0,1].
    pos_y: f32,
    /// Normalized rotation [0,1].
    rotation: f32,
    /// Screen aspect ratio, used for size correction.
    scale_factor: f32,
    /// Red tint.
    r: f32,
    /// Green tint.
    g: f32,
    /// Blue tint.
    b: f32,
    /// Alpha value.
    a: f32,
) Error!void {
    const func = try resolve(
        *const fn (c_int, c_int, c_int, c_int, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) callconv(.c) void,
        "?drawTexture@@YAXHHHHMMMMMMMMMMMM@Z",
    );

    func(
        id,
        index,
        level,
        time,
        size_x,
        size_y,
        center_x,
        center_y,
        pos_x,
        pos_y,
        rotation,
        scale_factor,
        r,
        g,
        b,
        a,
    );
}

/// `IDXGISwapChain::Present` callback
///
/// Called right before the actual Present method call, render test calls don't trigger callbacks
///
/// When the game uses DX10 it actually uses DX11 with DX10 feature level
///
/// Remember that you can't call natives inside:\
/// `void OnPresent(IDXGISwapChain *swapChain);`
///
/// GTAV specific
pub const PresentCallback = ?*const fn (swap_chain: ?*anyopaque) callconv(.c) void;

/// Register `IDXGISwapChain::Present` callback\
/// Must be called on DLL attach
///
/// GTAV specific
pub fn presentCallbackRegister(
    /// Callback function pointer of type `PresentCallback`.
    callback: PresentCallback,
) Error!void {
    const func = try resolve(
        *const fn (PresentCallback) callconv(.c) void,
        "?presentCallbackRegister@@YAXP6AXPEAX@Z@Z",
    );

    func(callback);
}

/// Unregister `IDXGISwapChain::Present` callback\
/// Must be called on DLL detach
///
/// GTAV specific
pub fn presentCallbackUnregister(
    /// Callback function pointer of type `PresentCallback`.
    callback: PresentCallback,
) Error!void {
    const func = try resolve(
        *const fn (PresentCallback) callconv(.c) void,
        "?presentCallbackUnregister@@YAXP6AXPEAX@Z@Z",
    );

    func(callback);
}

// Keyboard

/// Keyboard handler callback function type.
pub const KeyboardHandler = ?*const fn (
    /// [MSDN: Virtual-Key Codes](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes)
    key: windows.DWORD,
    /// [MSDN: Repeat Count](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#repeat-count)
    repeats: windows.WORD,
    /// [MSDN: Scan Codes](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#scan-codes)
    scanCode: windows.BYTE,
    /// [MSDN: Extended-Key Flag](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#extended-key-flag)
    isExtended: windows.BOOL,
    /// [MSDN: Context Code](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#context-code)
    isWithAlt: windows.BOOL,
    /// [MSDN: Previous Key-State Flag](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#previous-key-state-flag)
    wasDownBefore: windows.BOOL,
    /// [MSDN: Transition-State Flag](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#transition-state-flag)
    isUpNow: windows.BOOL,
) callconv(.c) void;

/// Register keyboard handler\
/// Must be called on DLL attach
pub fn keyboardHandlerRegister(
    /// Callback function pointer of type `KeyboardHandler`.
    handler: KeyboardHandler,
) Error!void {
    const func = try resolve(
        *const fn (KeyboardHandler) callconv(.c) void,
        "?keyboardHandlerRegister@@YAXP6AXKGEHHHH@Z@Z",
    );

    func(handler);
}

/// Unregister keyboard handler\
/// Must be called on DLL detach
pub fn keyboardHandlerUnregister(
    /// Callback function pointer of type `KeyboardHandler`.
    handler: KeyboardHandler,
) Error!void {
    const func = try resolve(
        *const fn (KeyboardHandler) callconv(.c) void,
        "?keyboardHandlerUnregister@@YAXP6AXKGEHHHH@Z@Z",
    );

    func(handler);
}

// Scripts

/// Stops the current script execution for a specified amount of time.
pub fn scriptWait(
    /// The time in milliseconds to wait.
    time: windows.DWORD,
) Error!void {
    const func = try resolve(
        *const fn (windows.DWORD) callconv(.c) void,
        "?scriptWait@@YAXK@Z",
    );

    func(time);
}

/// Callback function type for the main script function.\
/// This function is called when the script is started by ScriptHook.
pub const ScriptMainCallback = ?*const fn () callconv(.c) void;

/// Registers a script module with ScriptHook.\
/// Should be called on DLL attach.
pub fn scriptRegister(
    /// This module handle.
    module: windows.HMODULE,
    /// Pointer to the main script function, which is called when the script is started.
    script_main: ScriptMainCallback,
) Error!void {
    const func = try resolve(
        *const fn (windows.HMODULE, ScriptMainCallback) callconv(.c) void,
        "?scriptRegister@@YAXPEAUHINSTANCE__@@P6AXXZ@Z",
    );

    func(module, script_main);
}

/// Registers a script module with ScriptHook.\
/// Should be called after `scriptRegister()` if you want to register an additional thread.
pub fn scriptRegisterAdditionalThread(
    /// This module handle.
    module: windows.HMODULE,
    /// Pointer to the main script function, which is called when the script is started.
    script_main: ScriptMainCallback,
) Error!void {
    const func = try resolve(
        *const fn (windows.HMODULE, ScriptMainCallback) callconv(.c) void,
        "?scriptRegisterAdditionalThread@@YAXPEAUHINSTANCE__@@P6AXXZ@Z",
    );

    func(module, script_main);
}

/// Unregisters a script module from ScriptHook.\
/// Should be called on DLL detach.
pub fn scriptUnregister(
    module: windows.HMODULE,
) Error!void {
    const func = try resolve(
        *const fn (windows.HMODULE) callconv(.c) void,
        "?scriptUnregister@@YAXPEAUHINSTANCE__@@@Z",
    );

    func(module);
}

/// Initializes the stack for a new script function call.
pub fn nativeInit(
    /// The function hash to call.
    hash: u64,
) Error!void {
    const func = try resolve(
        *const fn (u64) callconv(.c) void,
        "?nativeInit@@YAX_K@Z",
    );

    func(hash);
}

/// Pushes a function argument on the script function stack.
pub fn nativePush64(
    /// The argument value.
    val: u64,
) Error!void {
    const func = try resolve(
        *const fn (u64) callconv(.c) void,
        "?nativePush64@@YAX_K@Z",
    );

    func(val);
}

/// Executes the script function call.
///
/// Returns a pointer to the return value of the call.
pub fn nativeCall() Error!*u64 {
    const func = try resolve(
        *const fn () callconv(.c) *u64,
        "?nativeCall@@YAPEA_KXZ",
    );

    return func();
}

/// Alias for `scriptWait` function.
pub fn wait(
    /// The time in milliseconds to wait.
    time: windows.DWORD,
) Error!void {
    try scriptWait(time);
}

/// Alias for `scriptWait(0xFFFFFFFF)` function, which effectively waits indefinitely.
pub fn terminate() Error!void {
    try wait(0xFFFFFFFF);
}

/// Returns pointer to a global variable.\
/// IDs may differ between game versions.
pub fn getGlobalPtr(
    /// The variable ID to query.
    global_id: c_int,
) Error!?*u64 {
    const func = try resolve(
        *const fn (c_int) callconv(.c) ?*u64,
        "?getGlobalPtr@@YAPEA_KH@Z",
    );

    return func(global_id);
}

// World

/// Get vehicles from internal pools
///
/// Can be called only in the same thread as natives
///
/// Returns the count of vehicles filled in the array.
pub fn worldGetAllVehicles(
    /// Array to fill with vehicle indexes.
    arr: [*]Types.Vehicle,
    /// Size of the array.
    arr_size: c_int,
) Error!c_int {
    const func = try resolve(
        *const fn ([*]Types.Vehicle, c_int) callconv(.c) c_int,
        "?worldGetAllVehicles@@YAHPEAHH@Z",
    );

    return func(arr, arr_size);
}

/// Get peds from internal pools
///
/// Can be called only in the same thread as natives
///
/// Returns the count of peds filled in the array.
pub fn worldGetAllPeds(
    /// Array to fill with ped indexes.
    arr: [*]Types.Ped,
    /// Size of the array.
    arr_size: c_int,
) Error!c_int {
    const func = try resolve(
        *const fn ([*]Types.Ped, c_int) callconv(.c) c_int,
        "?worldGetAllPeds@@YAHPEAHH@Z",
    );

    return func(arr, arr_size);
}

/// Get objects from internal pools
///
/// Can be called only in the same thread as natives
///
/// Returns the count of objects filled in the array.
pub fn worldGetAllObjects(
    /// Array to fill with object indexes.
    arr: [*]Types.Object,
    /// Size of the array.
    arr_size: c_int,
) Error!c_int {
    const func = try resolve(
        *const fn ([*]Types.Object, c_int) callconv(.c) c_int,
        "?worldGetAllObjects@@YAHPEAHH@Z",
    );

    return func(arr, arr_size);
}

/// Get pickups from internal pools
///
/// Can be called only in the same thread as natives
///
/// Returns the count of pickups filled in the array.
pub fn worldGetAllPickups(
    /// Array to fill with pickup indexes.
    arr: [*]Types.Pickup,
    /// Size of the array.
    arr_size: c_int,
) Error!c_int {
    const func = try resolve(
        *const fn ([*]Types.Pickup, c_int) callconv(.c) c_int,
        "?worldGetAllPickups@@YAHPEAHH@Z",
    );

    return func(arr, arr_size);
}

// Misc

/// Returns a pointer to the base address of the script handle's object.
///
/// Object fields may differ between game versions.
pub fn getScriptHandleBaseAddress(
    /// The script handle to query.
    handle: c_int,
) Error![*c]windows.BYTE {
    const func = try resolve(
        *const fn (c_int) callconv(.c) [*c]windows.BYTE,
        "?getScriptHandleBaseAddress@@YAPEAEH@Z",
    );

    return func(handle);
}

/// Gets the game version enumeration value as specified by ScriptHookV/ScriptHookRDR2.
///
/// Returns an integer value that corresponds to the game version.
/// Cast to the appropriate game version enumeration type for GTAV or RDR2.
pub fn getGameVersion() Error!c_int {
    const func = try resolve(
        *const fn () callconv(.c) c_int,
        "?getGameVersion@@YA?AW4eGameVersion@@XZ",
    );

    return func();
}

pub const GameVersionGTAV = @import("gta5/version.zig").GameVersion;
pub const GameVersionRDR2 = @import("rdr2/version.zig").GameVersion;

/// Error returned when game version check fails.
pub const GameVersionError = error{
    /// The current game is not GTA V.
    NotGTAV,
    /// The current game is not RDR2.
    NotRDR2,
};

/// Gets the game version enumeration value as specified by ScriptHookV.
///
/// Returns an error if the game is not GTA V.
pub fn getGameVersionGTAV() (Error || GameVersionError)!GameVersionGTAV {
    try ensureInitialized();

    if (state.game != .GTAV) {
        return GameVersionError.NotGTAV;
    }

    return @enumFromInt(try getGameVersion());
}

/// Gets the game version enumeration value as specified by ScriptHookRDR2.
///
/// Returns an error if the game is not RDR2.
pub fn getGameVersionRDR2() (Error || GameVersionError)!GameVersionRDR2 {
    try ensureInitialized();

    if (state.game != .RDR2) {
        return GameVersionError.NotRDR2;
    }

    return @enumFromInt(try getGameVersion());
}

test "ScriptHook" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}

/// Errors that can occur during path resolution.
const PathError = error{
    /// Path exceeds maximum supported length.
    PathTooLong,
};

fn getModuleFileNameW(
    allocator: std.mem.Allocator,
    module: ?windows.HMODULE,
) (std.mem.Allocator.Error || std.posix.UnexpectedError || PathError)![:0]u16 {
    const INITIAL_BUFFER_SIZE = windows.MAX_PATH;
    const MAX_ITERATIONS = 7; // 260 (MAX_PATH) * 2^7 = 33,280 characters

    var buffer_size: usize = INITIAL_BUFFER_SIZE;
    var buffer: []u16 = try allocator.alloc(u16, buffer_size);
    errdefer allocator.free(buffer);

    for (1..MAX_ITERATIONS) |_| {
        const size = (try windows.GetModuleFileNameW(
            module,
            buffer.ptr,
            @intCast(buffer.len),
        )).len;
        if (size < buffer.len) {
            buffer = try allocator.realloc(buffer, size + 1); // +1 for sentinel
            return buffer[0..size :0];
        } else {
            buffer_size *= 2;
        }

        buffer = try allocator.realloc(buffer, buffer_size);
    }

    // Max Windows path length is 32,767 characters, we should not reach here
    allocator.free(buffer);
    return PathError.PathTooLong;
}

extern "kernel32" fn GetLongPathNameW(
    lpszShortPath: ?windows.LPCWSTR,
    lpszLongPath: ?windows.LPWSTR,
    cchBuffer: windows.DWORD,
) callconv(.winapi) windows.DWORD;

fn getLongPathNameW(
    allocator: std.mem.Allocator,
    path: [*:0]const u16,
) (std.mem.Allocator.Error || std.posix.UnexpectedError || PathError)![:0]u16 {
    const INITIAL_BUFFER_SIZE = windows.MAX_PATH;
    const MAX_ITERATIONS = 7; // 260 (MAX_PATH) * 2^7 = 33,280 characters

    var buffer_size: usize = INITIAL_BUFFER_SIZE;
    var buffer: []u16 = try allocator.alloc(u16, buffer_size);
    errdefer allocator.free(buffer);

    for (1..MAX_ITERATIONS) |_| {
        const size = GetLongPathNameW(
            path,
            @ptrCast(buffer.ptr),
            @intCast(buffer.len),
        );
        if (size == 0) {
            return windows.unexpectedError(windows.GetLastError());
        }
        if (size < buffer.len) {
            buffer = try allocator.realloc(buffer, size + 1); // +1 for sentinel
            return buffer[0..size :0];
        } else {
            buffer_size *= 2;
        }

        buffer = try allocator.realloc(buffer, buffer_size);
    }

    // Max Windows path length is 32,767 characters, we should not reach here
    allocator.free(buffer);
    return PathError.PathTooLong;
}

fn getModulePathW(
    allocator: std.mem.Allocator,
    module: ?windows.HMODULE,
) (std.mem.Allocator.Error || std.posix.UnexpectedError || PathError)![:0]const u16 {
    const full_path_wtf16 = try getModuleFileNameW(
        allocator,
        module,
    );
    defer allocator.free(full_path_wtf16);

    const resolved_path_wtf16 = try getLongPathNameW(
        allocator,
        full_path_wtf16,
    );

    return resolved_path_wtf16;
}

fn getModulePathZ(
    allocator: std.mem.Allocator,
    module: ?windows.HMODULE,
) (std.mem.Allocator.Error || std.posix.UnexpectedError || PathError)![:0]const u8 {
    const full_path_wtf16 = try getModulePathW(
        allocator,
        module,
    );
    defer allocator.free(full_path_wtf16);

    const full_path = try std.unicode.wtf16LeToWtf8AllocZ(
        allocator,
        full_path_wtf16,
    );

    return full_path;
}
