// TODO FINAL PORT windows
const std = @import("std");
const builtin = @import("builtin");
const Dir = std.fs.Dir;
const File = std.fs.File;

const NORMAL: []const u8 = "\x1b[0m";
const RED: []const u8 = "\x1b[31m";
const GREEN: []const u8 = "\x1b[32m";
const CYAN: []const u8 = "\x1b[36m";

/// Return a boolean on whether the given path is absolute or relative.
fn path_is_absolute(path: []const u8) bool {
    switch (builtin.os.tag) {
        .linux, .macos, .dragonfly, .freebsd, .openbsd, .netbsd, .wasi =>
            return path[0] == '/' or path[0] == '~',
        .windows => {
            const has_drive_letter = std.ascii.isUpper(path[0]) and
                                     path[1] == ':' and
                                     path[2] == '\\';
            const is_UNC = std.mem.startsWith(path, "\\\\");
            return has_drive_letter or is_UNC;
        },
        else => return false
    }
}

/// Return a handle to the given directory path. If the directory doesn't exist,
/// try to create it.
/// Alternatively return a directory open error.
fn get_out_dir(dir: []const u8, stderr: anytype) Dir.OpenError!Dir {
    const is_absolute = path_is_absolute(dir);

    const result = if (is_absolute) std.fs.openDirAbsolute(dir, .{})
    else std.fs.cwd().openDir(dir, .{});

    return result catch |err| {
        if (err == Dir.OpenError.FileNotFound) {
            const new_dir = if (is_absolute) std.fs.makeDirAbsolute(dir)
            else std.fs.cwd().makeDir(dir);

            _ = new_dir catch {
                stderr.print("{s}error{s}: {s} could not create\n", .{RED, NORMAL, dir})
                catch {};
                return File.OpenError.FileNotFound;
            };
            stderr.print("{s}info{s}: {s}: created output directory\n",
                         .{GREEN, NORMAL, dir}) catch {};
            return get_out_dir(dir, stderr);
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

/// TODO CHANGE to also accept dir arguments
/// Return a handle to the given input file.
/// Alternatively return a file open error.
fn get_input_file(file_path: []const u8, stderr: anytype) File.OpenError!File {
    const result = if (path_is_absolute(file_path))
        std.fs.openFileAbsolute(file_path, .{})
    else std.fs.cwd().openFile(file_path, .{});

    return result catch |err| {
        const errmsg = switch (err) {
            File.OpenError.IsDir => "not a file",
            File.OpenError.AccessDenied => "access denied",
            File.OpenError.FileNotFound => "no such file",
            else => "could not open file"
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
fn transpilation_proc(file_path: []const u8, out_dir: *Dir, stderr: anytype) !void {
    stderr.print("TODO INFO transpiling {s}\n", .{file_path}) catch {};
    _ = out_dir; // TODO

    // TODO
    var file: File = get_input_file(file_path, stderr);
    defer file.close();
    //
    //var out_file: File = get_output_file(file_path, out_dir, stderr);
    //defer out_file.close();
    //
    //try transpile_file(&file, &out_file, stderr);

    return; // TODO
}

pub fn main() u8 {
    var stat: u8 = 0;
    var stderr = std.io.getStdErr().writer();

    // Command arguments
    var args = std.process.args();
    defer args.deinit();
    _ = args.skip(); // skip "wiki2md"
    
    // Output directory (first command argument)
    var out_dir = if (args.next()) |arg| blk: {
        const result = get_out_dir(arg, stderr);
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
