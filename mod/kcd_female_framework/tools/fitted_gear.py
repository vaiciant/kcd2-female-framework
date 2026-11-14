"""The fitted gear: the copies of the men's clothes for her (REFITTING.md, FITTED_GEAR.md).

Cytyryz refits a man's mesh in Blender and saves it in the framework next to where the game has it, under
data/Objects/characters/humans/male/clothing/, with _fffit before .skin: torso/plate/cuirass03/cuirass03_fffit.skin for
the game's torso/plate/cuirass03/cuirass03.skin. Its LODs, if it has them, are _fffit_lod1.skin and _fffit_lod2.skin.
_ffslim works the same way. This tool writes the rest, from the game's tables:

- each piece of the game that wears that mesh gets a copy <name>_ff in CharacterComponent__kcd_female_framework_fitted.xml.
  The copy is a child of the piece, and has its meshes with the refitted one in its place;
- each item of the game with that piece gets a copy <name>_ff in item__kcd_female_framework_fitted.xml, with the same
  stats;
- fitted_gear_data.lua tells the framework each item and its copy: she gets the copy, and a man the game's item;
- FITTED_GEAR.md gets the list of copies;
- REFITTING.md gets the list of the game's meshes still to refit, by garment, with the most worn first.

The men's pieces for the torso that nobody has refitted get a copy too, with the game's meshes. If her torso or her smock
comes through the piece, the copy hides them below the chest, where she is wider than the man (ml_ff_UnderMen,
generate_women.py). The tool measures it with her meshes, which generate_women.py writes: under a loose piece, like
Legate's robe, hiding them only left the inside empty, to be seen through the neckline.
When a refitted mesh comes for one of them, its copy becomes a refitted one with the same id, so a save keeps its items.

A refitted piece is made for her body, and a man's piece is not: together, over or under each other, one came through
the other. Those same copies switch on a morph, ml_ff_men_fit, that takes every refitted piece back to the game's shape:
with a man's piece on, everything she wears goes as a man's. The morph goes in a copy of each refitted mesh,
<name>_ffmen.skin, next to it, and the copies wear that one. The tool makes it from the refitted mesh and the game's, and
git leaves it out, since it carries the game's shape. The pak takes only those copies (tools/build_mod.py).

Run it after every change of meshes: it writes those files and meshes over. With --check it changes nothing, and says what it
would change.

Usage, from the root of the framework's repository, with the game's tables extracted (tools/extract_game.py):
    python -I -X utf8 mod/kcd_female_framework/tools/fitted_gear.py
    python -I -X utf8 mod/kcd_female_framework/tools/fitted_gear.py --check
"""
import copy
import functools
import math
import pathlib
import re
import struct
import sys
import uuid
import xml.etree.ElementTree as ET
import zipfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import generate_women as gw  # noqa: E402  (its constants; it runs nothing when imported)

DATA = pathlib.Path(f"mod/{gw.MOD}/data")
CLOTHING = DATA / "Objects/characters/humans/male/clothing"
COMPONENTS = DATA / "Libs/Tables/Character/CharacterComponent__kcd_female_framework_fitted.xml"
ITEMS = DATA / "Libs/Tables/item/item__kcd_female_framework_fitted.xml"
LUA = DATA / "Scripts/FemaleCore/fitted_gear_data.lua"
DOC = DATA.parent / "FITTED_GEAR.md"
# The list of copies in FITTED_GEAR.md goes between these lines; the rest of the page is written by hand.
LIST_START, LIST_END = "<!-- The copies: written by tools/fitted_gear.py. -->", "<!-- End of the copies. -->"
GUIDE = DATA.parent / "REFITTING.md"
TODO_START, TODO_END = "<!-- Still to refit: written by tools/fitted_gear.py. -->", "<!-- End of the list. -->"
# The parts whose meshes she needs refitted, and the title of each in the list. Hats, helmets and coifs on the head
# take the framework's own morph for her head; her hands and feet sit where Henry's do; belts and scabbards hang.
TODO_PARTS = {"torso": "Torso, arms and skirts", "arms": "Torso, arms and skirts", "waist": "Torso, arms and skirts",
              "legs": "Legs", "neck": "Neck"}
SUFFIX = "_ff"
REFIT = re.compile(r"(.+)_(?:fffit|ffslim)\.skin", re.IGNORECASE)
GUID_NAMESPACE = "kcd_female_framework/fitted"
# Item tables of tests and of deprecated items: nobody gets them in the game.
SKIPPED_ITEM_TABLES = {"item__autotests.xml", "item__test.xml", "item__deprecated.xml"}
# The parts of a piece that go over her torso: a piece with one of them, from a man's mesh, hides her under it.
TORSO_PARTS = ("torso", "waist")
HIDE = gw.UNDER_MEN_GROUP["Name"]
# Her torso and smock, which a man's piece hides when they come through it by more than this, in metres, and from this
# height up to the chest: at the hips the skirt of her smock is hidden by the game's own groups.
HER = (pathlib.Path(f"mod/{gw.MOD}/data/Objects/characters/humans/ml_ff_woman/body/female_body_01_torso.skin"),
       pathlib.Path(f"mod/{gw.MOD}/data/Objects/characters/humans/ml_ff_woman/clothing/f_torso/f_dress/f_smock01/f_smock01_top.skin"))
COMES_THROUGH, HER_FROM = 0.005, 0.95
# The cells of the comparison: by height and by angle around the body's axis.
CELL_HEIGHT, CELL_ANGLE = 0.01, 0.06
NO_MESH = ("", "dummy")
# The copy of each refitted mesh with the morph back to the game's shape, for when she wears a man's piece that is not
# refitted (U429 for the hoods, U431 for all).
MEN_FIT = "_ffmen"
# The game widens the hoods over padded clothes with this morph, but some pieces of that family declare their own morphs
# without it, like the short pourpoint (GambesonShort03). The hood in the game's shape crossed their shoulders, up to
# 7 cm; with it, in 2 or 3 points of the shoulders. Their copies switch it on again.
HOOD_PADDED = "#extend_hood_cloth_padded"
LOD = re.compile(r"(.+)_(?:fffit|ffslim)(_lod\d)\.skin", re.IGNORECASE)


def derived(node):
    holder = node.find("DerivedComponents")
    return list(holder) if holder is not None else []


def own_elements(node):
    holder = node.find("Elements")
    return list(holder) if holder is not None else []


game = ET.parse(gw.TABLES / "Character/CharacterComponent.xml").getroot().find("CharacterComponents")
male = game.find("Component[@Name='Male']")
parent_of = {child: parent for parent in male.iter() for child in derived(parent)}
by_name = {}
for node in male.iter():
    if node.get("Name") and node.tag != "Elements":
        by_name.setdefault(node.get("Name"), []).append(node)


def path_of(node):
    """The nodes from Male down to node."""
    nodes = []
    while node is not None:
        nodes.append(node)
        node = parent_of.get(node)
    return nodes[::-1]


def merged(old, new):
    """An element of a node over the one of its parent: the game takes the parent's attributes it does not give."""
    if old is None or old.tag != new.tag:
        return copy.deepcopy(new)
    out = ET.Element(new.tag, {**old.attrib, **new.attrib})
    out.extend(copy.deepcopy(child) for child in (list(new) or list(old)))
    return out


def resolved(node):
    """The meshes of a piece, one per part, and its joints, as the game puts them together from its parents."""
    meshes, joints = {}, {}
    for step in path_of(node):
        for element in own_elements(step):
            if element.tag == "JointElement":
                joints[element.get("Name")] = merged(joints.get(element.get("Name")), element)
            elif element.get("EquipmentPart"):
                meshes[element.get("EquipmentPart")] = merged(meshes.get(element.get("EquipmentPart")), element)
    return meshes, joints


def inherited(node, attribute):
    return next((step.get(attribute) for step in reversed(path_of(node)) if step.get(attribute) is not None), None)


def refitted_meshes():
    """Each refitted mesh on disk, by the path of the game's mesh it replaces, in lowercase."""
    found = {}
    for file in sorted(CLOTHING.rglob("*.skin")):
        match = REFIT.fullmatch(file.name)
        if match:
            relative = file.relative_to(CLOTHING).as_posix()
            original = f"{relative[:-len(file.name)]}{match.group(1)}.skin".lower()
            if original in found:
                raise SystemExit(f"Two refitted meshes for {original}: {found[original]} and {relative}")
            found[original] = relative
    return found


def current_files():
    """What the files have now: the ids of the copies, the place of each copy, and the items whose original is not in the
    game's tables (the hoods up, from a newer version of the game), which are kept as they are."""
    ids, places, rows, pairs, names = {}, {}, [], {}, {}
    if ITEMS.exists():
        rows = [row for row in ET.parse(ITEMS).getroot().iter() if row.get("Id") and row.get("Name")]
        ids = {row.get("Name"): row.get("Id") for row in rows}
    if COMPONENTS.exists():
        table = ET.parse(COMPONENTS).getroot().find("CharacterComponents")

        def walk(node, names_above):
            for child in derived(node):
                if child.get("Name", "").endswith(SUFFIX):
                    places[child.get("Name")[:-len(SUFFIX)]] = tuple(names_above + [node.get("Name")])
                walk(child, names_above + [node.get("Name")])
        for top in table:
            walk(top, [])
    if LUA.exists():
        text = LUA.read_text(encoding="utf-8")
        pairs = dict(re.findall(r'\["([0-9a-f-]{36})"\] = "([0-9a-f-]{36})"', text))
        names = dict(re.findall(r'\["([0-9a-f-]{36})"\] = "([^"]+)",\n', text))
    return ids, places, rows, pairs, names


def cell(point):
    return round(point[2] / CELL_HEIGHT), round(math.atan2(point[1], point[0]) / CELL_ANGLE)


@functools.cache
def her_points():
    points = []
    for path in HER:
        if not path.exists():
            raise SystemExit(f"Her meshes are not there: {path}. Run tools/generate_women.py first.")
        points += [p for p in positions(path.read_bytes()) if HER_FROM <= p[2] <= gw.UNDER_MEN_HEIGHT]
    return points


@functools.cache
def comes_through(models):
    """Whether her torso or smock comes out of the game's meshes of a piece: around the body's axis, at each height and
    angle, she is further out than the piece."""
    outer = {}
    for model in models:
        pak, name = game_meshes()[model]
        with zipfile.ZipFile(pak) as archive:
            for point in positions(archive.read(name)):
                key = cell(point)
                outer[key] = max(outer.get(key, 0.0), math.hypot(point[0], point[1]))
    angles = round(math.pi / CELL_ANGLE)
    for point in her_points():
        height, angle = cell(point)
        around = [outer.get((height + dz, (angle + da + angles) % (2 * angles) - angles)) for dz in (-1, 0, 1) for da in (-1, 0, 1)]
        around = [radius for radius in around if radius is not None]
        if around and math.hypot(point[0], point[1]) - max(around) > COMES_THROUGH:
            return True
    return False


def worn(refit):
    """The mesh a copy wears for a refitted mesh: its copy with the morph back to the game's shape."""
    return REFIT.sub(lambda match: match.group(1) + MEN_FIT + ".skin", refit)


@functools.cache
def game_meshes():
    """Where each mesh of the game's men's clothes is, by its path under the clothing folder, in lowercase."""
    found, prefix = {}, gw.GAME_PATH + "male/clothing/"
    for pak in sorted((gw.GAME / "Data").glob("*Characters*.pak")):
        with zipfile.ZipFile(pak) as archive:
            for name in archive.namelist():
                normalized = name.replace("\\", "/").lower()
                if normalized.startswith(prefix) and normalized.endswith(".skin"):
                    found[normalized[len(prefix):]] = (pak, name)
    return found


def positions(data):
    start, count, _ = gw.read_streams(data)[gw.STREAM_POSITION]
    return [struct.unpack_from("<3f", data, start + i * 12) for i in range(count)]


def men_fit_meshes(refits):
    """The copy of each refitted mesh with the morph back to the game's shape: what each vertex moves from where the
    refit put it to where the game has it. Its LODs go as they are, since the LODs have no morphs."""
    out = {}
    if not refits:
        return out
    meshes = game_meshes()
    for original, refit in sorted(refits.items()):
        if original not in meshes:
            raise SystemExit(f"The game has no {original}, for {refit}")
        pak, name = meshes[original]
        with zipfile.ZipFile(pak) as archive:
            game_points = positions(archive.read(name))
        data = (CLOTHING / refit).read_bytes()
        refit_points = positions(data)
        if len(game_points) != len(refit_points):
            raise SystemExit(f"{refit} has {len(refit_points)} vertices and the game's mesh {len(game_points)}: the morph "
                             "back to the game's shape needs the same vertices, in the same order")
        moves = [tuple(g[axis] - r[axis] for axis in range(3)) for g, r in zip(game_points, refit_points)]
        out[CLOTHING / worn(refit)] = gw.add_morph(data, gw.MEN_FIT_MORPH, None, moves)
        for lod in sorted((CLOTHING / refit).parent.glob("*.skin")):
            match = LOD.fullmatch(lod.name)
            if match and lod.name.lower().startswith(pathlib.PurePosixPath(refit).stem.lower() + "_lod"):
                out[lod.with_name(match.group(1) + MEN_FIT + match.group(2) + ".skin")] = lod.read_bytes()
    return out


def node_for(name, places):
    """The piece of the game with that name. The game repeats some names: then, the one the table already copies."""
    nodes = [node for node in by_name.get(name, []) if node.tag == "Clothing"]
    if len(nodes) == 1:
        return nodes[0]
    place = places.get(name)
    for node in nodes:
        if place and tuple(step.get("Name") for step in path_of(node)) == place:
            return node
    return None


def game_items():
    """The rows of the game's items, by name, in the order of their tables."""
    rows = {}
    for table in sorted((gw.TABLES / "item").glob("item*.xml")):
        if table.name in SKIPPED_ITEM_TABLES:
            continue
        for row in ET.parse(table).getroot().iter():
            if row.get("Id") and row.get("Name") and row.get("Clothing"):
                rows.setdefault(row.get("Name"), row)
    return rows


def the_copy(node, refits):
    """The copy of a piece, or None if she needs none: what is refitted takes the refitted mesh, and a man's mesh over her
    torso hides her under it. A refitted piece that keeps a man's mesh on her body goes as a man's too: Legate's robe has
    a refitted torso with the game's arms, and the seam opened 3 to 5 cm by the neck. Under a man's piece her body
    does not come through, her torso stays: the game's robe takes the body away under it, since the legate wears it over
    his tunic, and its neckline showed the inside of the robe below her neck."""
    meshes, joints = resolved(node)
    real = {part for part, mesh in meshes.items() if (mesh.get("Model") or "").lower() not in NO_MESH}
    refitted = {part for part, mesh in meshes.items() if (mesh.get("Model") or "").lower() in refits}
    hides = [part for part in TORSO_PARTS if part in real and part not in refitted]
    mixed = refitted and any(part in TODO_PARTS and part not in refitted for part in real)
    if not refitted and not hides:
        return None, None
    attributes = {"Name": node.get("Name") + SUFFIX}
    keeps_body = False
    if hides or mixed:
        body = tuple(sorted(meshes[part].get("Model").lower() for part in TORSO_PARTS if part in real
                            and meshes[part].get("Model").lower().endswith(".skin")))
        if body and comes_through(body):
            groups = (inherited(node, "HidingGroups") or "").split()
            attributes["HidingGroups"] = " ".join(groups + [HIDE])
        else:
            keeps_body = "torso" in real
        morphs = (inherited(node, "Morphs") or "").split()
        family = {morph for step in path_of(node) for morph in (step.get("Morphs") or "").split()}
        if HOOD_PADDED in family and HOOD_PADDED not in morphs:
            morphs.append(HOOD_PADDED)
        attributes["Morphs"] = " ".join(morphs + [gw.MEN_FIT_MORPH])
    out = ET.Element("Clothing", attributes)
    if keeps_body:
        meshes["torso"].set("KeepBodyLayer", "true")
    if refitted:
        elements = ET.SubElement(out, "Elements")
        for part, mesh in meshes.items():
            if part in refitted:
                mesh.set("Model", worn(refits[mesh.get("Model").lower()]))
            elements.append(mesh)
        elements.extend(joints.values())
    elif keeps_body:
        ET.SubElement(out, "Elements").append(meshes["torso"])
    return out, "refitted" if refitted else "game"


def item_copy(row, guid):
    attributes = {}
    for key, value in row.attrib.items():
        attributes[key] = {"Clothing": value + SUFFIX, "Id": guid, "Name": row.get("Name") + SUFFIX}.get(key, value)
    out = ET.Element(row.tag, attributes)
    out.extend(copy.deepcopy(child) for child in row)
    return out


def component_table(copies):
    """The game's nodes down to each piece, with the game's own attributes and elements, and the copies below them. A
    node declared again takes the attributes it is given, for every NPC too: they go as the game has them."""
    below = {}
    for original, node in copies:
        below.setdefault(original, []).append(node)
    wanted = {step for original in below for step in path_of(original)}

    def rebuild(node):
        out = ET.Element(node.tag, node.attrib)
        out.extend(copy.deepcopy(child) for child in node if child.tag != "DerivedComponents")
        children = [rebuild(child) for child in derived(node) if child in wanted] + below.get(node, [])
        if children:
            ET.SubElement(out, "DerivedComponents").extend(children)
        return out

    base = ET.Element("database", {"xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "name": "barbora",
                                   "xsi:noNamespaceSchemaLocation": "../database.xsd"})
    base.append(ET.Comment(" Generated by tools/fitted_gear.py from the game's tables and the refitted meshes "
                           "(FITTED_GEAR.md). Each node of the game keeps the game's own attributes: only the _ff copies "
                           "below them are new. "))
    table = ET.SubElement(base, "CharacterComponents")
    table.append(rebuild(male))
    ET.indent(base, "\t")
    return '<?xml version="1.0" encoding="utf-8"?>\n' + ET.tostring(base, encoding="unicode") + "\n"


def item_table(rows):
    base = ET.Element("database", {"xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "name": "barbora",
                                   "xsi:noNamespaceSchemaLocation": "item.xsd"})
    ET.SubElement(base, "ItemClasses", {"version": "8"}).extend(rows)
    ET.indent(base, "\t")
    return '<?xml version="1.0" encoding="us-ascii"?>\n' + ET.tostring(base, encoding="unicode") + "\n"


def lua_data(entries):
    lines = [
        "-- Generated by tools/fitted_gear.py from the game's tables and the refitted meshes (FITTED_GEAR.md): run it",
        "-- again, do not edit this file. Each item of the game and its copy for her, with the same stats and _ff at the",
        "-- end of its name. A refitted copy has the meshes Cytyryz fitted to her body; the others have the game's, and hide",
        "-- her torso under them if it comes through. The loader adds them to FemaleCore.CLOTHES, so they swap as her dresses",
        "-- do, and back for a man.",
        "FemaleCore.FITTED_GEAR = {",
    ]
    lines += [f'\t["{original}"] = "{guid}", -- {name} ({kind})' for original, guid, name, kind in entries]
    lines += ["}", "-- The name of each piece of the game, for ml_ff_fitted_give and ml_ff_npc_dress.", "FemaleCore.FITTED_GEAR_NAMES = {"]
    lines += [f'\t["{original}"] = "{name}",' for original, guid, name, kind in entries]
    lines += ["}"]
    return "\n".join(lines) + "\n"


def doc_with_list(entries):
    """FITTED_GEAR.md with the names of the copies, the refitted ones and the others."""
    text = DOC.read_text(encoding="utf-8")
    if LIST_START not in text or LIST_END not in text:
        raise SystemExit(f"{DOC} has lost the lines that mark the list of copies: {LIST_START} and {LIST_END}")
    blocks = []
    for kind, title in (("refitted", "Refitted"), ("game", "With the game's mesh")):
        names = sorted(f"{name}{SUFFIX}" for _, _, name, k in entries if k == kind)
        blocks.append(f"**{title}:** {len(names)}\n\n```text\n" + "\n".join(names) + "\n```")
    head, rest = text.split(LIST_START, 1)
    return head + LIST_START + "\n\n" + "\n\n".join(blocks) + "\n\n" + LIST_END + rest.split(LIST_END, 1)[1]


def garment_of(model):
    """The garment of a mesh, from its folder: gambesonshort02 for gambesonshort02_torso and gambesonshort02_arms."""
    return re.sub(r"_(torso|arms|waist|legs|neck|up)$", "", model.split("/")[-2])


def guide_with_list(missing):
    """REFITTING.md with the game's meshes nobody has refitted, by garment and by the items that wear them."""
    text = GUIDE.read_text(encoding="utf-8")
    if TODO_START not in text or TODO_END not in text:
        raise SystemExit(f"{GUIDE} has lost the lines that mark the list: {TODO_START} and {TODO_END}")
    garments = {}
    for model, (part, items) in missing.items():
        garment = garments.setdefault(garment_of(model), {"meshes": [], "items": set()})
        garment["meshes"].append((list(TODO_PARTS).index(part), model))
        garment["items"].update(items)
    sections = {}
    for name, garment in garments.items():
        sections.setdefault(TODO_PARTS[list(TODO_PARTS)[min(garment["meshes"])[0]]], []).append((name, garment))
    items = set().union(*(garment["items"] for garment in garments.values())) if garments else set()
    blocks = [f"{len(missing)} meshes of {len(garments)} garments, worn by {len(items)} items."]
    for title in dict.fromkeys(TODO_PARTS.values()):
        listed = sorted(sections.get(title, []), key=lambda entry: (-len(entry[1]["items"]), entry[0]))
        if not listed:
            continue
        lines = [f"### {title}", ""]
        for name, garment in listed:
            example = min(garment["items"])
            meshes = ", ".join(f"`{model}`" for _, model in sorted(garment["meshes"]))
            lines.append(f"- **{name}**, {len(garment['items'])} items, like `{example}`: {meshes}")
        blocks.append("\n".join(lines))
    head, rest = text.split(TODO_START, 1)
    return head + TODO_START + "\n\n" + "\n\n".join(blocks) + "\n\n" + TODO_END + rest.split(TODO_END, 1)[1]


def build():
    refits = refitted_meshes()
    ids, places, old_rows, old_pairs, old_names = current_files()
    items = game_items()
    copies, kinds, rows, entries, used = [], {}, [], [], set()

    def copy_of(node):
        if node not in kinds:
            made, kind = the_copy(node, refits)
            kinds[node] = kind
            if made is not None:
                copies.append((node, made))
                used.update(element.get("Model").lower() for element in made.iter() if element.get("Model"))
        return kinds[node]

    missing = {}
    for name, row in items.items():
        node = node_for(row.get("Clothing"), places)
        if node is None or path_of(node)[1].get("Name") != "Clothing":
            continue
        for part, mesh in resolved(node)[0].items():
            model = (mesh.get("Model") or "").lower()
            if part in TODO_PARTS and model.endswith(".skin") and model not in refits:
                missing.setdefault(model, (part, []))[1].append(name)
        kind = copy_of(node)
        if kind is None:
            continue
        guid = ids.get(name + SUFFIX) or str(uuid.uuid5(uuid.NAMESPACE_URL, f"{GUID_NAMESPACE}/{name}"))
        rows.append(item_copy(row, guid))
        entries.append((row.get("Id"), guid, name, kind))

    # Items of the table that the game's tables do not have: kept as they are, if their piece is copied.
    copied = {guid for _, guid, _, _ in entries}
    originals = {guid: original for original, guid in old_pairs.items()}
    kept = 0
    for row in old_rows:
        if row.get("Id") in copied or row.get("Id") not in originals:
            continue
        node = node_for(row.get("Clothing")[:-len(SUFFIX)], places)
        kind = copy_of(node) if node is not None else None
        if kind is None:
            print(f"Dropped {row.get('Name')}: its piece is not in the game's tables, or has nothing to copy")
            continue
        rows.append(copy.deepcopy(row))
        original = originals[row.get("Id")]
        entries.append((original, row.get("Id"), old_names.get(original, row.get("Name")[:-len(SUFFIX)]), kind))
        kept += 1

    unused = sorted(refit for original, refit in refits.items() if worn(refit).lower() not in used)
    files = {COMPONENTS: component_table(copies), ITEMS: item_table(rows), LUA: lua_data(entries), DOC: doc_with_list(entries),
             GUIDE: guide_with_list(missing)}
    files.update(men_fit_meshes(refits))
    summary = {kind: sum(1 for _, _, _, k in entries if k == kind) for kind in ("refitted", "game")}
    pieces = {kind: sum(1 for k in kinds.values() if k == kind) for kind in ("refitted", "game")}
    hiding = sum(1 for _, made in copies if HIDE in (made.get("HidingGroups") or ""))
    print(f"Refitted: {summary['refitted']} items, {pieces['refitted']} pieces. With the game's mesh: {summary['game']} items, "
          f"{pieces['game']} pieces. Hiding her torso: {hiding} pieces. Kept from the table: {kept}. Refitted meshes: {len(refits)}, unused: {len(unused)}. "
          f"Still to refit: {len(missing)} meshes")
    for refit in unused:
        print(f"  No piece of the game wears the mesh of {refit}")
    return files


def main():
    check = "--check" in sys.argv[1:]
    files = build()
    files = {path: content if isinstance(content, bytes) else content.encode("utf-8") for path, content in files.items()}
    stale = [path for path, content in files.items() if not path.exists() or path.read_bytes() != content]
    if check:
        for path in stale:
            print(f"Not up to date: {path}. Run the tool without --check.")
        return 1 if stale else 0
    for path in stale:
        path.write_bytes(files[path])
        print(f"Written: {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
