#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "Mute friendly knifing",
	author      = "fakuivan",
	description = "Mutes knife sounds against friendly targets when no damage is dealt",
	version     = "",
	url         = "https://forums.alliedmods.net/member.php?u=264797"
};

enum LastAttackInfo
{
	LAI_Mute,
	LAI_Inflictor,
}

int MuteAttack[MAXPLAYERS][LastAttackInfo];

public void OnPluginStart()
{
	AddNormalSoundHook(SoundHook);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) { continue; }
		MuteAttack[i][LAI_Mute] = false;
		SDKHook(i, SDKHook_TraceAttack, TraceHook);
	}
}

public void OnClientPutInServer(int client)
{
	MuteAttack[client][LAI_Mute] = false;
	SDKHook(client, SDKHook_TraceAttack, TraceHook);
}

stock bool IsEntityKnife(int entity)
{
	char classname[255];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") > -1;
}

public Action TraceHook(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (GetClientTeam(victim) != GetClientTeam(attacker))
	{
		MuteAttack[attacker][LAI_Mute] = false;
		return Plugin_Continue;
	}
	int weapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
	if (IsEntityKnife(weapon))
	{
		MuteAttack[attacker][LAI_Mute] = true;
		MuteAttack[attacker][LAI_Inflictor] = weapon;
	}
	MuteAttack[attacker][LAI_Mute] = false;
	return Plugin_Continue;
}

public Action SoundHook(int clients[MAXPLAYERS], 
                 int& numClients, 
                 char sample[PLATFORM_MAX_PATH], 
                 int& entity, 
                 int& channel, 
                 float& volume, 
                 int& level, 
                 int& pitch, 
                 int& flags, 
                 char soundEntry[PLATFORM_MAX_PATH], 
                 int& seed)
{
	if (!IsEntityKnife(entity)) return Plugin_Continue;

	int attacker = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (!IsClientConnected(attacker)) return Plugin_Continue;

	if (!MuteAttack[attacker][LAI_Mute]) return Plugin_Continue;

	if (MuteAttack[attacker][LAI_Inflictor] == entity)
	{
		MuteAttack[attacker][LAI_Mute] = false;
		return Plugin_Stop;
	}
	else
	{
		// A ``SoundHook`` call from a different emmiter slipped in between the expected ``TraceHook`` -> ``SoundHook`` flow
		ThrowError("Attack and hit sound callbacks desynchronized. This is not how this plugin is supposed to work!");
		return Plugin_Continue;
	}
}
