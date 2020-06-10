show_debug_messages = False

def process_contexts(contexts):
  # Global language contexts are considered to apply to _all_ pages and regions.
  # If you want to be more specific, make sure the languages are in layers
  # specifically for a page or region.
  global_language_contexts = []
  extant_languages = {}
  for c in contexts:
    page = c.get('page')
    region = c.get('region')
    language = c.get('language')
    if page is None and region is None and language is not None:
      global_language_contexts.append(c)
    if language is not None:
      extant_languages[language] = True

  for p in range(32): # or whatever the max page is:
    # Find all contexts pertaining to this page
    page_contexts = []
    subregion_contexts = []
    for c in contexts:
      page = c.get('page')
      region = c.get('region')
      if page == p:
        if region is None:
          page_contexts.append(c)
        else:
          subregion_contexts.append(c)

    if not page_contexts:
      if subregion_contexts:
        print(f"WARNING: Page {p} has no layers of its own, but it has regions!")
      else:
        if show_debug_messages:
          print(f"DEBUG: Page {p} has no contexts, skipping.")
        continue

    # Find all relevant language contexts for the page itself,
    # and determine which languages are in use for this page.
    page_language_contexts = []
    page_languages = {}
    for c in global_language_contexts:
      language = c.get('language')
      page_language_contexts.append(c)
      page_languages[language] = True
    for c in page_contexts:
      language = c.get('language')
      if language is not None:
        page_language_contexts.append(c)
        page_languages[language] = True

    # Now check that the page either uses no languages, or uses
    # all the extant ones.
    if page_languages:
      for lang in extant_languages.keys():
        if page_languages.get(lang) != True:
          print(f"WARNING: Page {p} does not have any layers for '{lang}' language.")

    def do_page(lang):
      print(f"page{p:03}.png\t(page {p} - {lang})")
    if page_languages:
      for lang in sorted(extant_languages.keys()):
        print(f"{lang}/", end='')
        do_page(lang)
    else:
      do_page("(none)")

    # Now we process the regions for this page.
    for r in range(32): # or whatever the max region is:
      # Find all contexts pertaining to this region
      region_contexts = []
      for c in subregion_contexts:
        region = c.get('region')
        if region == r:
          region_contexts.append(c)

      if not region_contexts:
        if show_debug_messages:
          print(f"DEBUG: Page {p} region {r} has no contexts, skipping.")
        continue

      # Find all relevant language contexts for the region,
      # and determine which languages are in use for this region.
      region_language_contexts = []
      region_languages = {}
      for c in page_language_contexts:
        language = c.get('language')
        region_language_contexts.append(c)
        region_languages[language] = True
      for c in region_contexts:
        language = c.get('language')
        if language is not None:
          region_language_contexts.append(c)
          region_languages[language] = True

      # Now check that the region either uses no languages, or uses
      # all the extant ones.
      if region_languages:
        for lang in extant_languages.keys():
          if region_languages.get(lang) != True:
            print(f"WARNING: Page {p} region {r} does not have any layers for '{lang}' language.")

      def do_region(lang):
        print(f"p{p:03}r{r:03}.png\t(page {p}, region {r} - {lang})")
      if region_languages:
        for lang in sorted(extant_languages.keys()):
          print(f"{lang}/", end='')
          do_region(lang)
      else:
        do_region("(none)")

  # So this works. The next step is for each page+language and each page+region+language combination
  # to decide which layers to turn on or off.
  # Also rejig the thing to only use the active document, nothing else. Otherwise the logic is too
  # convoluted in terms of exporting. A separate script could maybe run this for all open documents, treating
  # each _alone_.
  #
  # Really I think this thing could work by bucketing layers into lang/page/region with a single pass,
  # and one post-cleanup to make sure no 'none' language is exported for a page/region when a language-specific
  # variation for it exists.
  #
  # In that same single pass, the extents of the layer could be measured, and then unioned with the page/region's
  # existing extents (the extents will be language-specific too if any of the regions are)


## all the stuff above here can be disregarded, right?

MAX_PAGES = 32
MAX_REGIONS = 256
ALL_LANGUAGES = ['english', 'french', 'german', 'spanish', 'russian', 'italian']

import re
LANGUAGE_REGEX = re.compile(r"english|french|german|spanish|russian|italian")
PAGE_REGEX = re.compile(r"\bp(?:age)?\s*([0-9]{1,3})", re.IGNORECASE)
REGION_REGEX = re.compile(r"(?:\b|p(?:age)?\s*[0-9]{1,3})r(?:egion)?\s*([0-9]{1,3})\b", re.IGNORECASE)

def GetPageFromName(name):
  m = PAGE_REGEX.search(name)
  if m:
    return int(m.group(1), 10)
  else:
    return None

def GetRegionFromName(name):
  m = REGION_REGEX.search(name)
  if m:
    return int(m.group(1), 10)
  else:
    return None

def GetLanguageFromName(name):
  m = LANGUAGE_REGEX.search(name)
  if m:
    return m.group(0).lower()
  else:
    return None

def find_interesting_objects(doc, interesting_object):
  _recursive_find_interesting_objects(doc, interesting_object, None, None)

def _recursive_find_interesting_objects(o, interesting_object, inherited_page, inherited_lang):
  name = o['name']
  page = GetPageFromName(name)
  region = GetRegionFromName(name)
  lang = GetLanguageFromName(name)
  is_interesting = (page is not None or region is not None or lang is not None)
  if region is not None and (page is None and inherited_page is None):
    print(f"Warning: '{name}' has a region but I can't figure out a page number! Ignoring it.")
    is_interesting = False

  resolved_lang = lang if lang is not None else inherited_lang
  resolved_page = page if page is not None else inherited_page
  if is_interesting:
    interesting_object(o, resolved_page, region, resolved_lang)
  if 'layers' in o:
    for layer in o['layers']:
      _recursive_find_interesting_objects(layer, interesting_object, resolved_page, resolved_lang)

def make_export_plan(doc):
  # FIXME...
  # Mapping of filename -> layers
  PLAN = {}
  def append_object(o, page, region, lang):
    if page is None: raise ValueError("page")

    if region is not None:
      name = f"p{page:03}r{region:03}"
    else:
      name = f"page{page:03}"
    if name not in PLAN:
      PLAN[name] = {'language_layers': {}, 'in_use': False}
    page_plan = PLAN[name]

    lang_key = '' if lang is None else lang
    language_layers = page_plan['language_layers']
    if lang_key not in language_layers:
      language_layers[lang_key] = []
    layers = language_layers[lang_key]

    layers.append(o)

    # if page is not None:
    #   entry['in_use'] = True
    # FIXME: should probably cancel in_use of base_name asset if lang is not None?
    #        but there's an ordering problem, I guess! Maybe we should simply build
    #        an array of all layers coming out of find_interesting_objects first, then go through
    #        it in two passes, once for lang-specific, once for generic? We'll see.

  def assign_object(o, page, region, lang):
    has_lang = (lang is not None)
    has_page = (page is not None)
    has_region = (region is not None)
    if has_page:
      # Page and region objects get assigned to their relevant page (for which language though???!?)
      append_object(o, page, region, lang)
    elif has_lang and not has_page and not has_region:
      # Language-only objects get assigned to all pages:
      for p in range(MAGE_PAGES):
        append_object(o, p, None, lang)
    elif has_page:
      pass
    elif has_page and has_region:
      # Assign to the relevant page and region
      pass
  find_interesting_objects(doc, assign_object)

def build_page_assets(page, objects, define_asset):
  page_objects = []
  region_objects = []
  lang_objects = []
  for o in objects:
    if o['page'] == p and o['region'] is not None:
      region_objects.append(o)
    elif o['page'] == p and o['region'] is None:
      page_objects.append(o)
    elif o['page'] is None and o['lang'] is not None:
      lang_objects.append(o)
  # If there's nothing specific to this page, we're not going to export it!
  if not page_objects: return
  # Figure out the languages in use for this page.
  used_langs = {}
  for o in region_objects + page_objects + lang_objects:
    lang = o['lang']
    if lang is not None:
      used_langs[lang] = True
  used_langs = used_langs.keys()
  # If any langs are used, then (for simplicity) assume they are used for all
  # assets in this page. So we reprocess the page and region lists, expanding
  # each for all langs.
  if used_langs:
    expanded_page_objects = []
    for o in page_objects:
      if o['lang'] is not None:
        expanded_page_objects.append(o)
      else:
        for lang in used_langs:
          expanded_page_objects.append({
            'layer': o['layer'],
            'page': o['page'],
            'region': o['region'],
            'lang': lang
            })
    page_objects = expanded_page_objects
    expanded_region_objects = []
    for o in region_objects:
      if o['lang'] is not None:
        expanded_region_objects.append(o)
      else:
        for lang in used_langs:
          expanded_region_objects.append({
            'layer': o['layer'],
            'page': o['page'],
            'region': o['region'],
            'lang': lang
            })
    region_objects = expanded_region_objects
  # So now the lists are ready to use.
  # Sort them for convenience of output
  page_objects.sort(key=lambda o: (o['lang'], o['page'], o['region']))
  region_objects.sort(key=lambda o: (o['lang'], o['page'], o['region']))
  # Print stuff, see where we're at...
  print()
  print("after expansion:")
  print("PAGE\tREGION\tLANG\tNAME")
  for o in page_objects + region_objects:
    print_page = o['page']
    print_region = o['region']
    print_lang = o['lang']
    print_name = o['layer']['name']
    print(f"{print_page}\t{print_region}\t{print_lang}\t'{print_name}'")

  for lang in [None] + ALL_LANGUAGES:
    layers = [o['layer'] for o in page_objects if o['lang'] == lang]
    if lang is None:
      filename = f"page{page:03}"
    else:
      filename = f"{lang}/page{page:03}"
    if not layers: continue
    define_asset(filename, layers)
    for r in range(MAX_REGIONS):
      layers = [o['layer'] for o in region_objects if o['region'] == r and o['lang'] == lang]
      if not layers: continue
      if lang is None:
        filename = f"p{page:03}r{r:03}"
      else:
        filename = f"{lang}/p{page:03}r{r:03}"
      define_asset(filename, layers)

if __name__ == '__main__':
  #import contexts
  #process_contexts(contexts.contexts_automap_p001)
  import hack
  #make_export_plan(hack.document)

  doc = hack.newbridge_document
  # doc = hack.operahouse_document

  print("PAGE\tREGION\tLANG\tNAME")
  def interesting_object(o, page, region, lang):
    o_sans_layers = dict((k, v) for (k, v) in o.items() if k != 'layers')
    name = o['name']
    print(f"{page}\t{region}\t{lang}\t'{name}'")
  find_interesting_objects(doc, interesting_object)

  # Find all the documents/groups/layers with interesting names.
  all_interesting_objects = []
  def interesting_object(o, page, region, lang):
    all_interesting_objects.append({'layer': o, 'page': page, 'region': region, 'lang': lang})
  find_interesting_objects(doc, interesting_object)

  # To allow language layers to be independent... expand...
  # So... a language layer with no page should be warned + ignored
  # A page layer with no specific language needs to be expanded to all languages in use for that page?
  all_assets = []
  def define_asset(filename, layers):
    all_assets.append({'filename': filename, 'layers': layers})
  for p in range(MAX_PAGES):
    build_page_assets(p, all_interesting_objects, define_asset)

  print()
  print("assets:")
  s = "FILENAME"
  print(f"{s:20}\tLAYERS")
  for a in all_assets:
    filename = a['filename']
    layer_names = ", ".join(l['name'] for l in a['layers'])
    print(f"{filename:20}\t{layer_names}")

# Note: when using bounds, be sure that the layer bounds doesn't exceed the doc bounds! and clip it if it does.
# Note: language-only layers should only be bound to all _pages_, not regions. When exporting a region, its
#       page's layers WILL also be made visible, IF the transparent option is off.