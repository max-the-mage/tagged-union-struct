const std = @import("std");
pub const pkgs = struct {
    pub const adma = std.build.Pkg{
        .name = "adma",
        .path = ".gyro\\adma-suirad-0.0.0-01c7275bd78a07b47744a764850397b2\\pkg\\src\\adma.zig",
    };

    pub fn addAllTo(artifact: *std.build.LibExeObjStep) void {
        @setEvalBranchQuota(1_000_000);
        inline for (std.meta.declarations(pkgs)) |decl| {
            if (decl.is_pub and decl.data == .Var) {
                artifact.addPackage(@field(pkgs, decl.name));
            }
        }
    }
};
