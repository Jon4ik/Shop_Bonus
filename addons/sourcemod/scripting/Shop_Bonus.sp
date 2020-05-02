#define ForPlayer(%0)   for (int %0 = MaxClients; %0 != 0; --%0) if (IsValideClient(%0))

#include <sourcemod>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

/* БД */

Database g_hDatabase;

/* Инфа о игроке */

char SteamID[32][MAXPLAYERS+1];
int LastTimeUse[MAXPLAYERS+1] = 0;

/* Квары и их значение*/
ConVar g_cBonustime;
ConVar g_cBonuscredits;

int g_iBonustime;
int g_iBonuscredits;

public Plugin myinfo =
{
	name = "SHOP BONUS",
	author = "Jon4ik (https://steamcommunity.com/id/jon4ik/)",
	version = "Beta 1.1",
	url	= "https://steamcommunity.com/id/jon4ik/"
};

public void OnPluginStart()
{	
	RegConsoleCmd("sm_bonus", Command_Cat);
	
	Database.Connect(ConnectCallBack, "credits");
	
	(g_cBonustime = CreateConVar("shop_bonus_time", "3600", "Через сколько секунд можно будет использовать бонус повторно? (указывать в СЕКУНДАХ, 0 = никогда)", FCVAR_NOTIFY, true, 0.0, false)).AddChangeHook(CVarChanged);
	g_iBonustime = g_cBonustime.IntValue;
	
	(g_cBonuscredits = CreateConVar("shop_bonus_credits", "1000", "Сколько выдавать кредитов игроку?", FCVAR_NOTIFY, true, 0.0, false)).AddChangeHook(CVarChanged);
	g_iBonuscredits = g_cBonuscredits.IntValue;
	
	AutoExecConfig(true, "shop_bonus");
	
	ForPlayer(i) OnClientPostAdminCheck(i);
}

public void CVarChanged(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	if (CVar == g_cBonustime) 
    { 
        g_iBonustime = g_cBonustime.IntValue;
    }
	else if (CVar == g_cBonustime) 
    { 
        g_iBonuscredits = g_cBonuscredits.IntValue;
    }	
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValideClient(client))
	{	
		char DBQuery[PLATFORM_MAX_PATH];
		GetClientAuthId(client, AuthId_Steam2, SteamID[client], 32);
		FormatEx(DBQuery, sizeof(DBQuery), "SELECT DISTINCT `timeuse` FROM `shop_credits` WHERE `steamid` = '%s';", SteamID[client]);
		g_hDatabase.Query(DB_LoadCallback, DBQuery, GetClientUserId(client));
	}
}

public void OnClientDisconnect(int client)
{
	if(IsValideClient(client))
	{	
		LastTimeUse[client] = 0;
	}
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data)
{
	if (hDatabase == null)
	{
		SetFailState("Database failure: %s", sError);
		return;
	}

	g_hDatabase = hDatabase;
	SQL_LockDatabase(g_hDatabase);
	DB_CreateTable();
	SQL_UnlockDatabase(g_hDatabase);
	g_hDatabase.SetCharset("utf8"); 
}

void DB_CreateTable()
{
	char driver[15];
	g_hDatabase.Driver.GetIdentifier(driver, 15); 
	
	if(StrEqual(driver, "mysql", false))
	{
		g_hDatabase.Query(DB_CheckError, "CREATE TABLE IF NOT EXISTS `shop_credits` ( \
		`id` INT NOT NULL AUTO_INCREMENT, \
		`steamid` VARCHAR(32) NOT NULL, \
		`timeuse` INT NOT NULL , \
		PRIMARY KEY (`id`))", 0);
	}
	else
	{
		g_hDatabase.Query(DB_CheckError, "CREATE TABLE IF NOT EXISTS `shop_credits` (\
			`id`       INTEGER      PRIMARY KEY UNIQUE NOT NULL, \
			`steamid`  VARCHAR (32) NOT NULL, \
			`timeuse`  INTEGER      NOT NULL);", 0);
	}
}

public void DB_CheckError(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("DB_CheckError: %s", szError);
	}
}

public void DB_LoadCallback(Database hDatabase, DBResultSet hResults, const char[] szError, any iUserID) 
{  
	if(szError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", szError);
		return;
	} 
	
	LastTimeUse[GetClientOfUserId(iUserID)] = (hResults.FetchRow()) ?  hResults.FetchInt(0) : 0;
}


public Action Command_Cat(int client, int args)
{
	if(!IsValideClient(client)) return Plugin_Handled;
	
	int ctime = GetTime();
	
	if(LastTimeUse[client] > 0)
	{
		if(g_iBonustime == 0)
		{
			PrintToChat(client, "\x04[SHOP] \x01Вы уже получали бонус!");
			
			return Plugin_Handled;
		}
		else if(ctime - LastTimeUse[client] < g_iBonustime)
		{
			char Time[100];
			FormatTime(Time, sizeof(Time), "%d/%m/%Y - %H:%M", LastTimeUse[client]);
			PrintToChat(client, "\x04[SHOP] \x01Следующий бонус можно получить \x04%s", Time);
			
			return Plugin_Handled;
		}
				
		LastTimeUse[client] = ctime + g_iBonustime;
		UpdatePlayer(client);
	}
	else
	{
		CreatePlayer(client);
		LastTimeUse[client] = ctime + g_iBonustime;
	}
	
	return Plugin_Continue;
}


void UpdatePlayer(int client)
{
	char DBQuery[PLATFORM_MAX_PATH];
	FormatEx(DBQuery, sizeof(DBQuery), "UPDATE `shop_credits` SET `timeuse` = '%i'  WHERE `steamid` = '%s'", GetTime(), SteamID[client]);
	g_hDatabase.Query(DB_CheckError, DBQuery, GetClientUserId(client));
	Shop_GiveClientCredits(client, g_iBonuscredits, CREDITS_BY_NATIVE);
	PrintToChat(client, "\x04[SHOP] \x01Вы получили \x04%i \x01бонусных кредитов", g_iBonuscredits);
}

void CreatePlayer(int client)
{
	char DBQuery[PLATFORM_MAX_PATH];
	FormatEx(DBQuery, sizeof(DBQuery), "INSERT INTO `shop_credits`(steamid, timeuse) VALUES('%s', '%i');", SteamID[client], GetTime());
	g_hDatabase.Query(DB_CheckError, DBQuery, GetClientUserId(client));
		
	PrintToChat(client, "\x04[SHOP] \x01Вы получили \x04%i \x01бонусных кредитов", g_iBonuscredits);
	Shop_GiveClientCredits(client, g_iBonuscredits, CREDITS_BY_NATIVE);
}

bool IsValideClient(int client)
{	
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}