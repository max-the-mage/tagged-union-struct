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
    serial_number: []const u8,
    name: []const u8,
    brand: []const u8,
    price: f32,
    stock: u32,
    min_age: u7,

    kind: ToyType,

    pub fn format(
        self: Toy,
        comptime fmt: []const u8,
        options: anytype,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        try writer.print("{s};{s};{s};{d:.2};{};{};", .{
            self.serial_number,
            self.name,
            self.brand,
            self.price,
            self.stock,
            self.min_age,
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



fn getSNType(sn: []const u8) error{InvalidSN}!ToyTypeTag {
    if(sn.len != 10) return error.InvalidSN;
    switch(sn[0]) {
        '0', '1' => return ToyTypeTag.Figure,
        '2', '3' => return ToyTypeTag.Animal,
        '4', '5', '6', => return ToyTypeTag.Puzzle,
        '7', '8', '9', => return ToyTypeTag.BoardGame,
        else => return error.InvalidSN,
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .never_unmap = true,
        .retain_metadata = true,
        .verbose_log = true,
    }){};

    const allocator = gpa.allocator();

    const file_content = try allocFileContents("toys.txt", allocator);
    defer allocator.free(file_content);

    var toys = try getToysFromFile(file_content, allocator);
    defer toys.deinit();

    for (toys.items) |toy| {
        std.debug.print("toy: {s}\n", .{toy});
    }
}

/// Caller owns memory.
fn allocFileContents(filename: []const u8, ac: std.mem.Allocator) ![]u8 {
    const f = try std.fs.cwd().openFile(
        filename,
        .{ .mode = .read_only},
    );
    defer f.close();
    
    return try f.readToEndAlloc(ac, (try f.stat()).size);
}

fn getToysFromFile(file_content: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Toy) {

    var toy_list = std.ArrayList(Toy).init(allocator);

    var iter = std.mem.split(u8, file_content, "\n");
    while (iter.next()) |line| {
        var toy_iter = std.mem.split(u8, line, ";");
        
        var sn = toy_iter.next().?;
        var name = toy_iter.next().?;
        var brand = toy_iter.next().?;
        var price = toy_iter.next().?;
        var stock = toy_iter.next().?;
        var min_age = toy_iter.next().?;

        const toy_type: ToyType = switch (try getSNType(sn)) {
            .Figure => ToyType{ .Figure = .{
                .classification = switch (toy_iter.next().?[0]) {
                    'A' => .Action,
                    'D' => .Doll,
                    'H' => .Historic,
                    else => return error.InvalidFigureClass,
                }},
            },
            .Animal => ToyType{ .Animal = .{
                .material = toy_iter.next().?,
                .size = switch (toy_iter.next().?[0]) {
                    'S' => .Small,
                    'M' => .Medium,
                    'L' => .Large,
                    else => return error.InvalidAnimalSize,
                },
            }},
            .Puzzle => ToyType{ .Puzzle = .{
                .puzzle_type = switch (toy_iter.next().?[0]) {
                    'M' => .Mechanical,
                    'C' => .Cryptic,
                    'L' => .Logic,
                    'T' => .Trivia,
                    'R' => .Riddle,
                    else => return error.InvalidPuzzleType,
                }
            }},
            .BoardGame => blk: {
                var players = std.mem.split(u8, toy_iter.next().?, "-");

                break :blk ToyType{ .BoardGame = .{
                    .min_players = try std.fmt.parseUnsigned(u8, players.next().?, 0),
                    .max_players = try std.fmt.parseUnsigned(u8, players.next().?, 0),
                    .designers = toy_iter.next().?,
                }};
            },
        };

        const new_toy = Toy {
            .serial_number = sn,
            .name = name,
            .brand = brand,
            .price = try std.fmt.parseFloat(f32, price),
            .stock = try std.fmt.parseUnsigned(u32, stock, 0),
            .min_age = try std.fmt.parseUnsigned(u7, min_age, 0),
            .kind = toy_type,
        };

        try toy_list.append(new_toy);
    }

    return toy_list;
}
