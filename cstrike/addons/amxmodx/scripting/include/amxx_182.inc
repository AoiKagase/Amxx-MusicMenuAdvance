#if AMXX_VERSION_NUM < 190
// =====================================
//	Amxmodx 1.8.2 Functions.
//
// 	by Aoi.Kagase
// =====================================

#if defined _amxx_182_included
	#endinput
#endif
#define _amxx_182_included
#include <cromchat>

#define MAX_PLAYERS							32
#define MAX_NAME_LENGTH 					32
#define MAX_AUTHID_LENGTH 					64
#define MAX_RESOURCE_PATH_LENGTH 			64
#define MAX_MENU_LENGTH 					512
#define HIT_SHIELD							8
#define Ham_CS_Player_ResetMaxSpeed 		Ham_Item_PreFrame
#define client_disconnected(%1,%2,%3,%4) 	client_disconnect(%1)

/**
 * SetTaskFlags constants for set_task_ex()
 */
enum SetTaskFlags (<<= 1)
{
	SetTask_Once = 0,          // None; execute callback after the specified amount of time (Default)
	SetTask_RepeatTimes = 1,   // Repeat timer a set amount of times
	SetTask_Repeat,            // Loop indefinitely until timer is stopped
	SetTask_AfterMapStart,     // Time interval is treated as absolute time after map start
	SetTask_BeforeMapChange    // Time interval is treated as absolute time before map change
};
/**
 * GetPlayerFlags constants for get_players_ex()
 */
enum GetPlayersFlags (<<= 1)
{
	GetPlayers_None = 0,           // No filter (Default)
	GetPlayers_ExcludeDead = 1,    // Do not include dead clients
	GetPlayers_ExcludeAlive,       // Do not include alive clients
	GetPlayers_ExcludeBots,        // Do not include bots
	GetPlayers_ExcludeHuman,       // Do not include human clients
	GetPlayers_MatchTeam,          // Match with team
	GetPlayers_MatchNameSubstring, // Match with part of name
	GetPlayers_CaseInsensitive,    // Match case insensitive
	GetPlayers_ExcludeHLTV,        // Do not include HLTV proxies
	GetPlayers_IncludeConnecting   // Include connecting clients
};
stock ArrayFindString(Array:which, const item[])
{
	new szValue[64], count = ArraySize(which);
	for (new i = 0; i < count; i++)
	{
		ArrayGetString(which, i, szValue, charsmax(szValue));
		if (equali(item, szValue))
			return i;
	}
	return -1;
}

stock register_event_ex(const event[], const function[], const flags[], const cond[] = "", ...)
{
	register_event(event, function, flags, cond);
}

stock create_cvar(const name[], const string[], flags = 0, const description[] = "", bool:has_min = false, Float:min_val = 0.0, bool:has_max = false, Float:max_val = 0.0)
{
	new temp[128];
	// Avoid Warning
	formatex(temp, charsmax(temp), "%s%s%s%s%s", description, has_min, min_val, has_max, max_val);
	log_amx(temp);
	return register_cvar(name, string, flags);
}

stock bind_pcvar_num(pointer, &value)
	value = get_pcvar_num(pointer);

stock bind_pcvar_float(pointer, &Float:value)
	value = get_pcvar_float(pointer);

stock bind_pcvar_string(pointer, any:value[], len)
	get_pcvar_string(pointer, value, len);

stock fmt(const szString[], any:...)
{
	new result[512];
	vformat(result, charsmax(result), szString, 2);
	return result;
}

stock set_task_ex(Float:time, const function[], id = 0, const any:parameter[] = "", len = 0, SetTaskFlags:flags = SetTask_Once, repeat = 0)
{
	new strFlags[2]; // There should never be a need to set more than 1 flag
	get_flags(_:flags, strFlags, charsmax(strFlags));
	set_task(time, function, id, parameter, len, strFlags, repeat);
}

stock split_string(const szSource[], const szDelim[], szParsed[], iMaxChars)
{
    new iPos = strfind(szSource, szDelim);
    return (iPos > -1) ? copy(szParsed, min(iPos, iMaxChars), szSource) + strlen(szDelim) : -1;
}

/**
 * Calls a function after a specified time has elapsed.
 *
 * @param time          Time interval to assign
 * @param function      Function to execute
 * @param id            Task id to assign
 * @param parameter     Data to pass through to callback
 * @param len           Size of data
 * @param flags         Optional flags (enum SetTaskFlags); valid flags are:
 *                        SetTask_Once - Execute callback once (Default)
 *                        SetTask_RepeatTimes - repeat timer a set amount of times
 *                        SetTask_Repeat - loop indefinitely until timer is stopped
 *                        SetTask_AfterMapStart - time interval is treated as absolute
 *                            time after map start
 *                        SetTask_BeforeMapChange - time interval is treated as absolute
 *                            time before map change
 * @param repeat        If the SetTask_RepeatTimes flag is set, the task will be repeated this
 *                      many times
 *
 * @noreturn
 * @error               If an invalid callback function is provided, an error is
 *                      thrown.
 */
stock set_task_ex(Float:time, const function[], id = 0, const any:parameter[] = "", len = 0, SetTaskFlags:flags = SetTask_Once, repeat = 0)
{
	new strFlags[2]; // There should never be a need to set more than 1 flag
	get_flags(_:flags, strFlags, charsmax(strFlags));
	set_task(time, function, id, parameter, len, strFlags, repeat);
}

/**
 * Stores a filtered list of client indexes to an array.
 *
 * @note Example retrieving all alive CTs:
 *       get_players_ex(players, num, GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT")
 *
 * @param players   Array to store indexes to
 * @param num       Variable to store number of indexes to
 * @param flags     Optional filtering flags (enum GetPlayersFlags); valid flags are:
 *                    GetPlayers_None - No filter (Default)
 *                    GetPlayers_ExcludeDead - do not include dead clients
 *                    GetPlayers_ExcludeAlive - do not include alive clients
 *                    GetPlayers_ExcludeBots - do not include bots
 *                    GetPlayers_ExcludeHuman - do not include human clients
 *                    GetPlayers_MatchTeam - match with team
 *                    GetPlayers_MatchNameSubstring - match with part of name
 *                    GetPlayers_CaseInsensitive - match case insensitive
 *                    GetPlayers_ExcludeHLTV - do not include HLTV proxies
 *                    GetPlayers_IncludeConnecting - include connecting clients
 * @param team      String to match against if the "e" or "f" flag is specified
 *
 * @noreturn
 */
stock get_players_ex(players[MAX_PLAYERS] = {}, &num, GetPlayersFlags:flags = GetPlayers_None, const team[] = "")
{
	new strFlags[10];
	get_flags(_:flags, strFlags, charsmax(strFlags));
	get_players(players, num, strFlags, team);
}

/**
 * Returns the number of clients on the server that match the specified flags.
 *
 * @note Example retrieving all alive CTs:
 *       new AliveCt = get_playersnum_ex(GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT")
 *
 * @param flags     Optional filtering flags (enum GetPlayersFlags); valid flags are:
 *                    GetPlayers_None - No filter (Default)
 *                    GetPlayers_ExcludeDead - do not include dead clients
 *                    GetPlayers_ExcludeAlive - do not include alive clients
 *                    GetPlayers_ExcludeBots - do not include bots
 *                    GetPlayers_ExcludeHuman - do not include human clients
 *                    GetPlayers_MatchTeam - match with team
 *                    GetPlayers_MatchNameSubstring - match with part of name
 *                    GetPlayers_CaseInsensitive - match case insensitive
 *                    GetPlayers_ExcludeHLTV - do not include HLTV proxies
 *                    GetPlayers_IncludeConnecting - include connecting clients
 * @param team      String to match against if the GetPlayers_MatchTeam or GetPlayers_MatchNameSubstring flag is specified
 *
 * @return          Number of clients on the server that match the specified flags
 */
stock get_playersnum_ex(GetPlayersFlags:flags = GetPlayers_None, const team[] = "")
{
	new PlayersNum;
	get_players_ex(_, PlayersNum, flags, team);
	return PlayersNum;
}

/**
 * Emulates strbreak() using argparse().
 *
 * @param text          Source input string.
 * @param left          Buffer to store string left part.
 * @param leftlen       Maximum length of the string part buffer.
 * @param right         Buffer to store string right part.
 * @param rightlen      Maximum length of the string part buffer.
 *
 * @return              -1 if no match was found; otherwise, an index into source
 *                      marking the first index after the searched text.  The
 *                      index is always relative to the start of the input string.
 */
stock argbreak(const text[], left[], leftlen, right[], rightlen)
{
	new pos = argparse(text, 0, left, leftlen);

	if (pos == -1)
	{
		return -1;
	}

	new textlen = strlen(text);

	while (pos < textlen && isspace(text[pos]))
	{
		pos++;
	}

	copy(right, rightlen, text[pos]);

	return pos;
}
#endif
