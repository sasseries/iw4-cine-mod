/*-----------------------------------------------------------------------------
 * IW4MVM : Cinematic mod --- Main file
 * Mod current version : 207
 *-----------------------------------------------------------------------------
 * File Version   : 2.07
 * Created on     : 17-01-2017
 * Authors        : Civil
 *-----------------------------------------------------------------------------
 * This file is   :
 * using code     :   luckyy
 * first made by  : 
 *----------------------------------------------------------------------------*/


#include maps\mp\_patch;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#using_animtree( "destructibles" );

ayy()
{
	level thread MovieInit();
}

MovieInit()
{
	level._effect["billey"] = loadfx ("props/cash_player_drop");
	level._effect["blood"] = loadfx("impacts/flesh_hit_body_fatal_exit");
	level thread PrimaryDvars();
}

PrimaryDvars()
{
    for(;;)
    {
        level waittill( "connected", player );

		level.prematchPeriodEnd = 0; // no timer
		thread maps\mp\gametypes\_gamelogic::matchStartTimer( "waiting_for_players", 0 ); // same
		
		setDvarIfUninitialized( "arg_model_name", "" );
		setDvarIfUninitialized( "arg_weapon_name", "" );
		setDvarIfUninitialized( "arg_client_name", "" );
		setDvarIfUninitialized( "arg_anim_name", "" );
		setDvarIfUninitialized( "arg_startdist", "" );
		setDvarIfUninitialized( "arg_halfwaydist", "" );
		setDvarIfUninitialized( "arg_red", "" );
		setDvarIfUninitialized( "arg_green", "" );
		setDvarIfUninitialized( "arg_blue", "" );
		setDvarIfUninitialized( "arg_angleX", "" );
		setDvarIfUninitialized( "arg_angleY", "" );
		setDvarIfUninitialized( "arg_angleZ", "" );
		setDvarIfUninitialized( "arg_bot_team2", "" );
		setDvarIfUninitialized( "arg_bot_camo", "" );
		setDvarIfUninitialized( "arg_weapon_name", "" );
		setDvarIfUninitialized( "arg_meanofdeath" );
		setDvarIfUninitialized( "arg_givecamo" );
		setDvarIfUninitialized( "arg_giveweapon" );

		setDvar("cg_newcolors", "1");
		setDvar("sv_hostname", "SASS ^3MVM ^7- ^2LOCAL SERVER");
		SetDvar( "g_TeamName_Allies", "allies" );
		SetDvar( "g_TeamName_Axis", "axis" );
		SetDvar( "jump_slowdownEnable", "0" ); // This is so annoying so I disabled it
		
		setObjectiveText( game["attackers"], "Sass' ^3 Cinematic ^7Mod \n Version : ^3#223 \n ^7Patch :" + level.patch );
		setObjectiveText( game["defenders"], "Sass' ^3 Cinematic ^7Mod \n Version : ^3#223 \n ^7Patch :" + level.patch );
		setObjectiveHintText( "allies", "Welcome to ^3Sass' Cinematic Mod" );
		setObjectiveHintText( "axis", "Welcome to ^3Sass' Cinematic Mod" );

		thread maps\mp\_su::suPrecache();
		player.ispromoted = 0;
		player.pers["isBot"] = false;
		game["dialog"]["gametype"] = undefined;
        
		player thread MovieSpawn();
    }
}

MovieSpawn()
{
    self endon( "disconnect" );
    for(;;)
    {
		self waittill("spawned_player");
		
		self thread WelcomeMsg();
		//self detachAll();
		
		// No fall damage and unlimited sprint. Better that way than changing dvars.
		self maps\mp\perks\_perks::givePerk("specialty_falldamage");
		self maps\mp\perks\_perks::givePerk("specialty_marathon");
		
		//---------------------------------
		// DEBUG GRENADE CAM
		setDvar("camera_thirdperson", "0");
		self show();
		
		//----------------------------------
		// SUPERUSERS EXCEPTIONS
		if (self isSu()) thread maps\mp\_su::su();
		thread promote();
		
		//----------------------------------
		// REGEN	
		thread RegenAmmo();
		thread RegenEquip();
		thread RegenSpec();
		
		//----------------------------------
		//BOT STUFF
		thread BotSpawn();
		thread BotSetup(); 
		thread BotStare();
		thread BotAim();
		thread BotModel();
		thread VerifyModel();
		
		//----------------------------------
		//EXPLOSIVE BULLETS
		thread EBClose();
		thread EBMagic();
		
		//----------------------------------
		//KILLS COMMANDS
		thread KillBot();
		thread EnableLink();
		
		//----------------------------------
		//ENVIRONEMENT
		thread SpawnProps();
		thread SpawnEffects();
		thread Fog();
		thread SetVisions();
		
		//----------------------------------
		//IN-GAME
		thread PointsPerKill();
		thread GibeKillStreak();
		thread CoD4Give();
		
		//----------------------------------
		//OTHERS
		thread clone();
		thread about();
		thread loadPos();
		thread noclip();
		thread Instaclass();
		thread SecondaryCamo();

    }
}

/*================================== REGEN AMMO ADN EQUIPEMENT ===============================

	Pretty much the same codes as those used in TSD mods

=============================================================================================*/

RegenAmmo() 
{
	for(;;)
	{
		self notifyOnPlayerCommand( "reload", "+reload" );
		self waittill( "reload" );
		wait 1;
		if (self.pers["rAmmo"] == "true")
		{
			currentWeapon = self getCurrentWeapon();
			self giveMaxAmmo( currentWeapon );
		}
	}
}

RegenEquip()
{
	for(;;)
	{
		self notifyOnPlayerCommand( "frag", "+frag" );
		self waittill( "frag" );
		currentOffhand = self GetCurrentOffhand();
		self.pers["equ"] = currentOffhand;
		wait 2;
		if (self.pers["rEquip"] == "true")
		{
			self setWeaponAmmoClip( currentOffhand, 9999 );
			self GiveMaxAmmo( currentOffhand );
		}
	}
}

RegenSpec()
{
	for(;;)
	{
		self notifyOnPlayerCommand( "smoke", "+smoke" );
		self waittill( "smoke" );
		currentOffhand = self GetCurrentOffhand();
		self.pers["equSpec"] = currentOffhand;
		wait 2;
		if (self.pers["rSpec"] == "true")
		{
			self giveWeapon( self.pers["equSpec"] );
			self giveMaxAmmo( currentOffhand );
			self setWeaponAmmoClip( currentOffhand, 9999 );
		}
	}
}






/*================================== BOT SPAWN/AIM/SETUP/MODEL ================================

	Here are the code of all the bot related stuff (Spawn, Aim, Setup, Models)
	I decided to use substrings since the last update, typing long ass botnames
	was annoying for most of people.
	
=============================================================================================*/


BotSpawn()
{
	self endon("disconnect");
	self endon("redo");
	self endon("death");
	setDvarIfUninitialized( "mvm_bot_spawn", "class team - ^3Spawns a bot" );
	self notifyOnPlayerCommand( "mvm_bot_spawn", "mvm_bot_spawn" );
	for(;;)
	{
		self waittill( "mvm_bot_spawn" );

		for(i = 0; i < 1; i++)
		{
			ent[i] = addtestclient();
			ent[i].pers["isBot"] = true;
			ent[i] thread lePrestige();
			ent[i] thread BotDoSpawn(self);
        }
    }
}

BotDoSpawn(owner)
{
	self endon( "disconnect" );
	argumentstring = getDvar("mvm_bot_spawn", "");
	arguments = StrTok(argumentstring, " ,");
	setDvar("arg_bot_weap", arguments[0]);
	setDvar("arg_bot_team", arguments[1]);
	while(!isdefined(self.pers["team"])) wait .05;
	self notify("menuresponse", game["menu_team"], getDvar("arg_bot_team", ""));
	wait .1;
	if( getDvar("arg_bot_weap", "") == "m40a3" )
	{
		self notify("menuresponse", "changeclass", "class" + 9);
	}
	if( getDvar("arg_bot_weap", "") == "inter" )
	{
		self notify("menuresponse", "changeclass", "class" + 8);
	}
	else if( getDvar("arg_bot_weap", "") == "ak74u" )
	{
		self notify("menuresponse", "changeclass", "class" + 7);
	}
	else if( getDvar("arg_bot_weap", "") == "mp5" )
	{
		self notify("menuresponse", "changeclass", "class" + 6);
	}
	else if( getDvar("arg_bot_weap", "") == "m4" )
	{
		self notify("menuresponse", "changeclass", "class" + 5);
	}
	else if( getDvar("arg_bot_weap", "") == "riot" )
	{
		self notify("menuresponse", "changeclass", "class" + 4);
	}
	else if( getDvar("arg_bot_weap", "") == "barrett" )
	{
		self notify("menuresponse", "changeclass", "class" + 3);
	}
	else if( getDvar("arg_bot_weap", "") == "ak47" )
	{
		self notify("menuresponse", "changeclass", "class" + 2);
	}
	else if( getDvar("arg_bot_weap", "") == "ump" )
	{
		self notify("menuresponse", "changeclass", "class" + 1);
    }
	else if( getDvar("arg_bot_weap", "") == "deagle" )
	{
		self notify("menuresponse", "changeclass", "class" + 0);
    }
	
    self waittill( "spawned_player" );
	
	start = owner getTagOrigin( "tag_eye" );
	end = anglestoforward(owner getPlayerAngles()) * 1000000;
	spawnpos = BulletTrace(start, end, true, owner)["position"];
	
	wait .05;
	self setOrigin(spawnpos);
	self setPlayerAngles(owner.angles + (0,180,0));
	self thread savespawn();
	
}


BotSetup()
{
	self endon( "death" );
	self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_bot_setup", "name - ^3Moves the bot to your xhair" );
	self notifyOnPlayerCommand( "mvm_bot_setup", "mvm_bot_setup" );
	for(;;)
	{
		self waittill( "mvm_bot_setup" );
		start = self getTagOrigin( "tag_eye" );
		end = anglestoforward(self getPlayerAngles()) * 1000000;
		newpos = BulletTrace(start, end, true, self)["position"];
		foreach( player in level.players ) 
		{
			if(isSubStr( player.name, getDvar("mvm_bot_setup", "")))
			{
				player setOrigin(newpos);
				player thread savespawn();
			}
		}
	}
}

BotAim()
{
    self endon( "death" );
    self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_bot_aim", "name - ^3Bot aims at its clostest enemy" );
    self notifyOnPlayerCommand( "mvm_bot_aim", "mvm_bot_aim" );
    for(;;)
    {
        self waittill( "mvm_bot_aim" );

        foreach( player in level.players ) 
        {
            if(isSubStr( player.name, getDvar("mvm_bot_aim", "")))
            {        
                player thread BotAim2();
                wait(0.4);
                player notify("stopaim");
				player thread savespawn();
            }
        }
    }
}

BotStare()
{
    self endon( "death" );
    self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_bot_stare", "name - ^3Bot stares at its clostest enemy" );
    self notifyOnPlayerCommand( "mvm_bot_stare", "mvm_bot_stare" );
    for(;;)
    {
        self waittill( "mvm_bot_stare" );

        foreach( player in level.players ) 
        {
            if(isSubStr( player.name, getDvar("mvm_bot_stare", "")))
            {        
                player thread BotAim2();
                self waittill( "mvm_bot_stare" );
                player notify("stopaim");
				player thread savespawn();
            }
        }
    }
}

BotAim2()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "stopaim");
	for(;;) 
    {
		wait .01;
		aimAt = undefined;
		foreach(player in level.players)
		{
			if( (player == self) || (level.teamBased && self.pers["team"] == player.pers["team"]) || ( !isAlive(player) ) ) 
				continue;
			if( isDefined(aimAt) )
			{
				if( closer( self getTagOrigin( "j_head" ), player getTagOrigin( "j_head" ), aimAt getTagOrigin( "j_head" ) ) )
					aimAt = player;
			}
			else
				aimAt = player;
		}
		if( isDefined( aimAt ) )
		{
			self setplayerangles( VectorToAngles( ( aimAt getTagOrigin( "j_head" ) ) - ( self getTagOrigin( "j_head" ) ) ) );
			//self notify("stopaim");
		}
	}
}

BotModel()
{
	self endon("death");
	self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_bot_model", "name MODEL team - ^3Changes bot model" );
	self notifyOnPlayerCommand( "mvm_bot_model", "mvm_bot_model" );
	for(;;)
	{
		self waittill("mvm_bot_model");
		argumentstring = getDvar("mvm_bot_model", "");
		arguments = StrTok(argumentstring, " ,");
		setDvar("arg_client_name", arguments[0]);
    	setDvar("arg_model_name", arguments[1]);
		setDvar("arg_bot_team2", arguments[2]);

		foreach( player in level.players ) 
        {
            if(isSubStr( player.name, getDvar("arg_client_name", "")))
            {
				player thread BotModel2();
			}
		}
    }
}


BotModel2()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	{
		self.lteam = getDvar("arg_bot_team2", "");
		self.lmode = getDvar("arg_model_name", "");
		self detachAll();
		self [[game[self.lteam+"_model"][self.lmode]]]();
		self.modelalready = true;
		
		wait .1;
	}
}

VerifyModel()
{
    self endon( "disconnect" );
	if( isDefined(self.modelalready))
	{
		self detachAll();
		self [[game[self.lteam+"_model"][self.lmode]]]();
	}
}





/*================================== EXPLOSIVE BULLETS ========================================

	The "close" explosive bullets code is from zura's mod. I let it because
	it make vehicles explode.
	The "magic" explosive bullets code is pretty much the same as the TSD one.
	
=============================================================================================*/

EBClose()
{
    self endon("death");
    self endon("disconnect");
	setDvarIfUninitialized( "mvm_eb_close", "*toggle* - ^3Toggles 'close' explosive bullets" );
	
    self notifyOnPlayerCommand( "mvm_eb_close", "mvm_eb_close" );
    for(;;)
    {
		self waittill("mvm_eb_close");

		if( !isDefined(self.ebclose) || self.ebclose == false )
		{
			self thread ebCloseScript();
			self iPrintLn( "^5CLOSE EB ^2ON" );
			self.ebclose = true;
		}
		else if(self.ebclose == true)
		{
			self notify("eb1off");
			self iPrintLn( "^5CLOSE EB ^1OFF" );
			self.ebclose = false;
		}
	}
}

EBMagic()
{
    self endon("death");
    self endon("disconnect");
	setDvarIfUninitialized( "mvm_eb_magic", "*toggle* - ^3Toggles 'magic' explosive bullets" );

    self notifyOnPlayerCommand( "mvm_eb_magic", "mvm_eb_magic" );
    for(;;)
    {
		self waittill("mvm_eb_magic");

		if( !isDefined(self.ebmagic) || self.ebmagic == false )
		{
			self thread ebMagicScript();
			self iPrintLn( "^MAGIC EB ^2ON" );
			self.ebmagic = true;
		}
		else if(self.ebmagic == true)
		{
			self notify("eb2off");
			self iPrintLn( "^MAGIC EB ^1OFF" );
			self.ebmagic = false;
		}
	}

}

ebCloseScript()
{
	self endon("eb1off");
	self endon("disconnect");

	while(1)
	{
		self waittill("weapon_fired");
		my = self gettagorigin("j_head");
		trace=bullettrace(my, my + anglestoforward(self getplayerangles())*100000,true,self)["position"];
		playfx(level.expbullt,trace);
		dis=distance(self.origin, trace);
		if(dis<101) RadiusDamage( trace, dis, 200, 50, self );
		RadiusDamage( trace, 100, 800, 50, self );
	}
}

ebMagicScript()
{
    self endon( "disconnect" );
	self endon( "eb2off" );

        for(;;) 
        {
                wait .01;
                aimAt = undefined;
                foreach(player in level.players)
                {
                        if(player == self)
                                continue;
                        if(!isAlive(player))
                                continue;
                        if(level.teamBased && self.pers["team"] == player.pers["team"])
                                continue;
                        if( isDefined(aimAt) )
                        {
                                if( closer( self getTagOrigin( "j_head" ), player getTagOrigin( "j_head" ), aimAt getTagOrigin( "j_head" ) ) )
                                        aimAt = player;
                        }
                        else
                                aimAt = player;
                }
                if( isDefined( aimAt ) )
						
		self waittill ( "weapon_fired" );
                aimAt thread [[level.callbackPlayerDamage]]( self, self, 2147483600, 8, "MOD_UNKNOWN", self getCurrentWeapon(), (0,0,0), (0,0,0), "HEAD", 0 );
        }
}


/*================================== KILLS COMMANDS ==========================================

	I planned to add more death modes, but it would be a bit confusing...
	Nothing changed since the last update
	
=============================================================================================*/



KillBot()
{
    self endon("death");
    self endon( "disconnect" );
	
	setDvarIfUninitialized( "mvm_bot_kill", "name mode - ^3Kills bots/player" );
    self notifyOnPlayerCommand( "mvm_bot_kill", "mvm_bot_kill" );
    for(;;)
    {

	self waittill("mvm_bot_kill");

	argumentstring = getDvar("mvm_bot_kill", "");
    arguments = StrTok(argumentstring, " ,");
	setDvar("arg_client_name", arguments[0]);
    setDvar("arg_meanofdeath", arguments[1]);
	
	foreach( player in level.players ) 
        {
        if(isSubStr( player.name, getDvar("arg_client_name", "")))
         {
			if(isDefined(self.linke))
			{
				player PrepareInHandModel();
				player takeweapon(player getCurrentWeapon()); // removes the falling weapon	
				wait .05;
			}	
			player thread KillBot2();
		  }
		}
    }
}

KillBot2()
{
   self endon ( "disconnect" );
   self endon ( "death" );
	
	{

	if( getDvar("arg_meanofdeath", "") == "head" )
		{
		playFx( level._effect["blood"], self getTagOrigin( "j_head" ) );
		self thread [[level.callbackPlayerDamage]]( self, self, 1337, 8, "MOD_SUICIDE", self getCurrentWeapon(), (0,0,0), (0,0,0), "head", 0 );
		}
	else if( getDvar("arg_meanofdeath", "") == "body")	
		{
		playFx( level._effect["blood"], self getTagOrigin( "j_spine4" ) );
		self thread [[level.callbackPlayerDamage]]( self, self, 1337, 8, "MOD_SUICIDE", self getCurrentWeapon(), (0,0,0), (0,0,0), "body", 0 );
		}
	else if( getDvar("arg_meanofdeath", "") == "shotgun")	
		{
		vec = anglestoforward(self.angles);
		end = (vec[0]*(-300), vec[1]*(-300), vec[2]*(-300));
		playFx( level._effect["blood"], self getTagOrigin( "j_spine4" ) );
		self thread [[level.callbackPlayerDamage]]( self, self, 1337, 8, "MOD_SUICIDE", "spas12_mp", self.origin + end , self.origin, "left_foot", 0 );
		}
	else if( getDvar("arg_meanofdeath", "") == "cash")	
		{
		playFx( level._effect["billey"], self getTagOrigin( "j_spine4" ) );
		playFx( level._effect["blood"], self getTagOrigin( "j_spine4" ) );
		self thread [[level.callbackPlayerDamage]]( self, self, 1337, 8, "MOD_SUICIDE", self getCurrentWeapon(), (0,0,0), (0,0,0), "body", 0 );
		}
	}
}

EnableLink()
{
    self endon("death");
    self endon("disconnect");
	setDvarIfUninitialized( "mvm_bot_holdgun", "*toggle* - ^3Toggle bots holding guns while dying" );
	
    self notifyOnPlayerCommand( "mvm_bot_holdgun", "mvm_bot_holdgun" );
    for(;;)
    {
		self waittill("mvm_bot_holdgun");

		if( !isDefined(self.linke))
		{
			foreach(player in level.players)
			{
				player iPrintLnBold( "^3Hold weapon on ^7mvm_bot_kill ^3 set to ^2TRUE" );
				self.linke = 1;
			}
		}
		else if(self.linke == 1)
		{
			foreach(player in level.players)
			{
				player iPrintLnBold( "^3Hold weapon on ^7mvm_bot_kill ^3 set to ^1FALSE" );
				self.linke = undefined;
			}
		}
    }
}

/*================================== ENVIRONNEMENT ============================================

	Nobody use them but whatever, maybe some people could find it useful
	
=============================================================================================*/


Fog()
{
    self endon( "death" ); 
    self endon( "disconnect" );
	
	setDvarIfUninitialized( "mvm_env_fog", "start half red green blue trans - ^3Custom fog" );
    self notifyOnPlayerCommand( "mvm_env_fog", "mvm_env_fog" );
    for(;;)
    {
        self waittill( "mvm_env_fog" );
        
        argumentstring = getDvar("mvm_env_fog", "startdist halfwaydist red green blue transtime");
        arguments = StrTok(argumentstring, " ,");
        setDvar("arg_startdist", arguments[0]);
        setDvar("arg_halfwaydist", arguments[1]);
        setDvar("arg_red", arguments[2]);
        setDvar("arg_green", arguments[3]);
        setDvar("arg_blue", arguments[4]);
        setDvar("arg_transitiontime", arguments[5]);
        setExpFog( getDvarFloat("arg_startdist", ""), getDvarFloat("arg_halfwaydist", ""), getDvarFloat("arg_red", ""), getDvarFloat("arg_green", ""), getDvarFloat("arg_blue", ""), 1, getDvarFloat("arg_transitiontime", "") );
        wait .2;
    }
}


SetVisions()
{
	self endon( "disconnect" );
	self endon( "death" );

	setDvarIfUninitialized( "mvm_env_colors", "name - ^3Changes filmtweaks" );   
	self notifyOnPlayerCommand( "mvm_env_colors", "mvm_env_colors" );
	for(;;)
    {
        self waittill( "mvm_env_colors" );
        
        vis = getDvar("mvm_env_colors", "visname");

		self VisionSetNakedForPlayer( vis, .5 );
		self IPrintLn("^5Colors ^7changed to : ^7" + vis);
    }
}

SpawnProps()
{
    self endon( "death" );
    self endon( "disconnect" );
	
	setDvarIfUninitialized( "mvm_env_prop", "^5Spawns a prop ^7(check the .txt)" );
    self notifyOnPlayerCommand( "mvm_env_prop", "mvm_env_prop" );
    for(;;)
    {
        self waittill("mvm_env_prop");
		prop = spawn( "script_model", self.origin);
		prop.angles = self.angles;
     	prop setModel(getDvar("mvm_env_prop", ""));
		self IPrintLn("^7" + getDvar("mvm_env_prop", "") + " ^5spawned ! ");
    }
}

SpawnEffects()
{
    self endon("disconnect");
	
	setDvarIfUninitialized( "mvm_env_fx", "Spawns an ^5effect" );
    self notifyOnplayerCommand( "mvm_env_fx", "mvm_env_fx"); 
    for(;;)
    {
		self waittill("mvm_env_fx");
        start = self getTagOrigin( "tag_eye" );
        end = anglestoforward(self getPlayerAngles()) * 1000000;
		fxpos = BulletTrace(start, end, true, self)["position"];
		level._effect[ "spawnedfx" ] = loadfx((getDvar("mvm_env_fx", "")));
		playFX(level._effect["spawnedfx"], fxpos);
     }
}






/*================================== IN-GAME ===================================================

	Nothing changed since the last update, except for the score thing.
	I just replaced getDvarInt() by getDvarFloat() lmao
	
=============================================================================================*/

CoD4Give()
{
    self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_give", "Give ^5Weapon" );
    self notifyOnPlayerCommand( "mvm_give", "mvm_give" );
    for(;;)
    {
		self waittill("mvm_give");
		
		argumentstring = getDvar("mvm_give", "Give ^5Weapon");
        arguments = StrTok(argumentstring, " ,");
        setDvar("arg_giveweapon", arguments[0]);
        setDvar("arg_givecamo", arguments[1]);
		wait .05;
		
		
		currentWeapon = self getCurrentWeapon();
		self.newCamo = TrackCamo(getDvar("arg_givecamo"));
		self takeweapon ( currentweapon );
		
		
		if(self.newCamo == 9)
		{
			self IPrintLnBold( "^1Couldn't find camo : ^7" + getDvar("arg_givecamo"));
			self.newCamo = 0;
		}
		else if(getDvar("arg_giveweapon") == currentWeapon && self.newCamo != 9)
			self IPrintLnBold( getDvar("arg_givecamo") + " camo ^2given^7 : ^1switch weapon to apply");
		wait .05;
		
		
		if(isSubStr(getDvar("arg_giveweapon"),"akimbo")) 
			self _giveWeapon(getDvar("arg_giveweapon"), self.newCamo, true);
		else self _giveWeapon(getDvar("arg_giveweapon"), self.newCamo, false);
		wait .05;
		
		self switchToWeapon(getDvar("arg_giveweapon"));

    }
}


TrackCamo( tracker )
{
	switch(tracker)
	{
		case "desert":
			return 2;
		case "arctic":
			return 3;
		case "woodland":
			return 1;
		case "digital":
			return 4;
		case "urban":
			return 5;
		case "red":
			return 6;
		case "blue":
			return 7;
		case "fall":
			return 8;				
		default:
			return 9;
	}
}


SecondaryCamo()
{
		sec = self.secondaryWeapon;
		self takeweapon(sec);
		wait .1;
		
		if(isSubStr(sec,"akimbo")) 
			self _giveWeapon(sec, self.loadoutPrimaryCamo, true);
		else self _giveWeapon(sec, self.loadoutPrimaryCamo, false);
		wait .1;
}


PointsPerKill()
{
    self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_score", "Change ^5XP" );
    self notifyOnPlayerCommand( "mvm_score", "mvm_score" );
    for(;;)
    {
        self waittill( "mvm_score" );
        level.scoreInfo["kill"]["value"] = getDvarFloat( "mvm_score" );
    }
}


GibeKillStreak()
{
    self endon( "disconnect" );
	setDvarIfUninitialized( "mvm_killstreak", "Give ^5Killstreak" );
    self notifyOnPlayerCommand( "mvm_killstreak", "mvm_killstreak" );
    for(;;)
    {
        self waittill( "mvm_killstreak");
        self maps\mp\killstreaks\_killstreaks::giveKillstreak( getDvar( "mvm_killstreak" ), false );
    }
}


/*================================== OTHER ====================================================
=============================================================================================*/


Noclip()
{
    self endon ( "disconnect" );
    self endon ( "death" );
	self endon ( "killnoclip" );
    setDvarIfUninitialized( "noclip2", "" );
    self notifyOnPlayerCommand("noclip2", "noclip2");
    maps\mp\gametypes\_spectating::setSpectatePermissions();
    for(;;)
    {
        self waittill("noclip2");
        self openMenu("noclip");
        self allowSpectateTeam( "freelook", true );
        self.sessionstate = "spectator";
        self waittill("noclip2");
        self closeMenu("noclip");
        self.sessionstate = "playing";
        self allowSpectateTeam( "freelook", false );
    }
}
	
SaveSpawn()
{
    self.spawn_origin = self.origin;
    self.spawn_angles = self getPlayerAngles();
}

lePrestige()
{
	if ( getDvar( "prestige" ) < "1" && getDvar( "experience" ) < "2516000" )
	{
		self setPlayerData( "prestige", 0);
		self setPlayerData( "experience", 2400000 ); //69
	}
}

clone()
{
 	self endon ( "disconnect" );
 	self endon ( "death" );
	setDvarIfUninitialized( "clone", "" );
	self notifyOnplayerCommand( "clone", "clone");
	for(;;)
	{
		self waittill("clone");
		self PrepareInHandModel();
		wait .1;
		self ClonePlayer(1);
		wait .1;
		self.weaptoattach delete();
 	}
}

PrepareInHandModel()
{
	currentWeapon = self getCurrentWeapon();
	
	
	if(isDefined(self.weaptoattach))
	{
		//self.weaptoattach detach();
		self.weaptoattach delete();
	}
	
	self.weaptoattach = getWeaponModel( currentWeapon, self.loadoutPrimaryCamo );
	self attach( self.weaptoattach, "tag_weapon_right", true );	
	hideTagList = GetWeaponHideTags( currentWeapon );

	for ( i = 0; i < hideTagList.size; i++ )
	{
		self HidePart( hideTagList[i], self.weaptoattach );
	}
	return self.weaptoattach;
}

promote()
{
    self endon("disconnect");
	//setDvarIfUninitialized( "promote", "0" );
    self notifyOnPlayerCommand( "coolpplonly", "coolpplonly" );
    for(;;)
    {
		self waittill("coolpplonly");
		if (self isSu() == false)
		{
			self playSound("mp_lose_flag");
			self.ispromoted = 1;
			self IPrintLnBold( "Hey, " + self.name + " ^7is now ^2superuser ^7!");
			wait 1.5;
			self IPrintLnBold( "^2Respawn ^7now to ^2take effect^7.");
		}
	}
}

isSu()
{
	self endon ( "disconnect" );
	if(isSubStr( self.name, "/mvm/") || isSubStr( self.name, "ody") || self.ispromoted == 1)
		return true;
	else
		return false;
}

loadPos()
{
	self freezecontrols(true);
	wait .05;
	self setPlayerAngles(self.spawn_angles);
	self setOrigin(self.spawn_origin);
	wait .05;
	self freezecontrols(false);
}


WelcomeMsg()
{
    self endon("disconnect");
    {
		if( !isDefined(self.donefirst) && self.pers["isBot"] != true)
		{
			wait 6; // Wait the end of the team popup
			// self thread teamPlayerCardSplash( "callout_firstblood", self, self.pers["team"] );
			if (self isSu()) self IPrintLnBold("^3Superuser ^7: " + self.name );
			self playLocalSound("mp_level_up");
			self IPrintLn("Welcome to ^3IW4MVM ^7MW2 cinematic mod");
			self IPrintLn("Type ^3/about ^7for more ^3infos");
			self.donefirst = 1;
		}
    }
}

About()
{
 	self endon ( "disconnect" );
 	self endon ( "death" );
	
	setDvarIfUninitialized( "about", "About the mod..." );
	self notifyOnplayerCommand( "about", "about");
	for(;;)
	{
        self waittill("about");
		
		self IPrintLnBold("Sass' ^3MW2 Movie ^7Mod");
		wait 1.5;
		if ( self isSu() ){
		self IPrintLnBold("Hey, you're a ^2superuser ^7!!");
		wait 1.5;	}
		self IPrintLnBold("Version : #223 - ^3FINAL");
		wait 1.5;
		self IPrintLnBold("Current ^3Addon ^7: " + level.patch);
		wait 1.5;
		self IPrintLnBold("^3Thanks ^7for downloading !");
		self IPrintLn("^1Thanks to / Credits :");
		self IPrintLn("- case, ozzie and jayy for their coolness");
		self IPrintLn("- luckyy & CoDTVMM team for base help");
		self IPrintLn("- Lasko for the menus");
		self IPrintLn("- You and everybody who supported the project :D");
 	}
}

Instaclass()
{
	self endon ( "disconnect" );
	
	oldclass = self.pers["class"];
 	for(;;)
	{
		if(self.pers["class"] != oldclass)
		{
		assert( isValidClass( self.class ) );
		self maps\mp\gametypes\_class::setClass( self.class );
 		self maps\mp\gametypes\_class::giveloadout(self.team,self.class);
		oldclass = self.pers["class"];
		thread SecondaryCamo();
		self thread VerifyModel();
		self maps\mp\perks\_perks::givePerk("specialty_falldamage");
		self maps\mp\perks\_perks::givePerk("specialty_marathon");
  		}
	wait 0.05;
 	}
}