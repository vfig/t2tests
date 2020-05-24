package main

import (
    "bytes"
    "encoding/binary"
    "flag"
    "fmt"
    "io"
    "io/ioutil"
)

func main() {
    flag.Parse()
    args := flag.Args()
    if len(args) < 1 {
        panic("Need a .mis file to read!")
    }
    mis_filename := args[0]
    mis_data, err := ioutil.ReadFile(mis_filename)
    if err != nil {
        panic(err)
    }
    rooms_data := get_rooms_data(mis_data)
    dump_rooms(rooms_data)
}

// --------------------------------------------------------

// These structs are all specific to the file format so should really be
// internal...
type TagVersion struct {
    Major uint32
    Minor uint32
}

type TagFileTag struct {
    LabelBytes [12]byte
}

func (t *TagFileTag) Label() string {
    null_term := bytes.IndexByte(t.LabelBytes[:], 0)
    if null_term == -1 {
        null_term = 12;
    }
    return string(t.LabelBytes[:null_term])
}

type TagFileHeader struct {
    TableOffset uint32
    Version TagVersion
    Pad [256]byte
    DeadBeef [4]byte
}

type TagTableHeader struct {
    EntryCount uint32
}

type TagTableEntry struct {
    Key TagFileTag
    Offset uint32
    Size uint32
}

// ...except this one.
type TagTable map[string]TagTableEntry

const TagFileBlockHeaderSize = 24
type TagFileBlockHeader struct {
    Tag TagFileTag
    Version TagVersion
    Size uint32
}

// --------------------------------------------------------

func get_rooms_data(data []byte) []byte {
    r := bytes.NewReader(data)

    // Okay, let's read the header.

    var header TagFileHeader
    if err := binary.Read(r, binary.LittleEndian, &header); err != nil {
        panic(err)
    }

    if header.DeadBeef != [4]byte{0xde, 0xad, 0xbe, 0xef} {
        fmt.Printf("DeadBeef %x\n", header.DeadBeef)
        panic("Where's the deadbeef?")
    }

    fmt.Printf("Version %d.%d\n", header.Version.Major, header.Version.Minor)
    fmt.Printf("Offset 0x%x\n", header.TableOffset)

    // Good, now let's go read that tag table

    if _, err := r.Seek(int64(header.TableOffset), io.SeekStart); err != nil {
        panic(err)
    }

    var table_header TagTableHeader
    if err := binary.Read(r, binary.LittleEndian, &table_header); err != nil {
        panic(err)
    }

    fmt.Printf("Entries %d\n", table_header.EntryCount)

    //table := make(map[string]TagTableEntry, int(table_header.EntryCount))
    var table TagTable = make(map[string]TagTableEntry, int(table_header.EntryCount))

    var entry TagTableEntry
    for i := 0; i < int(table_header.EntryCount); i++ {
        if err := binary.Read(r, binary.LittleEndian, &entry); err != nil {
            panic(err)
        }

        table[entry.Key.Label()] = entry
    }

    // Let's take a look at the room db entry

    entry = table["ROOM_DB"]
    fmt.Printf(
        "Entry %s:\n" +
        "  Offset: 0x%x\n" +
        "  Size: 0x%x\n\n",
        entry.Key.Label(), entry.Offset, entry.Size)

    // Great! Now we can grab the room db

    start := int(entry.Offset)
    end := int(entry.Offset) + int(entry.Size) + TagFileBlockHeaderSize
    entry_data := data[start:end]

    return entry_data
}

// --------------------------------------------------------

type Vector struct {
    X float32
    Y float32
    Z float32
}

type Plane struct {
    Normal Vector
    D float32
}

type RoomPortal struct {
    PortalID int
    Index int
    PortalPlane Plane
    EdgePlanes []Plane
    FarRoomID int
    NearRoomID int
    Center Vector
    FarPortalID int
}

func (portal *RoomPortal) Read(r io.Reader) {
    var portal_id int32
    if err := binary.Read(r, binary.LittleEndian, &portal_id); err != nil {
        panic(err)
    }
    portal.PortalID = int(portal_id)

    var index int32
    if err := binary.Read(r, binary.LittleEndian, &index); err != nil {
        panic(err)
    }
    portal.Index = int(index)

    var plane Plane
    if err := binary.Read(r, binary.LittleEndian, &plane); err != nil {
        panic(err)
    }
    portal.PortalPlane = plane

    var edge_count int32
    if err := binary.Read(r, binary.LittleEndian, &edge_count); err != nil {
        panic(err)
    }

    planes := make([]Plane, int(edge_count))
    for i := 0; i < int(edge_count); i++ {
        if err := binary.Read(r, binary.LittleEndian, &plane); err != nil {
            panic(err)
        }
        planes[i] = plane
    }
    portal.EdgePlanes = planes

    var room_id int32
    if err := binary.Read(r, binary.LittleEndian, &room_id); err != nil {
        panic(err)
    }
    portal.FarRoomID = int(room_id)

    if err := binary.Read(r, binary.LittleEndian, &room_id); err != nil {
        panic(err)
    }
    portal.NearRoomID = int(room_id)

    var center Vector
    if err := binary.Read(r, binary.LittleEndian, &center); err != nil {
        panic(err)
    }
    portal.Center = center

    if err := binary.Read(r, binary.LittleEndian, &portal_id); err != nil {
        panic(err)
    }
    portal.FarPortalID = int(portal_id)
}

type Room struct {
    ObjID int
    RoomID int
    Center Vector
    Planes []Plane
    Portals []RoomPortal
    PortalDistances [][]float32
    WatchList [][]int
}

func (room *Room) Read(r io.Reader) {
    var obj_id int32
    if err := binary.Read(r, binary.LittleEndian, &obj_id); err != nil {
        panic(err)
    }
    room.ObjID = int(obj_id)

    var room_id int16
    if err := binary.Read(r, binary.LittleEndian, &room_id); err != nil {
        panic(err)
    }
    room.RoomID = int(room_id)

    var center Vector
    if err := binary.Read(r, binary.LittleEndian, &center); err != nil {
        panic(err)
    }
    room.Center = center

    var planes [6]Plane
    if err := binary.Read(r, binary.LittleEndian, &planes); err != nil {
        panic(err)
    }
    room.Planes = planes[:]

    var portal_count int32
    if err := binary.Read(r, binary.LittleEndian, &portal_count); err != nil {
        panic(err)
    }

    var portal RoomPortal
    portals := make([]RoomPortal, int(portal_count))
    for i := 0; i < int(portal_count); i++ {
        portal.Read(r)
        portals[i] = portal
    }
    room.Portals = portals

    var distance float32
    distances := make([][]float32, int(portal_count))
    for i := 0; i < int(portal_count); i++ {
        inner_distances := make([]float32, int(portal_count))
        for j := 0; j < int(portal_count); j++ {
            if err := binary.Read(r, binary.LittleEndian, &distance); err != nil {
                panic(err)
            }
            inner_distances[j] = distance
        }
        distances[i] = inner_distances
    }

    var entry int32
    var entry_count int32
    var entries []int
    var watch_count int32
    if err := binary.Read(r, binary.LittleEndian, &watch_count); err != nil {
        panic(err)
    }
    watch_list := make([][]int, int(watch_count))
    for i := 0; i < int(watch_count); i++ {
        if err := binary.Read(r, binary.LittleEndian, &entry_count); err != nil {
            panic(err)
        }
        entries = make([]int, int(entry_count))
        for j := 0; j < int(entry_count); j++ {
            if err := binary.Read(r, binary.LittleEndian, &entry); err != nil {
                panic(err)
            }
            entries[j] = int(entry)
        }
        watch_list[i] = entries
    }
    room.WatchList = watch_list
}

// --------------------------------------------------------

func dump_rooms(data []byte) {
    r := bytes.NewReader(data)

    // Okay, let's read the header.

    var header TagFileBlockHeader
    if err := binary.Read(r, binary.LittleEndian, &header); err != nil {
        panic(err)
    }

    var rooms_ok int32
    if err := binary.Read(r, binary.LittleEndian, &rooms_ok); err != nil {
        panic(err)
    }
    if rooms_ok != 1 {
        fmt.Printf("Room db is not okay, so not gonna read it.")
        return
    }

    var room_count int32
    if err := binary.Read(r, binary.LittleEndian, &room_count); err != nil {
        panic(err)
    }
    

    var room Room
    rooms := make([]Room, int(room_count))
    for i := 0; i < int(room_count); i++ {
        room.Read(r)
        rooms[i] = room
    }

    // Dump it

    for _, room := range rooms {
        fmt.Printf(
            "[ROOM %d\tObj %d\tName \"???\"]\n" +
            "   Archetype: ??? (???)\n" +
            "   Center: (%0.3f %0.3f %0.3f)\n",
            room.RoomID, room.ObjID,
            room.Center.X, room.Center.Y, room.Center.Z)
        for j, plane := range room.Planes {
            fmt.Printf(
                "      Plane %d: (%0.3f %0.3f %0.3f) %0.3f\n",
                j, plane.Normal.X, plane.Normal.Y, plane.Normal.Z, plane.D)
        }
        fmt.Printf("\n\n")
    }
}

/* where this is at:

Okay, so this can load the room info just fine.

Next it needs to be able to output that into a format I can use from Squirrel.

Since the room system _should_ handle all the 'which object is in which place'
stuff that I need (assuming each room brush is a unique concrete!), I
won't actually need the planes for OBB or AABB interior testing, let alone need
to build a BSP tree from it all, or a [perfect spatial hash]
(http://hhoppe.com/perfecthash.pdf) or any such thing. All we need is to reverse
engineer the orientation and dimensions from the room brush's planes, then put
that in a lookup table indexed by... the room ID? or will we need the room
archetype or object ID? More research might be needed there.

UHHHH DOPE. Don't need to reverse engineer anything, just expand this to read
the brush properties too. This doesn't need to work on stripped missions!
    - assuming, that is, that room brushes are just in the brush tag block?
*/
