const std = @import("std");
const adma = @import("adma");

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
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
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
    const adma_ref = adma.AdmaAllocator.init();
    defer adma_ref.deinit();

    const allocator = &adma_ref.allocator;

    var toys = try getToysFromFile("toys.txt", allocator);
    defer toys.deinit();

    for (toys.items) |toy| {
        std.log.info("toy: {s}", .{toy});
    }

    // std.log.info("{s}", .{toys});
}

fn getToysFromFile(filename: []const u8, allocator: *std.mem.Allocator) !*std.ArrayList(Toy) {
    const toy_file = try std.fs.cwd().openFile(
        filename,
        .{ .read = true },
    );
    defer toy_file.close();
    
    const file_content = try toy_file.readToEndAlloc(allocator, (try toy_file.stat()).size);
    // TODO: figure out how I can free the file content without causing a use after free
    // defer allocator.free(file_content);

    var toy_list = std.ArrayList(Toy).init(allocator);

    var iter: std.mem.SplitIterator = std.mem.split(file_content, "\n");
    while (iter.next()) |line| {
        var toy_iter = std.mem.split(line, ";");
        
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
                var players = std.mem.split(toy_iter.next().?, "-");

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

    return &toy_list;
}
