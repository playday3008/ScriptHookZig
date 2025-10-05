# ScriptHookZig

Zig wrapper for ScriptHookV/ScriptHookRDR2.

## Examples

- [GTAV Beast Hunt Helper](https://github.com/playday3008/GTAV-Beast-Hunt-Helper)

## Requirements

- Zig 0.15.1 or later

## Usage

### Fetch the module

This will add module entry to your `build.zig.zon` file:

```sh
zig fetch --save git+<THIS_REPO_URL>
```

### Setup in your Zig project

By editing your `build.zig` file, you can include the `ScriptHookZig` module as a dependency.\
Here is an example of how to do this:

```zig
/// build.zig
// ...
// Add the ScriptHookZig dependency
const script_hook_v = b.dependency(
    "ScriptHookZig", // As defined in your build.zig.zon
    .{
        .target = target,
        .optimize = optimize,
    },
);

const lib = b.addLibrary(.{// Your library configuration
    // ...
    .imports = &.{
        // ...
        // Add the import to your library
        .{
            .name = "ScriptHookZig",
            .module = script_hook_v.module("ScriptHookZig"),
        },
    },
}); 
// ...
```

### Usage in your Zig code

Importing:

```zig
const ScriptHookZig = @import("ScriptHookZig");
const Hook = ScriptHookZig.Hooks;
```

Using:

<details><summary>Types</summary>
<p>

```zig
_ = ScriptHookZig.Types.Void;
_ = ScriptHookZig.Types.Any;
_ = ScriptHookZig.Types.uint;
_ = ScriptHookZig.Types.Hash;
_ = ScriptHookZig.Types.Blip;
_ = ScriptHookZig.Types.Cam;
_ = ScriptHookZig.Types.Camera;
_ = ScriptHookZig.Types.CarGenerator;
_ = ScriptHookZig.Types.ColourIndex;
_ = ScriptHookZig.Types.CoverPoint;
_ = ScriptHookZig.Types.Entity;
_ = ScriptHookZig.Types.FireId;
_ = ScriptHookZig.Types.Group;
_ = ScriptHookZig.Types.Interior;
_ = ScriptHookZig.Types.ItemSet;
_ = ScriptHookZig.Types.Object;
_ = ScriptHookZig.Types.Ped;
_ = ScriptHookZig.Types.Pickup;
_ = ScriptHookZig.Types.Player;
_ = ScriptHookZig.Types.ScrHandle;
_ = ScriptHookZig.Types.Sphere;
_ = ScriptHookZig.Types.TaskSequence;
_ = ScriptHookZig.Types.Texture;
_ = ScriptHookZig.Types.TextureDict;
_ = ScriptHookZig.Types.Train;
_ = ScriptHookZig.Types.Vehicle;
_ = ScriptHookZig.Types.Weapon;
_ = ScriptHookZig.Types.Vector2;
_ = ScriptHookZig.Types.Vector3;
_ = ScriptHookZig.Types.Vector4;
```

</p>
</details>

<details><summary>Invoker</summary>
<p>

```zig
_ = ScriptHookZig.Invoker.push;
_ = ScriptHookZig.Invoker.invoke;
```

</p>
</details>

<details><summary>Joaat</summary>
<p>

```zig
_ = comptime ScriptHookZig.Joaat.atFinalizeHash;
_ = comptime ScriptHookZig.Joaat.atLiteralStringHashWithSalt;
_ = comptime ScriptHookZig.Joaat.atStringHashWithSalt;
_ = comptime ScriptHookZig.Joaat.atLiteralStringHash;
_ = comptime ScriptHookZig.Joaat.atStringHash;
```

</p>
</details>

<details><summary>Functions</summary>
<p>

```zig
_ = Hook.createTexture;             // GTA V only
_ = Hook.drawTexture;               // GTA V only
_ = Hook.PresentCallback;           // GTA V only
_ = Hook.presentCallbackRegister;   // GTA V only
_ = Hook.presentCallbackUnregister; // GTA V only
_ = Hook.KeyboardHandler;
_ = Hook.keyboardHandlerRegister;
_ = Hook.keyboardHandlerUnregister;
_ = Hook.scriptWait;
_ = Hook.scriptRegister;
_ = Hook.scriptRegisterAdditionalThread;
_ = Hook.scriptUnregister;
_ = Hook.nativeInit;
_ = Hook.nativePush64;
_ = Hook.nativeCall;
_ = Hook.wait;
_ = Hook.terminate;
_ = Hook.getGlobalPtr;
_ = Hook.worldGetAllVehicles;
_ = Hook.worldGetAllPeds;
_ = Hook.worldGetAllObjects;
_ = Hook.worldGetAllPickups;
_ = Hook.getScriptHandleBaseAddress;
_ = Hook.getGameVersion;
_ = Hook.getGameVersionGTAV;
_ = Hook.getGameVersionRDR2;
```

</p>
</details>

## Acknowledgements

- Alexander Blade's [ScriptHookV](http://www.dev-c.com/gtav/scripthookv/)
- Alexander Blade's [ScriptHookRDR2](http://www.dev-c.com/gtav/scripthookrdr2/)

## Contributing

If you want to contribute to this project, feel free to open an issue or a pull request. Contributions are welcome!
