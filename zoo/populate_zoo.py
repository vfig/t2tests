import sys

mis_data = bytearray(open("zoo_models_original.mis", "rb").read())
bin_names = list(filter(None, sorted(open("binlist.txt").read().splitlines())))
placeholder = b'PLACHOLD'

# Here we replace bad bin names:
bad_bin_names = set([
    'droplet',
    ])
for i in range(len(bin_names)):
    if bin_names[i] in bad_bin_names:
        bin_names[i] = 'NORTYBOY'

def patch_mission():
    def pad_name(name):
        return bytes(name, 'ascii').ljust(8, b'\0')

    start_index = 0
    for bin_name in bin_names:
        index = mis_data.find(placeholder, start_index)
        if index == -1:
            print(f"Not enough placeholders! Got as far as {bin_name}")
            break
        assert len(bin_name) <= 8
        mis_data[index:index + 8] = pad_name(bin_name)
        start_index = index + 8

    with open("zoo_models_replaced.mis", "wb") as mis_file:
        mis_file.write(mis_data)

def binary_search_next(search_space, last_search, forward):
    npot = 2**32
    while search_space < npot:
        npot //= 2
    if last_search == -1:
        return npot // 2
    next_search = last_search

    while True:
        # find the last one bit
        mask = 1
        while mask < npot:
            if (next_search & mask) != 0: break
            mask *= 2
        # if there is no one bit, we're done
        if mask == npot: return -1
        # if it was bad, we need to zero it
        if not forward:
            next_search &= ~mask
        # then we set the next lowest bit
        mask //= 2
        # if there is no next lowest bit, we're done
        if not mask:
            return -1
        next_search |= mask
        # if this index is too far forward, need to back
        # up until we find something we can use
        if next_search >= search_space:
            forward = False
            # and loop around
        else:
            return next_search


def test_binary_search():
    import random
    s = 1024
    x = binary_search_next(s, -1, True)
    while True:
        good = random.choice([True, False])
        print(x, good, bin(x))
        x = binary_search_next(s, x, good)
        if x == -1: break
    sys.exit(0)


if len(sys.argv) == 2 or len(sys.argv) == 3:
    judgement = sys.argv[1]
    if len(sys.argv) == 3:
        last_bin = sys.argv[2] 
        index = bin_names.index(last_bin)
    else:
        last_bin = "~~~~"
        index = -1
    if judgement == "good" or judgement == "bad":
        index = binary_search_next(len(bin_names), index, (judgement == "good"))
        if index == -1:
            print("Run out of search space.")
            sys.exit(1)
        upto = bin_names[index]
        bin_names = bin_names[:(index+1)]
        print(f"Patching bin names up to: {upto}")
        patch_mission()
    else:
        print("I don't understand your judgement.")
        sys.exit(1)
elif len(sys.argv) == 1:
    patch_mission()
else:
    print("I don't understand the arguments.")
    sys.exit(1)

