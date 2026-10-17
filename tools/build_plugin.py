"""Build SS2LearnOnTheJob.esp: an ESL-flagged plugin holding one start-game-enabled quest
with the AISS2LearnOnTheJob:JobTrainingQuest script attached (no properties; the script looks
SS2 forms up at runtime).

The QUST layout mirrors SS2E_AddonQuest from SS2Extended.esp (SS2 3.8.0): EDID, VMAD,
DNAM (flags 0x0111 = start game enabled + run once, priority 40), NEXT, ANAM.

Usage: python -I tools/build_plugin.py <out.esp>
"""
import struct
import sys

FORM_VERSION = 0x83  # matches records in SS2 3.8.0 plugins
MASTERS = ["Fallout4.esm", "WorkshopFramework.esm", "SS2.esm"]
QUEST_OBJECT_ID = 0x800  # first valid object ID in a light (ESL) plugin
# "AI" = author prefix (AgentIcarus), per Kinggath's SS2 Mod School naming convention
QUEST_EDID = "AISS2LOJ_JobTrainingQuest"
SCRIPT_NAME = "AISS2LearnOnTheJob:JobTrainingQuest"
AUTHOR = "AgentIcarus"
DESCRIPTION = "SS2 settlers slowly train the SPECIAL stat their job uses."

FLAG_ESL = 0x200


def zstring(text):
    return text.encode("cp1252") + b"\0"


def wstring(text):
    raw = text.encode("cp1252")
    return struct.pack("<H", len(raw)) + raw


def subrecord(sig, payload):
    return sig.encode() + struct.pack("<H", len(payload)) + payload


def record(sig, flags, formid, payload):
    return sig.encode() + struct.pack("<IIIIHH", len(payload), flags, formid, 0, FORM_VERSION, 0) + payload


def group(label, payload):
    return b"GRUP" + struct.pack("<I4siHHI", 24 + len(payload), label.encode(), 0, 0, 0, 0) + payload


def build():
    quest_formid = (len(MASTERS) << 24) | QUEST_OBJECT_ID

    # VMAD: version 6, object format 2, one script with no properties, no quest fragments/aliases
    vmad = struct.pack("<hhH", 6, 2, 1) + wstring(SCRIPT_NAME) + struct.pack("<BH", 0, 0)
    quest = b"".join([
        subrecord("EDID", zstring(QUEST_EDID)),
        subrecord("VMAD", vmad),
        subrecord("DNAM", bytes.fromhex("110128000000000000000000")),
        subrecord("NEXT", b""),
        subrecord("ANAM", struct.pack("<I", 0)),
    ])
    quest_group = group("QUST", record("QUST", 0, quest_formid, quest))

    header = [
        # record count includes groups: 1 GRUP + 1 QUST
        subrecord("HEDR", struct.pack("<fII", 1.0, 2, QUEST_OBJECT_ID + 1)),
        subrecord("CNAM", zstring(AUTHOR)),
        subrecord("SNAM", zstring(DESCRIPTION)),
    ]
    for master in MASTERS:
        header += [subrecord("MAST", zstring(master)), subrecord("DATA", struct.pack("<Q", 0))]
    tes4 = record("TES4", FLAG_ESL, 0, b"".join(header))
    return tes4 + quest_group


if __name__ == "__main__":
    with open(sys.argv[1], "wb") as f:
        f.write(build())
