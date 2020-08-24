 // include //
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <warden>

// ConVar //
ConVar ConVar_god_T;
ConVar ConVar_kor_T;
ConVar ConVar_kom_T;
ConVar ConVar_kom_H;
ConVar ConVar_kor_H;

// Handle //
Handle T_KomRev;
Handle T_CTRev;
Handle T_God;

// int //
int KomRevHakki;
int CTRevHakki;
int Goduvar[MAXPLAYERS + 1];
int Normalverme[MAXPLAYERS + 1];

// pragma //
#pragma semicolon 1

// myinfo //
public Plugin myinfo = 
{
	name = "CT Revlenme", 
	author = "ByDexter & qantum.", 
	description = "Komutçunun ve CTnin ayrı X revlenme hakkı ve doğunca X spawnkill engelleme", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR/"
};

// pluginstart //
public void OnPluginStart()
{
	/*		COMMANDS	*/
	RegConsoleCmd("sm_hak", Hakkimkacoc, "Komutçu ve korumanın kalan hakkı");
	/*		HOOKS	*/
	HookEvent("round_start", Round_StartEnd);
	HookEvent("player_death", OnClientDeath);
	HookEvent("player_spawn", OnClientSpawn);
	HookEvent("round_end", Round_StartEnd);
	/*		CVARS	*/
	ConVar_god_T = CreateConVar("sm_god_timer", "5.0", "Kullanıcı doğduktan sonra kaç saniye godu olsun");
	ConVar_kor_T = CreateConVar("sm_koruma_timer", "10.0", "Koruma öldükten kaç saniye sonra canlansın");
	ConVar_kom_T = CreateConVar("sm_komutcu_timer", "10.0", "Komutçu öldükten kaç saniye sonra canlansın");
	ConVar_kor_H = CreateConVar("sm_koruma_hakki", "3", "Koruma kaç kez canlansın");
	ConVar_kom_H = CreateConVar("sm_komutcu_hakki", "3", "Komutçu kaç kez canlansın");
	/*		CFG	*/
	AutoExecConfig(true, "CTRev", "ByDexter-qua");
}

public Action Hakkimkacoc(int client, int args)
{
	CPrintToChat(client, " {darkred}[ByDexter] {darkblue}Komutçu: {green}%d", KomRevHakki);
	CPrintToChat(client, " {darkred}[ByDexter] {darkblue}Koruma: {green}%d", CTRevHakki);
}

public Action OnClientSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == CS_TEAM_CT && Normalverme[client] && !IsFakeClient(client))
	{
		CPrintToChat(client, "{darkred}[ByDexter] {default}Canlandığınız için {green}%d saniye {default}Godunuz var.", ConVar_god_T.IntValue);
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderColor(client, 0, 255, 0, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		T_God = CreateTimer(ConVar_god_T.FloatValue, Godalma, client, TIMER_FLAG_NO_MAPCHANGE);
		Goduvar[client] = 1;
	}
}

public Action Godalma(Handle Timer, any client)
{
	if (Goduvar[client])
	{
		CPrintToChat(client, "{darkred}[ByDexter] {green}Godunuz artık yok.");
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		Goduvar[client] = 0;
	}
}

public Action OnClientDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	Goduvar[client] = 0;
	if (GetClientTeam(client) == CS_TEAM_CT && !IsFakeClient(client))
	{
		if (KomRevHakki >= 1 && warden_iswarden(client))
		{
			T_KomRev = CreateTimer(ConVar_kom_T.FloatValue, WCanlandirma, client, TIMER_FLAG_NO_MAPCHANGE);
			CPrintToChat(client, "{darkred}[ByDexter] {darkblue}Komutçu {green}%d saniye {default}sonra canlancak", ConVar_kom_T.IntValue);
			Normalverme[client] = 1;
		}
		else if (CTRevHakki >= 1 && !warden_iswarden(client))
		{
			T_CTRev = CreateTimer(ConVar_kor_T.FloatValue, Canlandirma, client, TIMER_FLAG_NO_MAPCHANGE);
			CPrintToChat(client, "{darkred}[ByDexter] {darkblue}Koruma {green}%d saniye {default}sonra canlancak", ConVar_kor_T.IntValue);
			Normalverme[client] = 1;
		}
		else if (KomRevHakki <= 0)
		{
			CPrintToChatAll("{darkred}[ByDexter] {darkblue}Komutçunun {default}rev hakkı bittiği için {darkred}canlandırılmayacak !");
		}
		else if (CTRevHakki <= 0)
		{
			CPrintToChatAll("{darkred}[ByDexter] {green}CT rev hakkı {default}bittiği için {darkred}canlandırılmayacaklar !");
		}
	}
}

public Action WCanlandirma(Handle Timer, any client)
{
	if (GetClientTeam(client) == CS_TEAM_CT && !IsFakeClient(client) && !IsPlayerAlive(client))
	{
		if (KomRevHakki >= 1 && warden_iswarden(client))
		{
			KomRevHakki--;
			CS_RespawnPlayer(client);
			Normalverme[client] = 0;
			CPrintToChatAll("{darkred}[ByDexter] {darkblue}%N {default}adlı komutçu canlandı", client);
			CPrintToChat(client, "{darkred}[ByDexter] {darkblue}%N {green}%d hakkın {default}kaldı!", client, KomRevHakki);
			delete T_KomRev;
		}
	}
}

public Action Canlandirma(Handle Timer, any client)
{
	if (GetClientTeam(client) == CS_TEAM_CT && !IsFakeClient(client) && !IsPlayerAlive(client))
	{
		if (CTRevHakki >= 1)
		{
			CTRevHakki--;
			CS_RespawnPlayer(client);
			Normalverme[client] = 0;
			CPrintToChatAll("{darkred}[ByDexter] {darkblue}%N {default}adlı koruma canlandırıldı !", client);
			CPrintToChat(client, "{darkred}[ByDexter] {green}%d hakkın {default}kaldı!", CTRevHakki);
			delete T_CTRev;
		}
	}
}

public Action Round_StartEnd(Handle event, const char[] name, bool dontBroadcast)
{
	KomRevHakki = ConVar_kom_H.IntValue;
	CTRevHakki = ConVar_kor_H.IntValue;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Goduvar[i])
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			Goduvar[i] = 0;
		}
	}
	delete T_KomRev;
	delete T_CTRev;
	delete T_God;
}