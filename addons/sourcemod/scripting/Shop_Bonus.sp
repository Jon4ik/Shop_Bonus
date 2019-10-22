#include <sourcemod>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

Database g_hDatabase;
char SteamID[32][MAXPLAYERS+1];
bool IsUse[MAXPLAYERS+1] = false, IsNeedUpdate[MAXPLAYERS+1] = false;

public Plugin myinfo =
{
	name = "SHOP BONUS",
	author = "Jon4ik (https://steamcommunity.com/id/jon4ik/)",
	version = "1.0",
	url	= "https://steamcommunity.com/id/jon4ik/"
};

static int amount = 1000;

public void OnPluginStart()
{	
	RegConsoleCmd("sm_bonus", Command_Cat);
	
	Database.Connect(ConnectCallBack, "credits");
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValideClient(client))
	{	
		char DBQuery[PLATFORM_MAX_PATH];
		GetClientAuthId(client, AuthId_Steam2, SteamID[client], 32);
		FormatEx(DBQuery, sizeof(DBQuery), "SELECT DISTINCT `steamid` FROM `shop_credits` WHERE `steamid` = '%s';", SteamID[client]);
		g_hDatabase.Query(DB_LoadCallback, DBQuery, GetClientUserId(client));
	}
}

public void OnClientDisconnect(int client) 
{ 
	if(IsValideClient(client) && IsNeedUpdate[client])
	{	
		char DBQuery[PLATFORM_MAX_PATH];
		FormatEx(DBQuery, sizeof(DBQuery), "INSERT INTO `shop_credits`(steamid, timeuse) VALUES('%s', '%i');", SteamID[client], GetTime());
		g_hDatabase.Query(DB_CheckError, DBQuery, GetClientUserId(client));
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
	
	IsUse[GetClientOfUserId(iUserID)] = (SQL_GetRowCount(hResults) > 0) ? true : false;
}

public Action Command_Cat(int client, int args)
{	
	if(!IsValideClient(client)) return Plugin_Handled;

	if(IsUse[client])
	{
		PrintToChat(client, "\x04[SHOP] \x01Вы уже получали бонусные кредиты!");
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[SHOP] \x01Вы получили \x04%i \x01бонусных кредитов", amount);
	Shop_GiveClientCredits(client, amount, CREDITS_BY_NATIVE);
	IsNeedUpdate[client] = true;
	IsUse[client] = true;
		
	return Plugin_Continue;
}

bool IsValideClient(int client)
{	
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}