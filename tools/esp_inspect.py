"""Minimal Fallout 4 plugin reader for inspecting script (VMAD) data.

Usage:
  python -I esp_inspect.py <plugin> find-script <ScriptName>
      Print records whose VMAD attaches the named script, with decoded properties.
  python -I esp_inspect.py <plugin> edid <hexFormID> [...]
      Print editor IDs for form IDs.
  python -I esp_inspect.py <plugin> dump-record <hexFormID>
      Print the raw subrecords of one record.
"""
import struct
import sys
import zlib


def iter_records(data, pos=0, end=None):
    end = len(data) if end is None else end
    while pos < end:
        sig = data[pos:pos + 4]
        size = struct.unpack_from("<I", data, pos + 4)[0]
        if sig == b"GRUP":
            yield from iter_records(data, pos + 24, pos + size)
            pos += size
        else:
            flags, formid = struct.unpack_from("<II", data, pos + 8)
            body = data[pos + 24:pos + 24 + size]
            if flags & 0x40000:
                body = zlib.decompress(body[4:])
            yield sig.decode(), formid, flags, body, data[pos:pos + 24]
            pos += 24 + size


def iter_subrecords(body):
    pos, xxxx = 0, None
    while pos < len(body):
        sig = body[pos:pos + 4].decode()
        size = struct.unpack_from("<H", body, pos + 4)[0]
        pos += 6
        if sig == "XXXX":
            xxxx = struct.unpack_from("<I", body, pos)[0]
            pos += size
            continue
        if xxxx is not None:
            size, xxxx = xxxx, None
        yield sig, body[pos:pos + size]
        pos += size


class Reader:
    def __init__(self, buf):
        self.buf, self.pos = buf, 0

    def take(self, fmt):
        vals = struct.unpack_from("<" + fmt, self.buf, self.pos)
        self.pos += struct.calcsize("<" + fmt)
        return vals if len(vals) > 1 else vals[0]

    def wstr(self):
        n = self.take("H")
        s = self.buf[self.pos:self.pos + n].decode("utf-8", "replace")
        self.pos += n
        return s


def read_value(r, ptype):
    if ptype == 1:
        unused, alias, formid = r.take("HhI")
        return f"Form({formid:08X})"
    if ptype == 2:
        return r.wstr()
    if ptype == 3:
        return r.take("i")
    if ptype == 4:
        return round(r.take("f"), 6)
    if ptype == 5:
        return bool(r.take("B"))
    if ptype == 6:
        inner = r.take("B")
        return read_value(r, inner) if inner else None
    if ptype == 7:
        return read_struct(r)
    if 11 <= ptype <= 17:
        n = r.take("I")
        return [read_value(r, ptype - 10) for _ in range(n)]
    raise ValueError(f"unknown property type {ptype} at {r.pos}")


def read_struct(r):
    members = {}
    for _ in range(r.take("I")):
        name = r.wstr()
        ptype, _status = r.take("BB")
        members[name] = read_value(r, ptype)
    return members


def read_vmad_scripts(vmad):
    r = Reader(vmad)
    _version, _obj_format, count = r.take("hhH")
    scripts = []
    for _ in range(count):
        name = r.wstr()
        _status, nprops = r.take("BH")
        props = {}
        for _ in range(nprops):
            pname = r.wstr()
            ptype, _pstatus = r.take("BB")
            props[pname] = read_value(r, ptype)
        scripts.append((name, props))
    return scripts


def main():
    path, cmd, *args = sys.argv[1:]
    with open(path, "rb") as f:
        data = f.read()
    if cmd == "find-script":
        target = args[0].lower()
        for sig, formid, _, body, _ in iter_records(data):
            subs = dict(iter_subrecords(body)) if b"VMAD" in body else None
            if not subs or "VMAD" not in subs:
                continue
            if target.encode() not in subs["VMAD"].lower():
                continue
            edid = subs.get("EDID", b"").rstrip(b"\0").decode()
            print(f"== {sig} {formid:08X} {edid}")
            try:
                for name, props in read_vmad_scripts(subs["VMAD"]):
                    if name.lower() == target:
                        for k, v in props.items():
                            print(f"  {k} = {v}")
            except Exception as exc:  # fragments etc. follow the script list
                print(f"  (partial decode: {exc})")
    elif cmd == "edid":
        wanted = {int(a, 16) for a in args}
        for sig, formid, _, body, _ in iter_records(data):
            if formid in wanted:
                edid = dict(iter_subrecords(body)).get("EDID", b"").rstrip(b"\0").decode()
                print(f"{formid:08X} {sig} {edid}")
    elif cmd == "dump-record":
        wanted = int(args[0], 16)
        for sig, formid, flags, body, header in iter_records(data):
            if formid == wanted:
                print(f"{sig} {formid:08X} flags={flags:08X} header={header.hex()}")
                for s, v in iter_subrecords(body):
                    print(f"  {s} ({len(v)}): {v[:80].hex()}")


if __name__ == "__main__":
    main()
