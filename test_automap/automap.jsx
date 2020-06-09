#script "Export Automap"
#target photoshop
#strict on

const LANGUAGES = [
    "english",
    "french",
    "german",
    "italian",
    "russian",
    "spanish",
];

const MAX_PAGES_OLDDARK = 8;
const MAX_PAGES_NEWDARK = 32;
const MAX_REGIONS_OLDDARK = 64;
const MAX_REGIONS_NEWDARK = 256;
const MAX_PAGES = Math.max(MAX_PAGES_OLDDARK, MAX_PAGES_NEWDARK);
const MAX_REGIONS = Math.max(MAX_REGIONS_OLDDARK, MAX_REGIONS_NEWDARK);

function Log(message) {
    $.writeln(message);
}

function Context(document) {
    this.document = document;
    this.language = null;
    this.languageSource = null;
    this.page = null;
    this.pageSource = null;
    this.region = null;
    this.regionSource = null;
}
Context.prototype.clone = function() {
    var context = new Context(this.document);
    context.setLanguage(this.language, this.languageSource);
    context.setPage(this.page, this.pageSource);
    context.setRegion(this.region, this.regionSource);
    return context;
}
Context.prototype.setLanguage = function(language, source) {
    this.language = language;
    this.languageSource = source;
}
Context.prototype.setPage = function(page, source) {
    this.page = page;
    this.pageSource = source;
}
Context.prototype.setRegion = function(region, source) {
    this.region = region;
    this.regionSource = source;
}
Context.prototype.isComplete = function() {
    return (this.language !== null && this.languageSource !== null
        && this.page !== null && this.pageSource !== null
        && this.region !== null && this.regionSource !== null);
}

function ProcessAllOpenDocuments() {
    Log("-----------------------------------");
    if (documents.length > 0) {
        var allContexts = [];
        const saveContext = function(c) { allContexts.push(c) };
        for (var i=0; i<documents.length; ++i) {
            FindContextsInDocument(documents[i], saveContext);
        }

        Log("\n");
        Log("contexts = [");
        for (var i=0; i<allContexts.length; ++i) {
            var c = allContexts[i];
            var lines = [];
            lines.push("  {");
            lines.push("  'document': '" + c.document.name + "',");
            if (c.page !== null) {
                lines.push("  'page': " + c.page + ",");
                lines.push("  'pageSource': '" + c.pageSource.typename + " " + c.pageSource.name + "',");
            }
            if (c.region !== null) {
                lines.push("  'region': " + c.region + ",");
                lines.push("  'regionSource': '" + c.regionSource.typename + " " + c.regionSource.name + "',");
            }
            if (c.language !== null) {
                lines.push("  'language': '" + c.language + "',");
                lines.push("  'languageSource': '" + c.languageSource.typename + " " + c.languageSource.name + "',");
            }
            lines.push("  },");
            var msg = lines.join("\n");
            Log(msg);
        }
        Log("]");
        Log("\n");

        const exportPlan = BuildExportPlan(allContexts);
        Log("exportPlan: ");
        for (var k in exportPlan) {
            Log(k);
        }

        // Start generating things?
        //// Save the active document and layer, to restore afterwards
        //var activeDoc = activeDocument;
        //var activeLayer = activeDoc.activeLayer;
        // const defaultLanguage = LANGUAGES[0];
        // const defaultPage = 0;
        // const defaultRegion = 0;
        // layerRef.visible = !layerRef.visible;
        // if (docRef.layers.length == 1 && layerRef.isBackgroundLayer == true)
    } else {
        Log("No open documents.");
    }
}

function FindContextsInDocument(doc, saveContext) {
    const name = doc.name;
    Log("FindContextsInDocument: " + name);

    var emptyContext = new Context(doc);
    var newContext = GetContextFromSourceName(doc, name, emptyContext);
    var rootContext = (newContext !== null ? newContext : emptyContext);

    // We always save the document context, in case there are no others.
    saveContext(rootContext);
    Log("Current page: " + rootContext.page);
    Log("Current region: " + rootContext.region);
    Log("Current language: " + rootContext.language);

    const layers = doc.layers;
    const context = rootContext;
    for (var i=0; i<layers.length; ++i) {
        if (layers[i].typename == 'ArtLayer') {
            FindContextsInArtLayer(layers[i], context, saveContext);
        } else if (layers[i].typename == 'LayerSet') {
            FindContextsInLayerSet(layers[i], context, saveContext);
        }
    }
}

function FindContextsInLayerSet(layerSet, parentContext, saveContext) {
    const name = layerSet.name;
    Log("FindContextsInLayerSet: " + name);

    var newContext = GetContextFromSourceName(layerSet, name, parentContext);
    if (newContext !== null) {
        // Only save a LayerSet context if it had something new.
        saveContext(newContext);
        Log("Current page: " + newContext.page);
        Log("Current region: " + newContext.region);
        Log("Current language: " + newContext.language);
    }

    const layers = layerSet.layers;
    var context = (newContext !== null ? newContext : parentContext);
    for (var i=0; i<layers.length; ++i) {
        if (layers[i].typename == 'ArtLayer') {
            FindContextsInArtLayer(layers[i], context, saveContext);
        } else if (layers[i].typename == 'LayerSet') {
            FindContextsInLayerSet(layers[i], context, saveContext);
        }
    }
}

function FindContextsInArtLayer(artLayer, parentContext, saveContext) {
    const name = artLayer.name;
    Log("FindContextsInArtLayer: " + name);

    var newContext = GetContextFromSourceName(artLayer, name, parentContext);
    if (newContext !== null) {
        // Only save an ArtLayer context if it had something new.
        saveContext(newContext);
        Log("Current page: " + newContext.page);
        Log("Current region: " + newContext.region);
        Log("Current language: " + newContext.language);
    }
}

// TODO: delete this
/*
function XXXBuildExportPlan(allContexts) {
    // A blank structure that we will fill in.
    const blankSingleLanguage = function() {
        return {
            'exists': false,
            'contexts': [],
        };
    };
    const blankLanguages = function() {
        var languages = [];
        for (var l=0; l<LANGUAGES.length; ++l) {
            var key = LANGUAGES[l];
            languages[key] = {
                'exists': false,
                'contexts': [],
            };
        }
        return languages;
    };
    const blankRegions = function() {
        var regions = [];
        for (var r=0; r<MAX_REGIONS; ++r) {
            regions[r] = {
                'exists': false,
                'languages': blankLanguages(),
                'languageNeutral': blankSingleLanguage(),
            };
        }
        return regions;
    };
    const blankPages = function() {
        var pages = [];
        for (var p=0; p<MAX_PAGES; ++p) {
            pages[p] = {
                'exists': false,
                'languages': blankLanguages(),
                'languageNeutral': blankSingleLanguage(),
                'regions': blankRegions(),
            };
        }
    };
    var allPages = blankPages();

    // Allocate each context to all relevant pages and regions.
    const allocateToLanguage = function(context, language, lang) {
        if (context.language === lang) {
            language.exists = true;
        }
        language.contexts.push(context);
    }
    const allocateToRegion = function(context, region, r) {
        if (context.region === r) {
            region.exists = true;
        }
        // Allocate it to this region.
        if (context.language === null) {
            allocateToLanguage(context, region.languageNeutral, context.language);
            for (var l=0; l<LANGUAGES.length; ++l) {
                const key = LANGUAGES[l];
                allocateToLanguage(context, region.languages[key], context.language);
            }
        } else {
            const key = context.language;
            allocateToLanguage(context, region.languages[key], context.language);
        }
    }
    const allocateToPage = function(context, page, p) {
        if (context.page === p) {
            page.exists = true;
        }
        if (context.region === null) {
            // TODO: if the context is for a specific page, and we want alpha-transparent
            //       regions, then we should NOT allocate it to all regions.
            // Allocate it to all regions for this page.
            for (var r=0; r<MAX_REGIONS; ++r) {
                allocateToRegion(context, page.regions[r], r);
            }
            // Allocate it to this page.
            if (context.language === null) {
                allocateToLanguage(context, page.languageNeutral, context.language);
                for (var l=0; l<LANGUAGES.length; ++l) {
                    const key = LANGUAGES[l];
                    allocateToLanguage(context, page.languages[key], context.language);
                }
            } else {
                const key = context.language;
                allocateToLanguage(context, page.languages[key], context.language);
            }
        } else {
            allocateToPage(context, context.region);
        }
    }
    for (var i=0; i<allContexts.length; ++i) {
        var context = allContexts[i];
        if (context.page === null) {
            for (var p=0; p<MAX_PAGES; ++p) {
                allocateToPage(context, allPages[p], p);
            }
        } else {
            const p = contex.page;
            allocateToPage(context, allPages[p], p);
        }
    }
}
*/

function ThreeDigits(n) {
    return ('000' + n.toString()).slice(-3);
}

function DeriveFileKey(language, page, region) {
    if (page === null) {
        return null;
    }
    var key = [];
    if (language !== null) {
        key.push(language);
        key.push('/');
    }
    key.push('p');
    key.push(ThreeDigits(page));
    if (region !== null) {
        key.push('r');
        key.push(ThreeDigits(region));
    }
    return key.join('');
}

function BuildExportPlan(allContexts) {
    // Find out which pages and regions are in use.
    var pageIndex = [];
    for (var p=0; p<MAX_PAGES; ++p) {
        var regionIndex = [];
        for (var r=0; r<MAX_REGIONS; ++r) {
            regionIndex[r] = {
                'used': false,
            };
        }
        pageIndex[p] = {
            'used': false,
            'regions': regionIndex,
        };
    }
    for (var i=0; i<allContexts.length; ++i) {
        var context = allContexts[i];
        if (context.page !== null) {
            var p = context.page;
            pageIndex[p].used = true;
            if (context.region !== null) {
                var r = context.region;
                pageIndex[p].regions[r].used = true;
            }
        }
    }

    // Separate the contexts for specific pages from those for every page.
    var specificPageContexts = [];
    var everyPageContexts = [];
    for (var i=0; i<allContexts.length; ++i) {
        var context = allContexts[i];
        if (context.page === null) {
            if (context.region === null) {
                everyPageContexts.push(context);
            } else {
                // Ignore contexts that suggest a region without a page.
                // TODO: could issue a warning?
            }
        } else {
            specificPageContexts.push(context);
        }
    }

    var plan = {};
    var assignContextToKey = function(context, key) {
        var contextsForKey = plan[key];
        if (contextsForKey == null /* or undefined */) {
            contextsForKey = [];
            plan[key] = contextsForKey;
        }
        contextsForKey.push(context);
    }

    // First pass: process only contexts for a specific page, or specific page+region.
    for (var i=0; i<specificPageContexts.length; ++i) {
        var context = specificPageContexts[i];
        var key = DeriveFileKey(context.language, context.page, context.region);
        if (key === null) continue;
        assignContextToKey(context, key);
    }
    // Second pass: allocate contexts for every page, to every page and every region that is in use.
    for (var i=0; i<everyPageContexts.length; ++i) {
        var context = everyPageContexts[i];
        for (var p=0; p<MAX_PAGES; ++p) {
            if (! pageIndex[p].used) continue;
            var key = DeriveFileKey(context.language, p, null);
            if (key === null) continue;
            assignContextToKey(context, key);
            for (var r=0; r<MAX_REGIONS; ++r) {
                if (! pageIndex[p].regions[r].used) continue;
                var key = DeriveFileKey(context.language, p, r);
                if (key === null) continue;
                assignContextToKey(context, key);
            }
        }
    }

    return plan;

    /*
    ^^^ I feel like the above is overcomplicating things. As a data structure, we simply want:
        [all relevant layers]
        (language, page, region) -> [layers to make visible]
            where there is also a 'NONE' language.
            filename is derived from:
                language: base dir if 'NONE', otherwise language subdir
                page: pNNN
                region: nothing if null, otherwise +rMMM
        a defaultdict-style approach: generate a key, create an empty array if the key is not in
        the table already, and append. key can simply be file path! LANGUAGE/pNNNrMMM
        As we process this and export, then we also build up the region coordinates, so we can create
        the .bins
    */
}


function BuildLanguageRegExp(languages) {
    var pattern = [];
    pattern.push("\\b");
    pattern.push(languages[0]);
    for (var i=1; i<languages.length; ++i) {
        var lang = languages[i];
        pattern.push("|");
        pattern.push(languages[i]);
    }
    pattern.push("\\b");
    return new RegExp(pattern.join(""), 'i');
}

const LANGUAGE_REGEX = BuildLanguageRegExp(LANGUAGES);
const PAGE_REGEX = new RegExp("\\bp(?:age)?([0-9]{1,3})\\b", 'i');
const REGION_REGEX = new RegExp("\\br(?:egion)?([0-9]{1,3})\\b", 'i');

function GetPageFromName(name) {
    var m = name.match(PAGE_REGEX);
    if (m) {
        return parseInt(m[1], 10);
    } else {
        return null;
    }
}

function GetRegionFromName(name) {
    var m = name.match(REGION_REGEX);
    if (m) {
        return parseInt(m[1], 10);
    } else {
        return null;
    }
}

function GetLanguageFromName(name) {
    var m = name.match(LANGUAGE_REGEX);
    if (m) {
        return m[0].toLowerCase();
    } else {
        return null;
    }
}

function GetContextFromSourceName(source, name, parentContext) {
    var language = GetLanguageFromName(name);
    var page = GetPageFromName(name);
    var region = GetRegionFromName(name);
    if (language !== null || page !== null || region !== null) {
        var context = parentContext.clone();
        if (language !== null) {
            context.setLanguage(language, source);
        }
        if (page !== null) {
            context.setPage(page, source);
        }
        if (region !== null) {
            context.setRegion(region, source);
        }
        return context;
    } else {
        return null;
    }
}


ProcessAllOpenDocuments();
