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

int gi_mute_payload[MAXPLAYERS][LastAttackInfo];

public void OnPluginStart()
{
    AddNormalSoundHook(Hook_NormalSound);
    for (int i_client = 1; i_client <= MaxClients; i_client++)
    {
        if(!IsClientInGame(i_client)) { continue; }
        gi_mute_payload[i_client][LAI_Mute] = false;
        SDKHook(i_client, SDKHook_TraceAttack, Hook_TraceAttack);
    }
}

public void OnClientPutInServer(int i_client)
{
    gi_mute_payload[i_client][LAI_Mute] = false;
    SDKHook(i_client, SDKHook_TraceAttack, Hook_TraceAttack);
}

stock bool IsEntityKnife(int i_entity)
{
    char s_classname[255];
    GetEntityClassname(i_entity, s_classname, sizeof(s_classname));
    return  StrContains(s_classname, "knife") != -1 || 
            StrContains(s_classname, "bayonet") > -1;
}

public Action Hook_TraceAttack( int i_victim,
                                int &i_attacker,
                                int &i_inflictor,
                                float &f_damage,
                                int &i_damagetype,
                                int &i_ammotype,
                                int i_hitbox,
                                int i_hitgroup)
{
    if (GetClientTeam(i_victim) != GetClientTeam(i_attacker))
    {
        gi_mute_payload[i_attacker][LAI_Mute] = false;
        return Plugin_Continue;
    }
    int i_weapon = GetEntPropEnt(i_attacker, Prop_Data, "m_hActiveWeapon");
    if (IsEntityKnife(i_weapon))
    {
        gi_mute_payload[i_attacker][LAI_Mute] = true;
        gi_mute_payload[i_attacker][LAI_Inflictor] = i_weapon;
        return Plugin_Continue;
    }
    gi_mute_payload[i_attacker][LAI_Mute] = false;
    return Plugin_Continue;
}

public Action Hook_NormalSound( int i_clients[MAXPLAYERS],
                                int& i_num_clients,
                                char s_sample[PLATFORM_MAX_PATH],
                                int& i_entity,
                                int& i_channel,
                                float& f_volume,
                                int& i_level,
                                int& i_pitch,
                                int& i_flags,
                                char s_sound_entry[PLATFORM_MAX_PATH],
                                int& i_seed)
{
    if (!IsEntityKnife(i_entity)) return Plugin_Continue;

    int i_attacker = GetEntPropEnt(i_entity, Prop_Data, "m_hOwnerEntity");
    if (!IsClientConnected(i_attacker)) return Plugin_Continue;

    if (!gi_mute_payload[i_attacker][LAI_Mute]) return Plugin_Continue;

    if (gi_mute_payload[i_attacker][LAI_Inflictor] == i_entity)
    {
        gi_mute_payload[i_attacker][LAI_Mute] = false;
        return Plugin_Stop;
    }
    else
    {
        // A ``Hook_NormalSound`` call from a different emmiter slipped in between
        // the expected ``Hook_TraceAttack`` -> ``Hook_NormalSound`` flow
        ThrowError( "Attack and hit sound callbacks desynchronized. " ...
                    "This is not how this plugin is supposed to work!");
        return Plugin_Continue;
    }
}
