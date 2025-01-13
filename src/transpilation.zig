const std = @import("std");

const Dir = std.fs.Dir;
const File = std.fs.File;

const String = std.ArrayList(u8);

const TokenType = enum {
    PARAGRAPH,

    BOLD, ITALIC, STRIKETHROUGH, SUPERSCRIPT, SUBSCRIPT,

    INLINE_CODE, CODE_BLOCK,
    
    MATH,

    HEADING1, HEADING2, HEADING3, HEADING4, HEADING5, HEADING6,

    // TODO NOW
    // TODO CONSIDER simply enumerating all list types
    BULLET_LIST, STAR_LIST, HASH_LIST,

    DEFINITION_LIST,

    QUOTE,

    LINK, ALIAS_LINK,

    TRANSCLUSION,

    // TODO NOTE can be undone, done (X) and partionally done (.)
    // TODO NOTE there are more :h vimwiki-todo-lists
    CHECKBOX,

    // TODO NOTE they can contain colons for alignment :h vimwiki-tables
    TABLE,

    COMMENT,

    DELIMITER,

    TAG,

    PLACEHOLDER,

// TODO NOTE ordered list indices go up to INT64_MAX
// TODO different kind of lists
// number, lowercase letter, uppercase letter,
// lowercase roman, uppercase roman
// followed by . (only for numbers), or `)`
};

const Token = struct {
    type: TokenType,
    value: String
};


pub fn transpile_file(file: *File, out_file: *File, stderr: anytype) !void {
    const reader = file.reader();
}
