#include <amxmodx>
#include <amxmisc>
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

#define PL_CONFIG			"mma"
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

}

new Array:g_bgm_list;
new Array:g_bgm_no		[MAX_PLAYERS + 1];
new  bool:g_isPlaying	[MAX_PLAYERS + 1];
new g_config			[MAX_PLAYERS + 1][BGM_CONFIG];
new g_pcvars			[CVAR_LIST];
new g_values			[CVAR_VALUE];
new g_nv_handle;
new g_config_callback;

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


	g_nv_handle 	  = nvault_open(PL_CONFIG);
	g_config_callback = menu_makecallback("config_menu_callback");

}
#if AMXX_VERSION_NUM >= 190
public change_cvars_load(pcvar, const old_value[], const new_value[])
	g_values[V_LOADING_BGM] = str_to_num(new_value);
public change_cvars_round(pcvar, const old_value[], const new_value[])
	g_values[V_ROUND_BGM]	= str_to_num(new_value);
#endif
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
		}
	}
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	if (is_user_bot(id))
		return PLUGIN_CONTINUE;

	g_isPlaying[id] = false;
	if (g_values[V_ROUND_BGM])
	{
		new szNum[5];
		formatex(szNum, charsmax(szNum), "%d %d", 0, 1);
		set_task(0.1, "playlist_playing", id + TASK_PLAYLIST, szNum, charsmax(szNum));
	}
	new authid[MAX_AUTHID_LENGTH];
	get_user_authid(id, authid, charsmax(authid));
	g_config[id][SHUFFLE] = nvault_get(g_nv_handle, fmt("%s_SHUFFLE", authid));
	g_config[id][LOOP] 	  = nvault_get(g_nv_handle, fmt("%s_LOOP", 	  authid));

	set_task_ex(0.1, "get_cl_cvar", id + TASK_CL_CVAR);
	return PLUGIN_CONTINUE;
}

public get_cl_cvar(id)
{
	id -= TASK_CL_CVAR;
	query_client_cvar(id, "MP3volume", "set_mp3_volume");
}

public client_disconnected(id)
{
	new authid[MAX_AUTHID_LENGTH];
	get_user_authid(id, authid, charsmax(authid));
	nvault_set(g_nv_handle, fmt("%s_SHUFFLE", authid), g_config[id][SHUFFLE]);
	nvault_set(g_nv_handle, fmt("%s_LOOP", 	  authid), g_config[id][LOOP]);
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
			menu_item_setname(menu, item, fmt("Playlist Mode^t\y[%s]", ((g_config[id][SHUFFLE] > 0) ? "in Shuffle" : "in Order")));
		case 1:
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
			g_config[id][SHUFFLE] = (g_config[id][SHUFFLE] > 0) ? 0 : 1;
		case 1:
			g_config[id][LOOP]	  = (g_config[id][LOOP] > 0) ? 0 : 1;
		case 2:
		{
			if (g_config[id][VOLUME] < 1.0)
				g_config[id][VOLUME] += 0.1;
			else
				g_config[id][VOLUME] = 1.0;

			client_cmd(id, "MP3volume %.1f", g_config[id][VOLUME]);
		}
		case 3:
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
	new szData[5], szName[32], szNum[5];
	new _access, item_callback;
	// heres the function that will give us that information ( since it doesnt magicaly appear )
	menu_item_getinfo(menu, item, _access, szData, charsmax(szData), szName, charsmax(szName), item_callback);



	if (task_exists(id + TASK_PLAYLIST))
	{
		g_isPlaying[id] = false;
		client_cmd(id, "mp3 stop");
		remove_task(id + TASK_PLAYLIST);
	}

	if (equali("stop", szData))
	{
		client_cmd(id, "mp3 %s", szData);
		client_print_color(id, print_chat, "^4[MMA] ^1BGM Stopped.");
	}
	else if (equali("all", szData))
	{
		if (g_config[id][SHUFFLE])
			formatex(szNum, charsmax(szNum), "%d %d", 0, 1);
		else
			formatex(szNum, charsmax(szNum), "%d %d", 0, 0);

		client_print_color(id, print_chat, "^4[MMA] ^1BGM Start!:^3Playlist.");
		set_task(0.1, "playlist_playing", id + TASK_PLAYLIST, szNum, sizeof(szNum));
	}
	else
	{
		client_print_color(id, print_chat, "^4[MMA] ^1BGM Start!:^3[%s]", szName);
		set_task(0.1, "single_playing", id + TASK_PLAYLIST, szData, sizeof(szData));
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public single_playing(szData[], taskid)
{
	new id = taskid - TASK_PLAYLIST;
	new num = str_to_num(szData);
	new aBGM[BGM_LIST];

	ArrayGetArray(g_bgm_list, num, aBGM, sizeof(aBGM));

	if (g_isPlaying[id])
	{
		if (g_config[id][LOOP])
		{
			client_cmd(id, "mp3 play %s", aBGM[FILE_PATH]);
			set_task(aBGM[BGM_TIME], "single_playing", taskid, szData, 5);
		}
		else
			g_isPlaying[id] = false;
	}
	else
	{
		g_isPlaying[id] = true;
		client_cmd(id, "mp3 play %s", aBGM[FILE_PATH]);
		set_task(aBGM[BGM_TIME], "single_playing", taskid, szData, 5);
	}
	return PLUGIN_CONTINUE;
}

public playlist_playing(param[], taskid)
{
	new aBGM[BGM_LIST];
	new num, szNum[5];
	new id = taskid - TASK_PLAYLIST;

	if (!is_user_connected(id) || is_user_bot(id))
		return PLUGIN_HANDLED;

	new a[3], b[2];
	parse(param, a, charsmax(a), b, charsmax(b));
	num = str_to_num(a);
	if (str_to_num(b))
	{
		if (!g_isPlaying[id])
			random_shuffle(id);

		num = ArrayGetCell(g_bgm_no[id], num);
	}


	ArrayGetArray(g_bgm_list, num, aBGM, sizeof(aBGM));
	client_cmd(id, "mp3 play %s", aBGM[FILE_PATH]);
	client_print_color(id, print_chat, "^4[MMA] ^1Playing:^3%02d:[%s][%02d:%02d]", str_to_num(a) + 1, aBGM[MENU_TITLE], floatround(aBGM[BGM_TIME]) / 60, floatround(aBGM[BGM_TIME]) % 60);

	g_isPlaying[id] = true;
	new no_temp = str_to_num(a) + 1;
	if (no_temp < ArraySize(g_bgm_list))
	{
		formatex(szNum, charsmax(szNum), "%d %d", no_temp, str_to_num(b));
		set_task(aBGM[BGM_TIME], "playlist_playing", taskid, szNum, sizeof(szNum));
		return PLUGIN_CONTINUE;
	}

	if (g_config[id][LOOP])
	{
		no_temp = 0;
		formatex(szNum, charsmax(szNum), "%d %d", no_temp, str_to_num(b));
		set_task(aBGM[BGM_TIME], "playlist_playing", taskid, szNum, sizeof(szNum));
		return PLUGIN_CONTINUE;
	}
	g_isPlaying[id] = false;
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

