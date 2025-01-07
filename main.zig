const std = @import("std");

const FileInfo = struct {
    name: []const u8,
    dir: std.fs.Dir
};

pub fn main() u8 {
    const stderr = std.io.getStdErr().writer();
    var stat: u8 = 0;

    var args = std.process.args();
    defer args.deinit();
    _ = args.skip();

    if (args.next()) |arg| handle_arg(arg, stderr, &stat)
    else {
        stderr.print(
            \\wiki2md – translate Vimwiki files to Markdown
            \\
            \\Usage: wiki2md <source files>
            \\
            , .{}
        ) catch {};
        return 1;
    }

    while (args.next()) |arg| handle_arg(arg, stderr, &stat);

    return stat;
}

fn handle_arg(filename: []const u8, stderr: anytype, stat: *u8) void {
    if (!std.mem.endsWith(u8, filename, ".wiki")) {
        stderr.print("error: {s}: not a vimwiki file\n", .{filename}) catch {};
        stat.* = 1;
        return;
    }

    var file: FileInfo = undefined;

    // TODO FINAL port to windows
    file.dir = if (std.mem.startsWith(u8, filename, "/"))
        std.fs.openDirAbsolute(filename[0..filename.len - ], .{});
    else std.fs.cwd().openDir(filename, .{})
    catch {
        stderr.print("error: {s}: no such file\n", .{filename}) catch {};
        stat.* = 1;
        return;
    };
    
    translate_file(&file, )

    if (std.mem.startsWith(u8, filename, "/")) {
        const file = std.fs.openFileAbsolute(filename, .{}) catch {
            stderr.print("error: {s}: no such file\n", .{filename}) catch {};
            stat.* = 1;
            return;
        };
        translate_file(&file, filename, stat);
    } else {
        const file = std.fs.cwd().openFile(filename, .{}) catch {
            stderr.print("error: {s}: no such file\n", .{filename}) catch {};
            stat.* = 1;
            return;
        };
        translate_file(&file, filename, stat);
    }
}

fn translate_file(file: *const std.fs.File, name: []const u8, stat: *u8) void {
    const filename_extless = name[0..name.len - 5];

    try 

    std.debug.print("this is the extless name: {s}\n", .{filename_extless});
    _ = file.stat() catch return;
    stat.* = 1;
    // TODO PLAN
    // try creating <file without extension>.md
}
