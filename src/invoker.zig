//! ScriptHook Invoker
//!
//! High-level wrapper for invoking native game functions.

const std = @import("std");

const ScriptHook = @import("ScriptHook.zig");

/// Errors that can occur during native function invocation.
pub const Error = ScriptHook.Error;

/// Pushes a value of type `T` onto the native argument stack.
pub inline fn push(
    /// Type of the argument to push
    comptime T: type,
    /// Value to push
    val: T,
) Error!void {
    var val64: u64 = 0;
    if (@sizeOf(T) > @sizeOf(u64)) {
        @compileError("type " ++ @typeName(T) ++ " is too large to be passed as a native argument");
    }
    @as(*T, @ptrCast(@alignCast(&val64))).* = val;
    try ScriptHook.nativePush64(val64);
}

/// Invokes a native function with the given hash and arguments.
///
/// Returns the result of the native function, or an error if the
/// ScriptHook DLL could not be loaded or a function could not be resolved.
pub inline fn invoke(
    /// Return type
    comptime R: type,
    /// Native function hash
    hash: u64,
    /// Arguments to pass to the native function
    args: anytype,
) Error!R {
    try ScriptHook.nativeInit(hash);

    const ArgsType = @TypeOf(args);
    const args_type_info = @typeInfo(ArgsType);
    if (args_type_info != .@"struct") {
        @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
    }

    const fields_info = args_type_info.@"struct".fields;
    inline for (fields_info) |field_info| {
        const field_name = field_info.name;
        const field = @field(args, field_name);
        try push(@TypeOf(field), field);
    }

    return @as(*R, @ptrCast(@alignCast(try ScriptHook.nativeCall()))).*;
}

test "invoker" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
