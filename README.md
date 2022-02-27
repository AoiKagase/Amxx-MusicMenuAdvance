# Music Menu Advance
### Description:
>Open the background music list set on the server from the menu and play the MP3 file on the client side.
---
### Modules:
- <font color="red">[required]: **AMXMODX v1.9.0**  (split_string function does not exist in v1.8.2)</font>
- (3.03alpha:1.8.2 and cromchat.inc)

---
## Usage:
### Installation:
- Introduce the INI file which described a MP3 file in the Config dir. "addons/amxmodx/configs/bgmlist.ini"
- and all mp3 files in <font color="blue">"[modname_directory]/"</font> folder.
- Edit INI file
	- ``` "music title";"[directory]/[mp3 filename]";"[TIME FORMAT MM:SS]"```
	- example: 
```
HL-BGM 01;media/Half-Life01.mp3;02:12
HL-BGM 02;media/Half-Life02.mp3;01:47
```
- <font color="red">**Attention: Please note that the maximum number that can be precached is 512.**</font>

### Cvars:
| Cvars | Value | Default | Description |
|-------|-------|---------|-------------|
| amx_mma_loadingsong | `0` or `1` | `1` | BGM from loading enabled. 0 = OFF, 1 = ON |
| amx_mma_round | `0` or `1` | `1` | Play BGM on join. 0 = OFF, 1 = ON |

### Commnads:
| Commands | Value | Description |
|----------|-------|-------------|
| amx_mma_play | `BgmNumber` | All player BGM play starting. |
| say /mma |/2. |/2. Shows a menu of a Music commands.
| say /bgm |
| say /mma config |/2. |/2.show a menu of a config commands.
| say /bgm config |
