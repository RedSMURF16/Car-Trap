/*
*
*	Car Trap by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /ct                     "Opens the Car Trap menu."
*       say_team /ct                "Opens the Car Trap menu."
*       ct_reload                       "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define CAR_KEY                     172714
#define CAR_ARRAY_ITEM              pev_iuser1
#define CAR_OWNER                   pev_iuser1
#define CAR_SEQ_UP                  0
#define CAR_SEQ_DOWN                1
#define CAR_POINT_EPSILON           1.0
#define CAR_DEATH_PENALTY           5000.0
#define CAR_ROPE_HEIGHT             512.0
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 1.0
new const ERROR_FILE[]              = "CarTrap_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_CAR
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_SHAKE              = (1 << 0),

    FLAG_SHOW               = (1 << 1),
    FLAG_GHOST              = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_FALL               = (1 << 4),
    FLAG_IDLE               = (1 << 5),
    FLAG_RAISE              = (1 << 6),
    FLAG_LOCK               = (1 << 7)
}

enum
{
    ENTITY_SWITCH,
    ENTITY_CAR
}

enum
{
    ROTATE_MODE_PITCH,
    ROTATE_MODE_YAW,
    ROTATE_MODE_ROLL
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SKIN_1,
    SKIN_2,
    SKIN_3
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    Array:SETTING_DEFAULT_SOUND_ROPE,
    Array:SETTING_DEFAULT_SOUND_SWITCH,
    Array:SETTING_DEFAULT_SOUND_SMASH,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    Float:SETTING_DEFAULT_FALL_STRENGTH[2],
    Float:SETTING_DEFAULT_FALL_FREQ[2],
    Float:SETTING_DEFAULT_IDLE_DURATION[2],
    Float:SETTING_DEFAULT_RAISE_STRENGTH[2],
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_DEFAULT_SHAKE_DISTANCE,
    SETTING_DEFAULT_SHAKE_AMPLITUDE,
    SETTING_DEFAULT_SHAKE_FREQUENCY,
    SETTING_DEFAULT_SHAKE_DURATION,
    bool:SETTING_KILL_WORLD,

    SETTING_MODEL_ROPE[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_SWITCH[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_CAR_1[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_CAR_2[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_CAR_3[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_SWITCH[3],
    Float:SETTING_MAXS_SWITCH[3],
    Float:SETTING_MINS_CAR_1[3],
    Float:SETTING_MAXS_CAR_1[3],
    Float:SETTING_MINS_CAR_2[3],
    Float:SETTING_MAXS_CAR_2[3],
    Float:SETTING_MINS_CAR_3[3],
    Float:SETTING_MAXS_CAR_3[3],

    bool:SETTING_CAR_LOAD,
    Float:SETTING_CAR_CHECK,
    Float:SETTING_CAR_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP
}

enum _:CAR
{
    CAR_ID_ROPE,
    CAR_ID_SWITCH,
    CAR_ID_CAR,
    CAR_ITEM,
    CAR_FLAGS,
    CAR_TEAM,
    CAR_SKIN,
    CAR_ACTIVATOR,
    CAR_NAME[MAX_VALUE_LENGTH],
    CAR_MODEL[MAX_RESOURCE_PATH_LENGTH],

    Float:CAR_ORIGIN_SWITCH[3],
    Float:CAR_ANGLES_SWITCH[3],
    Float:CAR_ORIGIN_CAR_START[3],
    Float:CAR_ORIGIN_CAR_END[3],
    Float:CAR_ANGLES_CAR[3],
    Float:CAR_ORIGIN_ROPE[3],
    Float:CAR_MINS[3],
    Float:CAR_MAXS[3],

    Float:CAR_FALL_STRENGTH[2],
    Float:CAR_FALL_FREQ[2],
    Float:CAR_IDLE_DURATION[2],
    Float:CAR_RAISE_STRENGTH[2],
    Float:CAR_COOLDOWN[2],
    Float:CAR_SHAKE_DISTANCE,
    CAR_SHAKE_AMPLITUDE,
    CAR_SHAKE_FREQUENCY,
    CAR_SHAKE_DURATION,

    Float:CAR_NEXT_ACTIVE,
    Float:CAR_NEXT_FALL,
    Float:CAR_NEXT_RAISE
}

enum _:PLAYER_DATA
{
    PDATA_CAR_GHOST,
    PDATA_CAR_MENU,
    bool:PDATA_CAR_ACTION,
    PDATA_ROTATE_MODE,
    PDATA_ROTATE_SKIN,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE_SWITCH,
    MENU_ROTATE_CAR
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_SWITCH_UP,
    ROTATE_SWITCH_DOWN,

    ROTATE_SWITCH_MODE = 3,
    ROTATE_SWITCH_PLACE
}

enum
{
    ROTATE_CAR_UP,
    ROTATE_CAR_DOWN,

    ROTATE_CAR_SKIN = 3,
    ROTATE_CAR_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotateSwitch",
    "menuHandlerRotateCar"
}

new g_szCN[] = "cartrap"

new Array:g_aCar,
    Array:g_aCarConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdStartFrame, HamHook:g_iFwdTouch, HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iCar, g_iCarConfig, g_iScreenShake,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateMode[][] = {"CAR_ROTATE_PITCH", "CAR_ROTATE_YAW", "CAR_ROTATE_ROLL"}
new g_szRotateSkin[][] = {"CAR_ROTATE_SKIN_1", "CAR_ROTATE_SKIN_2", "CAR_ROTATE_SKIN_3"}

public plugin_init()
{
    register_plugin("Car car", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_ct", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /ct",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Car car menu.")
    register_clcmd("say_team /ct",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Car car menu.")
    register_concmd("ct_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("CarTrap.txt")

    g_iFwdStartFrame = register_forward(FM_StartFrame, "fwdStartFrame")
    g_iFwdTouch = RegisterHam(Ham_Touch, "info_target", "fwdTouch")
    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iScreenShake = get_user_msgid("ScreenShake")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableCar()

    carInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aCar = ArrayCreate(CAR)
    g_aCarConfig = ArrayCreate(CAR)
    g_eSettings[SETTING_DEFAULT_SOUND_ROPE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_SWITCH] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_SMASH] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aCar)
    ArrayDestroy(g_aCarConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_SWITCH])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_ROPE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_SMASH])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    carSound(id, SOUND_MENU_NAV)
    carMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    carReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id) )
                UpdateData(id)

        ArrayClear(g_aCarConfig)
        g_iCarConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/CarTrap.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eCar[CAR], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iCarConfig )
                            ArrayPushArray(g_aCarConfig, eCar)

                        copy(eCar[CAR_NAME], charsmax(eCar[CAR_NAME]), szData)
                        eCar[CAR_FLAGS]                     = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eCar[CAR_TEAM]                      = g_eSettings[SETTING_DEFAULT_TEAM]
                        eCar[CAR_FALL_STRENGTH][0]          = g_eSettings[SETTING_DEFAULT_FALL_STRENGTH][0]
                        eCar[CAR_FALL_STRENGTH][1]          = g_eSettings[SETTING_DEFAULT_FALL_STRENGTH][1]
                        eCar[CAR_FALL_FREQ][0]              = g_eSettings[SETTING_DEFAULT_FALL_FREQ][0]
                        eCar[CAR_FALL_FREQ][1]              = g_eSettings[SETTING_DEFAULT_FALL_FREQ][1]
                        eCar[CAR_IDLE_DURATION][0]          = g_eSettings[SETTING_DEFAULT_IDLE_DURATION][0]
                        eCar[CAR_IDLE_DURATION][1]          = g_eSettings[SETTING_DEFAULT_IDLE_DURATION][1]
                        eCar[CAR_RAISE_STRENGTH][0]         = g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH][0]
                        eCar[CAR_RAISE_STRENGTH][1]         = g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH][1]
                        eCar[CAR_COOLDOWN][0]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eCar[CAR_COOLDOWN][1]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]
                        eCar[CAR_SHAKE_DISTANCE]            = g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]
                        eCar[CAR_SHAKE_AMPLITUDE]           = g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]
                        eCar[CAR_SHAKE_FREQUENCY]           = g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]
                        eCar[CAR_SHAKE_DURATION]            = g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]

                        iSection = SECTION_CAR
                        g_iCarConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_SOUND_ROPE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_ROPE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_ROPE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_SWITCH") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_SWITCH], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_SWITCH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_SMASH") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_SMASH], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_SMASH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FALL_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FALL_STRENGTH], charsmax(g_eSettings[SETTING_DEFAULT_FALL_STRENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FALL_FREQ") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FALL_FREQ], charsmax(g_eSettings[SETTING_DEFAULT_FALL_FREQ]))
                        else if ( equali(szKey, "SETTING_DEFAULT_IDLE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_IDLE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_IDLE_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_RAISE_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH], charsmax(g_eSettings[SETTING_DEFAULT_RAISE_STRENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]))
                        else if ( equali(szKey, "SETTING_KILL_WORLD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_WORLD], charsmax(g_eSettings[SETTING_KILL_WORLD]))
                        else if ( equali(szKey, "SETTING_MODEL_ROPE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_ROPE], charsmax(g_eSettings[SETTING_MODEL_ROPE]))
                        else if ( equali(szKey, "SETTING_MODEL_SWITCH") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_SWITCH], charsmax(g_eSettings[SETTING_MODEL_SWITCH]))
                        else if ( equali(szKey, "SETTING_MODEL_CAR_1") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_CAR_1], charsmax(g_eSettings[SETTING_MODEL_CAR_1]))
                        else if ( equali(szKey, "SETTING_MODEL_CAR_2") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_CAR_2], charsmax(g_eSettings[SETTING_MODEL_CAR_2]))
                        else if ( equali(szKey, "SETTING_MODEL_CAR_3") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_CAR_3], charsmax(g_eSettings[SETTING_MODEL_CAR_3]))
                        else if ( equali(szKey, "SETTING_MINS_SWITCH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_SWITCH], charsmax(g_eSettings[SETTING_MINS_SWITCH]))
                        else if ( equali(szKey, "SETTING_MAXS_SWITCH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_SWITCH], charsmax(g_eSettings[SETTING_MAXS_SWITCH]))
                        else if ( equali(szKey, "SETTING_MINS_CAR_1") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_CAR_1], charsmax(g_eSettings[SETTING_MINS_CAR_1]))
                        else if ( equali(szKey, "SETTING_MAXS_CAR_1") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_CAR_1], charsmax(g_eSettings[SETTING_MAXS_CAR_1]))
                        else if ( equali(szKey, "SETTING_MINS_CAR_2") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_CAR_2], charsmax(g_eSettings[SETTING_MINS_CAR_2]))
                        else if ( equali(szKey, "SETTING_MAXS_CAR_2") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_CAR_2], charsmax(g_eSettings[SETTING_MAXS_CAR_2]))
                        else if ( equali(szKey, "SETTING_MINS_CAR_3") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_CAR_3], charsmax(g_eSettings[SETTING_MINS_CAR_3]))
                        else if ( equali(szKey, "SETTING_MAXS_CAR_3") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_CAR_3], charsmax(g_eSettings[SETTING_MAXS_CAR_3]))
                        else if ( equali(szKey, "SETTING_CAR_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CAR_LOAD], charsmax(g_eSettings[SETTING_CAR_LOAD]))
                        else if ( equali(szKey, "SETTING_CAR_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_CAR_CHECK], charsmax(g_eSettings[SETTING_CAR_CHECK]))
                        else if ( equali(szKey, "SETTING_CAR_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_CAR_TASK], charsmax(g_eSettings[SETTING_CAR_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                    }
                    case SECTION_CAR:
                    {
                        if ( equali(szKey, "CAR_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eCar[CAR_FLAGS], charsmax(eCar[CAR_FLAGS]))
                        else if ( equali(szKey, "CAR_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCar[CAR_TEAM], charsmax(eCar[CAR_TEAM]))
                        else if ( equali(szKey, "CAR_FALL_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCar[CAR_FALL_STRENGTH], charsmax(eCar[CAR_FALL_STRENGTH]))
                        else if ( equali(szKey, "CAR_FALL_FREQ") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCar[CAR_FALL_FREQ], charsmax(eCar[CAR_FALL_FREQ]))
                        else if ( equali(szKey, "CAR_IDLE_DURATION") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCar[CAR_IDLE_DURATION], charsmax(eCar[CAR_IDLE_DURATION]))
                        else if ( equali(szKey, "CAR_RAISE_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCar[CAR_RAISE_STRENGTH], charsmax(eCar[CAR_RAISE_STRENGTH]))
                        else if ( equali(szKey, "CAR_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCar[CAR_COOLDOWN], charsmax(eCar[CAR_COOLDOWN]))
                        else if ( equali(szKey, "CAR_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eCar[CAR_SHAKE_DISTANCE], charsmax(eCar[CAR_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "CAR_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCar[CAR_SHAKE_AMPLITUDE], charsmax(eCar[CAR_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "CAR_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCar[CAR_SHAKE_FREQUENCY], charsmax(eCar[CAR_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "CAR_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eCar[CAR_SHAKE_DURATION], charsmax(eCar[CAR_SHAKE_DURATION]))
                    }
                }
            }
        }
    }

    if ( g_iCarConfig )
        ArrayPushArray(g_aCarConfig, eCar)
    else
        set_fail_state("No cars were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eCar[CAR], iItem
    if ( g_ePlayerData[id][PDATA_CAR_GHOST]
    && (iItem = carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST])) != -1 )
    {
        carKill(eCar)
        carRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_CAR_GHOST]  = 0
    g_ePlayerData[id][PDATA_CAR_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock carInit()
{
    if ( g_eSettings[SETTING_CAR_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock carTerminate()
{
    new eCar[CAR]
    for ( new i = 0; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)
        eCar[CAR_FLAGS] &= ~(FLAG_FALL | FLAG_IDLE | FLAG_RAISE)
        ArraySetArray(g_aCar, i, eCar)
    }
}

stock carMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "CAR_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_STATUS"); }
        case MENU_ROTATE_SWITCH:    { menuRotateSwitch(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_ROTATE"); }
        case MENU_ROTATE_CAR:       { menuRotateCar(id, iMenu);     format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "CAR_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAR_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROOT_NOCLIP", id, get_user_noclip(id) ? "CAR_ON" : "CAR_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROOT_GODMODE", id, get_user_godmode(id) ? "CAR_ON" : "CAR_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iCar >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_LIMIT", MAX_ENT)

                carSound(id, SOUND_MENU_REMOVE)
                carMenu(id, MENU_ROOT)
            }
            else
            {
                carSound(id, SOUND_MENU_NAV)
                carMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iCar )
            {
                client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_NO_CAR")

                carSound(id, SOUND_MENU_REMOVE)
                carMenu(id, MENU_ROOT)
            }
            else
            {
                carSound(id, SOUND_MENU_NAV)
                carMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iCar )
            {
                client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_NO_CAR")

                carSound(id, SOUND_MENU_REMOVE)
                carMenu(id, MENU_ROOT)
            }
            else
            {
                carSound(id, SOUND_MENU_REMOVE)
                carMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            carNoClip(id)
        }
        case ROOT_GODMODE:
        {
            carGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eCar[CAR], szItem[64]
    for ( new i = 0; i < g_iCarConfig; i ++ )
    {
        ArrayGetArray(g_aCarConfig, i, eCar)

        copy(szItem, charsmax(szItem), eCar[CAR_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        carSound(id, SOUND_MENU_NAV)
        carMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    carCreate(id, item)
    carSound(id, SOUND_MENU_NAV)
    carMenu(id, MENU_ROTATE_SWITCH)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "CAR_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eCar[CAR]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_REMOVE_CURRENT", eCar[CAR_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    carSelect(eCar, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
}

public menuHandlerRemove(id, menu, item)
{
    new eCar[CAR]
    ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        carSelect(eCar, eCar[CAR_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAR_MENU] >= g_iCar - 1 )
                g_ePlayerData[id][PDATA_CAR_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAR_MENU] ++

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAR_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAR_MENU] = g_iCar - 1
            else
                g_ePlayerData[id][PDATA_CAR_MENU] --

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eCar[CAR_FLAGS] &= ~FLAG_ACTIVE
            carSetState(eCar)
            carKill(eCar)
            carRemove(g_ePlayerData[id][PDATA_CAR_MENU])

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_REMOVE_CURRENT", eCar[CAR_NAME])
            g_ePlayerData[id][PDATA_CAR_MENU] = 0

            carSound(id, g_iCar > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            carMenu(id, g_iCar > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iCar )
            {
                ArrayGetArray(g_aCar, 0, eCar)
                eCar[CAR_FLAGS] &= ~FLAG_ACTIVE

                carSetState(eCar)
                carKill(eCar)
                carRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_CAR_MENU] = 0

            carSound(id, SOUND_MENU_ALERT)
            carMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                carSound(id, SOUND_MENU_NAV)
                carMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAR_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAR_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eCar[CAR]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_SHOW_CURRENT",
    eCar[CAR_FLAGS] & FLAG_SHOW ? "\y" : "\r", eCar[CAR_NAME], id, eCar[CAR_FLAGS] & FLAG_SHOW ? "CAR_SHOWN" : "CAR_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    carSelect(eCar, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
}

public menuHandlerShow(id, menu, item)
{
    new eCar[CAR]
    ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        carSelect(eCar, eCar[CAR_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAR_MENU] >= g_iCar - 1 )
                g_ePlayerData[id][PDATA_CAR_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAR_MENU] ++

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAR_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAR_MENU] = g_iCar - 1
            else
                g_ePlayerData[id][PDATA_CAR_MENU] --

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eCar[CAR_FLAGS] ^= FLAG_SHOW
            if ( eCar[CAR_FLAGS] & FLAG_SHOW )
                eCar[CAR_FLAGS] |= FLAG_ACTIVE
            else
                eCar[CAR_FLAGS] &= ~FLAG_ACTIVE
            carSetState(eCar)

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_SHOW_CURRENT",
            eCar[CAR_NAME], id, eCar[CAR_FLAGS] & FLAG_SHOW ? "CAR_CHAT_SHOWN" : "CAR_CHAT_HIDDEN")
            ArraySetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iCar; i ++ )
            {
                ArrayGetArray(g_aCar, i, eCar)
                eCar[CAR_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                carSetState(eCar)

                ArraySetArray(g_aCar, i, eCar)
            }

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_SHOW_ALL_SHOWN")
            carSound(id, SOUND_MENU_ALERT)
            carMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iCar; i ++ )
            {
                ArrayGetArray(g_aCar, i, eCar)
                eCar[CAR_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                carSetState(eCar)

                ArraySetArray(g_aCar, i, eCar)
            }

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_SHOW_ALL_HIDDEN")
            carSound(id, SOUND_MENU_ALERT)
            carMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                carSound(id, SOUND_MENU_NAV)
                carMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAR_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAR_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eCar[CAR]
    menuNav(id, iMenu)
    ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_STATUS_CURRENT",
    eCar[CAR_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eCar[CAR_NAME], id, eCar[CAR_FLAGS] & FLAG_ACTIVE ? "CAR_ENABLED" : "CAR_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    carSelect(eCar, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
}

public menuHandlerStatus(id, menu, item)
{
    new eCar[CAR]
    ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        carSelect(eCar, eCar[CAR_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_CAR_MENU] >= g_iCar - 1 )
                g_ePlayerData[id][PDATA_CAR_MENU] = 0
            else
                g_ePlayerData[id][PDATA_CAR_MENU] ++

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_CAR_MENU] <= 0 )
                g_ePlayerData[id][PDATA_CAR_MENU] = g_iCar - 1
            else
                g_ePlayerData[id][PDATA_CAR_MENU] --

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eCar[CAR_FLAGS] ^= FLAG_ACTIVE
            carSetState(eCar)

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_STATUS_CURRENT",
            eCar[CAR_NAME], id, eCar[CAR_FLAGS] & FLAG_ACTIVE ? "CAR_CHAT_ENABLED" : "CAR_CHAT_DISABLED")
            ArraySetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iCar; i ++ )
            {
                ArrayGetArray(g_aCar, i, eCar)
                eCar[CAR_FLAGS] |= FLAG_ACTIVE
                carSetState(eCar)

                ArraySetArray(g_aCar, i, eCar)
            }

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_STATUS_ALL_ENABLED")
            carSound(id, SOUND_MENU_ALERT)
            carMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iCar; i ++ )
            {
                ArrayGetArray(g_aCar, i, eCar)
                eCar[CAR_FLAGS] &= ~FLAG_ACTIVE
                carSetState(eCar)

                ArraySetArray(g_aCar, i, eCar)
            }

            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_STATUS_ALL_DISABLED")
            carSound(id, SOUND_MENU_ALERT)
            carMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                carSound(id, SOUND_MENU_NAV)
                carMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_CAR_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_CAR_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotateSwitch(id, iMenu)
{
    new szItem[64], eCar[CAR]
    if ( carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_MODE", id, g_szRotateMode[g_ePlayerData[id][PDATA_ROTATE_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotateSwitch(id, menu, item)
{
    new eCar[CAR], iItem
    if ( (iItem = carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_SWITCH_UP:
        {
            pev(eCar[CAR_ID_SWITCH], pev_angles, eCar[CAR_ANGLES_SWITCH])
            eCar[CAR_ANGLES_SWITCH][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eCar[CAR_ANGLES_SWITCH][g_ePlayerData[id][PDATA_ROTATE_MODE]] < -180.0 ) eCar[CAR_ANGLES_SWITCH][g_ePlayerData[id][PDATA_ROTATE_MODE]] += 360.0

            set_pev(eCar[CAR_ID_SWITCH], pev_angles, eCar[CAR_ANGLES_SWITCH])
            ArraySetArray(g_aCar, iItem, eCar)

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_SWITCH)
        }
        case ROTATE_SWITCH_DOWN:
        {
            pev(eCar[CAR_ID_SWITCH], pev_angles, eCar[CAR_ANGLES_SWITCH])
            eCar[CAR_ANGLES_SWITCH][g_ePlayerData[id][PDATA_ROTATE_MODE]] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eCar[CAR_ANGLES_SWITCH][g_ePlayerData[id][PDATA_ROTATE_MODE]] > 180.0 ) eCar[CAR_ANGLES_SWITCH][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= 360.0

            set_pev(eCar[CAR_ID_SWITCH], pev_angles, eCar[CAR_ANGLES_SWITCH])
            ArraySetArray(g_aCar, iItem, eCar)

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_SWITCH)
        }
        case ROTATE_SWITCH_MODE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_MODE] > ROTATE_MODE_ROLL )
                g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_PITCH

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_SWITCH)
        }
        case ROTATE_SWITCH_PLACE:
        {
            carTrace(eCar, id)

            eCar[CAR_FLAGS] |= FLAG_SHOW
            eCar[CAR_ANGLES_SWITCH][0] = -eCar[CAR_ANGLES_SWITCH][0]
            carSetSize(eCar, ENTITY_SWITCH)

            ArraySetArray(g_aCar, iItem, eCar)
            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_CAR)
        }
        case MENU_EXIT:
        {
            carKill(eCar)
            carRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAR_GHOST] = 0

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_CREATE)
        }
        default:
        {
            carKill(eCar)
            carRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAR_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotateCar(id, iMenu)
{
    new szItem[64], eCar[CAR]
    if ( carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_SKIN", id, g_szRotateSkin[g_ePlayerData[id][PDATA_ROTATE_SKIN]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "CAR_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotateCar(id, menu, item)
{
    new eCar[CAR], iItem
    if ( (iItem = carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_CAR_UP:
        {
            pev(eCar[CAR_ID_CAR], pev_angles, eCar[CAR_ANGLES_CAR])
            eCar[CAR_ANGLES_CAR][1] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eCar[CAR_ANGLES_CAR][1] < -180.0 ) eCar[CAR_ANGLES_CAR][1] += 360.0

            set_pev(eCar[CAR_ID_CAR], pev_angles, eCar[CAR_ANGLES_CAR])
            ArraySetArray(g_aCar, iItem, eCar)

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_CAR)
        }
        case ROTATE_CAR_DOWN:
        {
            pev(eCar[CAR_ID_CAR], pev_angles, eCar[CAR_ANGLES_CAR])
            eCar[CAR_ANGLES_CAR][1] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eCar[CAR_ANGLES_CAR][1] > 180.0 ) eCar[CAR_ANGLES_CAR][1] -= 360.0

            set_pev(eCar[CAR_ID_CAR], pev_angles, eCar[CAR_ANGLES_CAR])
            ArraySetArray(g_aCar, iItem, eCar)

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_CAR)
        }
        case ROTATE_CAR_SKIN:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SKIN] > SKIN_3 )
                g_ePlayerData[id][PDATA_ROTATE_SKIN] = SKIN_1

            eCar[CAR_SKIN] = g_ePlayerData[id][PDATA_ROTATE_SKIN]
            switch( eCar[CAR_SKIN] )
            {
                case SKIN_1: engfunc(EngFunc_SetModel, eCar[CAR_ID_CAR], g_eSettings[SETTING_MODEL_CAR_1])
                case SKIN_2: engfunc(EngFunc_SetModel, eCar[CAR_ID_CAR], g_eSettings[SETTING_MODEL_CAR_2])
                case SKIN_3: engfunc(EngFunc_SetModel, eCar[CAR_ID_CAR], g_eSettings[SETTING_MODEL_CAR_3])
            }

            ArraySetArray(g_aCar, iItem, eCar)
            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_ROTATE_CAR)
        }
        case ROTATE_CAR_PLACE:
        {
            carTrace(eCar, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAR_GHOST] = 0

            eCar[CAR_FLAGS] &= ~FLAG_GHOST
            eCar[CAR_FLAGS] |= FLAG_ACTIVE
            eCar[CAR_ANGLES_CAR][0] = -eCar[CAR_ANGLES_CAR][0]
            carSetSize(eCar, ENTITY_CAR)
            carSetState(eCar)
            client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_CREATE_NEW", eCar[CAR_NAME])

            ArraySetArray(g_aCar, iItem, eCar)
            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            carKill(eCar)
            carRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAR_GHOST] = 0

            carSound(id, SOUND_MENU_NAV)
            carMenu(id, MENU_CREATE)
        }
        default:
        {
            carKill(eCar)
            carRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_CAR_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public carTask()
{
    new eCar[CAR], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)
        bModified = false

        if ( eCar[CAR_FLAGS] & FLAG_RAISE
        && !(eCar[CAR_FLAGS] & FLAG_FALL) )
        {
            new Float:fVelocity[3]
            fVelocity[2] = random_float(eCar[CAR_RAISE_STRENGTH][0], eCar[CAR_RAISE_STRENGTH][1])
            set_pev(eCar[CAR_ID_CAR], pev_velocity, fVelocity)
        }

        if ( eCar[CAR_FLAGS] & FLAG_ACTIVE )
        {
            if ( eCar[CAR_FLAGS] & FLAG_FALL )
            {
                if ( fCurrentTime >= eCar[CAR_NEXT_FALL] )
                {
                    new Float:fVelocity[3]
                    pev(eCar[CAR_ID_CAR], pev_velocity, fVelocity)
                    fVelocity[2] -= random_float(eCar[CAR_FALL_STRENGTH][0], eCar[CAR_FALL_STRENGTH][1])
                    set_pev(eCar[CAR_ID_CAR], pev_velocity, fVelocity)
                    eCar[CAR_NEXT_FALL] = fCurrentTime + random_float(eCar[CAR_FALL_FREQ][0], eCar[CAR_FALL_FREQ][1])

                    bModified = true
                }
            }
            else if ( eCar[CAR_FLAGS] & FLAG_IDLE )
            {
                if ( fCurrentTime >= eCar[CAR_NEXT_RAISE] )
                {
                    new szSound[MAX_RESOURCE_PATH_LENGTH]
                    ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_ROPE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_ROPE])), szSound, charsmax(szSound))
                    engfunc(EngFunc_EmitSound, eCar[CAR_ID_CAR], CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

                    eCar[CAR_ACTIVATOR] = 0
                    eCar[CAR_FLAGS] &= ~FLAG_IDLE
                    eCar[CAR_FLAGS] |= FLAG_RAISE
                    eCar[CAR_NEXT_ACTIVE] = fCurrentTime + random_float(eCar[CAR_COOLDOWN][0], eCar[CAR_COOLDOWN][1])
                    carSetSeq(eCar[CAR_ID_SWITCH], CAR_SEQ_UP)

                    bModified = true
                }
            }
        }

        if ( bModified )
            ArraySetArray(g_aCar, i, eCar)
    }
}

stock carCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eCar[CAR], szCN[32]
    ArrayGetArray(g_aCarConfig, iItem, eCar)
    eCar[CAR_ID_SWITCH] = iEnt
    eCar[CAR_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_CAR_GHOST] = eCar[CAR_ID_SWITCH]
        g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_YAW
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eCar[CAR_FLAGS] |= FLAG_GHOST
        eCar[CAR_SKIN] = g_ePlayerData[id][PDATA_ROTATE_SKIN]
    }

    formatex(szCN, charsmax(szCN), "%s_switch", g_szCN)
    carSelect(eCar, TARGET_GHOST, false)
    set_pev(iEnt, pev_classname, szCN)
    set_pev(iEnt, pev_impulse, CAR_KEY)
    set_pev(iEnt, CAR_ARRAY_ITEM, g_iCar)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SWITCH])

    ArrayPushArray(g_aCar, eCar)
    if ( ++ g_iCar == 1 )
    {
        set_task(g_eSettings[SETTING_CAR_TASK], "carTask", CAR_KEY, .flags = "b")
        EnableCar()
    }
}

stock carCreateCar(eCar[CAR])
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new szCN[32]
    eCar[CAR_ID_CAR] = iEnt
    eCar[CAR_FLAGS] |= FLAG_LOCK

    formatex(szCN, charsmax(szCN), "%s_car", g_szCN)
    carSelect(eCar, TARGET_GHOST)
    set_pev(iEnt, CAR_OWNER, eCar[CAR_ID_SWITCH])
    set_pev(iEnt, pev_classname, szCN)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    switch( eCar[CAR_SKIN] )
    {
        case SKIN_1: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_CAR_1])
        case SKIN_2: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_CAR_2])
        case SKIN_3: engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_CAR_3])
    }
}

stock carCreateRope(eCar[CAR])
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new szCN[32], Float:fAttachment[3], Float:fDist
    eCar[CAR_ID_ROPE] = iEnt

    formatex(szCN, charsmax(szCN), "%s_rope", g_szCN)
    set_pev(iEnt, CAR_OWNER, eCar[CAR_ID_SWITCH])
    set_pev(iEnt, pev_classname, szCN)
    dllfunc(DLLFunc_Spawn, iEnt)

    engfunc(EngFunc_GetAttachment, eCar[CAR_ID_CAR], 0, fAttachment)
    xs_vec_add(fAttachment, Float:{0.0, 0.0, CAR_ROPE_HEIGHT}, eCar[CAR_ORIGIN_ROPE])
    engfunc(EngFunc_TraceLine, fAttachment, eCar[CAR_ORIGIN_ROPE], IGNORE_MONSTERS, eCar[CAR_ID_CAR], 0)
    get_tr2(0, TR_vecEndPos, eCar[CAR_ORIGIN_ROPE])
    while ( engfunc(EngFunc_PointContents, eCar[CAR_ORIGIN_ROPE]) != CONTENTS_EMPTY )
        eCar[CAR_ORIGIN_ROPE][2] -= 1.0

    engfunc(EngFunc_SetOrigin, eCar[CAR_ID_ROPE], eCar[CAR_ORIGIN_ROPE])
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_ROPE])

    fDist = xs_vec_distance(fAttachment, eCar[CAR_ORIGIN_ROPE])
    set_pev(iEnt, pev_controller_0, floatround(floatclamp(fDist / 1024.0 * 255.0, 0.0, 255.0)))
}

public carRemove(iItem)
{
    new eCar[CAR]
    ArrayDeleteItem(g_aCar, iItem)

    if ( -- g_iCar == 0 )
    {
        remove_task(CAR_KEY)
        DisableCar()
    }

    for ( new i = iItem; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)
        set_pev(eCar[CAR_ID_SWITCH], CAR_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eCar[CAR],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_CarTrap.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    carTerminate()
    for ( new i = 0; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eCar[CAR_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eCar[CAR_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "skin = %d^n", eCar[CAR_SKIN])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "switch_origin = %.2f %.2f %.2f^n",
        eCar[CAR_ORIGIN_SWITCH][0], eCar[CAR_ORIGIN_SWITCH][1], eCar[CAR_ORIGIN_SWITCH][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "switch_angles = %.2f %.2f %.2f^n",
        eCar[CAR_ANGLES_SWITCH][0], eCar[CAR_ANGLES_SWITCH][1], eCar[CAR_ANGLES_SWITCH][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "car_origin = %.2f %.2f %.2f^n",
        eCar[CAR_ORIGIN_CAR_START][0], eCar[CAR_ORIGIN_CAR_START][1], eCar[CAR_ORIGIN_CAR_START][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "car_angles = %.2f %.2f %.2f^n",
        eCar[CAR_ANGLES_CAR][0], eCar[CAR_ANGLES_CAR][1], eCar[CAR_ANGLES_CAR][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "CAR_CHAT_TAG", id, "CAR_CHAT_SAVE", szFile)
    fclose(iFile)

    carSound(id, SOUND_MENU_NAV)
    carMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOriginSwitch[3], Float:fAnglesSwitch[3], Float:fOriginCar[3], Float:fAnglesCar[3], iItem, iFlags, iSkin, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_CarTrap.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataCar(iItem, iFlags, iSkin, fOriginSwitch, fAnglesSwitch, fOriginCar, fAnglesCar, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "skin") )
            {
                iSkin = str_to_num(szValue)
            }
            else if ( equal(szKey, "switch_origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginSwitch[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginSwitch[1] = str_to_float(szKey)
                fOriginSwitch[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "switch_angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesSwitch[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesSwitch[1] = str_to_float(szKey)
                fAnglesSwitch[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "car_origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginCar[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginCar[1] = str_to_float(szKey)
                fOriginCar[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "car_angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesCar[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesCar[1] = str_to_float(szKey)
                fAnglesCar[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataCar(iItem, iFlags, iSkin, fOriginSwitch, fAnglesSwitch, fOriginCar, fAnglesCar, iCount)

    fclose(iFile)
}

stock LoadDataCar(iItem, iFlags, iSkin, Float:fOriginSwitch[3], Float:fAnglesSwitch[3], Float:fOriginCar[3], Float:fAnglesCar[3], iCount)
{
    new eCar[CAR]
    carCreate(0, iItem)
    ArrayGetArray(g_aCar, iCount, eCar)

    eCar[CAR_FLAGS] = iFlags
    eCar[CAR_SKIN] = iSkin
    fAnglesSwitch[0] = -fAnglesSwitch[0]
    fAnglesCar[0] = -fAnglesCar[0]
    xs_vec_copy(fOriginSwitch, eCar[CAR_ORIGIN_SWITCH])
    xs_vec_copy(fAnglesSwitch, eCar[CAR_ANGLES_SWITCH])
    xs_vec_copy(fOriginCar, eCar[CAR_ORIGIN_CAR_START])
    xs_vec_copy(fAnglesCar, eCar[CAR_ANGLES_CAR])

    carSetBox(eCar, ENTITY_SWITCH)
    carSetSize(eCar, ENTITY_SWITCH)
    carSetBox(eCar, ENTITY_CAR)
    carSetSize(eCar, ENTITY_CAR)
    carSetState(eCar)
    ArraySetArray(g_aCar, iCount, eCar)
}

public carNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    carSound(id, SOUND_MENU_NAV)
    carMenu(id, MENU_ROOT)
}

public carGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    carSound(id, SOUND_MENU_NAV)
    carMenu(id, MENU_ROOT)
}

public fwdStartFrame()
{
    new eCar[CAR], Float:fAttachment[3], Float:fDist, bool:bModified
    for ( new i = 0; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)
        if ( !(eCar[CAR_FLAGS] & (FLAG_FALL | FLAG_RAISE)) )
            continue

        if ( !(eCar[CAR_FLAGS] & FLAG_FALL) )
        {
            new Float:fOrigin[3]
            pev(eCar[CAR_ID_CAR], pev_origin, fOrigin)
            if ( fOrigin[2] >= eCar[CAR_ORIGIN_CAR_START][2] - CAR_POINT_EPSILON )
            {
                eCar[CAR_FLAGS] &= ~FLAG_RAISE
                set_pev(eCar[CAR_ID_CAR], pev_velocity, Float:{0.0, 0.0, 0.0})

                bModified = true
            }
        }
        else if ( eCar[CAR_FLAGS] & FLAG_ACTIVE )
        {
            new Float:fOrigin[3]
            pev(eCar[CAR_ID_CAR], pev_origin, fOrigin)
            if ( fOrigin[2] <= eCar[CAR_ORIGIN_CAR_END][2] + CAR_POINT_EPSILON )
            {
                new szSound[MAX_RESOURCE_PATH_LENGTH]
                ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_SMASH], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_SMASH])), szSound, charsmax(szSound))
                engfunc(EngFunc_EmitSound, eCar[CAR_ID_CAR], CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

                eCar[CAR_FLAGS] &= ~FLAG_FALL
                eCar[CAR_FLAGS] |= FLAG_IDLE
                eCar[CAR_NEXT_RAISE] = get_gametime() + random_float(eCar[CAR_IDLE_DURATION][0], eCar[CAR_IDLE_DURATION][1])
                set_pev(eCar[CAR_ID_CAR], pev_velocity, Float:{0.0, 0.0, 0.0})

                if ( eCar[CAR_FLAGS] & FLAG_SHAKE )
                    carShake(eCar)

                bModified = true
            }
        }

        engfunc(EngFunc_GetAttachment, eCar[CAR_ID_CAR], 0, fAttachment)
        fDist = xs_vec_distance(fAttachment, eCar[CAR_ORIGIN_ROPE])
        set_pev(eCar[CAR_ID_ROPE], pev_controller_0, floatround(floatclamp(fDist / 1024.0 * 255.0, 0.0, 255.0)))
        if ( bModified )
            ArraySetArray(g_aCar, i, eCar)
    }
}

public fwdTouch(iEnt, iOther)
{
    if ( !is_user_alive(iOther)
    || !isCar(pev(iEnt, CAR_OWNER)) )
        return HAM_IGNORED

    new eCar[CAR]
    if ( carGet(eCar, pev(iEnt, CAR_OWNER)) == -1
    || !(eCar[CAR_FLAGS] & FLAG_ACTIVE) )
        return HAM_IGNORED

    new iKiller
    iKiller = g_eSettings[SETTING_KILL_WORLD] ? iEnt : eCar[CAR_ACTIVATOR]
    if ( eCar[CAR_FLAGS] & FLAG_FALL )
    {
        new Float:fCarOrigin[3], Float:fOrigin[3]
        pev(iEnt, pev_origin, fCarOrigin)
        pev(iOther, pev_origin, fOrigin)
        switch( eCar[CAR_ITEM] )
        {
            case SKIN_1: fCarOrigin[2] += g_eSettings[SETTING_MINS_CAR_1][2]
            case SKIN_2: fCarOrigin[2] += g_eSettings[SETTING_MINS_CAR_2][2]
            case SKIN_3: fCarOrigin[2] += g_eSettings[SETTING_MINS_CAR_3][2]
        }

        if ( fOrigin[2] < fCarOrigin[2] )
            ExecuteHamB(Ham_TakeDamage, iOther, 0, iKiller, CAR_DEATH_PENALTY, DMG_ALWAYSGIB)
    }

    return HAM_IGNORED
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isCar(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eCar[CAR], iItem
    if ( (iItem = carGet(eCar, iEnt)) == -1 )
        return HAM_IGNORED

    if ( !(eCar[CAR_FLAGS] & FLAG_ACTIVE)
    || eCar[CAR_FLAGS] & (FLAG_FALL | FLAG_IDLE)
    || !(CsTeams:eCar[CAR_TEAM] & cs_get_user_team(iActivator))
    || get_gametime() < eCar[CAR_NEXT_ACTIVE] )
        return HAM_IGNORED

    new szSound[MAX_RESOURCE_PATH_LENGTH]
    ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_SWITCH], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_SWITCH])), szSound, charsmax(szSound))
    engfunc(EngFunc_EmitSound, eCar[CAR_ID_SWITCH], CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_ROPE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_ROPE])), szSound, charsmax(szSound))
    engfunc(EngFunc_EmitSound, eCar[CAR_ID_CAR], CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    eCar[CAR_ACTIVATOR] = iActivator
    eCar[CAR_FLAGS] |= FLAG_FALL
    eCar[CAR_FLAGS] &= ~FLAG_RAISE
    carSetSeq(eCar[CAR_ID_SWITCH], CAR_SEQ_DOWN)
    ArraySetArray(g_aCar, iItem, eCar)
    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isCar(iEnt) )
        return HAM_IGNORED

    SetHamReturnInteger(FCAP_IMPULSE_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eCar[CAR], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_CAR_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            carTrace(eCar, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_CAR_ACTION] )
    {
        carCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_CAR_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_CAR_GHOST] )
    {
        new eCar[CAR], iItem
        if ( (iItem = carGet(eCar, g_ePlayerData[id][PDATA_CAR_GHOST])) != -1 )
        {
            carKill(eCar)
            carRemove(iItem)
        }

        g_ePlayerData[id][PDATA_CAR_GHOST] = 0
    }
}

stock carTrace(eCar[CAR], id)
{
    new Float:fVec1[3], Float:fVec2[3]
    pev(id, pev_origin, fVec2)
    pev(id, pev_view_ofs, fVec1)
    xs_vec_add(fVec2, fVec1, fVec2)
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, fVec2, fVec1)

    engfunc(EngFunc_TraceLine, fVec2, fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, fVec2)

    if ( eCar[CAR_FLAGS] & FLAG_LOCK )
    {
        carSetBox(eCar, ENTITY_CAR)
        carSetOffset(eCar, fVec2, eCar[CAR_ID_CAR])

        xs_vec_copy(fVec2, eCar[CAR_ORIGIN_CAR_START])
        set_pev(eCar[CAR_ID_CAR], pev_origin, fVec2)
    }
    else
    {
        carSetBox(eCar, ENTITY_SWITCH)
        carSetOffset(eCar, fVec2, eCar[CAR_ID_SWITCH])

        xs_vec_copy(fVec2, eCar[CAR_ORIGIN_SWITCH])
        set_pev(eCar[CAR_ID_SWITCH], pev_origin, fVec2)
    }
}

stock carCheck(id)
{
    new eCar[CAR], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDotSwitch, Float:fDotCar, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_CAR_CHECK]
    for ( new i = 0; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)
        xs_vec_sub(eCar[CAR_ORIGIN_SWITCH], fVec1, fVec3)
        fDotSwitch = xs_vec_dot(fVec2, fVec3)
        xs_vec_sub(eCar[CAR_ORIGIN_CAR_START], fVec1, fVec3)
        fDotCar = xs_vec_dot(fVec2, fVec3)

        if ( fDotSwitch >= 0.0 )
        {
            xs_vec_mul_scalar(fVec2, fDotSwitch, fVec3)
            xs_vec_add(fVec3, fVec1, fVec3)

            pev(eCar[CAR_ID_SWITCH], pev_absmin, fMins)
            pev(eCar[CAR_ID_SWITCH], pev_absmax, fMaxs)
            fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
            fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
            fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
            fDist = xs_vec_distance(fVec3, fNearest)

            if ( fDist < fBestDist )
            {
                fBestDist = fDist
                iBest = i
            }
        }

        if ( fDotCar >= 0.0 )
        {
            xs_vec_mul_scalar(fVec2, fDotCar, fVec3)
            xs_vec_add(fVec3, fVec1, fVec3)

            pev(eCar[CAR_ID_CAR], pev_absmin, fMins)
            pev(eCar[CAR_ID_CAR], pev_absmax, fMaxs)
            fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
            fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
            fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
            fDist = xs_vec_distance(fVec3, fNearest)

            if ( fDist < fBestDist )
            {
                fBestDist = fDist
                iBest = i
            }
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_CAR_MENU] != iBest )
    {
        ArrayGetArray(g_aCar, g_ePlayerData[id][PDATA_CAR_MENU], eCar)
        carSelect(eCar, eCar[CAR_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_CAR_MENU] = iBest
        carMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock carShake(eCar[CAR])
{
    new Float:fOrigin[3]
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eCar[CAR_ORIGIN_CAR_END]) > eCar[CAR_SHAKE_DISTANCE] )
            continue

        message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
        write_short(eCar[CAR_SHAKE_AMPLITUDE] * 4096)
        write_short(eCar[CAR_SHAKE_DURATION] * 4096)
        write_short(eCar[CAR_SHAKE_FREQUENCY] * 4096)
        message_end()
    }
}

stock carSetBox(eCar[CAR], iEntity)
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    if ( iEntity == ENTITY_CAR )
    {
        eCar[CAR_ANGLES_CAR][0] = -eCar[CAR_ANGLES_CAR][0]
        engfunc(EngFunc_AngleVectors, eCar[CAR_ANGLES_CAR], fForward, fRight, fUp)

        switch ( eCar[CAR_SKIN] )
        {
            case SKIN_1:  xs_vec_copy(g_eSettings[SETTING_MINS_CAR_1], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_CAR_1], fMaxs)
            case SKIN_2:  xs_vec_copy(g_eSettings[SETTING_MINS_CAR_2], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_CAR_2], fMaxs)
            case SKIN_3:  xs_vec_copy(g_eSettings[SETTING_MINS_CAR_3], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_CAR_3], fMaxs)
        }
    }
    else
    {
        eCar[CAR_ANGLES_SWITCH][0] = -eCar[CAR_ANGLES_SWITCH][0]
        engfunc(EngFunc_AngleVectors, eCar[CAR_ANGLES_SWITCH], fForward, fRight, fUp)

        xs_vec_copy(g_eSettings[SETTING_MINS_SWITCH], fMins)
        xs_vec_copy(g_eSettings[SETTING_MAXS_SWITCH], fMaxs)
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eCar[CAR_MINS])
    xs_vec_copy(fMaxs, eCar[CAR_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock carSetOffset(eCar[CAR], Float:fOrigin[3], iEnt)
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eCar[CAR_MINS][0]
    fGaps[1] = eCar[CAR_MAXS][0]
    fGaps[2] = -eCar[CAR_MINS][1]
    fGaps[3] = eCar[CAR_MAXS][1]
    fGaps[4] = -eCar[CAR_MINS][2]
    fGaps[5] = eCar[CAR_MAXS][2]

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, fOrigin, fVec1)
        engfunc(EngFunc_TraceLine, fOrigin, fVec1, DONT_IGNORE_MONSTERS, iEnt, 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(fOrigin, fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(fOrigin, fVec1, fOrigin)
        }
    }
}

stock carSetSeq(iEnt, iSequence)
{
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, g_eSettings[SETTING_DEFAULT_FRAMERATE])
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock carSetSize(eCar[CAR], iEntity)
{
    if ( iEntity == ENTITY_SWITCH )
    {
        carSetSeq(eCar[CAR_ID_SWITCH], CAR_SEQ_UP)
        engfunc(EngFunc_SetOrigin, eCar[CAR_ID_SWITCH], eCar[CAR_ORIGIN_SWITCH])
        set_pev(eCar[CAR_ID_SWITCH], pev_angles, eCar[CAR_ANGLES_SWITCH])
        set_pev(eCar[CAR_ID_SWITCH], pev_solid, eCar[CAR_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
        set_pev(eCar[CAR_ID_SWITCH], pev_movetype, MOVETYPE_NONE)

        engfunc(EngFunc_SetSize, eCar[CAR_ID_SWITCH], eCar[CAR_MINS], eCar[CAR_MAXS])
        carCreateCar(eCar)
    }
    else if ( iEntity == ENTITY_CAR )
    {
        eCar[CAR_FLAGS] &= ~FLAG_LOCK
        carSelect(eCar, TARGET_CLEAR)
        engfunc(EngFunc_SetOrigin, eCar[CAR_ID_CAR], eCar[CAR_ORIGIN_CAR_START])
        set_pev(eCar[CAR_ID_CAR], pev_angles, eCar[CAR_ANGLES_CAR])
        set_pev(eCar[CAR_ID_CAR], pev_solid, eCar[CAR_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
        set_pev(eCar[CAR_ID_CAR], pev_movetype, MOVETYPE_FLY)

        xs_vec_sub(eCar[CAR_ORIGIN_CAR_START], Float:{0.0, 0.0, 8192.0}, eCar[CAR_ORIGIN_CAR_END])
        engfunc(EngFunc_TraceLine, eCar[CAR_ORIGIN_CAR_START], eCar[CAR_ORIGIN_CAR_END], IGNORE_MONSTERS, eCar[CAR_ID_CAR], 0)
        get_tr2(0, TR_vecEndPos, eCar[CAR_ORIGIN_CAR_END])
        switch ( eCar[CAR_SKIN] )
        {
            case SKIN_1:  eCar[CAR_ORIGIN_CAR_END][2] += g_eSettings[SETTING_MAXS_CAR_1][2]
            case SKIN_2:  eCar[CAR_ORIGIN_CAR_END][2] += g_eSettings[SETTING_MAXS_CAR_2][2]
            case SKIN_3:  eCar[CAR_ORIGIN_CAR_END][2] += g_eSettings[SETTING_MAXS_CAR_3][2]
        }

        engfunc(EngFunc_SetSize, eCar[CAR_ID_CAR], eCar[CAR_MINS], eCar[CAR_MAXS])
        carCreateRope(eCar)
    }
}

stock carSetState(eCar[CAR])
{
    if ( eCar[CAR_FLAGS] & FLAG_SHOW )
    {
        set_pev(eCar[CAR_ID_SWITCH], pev_solid, SOLID_BBOX)
        set_pev(eCar[CAR_ID_CAR], pev_solid, SOLID_BBOX)
        carSelect(eCar, TARGET_CLEAR)
        if ( !(eCar[CAR_FLAGS] & FLAG_ACTIVE) )
        {
            if ( eCar[CAR_FLAGS] & FLAG_FALL )
            {
                eCar[CAR_FLAGS] &= ~FLAG_FALL
                eCar[CAR_FLAGS] |= FLAG_RAISE
            }
        }
    }
    else
    {
        set_pev(eCar[CAR_ID_SWITCH], pev_solid, SOLID_NOT)
        set_pev(eCar[CAR_ID_CAR], pev_solid, SOLID_NOT)
        carSelect(eCar, TARGET_HIDE)
        if ( eCar[CAR_FLAGS] & FLAG_FALL )
        {
            eCar[CAR_FLAGS] &= ~FLAG_FALL
            eCar[CAR_FLAGS] |= FLAG_RAISE
        }
    }
}

stock carSelect(eCar[CAR], iAction, bool:bCarExists = true)
{
    new iRenderColor[3]
    if ( iAction == TARGET_SELECT )
    {
        if ( eCar[CAR_FLAGS] & FLAG_ACTIVE )  { iRenderColor[0] = g_iColorActive[0];    iRenderColor[1] = g_iColorActive[1];    iRenderColor[2] = g_iColorActive[2]; }
        else                                  { iRenderColor[0] = g_iColorInactive[0];  iRenderColor[1] = g_iColorInactive[1];  iRenderColor[2] = g_iColorInactive[2]; }

        set_ent_rendering(eCar[CAR_ID_ROPE], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
        set_ent_rendering(eCar[CAR_ID_SWITCH], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
        set_ent_rendering(eCar[CAR_ID_CAR], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_ent_rendering(eCar[CAR_ID_SWITCH], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])

        if ( bCarExists )
        {
            set_ent_rendering(eCar[CAR_ID_CAR], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])
            set_ent_rendering(eCar[CAR_ID_ROPE], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])
        }
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_ent_rendering(eCar[CAR_ID_ROPE], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
        set_ent_rendering(eCar[CAR_ID_SWITCH], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
        set_ent_rendering(eCar[CAR_ID_CAR], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_ent_rendering(eCar[CAR_ID_SWITCH], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)

        if ( bCarExists )
        {
            set_ent_rendering(eCar[CAR_ID_CAR], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
            set_ent_rendering(eCar[CAR_ID_ROPE], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
        }
    }
}

stock carSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock carReset()
{
    new eCar[CAR]
    for ( new i = 0; i < g_iCar; i ++ )
    {
        ArrayGetArray(g_aCar, i, eCar)
        eCar[CAR_NEXT_ACTIVE] = 0.0
        eCar[CAR_NEXT_FALL] = 0.0
        eCar[CAR_NEXT_RAISE] = 0.0
        ArraySetArray(g_aCar, i, eCar)
    }
}

stock carGet(eCar[CAR], iEnt)
{
    if ( !isCar(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, CAR_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iCar )
        return -1

    ArrayGetArray(g_aCar, iItem, eCar)
    return iItem
}

stock bool:isCar(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == CAR_KEY
}

stock carKill(eCar[CAR])
{
    if ( pev_valid(eCar[CAR_ID_SWITCH]) )
        set_pev(eCar[CAR_ID_SWITCH], pev_flags, pev(eCar[CAR_ID_SWITCH], pev_flags) | FL_KILLME)

    if ( pev_valid(eCar[CAR_ID_CAR]) )
        set_pev(eCar[CAR_ID_CAR], pev_flags, pev(eCar[CAR_ID_CAR], pev_flags) | FL_KILLME)

    if ( pev_valid(eCar[CAR_ID_ROPE]) )
        set_pev(eCar[CAR_ID_ROPE], pev_flags, pev(eCar[CAR_ID_ROPE], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_CAR_ACTION] )
    {
        new eCar[CAR]
        for ( new i = 0; i < g_iCar; i ++ )
        {
            ArrayGetArray(g_aCar, i, eCar)
            if ( eCar[CAR_FLAGS] & FLAG_SHOW )
                continue

            carSelect(eCar, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_CAR_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_CAR_ACTION] )
    {
        new eCar[CAR]
        for ( new i = 0; i < g_iCar; i ++ )
        {
            ArrayGetArray(g_aCar, i, eCar)
            if ( eCar[CAR_FLAGS] & FLAG_SHOW )
                continue

            carSelect(eCar, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_CAR_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock EnableCar()
{
    g_iFwdStartFrame = register_forward(FM_StartFrame, "fwdStartFrame")
    EnableHamForward(g_iFwdTouch)
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
}

stock DisableCar()
{
    unregister_forward(FM_StartFrame, g_iFwdStartFrame)
    DisableHamForward(g_iFwdTouch)
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}