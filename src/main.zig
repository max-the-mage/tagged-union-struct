const std = @import("std");

const ToyTypeTag = enum {
    Animal,
    BoardGame,
    Figure,
    Puzzle,
};

const ToyType = union(ToyTypeTag) {
    Animal: struct {
        const Size = enum {
            Small,
            Medium,
            Large,
        };

        size: Size,
        material: []const u8,
    },
    BoardGame: struct { min_players: u8, max_players: u8, designers: []const u8, },
    Figure: struct {
        const Class = enum {
            Action,
            Doll,
            Historic,
        };
        classification: Class,
    },
    Puzzle: struct {
        const Type = enum {
            Mechanical, Cryptic,
            Logic, Trivia, Riddle,
        };
        puzzle_type: Type,
    },
};

const Toy = struct {
    serial_number: [10]u8,
    name: []const u8,
    brand: []const u8,
    price: f32,
    stock: u32,
    minAge: u7,

    kind: ToyType,

    pub fn format(
        self: Toy,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s};{s};{s};{d:.2};{};{};", .{
            self.serial_number,
            self.name,
            self.brand,
            self.price,
            self.stock,
            self.minAge,
        });

        switch (self.kind) {
            .Animal => |*animal| {
                try writer.print("{s};{}", .{
                    animal.material,
                    @tagName(animal.size)[0],
                });
            },
            .BoardGame => |*board_game| {
                try writer.print("{}-{};{s}", .{
                    board_game.min_players,
                    board_game.max_players,
                    board_game.designers,
                });
            },
            .Figure => |*figure| {
                try writer.print("{c}", .{@tagName(figure.classification)[0]});
            },
            .Puzzle => |*puzzle| {
                try writer.print("{c}", .{@tagName(puzzle.puzzle_type)[0]});
            },
        }
    }
};



fn getSNType(sn: [10]u8) error{InvalidSN}!ToyTypeTag {
    switch(sn[0]) {
        '0', '1' => return ToyTypeTag.Figure,
        '2', '3' => return ToyTypeTag.Animal,
        '4', '5', '6', => return ToyTypeTag.Puzzle,
        '7', '8', '9', => return ToyTypeTag.BoardGame,
        else => return error.InvalidSN,
    }
}

pub fn main() !void {
    var thing = Toy{
        .serial_number = "9999999999",
        .name = "fucky",
        .brand = "wucky",
        .price = 420.69,
        .stock = 666,
        .minAge = 2,
        .kind = ToyType{ .Animal = .{
            .material = "glass",
            .size = .Small,

        }},
    };

    var board_game = Toy{
        .serial_number = "7897897891",
        .name = "gay shit",
        .brand = "big gay inc.",
        .price = 34.99,
        .stock = 13,
        .minAge = 17,
        .kind = ToyType{ .BoardGame = .{
            .min_players = 2,
            .max_players = 6,
            .designers = "Maximum Overdrive Jacobs"
        }}
    };

    std.debug.print("Toy: {}\n", .{thing});
    std.debug.print("\n\n{}\n\n", .{board_game});
}
