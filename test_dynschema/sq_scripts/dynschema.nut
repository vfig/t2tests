// Play Params flags

const SCH_PLAY_RETRIGGER = 0x0001; // Does schema restart when multi-plays?
const SCH_PAN_POS        = 0x0002; // Fixed pan position described
const SCH_PAN_RANGE      = 0x0004; // Fixed pan within range described
const SCH_NO_REPEAT      = 0x0008; // Don't repeat last sample (if possible)

const SCH_NO_CACHE       = 0x0010; // dont cache this, we are unlikely to want it again
const SCH_STREAM         = 0x0020; // stream this off, dont load it all at once
const SCH_PLAY_ONCE      = 0x0040; // This is intended to be played only once.
const SCH_NO_COMBAT      = 0x0080; // This is not intended to be played in combat
const SCH_NET_AMBIENT    = 0x0100; // This ambient should be networked
const SCH_LOC_SPATIAL    = 0x0200; // This spatial sound should be local-only

const SCH_CLASS_SHIFT    = 16;
const SCH_CLASS_MASK     = 0xF0000; // (0x0F << SCH_CLASS_SHIFT)

// Loop Params flags

const SCHEMA_LOOP_POLY  = 0x01;        // polyphonous
const SCHEMA_LOOP_COUNT = 0x02;       // only loop n times

// Schema classes

enum eSchemaType {
   kSchemaTypeNone,           // Originial Thief classes.
   kSchemaTypeNoise,
   kSchemaTypeSpeech,
   kSchemaTypeAmbient,
   kSchemaTypeMusic,
   kSchemaTypeMetaUI,
};

class FocusButton extends SqRootScript
{
    function OnWorldSelect() {
        Link.BroadcastOnAllLinks(self, "Info", "ControlDevice");
    }
}

class PlayBaseSchema extends SqRootScript
{
    function GetSchemaName() {
        return "dinner_bell";
    }

    function GetAmbient() {
        return false;
    }

    function GetInfo() {
        return "Control: play dinner_bell";
    }

    function OnInfo() {
        DarkUI.TextMessage(GetInfo(), 0x0000FF, 1000);
    }

    function BeforePlay(name, schema) {
    }

    function Play(name, schema) {
        local ok;
        if (GetAmbient()) {
            ok = Sound.PlaySchemaAmbient(self, schema);

        } else {
            ok = Sound.PlaySchemaAtObject(self, schema, self);
        }
        print("Play schema "+name
            +" ("+schema+")"
            +": "+ok);
    }

    function AfterPlay(name, schema) {
    }

    function OnTurnOn() {
        local name = GetSchemaName();
        local schema = ObjID(name);
        BeforePlay(name, schema);
        Play(name, schema);
        AfterPlay(name, schema);
    }

    function OnSchemaDone() {
        print("Finished schema "+message().name
            +" on "+message().targetObject
            +" at "+message().coordinates);
    }
}

//----------------------------------------------------------------------------
// FAILED: Attempt to create a new schema object with new params at runtime

class DynSchemaMaker extends SqRootScript
{
    // DOESNT WORK: the object is created and found okay, but it won't play:
    //
    //      SchemaChooseSample: schema dinner_bell_DYN (43) has no samples
    //      Couldn't find a sample to play for schema dinner_bell_DYN (43)
    //
    // The sample db seems to be outwith the object hierarchy.

    function GetInfo() {
        return "Create dyn schema object (please press only once)";
    }

    function OnInfo() {
        DarkUI.TextMessage(GetInfo(), 0x0000FF, 1000);
    }

    function OnTurnOn() {
        local name = "dinner_bell";
        local schema = ObjID(name);
        local dyn = Object.BeginCreate(schema);
        Object.SetName(dyn, name+"_DYN");
        Property.CopyFrom(dyn, "SchPlayParams", schema);
        Property.Set(dyn, "SchPlayParams", "Volume", -3000);
        Object.EndCreate(dyn);

        print("Created "+Object.GetName(dyn)
            +" ("+dyn+")");
    }
}


class PlayDynSchema extends PlayBaseSchema
{
    function GetInfo() {
        return "Dynamically created schema obj";
    }

    function GetSchemaName() {
        return "dinner_bell_DYN";
    }
}


//----------------------------------------------------------------------------
// SUCCESS: mess with schema volume just before playing it

class SchemaVolume extends PlayBaseSchema
{
    // So the first approach didn't work. What about if we change the play
    // params before we request it to be played, then change it back after?
    //
    // THIS WORKS! nice.

    volume = -1;

    function GetInfo() {
        return "Mess with volume";
    }

    function BeforePlay(name, schema) {
        volume = Property.Get(schema, "SchPlayParams", "Volume");
        Property.Set(schema, "SchPlayParams", "Volume", -2000);
    }

    function AfterPlay(name, schema) {
        Property.Set(schema, "SchPlayParams", "Volume", volume);
    }
}


//----------------------------------------------------------------------------
// SUCCESS: mess with attenuation factor just before playing it

class SchemaAttFactor extends PlayBaseSchema
{
    // Attenuation Factor is a divisor (yeah, naming is hard) applied to the
    // sound distance before playing. So an attenuation factor of 2.0 means
    // the sound will always seem to be half as far away as the object it
    // is coming from. Used, for example

    attfac = 1.0;

    function GetInfo() {
        return "Mess with attenuation factor";
    }

    function BeforePlay(name, schema) {
        if (Property.Possessed(schema, "SchAttFac")) {
            attfac = Property.Get(schema, "SchAttFac");
        }
        Property.SetSimple(schema, "SchAttFac", 4.0);
    }

    function AfterPlay(name, schema) {
        Property.SetSimple(schema, "SchAttFac", attfac);
    }
}

//----------------------------------------------------------------------------
// FAILED: messing with loop settings just seems to get the sample to loop
//         infinitely (i guess we could use StopSchema to stop it...)

class SchemaLoopCount extends PlayBaseSchema
{
    hasProp = false;
    flags = 0;
    maxSamples = 1;

    function GetInfo() {
        return "Set Max Samples to 2";
    }

    function BeforePlay(name, schema) {
        if (Property.Possessed(schema, "SchLoopParams")) {
            hasProp = true;
            flags = Property.Get(schema, "SchLoopParams", "Flags")
            maxSamples = Property.Get(schema, "SchLoopParams", "Max Samples");
            print("hasProp: "+hasProp
                +", flags: "+flags
                +", maxSamples: "+maxSamples);
        }
        Property.Set(schema, "SchLoopParams", "Flags", SCHEMA_LOOP_COUNT);
        Property.Set(schema, "SchLoopParams", "Max Samples", 2);
    }

    function AfterPlay(name, schema) {
        if (hasProp) {
            Property.Set(schema, "SchLoopParams", "Flags", flags);
            Property.Set(schema, "SchLoopParams", "Max Samples", maxSamples);
        } else {
            Property.Remove(schema, "SchLoopParams");
        }
    }
}

//----------------------------------------------------------------------------
// SUCCESS: set pan position just before playing it (only works on ambient)

class SchemaPanPosition extends PlayBaseSchema
{
    flags = 0;
    pan = 0; // -10000 ... 10000

    function GetInfo() {
        return "Mess with pan position";
    }

    function GetAmbient() {
        return true;
    }

    function BeforePlay(name, schema) {
        flags = Property.Get(schema, "SchPlayParams", "Flags");
        pan = Property.Get(schema, "SchPlayParams", "Pan");
        Property.Set(schema, "SchPlayParams", "Flags", (flags|SCH_PAN_POS));
        Property.Set(schema, "SchPlayParams", "Pan", -10000);
    }

    function AfterPlay(name, schema) {
        Property.Set(schema, "SchPlayParams", "Flags", flags);
        Property.Set(schema, "SchPlayParams", "Pan", pan);
    }
}


/*
ObjProp "SchLoopParams"      // type sSchemaLoopParams         , flags 0x0000 , editor name: "Schema: Loop Params"
{
    "Flags" : bitflags
    "Max Samples" : int
    "Interval Min" : int
    "Interval Max" : int
}

ObjProp "SchPlayParams"      // type sSchemaPlayParams         , flags 0x0000 , editor name: "Schema: Play Params"
{
    "Flags" : bitflags    // flags: "Retrigger", "Pan position", "Pan Range", "No Repeat", "No Cache", "Stream", "Play Once", "No Combat", "Net Ambient", "Local Spatial", "", "", "", "", "", "", "Noise", "Speech", "Ambient", "Music", "MetaUI"
    "Volume" : int
    "Initial Delay" : short
    "Pan" : int
    "Fade" : int
}

ObjProp "SchPriority"        // type int                       , flags 0x0000 , editor name: "Schema: Priority"
{
    "" : int
}

ObjProp "SchMsg"             // type Label                     , flags 0x0000 , editor name: "Schema: Message"
{
    "" : string    // max 15 characters long
}

ObjProp "SchActionSnd"       // type Label                     , flags 0x0000 , editor name: "Schema: Action"
{
    "" : string    // max 15 characters long
}

ObjProp "SchAttFac"          // type float                     , flags 0x0000 , editor name: "Schema: Attenuation Factor"
{
    "" : float
}
*/