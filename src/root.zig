//! Root of the ScriptHookZig library
//!
//! ## Usage
//!
//! ### Fetch the module
//!
//! This will add module entry to your `build.zig.zon` file:
//!
//! ```sh
//! zig fetch --save git+<THIS_REPO_URL>
//! ```
//!
//! ### Setup in your Zig project
//!
//! By editing your `build.zig` file, you can include the `ScriptHookZig` module as a dependency.\
//! Here is an example of how to do this:
//!
//! ```zig
//! /// build.zig
//! // ...
//! const lib = b.addLibrary(.{ ... }); // Your library configuration
//!
//! // Add the ScriptHookZig dependency
//! const script_hook_v = b.dependency(
//!     "ScriptHookZig", // As defined in your build.zig.zon
//!     .{
//!         .target = target,
//!         .optimize = optimize,
//!     },
//! );
//!
//! // Add the import to your library
//! lib.root_module.addImport(
//!     "ScriptHookZig", // The name you want to use in your Zig code
//!     script_hook_v.module("ScriptHookZig"), // As defined inside the module
//! );
//! // ...
//! ```
//!
//! ## Acknowledgements
//!
//! - Alexander Blade's [ScriptHookV](http://www.dev-c.com/gtav/scripthookv/)
//! - Alexander Blade's [ScriptHookRDR2](http://www.dev-c.com/gtav/scripthookrdr2/)

pub const Types = @import("types.zig");
pub const Invoker = @import("invoker.zig");
pub const Joaat = @import("joaat.zig");
pub const Hook = @import("ScriptHook.zig");

test "root" {
    const std = @import("std");
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
