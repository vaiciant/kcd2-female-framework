"""Converts the women's clothes of another mod for the woman of KCD2 Female Framework (MAKING_CLOTHES.md).

The woman of the framework plays with Henry's soul, which is a man's, and the game looks for her clothes only in the
Male branch. So a women's garment, of the game or of a mod, has to be copied there, fitted to the man's skeleton. The
framework does it for the game's women's clothes with generate_women.py, and this does the same for another mod, with
the same code.

Your mod adds women's clothes the usual way: their Clothing in the Female branch, in
Libs/Tables/Character/CharacterComponent__<anything>.xml; their meshes under Objects/characters/humans/female/clothing/,
for the women's skeleton; and their items, in Libs/Tables/item/item__<anything>.xml. This writes, in your mod:

- Libs/Tables/Character/CharacterComponent__<modid>_ff.xml: each garment, copied into the Male branch as ml_ff_<name>;
- Libs/Tables/item/item__<modid>_ff.xml: each item, copied as ml_ff_<name>, with the same stats;
- Objects/characters/humans/ml_ff_woman/clothing/: its meshes, fitted to her;
- Scripts/FemaleCore/Clothes/<modid>.lua: the flag that tells the framework the copies are for her. The framework loads
  every file of that folder, and swaps each item for its copy while she is a woman.

Run it again after every change to your clothes: it writes the four over. With --check it changes nothing, and checks
a mod, also one made by hand: that each entry of its Scripts/FemaleCore/Clothes file has its items, that each copy has
its Clothing in the Male branch, and that its meshes are there. It also checks that each node of the game the mod
declares again keeps the game's attributes: a node declared again takes the attributes it is given, for every NPC too,
and a missing ArmorType, HidingGroups or Morphs breaks the men's clothes of the whole game.

Usage, from the root of the framework's repository, with the game's tables extracted (tools/extract_game.py):
    python -I -X utf8 mod/kcd_female_framework/tools/convert_clothes.py <folder of your mod>
    python -I -X utf8 mod/kcd_female_framework/tools/convert_clothes.py <folder of your mod> --check
"""
import copy
import pathlib
import re
import sys
import uuid
import xml.etree.ElementTree as ET

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import generate_women as gw  # noqa: E402  (its functions; it runs nothing when imported)

OUT = "_ff"
GUID_NAMESPACE = "kcd_female_framework/clothes"
FF_COMPONENTS = pathlib.Path("mod/kcd_female_framework/data/Libs/Tables/Character/CharacterComponent__kcd_female_framework.xml")
CLOTHES_FOLDER = "Scripts/FemaleCore/Clothes"
# The women's types whose effect the rules of the framework read: a man takes them off, and a dress takes off a man's
# clothes. The same groups as generate_women.py.
WOMEN_TYPES = {name: group for group, (_, names) in gw.DETECTED_CLOTHES.items() for name in names}


def modid_of(mod):
    found = re.search(r"<modid>\s*(.*?)\s*</modid>", (mod / "mod.manifest").read_text(encoding="utf-8-sig"))
    if not found:
        raise SystemExit(f"{mod / 'mod.manifest'}: no <modid>")
    return found.group(1)


def mod_tables(mod, folder, table, modid):
    """The mod's own patches of a table, without the one this writes."""
    return sorted(p for p in (mod / "data/Libs/Tables" / folder).glob(f"{table}__*.xml")
                  if p.stem.lower() != f"{table}__{modid}{OUT}".lower())


def merge(game, theirs):
    """Adds the nodes of a patch to the game's tree, matching each one by its tag and its name, as the game does."""
    children = theirs.find("DerivedComponents")
    if children is None:
        return
    mine = game.find("DerivedComponents")
    if mine is None:
        mine = ET.SubElement(game, "DerivedComponents")
    for child in children:
        match = next((c for c in mine if c.tag == child.tag and c.get("Name") == child.get("Name")), None)
        if match is None:
            mine.append(copy.deepcopy(child))
        else:
            merge(match, child)


def add_female_patches(mod, modid):
    count = 0
    for path in mod_tables(mod, "Character", "CharacterComponent", modid):
        female = ET.parse(path).getroot().find(".//Component[@Name='Female']")
        if female is not None:
            merge(gw.female, female)
            count += 1
    gw.parents.clear()
    gw.parents.update({child: parent for parent in gw.root.iter() for child in parent})
    return count


def female_node(name):
    return gw.female.find(f".//*[@Name='{name}']")


def mod_items(mod, modid):
    rows = []
    for path in mod_tables(mod, "item", "item", modid):
        classes = ET.parse(path).getroot().find("ItemClasses")
        rows += [row for row in (classes if classes is not None else []) if row.get("Clothing")]
    return rows


def armor_type(name):
    return next((n.get("ArmorType") for n in reversed(gw.chain(female_node(name))) if n.get("ArmorType")), None)


def write_xml(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def convert(mod):
    modid = modid_of(mod)
    vanilla = {n.get("Name") for n in gw.female.iter() if n.get("Name")}
    if not add_female_patches(mod, modid):
        print("No CharacterComponent patch of the mod adds to the Female branch: only its items of the game's clothes.")
    rows = [row for row in mod_items(mod, modid) if female_node(row.get("Clothing")) is not None]
    if not rows:
        raise SystemExit("No item of the mod wears a Clothing of the Female branch: nothing to convert.")
    framework = {n.get("Name") for n in ET.parse(FF_COMPONENTS).getroot().iter() if n.get("Name")}

    # The garments, in the Male branch. One of the game that the framework already copies is not copied again.
    gw.meshes.clear()
    patch = ET.Element(gw.male.tag, gw.male.attrib)
    known = set()
    for name in sorted({row.get("Clothing") for row in rows}):
        if name in vanilla and gw.with_prefix(name) in framework:
            continue
        gw.mount_clothing(patch, name)
        # The nodes above it that the framework already copies keep the framework's meshes: they are not made again.
        for node in gw.chain(female_node(name)):
            if gw.with_prefix(node.get("Name") or "") in framework:
                for element in node.findall("Elements/*"):
                    if element.get("Model"):
                        known.add(("clothing", element.get("Model")))
    gw.meshes.difference_update(known)
    base = ET.Element("database", {"xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "name": "barbora",
                                   "xsi:noNamespaceSchemaLocation": "../database.xsd"})
    base.append(ET.Comment(f" Written by tools/convert_clothes.py of KCD2 Female Framework from the women's clothes of {modid}. "
                           "Change those and run it again, not this file. "))
    ET.SubElement(base, "CharacterComponents", {"version": "6"}).append(patch)
    ET.indent(base, "\t")
    components = mod / f"data/Libs/Tables/Character/CharacterComponent__{modid}{OUT}.xml"
    write_xml(components, '<?xml version="1.0" encoding="utf-8"?>\n' + ET.tostring(base, encoding="unicode") + "\n")

    # The items, and the flag: the file that the framework loads.
    copies, entries = [], []
    for row in sorted(rows, key=lambda r: r.get("Name")):
        name = gw.with_prefix(row.get("Name"))
        guid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{GUID_NAMESPACE}/{modid}/{name}"))
        clone = ET.Element(row.tag, {**row.attrib, "Clothing": gw.with_prefix(row.get("Clothing")), "Id": guid, "Name": name})
        copies.append(f"\t\t{ET.tostring(clone, encoding='unicode')}\n")
        entries.append(f'\t{{ original = "{row.get("Id")}", copy = "{guid}", name = "{row.get("Name")}", copy_name = "{name}" }},\n')
    items = mod / f"data/Libs/Tables/item/item__{modid}{OUT}.xml"
    write_xml(items, '<?xml version="1.0" encoding="utf-8"?>\n<database xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
                     'name="barbora" xsi:noNamespaceSchemaLocation="item.xsd">\n'
                     f"\t<!-- Written by tools/convert_clothes.py of KCD2 Female Framework: the items of {modid} for her. -->\n"
                     f'\t<ItemClasses version="8">\n{"".join(copies)}\t</ItemClasses>\n</database>\n')
    flag = mod / "data" / CLOTHES_FOLDER / f"{modid}.lua"
    write_xml(flag, f"-- Written by tools/convert_clothes.py of KCD2 Female Framework (MAKING_CLOTHES.md): the clothes of {modid}\n"
                    "-- for the woman of the framework. Each item and its copy that she wears: she gets the copy while she is a woman.\n"
                    f'FemaleCore.RegisterClothes({{\n{"".join(entries)}}}, "{modid}")\n')

    # The meshes: the mod's own come before the game's.
    objects = mod / "data/Objects"
    extra = {"objects/" + p.relative_to(objects).as_posix().lower(): p
             for p in objects.rglob("*") if p.suffix.lower() in (".skin", ".chr") and "ml_ff_woman" not in p.parts}
    gw.MESHES_DIR = objects / f"characters/humans/{gw.PREFIX}woman"
    gw.generate_meshes(extra, headgear=False)

    print(f"{len(rows)} items of {modid}: {components.name}, {items.name}, {flag.relative_to(mod).as_posix()} and the meshes "
          f"in {gw.MESHES_DIR.relative_to(mod).as_posix()}")
    for row in rows:
        kind = armor_type(row.get("Clothing"))
        if kind not in WOMEN_TYPES:
            print(f"  {row.get('Name')}: its type, {kind}, is not one of the women's types of the framework, so a man would "
                  "keep it on. Give it one of: " + ", ".join(WOMEN_TYPES))


def lua_entries(mod):
    entries = []
    for path in sorted((mod / "data" / CLOTHES_FOLDER).glob("*.lua")):
        text = path.read_text(encoding="utf-8")
        entries += [(path.name, m[1], m[2]) for m in re.finditer(r'original\s*=\s*"([^"]+)"\s*,\s*copy\s*=\s*"([^"]+)"', text)]
        if "FemaleCore.RegisterClothes" not in text:
            print(f"  {path.name}: it never calls FemaleCore.RegisterClothes")
    return entries


def check(mod):
    """Each entry of the mod's flag file: its items, the Male Clothing of the copy, and that Clothing's meshes."""
    entries = lua_entries(mod)
    if not entries:
        raise SystemExit(f"No entry in {mod / 'data' / CLOTHES_FOLDER}: the framework would take none of its clothes.")
    items = {}
    for path in [gw.TABLES / "item/item.xml", *sorted((mod / "data/Libs/Tables/item").glob("item__*.xml"))]:
        classes = ET.parse(path).getroot().find("ItemClasses")
        items.update({row.get("Id"): row for row in (classes if classes is not None else [])})
    male_nodes = {}
    for path in sorted((mod / "data/Libs/Tables/Character").glob("CharacterComponent__*.xml")):
        tree = ET.parse(path).getroot()
        male = tree.find(".//Component[@Name='Male']")
        if male is None:
            continue
        holder = {child: parent for parent in male.iter() for child in parent}
        for node in male.iter():
            if node.get("Name"):
                male_nodes[node.get("Name")] = (node, holder)
    files = {p.relative_to(mod / "data").as_posix().lower() for p in (mod / "data/Objects").rglob("*.skin")}
    problems = 0
    # The game's nodes that the mod declares again must keep their attributes: the game takes the patch's for them.
    game_nodes = {(n.tag, n.get("Name")): n for n in gw.male.iter() if n.tag in ("Component", "Clothing") and n.get("Name")}
    for name, (node, _) in sorted(male_nodes.items()):
        game_node = game_nodes.get((node.tag, name))
        if game_node is not None and dict(node.attrib) != dict(game_node.attrib):
            changed = sorted(k for k in set(node.attrib) | set(game_node.attrib) if node.get(k) != game_node.get(k))
            print(f"  {name}: a node of the game declared with other attributes ({', '.join(changed)}). The game takes them "
                  "for every NPC: copy the game's attributes as they are")
            problems += 1
    for file_name, original, copy_id in entries:
        if original not in items:
            print(f"  {file_name}: original {original} is in no item table, of the game or of the mod")
            problems += 1
        row = items.get(copy_id)
        if row is None:
            print(f"  {file_name}: copy {copy_id} is in no item table of the mod")
            problems += 1
            continue
        found = male_nodes.get(row.get("Clothing"))
        if found is None:
            print(f"  {row.get('Name')}: its Clothing, {row.get('Clothing')}, is not in the Male branch of the mod's tables")
            problems += 1
            continue
        node, holder = found
        base, walk = None, node
        while walk is not None and base is None:
            base = walk.get("FilePath")
            walk = holder.get(walk)
        for element in node.iter():
            model = element.get("Model")
            if model and model != "dummy":
                path = pathlib.PurePosixPath("objects/characters") / (base or "") / model
                normalized = "/".join(_resolve(path.parts)).lower()
                if normalized not in files:
                    print(f"  {row.get('Name')}: mesh {normalized} is not in the mod")
                    problems += 1
    print(f"{len(entries)} entries checked, {problems} problems")
    return problems


def _resolve(parts):
    out = []
    for part in parts:
        if part == "..":
            out.pop()
        elif part not in ("", "."):
            out.append(part)
    return out


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    if len(args) != 1:
        raise SystemExit(__doc__)
    mod = pathlib.Path(args[0]).resolve()
    if not (mod / "mod.manifest").is_file():
        raise SystemExit(f"{mod}: no mod.manifest, so it is not the folder of a mod")
    if "--check" in sys.argv:
        sys.exit(1 if check(mod) else 0)
    convert(mod)
    check(mod)


if __name__ == "__main__":
    main()
