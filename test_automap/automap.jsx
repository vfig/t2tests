﻿#script "Export Automap"
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
const PAGE_REGEX = new RegExp("\\bp(?:age)?\\s*([0-9]{1,3})(?:r(?:egion)?\\s*[0-9]{1,3})?\\b", 'i');
const REGION_REGEX = new RegExp("\\b(?:p(?:age)?\\s*[0-9]{1,3})?r(?:egion)?\\s*([0-9]{1,3})\\b", 'i');

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

var previousPeriodicWaitTime = 0;
const PeriodicWaitInterval = 5000;
function PeriodicWait() {
    var now = (new Date()).getTime();
    if (now - previousPeriodicWaitTime >= PeriodicWaitInterval) {
        previousPeriodicWaitTime = now;
        $.sleep(1);
        app.refresh();
    }
}

function RelevantLayer(layer, page, region, language) {
    this.layer = layer;
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

    PeriodicWait();
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

function BuildAssetsForPage(doc, page, relevantLayers, defineAssetFn) {
    var pageLayers = [];
    var regionLayers = [];
    var languageLayers = [];
    for (var i=0; i<relevantLayers.length; ++i) {
        var rl = relevantLayers[i];
        if (rl.page === page && rl.region !== null) {
            regionLayers.push(rl);
        } else if (rl.page === page && rl.region === null) {
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
                pageAndLanguageLayers.push(rl.layer);
            }
        }
        if (pageAndLanguageLayers.length == 0) continue;

        var bounds = [0, 0, doc.width.as("px"), doc.height.as("px")];
        var basename = "page" + ThreeDigits(page);
        var filename = (language !== null ? (language + "/" + basename) : basename);
        defineAssetFn(filename, bounds, pageAndLanguageLayers);

        // Build region assets for this language.
        for (var r=0; r<MODE.MAX_REGIONS; ++r) {
            var regionAndLanguageLayers = [];
            for (var j=0; j<regionLayers.length; ++j) {
                var rl = regionLayers[j];
                if (rl.region === r && rl.language === language) {
                    regionAndLanguageLayers.push(rl.layer);
                }
            }
            if (regionAndLanguageLayers.length == 0) continue;
            // FIXME: do we want to have alpha transparency? Then don't concatenate here?
            // FIXME: need to figure out exactly what we're going to export!
            // FIXME: I guess regions for T2 style _always_ need to be transparent; just that traditionally
            // FIXME: they used 1-bit alpha in the palette?
            // FIXME: which makes things a little bit awkward, doesn't it? They probably still need to
            // FIXME: be _composited_ with the page layers, but _cropped_ to the region outline.
            // FIXME: although I suppose with alpha transparency the compositing isn't needed. It would
            // FIXME: only be required for olddark/pcx mode...
            // FIXME: But for now, just concat in the page layers for a full list for this asset:
            var assetLayers = pageAndLanguageLayers.concat(regionAndLanguageLayers);
            var bounds = [doc.width.as("px"), doc.height.as("px"), 0, 0];
            for (var j=0; j<regionAndLanguageLayers.length; ++j) {
                var lb = regionAndLanguageLayers[j].bounds;
                var b = [lb[0].as("px"), lb[1].as("px"), lb[2].as("px"), lb[3].as("px")];
                bounds[0] = Math.min(bounds[0], b[0]);
                bounds[1] = Math.min(bounds[1], b[1]);
                bounds[2] = Math.max(bounds[2], b[2]);
                bounds[3] = Math.max(bounds[3], b[3]);
            }
            var basename = "p" + ThreeDigits(page) + "r" + ThreeDigits(r);
            var filename = (language !== null ? (language + "/" + basename) : basename);
            defineAssetFn(filename, bounds, assetLayers);
        }
    }
}

function DefineAssets(doc) {
    var relevantLayers = FindRelevantLayers(doc);

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
    function Asset(filename, bounds, layers) {
        this.filename = filename;
        this.bounds = bounds;
        this.layers = layers;
    }
    function DefineAsset(filename, bounds, layers) {
        allAssets.push(new Asset(filename, bounds, layers));
    }
    for (var p=0; p<MODE.MAX_PAGES; ++p) {
        BuildAssetsForPage(doc, p, relevantLayers, DefineAsset);
        PeriodicWait();
    }

    /*
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
    */
    var allLayers = [];
    for (var i=0; i<relevantLayers.length; ++i) {
        allLayers.push(relevantLayers[i].layer);
    }

    return {
        'assets': allAssets,
        'allLayers': allLayers,
    };
}

function ExportAssets(doc) {
    var initialState = doc.activeHistoryState;
    var plan = DefineAssets(doc);
    var saveOptions = new PNGSaveOptions();
    saveOptions.interlaced = false;

    try {
        for (var i=0; i<plan.assets.length; ++i) {
            // Hide all layers
            for (var j=0; j<plan.allLayers.length; ++j) {
                var l = plan.allLayers[j];
                l.visible = false;
            }
            // Show only layers for this asset
            var asset = plan.assets[i];
            for (var j=0; j<asset.layers.length; ++j) {
                var l = asset.layers[j];
                l.visible = true;
            }
            // Crop and save (FIXME: support path selection! support formats other than .png!)
            doc.crop(asset.bounds);
            // NOTE! there is also doc.trim() to remove transparent areas.. BUT I don't know
            // how much it would remove, so it's kinda unreliable I guess?

            app.refresh();
            $.sleep(1);

            var path = "e:/temp/automap/";
            var file = new File(path + asset.filename);
            doc.saveAs(file, saveOptions, true);
            Log(file.fsName);

            doc.activeHistoryState = initialState;
        }
    } finally {
        //app.bringToFront();
        app.refresh();
        $.sleep(1);
        // FIXME: this doesn't seem to work? The file is left changed?
        doc.activeHistoryState = initialState;
    }
    //app.purge(PurgeTarget.HISTORYCACHES);
}

ExportAssets(activeDocument);
