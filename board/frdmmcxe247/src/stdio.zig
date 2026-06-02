const c = @import("c.zig").c;

pub fn SerialStdio(T: type, serialio: *T) type {
    return struct {
        ioFile: c.FILE = .{
            .flags = c._FDEV_SETUP_RW,
            .put = putc,
            .get = getc,
            .flush = flush,
        },

        pub fn putc(ch: u8, file: [*c]c.FILE) callconv(.c) c_int {
            _ = file;
            const out_char = ch;

            serialio.write((&ch)[0..1]) catch {
                return @intCast(c.EOF);
            };

            return @intCast(out_char);
        }
        pub fn getc(file: [*c]c.FILE) callconv(.c) c_int {
            _ = file;

            return @intCast(1);
        }
        fn flush(_: [*c]c.FILE) callconv(.c) c_int {
            return @intCast(0);
        }

        pub fn default() @This() {
            return .{
                .ioFile = .{
                    .flags = c._FDEV_SETUP_RW,
                    .put = putc,
                    .get = getc,
                    .flush = flush,
                },
            };
        }
    };
}
