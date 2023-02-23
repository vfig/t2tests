# Demonstration of "Briefing books"

This mission demonstrates using books to stand in for briefing and cutscene videos--a feature that has existed since OldDark. It also shows how you can use NewDark's decals and qvar-controlled decal groups to change what is displayed in a post-mission cutscene book. To see this in action, play the mission a second time and make the other choice.

The Squirrel scripts used in this mission are not needed for the briefing books feature; they are only handling the qvars for this demo.

This demo mission was made for Thief 2, NewDark 1.27. But the techniques demonstrated here should work for any Thief version.


# Tutorial: Books for briefings

Thief has the ability to display a book instead of playing a movie, if the movie file cannot be found. This is very useful if you don't have a briefing movie, but would like players to have a chance to read your mission briefing text, even if they never open the readme.

This book can also be made available in different languages, just like any other book. This feature works in TDP/TG and T2. I'm using NewDark in this tutorial because of the convenience of providing configuration options in fm.cfg, but the core feature works in OldDark too.

## Using a book for the mission briefing

Decide which book art you want to use for the briefing. I'm going to use "parch" in this tutorial. If you use a different book art, just replace the name "parch" everywhere with the book art you chose.

In this tutorial, my mission is number 20, i.e. miss20.mis. If your mission is a different number, you'll need to name the book accordingly.

1. Create a book art folder books/parch/ in your mission's folder, and copy the book art and font files (book.pcx and so on) into there. The main book art file at least must be in your mission's folder/zip, or the book will not be shown.

2. Edit (or create) the config file fm.cfg in your mission folder, and add this line:

    default_text_bg parch

3. Create the briefing book file in your mission's books folder, books/english/b20.str and put your briefing text into it. If your briefing has been translated into other languages, create additional book files in the appropriate folder for each language.

That's it. When you launch the game with your mission, the book will be shown when you start the mission.

If you later decide to make a briefing video, you don't need to change any of the above: if the game finds `movies/b20.avi`, it will always try to play that instead of showing the briefing book.

Note: it is important not to copy the book art's fonts into your mission, or language patches that need custom fonts, such as Russian, will end up using the wrong font when showing the briefing book. However, if the book art is paletted, players with "enhancement" packs installed may end up with unreadable readables if the "enhanced" font's palette is different from the default palette; so stick with .png or other non-paletted book art for safety.

## Advanced options

Any video can have a book shown instead. If your missflag.str specifies "cutscene" for your mission, but you don't have a `movies/cs20.avi`, then the game will look for `books/english/cs20.str`, and show it if it can find it. If you have a campaign with multiple missions, this is an easy way to provide information between missions.

If you have more than one book, whether for briefings in a campaign, or in place of post-mission cutscenes, you can use a different book art for each movie if you want: you must add a line like this for each book with different art to your fm.cfg — replace "cs20" and "parch" here with the name of the book and the name of the art you want to use — and you must make sure you copy the art folder into your mission:

    cs20_text_bg parch

This technique is not new, but as far as I can find has never been written up in a tutorial. I'm doing that now because I think it's really nice to have the mission briefing text shown in the game, and wish more FMs without briefing movies could have done so.
