// TODO FINAL PORT windows
const std = @import("std");
const builtin = @import("builtin");

const Dir = std.fs.Dir;
const File = std.fs.File;

const NORMAL: []const u8 = "\x1b[0m";
const RED: []const u8 = "\x1b[31m";
const GREEN: []const u8 = "\x1b[32m";
const CYAN: []const u8 = "\x1b[36m";


/// TODO COMMENT
fn mkdir(dir: []const u8, is_absolute: bool) Dir.OpenError!void {
    const new_dir = if (is_absolute) std.fs.makeDirAbsolute(dir)
    else std.fs.cwd().makeDir(dir);

    _ = new_dir catch {
        stderr.print("{s}error{s}: {s} could not create\n", .{RED, NORMAL, dir})
        catch {};
        return File.OpenError.FileNotFound;
    };
    stderr.print("{s}info{s}: {s}: created output directory\n",
                 .{GREEN, NORMAL, dir}) catch {};
}

/// Return a handle to the given directory path. If the directory doesn't exist,
/// try to create it.
/// Alternatively return a directory open error.
fn get_output_dir(dir: []const u8, stderr: anytype) Dir.OpenError!Dir {
    const is_absolute = std.fs.path.isAbsolute(dir);

    const result = if (is_absolute) std.fs.openDirAbsolute(dir, .{})
    else std.fs.cwd().openDir(dir, .{});

    return result catch |err| {
        if (err == Dir.OpenError.FileNotFound) {
            try mkdir(dir, is_absolute);
            return get_output_dir(dir, stderr);
        }

        const errmsg = switch (err) {
            Dir.OpenError.NotDir => "not a directory",
            Dir.OpenError.FileNotFound => "no such directory",
            Dir.OpenError.AccessDenied => "access denied",
            else => "could not open directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, dir, errmsg}) catch {};
        return err;
    };
}

/// Return a handle to the given input file.
/// Alternatively return a file open error.
fn get_input_file(file_path: []const u8, is_absolute: bool, stderr: anytype) File.OpenError!File {
    const result = if (is_absolute) std.fs.openFileAbsolute(file_path, .{})
    else std.fs.cwd().openFile(file_path, .{});

    return result catch |err| {
        const errmsg = switch (err) {
            File.OpenError.AccessDenied => "access denied",
            File.OpenError.FileNotFound => "no such file",
            else => "could not open file"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, result, errmsg}) catch {};
        return err;
    };
}

/// Return a handle to the given input directory.
/// Alternatively return a directory open error.
fn get_input_dir(dir_path: []const u8, is_absolute: bool, out_dir: *Dir, stderr: anytype) Dir.OpenError!Dir {
    const result = if (is_absolute) {
        // TODO NOW i dont think basename is appropriate here
        const basename = std.fs.path.basename(dir_path);
        out_dir.openDir(basename, .{ .iterate = true }) catch |err| {
            if (err == Dir.OpenError.FileNotFound) {
                try mkdir() // TODO NOW NOTE PLAN
                // so i will inevitably land here because the main out dir doesnt have
                // all the subdirs of the arguments
                // if mkdir() will have only one call, then i wont keep it as a func
                // now ill research on how to make dir chains
            }
        };
    } else dir_path.openDir(dir_path, .{ .iterate = true });

    return result catch |err| {
        const errmsg = switch (err) {
            Dir.OpenError.AccessDenied => "access denied",
            Dir.OpenError.FileNotFound => "no such directory",
            else => "could not open directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, result, errmsg}) catch {};
        return err;
    };
}

/// TODO COMMENT
fn get_output_file(arg: []const u8, out_dir: *Dir, stderr: anytype) File {
    // TODO
    _ = arg;
    _ = out_dir;
    _ = stderr;

}

/// TODO COMMENT
fn transpile_file(file: *File, out_file: *File, stderr: anytype) !void {
    // TODO
    _ = file;
    _ = out_file;
    _ = stderr;
}

/// TODO COMMENT
fn transpilation_proc(path: []const u8, out_dir: *Dir, stderr: anytype) !void {
    stderr.print("TODO INFO transpiling {s}\n", .{path}) catch {};

    const is_absolute = std.fs.path.isAbsolute(path);
    const file_stat = std.fs.cwd().stat(path);

    if (file_stat.kind == .File) {
        const file: File = get_input_file(path, is_absolute, out_dir, stderr);
        const out_file: File = get_output_file(path, is_absolute, out_dir, stderr);
        transpile_file(&file, &out_file, stderr);
    } else {
        const dir: File = get_input_dir(path, is_absolute, out_dir, stderr);
        var dir_iter: Dir.Iterator = dir.iterate();
        while (dir_iter.next() catch null) |entry|
            try transpilation_proc(entry.name, dir, stderr);
        defer dir_iter.close();
    }
}

pub fn main() u8 {
    var stat: u8 = 0;
    var stderr = std.io.getStdErr().writer();

    // Command arguments
    var args = std.process.args();
    defer args.deinit();
    _ = args.skip(); // skip "wiki2md"
    
    // Output directory (first command argument)
    var out_dir: Dir = if (args.next()) |arg| blk: {
        const result = get_output_dir(arg, stderr);
        break :blk result catch { return 1; };
    } else {
        // Help message (no arguments)
        stderr.print(
            \\wiki2md – transpile your Vimwiki files to Markdown
            \\
            \\{s}Usage{s}: {s}wiki2md <destination directory> [(<input file>|<input directory>) ...]{s}
            \\
            , .{GREEN, NORMAL, CYAN, NORMAL}
        ) catch {};
        return 1;
    };
    defer out_dir.close();

    // Any input files (first argument)
    if (args.next()) |arg| transpilation_proc(arg, &out_dir, stderr) catch { stat = 1; }
    else {
        stderr.print("{s}error{s}: no input files\n", .{RED, NORMAL}) catch {};
        return 1;
    }

    // Rest of input files
    while (args.next()) |arg|
        transpilation_proc(arg, &out_dir, stderr) catch { stat = 1; };

    return stat;
}
