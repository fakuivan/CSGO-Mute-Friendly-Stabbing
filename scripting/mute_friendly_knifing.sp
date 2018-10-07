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

public void OnPluginStart()
{
	AddNormalSoundHook(SoundHook);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) { continue; }
		SDKHook(i, SDKHook_TraceAttack, TraceHook);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceHook);
}

public Action TraceHook(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	char ent_name[255];
	GetEntityClassname(inflictor, ent_name, sizeof(ent_name));
	PrintToChatAll("%N attacked %N with inflictor %s at index %d dealing %f HP", attacker, victim, ent_name, inflictor, damage);
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
	char ent_name[255];
	GetEntityClassname(entity, ent_name, sizeof(ent_name));
	PrintToChatAll("Sound emmited with sample %s from entity %d with classname %s", sample, entity, ent_name);
}
