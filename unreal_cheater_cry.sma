#include <amxmodx>
#include <amxmisc>
#include <reapi>

new const Plugin_sName[] = "Unreal Cheater Cry";
new const Plugin_sVersion[] = "1.6";
new const Plugin_sAuthor[] = "Karaulov";

// !!!! НАСТРОЙКИ НАХОДЯТСЯ ТУТ !!!!
// Настройки (значение true - опция включена, значение false - опция выключена)
// 1) использовать для пользователей Steam небезопасный краш читов (не рекомендуется!, если запущен GSCLIENT в режиме Steam)
new const bool:UNSAFE_METHODS_FOR_STEAM = false;
// 2) скрывает убийства (может слегка снизить защиту)
new const bool:HIDE_NAMES_FROM_KILLFEED = true;
// 3) отображать в чате информацию о срабатывании античита
new const bool:SHOW_INFO_IN_CHAT = true;
// 4) быстрый детект дропа (не реализовано в 1.6 версии!)
//new const bool:FAST_CRASH_DETECTION = false;

// Методы краша читов, в некоторых читах не проверяет границы и происходит краш
// 1) отправляет сообщение о убийстве несуществующих игроков
new const bool:USE_METHOD_1 = true;
// 2) отправляет ложные данные о команде, для несуществующих игроков
new const bool:USE_METHOD_2 = true;
// 3) попытка краша протекторов используемых в читах, опция не протестирована и может быть не стабильна (не рекомендуется!)
new const bool:USE_METHOD_3 = false;
// 4) попытка краша ESP читов, опция не протестирована и может быть не стабильна (не рекомендуется!)
new const bool:USE_METHOD_4 = false;
// 5) отправляет ложные данные о параметрах scoreboard, для несуществующих игроков
new const bool:USE_METHOD_5 = true;
// 6) отправка несуществующего звука (может увеличить время коннекта игрока на несколько секунд, абсолютно точно крашит читы alternative 2020 и 2021)
new const bool:USE_METHOD_6 = true;

// Введите строку бана. Параметры [username] [ip] [steamid]. Например "amx_offban [steamid] 1000".
new const BAN_STR[] = "";

// !!!! КОНЕЦ НАСТРОЕК !!!!

new g_sUserNames[MAX_PLAYERS + 1][33];
new g_sUserIps[MAX_PLAYERS + 1][33];
new g_sUserAuths[MAX_PLAYERS + 1][65];
new bool:g_bUserWait[MAX_PLAYERS + 1] = {false,...};
new bool:g_bUserCrash[MAX_PLAYERS + 1] = {false,...};
new Float:g_fUserWait[MAX_PLAYERS + 1] = {0.0,...};
new g_iCrashOffset[MAX_PLAYERS + 1][7];
new g_sCrashSound[64];

//
new const MAGIC_TASK_NUMBER_CRASH_OFFSET = 1000;
//new const MAGIC_TASK_NUMBER_CHECK_OFFSET = 2000;

// Начало запуска плагина
public plugin_init()
{
// Регистрация плагина, название версия и автор
	register_plugin(Plugin_sName, Plugin_sVersion, Plugin_sAuthor);
// Регистрация серверного квара что бы можно было найти все сервера с этим хорошим плагином
	register_cvar("unreal_cheater_cry", Plugin_sVersion, FCVAR_SERVER | FCVAR_SPONLY);
// Регистрация пакетов движения простого и движения в воздухе
	RegisterHookChain(RG_PM_Move, "PM_Move", .post = false);
}

public plugin_precache()
{
	new tmpString[64];
	RandomString(tmpString, 20);
	formatex(g_sCrashSound, 64, "player/%s.wav", tmpString);
	precache_sound(g_sCrashSound);
}

// Игрок начинает подключение к серверу
public client_connectex(id, const name[], const ip[], reason[128])
{   
// При подключении клиента сохраняем его никнейм и айпишник
	copy(g_sUserNames[id],charsmax(g_sUserNames[]), name);
	copy(g_sUserIps[id],charsmax(g_sUserIps[]), ip);
	strip_port(g_sUserIps[id], charsmax(g_sUserIps[]));

	g_sUserAuths[id][0] = EOS;
	
// При подключении клиента удаляем все таски с номером игрока
	if(task_exists(id))
		remove_task(id);

	if(task_exists(id + MAGIC_TASK_NUMBER_CRASH_OFFSET))
		remove_task(id + MAGIC_TASK_NUMBER_CRASH_OFFSET);
		
// Установить флаг проверки в false
	g_bUserWait[id] = false;
	g_bUserCrash[id] = false;
	
	return PLUGIN_CONTINUE;
}


// Если игрок прислал пакет MOVE, то его не выкинуло. 
// Установить флаг проверки в false
public PM_Move(const id)
{
	if ( id >= 1 && id <= MaxClients )
	{
		if (g_bUserWait[id] && get_gametime() - g_fUserWait[id] > 0.7)
		{
			g_bUserWait[id] = false;
		}
		if (g_bUserCrash[id])
		{                
			g_bUserCrash[id] = false;
			
			for(new i = 0; i < sizeof(g_iCrashOffset[]); i++)
			{
				g_iCrashOffset[id][i] = 33;
			}
			
			set_task(0.01,"do_crash",id + MAGIC_TASK_NUMBER_CRASH_OFFSET);
		}
	}
}

public do_crash(idx)
{
	new id = idx - MAGIC_TASK_NUMBER_CRASH_OFFSET;

	if (!make_cheater_cry_method1(id) &&
		!make_cheater_cry_method2(id) &&
		!make_cheater_cry_method3(id) &&
		!make_cheater_cry_method4(id) &&
		!make_cheater_cry_method6(id) &&
		!make_cheater_cry_method5(id))
	{
		if (is_user_connected(id))
		{
			client_cmd(id, "clear");
		}
		
		g_bUserWait[id] = true;
		g_fUserWait[id] = get_gametime();
		return;
	}

	g_bUserWait[id] = true;
	g_fUserWait[id] = get_gametime();
	set_task(0.01,"do_crash",id + MAGIC_TASK_NUMBER_CRASH_OFFSET);
}

public client_authorized(id, const authid[])
{
	copy(g_sUserAuths[id],charsmax(g_sUserAuths[]), authid);
}

// Игрок подключился к серверу
public client_putinserver(id)
{
	if (is_user_hltv(id) || is_user_bot(id)) return;
	
// Установить флаг проверки в false
	g_bUserWait[id] = false;
	g_bUserCrash[id] = false;
	
// При подключении клиента удаляем все таски с номером игрока
	if(task_exists(id))
		remove_task(id);
	if(task_exists(id + MAGIC_TASK_NUMBER_CRASH_OFFSET))
		remove_task(id + MAGIC_TASK_NUMBER_CRASH_OFFSET);
		
// Запускаем две попытки краша, сразу, и через несколько минут
// если читер включает чит не перед игрой
	g_bUserCrash[id] = true;

	set_task(random_float(60.0,500.0),"start_make_cheater_cry",id);
}

// Игрок отключился от сервера
public client_disconnected(id, bool:drop, message[], maxlen)
{
	// При отключении клиента удаляем все таски с номером игрока
	if(task_exists(id))
		remove_task(id);

	if(task_exists(id + MAGIC_TASK_NUMBER_CRASH_OFFSET))
		remove_task(id + MAGIC_TASK_NUMBER_CRASH_OFFSET);

	if (drop && equal(message,"Timed out") && g_bUserWait[id])
	{
		if (SHOW_INFO_IN_CHAT)
		{
			client_print_color(0, print_team_blue, "^3[CHEATER_CRY]^1 Игрок ^4%s^3 попытался войти с читом...Но не смог :)", g_sUserNames[id]);
		}
		log_to_file("unreal_cheater_cry.log","Игрок %s [IP:%s] попытался войти с читом...", g_sUserNames[id],g_sUserIps[id]);

		if (BAN_STR[0] != EOS)
		{
			static banstr[256];
			copy(banstr,charsmax(banstr), BAN_STR);
			replace_all(banstr,charsmax(banstr),"[username]",g_sUserNames[id]);
			replace_all(banstr,charsmax(banstr),"[ip]",g_sUserIps[id]);
			if (replace_all(banstr,charsmax(banstr),"[steamid]",g_sUserAuths[id]) > 0 && g_sUserAuths[id][0] == EOS)
			{
				log_to_file("unreal_cheater_cry.log","[ERROR] Invalid ban string: %s",banstr);
			}
			else 
			{
				server_cmd(banstr);
				log_to_file("unreal_cheater_cry.log",banstr);
			}
		}
	}
 
	g_bUserWait[id] = false;
	g_bUserCrash[id] = false;
}

// Функция краша использующая 5 различных метода которые должны вызвать падения 
// если используются модификации клиента (чит программы)
public start_make_cheater_cry(id)
{
	if (is_user_connected(id))
	{
		//Сделать краш игрока если он подаст "признаки жизни"
		g_bUserCrash[id] = true;
	}
}

public bool:make_cheater_cry_method1(id)
{
	if (!USE_METHOD_1)
	{
		return false;
	}

	if (!is_user_connected(id))
		return false;

	static deathMsg = 0;

	if ( deathMsg == 0 )
		deathMsg = get_user_msgid ( "DeathMsg" );

	new deathMax = 65;
	if (UNSAFE_METHODS_FOR_STEAM && is_user_steam(id))
	{	
		deathMax = 255;
	}

	if (g_iCrashOffset[id][1] >= deathMax)
	{
		return false;
	}

	for(new i = 0; i <= 5; i++)
	{
		if (g_iCrashOffset[id][1] >= 65)
		{
			if (deathMax == 255)
			{
				g_iCrashOffset[id][1] = 1000;
				message_begin( MSG_ONE, deathMsg, _,id );
				write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
				write_byte( 255 );
				write_byte( 0  );
				write_string( "knife" );
				message_end();

				message_begin( MSG_ONE, deathMsg, _,id );
				write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
				write_byte( 124 );
				write_byte( 0  );
				write_string( "knife" );
				message_end();

				message_begin( MSG_ONE, deathMsg, _,id );
				write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
				write_byte( 125 );
				write_byte( 1 );
				write_string( "deagle" );
				message_end();
			}
			return false;
		}

		if (g_iCrashOffset[id][1] >= 33)
		{
			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 0  );
			write_string( "knife" );
			message_end();
			
			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 1 );
			write_string( "deagle" );
			message_end();

			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 1  );
			write_string( "knife" );
			message_end();

			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( HIDE_NAMES_FROM_KILLFEED ? 0 : id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 0 );
			write_string( "deagle" );
			message_end();
		}

		g_iCrashOffset[id][1]++;
	}
	return true;
}

public bool:make_cheater_cry_method2(id)
{
	if (!USE_METHOD_2)
	{
		return false;
	}

	if (!is_user_connected(id))
		return false;

	static teamInfo = 0;

	if ( teamInfo == 0 )
		teamInfo = get_user_msgid ( "TeamInfo" );

	if (g_iCrashOffset[id][2] >= 256)
			return false;

	for(new i = 0; i <= 12; i++)
	{
		if (g_iCrashOffset[id][2] >= 256)
			return false;
		
		if (g_iCrashOffset[id][2] >= 36)
		{
			message_begin( MSG_ONE, teamInfo, _,id );
			write_byte( g_iCrashOffset[id][2]  );
			write_string( "KILL_BAD_CHEATERS_KILL_KILL_KILL_KILL_KILL_KILL" );
			message_end();
		}
		g_iCrashOffset[id][2]++;
	}
	return true;
}

public bool:make_cheater_cry_method3(id)
{
	if (!USE_METHOD_3)
	{
		return false;
	}

	if (!is_user_connected(id))
		return false;
		
	message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
	write_string( "" );
	message_end();
	message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
	write_string( ";" );
	message_end();
	message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
	write_string( "^n" );
	message_end();

	return false;
}

public bool:make_cheater_cry_method4(id)
{
	if (!USE_METHOD_4)
	{
		return false;
	}

	if (!is_user_connected(id))
		return false;

	message_begin(MSG_ONE, SVC_SPAWNSTATICSOUND, .player = id);
	write_coord_f(random_float(-1000.0,1000.0));
	write_coord_f(random_float(-1000.0,1000.0));
	write_coord_f(random_float(-1000.0,1000.0));
	write_short(511);
	write_byte(255);
	write_byte(255);
	write_short(id == 1 ? 2 : 1); 
	write_byte(255);
	write_byte(0);
	message_end();
   
	message_begin(MSG_ONE, SVC_SPAWNSTATICSOUND, .player = id);
	write_coord_f(random_float(-1000.0,1000.0));
	write_coord_f(random_float(-1000.0,1000.0));
	write_coord_f(random_float(-1000.0,1000.0));
	// Если pich > 0 то краш даже у клиента без читов :)
	write_short(512);
	write_byte(255);
	write_byte(255);
	write_short(id == 1 ? 2 : 1); 
	write_byte(0);
	write_byte(0);
	message_end();
	return false;
}

public bool:make_cheater_cry_method5(id)
{
	if (!USE_METHOD_5)
	{
		return false;
	}

	if (!is_user_connected(id))
		return false;

	static scoreAttrib = 0;

	if ( scoreAttrib == 0 )
		scoreAttrib = get_user_msgid ( "ScoreAttrib" );

	if (g_iCrashOffset[id][5] >= 256)
			return false;

	for(new i = 0; i <= 12; i++)
	{
		if (g_iCrashOffset[id][5] >= 256)
			return false;
		
		if (g_iCrashOffset[id][5] >= 33)
		{
			message_begin( MSG_ONE, scoreAttrib, _,id );
			write_byte( g_iCrashOffset[id][5] );
			write_byte( 0 );
			message_end();

			message_begin( MSG_ONE, scoreAttrib, _,id );
			write_byte( g_iCrashOffset[id][5] );
			write_byte( 0xF );
			message_end();
		}

		g_iCrashOffset[id][5]++;
	}
	return true;
}

public bool:make_cheater_cry_method6(id)
{
	if (!USE_METHOD_6)
	{
		return false;
	}

	if (!is_user_connected(id))
		return false;

	rh_emit_sound2(id, id, random_num(0,100) > 50 ? CHAN_VOICE : CHAN_STREAM, g_sCrashSound, VOL_NORM, ATTN_NORM);
	return false;
}

new const g_CharSet[] = "abcdefghijklmnopqrstuvwxyz";

stock RandomString(dest[], length)
{
	new i, randIndex;
	new charsetLength = strlen(g_CharSet);

	for (i = 0; i < length; i++)
	{
		randIndex = random(charsetLength);
		dest[i] = g_CharSet[randIndex];
	}

	dest[length - 1] = EOS;  // Null-terminate the string
}

stock strip_port(address[], length)
{
	for (new i = length - 1; i >= 0; i--)
	{
		if (address[i] == ':')
		{
			address[i] = EOS;
			return;
		}
	}
}