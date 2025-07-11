//! Types used by ScriptHook

const std = @import("std");
const w = std.os.windows;

pub const Void = w.DWORD;
pub const Any = w.DWORD;
pub const uint = w.DWORD;
pub const Hash = w.DWORD;

pub const Blip = c_int;
pub const Cam = c_int;
pub const Camera = c_int;
pub const CarGenerator = c_int;
pub const ColourIndex = c_int;
pub const CoverPoint = c_int;
pub const Entity = c_int;
pub const FireId = c_int;
pub const Group = c_int;
pub const Interior = c_int;
pub const ItemSet = c_int;
pub const Object = c_int;
pub const Ped = c_int;
pub const Pickup = c_int;
pub const Player = c_int;
pub const ScrHandle = c_int;
pub const Sphere = c_int;
pub const TaskSequence = c_int;
pub const Texture = c_int;
pub const TextureDict = c_int;
pub const Train = c_int;
pub const Vehicle = c_int;
pub const Weapon = c_int;

pub const Vector2 = extern struct {
    x: f32,
    _x: u32 = 0, // Padding
    y: f32,
    _y: u32 = 0, // Padding

    comptime {
        const expected_size = 2 * @sizeOf(u64);
        validateSize(@This(), expected_size);
    }
};
pub const Vector3 = extern struct {
    x: f32,
    _x: u32 = 0, // Padding
    y: f32,
    _y: u32 = 0, // Padding
    z: f32,
    _z: u32 = 0, // Padding

    comptime {
        const expected_size = 3 * @sizeOf(u64);
        validateSize(@This(), expected_size);
    }
};
pub const Vector4 = extern struct {
    x: f32,
    _x: u32 = 0, // Padding
    y: f32,
    _y: u32 = 0, // Padding
    z: f32,
    _z: u32 = 0, // Padding
    w: f32,
    _w: u32 = 0, // Padding

    comptime {
        const expected_size = 4 * @sizeOf(u64);
        validateSize(@This(), expected_size);
    }
};

fn validateSize(comptime T: type, comptime expected_size: u32) void {
    if (@sizeOf(T) != expected_size) {
        @compileError(std.fmt.comptimePrint(
            "Size of {s} isn't 0x{X}, it's 0x{X}",
            .{
                @typeName(T),
                expected_size,
                @sizeOf(T),
            },
        ));
    }
}

test "Types" {
    _ = Void;
    _ = Any;
    _ = uint;
    _ = Hash;

    _ = Blip;
    _ = Cam;
    _ = Camera;
    _ = CarGenerator;
    _ = ColourIndex;
    _ = CoverPoint;
    _ = Entity;
    _ = FireId;
    _ = Group;
    _ = Interior;
    _ = Object;
    _ = Ped;
    _ = Pickup;
    _ = Player;
    _ = ScrHandle;
    _ = Sphere;
    _ = TaskSequence;
    _ = Texture;
    _ = TextureDict;
    _ = Train;
    _ = Vehicle;
    _ = Weapon;

    _ = Vector2;
    _ = Vector3;
    _ = Vector4;
}
