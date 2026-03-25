> [!NOTE]
> README in construction. Things are subject to change.

# Beatrun (Legacy)

Older version of infamous parkour gamemode Beatrun for Garry's Mod, now with extracted source code and modifications/improvements (?).

This is based off of a dump of v1.01 [^1]. Last modified October 14th 2022 (content 1:53 PM, binaries 2:20 PM *(client)* / 2:22 PM *(server)*)

See the [`kitbashed`](https://github.com/UnderSet/beatrun-legacy/tree/kitbashed) branch if the version originally uploaded to this repository is what you're looking for.

If you're looking for what this is based off of, it's on the [`1.0.1`](https://github.com/UnderSet/beatrun-legacy/tree/1.0.1) branch.

> [!IMPORTANT]
> You *really* shouldn't play this version.
> 
> This (v1.01) is an old version from late 2022 and is *incompatible* with (most?) current Beatrun courses, and has *drastically different gameplay*.
>
> Try [Beatrun Community Edition](https://steamcommunity.com/sharedfiles/filedetails/?id=3467179024) if the newest Beatrun's what you're looking for.
>
> This version has some backported stuff from Community Edition so it can load Community Edition courses, however I would not recommend doing so anyway.

> [!CAUTION]
> [**VManip**](https://steamcommunity.com/sharedfiles/filedetails/?id=2155366756) is a **requirement** for this version of Beatrun to work correctly. [^2] A version is [included in this repository](/vmaniprework/) that is known to work with this version of Beatrun.
>
> ~~**Do not** have Beatrun Community Edition enabled with this addon also installed. You *will* run into issues. This will be fixed at some point...probably.~~ This has been fixed.

### How-

[**x64dbg**](https://github.com/x64dbg/x64dbg) and a little bit of patience.

### Changes
- Fixed some stuff that was causing Lua errors due to changes in GMod between 2022 and now
- Backported some stuff from Community Edition *(see above)*
    - ***Course database is not available.*** Download courses using Beatrun Community Edition. Saved courses can be loaded normally.
  - Notably: Build Mode and course entities
    - This allows you to play modern Beatrun courses on this version...not that you should
    - *Incomplete implementation* - many visual aspects have been removed/not fixed for the sake of it just working and some stuff still doesn't work right

### Credits
- [**Beatrun Community Edition contributors**](https://github.com/JonnyBro/beatrun/graphs/contributors)
- [**JonnyBro**](https://github.com/jonnybro) and **relaxtakenotes** for Beatrun Community Edition (which inspired this whole thing) and `lual_loadbuffer` method (`lual_loadbufferx` in my case), which made all this possible
- **EL1S1ON** for files of this version
- [**x64dbg**](https://github.com/x64dbg/x64dbg), which I used to make this
- **datae** for creating Beatrun
- [x14y24HeadsUpDaisy font](https://hicchicc.github.io/00ff/)
- [Datto D-DIN font](https://github.com/amcchord/datto-d-din)
- scubamaster96 (on Discord) for grayscale icon idea

[^1]: The files of this version I got was labeled v1.0.1 for somme reason.

[^2]: Another version might be required... I'll upload it into this repository if that turns out to be the case.
