Download wsusoffline and build the repo. I prefer to build the repo the day before patch tuesday, microsoft usually has all the bugs worked out by then.
Running copyrepo.bat should build it into the server properly
The directory structure should look like
\\<server>\MegaScript\stuff\Phase4\wsus:
bin
cmd
cpp
dotnet
exclude
md

etc

Why does this step need to exist? If you're using kace patching, the PC's should already have the windows updates, and this won't do anything..
..in theory. In practice, laptops that are consistently offline during the patch window can be missing all of the patches.
I've seen this phase push over 80 updates to a laptop before.
Anyway, sometimes a win10 upgrade will fail on a PC that's missing patches, so this can help a lot with improving your win10 deployment numbers.
