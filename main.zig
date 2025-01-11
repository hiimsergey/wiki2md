// TODO FINAL PORT windows
const std = @import("std");
const Dir = std.fs.Dir;
const File = std.fs.File;

const NORMAL: []const u8 = "\x1b[0m";
const RED: []const u8 = "\x1b[31m";
const GREEN: []const u8 = "\x1b[32m";
const CYAN: []const u8 = "\x1b[36m";

fn parse_out_dir(arg: []const u8, stderr: anytype) !Dir {
    const is_absolute = std.mem.startsWith(u8, "/", arg) or std.mem.startsWith(u8, "~", arg);

    const result = if (is_absolute) std.fs.openDirAbsolute(arg, .{})
    else std.fs.cwd().openDir(arg, .{});

    return result catch |err| {
        if (err == File.OpenError.FileNotFound) {
            const new_dir = if (is_absolute) std.fs.makeDirAbsolute(arg)
            else std.fs.cwd().makeDir(arg);

            _ = new_dir catch {
                stderr.print("{s}error{s}: {s} could not create\n", .{RED, NORMAL, arg})
                catch {};
                return File.OpenError.FileNotFound;
            };
            stderr.print("{s}info{s}: {s}: created output directory\n",
                         .{GREEN, NORMAL, arg}) catch {};
            return parse_out_dir(arg, stderr);
        }

        const errmsg = switch (err) {
            File.OpenError.NotDir => "not a directory",
            File.OpenError.FileNotFound => "no such directory",
            File.OpenError.AccessDenied => "permission denied",
            else => "could not open directory"
        };
        stderr.print("{s}error{s}: {s}: {s}\n", .{RED, NORMAL, arg, errmsg}) catch {};
        return err;
    };
}

fn parse_arg(arg: []const u8, out_dir: *const Dir, stderr: anytype) !void {
    stderr.print("parse_arg: so our arg is {s} now, huh?\n", .{arg}) catch {};
    _ = out_dir;
    return;
}

pub fn main() u8 {
    var stat: u8 = 0;
    var stderr = std.io.getStdErr().writer();

    var args = std.process.args();
    defer args.deinit();
    _ = args.skip(); // skip "wiki2md"
    
    var out_dir = if (args.next()) |arg| blk: {
        const result = parse_out_dir(arg, stderr);
        break :blk result catch { return 1; };
    } else {
        stderr.print(
            \\wiki2md – translate your Vimwiki files to Markdown
            \\
            \\{s}Usage{s}: {s}wiki2md <destination directory> [(<input file>|<input directory>) ...]{s}
            \\
            , .{GREEN, NORMAL, CYAN, NORMAL}
        ) catch {};
        return 1;
    };
    defer out_dir.close();

    if (args.next()) |arg| parse_arg(arg, &out_dir, stderr) catch { stat = 1; }
    else {
        stderr.print("{s}error{s}: no input files\n", .{RED, NORMAL}) catch {};
        return 1;
    }

    while (args.next()) |arg| parse_arg(arg, &out_dir, stderr) catch { stat = 1; };

    return stat;
}
