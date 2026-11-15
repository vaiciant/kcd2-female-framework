"""A face pack: the faces of another mod for KCD2 Female Framework (MAKING_FACES.md).

The mod has a faces.toml at its root. This tool writes into that mod what the framework needs to put its faces on Henry,
next to the framework's own looks and without changing the framework's files:

- its tokens, one per face, in data/Libs/Tables/item/item__<pack>.xml;
- its Skald project, data/Quests/<pack>.xml, with one module: each face has a state that its token turns on and the
  framework's reset turns off, that answers the framework's question with its id, and that puts the face's head and body
  on Henry while it is on. The framework's own project does the rest (its outside token: a woman, her shift and her
  clothes rules);
- its Lua, data/Scripts/FemaleCore/Looks/<pack>.lua, which registers the faces with FemaleCore.RegisterLooks;
- mod.manifest, if the mod has none yet.

A face takes a head that the framework already has (ml_ff_head_*: LOOKS.md lists them) or a head of your own (head_mesh
and material), and a body of the framework (ml_ff_body_*). A head of your own is a woman's head on the game's female
skeleton: the tool fits it to the player's skeleton, as the framework fits the game's women's heads, and writes it into
data/Objects/characters/humans/<pack>/head/<face>/ with its LODs and its poses, and its node into
data/Libs/Tables/Character/CharacterComponent__<pack>.xml.

The ids are those of the save, shared by both frameworks: a pack takes a block of ten between 200 and 499, by its name or
the block that faces.toml asks for. Two packs on the same block clash, and the framework leaves out the second one.

Usage, from the root of the framework's repository:
    python -I -X utf8 mod/kcd_female_framework/tools/make_face_pack.py path/to/your_mod
"""
import pathlib
import re
import sys
import tomllib
import uuid
import xml.etree.ElementTree as ET
import zipfile
import zlib

FRAMEWORK = pathlib.Path("mod/kcd_female_framework/data")
LOOKS_DATA = FRAMEWORK / "Scripts/FemaleCore/looks_data.lua"
COMPONENTS = FRAMEWORK / "Libs/Tables/Character/CharacterComponent__kcd_female_framework.xml"
ITEMS = FRAMEWORK / "Libs/Tables/item/item__kcd_female_framework.xml"
# Henry's soul, as the framework's own project has it (tools/generate_models.py, HENRY_SOUL).
HENRY_SOUL = "4c2dcffb-dea1-6263-72d7-b39f4db2d8b5"
FIRST_ID, LAST_ID, BLOCK = 200, 499, 10
BLOCKS = (LAST_ID - FIRST_ID + 1) // BLOCK
HAIR_COLORS = ["dark_brown", "black", "light_brown", "blonde", "ginger", "dark_ginger", "dark_grey", "grey", "white"]
# The barber's styles and how many of the colors each has: style 3 only the first six.
HAIR_STYLES = {1: 9, 2: 9, 3: 6, 4: 9, 5: 9, 6: 9, 7: 9}
NAME = re.compile(r"[a-z][a-z0-9_]*")


def framework_value(name):
    match = re.search(rf'^FemaleCore\.{name} = "([0-9a-f-]+)"', LOOKS_DATA.read_text(encoding="utf-8"), re.M)
    if not match:
        raise SystemExit(f"{LOOKS_DATA} has no {name}: run the tool from the root of the framework's repository")
    return match.group(1)


def framework_parts():
    text = COMPONENTS.read_text(encoding="utf-8")
    heads = set(re.findall(r'<Head Name="(ml_ff_head_[^"]+)"', text))
    bodies = set(re.findall(r'<Body Name="(ml_ff_body_[^"]+)"', text))
    return heads, bodies


def token_row(guid, name):
    template = re.search(r'\t\t<MiscItem [^\n]*Name="ml_ff_set_\d+" />', ITEMS.read_text(encoding="utf-8")).group(0)
    return re.sub(r'Id="[^"]+" Name="[^"]+"', f'Id="{guid}" Name="{name}"', template)


def read_faces(mod):
    path = mod / "faces.toml"
    if not path.exists():
        raise SystemExit(f"{path} is not there: MAKING_FACES.md shows how to write it")
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    pack = data.get("pack", {})
    pack_id = pack.get("id", "")
    if not NAME.fullmatch(pack_id):
        raise SystemExit("faces.toml: [pack] id is the id of your mod, in lowercase letters, digits and _")
    faces = data.get("face", [])
    if not 1 <= len(faces) <= BLOCK:
        raise SystemExit(f"faces.toml: a pack has from 1 to {BLOCK} faces")
    return pack, faces


def check_face(face, heads, bodies, mod, pack_id):
    name = face.get("name", "")
    problems = []
    if not NAME.fullmatch(name):
        problems.append("its name is in lowercase letters, digits and _")
    if face.get("head_mesh"):
        # A head of your own: the tool fits it and writes its node (own_head).
        mesh, material = mod / face["head_mesh"], mod / face.get("material", "")
        if not mesh.is_file():
            problems.append(f"head_mesh {face['head_mesh']} is not in your mod")
        elif mesh.parent.resolve() == head_folder(mod, pack_id, face).resolve():
            problems.append(f"keep the files of your head out of {head_folder(mod, pack_id, face)}: the tool writes its head there")
        if not face.get("material") or not material.is_file():
            problems.append("a head of your own needs its material: material = path of its .mtl in your mod")
        face["head"] = f"{pack_id}_head_{name}"
    elif face.get("head") not in heads:
        problems.append(f"head {face.get('head')} is not a head of the framework (ml_ff_head_*, LOOKS.md)")
    if face.get("body") not in bodies:
        problems.append(f"body {face.get('body')} is not a body of the framework (ml_ff_body_*)")
    style, color = face.get("hair", 1), face.get("color", "dark_brown")
    if style not in HAIR_STYLES:
        problems.append("hair is a style from 1 to 7")
    elif color not in HAIR_COLORS[:HAIR_STYLES[style]]:
        problems.append(f"color of style {style} is one of {', '.join(HAIR_COLORS[:HAIR_STYLES[style]])}")
    if problems:
        raise SystemExit(f"faces.toml, face {name or '?'}: " + "; ".join(problems))
    return style, HAIR_COLORS.index(color) + 1


def skald_module(pack_id, faces, reset, ask, answer):
    def descriptor(name, guid, y):
        return (f'\t\t\t\t<Function Name="{name}_descriptor" PositionY="{y}" PositionX="-900" MethodName="wh::entitymodule::CreateItemClassDescriptor" DeclaringType="wh::entitymodule">\n'
                f'\t\t\t\t\t<Constant Name="ItemClass" Value="{guid}" />\n\t\t\t\t\t<Constant Name="Amount" Value="1" />\n\t\t\t\t</Function>\n'
                f'\t\t\t\t<ItemDescriptorTrigger Name="{name}_token" PositionY="{y}" PositionX="-600">\n'
                '\t\t\t\t\t<Edge From="henry.Inventory" To="Inventory" />\n'
                f'\t\t\t\t\t<Edge From="{name}_descriptor.ItemDescriptor" To="ItemDescriptor" />\n'
                '\t\t\t\t\t<Edge From="always_on.State" To="IsActive" />\n\t\t\t\t</ItemDescriptorTrigger>\n')
    nodes = ('\t\t\t\t<ObjectProperties Name="henry" PositionY="0" PositionX="-1200" DeclaringType="wh::rpgmodule::I_Soul">\n'
             '\t\t\t\t\t<Asset Name="I_Soul" Alias="henry" />\n\t\t\t\t</ObjectProperties>\n'
             '\t\t\t\t<State Name="always_on" PositionY="-150" PositionX="-1200" TypeT="bool">\n'
             '\t\t\t\t\t<Constant Name="DefaultValue" Value="true" />\n\t\t\t\t</State>\n'
             + descriptor("reset", reset, -300) + descriptor("ask", ask, -450))
    for n, face in enumerate(faces):
        i, y = face["id"], 200 * n
        nodes += (descriptor(f"set_{i}", face["token"], y).replace(f'Name="set_{i}_token"', f'Name="set_token_{i}"')
                  .replace(f'set_{i}_token.', f'set_token_{i}.')
                  + f'\t\t\t\t<State Name="chosen_{i}" PositionY="{y}" PositionX="-300" TypeT="bool">\n'
                  '\t\t\t\t\t<Constant Name="DefaultValue" Value="false" />\n'
                  f'\t\t\t\t\t<Edge From="set_token_{i}.OnAcquire" To="SetTrue" />\n'
                  '\t\t\t\t\t<Edge From="reset_token.OnAcquire" To="SetFalse" />\n\t\t\t\t</State>\n'
                  f'\t\t\t\t<If Name="answer_if_{i}" PositionY="{y}" PositionX="300">\n'
                  f'\t\t\t\t\t<Edge From="chosen_{i}.State" To="Condition" />\n'
                  '\t\t\t\t\t<Edge From="ask_token.OnAcquire" To="Exec" />\n\t\t\t\t</If>\n'
                  f'\t\t\t\t<EventFunction Name="answer_{i}" PositionY="{y}" PositionX="600" MethodName="wh::entitymodule::CreatePlayerReward" DeclaringType="wh::entitymodule">\n'
                  f'\t\t\t\t\t<Constant Name="ItemClass" Value="{answer}" />\n\t\t\t\t\t<Constant Name="Amount" Value="{i}" />\n'
                  '\t\t\t\t\t<Constant Name="ShowUINotification" Value="false" />\n'
                  f'\t\t\t\t\t<Edge From="answer_if_{i}.True" To="Exec" />\n\t\t\t\t</EventFunction>\n'
                  + "".join(
                      f'\t\t\t\t<BodyPartOverride Name="{part}_{i}" PositionY="{y + 70 * k}" PositionX="0">\n'
                      '\t\t\t\t\t<Asset Name="Soul" Alias="henry" />\n'
                      f'\t\t\t\t\t<Constant Name="BodyPart" Value="{part.capitalize()}" />\n'
                      f'\t\t\t\t\t<Constant Name="Component" Value="{face[part]}" />\n'
                      f'\t\t\t\t\t<Edge From="chosen_{i}.State" To="IsActive" />\n\t\t\t\t</BodyPartOverride>\n'
                      for k, part in enumerate(("head", "body"))))
    module = f"{pack_id}_faces"
    return module, ('<?xml version="1.0" encoding="utf-8"?>\n'
                    '<Database xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Name="brambora">\n'
                    '\t<!-- Written by make_face_pack.py of KCD2 Female Framework from faces.toml. Each face: its token turns it on, and\n'
                    '\t     the framework\'s reset turns it off; it answers the framework\'s question with its id, and puts its head and\n'
                    '\t     body on Henry while it is on. -->\n'
                    f'\t<Skald>\n\t\t<Module Name="{module}">\n\t\t\t<Nodes>\n' + nodes
                    + '\t\t\t</Nodes>\n\t\t\t<Assets>\n'
                    f'\t\t\t\t<SoulAsset Name="henry" SharedSoulGuids="{HENRY_SOUL}" />\n'
                    f'\t\t\t</Assets>\n\t\t\t<Text Text="{module}" />\n\t\t</Module>\n\t</Skald>\n</Database>\n')


def skald_project(pack_id, module):
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<Database xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Name="brambora">\n'
            '\t<!-- Written by make_face_pack.py of KCD2 Female Framework: the faces of this mod (MAKING_FACES.md). -->\n'
            f'\t<Skald>\n\t\t<Project Name="{pack_id}">\n\t\t\t<Definitions>\n'
            f'\t\t\t\t<Definition File="{pack_id}/{module}.xml" />\n\t\t\t</Definitions>\n'
            f'\t\t\t<Nodes>\n\t\t\t\t<{module} Name="{module}" PositionY="0" PositionX="0" />\n\t\t\t</Nodes>\n'
            f'\t\t\t<Text Text="{pack_id}" />\n\t\t\t<ObjectiveValueTypes>\n'
            '\t\t\t\t<ObjectiveValueType Type="None" IsPast="false" Icon="Exclamation" />\n'
            '\t\t\t\t<ObjectiveValueType Type="Started" IsPast="false" Icon="Exclamation" Hint="objective_HintStarted" />\n'
            '\t\t\t\t<ObjectiveValueType Type="Updated" IsPast="false" Icon="Exclamation" Hint="objective_HintUpdated" />\n'
            '\t\t\t\t<ObjectiveValueType Type="Completed" IsPast="true" Icon="Check" Hint="objective_HintCompleted" />\n'
            '\t\t\t\t<ObjectiveValueType Type="Canceled" IsPast="true" Icon="Cross" Hint="objective_HintCanceled" />\n'
            '\t\t\t</ObjectiveValueTypes>\n\t\t</Project>\n\t</Skald>\n</Database>\n')


def lua_file(pack_id, faces):
    lines = [f"-- Written by make_face_pack.py of KCD2 Female Framework from faces.toml: the faces of {pack_id}.",
             "-- The framework reads every file of Scripts/FemaleCore/Looks and keeps these with its own looks.",
             "if not (FemaleCore and FemaleCore.RegisterLooks) then",
             f'\tSystem.LogAlways("[{pack_id}] this version of KCD2 Female Framework has no RegisterLooks: these faces need a newer one")',
             "\treturn", "end", f'FemaleCore.RegisterLooks("{pack_id}", {{']
    for face in faces:
        lines.append(f'\t{{ id = {face["id"]}, name = "{face["name"]}", style = {face["style"]}, color = {face["color_index"]}, '
                     f'age = "{face.get("age", "young")}", token = "{face["token"]}" }},')
    lines += ["})", ""]
    return "\n".join(lines)


def head_folder(mod, pack_id, face):
    return mod / f"data/Objects/characters/humans/{pack_id}/head/{face['name']}"


def copy_material(source, target):
    """The material of a head of your own, next to its head: the textures it names next to it (File="./...") go there too,
    with their mipmaps (.dds.1...), and those it names by their full path stay where they are."""
    text = source.read_text(encoding="utf-8")
    for texture in sorted(set(re.findall(r'File="\./([^"/]+)\.[a-z]+"', text))):
        files = [p for p in source.parent.iterdir() if p.is_file() and p.name.lower().startswith(texture.lower() + ".")]
        if not files:
            print(f"WARNING: {source} names ./{texture}, which is not next to it: give it its full path in your mod")
        for path in files:
            if path.parent.resolve() != target.parent.resolve():
                (target.parent / path.name).write_bytes(path.read_bytes())
    target.write_text(text, encoding="utf-8", newline="")


def own_head(mod, pack_id, face):
    """A head of your own, made on the game's female skeleton as the game's women's heads are: fitted to the player's
    skeleton by generate_women.py, as the framework fits the game's, with its LODs (<head>_lod1.skin...) and its face poses
    (<head>_poses.xml) next to it, and hidden in first-person view. Its material goes next to it."""
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import generate_women as gw
    index = {}
    for pak in sorted((gw.GAME / "Data").glob("*Characters*.pak")):
        with zipfile.ZipFile(pak) as archive:
            for name in archive.namelist():
                index.setdefault(name.replace("\\", "/").lower(), (pak, name))

    def game(path):
        pak, name = index[path]
        with zipfile.ZipFile(pak) as archive:
            return archive.read(name)

    man = {n: p for n, p, _ in gw.bones(game(f"{gw.GAME_PATH}male/skeleton/male.chr"))}
    woman = {n: p for n, p, _ in gw.bones(game(f"{gw.GAME_PATH}female/skeleton/female.chr"))}
    man_binds = gw.bind_poses(game(f"{gw.GAME_PATH}male/skeleton/male.chr"))
    source = mod / face["head_mesh"]
    out = head_folder(mod, pack_id, face)
    out.mkdir(parents=True, exist_ok=True)
    stem = source.name[:-len(".skin")]
    for path in sorted(source.parent.glob(stem + "*.skin")):
        lod = path.name[len(stem):-len(".skin")]
        if lod and not re.fullmatch(r"_lod\d", lod):
            continue
        fitted, low, high = gw.fit(path.read_bytes(), man, woman, gw.hidden("head", ""), 0)
        fitted = gw.with_moved_bind(fitted, man, woman, man_binds)
        (out / f"{face['name']}{lod}.skin").write_bytes(fitted)
        print(f"Written: {out / (face['name'] + lod + '.skin')}, height {low:.3f} to {high:.3f}")
    poses = source.with_name(stem + gw.POSES)
    if poses.is_file():
        (out / f"{face['name']}{gw.POSES}").write_bytes(poses.read_bytes())
    else:
        print(f"WARNING: {poses} is not there: her face keeps still, with no expressions")
    copy_material(mod / face["material"], out / f"{face['name']}.mtl")


def head_table(pack_id, faces):
    """The node of each head of your own, under the man's Head, as the framework declares its own: the man's branch and its
    Head as the framework's table has them, so nothing of the game changes."""
    tree = ET.parse(COMPONENTS).getroot()
    male = next(n for n in tree.find("CharacterComponents") if n.get("Name") == "Male")
    head = next(n for n in male.find("DerivedComponents") if n.get("Name") == "Head")
    attributes = lambda node: " ".join(f'{k}="{v}"' for k, v in node.attrib.items())
    elements = "".join(f"\t\t\t\t\t\t\t{ET.tostring(e, encoding='unicode').strip()}\n" for e in head.find("Elements"))
    nodes = "".join(
        f'\t\t\t\t\t\t\t\t<Head Name="{face["head"]}" Paleness="{face.get("paleness", "Pale Ordinary Suntanned")}" '
        f'Age="{"Old" if face.get("age") == "old" else "YoungAdult"}" FilePath="humans/{pack_id}/head/" Morphs="#ml_ff_head">\n'
        '\t\t\t\t\t\t\t\t\t<Elements>\n'
        f'\t\t\t\t\t\t\t\t\t\t<SkinElement EquipmentPart="face" Model="{face["name"]}/{face["name"]}.skin" Material="{face["name"]}/{face["name"]}.mtl" />\n'
        '\t\t\t\t\t\t\t\t\t</Elements>\n\t\t\t\t\t\t\t\t</Head>\n'
        for face in faces)
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<database xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="barbora" xsi:noNamespaceSchemaLocation="../database.xsd">\n'
            '\t<!-- Written by make_face_pack.py of KCD2 Female Framework: the heads of this mod, fitted to the player. -->\n'
            '\t<CharacterComponents version="6">\n'
            f'\t\t<Component {attributes(male)}>\n\t\t\t<DerivedComponents>\n'
            f'\t\t\t\t<Head {attributes(head)}>\n\t\t\t\t\t<Elements>\n{elements}\t\t\t\t\t</Elements>\n'
            '\t\t\t\t\t<DerivedComponents>\n' + nodes + '\t\t\t\t\t</DerivedComponents>\n\t\t\t\t</Head>\n'
            '\t\t\t</DerivedComponents>\n\t\t</Component>\n\t</CharacterComponents>\n</database>\n')


def manifest(pack):
    return ('<?xml version="1.0" encoding="utf-8"?>\n<kcd_mod>\n\t<info>\n'
            f'\t\t<name>{pack.get("name", pack["id"])}</name>\n\t\t<modid>{pack["id"]}</modid>\n'
            f'\t\t<description>{pack.get("description", "Faces for KCD2 Female Framework")}</description>\n'
            f'\t\t<author>{pack.get("author", "")}</author>\n\t\t<version>{pack.get("version", "0.1.0")}</version>\n'
            '\t\t<modifies_level>false</modifies_level>\n\t</info>\n'
            '\t<supports>\n\t\t<version>1.5*</version>\n\t</supports>\n</kcd_mod>\n')


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    mod = pathlib.Path(sys.argv[1])
    pack, faces = read_faces(mod)
    pack_id = pack["id"]
    heads, bodies = framework_parts()
    block = pack.get("block", zlib.crc32(pack_id.encode()) % BLOCKS)
    if not isinstance(block, int) or not 0 <= block < BLOCKS:
        raise SystemExit(f"faces.toml: block is a number from 0 to {BLOCKS - 1}")
    for n, face in enumerate(faces):
        face["style"], face["color_index"] = check_face(face, heads, bodies, mod, pack_id)
        face["id"] = FIRST_ID + BLOCK * block + n
        face["token"] = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{pack_id}/ml_ff_face/{face['name']}"))
    reset, ask, answer = framework_value("RESET_TOKEN"), framework_value("ASK_TOKEN"), framework_value("ANSWER_ITEM")
    module, module_text = skald_module(pack_id, faces, reset, ask, answer)
    data = mod / "data"
    files = {
        data / f"Libs/Tables/item/item__{pack_id}.xml":
            '<?xml version="1.0" encoding="us-ascii"?>\n'
            '<database xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="barbora" xsi:noNamespaceSchemaLocation="item.xsd">\n'
            '\t<ItemClasses version="8">\n'
            '\t\t<!-- Written by make_face_pack.py of KCD2 Female Framework: the token of each face. -->\n'
            + "".join(token_row(face["token"], f"{pack_id}_face_{face['id']}") + "\n" for face in faces)
            + "\t</ItemClasses>\n</database>\n",
        data / f"Quests/{pack_id}.xml": skald_project(pack_id, module),
        data / f"Quests/{pack_id}/{module}.xml": module_text,
        data / f"Scripts/FemaleCore/Looks/{pack_id}.lua": lua_file(pack_id, faces),
    }
    if not (mod / "mod.manifest").exists():
        files[mod / "mod.manifest"] = manifest(pack)
    own = [face for face in faces if face.get("head_mesh")]
    if own:
        files[data / f"Libs/Tables/Character/CharacterComponent__{pack_id}.xml"] = head_table(pack_id, own)
    for path, text in files.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8", newline="\n")
        print(f"Written: {path}")
    for face in own:
        own_head(mod, pack_id, face)
    first = FIRST_ID + BLOCK * block
    print(f"{pack_id}: {len(faces)} faces, block {block}, ids {first} to {first + len(faces) - 1}")


if __name__ == "__main__":
    main()
