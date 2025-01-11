const std = @import("std");
const File = std.fs.File;

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

fn handle_arg(path: []const u8, stderr: anytype, stat: *u8) void {
    if (!std.mem.endsWith(u8, path, ".wiki")) {
        stderr.print("error: {s}: not a vimwiki file\n", .{path}) catch {};
        stat.* = 1;
        return;
    }

    const cwd = std.fs.cwd();
    // TODO FINAL port to windows
    const is_absolute: bool = std.mem.startsWith(u8, path, "/");

    const src = blk: {
        const result = if (is_absolute) std.fs.openFileAbsolute(path, .{})
        else cwd.openFile(path, .{});

        break :blk result catch {
            stderr.print("error: {s}: no such file\n", .{path}) catch {};
            stat.* = 1;
            return;
        };
    };

    const dst = blk: {
        // TODO FINAL PORT
        const buffer_len = std.os.linux.NAME_MAX;

        const path_extless = path[0..path.len - 4];
        var dst_buffer: [buffer_len]u8 = undefined;
        _ = std.fmt.bufPrint(&dst_buffer, "{s}md", .{path_extless}) catch {
            stderr.print("error: {s}md could not create file", .{path_extless}) catch {};
            stat.* = 1;
            return;
        };
        const dst_path = dst_buffer[0..path.len - 2];

        const result = if (is_absolute) std.fs.createFileAbsolute(dst_path, .{})
        else cwd.createFile(dst_path, .{});

        break :blk result catch {
            stderr.print("error: {s}: could not create file\n", .{dst_path}) catch {};
            stat.* = 1;
            return;
        };
    };

    translate_file(&src, &dst, stderr, stat);
}

fn translate_file(src: *const File, dst: *const File, stderr: anytype, stat: *u8) void {
    _ = src;
    _ = dst;
    stderr.print("finally translating a file\n", .{}) catch {};
    stat.* = 1;
}
