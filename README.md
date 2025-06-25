# ScriptHookZig

Zig wrapper for ScriptHookV/ScriptHookRDR2.

## Requirements

- Zig 0.14.0 or later

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
    const lib = b.addLibrary(.{ ... }); // Your library configuration

    // Add the ScriptHookZig dependency
    const script_hook_v = b.dependency(
        "ScriptHookZig", // As defined in your build.zig.zon
        .{
            .target = target,
            .optimize = optimize,
        },
    );

    // Add the import to your library
    lib.root_module.addImport(
        "ScriptHookZig", // The name you want to use in your Zig code
        script_hook_v.module("ScriptHookZig"), // As defined inside the module
    );
    // ...
```

### Usage in your Zig code

Importing:

```zig
const ScriptHookZig = @import("ScriptHookZig");
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
_ = ScriptHookZig.createTexture;             // GTA V only
_ = ScriptHookZig.drawTexture;               // GTA V only
_ = ScriptHookZig.PresentCallback;           // GTA V only
_ = ScriptHookZig.presentCallbackRegister;   // GTA V only
_ = ScriptHookZig.presentCallbackUnregister; // GTA V only
_ = ScriptHookZig.KeyboardHandler;
_ = ScriptHookZig.keyboardHandlerRegister;
_ = ScriptHookZig.keyboardHandlerUnregister;
_ = ScriptHookZig.scriptWait;
_ = ScriptHookZig.scriptRegister;
_ = ScriptHookZig.scriptRegisterAdditionalThread;
_ = ScriptHookZig.scriptUnregister;
_ = ScriptHookZig.nativeInit;
_ = ScriptHookZig.nativePush64;
_ = ScriptHookZig.nativeCall;
_ = ScriptHookZig.wait;
_ = ScriptHookZig.terminate;
_ = ScriptHookZig.getGlobalPtr;
_ = ScriptHookZig.worldGetAllVehicles;
_ = ScriptHookZig.worldGetAllPeds;
_ = ScriptHookZig.worldGetAllObjects;
_ = ScriptHookZig.worldGetAllPickups;
_ = ScriptHookZig.getScriptHandleBaseAddress;
_ = ScriptHookZig.getGameVersion;
_ = ScriptHookZig.getGameVersionGTAV;
_ = ScriptHookZig.getGameVersionRDR2;
```

</p>
</details>

## Acknowledgements

- Alexander Blade's [ScriptHookV](http://www.dev-c.com/gtav/scripthookv/)
- Alexander Blade's [ScriptHookRDR2](http://www.dev-c.com/gtav/scripthookrdr2/)

## Contributing

If you want to contribute to this project, feel free to open an issue or a pull request. Contributions are welcome!
