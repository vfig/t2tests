from contexts import *

contexts = contexts_automap_p001

show_debug_messages = False

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
