//! Supported by ScriptHookRDR2 game versions
// Keep in sync with: .github/workflows/check-update.yml

pub const GameVersion = enum(c_int) {
    VER_AUTO,

    VER_1_0_1207_60,
    VER_1_0_1207_69,
    VER_1_0_1207_73,
    VER_1_0_1207_77,
    VER_1_0_1207_80,
    VER_1_0_1232_13,
    VER_1_0_1232_17,
    VER_1_0_1311_12,
    VER_1_0_1436_25,
    VER_1_0_1436_31,
    VER_1_0_1491_16,
    VER_1_0_1491_17,

    VER_UNKNOWN = -1,
    _,
};

test GameVersion {
    _ = GameVersion;
}
