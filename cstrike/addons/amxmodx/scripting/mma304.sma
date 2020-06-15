#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>

#if AMXX_VERSION_NUM < 190
	#include <amxx_182>
#endif

#pragma semicolon 1

//=====================================
//  VERSION CHECK
//=====================================
#if AMXX_VERSION_NUM < 182
	#assert "AMX Mod X v1.8.2 or greater library required!"
#endif
#if AMXX_VERSION_NUM < 190
	#define mma_file_exists(%1)		file_exists(%1)
#else
	#define mma_file_exists(%1)		file_exists(%1, true)
#endif

#define PLUGIN				"Music Menu Advance"
#define VERSION				"3.04"
#define AUTHOR				"Aoi.Kagase"

#define PL_CONFIG			"mma"		// nvault
#define MEDIA_LIST			"bgmlist"	// in configdir.

#define TASK_CL_CVAR		51034
#define TASK_PLAYLIST		51234
#define DEFAULT_BGM_TIME	"02:00"

enum _:CVAR_LIST
{
	LOADING_BGM,
	ROUND_BGM,
}

enum _:CVAR_VALUE
{
	V_LOADING_BGM,
	V_ROUND_BGM,
}

enum _:BGM_LIST
{
	MENU_TITLE			[32],
	FILE_PATH			[64],
	Float:BGM_TIME
}

enum _:BGM_CONFIG
{
	SHUFFLE,
	LOOP,
	Float:VOLUME,
	SHOW_HUD,
}

enum _:PLAY_STATE
{
	MANUAL_STOP,
	STOP,
	START,
	PLAYING,
}

enum _:NOW_PLAYING
{
	NUM,
	MODE,
	Float:TIME_TOTAL,
	Float:TIME_CURRENT,
	PLAY_STATE:STATE,
}

new Array:g_bgm_list;
new Array:g_bgm_no		[MAX_PLAYERS + 1];
new g_isPlaying			[MAX_PLAYERS + 1][NOW_PLAYING];
new g_config			[MAX_PLAYERS + 1][BGM_CONFIG];
new g_pcvars			[CVAR_LIST];
new g_values			[CVAR_VALUE];
new g_nv_handle;
new g_config_callback;
new g_hudobj;

// 00:00
stock Float:StrToTime(szTime[])
{
	new szMin[4], szSec[4];
	new iMin, iSec;

	replace_all(szTime, 5, ":", " ");
	parse(szTime, szMin, charsmax(szMin), szSec, charsmax(szSec));
	iMin = str_to_num(szMin);
	iSec = str_to_num(szSec);

	if (iSec >= 60)
	{
		iMin += (iSec / 60);
		iSec = 59;
	}

	iSec += (iMin * 60);
	return float(iSec);
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pcvars[LOADING_BGM] 	= create_cvar("amx_mma_loading","1");
	g_pcvars[ROUND_BGM]	  	= create_cvar("amx_mma_round",	"1");

	bind_pcvar_num		(g_pcvars[LOADING_BGM], g_values[V_LOADING_BGM]);
	bind_pcvar_num		(g_pcvars[ROUND_BGM],	g_values[V_ROUND_BGM]);

#if AMXX_VERSION_NUM >= 190
	hook_cvar_change	(g_pcvars[LOADING_BGM], "change_cvars_load");
	hook_cvar_change	(g_pcvars[ROUND_BGM],	"change_cvars_round");
#endif

	// Add your code here...
	register_clcmd		("mma", "cmdBgmMenu", -1, " - shows a menu of a Music commands");
	register_clcmd		("say", "say_mma");

	register_concmd		("amx_mma_play", "server_bgm", ADMIN_ADMIN, "amx_mma_play <BgmNumber> | server bgm starting");

	register_forward(FM_PlayerPreThink, "PlayerBgmThink");

	g_nv_handle 	  = nvault_open(PL_CONFIG);
	g_config_callback = menu_makecallback("config_menu_callback");
	g_hudobj 		  = CreateHudSyncObj(); // Create a hud object
}
#if AMXX_VERSION_NUM >= 190
public change_cvars_load(pcvar, const old_value[], const new_value[])
	g_values[V_LOADING_BGM] = str_to_num(new_value);
public change_cvars_round(pcvar, const old_value[], const new_value[])
	g_values[V_ROUND_BGM]	= str_to_num(new_value);
#endif

public PlayerBgmThink(const id)
{
	if (!is_user_connected(id) || is_user_bot(id))
		return HAM_IGNORED;

	static aBGM[BGM_LIST];
	static Float:times;

	switch(g_isPlaying[id][STATE])
	{
		case MANUAL_STOP:
		{

		}
		case STOP:
		{
			if (g_config[id][LOOP])
			{
				if (g_isPlaying[id][MODE])
				{
					if (g_isPlaying[id][NUM] < ArraySize(g_bgm_list) - 1)
						g_isPlaying[id][NUM]++;
					else
						g_isPlaying[id][NUM] = 0;

					if (g_config[id][SHUFFLE] && g_isPlaying[id][NUM] == 0)
						random_shuffle(id);
				}
				g_isPlaying[id][TIME_CURRENT] = get_gametime();
				g_isPlaying[id][STATE] 	 	  = PLAY_STATE:START;
			}
		}
		case START:
		{
			if (g_isPlaying[id][SHUFFLE] > 0 && g_isPlaying[id][NUM] == 0)
				random_shuffle(id);

			ArrayGetArray(g_bgm_list, ArrayGetCell(g_bgm_no[id], g_isPlaying[id][NUM]), aBGM, sizeof(aBGM));
			client_cmd(id, "mp3 play %s", aBGM[FILE_PATH]);
			client_print_color(id, print_chat, "^4[MMA] ^1Playing:^3%02d:[%s][%02d:%02d]", g_isPlaying[id][NUM] + 1, aBGM[MENU_TITLE], floatround(aBGM[BGM_TIME]) / 60, floatround(aBGM[BGM_TIME]) % 60);
			g_isPlaying[id][TIME_TOTAL] 	= aBGM[BGM_TIME];
			g_isPlaying[id][TIME_CURRENT]	= get_gametime();
			g_isPlaying[id][STATE]			= PLAY_STATE:PLAYING;
		}
		case PLAYING:
		{
			if (g_config[id][SHOW_HUD])
			{
				times = get_gametime() - g_isPlaying[id][TIME_CURRENT];
				times = (times / g_isPlaying[id][TIME_TOTAL] * 100.0) / 10.0;

				if (times < g_isPlaying[id][TIME_TOTAL])
					show_time_bar(id, floatround(times), (g_isPlaying[id][TIME_TOTAL] / 10.0));
				else
					g_isPlaying[id][STATE] = PLAY_STATE:STOP;
			}

			if ((get_gametime() - g_isPlaying[id][TIME_CURRENT]) >= g_isPlaying[id][TIME_TOTAL])
			{
				g_isPlaying[id][TIME_CURRENT] = get_gametime();
				g_isPlaying[id][STATE] 	 	  = PLAY_STATE:STOP;
			}
		}
	}

	return HAM_IGNORED;
}

show_time_bar(id, percent, Float:hold)
{
	new bar[11] = "==========";
	static oldpercent[33];

	if (oldpercent[id] != percent)
	{
		for(new i = 0; i < percent; i++)
			bar[i] = '>';
		set_hudmessage(0, 255, 255, 0.30, 0.95, 0 , 0.0, hold, 0.0, 0.0, 4);
	//	show_hudmessage(id, "BGM:[%s]", bar);
		ShowSyncHudMsg(id, g_hudobj, "BGM:[%s]", bar);
	}
	oldpercent[id] = percent;
}

//====================================================
// Chat command.
//====================================================
public say_mma(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	new said[32], sLeft[5], sRight[27];
	read_argv(1, said, charsmax(said));
	argbreak(said, sLeft, charsmax(sLeft), sRight, charsmax(sRight));

	if (equali(sLeft,"/bgm") 
	||	equali(sLeft,"/mma"))
	{
		if (equali(sRight, "config"))
			config_showmenu(id);
		else
			music_showmenu(id);
	}  
	return PLUGIN_CONTINUE;
}

public cmdBgmMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	music_showmenu(id);
	return PLUGIN_HANDLED;
}

public plugin_precache()
{
	new iniFile		[64];
	new sConfigDir	[64];
	new aBGM		[BGM_LIST];

	get_configsdir(sConfigDir, charsmax(sConfigDir));
	formatex(iniFile, charsmax(iniFile), "%s/%s.ini", sConfigDir, MEDIA_LIST);

	load_bgm_files(iniFile);

	for(new i = 0; i < ArraySize(g_bgm_list); i++)
	{
		ArrayGetArray(g_bgm_list, i, aBGM, sizeof(aBGM));
		if (mma_file_exists(aBGM[FILE_PATH]))
			precache_generic(aBGM[FILE_PATH]);
	}
	server_print("Server BGMs Loaded (%i BGMs)", ArraySize(g_bgm_list));
}

load_bgm_files(sFileName[])
{ 
	if (!file_exists(sFileName))
		return;

	new sRec		[128];
	new sRecLen 	= charsmax(sRec);

	new sBlocks		[3][64];
	new aBGM		[BGM_LIST];

	new fp 			= fopen(sFileName, "r");
	new iCount 		= 0;

	g_bgm_list		= ArrayCreate(BGM_LIST);
	for(new i = 0; i < 33; i++)
		g_bgm_no[i]	= ArrayCreate();

	while(!feof(fp))
	{
		if (fgets(fp, sRec, sRecLen) == 0)
			break;

		trim(sRec);

		if (sRec[0] == ';')
			continue;

		formatex(sRec, sRecLen, "%s%s", sRec, ";");

		explode_string(sRec, ";", sBlocks, sizeof(sBlocks), charsmax(sBlocks[]));
		for(new i = 0; i < 3; i++)
			trim(sBlocks[i]);

		if (mma_file_exists(sBlocks[1]))
		{
			copy(aBGM[MENU_TITLE], charsmax(aBGM[MENU_TITLE]), sBlocks[0]);
			copy(aBGM[FILE_PATH],  charsmax(aBGM[FILE_PATH]),  sBlocks[1]);
			if (strlen(sBlocks[2]) <= 0)
				aBGM[BGM_TIME] = StrToTime(DEFAULT_BGM_TIME);
			else
				aBGM[BGM_TIME] = StrToTime(sBlocks[2]);

			ArrayPushArray(g_bgm_list, aBGM, sizeof(aBGM));
			for (new j = 0; j < 33; j ++)
				ArrayPushCell(g_bgm_no[j], iCount);

			iCount++;
		}
		else
		{
			server_print("File not exists: %s", sBlocks[1]);
			continue;
		}
	}
	fclose(fp);
} 

public client_connect(id)
{
	if(g_values[V_LOADING_BGM])
	{
		if (!is_user_bot(id))
		{
			new aBGM[BGM_LIST];
			new j = random_num(0, ArraySize(g_bgm_list) - 1);
			ArrayGetArray(g_bgm_list, j, aBGM, sizeof(aBGM));
			client_cmd(id, "mp3 play %s", aBGM[FILE_PATH]);
			random_shuffle(id);
		}
	}
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	if (is_user_bot(id))
		return PLUGIN_CONTINUE;

	g_isPlaying[id][STATE] = PLAY_STATE:MANUAL_STOP;
	random_shuffle(id);

	set_task_ex(0.1, "get_cl_cvar", id + TASK_CL_CVAR);
	return PLUGIN_CONTINUE;
}

public get_cl_cvar(id)
{
	id -= TASK_CL_CVAR;
	query_client_cvar(id, "MP3volume", "set_mp3_volume");

	new authid[MAX_AUTHID_LENGTH], temp[2], timestamp;
	get_user_authid(id, authid, charsmax(authid));

	if (nvault_lookup(g_nv_handle, fmt("%s_SHUFFLE",authid), temp, charsmax(temp), timestamp) == 1)
		g_config[id][SHUFFLE]	= str_to_num(temp);
	else
		g_config[id][SHUFFLE]	= 1;
	
	if (nvault_lookup(g_nv_handle, fmt("%s_LOOP",authid), temp, charsmax(temp), timestamp) == 1)
		g_config[id][LOOP]		= str_to_num(temp);
	else
		g_config[id][LOOP]		= 1;

	if (nvault_lookup(g_nv_handle, fmt("%s_SHOWHUD",authid), temp, charsmax(temp), timestamp) == 1)
		g_config[id][SHOW_HUD]	= str_to_num(temp);
	else
		g_config[id][SHOW_HUD]	= 1;

	if (g_values[V_ROUND_BGM])
	{
		g_isPlaying[id][MODE]  = 1; // playlist
		g_isPlaying[id][NUM]   = 0;
		g_isPlaying[id][STATE] = PLAY_STATE:START;
	}
	else
		g_isPlaying[id][STATE] = PLAY_STATE:MANUAL_STOP;
}

public client_disconnected(id)
{
	new authid[MAX_AUTHID_LENGTH];
	get_user_authid(id, authid, charsmax(authid));
	nvault_set(g_nv_handle, fmt("%s_SHUFFLE", authid), fmt("%d", g_config[id][SHUFFLE]));
	nvault_set(g_nv_handle, fmt("%s_LOOP", 	  authid), fmt("%d", g_config[id][LOOP]));
	nvault_set(g_nv_handle, fmt("%s_SHOWHUD", authid), fmt("%d", g_config[id][SHOW_HUD]));	
}

public set_mp3_volume(id, const cvar[], const value[])
{
	g_config[id][VOLUME] = str_to_float(value);
}

public server_bgm()
{
	new aBGM	[BGM_LIST];
	new arg		[3];
	read_argv(1, arg, charsmax(arg));

	new num 	 = str_to_num(arg);
	new bgmCount = ArraySize(g_bgm_list);

	if (bgmCount <= 0)
	{
		server_print("BGM isn't registered.");
		return PLUGIN_HANDLED;
	} 
	else
	{
		if (0 < num <= bgmCount)
		{
			ArrayGetArray(g_bgm_list, num - 1, aBGM, sizeof(aBGM));
			// All Player Command.
			client_cmd(0, "mp3 stop");
			client_cmd(0, "mp3 play %s", aBGM[FILE_PATH]);
			client_print_color(0, print_chat, "^4[MMA] ^3ADMIN: BGM START! ^2[%s]", aBGM[MENU_TITLE]);
		}
		else
		{
			server_print("BGM isn't registered in this number.");
		}
	}
	return PLUGIN_HANDLED;
}

config_showmenu(id)
{
	new menu = menu_create("Music Menu: Config", "config_menu_handler");
	menu_additem(menu, "Show Time bar^t",	"",	 0, g_config_callback);
	menu_additem(menu, "Playlist Mode^t",	"",	 0, g_config_callback);
	menu_additem(menu, "Loop Mode^t",		"",	 0, g_config_callback);
	menu_additem(menu, "Volume Up",			"",	 0, g_config_callback);
	menu_additem(menu, "Volume Down",		"",	 0, g_config_callback);

	new volbar[] = "VOL:\r[||||||||||||||||||||||\r]";
	new pos = 7 + (floatround(g_config[id][VOLUME] * 10.0, floatround_floor) * 2);
	volbar[pos++] = '\';
	volbar[pos++] = 'y';
	menu_addblank(menu);
	menu_addtext(menu, volbar, 0);

    // We now have all players in the menu, lets display the menu
	menu_display(id, menu, 0);
}

public config_menu_callback(id, menu, item)
{
	new szData[6], szName[64], access, callback;
	//Get information about the menu item
	menu_item_getinfo(menu, item, access, szData, charsmax(szData), szName, charsmax(szName), callback);

	switch (item)
	{
		case 0:
			menu_item_setname(menu, item, fmt("Show Time bar^t\y[%s]", ((g_config[id][SHOW_HUD] > 0) ? "ON" : "OFF")));
		case 1:
			menu_item_setname(menu, item, fmt("Playlist Mode^t\y[%s]", ((g_config[id][SHUFFLE] > 0) ? "in Shuffle" : "in Order")));
		case 2:
			menu_item_setname(menu, item, fmt("Loop Mode^t^t\y[%s]", ((g_config[id][LOOP] > 0) ? "ON" : "OFF")));
	}
	return PLUGIN_CONTINUE;
}

public config_menu_handler(id, menu, item)
{
	// Do a check to see if they exited because menu_item_getinfo ( see below ) will give an error if the item is MENU_EXIT
	if (item == MENU_EXIT)
	{
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }
		
	// now lets create some variables that will give us information about the menu and the item that was pressed/chosen
	new szData[64 + 6], szName[32];
	new _access, item_callback;
	// heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo(menu, item, _access, szData, charsmax(szData), szName, charsmax(szName), item_callback);

	switch(item)
	{
		case 0:
			g_config[id][SHOW_HUD]= (g_config[id][SHOW_HUD] > 0) ? 0 : 1;
		case 1:
			g_config[id][SHUFFLE] = (g_config[id][SHUFFLE] > 0) ? 0 : 1;
		case 2:
			g_config[id][LOOP]	  = (g_config[id][LOOP] > 0) ? 0 : 1;
		case 3:
		{
			if (g_config[id][VOLUME] < 1.0)
				g_config[id][VOLUME] += 0.1;
			else
				g_config[id][VOLUME] = 1.0;

			client_cmd(id, "MP3volume %.1f", g_config[id][VOLUME]);
		}
		case 4:
		{
			if (g_config[id][VOLUME] > 0.0)
				g_config[id][VOLUME] -= 0.1;
			else
				g_config[id][VOLUME] = 0.0;

			client_cmd(id, "MP3volume %.1f", g_config[id][VOLUME]);
		}
	}
	config_showmenu(id);
	return PLUGIN_HANDLED;
}

//====================================================
// Main menu.
//====================================================
music_showmenu(id)
{
    // Some variables to hold information about the players
	new szNum	[5];
	new aBGM	[BGM_LIST];

    // Create a variable to hold the menu
	new menu = menu_create("Music Menu: BGM-List",	"music_menu_handler");
	menu_additem(menu, "Play All.",	"all", 	0);
	menu_additem(menu, "STOP BGM.",	"stop", 0);
	menu_addblank(menu, 0);
	for(new i = 0; i < ArraySize(g_bgm_list); i++)
	{
		ArrayGetArray(g_bgm_list, i, aBGM, sizeof(aBGM));
		num_to_str(i, szNum, charsmax(szNum));
        // Add the item for this player
		menu_additem(menu, aBGM[MENU_TITLE], szNum, 0);
    }
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");

    // We now have all players in the menu, lets display the menu
	menu_display(id, menu, 0);
}

public music_menu_handler(id, menu, item)
{
	// Do a check to see if they exited because menu_item_getinfo ( see below ) will give an error if the item is MENU_EXIT
	if (item == MENU_EXIT)
	{
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }
		
	// now lets create some variables that will give us information about the menu and the item that was pressed/chosen
	new szData[5], szName[32];
	new _access, item_callback;
	// heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo(menu, item, _access, szData, charsmax(szData), szName, charsmax(szName), item_callback);

	client_cmd(id, "mp3 stop");
	g_isPlaying[id][MODE] 		= 0; // single
	g_isPlaying[id][NUM]  		= 0;
	g_isPlaying[id][STATE] 		= PLAY_STATE:MANUAL_STOP;

	if (equali("stop", szData))
	{
		client_print_color(id, print_chat, "^4[MMA] ^1BGM Stopped.");
	}
	else if (equali("all", szData))
	{
		if (g_config[id][SHUFFLE])
			random_shuffle(id);

		client_print_color(id, print_chat, "^4[MMA] ^1BGM Start!:^3Playlist.");
		g_isPlaying[id][MODE] 		= 1; // playlist
		g_isPlaying[id][STATE] 		= PLAY_STATE:START;
	}
	else
	{
		new num = str_to_num(szData);		
		client_print_color(id, print_chat, "^4[MMA] ^1BGM Start!:^3[%s]", szName);
		g_isPlaying[id][MODE] 		= 0; // single
		g_isPlaying[id][NUM]  		= num;
		g_isPlaying[id][STATE] 		= PLAY_STATE:START;
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public plugin_end()
{
	ArrayDestroy(g_bgm_list);
	for(new i = 0; i < 33; i++)
		ArrayDestroy(g_bgm_no[i]);

	nvault_close(g_nv_handle);
}

stock random_shuffle(id)
{
	new a, b, tmp;
	for(new i = ArraySize(g_bgm_no[id]); i > 1; --i)
	{
		a	= i - 1;
		b	= random_num(0, ArraySize(g_bgm_no[id]) - 1);
		tmp = ArrayGetCell(g_bgm_no[id], a);
		ArraySetCell(g_bgm_no[id], a, ArrayGetCell(g_bgm_no[id], b));
		ArraySetCell(g_bgm_no[id], b, tmp);
    }
}

