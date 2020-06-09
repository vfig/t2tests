def main(args):
    from json import dumps as encode_json, loads as decode_json
    from os.path import exists
    from sys import exit, stdin, stdout
    if len(args) < 3:
        cmd = args[0]
        print(f"{cmd} --encode <input.json> <output.bin>")
        print(f"{cmd} --decode <input.bin> <output.json>")
        exit(1)
    to_bin = (args[1] == '--encode')
    input_filename = args[2]
    output_filename = args[3]
    read_mode = ('r' if to_bin else 'rb')
    write_mode = ('wb' if to_bin else 'w')
    inf = stdin if (input_filename == '-') else open(input_filename, read_mode)
    input_data = inf.read()
    if to_bin:
        output_data = encode_rects(decode_json(input_data))
    else:
        output_data = encode_json(decode_rects(input_data))
    outf = stdout if (output_filename == '-') else open(output_filename, write_mode)
    outf.write(output_data)
    exit(0)

RECT = '<4H'

def encode_rects(rects):
    from struct import calcsize, pack_into
    count = len(rects)
    rect_size = calcsize(RECT)
    data = bytearray(count * rect_size)
    for i, rect in enumerate(rects):
        pack_into(RECT, data, (i * rect_size),
            rect['x0'], rect['y0'], rect['x1'], rect['y1'])
    return data

def decode_rects(data):
    from struct import calcsize, iter_unpack
    count = len(data) // calcsize(RECT)
    keys = ('x0', 'y0', 'x1', 'y1')
    rects = [ dict(zip(keys, t))
        for t in iter_unpack(RECT, data) ]
    return rects

if __name__ == '__main__':
    import sys
    main(sys.argv)
