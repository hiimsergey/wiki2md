const std = @import("std");

const Dir = std.fs.Dir;
const File = std.fs.File;

const NORMAL: []const u8 = "\x1b[0m";
const RED: []const u8 = "\x1b[31m";
const GREEN: []const u8 = "\x1b[32m";
const CYAN: []const u8 = "\x1b[36m";


/// TODO COMMENT
fn mkdir(dir: *Dir, dir_basename: []const u8, stderr: anytype) Dir.MakeError!void {
    dir.makeDir(dir_basename) catch |err| {
        const errmsg = switch (err) {
            Dir.MakeError.AccessDenied => "access denied",
            Dir.MakeError.NoSpaceLeft => "no space left in memory",
            else => "could not make directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, dir_basename, errmsg}) catch {};
        return err;
    };
    stderr.print("{s}info{s}: {s}: made directory\n", .{GREEN, NORMAL, dir_basename}) catch {};
}

/// TODO COMMENT
fn get_output_dir(dir_path: []const u8, stderr: anytype) (Dir.MakeError || Dir.OpenError)!Dir {
    var cwd = std.fs.cwd();
    defer cwd.close();

    return cwd.openDir(dir_path, .{}) catch |err| {
        if (err == Dir.OpenError.FileNotFound) {
            try mkdir(&cwd, dir_path, stderr);
            return get_output_dir(dir_path, stderr);
        }

        const errmsg = switch (err) {
            Dir.OpenError.NotDir => "not a directory",
            Dir.OpenError.FileNotFound => "no such directory",
            else => "could not open directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, dir_path, errmsg}) catch {};
        return err;
    };
}

/// TODO COMMENT
fn get_output_file(file_basename: []const u8, out_dir: *Dir, stderr: anytype) File.OpenError!File {
    const result = out_dir.createFile(file_basename, .{}) catch |err| {
        const errmsg = switch (err) {
            File.OpenError.NoSpaceLeft => "no space left in memory",
            File.OpenError.PathAlreadyExists => "already exists",
            else => "could not create file"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, file_basename, errmsg}) catch {};
        return err;
    };
    stderr.print("{s}info{s}: {s}: created file\n", .{GREEN, NORMAL, file_basename}) catch {};
    return result;
}

// TODO CONSIDER not using a separate function for that
/// TODO COMMENT
fn get_input_file(file_path: []const u8, stderr: anytype) File.OpenError!File {
    return std.fs.cwd().openFile(file_path, .{}) catch |err| {
        stderr.print("{s}error{s}: {s}: could not open", .{RED, NORMAL, file_path}) catch {};
        return err;
    };
}

/// TODO COMMMENT
fn transpile_file(file: *File, out_file: *File, stderr: anytype) !void {
    stderr.print("very well\n", .{}) catch {};
    _ = file;
    _ = out_file;
}

// TODO CONSIDER passings is_absolute here because when recursing to this func for all children
// of a dir, you can check for is_absolute for one file, since all of them are the same.
/// TODO COMMENT
fn read_arg(path: []const u8, out_dir: *Dir, stderr: anytype)
(File.StatError || File.OpenError || Dir.MakeError)!void {
    const path_stat: File.Stat = std.fs.cwd().statFile(path) catch |err| {
        const errmsg = switch (err) {
            File.StatError.AccessDenied => "access denied",
            else => "could not open"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, path, errmsg}) catch {};
        return err;
    };

    if (path_stat.kind == File.Kind.file) {
        var file: File = try get_input_file(path, stderr);
        defer file.close();

        const basename = std.fs.path.basename(path);
        var out_file: File = try get_output_file(basename, out_dir, stderr);
        defer out_file.close();

        try transpile_file(&file, &out_file, stderr);
    } else {
        const basename = std.fs.path.basename(path);
        // TODO CONSIDER moving to two functions
        try mkdir(out_dir, basename, stderr);

        var out_subdir: Dir = out_dir.openDir(path, .{ .iterate = true }) catch |err| {
            stderr.print(
                "{s}error{s}: {s}: could not open directory, despite just making it :/\n",
                .{RED, NORMAL, path}
            ) catch {};
            return err;
        };
        defer out_subdir.close();

        var subdir_it: Dir.Iterator = out_subdir.iterate();
        while (try subdir_it.next()) |entry| try read_arg(entry.name, &out_subdir, stderr);
    }
}

pub fn main() u8 {
    const stderr = std.io.getStdErr().writer();

    // Command arguments
    var args = std.process.args();
    defer args.deinit();
    _ = args.skip(); // skip "wiki2md"

    // Output directory (first argument)
    var out_dir: Dir = if (args.next()) |arg| get_output_dir(arg, stderr) catch { return 1; }
    else {
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

    // Any input paths (second argument)
    if (args.next()) |arg| read_arg(arg, &out_dir, stderr) catch { return 1; }
    else {
        stderr.print("{s}error{s}: no input files\n", .{RED, NORMAL}) catch {};
        return 1;
    }

    // Rest of arguments
    var stat: u8 = 0;
    while (args.next()) |arg| read_arg(arg, &out_dir, stderr) catch { stat = 1; };
    return stat;
}
