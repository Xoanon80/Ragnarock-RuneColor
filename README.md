# Ragnarock - RuneColorVR Mod

**Lua script to change Rune Colors in Ragnarock VR.**

> [!WARNING]
> This works only in VR mode, Flat mode would crash.
> If you play both, make sure you deactivate the Mod whenever you start the Flat version.
> This is for the Steam PCVR version of Ragnarock.

# Features

- Change VR rune colors via simple config file editing
- 20+ named color presets included (`rune_palette.cfg`)
- Custom color mode with full HEX control (body, glow, emissive boost)
- Rainbow mode — runes continuously cycle through colors

# Screenshots

![Screenshots](assets/screenshots.jpg)

# Prerequisites

[UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) (UE4SS_v3.0.1-1028-gd7e7826d.zip) must be installed.<br />
A backup of this version is kept in a sub-directory of this repository.<br />
Contents from UE4SS zip go into your Win64 directory of your Ragnarock installation, for example<br />
```C:\Program Files (x86)\Steam\steamapps\common\Ragnarock\Ragnarock\Binaries\Win64```

# Installing Mod

1. Extract [RuneColorVRMod](RuneColorVRMod.zip) and place into the Mods-directory of UE4SS, for example:<br />
```C:\Program Files (x86)\Steam\steamapps\common\Ragnarock\Ragnarock\Binaries\Win64\ue4ss\Mods```

2. Activate Mod<br />
Add "**RuneColorMod: 1**" to mods.txt (right before the line "**; Built-in keybinds, do not move up!**)"<br />
It is located in the same directory as above.

# Configuration

Edit the active_color.cfg in your RuneColorVR mod directory to your liking.<br />

**Options** are:<br />

<table>
<tr><th>Value</th><th>Description</th></tr>
<tr><td><code>off</code></td><td>Use the game's built-in colors</td></tr>
<tr><td><code>custom</code></td><td>Use the <code>custom_...</code> values defined in this file</td></tr>
<tr><td><code>PRESETNAME</code></td><td>Use a named preset from <code>rune_palette.cfg</code></td></tr>
<tr><td><code>rainbow</code></td><td>Runes continuously cycle through colors</td></tr>
</table>

Colors work with HEX values and a value for brightness boost, like: 

<table>
<tr><th>Field</th><th>Meaning</th></tr>
<tr><td>Body color</td><td>Main/base color (1st hex value)</td></tr>
<tr><td>Glow color</td><td>Rune sign color &amp; borders (2nd hex value)</td></tr>
<tr><td>Emissive boost</td><td>Brightness multiplier, default <code>1.0</code> (3rd value)</td></tr>
</table>

---

# Project Support

For issues related to this Mod:
- Discord: @xoanon
- GitHub: https://github.com/Xoanon80
