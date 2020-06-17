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
1. amx_mma_loadingsong
	- loadingsong 1 to on, 0 to off.

2. amx_mma_round
	- round bgm 1 to on, 0 to off.

### Commnads:
1. amx_mma_play <BgmNumber> 
	- server bgm starting
2. say /mma or /bgm
	- shows a menu of a Music commands.
3. say /mma config or /bgm config
	- show a menu of a config commands.