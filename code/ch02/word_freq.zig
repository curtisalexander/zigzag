// word_freq.zig — Count word frequencies in a text file
//
// Run with:  zig run word_freq.zig -- shakespeare.txt
//            zig run word_freq.zig -- shakespeare.txt 25
//
// Source text: The Complete Works of William Shakespeare
//   Project Gutenberg, eBook #100
//   https://www.gutenberg.org/ebooks/100
//
// This program is meant to be READ, not just run. It's a tour of Zig's
// surface area: allocators, error handling, file I/O, data structures,
// slices, sorting, and the standard library.
//
// Written for Zig 0.15.x, which overhauled the I/O system. Writers now
// require explicit buffers — no more hidden buffering. This mirrors how
// Zig handles allocators: nothing is implicit.
//
// ┌─────────────────────────────────────────────────────────────────┐
// │ TRY IT: The summary header shows "Unique words" but not the     │
// │ total number of words processed. Can you add that?              │
// │                                                                 │
// │ You need three things:                                          │
// │   1. A counter variable (var, not const!) before the loop       │
// │   2. An increment inside the tokenize loop                      │
// │   3. A print line in the summary section                        │
// │                                                                 │
// │ Hint: look at how `counts.count()` is used in the summary,      │
// │ then add your own line next to it.                              │
// │                                                                 │
// │ Expected output for Shakespeare: ~900,000 total words.          │
// └─────────────────────────────────────────────────────────────────┘

const std = @import("std");

// ┌─────────────────────────────────────────────────────────────────┐
// │ EXPLORE: In Zig, you don't get a garbage collector or           │
// │ reference counting. Instead, you pass an Allocator explicitly   │
// │ to anything that needs heap memory. This is THE big idea in     │
// │ Zig's memory model — memory allocation is never hidden from you.│
// │                                                                 │
// │ As of Zig 0.15, I/O follows the same philosophy: writers need   │
// │ an explicit buffer you provide. Nothing is hidden.              │
// └─────────────────────────────────────────────────────────────────┘

pub fn main() !void {
    // ── Allocator setup ──────────────────────────────────────────
    //
    // GeneralPurposeAllocator is Zig's "batteries included" allocator.
    // It's debug-friendly: it detects leaks, double-frees, and
    // use-after-free in debug builds. In release builds it's fast.
    //
    // The .{} is an anonymous struct literal with all default fields.
    // You'll see this pattern EVERYWHERE in Zig — it means
    // "give me the defaults."
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    // EXPLORE: `defer` runs cleanup code when the current scope exits.
    // This is Zig's answer to RAII, try/finally, and context managers.
    // It guarantees cleanup even if the function returns early via error.
    //
    // .deinit() returns .ok or .leak — we check for leaks at exit.
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }

    // EXPLORE: Why store this in a `const`? Because `allocator` is an
    // interface value (a fat pointer — vtable + pointer). It doesn't
    // change; what changes is the memory the GPA manages internally.
    const allocator = gpa.allocator();

    // ── I/O setup ────────────────────────────────────────────────
    //
    // EXPLORE: In Zig 0.15, stdout and stderr are obtained from
    // std.fs.File — they're just file handles. To WRITE to them,
    // you create a writer with an explicit buffer you provide.
    //
    // This is the same philosophy as allocators: the caller owns
    // the resources (here, the buffer memory). Nothing is hidden.
    //
    // .interface gives you the generic Writer interface — you can
    // pass &stdout to any function that takes a *Writer.
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    var stderr_buf: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
    const stderr = &stderr_writer.interface;

    // ── Parse command-line arguments ─────────────────────────────
    //
    // EXPLORE: `try` is Zig's error propagation operator.
    // If argsAlloc returns an error, `try` immediately returns
    // that error from main. The `!void` return type means
    // "returns void on success, or an error."
    //
    // This is like Rust's `?` operator, but Zig's error unions
    // are a language primitive, not a library type like Result<T, E>.
    const args = try std.process.argsAlloc(allocator);

    // EXPLORE: `defer` again — freeing the args when we're done.
    // Notice the pattern: allocate, then immediately defer the free.
    // This keeps the "open/close" pair visually adjacent.
    defer std.process.argsFree(allocator, args);

    // args[0] is the program name (just like C's argv).
    if (args.len < 2) {
        try stderr.print("Usage: word_freq <filename> [top_n]\n", .{});
        try stderr.flush();

        // EXPLORE: This is how Zig does "exit with error status."
        // std.process.exit is noreturn — it terminates the process.
        std.process.exit(1);
    }

    const filename = args[1];

    // Parse optional top_n argument, default to 20.
    // EXPLORE: This shows Zig's integer parsing. `catch` here handles
    // the error case inline — if parsing fails, we print and exit.
    const top_n: usize = if (args.len > 2)
        std.fmt.parseInt(usize, args[2], 10) catch {
            try stderr.print("Invalid number: {s}\n", .{args[2]});
            try stderr.flush();
            std.process.exit(1);
        }
    else
        20;

    // ── Read the file ────────────────────────────────────────────
    //
    // EXPLORE: Zig's file API is lower-level than Python's open().
    // You open a file, get a File handle, and read from it.
    // There's no with-statement — you use defer to close it.
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        try stderr.print("Cannot open '{s}': {}\n", .{ filename, err });
        try stderr.flush();
        std.process.exit(1);
    };
    defer file.close();

    // EXPLORE: readToEndAlloc reads the ENTIRE file into memory.
    // The second arg is a max size (here ~10 MB). This is a safety
    // valve — Zig won't silently allocate unbounded memory.
    //
    // In Python you'd just do f.read(). In Zig, the allocator is
    // explicit and you set a ceiling. This is the trade-off:
    // more typing, but no surprises.
    const content = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(content);

    // ── Count words ──────────────────────────────────────────────
    //
    // EXPLORE: StringHashMap(u32) is a hash map where keys are []const u8
    // (string slices) and values are u32 (our counts).
    //
    // Zig's hash maps are generic but have convenience aliases:
    //   StringHashMap(V) = HashMap([]const u8, V, ..., ...)
    //
    // Note: the keys here are slices pointing INTO `content`.
    // They don't own their memory — they're views. This is efficient
    // but means `content` must outlive the map. (It does, because
    // we defer-free content AFTER we're done with the map.)
    var counts = std.StringHashMap(u32).init(allocator);
    defer counts.deinit();

    // ── Tokenize ─────────────────────────────────────────────────
    //
    // EXPLORE: std.mem.tokenizeAny splits on ANY character in the
    // delimiter set. It skips consecutive delimiters (unlike split,
    // which would give you empty strings between them).
    //
    // The delimiter is a SET of characters, not a sequence.
    // So &[_]u8{ ' ', '\t', '\n', '\r' } means "split on space
    // OR tab OR newline OR carriage return."
    //
    // Zig 0.15 offers three tokenize variants:
    //   tokenizeScalar   — split on one character
    //   tokenizeAny      — split on any char in a set
    //   tokenizeSequence — split on an exact multi-char sequence
    var it = std.mem.tokenizeAny(u8, content, &[_]u8{ ' ', '\t', '\n', '\r' });

    while (it.next()) |raw_word| {
        // ── Normalize: strip punctuation ─────────────────────────
        //
        // EXPLORE: This is manual work that Python's str.strip() does
        // for you. Zig gives you building blocks, not batteries.
        const word = normalizeWord(raw_word);

        // Skip empty strings (words that were all punctuation).
        if (word.len == 0) continue;

        // EXPLORE: getOrPut is the "upsert" pattern. It either:
        //   - finds an existing entry -> found_existing = true
        //   - creates a new entry    -> found_existing = false
        //
        // Either way, .value_ptr gives you a *u32 you can modify.
        // This avoids doing two hash lookups (one to check, one to set).
        const result = try counts.getOrPut(word);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    // ── Sort by frequency ────────────────────────────────────────
    //
    // EXPLORE: To sort a hash map's entries, we need to extract them
    // into a slice (contiguous array) first. Hash maps have no
    // inherent order.
    //
    // ArrayList is Zig's growable array (like Python's list or Rust's Vec).

    const Entry = struct {
        word: []const u8,
        count: u32,
    };

    // EXPLORE: In Zig 0.15, ArrayList is "unmanaged" — it doesn't store
    // the allocator internally. You pass the allocator to each method
    // that needs it (append, deinit, etc). This mirrors the philosophy:
    // make resource usage explicit at every call site.
    var entries: std.ArrayList(Entry) = .{};
    defer entries.deinit(allocator);

    // EXPLORE: We iterate the map and collect entries into the ArrayList.
    // .iterator() gives us a stateful iterator — each .next() returns
    // a pointer to the next key/value pair, or null when exhausted.
    var map_it = counts.iterator();
    while (map_it.next()) |entry| {
        try entries.append(allocator, .{
            .word = entry.key_ptr.*,
            .count = entry.value_ptr.*,
        });
    }

    // EXPLORE: std.mem.sort is in-place, unstable sort.
    // The third argument is a "context" (unused here, hence {}).
    // The fourth is a comparison function.
    //
    // Notice the comparison returns true when a.count > b.count,
    // so higher counts come first (descending order).
    //
    // The comparison function is defined as an anonymous struct with
    // a single method — this is a common Zig pattern for passing
    // function pointers with type information.
    std.mem.sort(Entry, entries.items, {}, struct {
        fn cmp(_: void, a: Entry, b: Entry) bool {
            return a.count > b.count;
        }
    }.cmp);

    // ── Print results ────────────────────────────────────────────
    //
    // EXPLORE: We already set up stdout above. Now we just use it.
    // Remember: stdout is a *Writer backed by a 4096-byte buffer.
    // We must flush() at the end to ensure everything gets written.

    try stdout.print("===========================================\n", .{});
    try stdout.print(" Word Frequency Analysis\n", .{});
    try stdout.print(" File: {s}\n", .{filename});
    try stdout.print(" Unique words: {d}\n", .{counts.count()});
    try stdout.print("===========================================\n\n", .{});

    // ── Top words (all) ──────────────────────────────────────────
    const limit = @min(top_n, entries.items.len);

    try stdout.print(" TOP {d} WORDS (all)\n", .{limit});
    try stdout.print(" {s:<5}  {s:<20}  {s:>8}\n", .{ "Rank", "Word", "Count" });
    try stdout.print(" {s:-<5}  {s:-<20}  {s:->8}\n", .{ "", "", "" });

    for (entries.items[0..limit], 1..) |entry, rank| {
        // EXPLORE: Format specifiers in Zig:
        //   {d}    = decimal integer
        //   {s}    = string ([]const u8)
        //   {d:<5} = left-aligned, 5 chars wide
        //   {s:<20} = left-aligned, 20 chars wide
        //   {d:>8} = right-aligned, 8 chars wide
        try stdout.print(" {d:<5}  {s:<20}  {d:>8}\n", .{ rank, entry.word, entry.count });
    }

    // ── Top words (skipping stopwords) ───────────────────────────
    //
    // EXPLORE: The top words are mostly "the", "and", "of" — boring!
    // Let's filter those out to surface the interesting vocabulary.
    //
    // isStopword() uses a comptime-built lookup — see below for how
    // Zig's comptime feature lets us build a hash set at compile time.
    try stdout.print("\n TOP {d} WORDS (skipping stopwords)\n", .{limit});
    try stdout.print(" {s:<5}  {s:<20}  {s:>8}\n", .{ "Rank", "Word", "Count" });
    try stdout.print(" {s:-<5}  {s:-<20}  {s:->8}\n", .{ "", "", "" });

    var printed: usize = 0;
    for (entries.items) |entry| {
        if (printed >= limit) break;
        if (isStopword(entry.word)) continue;
        printed += 1;
        try stdout.print(" {d:<5}  {s:<20}  {d:>8}\n", .{ printed, entry.word, entry.count });
    }

    // ── Shakespeare spotlight ────────────────────────────────────
    //
    // Shakespeare invented or popularized hundreds of English words
    // and phrases we still use today. Let's see how often they appear
    // in his complete works.
    //
    // EXPLORE: This section shows how to use comptime string arrays
    // and iterate them at runtime. The array itself is baked into the
    // binary at compile time — no allocation needed.
    try stdout.print("\n SHAKESPEARE SPOTLIGHT\n", .{});
    try stdout.print(" Words he invented (or first wrote down)\n", .{});
    try stdout.print(" {s:<20}  {s:>8}\n", .{ "Word", "Count" });
    try stdout.print(" {s:-<20}  {s:->8}\n", .{ "", "" });

    // EXPLORE: This is a comptime array of string literals. The type
    // is []const []const u8 — a slice of slices. Each inner slice is
    // a string. The &.{ ... } syntax creates an anonymous array and
    // takes its address, giving us a slice.
    const coined_words = &[_][]const u8{
        "assassination", // Macbeth — "If the assassination could trammel up..."
        "eyeball", //       The Tempest / A Midsummer Night's Dream
        "lonely", //        Coriolanus
        "generous", //      Othello
        "gloomy", //        Titus Andronicus
        "swagger", //       Henry V / A Midsummer Night's Dream
        "torture", //       Throughout — he loved this word
        "champion", //      Macbeth
        "dauntless", //     Henry VI
        "worthless", //     Throughout
        "elbow", //         Measure for Measure (as a verb!)
        "gossip", //        The Comedy of Errors (as a person, then a verb)
        "obscene", //       Richard II / Love's Labour's Lost
        "majestic", //      Julius Caesar
        "courtship", //     The Merry Wives of Windsor
        "dwindle", //       Macbeth / Henry IV
        "amazement", //     The Tempest
        "luggage", //       Henry IV / Henry V
        "vulnerable", //    Macbeth
        "suspicious", //    Richard II
        "unreal", //        Macbeth — "Is this a dagger... unreal mockery"
        "eventful", //      As You Like It — "Last scene of all"
        "bedroom", //       A Midsummer Night's Dream
        "uncomfortable", // Romeo and Juliet
        "zany", //          Love's Labour's Lost
        "rant", //          Hamlet — "Nay, an thou'lt rant"
        "hint", //          Othello
        "flawed", //        King Lear
        "radiance", //      All's Well That Ends Well
        "gnarled", //       Measure for Measure
    };

    for (coined_words) |coined| {
        // EXPLORE: We look up each coined word in our counts map.
        // HashMap.get() returns an optional: ?u32.
        // The `if` with `|count|` unwraps it — this is Zig's
        // equivalent of "if let Some(count) = map.get(word)" in Rust.
        //
        // Note the case sensitivity issue again: we check the word
        // as-is, so we might miss capitalized occurrences.
        if (counts.get(coined)) |count| {
            try stdout.print(" {s:<20}  {d:>8}\n", .{ coined, count });
        } else {
            try stdout.print(" {s:<20}  {s:>8}\n", .{ coined, "-" });
        }
    }

    // ── Ye Olde English ──────────────────────────────────────────
    //
    // These aren't words Shakespeare invented — they're the archaic
    // forms that make his work feel distinctly Elizabethan.
    try stdout.print("\n YE OLDE ENGLISH\n", .{});
    try stdout.print(" {s:<20}  {s:>8}\n", .{ "Word", "Count" });
    try stdout.print(" {s:-<20}  {s:->8}\n", .{ "", "" });

    const archaic_words = &[_][]const u8{
        "thou", //     you (subject)
        "thee", //     you (object)
        "thy", //      your
        "thine", //    yours
        "hath", //     has
        "doth", //     does
        "art", //      are (thou art = you are)
        "ere", //      before
        "hence", //    from here / therefore
        "hither", //   to here
        "thither", //  to there
        "whence", //   from where
        "wherefore", // why (NOT "where" — Romeo, Romeo!)
        "prithee", //  I pray thee (please)
        "forsooth", // in truth
        "methinks", // it seems to me
        "anon", //     soon / shortly
        "alas", //     expression of grief
        "nay", //      no
        "aye", //      yes
        "woe", //      grief / sorrow
        "fie", //      expression of disgust
        "hark", //     listen!
        "knave", //    rascal / villain
        "villain", //  (Shakespeare's favorite insult)
        "sirrah", //   term of address (to inferiors)
    };

    for (archaic_words) |word| {
        if (counts.get(word)) |count| {
            try stdout.print(" {s:<20}  {d:>8}\n", .{ word, count });
        } else {
            try stdout.print(" {s:<20}  {s:>8}\n", .{ word, "-" });
        }
    }

    try stdout.print("\n", .{});

    // EXPLORE: Don't forget to flush! The writer holds data in its
    // buffer until you flush. Skip this and you might see no output
    // (or truncated output). This is a classic systems programming
    // gotcha — and Zig makes it explicit rather than hiding it.
    try stdout.flush();
}

// ┌─────────────────────────────────────────────────────────────────┐
// │ EXPLORE: Comptime in action! This function checks if a word is  │
// │ a common English stopword. The list is defined at comptime —    │
// │ it's baked into the binary. No heap allocation, no hash map     │
// │ setup at runtime.                                               │
// │                                                                 │
// │ We do a simple linear scan here. For ~50 words this is fine.    │
// │ Zig also has std.StaticStringMap for comptime-built perfect     │
// │ hash maps if you needed something faster.                       │
// └─────────────────────────────────────────────────────────────────┘
fn isStopword(word: []const u8) bool {
    const stopwords = [_][]const u8{
        "the",  "The",  "and",  "And",  "of",   "Of",
        "to",   "To",   "a",    "A",    "I",    "in",
        "In",   "is",   "Is",   "it",   "It",   "that",
        "That", "you",  "You",  "my",   "My",   "me",
        "Me",   "not",  "Not",  "with", "With", "for",
        "For",  "be",   "Be",   "his",  "His",  "your",
        "Your", "he",   "He",   "him",  "Him",  "her",
        "Her",  "have", "Have", "this", "This", "but",
        "But",  "so",   "So",   "will", "Will", "shall",
        "Shall", "do",  "Do",   "no",   "No",   "are",
        "Are",  "was",  "Was",  "we",   "We",   "as",
        "As",   "if",   "If",   "or",   "Or",   "from",
        "From", "by",   "By",   "at",   "At",   "on",
        "On",   "all",  "All",  "what", "What", "an",
        "An",   "which","Which","they", "They", "had",
        "Had",  "our",  "Our",  "them", "Them", "than",
        "Than", "who",  "Who",  "can",  "may",  "did",
        "would","could","should","were","been", "has",
        "am",   "up",   "out",  "one",  "upon", "how",
        "more", "their","when", "she",  "She",
    };

    for (&stopwords) |sw| {
        if (std.mem.eql(u8, word, sw)) return true;
    }
    return false;
}

// ┌─────────────────────────────────────────────────────────────────┐
// │ EXPLORE: This function shows several Zig concepts at once:      │
// │  - It takes a slice ([]const u8) and returns a sub-slice        │
// │  - No allocation needed — it returns a view into the input      │
// │  - The return type is the same as the input: a string slice     │
// │                                                                 │
// │ LIMITATION: This strips punctuation but does NOT lowercase.     │
// │ "The" and "the" are counted as different words. Fixing this     │
// │ properly requires allocating lowercased copies (costs memory)   │
// │ or using a custom hash map with case-insensitive hashing.       │
// │ Great thing to improve in a later chapter!                      │
// └─────────────────────────────────────────────────────────────────┘
fn normalizeWord(raw: []const u8) []const u8 {
    // Strip leading/trailing punctuation and digits.
    var start: usize = 0;
    var end: usize = raw.len;

    while (start < end and !std.ascii.isAlphabetic(raw[start])) {
        start += 1;
    }
    while (end > start and !std.ascii.isAlphabetic(raw[end - 1])) {
        end -= 1;
    }

    return raw[start..end];
}
