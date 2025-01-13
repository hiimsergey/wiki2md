const std = @import("std");
const builtin = @import("builtin");
const transpilation = @import("src/transpilation.zig");

const Dir = std.fs.Dir;
const File = std.fs.File;

const NORMAL: []const u8 = "\x1b[0m";
const RED: []const u8 = "\x1b[31m";
const GREEN: []const u8 = "\x1b[32m";
const CYAN: []const u8 = "\x1b[36m";

const NAME_MAX = switch(builtin.os.tag) {
    .windows => std.os.windows.NAME_MAX,
    else => std.os.linux.NAME_MAX // what could go wrong?
};


/// TODO COMMENT
fn mkdir(dir: *Dir, dir_basename: []const u8, stderr: anytype) Dir.MakeError!void {
    dir.makeDir(dir_basename) catch |err| {
        if (err == Dir.MakeError.PathAlreadyExists) return;
        const errmsg = switch (err) {
            Dir.MakeError.AccessDenied => "access denied",
            Dir.MakeError.NoSpaceLeft => "no space left in memory",
            else => "could not make directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, dir_basename, errmsg}) catch {};
        return err;
    };
}

/// TODO COMMENT
fn get_output_dir(dir_path: []const u8, cwd: *Dir, stderr: anytype) (Dir.MakeError || Dir.OpenError)!Dir {
    return cwd.openDir(dir_path, .{}) catch |err| {
        if (err == Dir.OpenError.FileNotFound) {
            try mkdir(cwd, dir_path, stderr);
            return get_output_dir(dir_path, cwd, stderr);
        }

        const errmsg = switch (err) {
            Dir.OpenError.AccessDenied => "access denied",
            Dir.OpenError.FileNotFound => "no such directory",
            Dir.OpenError.NotDir => "not a directory",
            else => "could not open directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, dir_path, errmsg}) catch {};
        return err;
    };
}

/// TODO COMMENT
fn get_output_file(file_basename: []const u8, out_dir: *Dir, stderr: anytype) File.OpenError!File {
    var out_file_buffer: [NAME_MAX]u8 = undefined;
    std.mem.copyForwards(u8, &out_file_buffer, file_basename[0..file_basename.len - 4]);
    std.mem.copyForwards(u8, out_file_buffer[file_basename.len - 4..file_basename.len - 2], "md");
    const out_file_basename = out_file_buffer[0..file_basename.len - 2];

    const result = out_dir.createFile(out_file_basename, .{}) catch |err| {
        const errmsg = switch (err) {
            File.OpenError.NoSpaceLeft => "no space left in memory",
            File.OpenError.PathAlreadyExists => "already exists",
            else => "could not create file"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, out_file_basename, errmsg})
        catch {};
        return err;
    };
    return result;
}

// TODO CONSIDER not using a separate function for that
/// TODO COMMENT
fn get_input_file(file_path: []const u8, cwd: *Dir, stderr: anytype) File.OpenError!File {
    return cwd.openFile(file_path, .{}) catch |err| {
        stderr.print("{s}error{s}: {s}: could not open", .{RED, NORMAL, file_path}) catch {};
        return err;
    };
}

const ReadArgError = Dir.StatFileError || File.OpenError || Dir.MakeError;

/// TODO COMMENT
/// TODO NOW in order to read dir subargs, i think i need to pass cwd
/// (keep in mind that closing cwd can lead to a race condition)
/// so you store the old cwd in main() or something and when recursing advancing
fn read_arg(path: []const u8, cwd: *Dir, out_dir: *Dir, stderr: anytype) ReadArgError!void {
    const path_stat: File.Stat = cwd.statFile(path) catch |err| {
        const errmsg = switch (err) {
            Dir.StatFileError.AccessDenied => "access denied for stat",
            Dir.StatFileError.FileTooBig => "file too large for stat",
            Dir.StatFileError.NoSpaceLeft => "no space left to open for stat",
            Dir.StatFileError.FileNotFound => "no such file",
            else => "could not open for stat"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, path, errmsg}) catch {};
        return err;
    };

    if (path_stat.kind == File.Kind.file) {
        if (!std.mem.endsWith(u8, path, ".wiki")) {
            stderr.print("{s}error{s}: {s}: not a vimwiki file\n", .{RED, NORMAL, path}) catch {};
            // Not an accurate error value but it doesn't matter since I show error through
            // exit codes.
            // TODO return File.OpenError.BadPathName;
            return File.StatError.Unexpected;
        }

        var file: File = try get_input_file(path, cwd, stderr);
        defer file.close();

        const basename = std.fs.path.basename(path);
        var out_file: File = try get_output_file(basename, out_dir, stderr);
        defer out_file.close();

        try transpilation.transpile_file(&file, &out_file, stderr);
    } else {
        const basename = std.fs.path.basename(path);
        try mkdir(out_dir, basename, stderr);

        var out_subdir: Dir = out_dir.openDir(basename, .{}) catch |err| {
            stderr.print(
                "{s}error{s}: {s}: could not open directory, despite just making it :/\n",
                .{RED, NORMAL, path}
            ) catch {};
            return err;
        };
        defer out_subdir.close();

        // TODO NOW here
        var dir: Dir = cwd.openDir(path, .{ .iterate = true }) catch |err| {
            stderr.print(
                "TODO: {s}error{s}: {s}: could not open directory, but too lazy to write errmsg :/\n",
                .{RED, NORMAL, path}
            ) catch {};
            return err;
        };
        defer dir.close();

        var dir_it: Dir.Iterator = dir.iterate();
        var result: ?ReadArgError = null;
        while (try dir_it.next()) |entry| read_arg(entry.name, &dir, &out_subdir, stderr)
        catch |err| { result = err; };
        return result orelse {};
    }
}

pub fn main() u8 {
    const stderr = std.io.getStdErr().writer();

    // Command arguments
    var args = std.process.args();
    defer args.deinit();
    _ = args.skip(); // skip "wiki2md"

    var cwd = std.fs.cwd();

    // Output directory (first argument)
    var out_dir: Dir = if (args.next()) |arg| blk: {
        stderr.print(
            "{s}info{s}: transpiling to {s}{s}{s}\n",
            .{GREEN, NORMAL, CYAN, arg, NORMAL}
        ) catch {};
        const result = get_output_dir(arg, &cwd, stderr);
        break :blk result catch { return 1; };
    } else {
        stderr.print(
            \\wiki2md – transpile your Vimwiki files to Markdown
            \\
            \\{s}Usage{s}: {s}wiki2md <output directory> [(<input file>|<input directory>) ...]{s}
            \\
            , .{GREEN, NORMAL, CYAN, NORMAL}
        ) catch {};
        return 1;
    };
    defer out_dir.close();

    var stat: u8 = 0;

    // Any input paths (second argument)
    if (args.next()) |arg| read_arg(arg, &cwd, &out_dir, stderr) catch { stat = 1; }
    else {
        stderr.print("{s}error{s}: no input files\n", .{RED, NORMAL}) catch {};
        return 1;
    }

    // Rest of arguments
    while (args.next()) |arg| read_arg(arg, &cwd, &out_dir, stderr) catch { stat = 1; };
    return stat;
}
