//! Joaat (Jenkins' one-at-a-time) hash functions.
//!
//! Reference: http://burtleburtle.net/bob/hash/doobs.html

const std = @import("std");

fn validate(comptime T: type) void {
    if (!@inComptime()) {
        @compileError("This should be done at compile time");
    }

    if (@bitSizeOf(T) != 32 and @bitSizeOf(T) != 64) {
        @compileError("Unsupported hash size, must be 32 or 64 bits");
    }
}

/// Returns finalized hash value.
pub fn atFinalizeHash(
    /// Type of the hash.
    comptime T: type,
    /// Partial hash to finalize.
    comptime hash: T,
) T {
    comptime validate(T);

    comptime var result: T = hash;
    result +%= (result << 3);
    result ^= (result >> 11);
    result +%= (result << 15);

    return result;
}

/// Returns a hash of a literal string.
pub fn atLiteralStringHashWithSalt(
    /// Type of the hash.
    comptime T: type,
    /// Salt to use in the hash.
    comptime salt: T,
    /// String to hash.
    /// No preprocessing is done.
    comptime str: []const u8,
) T {
    comptime validate(T);

    comptime var hash: T = salt;

    @setEvalBranchQuota(1_000_000);
    inline for (str) |c| {
        if (c == 0) break;
        hash +%= c;
        hash +%= (hash << 10);
        hash ^= (hash >> 6);
    }

    return comptime atFinalizeHash(T, hash);
}

/// Returns a hash of a string.
pub fn atStringHashWithSalt(
    /// Type of the hash.
    comptime T: type,
    /// Salt to use in the hash.
    comptime salt: T,
    /// String to hash.
    /// Preprocessing is done:
    /// - All characters are converted to lowercase.
    /// - Backslashes are replaced with forward slashes.
    /// - If the string starts with a double quote:
    ///   - The first double quote is skipped.
    ///   - Hashing is done until the next double quote or end of the string.
    comptime str: []const u8,
) T {
    comptime validate(T);

    comptime var hash: T = salt;

    const quoted: bool = (str.len > 0 and str[0] == '"');

    @setEvalBranchQuota(1_000_000);
    inline for (str[(if (quoted) 1 else 0)..]) |c| {
        if (c == 0 or (quoted and c == '"')) break;

        comptime var cc = std.ascii.toLower(c);
        cc = if (cc == '\\') '/' else cc;

        hash +%= cc;
        hash +%= (hash << 10);
        hash ^= (hash >> 6);
    }

    return comptime atFinalizeHash(T, hash);
}

/// Returns a hash of a literal string.
pub fn atLiteralStringHash(
    /// Type of the hash.
    comptime T: type,
    /// String to hash.
    /// No preprocessing is done.
    comptime str: []const u8,
) T {
    comptime validate(T);

    return comptime atLiteralStringHashWithSalt(T, 0, str);
}

/// Returns a hash of a string.
pub fn atStringHash(
    /// Type of the hash.
    comptime T: type,
    /// String to hash.
    /// Preprocessing is done:
    /// - All characters are converted to lowercase.
    /// - Backslashes are replaced with forward slashes.
    /// - If the string starts with a double quote:
    ///   - The first double quote is skipped.
    ///   - Hashing is done until the next double quote or end of the string.
    comptime str: []const u8,
) T {
    comptime validate(T);

    return comptime atStringHashWithSalt(T, 0, str);
}

test atLiteralStringHash {
    const testing = std.testing;

    try testing.expect(0x00000000 == comptime atLiteralStringHash(u32, ""));
    try testing.expect(0x4A93AFF3 == comptime atLiteralStringHash(u32, "DAWG"));
    try testing.expect(0xDC085FA0 == comptime atLiteralStringHash(u32, "dawg"));
    try testing.expect(0xC90434DB == comptime atLiteralStringHash(u32, "DaWg"));
    try testing.expect(0x29B8DFB0 == comptime atLiteralStringHash(u32, "123"));
    try testing.expect(0x50CF2F5D == comptime atLiteralStringHash(u32, "1aW2"));
    try testing.expect(0x55D40D0D == comptime atLiteralStringHash(u32, "d12G"));
    try testing.expect(0x048FEB7D == comptime atLiteralStringHash(u32, "1a2g"));
    try testing.expect(0xB2AC2748 == comptime atLiteralStringHash(u32, "d1W2"));
    try testing.expect(0x6E4BD97E == comptime atLiteralStringHash(u32, "D_A_W_G"));
    try testing.expect(0x0C3E6064 == comptime atLiteralStringHash(u32, "_D_A_W_G_"));
    try testing.expect(0x6B2DB840 == comptime atLiteralStringHash(u32, "d/a/w/g"));
    try testing.expect(0x2F112FBB == comptime atLiteralStringHash(u32, "/d/a/w/g/"));
    try testing.expect(0x0F90E1E0 == comptime atLiteralStringHash(u32, "D\\a\\W\\g"));
    try testing.expect(0xAB9EA6C0 == comptime atLiteralStringHash(u32, "\\D\\a\\W\\g\\"));
    try testing.expect(0x6D495A89 == comptime atLiteralStringHash(u32, "\""));
    try testing.expect(0xFDDAD55A == comptime atLiteralStringHash(u32, "\"\""));
    try testing.expect(0xB91E4E22 == comptime atLiteralStringHash(u32, " \""));
    try testing.expect(0x99588C57 == comptime atLiteralStringHash(u32, "\" "));
    try testing.expect(0x12EA62CC == comptime atLiteralStringHash(u32, "\" \""));
    try testing.expect(0x1942C51A == comptime atLiteralStringHash(u32, "a\""));
    try testing.expect(0x7EC8D71C == comptime atLiteralStringHash(u32, "\"a"));
    try testing.expect(0xB7D775C8 == comptime atLiteralStringHash(u32, "a\"\""));
    try testing.expect(0x361DDB67 == comptime atLiteralStringHash(u32, "\"a\""));
    try testing.expect(0x25B2819C == comptime atLiteralStringHash(u32, "\"\"a"));
    try testing.expect(0xC29A9CB3 == comptime atLiteralStringHash(u32, "\\\""));
    try testing.expect(0xE12D9BF0 == comptime atLiteralStringHash(u32, "\"\\"));
    try testing.expect(0x9850F8D1 == comptime atLiteralStringHash(u32, "\\\"\""));
    try testing.expect(0xA7F6C1F3 == comptime atLiteralStringHash(u32, "\"\\\""));
    try testing.expect(0x7D90B157 == comptime atLiteralStringHash(u32, "\"\"\\"));
    try testing.expect(0x474D80BA == comptime atLiteralStringHash(u32, "\"\\\\"));
    try testing.expect(0x2C67F8B4 == comptime atLiteralStringHash(u32, "\\\\\""));
    try testing.expect(0x34B52ADF == comptime atLiteralStringHash(u32, "\\\\\"\\\\"));
    try testing.expect(0x4A8D0D02 == comptime atLiteralStringHash(u32, "\"abc\"def\""));
    try testing.expect(0x68D71EE7 == comptime atLiteralStringHash(u32, "abc\"def\""));
    try testing.expect(0x00000000 == comptime atLiteralStringHash(u32, "\x00\x01\x02\x03"));
    try testing.expect(0x4699DE71 == comptime atLiteralStringHash(u32, "\x02\x03\x01\x00"));
    try testing.expect(0x36E36DC6 == comptime atLiteralStringHash(u32, "\x03\x00\x02\x01"));

    try testing.expect(0x0000000000000000 == comptime atLiteralStringHash(u64, ""));
    try testing.expect(0x34273915D091DDF3 == comptime atLiteralStringHash(u64, "DAWG"));
    try testing.expect(0xC414713540F6DDA0 == comptime atLiteralStringHash(u64, "dawg"));
    try testing.expect(0x33EEAD2ABC11E2DB == comptime atLiteralStringHash(u64, "DaWg"));
    try testing.expect(0x0038346DD7D2DFB0 == comptime atLiteralStringHash(u64, "123"));
    try testing.expect(0xDD6842E843E4E75D == comptime atLiteralStringHash(u64, "1aW2"));
    try testing.expect(0xC35D8A2FDC7E2B0D == comptime atLiteralStringHash(u64, "d12G"));
    try testing.expect(0xDD685E3B089A037D == comptime atLiteralStringHash(u64, "1a2g"));
    try testing.expect(0xC35D900D53568148 == comptime atLiteralStringHash(u64, "d1W2"));
    try testing.expect(0x77B5FE4327BC7959 == comptime atLiteralStringHash(u64, "D_A_W_G"));
    try testing.expect(0x0872500FE8074179 == comptime atLiteralStringHash(u64, "_D_A_W_G_"));
    try testing.expect(0x33A82986ECDF8593 == comptime atLiteralStringHash(u64, "d/a/w/g"));
    try testing.expect(0xC7E8361C3A1E8BF0 == comptime atLiteralStringHash(u64, "/d/a/w/g/"));
    try testing.expect(0x07365FAC8C1000F3 == comptime atLiteralStringHash(u64, "D\\a\\W\\g"));
    try testing.expect(0x1B9CCAA5A9364BE9 == comptime atLiteralStringHash(u64, "\\D\\a\\W\\g\\"));
    try testing.expect(0x000000026D495A89 == comptime atLiteralStringHash(u64, "\""));
    try testing.expect(0x00000996FDDAD55A == comptime atLiteralStringHash(u64, "\"\""));
    try testing.expect(0x00000906B91E4E22 == comptime atLiteralStringHash(u64, " \""));
    try testing.expect(0x0000099699588C57 == comptime atLiteralStringHash(u64, "\" "));
    try testing.expect(0x0027047A39BE62CC == comptime atLiteralStringHash(u64, "\" \""));
    try testing.expect(0x00001B5B1942C51A == comptime atLiteralStringHash(u64, "a\""));
    try testing.expect(0x0000099D7EC8D71C == comptime atLiteralStringHash(u64, "\"a"));
    try testing.expect(0x006CE4C582BB75C8 == comptime atLiteralStringHash(u64, "a\"\""));
    try testing.expect(0x002711254F61DB67 == comptime atLiteralStringHash(u64, "\"a\""));
    try testing.expect(0x002706EA4E06819C == comptime atLiteralStringHash(u64, "\"\"a"));
    try testing.expect(0x00001A20C29A9CB3 == comptime atLiteralStringHash(u64, "\\\""));
    try testing.expect(0x0000099AE12D9BF0 == comptime atLiteralStringHash(u64, "\"\\"));
    try testing.expect(0x006807C10A4A78D1 == comptime atLiteralStringHash(u64, "\\\"\""));
    try testing.expect(0x002717EAD032C1F3 == comptime atLiteralStringHash(u64, "\"\\\""));
    try testing.expect(0x002706EAA5E4B157 == comptime atLiteralStringHash(u64, "\"\"\\"));
    try testing.expect(0x002717E86F9180BA == comptime atLiteralStringHash(u64, "\"\\\\"));
    try testing.expect(0x006937F52A9F78B4 == comptime atLiteralStringHash(u64, "\\\\\""));
    try testing.expect(0x00E2112312E0FEE7 == comptime atLiteralStringHash(u64, "\\\\\"\\\\"));
    try testing.expect(0xE3B50EA40A5EC800 == comptime atLiteralStringHash(u64, "\"abc\"def\""));
    try testing.expect(0xDD9988FF5D883453 == comptime atLiteralStringHash(u64, "abc\"def\""));
    try testing.expect(0x0000000000000000 == comptime atLiteralStringHash(u64, "\x00\x01\x02\x03"));
    try testing.expect(0x00024BF54719DE71 == comptime atLiteralStringHash(u64, "\x02\x03\x01\x00"));
    try testing.expect(0x0000000036E36DC6 == comptime atLiteralStringHash(u64, "\x03\x00\x02\x01"));
}

test atStringHash {
    const testing = std.testing;

    try testing.expect(0x00000000 == comptime atStringHash(u32, ""));
    try testing.expect(0xDC085FA0 == comptime atStringHash(u32, "DAWG"));
    try testing.expect(0xDC085FA0 == comptime atStringHash(u32, "dawg"));
    try testing.expect(0xDC085FA0 == comptime atStringHash(u32, "DaWg"));
    try testing.expect(0x29B8DFB0 == comptime atStringHash(u32, "123"));
    try testing.expect(0x0B0CFF96 == comptime atStringHash(u32, "1aW2"));
    try testing.expect(0x877AF062 == comptime atStringHash(u32, "d12G"));
    try testing.expect(0x048FEB7D == comptime atStringHash(u32, "1a2g"));
    try testing.expect(0xA59277C0 == comptime atStringHash(u32, "d1W2"));
    try testing.expect(0x2B627739 == comptime atStringHash(u32, "D_A_W_G"));
    try testing.expect(0x81806B65 == comptime atStringHash(u32, "_D_A_W_G_"));
    try testing.expect(0x6B2DB840 == comptime atStringHash(u32, "d/a/w/g"));
    try testing.expect(0x2F112FBB == comptime atStringHash(u32, "/d/a/w/g/"));
    try testing.expect(0x6B2DB840 == comptime atStringHash(u32, "D\\a\\W\\g"));
    try testing.expect(0x2F112FBB == comptime atStringHash(u32, "\\D\\a\\W\\g\\"));
    try testing.expect(0x00000000 == comptime atStringHash(u32, "\""));
    try testing.expect(0x00000000 == comptime atStringHash(u32, "\"\""));
    try testing.expect(0xB91E4E22 == comptime atStringHash(u32, " \""));
    try testing.expect(0x49DD93B2 == comptime atStringHash(u32, "\" "));
    try testing.expect(0x49DD93B2 == comptime atStringHash(u32, "\" \""));
    try testing.expect(0x1942C51A == comptime atStringHash(u32, "a\""));
    try testing.expect(0xCA2E9442 == comptime atStringHash(u32, "\"a"));
    try testing.expect(0xB7D775C8 == comptime atStringHash(u32, "a\"\""));
    try testing.expect(0xCA2E9442 == comptime atStringHash(u32, "\"a\""));
    try testing.expect(0x00000000 == comptime atStringHash(u32, "\"\"a"));
    try testing.expect(0x0DE56663 == comptime atStringHash(u32, "\\\""));
    try testing.expect(0x5A873501 == comptime atStringHash(u32, "\"\\"));
    try testing.expect(0x1C7132CD == comptime atStringHash(u32, "\\\"\""));
    try testing.expect(0x5A873501 == comptime atStringHash(u32, "\"\\\""));
    try testing.expect(0x00000000 == comptime atStringHash(u32, "\"\"\\"));
    try testing.expect(0x59EFFE87 == comptime atStringHash(u32, "\"\\\\"));
    try testing.expect(0x3CB6F900 == comptime atStringHash(u32, "\\\\\""));
    try testing.expect(0xAA4E1859 == comptime atStringHash(u32, "\\\\\"\\\\"));
    try testing.expect(0xED131F5B == comptime atStringHash(u32, "\"abc\"def\""));
    try testing.expect(0x68D71EE7 == comptime atStringHash(u32, "abc\"def\""));
    try testing.expect(0x00000000 == comptime atStringHash(u32, "\x00\x01\x02\x03"));
    try testing.expect(0x4699DE71 == comptime atStringHash(u32, "\x02\x03\x01\x00"));
    try testing.expect(0x36E36DC6 == comptime atStringHash(u32, "\x03\x00\x02\x01"));

    try testing.expect(0x0000000000000000 == comptime atStringHash(u64, ""));
    try testing.expect(0xC414713540F6DDA0 == comptime atStringHash(u64, "DAWG"));
    try testing.expect(0xC414713540F6DDA0 == comptime atStringHash(u64, "dawg"));
    try testing.expect(0xC414713540F6DDA0 == comptime atStringHash(u64, "DaWg"));
    try testing.expect(0x0038346DD7D2DFB0 == comptime atStringHash(u64, "123"));
    try testing.expect(0xDD685A339297A796 == comptime atStringHash(u64, "1aW2"));
    try testing.expect(0xC35D8A2DF224D662 == comptime atStringHash(u64, "d12G"));
    try testing.expect(0xDD685E3B089A037D == comptime atStringHash(u64, "1a2g"));
    try testing.expect(0xC35E72ED854F59C0 == comptime atStringHash(u64, "d1W2"));
    try testing.expect(0x820B49D5A9CE0091 == comptime atStringHash(u64, "D_A_W_G"));
    try testing.expect(0x73562E373C88C805 == comptime atStringHash(u64, "_D_A_W_G_"));
    try testing.expect(0x33A82986ECDF8593 == comptime atStringHash(u64, "d/a/w/g"));
    try testing.expect(0xC7E8361C3A1E8BF0 == comptime atStringHash(u64, "/d/a/w/g/"));
    try testing.expect(0x33A82986ECDF8593 == comptime atStringHash(u64, "D\\a\\W\\g"));
    try testing.expect(0xC7E8361C3A1E8BF0 == comptime atStringHash(u64, "\\D\\a\\W\\g\\"));
    try testing.expect(0x0000000000000000 == comptime atStringHash(u64, "\""));
    try testing.expect(0x0000000000000000 == comptime atStringHash(u64, "\"\""));
    try testing.expect(0x00000906B91E4E22 == comptime atStringHash(u64, " \""));
    try testing.expect(0x0000000249DD93B2 == comptime atStringHash(u64, "\" "));
    try testing.expect(0x0000000249DD93B2 == comptime atStringHash(u64, "\" \""));
    try testing.expect(0x00001B5B1942C51A == comptime atStringHash(u64, "a\""));
    try testing.expect(0x00000006CA2E9442 == comptime atStringHash(u64, "\"a"));
    try testing.expect(0x006CE4C582BB75C8 == comptime atStringHash(u64, "a\"\""));
    try testing.expect(0x00000006CA2E9442 == comptime atStringHash(u64, "\"a\""));
    try testing.expect(0x0000000000000000 == comptime atStringHash(u64, "\"\"a"));
    try testing.expect(0x00000D5A0DE56663 == comptime atStringHash(u64, "\\\""));
    try testing.expect(0x000000035A873501 == comptime atStringHash(u64, "\"\\"));
    try testing.expect(0x0035BDA993E2B2CD == comptime atStringHash(u64, "\\\"\""));
    try testing.expect(0x000000035A873501 == comptime atStringHash(u64, "\"\\\""));
    try testing.expect(0x0000000000000000 == comptime atStringHash(u64, "\"\"\\"));
    try testing.expect(0x00000D5659EFFE87 == comptime atStringHash(u64, "\"\\\\"));
    try testing.expect(0x0035BD0BB5C07900 == comptime atStringHash(u64, "\\\\\""));
    try testing.expect(0xD9C1E139D63B3FE1 == comptime atStringHash(u64, "\\\\\"\\\\"));
    try testing.expect(0x006CF406B6071F5B == comptime atStringHash(u64, "\"abc\"def\""));
    try testing.expect(0xDD9988FF5D883453 == comptime atStringHash(u64, "abc\"def\""));
    try testing.expect(0x0000000000000000 == comptime atStringHash(u64, "\x00\x01\x02\x03"));
    try testing.expect(0x00024BF54719DE71 == comptime atStringHash(u64, "\x02\x03\x01\x00"));
    try testing.expect(0x0000000036E36DC6 == comptime atStringHash(u64, "\x03\x00\x02\x01"));
}

test atLiteralStringHashWithSalt {
    const testing = std.testing;

    try testing.expect(0x144D9288 == comptime atLiteralStringHashWithSalt(u32, 0xDEADBEEF, "\\\\\"\\\\"));
    try testing.expect(0xB4A1EFAC == comptime atLiteralStringHashWithSalt(u32, 0xDEADBEEF, "\"abc\"def\""));
    try testing.expect(0xC78D5D7E == comptime atLiteralStringHashWithSalt(u32, 0xDEADBEEF, "abc\"def\""));
    try testing.expect(0x6E89B511 == comptime atLiteralStringHashWithSalt(u32, 0xDEADBEEF, "\x00\x01\x02\x03"));
    try testing.expect(0xC38CD734 == comptime atLiteralStringHashWithSalt(u32, 0xDEADBEEF, "\x03\x00\x02\x01"));

    try testing.expect(0x01EFCF7B8490297C == comptime atLiteralStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\\\\\"\\\\"));
    try testing.expect(0xAB30F824C6DFBE00 == comptime atLiteralStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\"abc\"def\""));
    try testing.expect(0x471D0585074B120B == comptime atLiteralStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "abc\"def\""));
    try testing.expect(0x7657DBFDC929B511 == comptime atLiteralStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\x00\x01\x02\x03"));
    try testing.expect(0x03B0EFFC59845734 == comptime atLiteralStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\x03\x00\x02\x01"));
}

test atStringHashWithSalt {
    const testing = std.testing;

    try testing.expect(0xEE2162D1 == comptime atStringHashWithSalt(u32, 0xDEADBEEF, "\\\\\"\\\\"));
    try testing.expect(0x6BC9DC0C == comptime atStringHashWithSalt(u32, 0xDEADBEEF, "\"abc\"def\""));
    try testing.expect(0xC78D5D7E == comptime atStringHashWithSalt(u32, 0xDEADBEEF, "abc\"def\""));
    try testing.expect(0x6E89B511 == comptime atStringHashWithSalt(u32, 0xDEADBEEF, "\x00\x01\x02\x03"));
    try testing.expect(0xC38CD734 == comptime atStringHashWithSalt(u32, 0xDEADBEEF, "\x03\x00\x02\x01"));

    try testing.expect(0x3C630FCDBEE1141C == comptime atStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\\\\\"\\\\"));
    try testing.expect(0x0FB1FE05C7ED9FF4 == comptime atStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\"abc\"def\""));
    try testing.expect(0x471D0585074B120B == comptime atStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "abc\"def\""));
    try testing.expect(0x7657DBFDC929B511 == comptime atStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\x00\x01\x02\x03"));
    try testing.expect(0x03B0EFFC59845734 == comptime atStringHashWithSalt(u64, 0xDEADC0DEDEADBEEF, "\x03\x00\x02\x01"));
}

test "joaat" {
    const testing = std.testing;

    testing.refAllDeclsRecursive(@This());
}
