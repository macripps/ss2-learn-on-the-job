"""Minimal Fallout 4 BA2 (GNRL) extractor.

Usage: python -I ba2_extract.py <archive.ba2> <out_dir> [path_filter_regex]
Lists/extracts files whose archive path matches the regex (default: scripts).
"""
import os
import re
import struct
import sys
import zlib


def read_entries(f):
    magic, version, kind, count, names_off = struct.unpack("<4sI4sIQ", f.read(24))
    if magic != b"BTDX" or kind != b"GNRL":
        raise SystemExit(f"Unsupported archive: {magic} {kind}")
    if version in (2, 3):
        f.read(8 if version == 2 else 12)
    records = [struct.unpack("<I4sIIQIII", f.read(36)) for _ in range(count)]
    f.seek(names_off)
    names = []
    for _ in range(count):
        (n,) = struct.unpack("<H", f.read(2))
        names.append(f.read(n).decode("utf-8", "replace").replace("\\", "/"))
    return list(zip(names, records))


def main():
    archive, out_dir = sys.argv[1], sys.argv[2]
    pattern = re.compile(sys.argv[3] if len(sys.argv) > 3 else r"(?i)^scripts/", re.I)
    out_root = os.path.realpath(out_dir)
    extracted = 0
    with open(archive, "rb") as f:
        for name, (_, _, _, _, offset, packed, unpacked, _) in read_entries(f):
            if not pattern.search(name):
                continue
            dest = os.path.realpath(os.path.join(out_root, name))
            if not dest.startswith(out_root + os.sep):
                print(f"skipping unsafe path {name}")
                continue
            f.seek(offset)
            data = f.read(packed or unpacked)
            if packed:
                data = zlib.decompress(data)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as out:
                out.write(data)
            extracted += 1
    print(f"{archive}: extracted {extracted} files")


if __name__ == "__main__":
    main()
