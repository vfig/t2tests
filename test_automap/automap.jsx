#script "Export Automap"
#target photoshop
#strict on

/** This script will only look for these exact language names
 *  when figuring out which languages to export for. If you
 *  need to support additional languages, just add them to
 *  this list. Make sure the language name here is exactly the
 *  same as the folder name used by the game for the language.
 */
const LANGUAGES = [
    "english",
    "french",
    "german",
    "italian",
    "russian",
    "spanish",
];

const MODES = {
    OLDDARK: {
        MAX_PAGES: 8,
        MAX_REGIONS: 64,
    },
    NEWDARK: {
        MAX_PAGES: 32,
        MAX_REGIONS: 256,
    },
};

// TODO: support choosing which mode we operate in.
const MODE = MODES.NEWDARK;

function Log(message) {
    $.writeln(message);
}

function LogWarning(message) {
    $.writeln("WARNING: " + message);
}

function ThreeDigits(n) {
    return ('000' + n.toString()).slice(-3);
}

// FIXME: I think all the stuff between here and the next message is irrelevant.

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
    for (var p=0; p<MODE.MAX_PAGES; ++p) {
        var regionIndex = [];
        for (var r=0; r<MODE.MAX_REGIONS; ++r) {
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
        for (var p=0; p<MODE.MAX_PAGES; ++p) {
            if (! pageIndex[p].used) continue;
            var key = DeriveFileKey(context.language, p, null);
            if (key === null) continue;
            assignContextToKey(context, key);
            for (var r=0; r<MODE.MAX_REGIONS; ++r) {
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

// FIXME: nearly all the stuff above is irrelevant


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
const PAGE_REGEX = new RegExp("p(?:age)?\\s*([0-9]{1,3})", 'i');
const REGION_REGEX = new RegExp("r(?:egion)?\\s*([0-9]{1,3})", 'i');

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

//ProcessAllOpenDocuments();
function log_recursive(o) {
    var s = [];
    var b;
    var v;
    if (o.typename == 'Document') {
        b = [0, 0, o.width.as("px"), o.height.as("px")];
        v = true;
    } else {
        b = [o.bounds[0].as("px"), o.bounds[1].as("px"), o.bounds[2].as("px"), o.bounds[3].as("px")];
        v = o.visible;
    }
    Log(o.name)
    s.push("{ 'name': '" + o.name + "',");
    s.push("  'typename': '" + o.typename + "',");
    s.push("  'visible': " + (v ? 1 : 0) + ",");
    s.push("  'bounds': [" + b[0] + ", " + b[1] + ", " + b[2] + ", " + b[3] + "],");
    if (o.typename == 'Document' || o.typename == 'LayerSet') {
        s.push("  'layers': [");
        var layers = o.layers;
        // Note: without these log calls, ps stops responding... ?!?
        Log(layers.length + " layers");
        for (var i=0; i<o.layers.length; ++i) {
            Log(">> " + o.name + " layer: " + i);
            s.push(log_recursive(o.layers[i]) + ",");
        }
        s.push("  ],")
    }
    s.push("}");
    return s.join("\n");
}
/* //To dump layers recursively (ready for python)
Log(log_recursive(activeDocument));
*/


/* //To do a progress bar:
function WaitForRedraw(){
    $.sleep(1);
    app.refresh();
}
var win = new Window("window{text:'Progress',bounds:[100,100,400,150],bar:Progressbar{bounds:[20,20,280,31] , value:0,maxvalue:100}};");
win.show();
try {
    for(var i=0; i<10; ++i){
        Log("tick " + i);
        win.bar.value = i / 10.0 * 100.0;
    	WaitForRedraw();	
    }
} finally {
    win.close();
}
*/

////////////////////////////

var previousWaitTime = 0;
const WaitInterval = 5000;
function Wait() {
    var now = (new Date()).getTime();
    if (now - previousWaitTime >= WaitInterval) {
        previousWaitTime = now;
        $.sleep(1);
        app.refresh();
    }
}

function RelevantLayer(layer, page, region, language) {
    var b = layer.bounds;
    this.layer = layer;
    this.bounds = [b[0].as("px"), b[1].as("px"), b[2].as("px"), b[3].as("px")];
    this.page = page;
    this.region = region;
    this.language = language;
    this.originallyVisible = layer.visible;
}

function FindRelevantLayersRecursive(o, foundRelevantLayerFn, inheritedPage, inheritedLanguage) {
    var isLayer = (o.typename === 'ArtLayer' || o.typename === 'LayerSet');
    var hasSublayers = (o.typename === 'Document' || o.typename === 'LayerSet');

    var name = o.name;
    var page = GetPageFromName(name);
    var region = GetRegionFromName(name);
    var language = GetLanguageFromName(name);
    var isRelevant = isLayer && (page !== null || region !== null || language !== null);
    if (region !== null && (page === null && inheritedPage === null)) {
        LogWarning("Warning: layer '" + name + "' has a region but I can't figure out a page number! Ignoring it.");
        isRelevant = false;
    }

    var resolvedPage = (page !== null ? page : inheritedPage);
    // FIXME: do we need an inheritedRegion, e.g. in case of language sublayers of a region?
    var resolvedRegion = region;
    var resolvedLanguage = (language !== null ? language : inheritedLanguage);

    if (isRelevant) {
        foundRelevantLayerFn(new RelevantLayer(o, resolvedPage, resolvedRegion, resolvedLanguage));
    }
    if (hasSublayers) {
        var sublayers = o.layers;
        for (var i=0; i<sublayers.length; ++i) {
            FindRelevantLayersRecursive(sublayers[i], foundRelevantLayerFn, resolvedPage, resolvedLanguage);
        }
    }

    Wait();
}

function FindRelevantLayers(doc) {
    var relevantLayers = [];
    var found = function(rl) {
        relevantLayers.push(rl);
    }
    // FIXME: if we want to force a default language, can pass it in here as 'inheritedLanguage'
    FindRelevantLayersRecursive(doc, found, null, null);
    return relevantLayers;
}

function BuildAssetsForPage(page, relevantLayers, defineAssetFn) {
    var pageLayers = [];
    var regionLayers = [];
    var languageLayers = [];
    for (var i=0; i<relevantLayers.length; ++i) {
        var rl = relevantLayers[i];
        if (rl.page === p && rl.region !== null) {
            regionLayers.push(rl);
        } else if (rl.page === p && rl.region === null) {
            pageLayers.push(rl);
        } else if (rl.page === null && rl.language !== null) {
            languageLayers.append(rl);
        }
    }
    // If there's nothing specific to this page, we're not going to export it!
    if (pageLayers.length == 0) return;

    // Figure out the languages in use for this page.
    var isLanguageUsed = {};
    for (var i=0; i<LANGUAGES.length; ++i) {
        var language = LANGUAGES[i];
        isLanguageUsed[language] = false;
    }
    for (var i=0; i<pageLayers.length; ++i) {
        var language = pageLayers[i].language;
        if (language !== null) {
            isLanguageUsed[language] = true;
        }
    }
    for (var i=0; i<regionLayers.length; ++i) {
        var language = regionLayers[i].language;
        if (language !== null) {
            isLanguageUsed[language] = true;
        }
    }
    for (var i=0; i<languageLayers.length; ++i) {
        var language = languageLayers[i].language;
        if (language !== null) {
            isLanguageUsed[language] = true;
        }
    }
    var usedLanguages = [];
    for (var i=0; i<LANGUAGES.length; ++i) {
        var language = LANGUAGES[i];
        if (isLanguageUsed[language]) {
            usedLanguages.push(language);
        }
    }
    // If any langs are used, then (for simplicity) assume they are used for all
    // assets in this page. So we reprocess the page and region lists, expanding
    // each for all langs.
    if (usedLanguages.length > 0) {
        var expandedPageLayers = [];
        for (var i=0; i<pageLayers.length; ++i) {
            var rl = pageLayers[i];
            if (rl.language !== null) {
                expandedPageLayers.push(rl);
            } else {
                for (var j=0; j<usedLanguages.length; ++j) {
                    var nrl = new RelevantLayer(rl.layer, rl.page, rl.region, usedLanguages[j]);
                    expandedPageLayers.push(nrl);
                }
            }
        }
        pageLayers = expandedPageLayers;
        var expandedRegionLayers = [];
        for (var i=0; i<regionLayers.length; ++i) {
            var rl = regionLayers[i];
            if (rl.language !== null) {
                expandedRegionLayers.push(rl);
            } else {
                for (var j=0; j<usedLanguages.length; ++j) {
                    var nrl = new RelevantLayer(rl.layer, rl.page, rl.region, usedLanguages[j]);
                    expandedRegionLayers.push(nrl);
                }
            }
        }
        regionLayers = expandedRegionLayers;
    }
    // So now the lists are ready to use.
    // Sort them for convenience of output:
    var compareRelevantLayers = function (a, b) {
        var n;
        if (a.language === null) return -1;
        if (b.language === null) return 1;
        n = a.language.localeCompare(b.language);
        if (n != 0) return n;
        if (a.page === null) return -1;
        if (b.page === null) return 1;
        if (a.page < b.page) return -1;
        if (a.page > b.page) return 1;
        if (a.region === null) return -1;
        if (b.region === null) return 1;
        if (a.region < b.region) return -1;
        if (a.region > b.region) return 1;
        return a.layer.name.localeCompare(b.layer.name);
    }
    pageLayers.sort(compareRelevantLayers);
    regionLayers.sort(compareRelevantLayers);

    /*
    // Print stuff, see where we're at...
    Log("after expansion:");
    for (var i=0; i<pageLayers.length; ++i) {
        var rl = pageLayers[i];
        Log("page " + rl.page + ", region " + rl.region + ", language " + rl.language + " : " + rl.layer.name);
    }
    for (var i=0; i<regionLayers.length; ++i) {
        var rl = regionLayers[i];
        Log("page " + rl.page + ", region " + rl.region + ", language " + rl.language + " : " + rl.layer.name);
    }
    */

    var exportLanguages = [null].concat(usedLanguages);
    for (var i=0; i<exportLanguages.length; ++i) {
        // Build page asset for this language.
        var language = exportLanguages[i];
        var pageAndLanguageLayers = [];
        for (var j=0; j<pageLayers.length; ++j) {
            var rl = pageLayers[j];
            if (rl.language === language) {
                pageAndLanguageLayers.push(rl);
            }
        }
        if (pageAndLanguageLayers.length == 0) continue;

        var basename = "page" + ThreeDigits(page);
        var filename = (language !== null ? (language + "/" + basename) : basename);
        defineAssetFn(filename, pageAndLanguageLayers);

        // Build region assets for this language.
        for (var r=0; r<MODE.MAX_REGIONS; ++r) {
            var regionAndLanguageLayers = [];
            for (var j=0; j<regionLayers.length; ++j) {
                var rl = regionLayers[j];
                if (rl.region === r && rl.language === language) {
                    regionAndLanguageLayers.push(rl);
                }
            }
            if (regionAndLanguageLayers.length == 0) continue;
            // FIXME: do we want to have alpha transparency? Then don't concatenate here?
            // FIXME: need to figure out exactly what we're going to export!
            // FIXME: I guess regions for T2 style _always_ need to be transparent; just that traditionally
            // FIXME: they used 1-bit alpha in the palette?
            // FIXME: which makes things a little bit awkward, doesn't it? They probably still need to
            // FIXME: be _composited_ with the page layers, but _cropped_ to the region outline.
            // FIXME: But for now, just concat in the page layers for a full list for this asset:
            regionAndLanguageLayers = pageLayers.concat(regionAndLanguageLayers);
            var basename = "p" + ThreeDigits(page) + "r" + ThreeDigits(r);
            var filename = (language !== null ? (language + "/" + basename) : basename);
            defineAssetFn(filename, regionAndLanguageLayers);
        }
    }
}

var relevantLayers = FindRelevantLayers(activeDocument);

/*
// FIXME: temp
for (var i=0; i<relevantLayers.length; ++i) {
    var rl = relevantLayers[i];
    Log(rl.layer.typename + " " + rl.layer.name + ": p" + rl.page + " r" + rl.region + " l" + rl.language);
}
Log("--------------------");
*/

// Build out the asset list for each page.
var allAssets = [];
function Asset(filename, layers) {
    this.filename = filename;
    this.layers = layers;
}
function DefineAsset(filename, layers) {
    allAssets.push(new Asset(filename, layers));
}
for (var p=0; p<MODE.MAX_PAGES; ++p) {
    BuildAssetsForPage(p, relevantLayers, DefineAsset);
    Wait();
}

// FIXME: temp. log the assets!
Log("--------------------");
Log(" ");
Log("assets:")
for (var i=0; i<allAssets.length; ++i) {
    var a = allAssets[i];
    var l = [];
    for (var j=0; j<a.layers.length; ++j) {
        l.push(a.layers[j].layer.name);
    }
    Log(a.filename + ": " + l.join(", "));
}
