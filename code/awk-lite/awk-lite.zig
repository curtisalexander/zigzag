// awk-lite.zig — A minimalistic awk-like tool for learning
//
// Usage:
//   awk-lite '<program>' [file]          # process file (or stdin)
//   awk-lite -F, '<program>' [file]      # use comma as field separator
//
// Program syntax (a tiny subset of awk):
//   {print $0}                  — print whole line
//   {print $1}                  — print first field
//   {print $1, $3}              — print first and third fields
//   /pattern/ {print $0}        — only lines matching pattern
//   NR == 5 {print $0}          — only line 5
//   NR <= 10 {print $0}         — first 10 lines
//   NR >= 100 {print $0}        — lines from 100 onward
//   BEGIN {print "header"}      — run before processing lines
//   END {print "done"}          — run after processing lines
//
// How awk works (the mental model):
//   1. For each line of input:
//      a. Split the line into fields ($1, $2, ... $NF)
//      b. $0 is the whole line
//      c. Check each rule's pattern — if it matches, run the action
//   2. That's it. The loop over lines is implicit — you don't write it.
//
// This tool implements that core loop. Real awk has variables, math,
// arrays, printf, getline, and more. We skip all of that. The goal
// is to understand the ARCHITECTURE, not replicate the features.
//
// Written for Zig 0.15.x.

const std = @import("std");

// ── The parsed program ───────────────────────────────────────────
//
// EXPLORE: In Zig, you model your domain with structs and enums,
// not classes. There's no inheritance. Enums can have methods and
// can be tagged unions (sum types) — more like Rust's enums than
// C's enums.
//
// A "program" is a list of rules. Each rule has a pattern (when to
// fire) and an action (what to do). This is the core of awk's design.

const Pattern = union(enum) {
    // EXPLORE: This is a tagged union — it can be ONE of these variants
    // at a time. The tag tells you which one. Like Rust's enum or
    // TypeScript's discriminated union.
    always, // no pattern — matches every line
    begin, //  BEGIN — before any lines
    end, //    END — after all lines
    regex: []const u8, // /pattern/ — substring match
    line_number: LineNumberPattern,
};

const Comparison = enum {
    eq, // ==
    ne, // !=
    lt, // <
    le, // <=
    gt, // >
    ge, // >=
};

const LineNumberPattern = struct {
    op: Comparison,
    value: usize,
};

const FieldRef = union(enum) {
    // $0 = whole line, $1..$N = fields
    index: usize,
    literal: []const u8,
};

const Action = struct {
    // For now, the only action is "print" with a list of field refs.
    fields: []const FieldRef,
};

const Rule = struct {
    pattern: Pattern,
    action: Action,
};

const Program = struct {
    rules: []const Rule,
};

// ── Entry point ──────────────────────────────────────────────────

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // I/O setup (Zig 0.15 style)
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    var stderr_buf: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
    const stderr = &stderr_writer.interface;

    // ── Parse CLI arguments ──────────────────────────────────────
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Skip args[0] (program name). Look for -F flag, program, and file.
    var field_sep: []const u8 = &[_]u8{' '};
    var squeeze_delimiters: bool = true;
    var program_src: ?[]const u8 = null;
    var input_filename: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (arg.len >= 2 and arg[0] == '-' and arg[1] == 'F') {
            // -F, or -F,  (separator follows immediately or is next arg)
            if (arg.len > 2) {
                field_sep = arg[2..];
            } else if (i + 1 < args.len) {
                i += 1;
                field_sep = args[i];
            } else {
                try stderr.print("awk-lite: -F requires a separator\n", .{});
                try stderr.flush();
                std.process.exit(1);
            }
            // With explicit delimiter, don't squeeze (like real awk -F,)
            squeeze_delimiters = false;
        } else if (program_src == null) {
            program_src = arg;
        } else if (input_filename == null) {
            input_filename = arg;
        }
    }

    if (program_src == null) {
        try stderr.print("Usage: awk-lite [-F sep] '<program>' [file]\n", .{});
        try stderr.flush();
        std.process.exit(1);
    }

    // ── Parse the program ────────────────────────────────────────
    //
    // EXPLORE: We parse the awk program string into our Rule structs.
    // This is a tiny hand-written parser — no parser generator needed.
    // For a language this small, hand-parsing is the right call.
    const program = parseProgram(allocator, program_src.?) catch |err| {
        try stderr.print("awk-lite: parse error: {}\n", .{err});
        try stderr.flush();
        std.process.exit(1);
    };
    defer freeProgram(allocator, program);

    // ── Open input (file or stdin) ───────────────────────────────
    //
    // EXPLORE: This pattern — "open a file if given, otherwise use
    // stdin" — is bread and butter for Unix CLI tools. In Zig we
    // handle it by making the file handle optional and falling back
    // to stdin.
    const input_file = if (input_filename) |fname|
        std.fs.cwd().openFile(fname, .{}) catch |err| {
            try stderr.print("awk-lite: cannot open '{s}': {}\n", .{ fname, err });
            try stderr.flush();
            std.process.exit(1);
        }
    else
        null;
    defer if (input_file) |f| f.close();

    // Get a reader — either from the file or from stdin.
    // EXPLORE: Zig doesn't have inheritance or dynamic dispatch by
    // default. But file handles and stdin are both File types, so
    // we can just pick one.
    const input = if (input_file) |f| f else std.fs.File.stdin();

    // ── Run BEGIN rules ──────────────────────────────────────────
    for (program.rules) |rule| {
        if (rule.pattern == .begin) {
            try executeAction(stdout, rule.action, "", &[_][]const u8{});
        }
    }

    // ── The main loop — this IS awk ──────────────────────────────
    //
    // EXPLORE: This is the heart of awk's design: an implicit loop
    // over every line of input. You don't write the loop — awk does
    // it for you. Each line gets split into fields, then every rule
    // is checked against it.
    //
    // We read the entire input into memory, then split on newlines.
    // For a teaching tool, clarity beats streaming efficiency.
    // A production awk would stream line-by-line to handle huge files.
    const content = try input.readToEndAlloc(allocator, 100 * 1024 * 1024);
    defer allocator.free(content);

    // EXPLORE: We split on newlines to get lines, then for each line
    // we split on the field separator to get fields.
    var line_it = std.mem.splitScalar(u8, content, '\n');

    var nr: usize = 0;
    while (line_it.next()) |raw_line| {
        // Trim trailing \r for Windows line endings
        const line = if (raw_line.len > 0 and raw_line[raw_line.len - 1] == '\r')
            raw_line[0 .. raw_line.len - 1]
        else
            raw_line;

        nr += 1;

        // ── Split line into fields ───────────────────────────────
        //
        // EXPLORE: This is where $1, $2, etc come from. In real awk,
        // the default separator is "whitespace" and consecutive
        // whitespace is squeezed. With -F, each separator is significant.
        //
        // We use an ArrayList to collect fields since we don't know
        // how many there'll be.
        var fields: std.ArrayList([]const u8) = .{};
        defer fields.deinit(allocator);

        if (squeeze_delimiters and field_sep.len == 1) {
            var field_it = std.mem.tokenizeScalar(u8, line, field_sep[0]);
            while (field_it.next()) |field| {
                try fields.append(allocator, field);
            }
        } else if (field_sep.len == 1) {
            var field_it = std.mem.splitScalar(u8, line, field_sep[0]);
            while (field_it.next()) |field| {
                try fields.append(allocator, field);
            }
        } else {
            var field_it = std.mem.splitSequence(u8, line, field_sep);
            while (field_it.next()) |field| {
                try fields.append(allocator, field);
            }
        }

        // ── Check each rule against this line ────────────────────
        for (program.rules) |rule| {
            const matches = switch (rule.pattern) {
                .always => true,
                .begin => false, // already ran
                .end => false, // runs after
                .regex => |pat| std.mem.indexOf(u8, line, pat) != null,
                .line_number => |ln| switch (ln.op) {
                    .eq => nr == ln.value,
                    .ne => nr != ln.value,
                    .lt => nr < ln.value,
                    .le => nr <= ln.value,
                    .gt => nr > ln.value,
                    .ge => nr >= ln.value,
                },
            };

            if (matches) {
                try executeAction(stdout, rule.action, line, fields.items);
            }
        }
    }

    // ── Run END rules ────────────────────────────────────────────
    for (program.rules) |rule| {
        if (rule.pattern == .end) {
            try executeAction(stdout, rule.action, "", &[_][]const u8{});
        }
    }

    try stdout.flush();
}

// ── Execute a print action ───────────────────────────────────────
//
// EXPLORE: The Writer is passed as a pointer — this function doesn't
// know or care whether it's writing to stdout, a file, or a buffer.
// That's the power of Zig's interface pattern.
const Writer = std.io.GenericWriter(void, anyerror, struct {
    fn f(_: void, _: []const u8) anyerror!usize {
        unreachable;
    }
}.f);

fn executeAction(
    stdout: anytype,
    action: Action,
    line: []const u8,
    fields: []const []const u8,
) !void {
    for (action.fields, 0..) |field_ref, idx| {
        if (idx > 0) try stdout.print(" ", .{});

        switch (field_ref) {
            .index => |field_idx| {
                if (field_idx == 0) {
                    try stdout.print("{s}", .{line});
                } else if (field_idx <= fields.len) {
                    try stdout.print("{s}", .{fields[field_idx - 1]});
                }
                // If field_idx > fields.len, print nothing (like real awk)
            },
            .literal => |text| {
                try stdout.print("{s}", .{text});
            },
        }
    }
    try stdout.print("\n", .{});
}

// ── Parser ───────────────────────────────────────────────────────
//
// EXPLORE: This is a hand-written recursive descent parser. It's
// the simplest kind of parser — you just walk through the input
// character by character, calling functions for each grammar rule.
//
// For a language as small as awk-lite, this is the right approach.
// You wouldn't reach for a parser generator until the grammar gets
// much bigger.

const ParseError = error{
    UnexpectedChar,
    ExpectedOpenBrace,
    ExpectedCloseBrace,
    ExpectedPrint,
    UnexpectedEnd,
    InvalidFieldRef,
    InvalidNumber,
    ExpectedComparison,
    OutOfMemory,
};

fn parseProgram(allocator: std.mem.Allocator, src: []const u8) ParseError!Program {
    var rules: std.ArrayList(Rule) = .{};
    errdefer {
        for (rules.items) |rule| freeRule(allocator, rule);
        rules.deinit(allocator);
    }

    var pos: usize = 0;
    while (pos < src.len) {
        // Skip whitespace between rules
        while (pos < src.len and (src[pos] == ' ' or src[pos] == '\t' or src[pos] == ';')) {
            pos += 1;
        }
        if (pos >= src.len) break;

        const rule = try parseRule(allocator, src, &pos);
        try rules.append(allocator, rule);
    }

    // EXPLORE: .toOwnedSlice() extracts the underlying slice from
    // the ArrayList and transfers ownership to the caller. The
    // ArrayList becomes empty after this — you can't use it anymore.
    return .{ .rules = try rules.toOwnedSlice(allocator) };
}

fn parseRule(allocator: std.mem.Allocator, src: []const u8, pos: *usize) ParseError!Rule {
    skipWhitespace(src, pos);
    if (pos.* >= src.len) return ParseError.UnexpectedEnd;

    // Determine the pattern
    var pattern: Pattern = .always;

    if (src[pos.*] == '/') {
        // /regex/ pattern
        pos.* += 1; // skip opening /
        const start = pos.*;
        while (pos.* < src.len and src[pos.*] != '/') {
            pos.* += 1;
        }
        if (pos.* >= src.len) return ParseError.UnexpectedEnd;
        pattern = .{ .regex = src[start..pos.*] };
        pos.* += 1; // skip closing /
    } else if (pos.* + 5 <= src.len and std.mem.eql(u8, src[pos.* .. pos.* + 5], "BEGIN")) {
        pattern = .begin;
        pos.* += 5;
    } else if (pos.* + 3 <= src.len and std.mem.eql(u8, src[pos.* .. pos.* + 3], "END")) {
        pattern = .end;
        pos.* += 3;
    } else if (pos.* + 2 <= src.len and src[pos.*] == 'N' and src[pos.* + 1] == 'R') {
        // NR comparison pattern
        pos.* += 2;
        skipWhitespace(src, pos);

        // Parse comparison operator
        const op: Comparison = blk: {
            if (pos.* + 1 < src.len and src[pos.*] == '=' and src[pos.* + 1] == '=') {
                pos.* += 2;
                break :blk .eq;
            } else if (pos.* + 1 < src.len and src[pos.*] == '!' and src[pos.* + 1] == '=') {
                pos.* += 2;
                break :blk .ne;
            } else if (pos.* + 1 < src.len and src[pos.*] == '<' and src[pos.* + 1] == '=') {
                pos.* += 2;
                break :blk .le;
            } else if (pos.* + 1 < src.len and src[pos.*] == '>' and src[pos.* + 1] == '=') {
                pos.* += 2;
                break :blk .ge;
            } else if (pos.* < src.len and src[pos.*] == '<') {
                pos.* += 1;
                break :blk .lt;
            } else if (pos.* < src.len and src[pos.*] == '>') {
                pos.* += 1;
                break :blk .gt;
            } else {
                return ParseError.ExpectedComparison;
            }
        };

        skipWhitespace(src, pos);

        // Parse number
        const num_start = pos.*;
        while (pos.* < src.len and src[pos.*] >= '0' and src[pos.*] <= '9') {
            pos.* += 1;
        }
        if (pos.* == num_start) return ParseError.InvalidNumber;
        const value = std.fmt.parseInt(usize, src[num_start..pos.*], 10) catch
            return ParseError.InvalidNumber;

        pattern = .{ .line_number = .{ .op = op, .value = value } };
    } else if (src[pos.*] != '{') {
        return ParseError.UnexpectedChar;
    }

    // Parse the action: { print $1, $2 }
    skipWhitespace(src, pos);
    if (pos.* >= src.len or src[pos.*] != '{') return ParseError.ExpectedOpenBrace;
    pos.* += 1;
    skipWhitespace(src, pos);

    // Expect "print"
    if (pos.* + 5 > src.len or !std.mem.eql(u8, src[pos.* .. pos.* + 5], "print")) {
        return ParseError.ExpectedPrint;
    }
    pos.* += 5;
    skipWhitespace(src, pos);

    // Parse field references and string literals
    var field_refs: std.ArrayList(FieldRef) = .{};
    errdefer field_refs.deinit(allocator);

    while (pos.* < src.len and src[pos.*] != '}') {
        skipWhitespace(src, pos);
        if (pos.* >= src.len or src[pos.*] == '}') break;

        // Skip commas between fields
        if (src[pos.*] == ',') {
            pos.* += 1;
            skipWhitespace(src, pos);
            continue;
        }

        if (src[pos.*] == '$') {
            // Field reference: $0, $1, $2, etc.
            pos.* += 1;
            const num_start = pos.*;
            while (pos.* < src.len and src[pos.*] >= '0' and src[pos.*] <= '9') {
                pos.* += 1;
            }
            if (pos.* == num_start) return ParseError.InvalidFieldRef;
            const field_idx = std.fmt.parseInt(usize, src[num_start..pos.*], 10) catch
                return ParseError.InvalidFieldRef;
            try field_refs.append(allocator, .{ .index = field_idx });
        } else if (src[pos.*] == '"') {
            // String literal: "hello"
            pos.* += 1;
            const str_start = pos.*;
            while (pos.* < src.len and src[pos.*] != '"') {
                pos.* += 1;
            }
            if (pos.* >= src.len) return ParseError.UnexpectedEnd;
            try field_refs.append(allocator, .{ .literal = src[str_start..pos.*] });
            pos.* += 1; // skip closing quote
        } else {
            break;
        }
    }

    // Default: if no fields specified, print $0
    if (field_refs.items.len == 0) {
        try field_refs.append(allocator, .{ .index = 0 });
    }

    skipWhitespace(src, pos);
    if (pos.* >= src.len or src[pos.*] != '}') return ParseError.ExpectedCloseBrace;
    pos.* += 1;

    return .{
        .pattern = pattern,
        .action = .{ .fields = try field_refs.toOwnedSlice(allocator) },
    };
}

fn skipWhitespace(src: []const u8, pos: *usize) void {
    while (pos.* < src.len and (src[pos.*] == ' ' or src[pos.*] == '\t')) {
        pos.* += 1;
    }
}

fn freeRule(allocator: std.mem.Allocator, rule: Rule) void {
    allocator.free(rule.action.fields);
}

fn freeProgram(allocator: std.mem.Allocator, program: Program) void {
    for (program.rules) |rule| freeRule(allocator, rule);
    allocator.free(program.rules);
}
