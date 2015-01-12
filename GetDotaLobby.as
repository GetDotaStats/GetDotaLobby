package  {
	
	// Valve Libaries
    import ValveLib.Globals;
    import ValveLib.ResizeManager;
	
	// Hacky stuff
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	
	import flash.utils.Timer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
    import flash.events.MouseEvent;
	import scaleform.clik.events.ButtonEvent;
	
	import dota2Net.D2HTTPSocket;
	
	import com.adobe.serialization.json.*;
	
	public class GetDotaLobby extends MovieClip {
		// Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;
		
		public var buttonCount:int = 1;
		
		//These are test values, when API is available, read from them
		//var target_gamemode:int = 322254016; //Shitwars
		var target_gamemode:int; //Warchasers
		var target_password:String;
		var target_lobby:int;
		
		var socket:D2HTTPSocket;
		
		public function GetDotaLobby() {
			// constructor code
		}
		
		
		public function onLoaded() : void {
			trace("injected by SinZ!\n\n\n");
			socket = new D2HTTPSocket("getdotastats.com", "176.31.182.87");
			this.gameAPI.OnReady();
			Globals.instance.resizeManager.AddListener(this);
			
			createTestButton("Create Game", test1);
			createTestButton("Join Game", test2);
			createTestButton("Dump Globals", test3);
			createTestButton("hook clicks", test4);
			createTestButton("Get Lobbies", test5);
			createTestButton("Lobby Status", test6);
		}
		public function test1(event:MouseEvent) { //Create Game
			globals.Loader_top_bar.movieClip.gameAPI.DashboardSwitchToSection(2); //Set topbar to DASHBOARD_SECTION_PLAY
			globals.Loader_play.movieClip.setCurrentTab(12); //Set tab to CustomGames
			
			globals.Loader_custom_games.movieClip.setCustomGameModeListStyle(0); //We want rows, not grid
			globals.Loader_custom_games.movieClip.setCurrentCustomGameSubTab(0); //We want gamemodes, not lobbies
			globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeSortingComboChanged(5); //Typical valve, requires gameAPI for it to work
			
			var injectTimer:Timer = new Timer(50, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, createGame);
            injectTimer.start();
		}
		
		var pattern:RegExp = /Page: (\d) \/ (\d)/;
		public function createGame(e:TimerEvent) {
			var result = pattern.exec(globals.Loader_custom_games.movieClip.CustomGames.ModeList.PageLabel.text);
			trace("#REGEX: Page "+result[1]+" / "+result[2]);
			
			var i:int;
			for (i=0; i < 12; i++) {
				var obj = globals.Loader_custom_games.movieClip.CustomGames.ModeList.Rows["row"+i].FlyOutButton;
				if (obj.GameModeID == false) {
					trace("ROW "+i+" IS A LIE!!");
					continue;
				}
				if (obj.GameModeID == target_gamemode) {
					//Lets test with WarChasers
					globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeFlyoutClicked(obj.row,obj.GameModeID);
					var injectTimer:Timer = new Timer(50, 1);
					injectTimer.addEventListener(TimerEvent.TIMER, createGame2);
					injectTimer.start();
					return; //We found what we want, stop looping and dont hit the error stuff at the end
				}
			}
			if (result[1] == result[2]) {
				//We are on the last page
				//TODO: add some subscribe hackery here
				trace("Geez, git good");
			} else {
				//We have another page!
				trace("New page time!");
				globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeListNextPageClicked();
				var injectTimer:Timer = new Timer(50, 1);
				injectTimer.addEventListener(TimerEvent.TIMER, createGame); //Delayed resurseive function ftw?
				injectTimer.start();
			}
		}
		public function createGame2(e:TimerEvent) {
			globals.Loader_dashboard_overlay.movieClip.onCustomGameCreateLobbyButtonClicked(new ButtonEvent(ButtonEvent.CLICK));
			var injectTimer:Timer = new Timer(250, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, createGame3);
            injectTimer.start();
		}
		public function createGame3(e:TimerEvent) {
			globals.Loader_popups.movieClip.onButton1Clicked(new ButtonEvent(ButtonEvent.CLICK));
			var injectTimer:Timer = new Timer(50, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, createGame4);
            injectTimer.start();
		}
		public function createGame4(e:TimerEvent) {
			globals.Loader_lobby_settings.movieClip.LobbySettings.gamenamefield.text = "GetDotaStats Lobby";
			globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.text = target_password;
			PrintTable(globals.Loader_lobby_settings.movieClip.LobbySettings);
			globals.Loader_lobby_settings.movieClip.onConfirmSetupClicked(new ButtonEvent(ButtonEvent.CLICK));
			socket.getDataAsync("d2mods/api/lobby_joined.php?uid="+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text+"&lid="+target_lobby, createdGame);
		}
		public function createdGame(statusCode:int, data:String) {
			trace("##CREATED_GAME "+data);
		}
		public function test2(event:MouseEvent) { //Join Game
			globals.Loader_play.movieClip.gameAPI.SetPracticeLobbyFilter(target_password); //Set password
			
			globals.Loader_top_bar.movieClip.gameAPI.DashboardSwitchToSection(2); //Set topbar to DASHBOARD_SECTION_PLAY
			globals.Loader_play.movieClip.setCurrentTab(3); //Set tab to Find Lobbies
			globals.Loader_play.movieClip.setCurrentFindLobbyTab(3); //Set tab to Private Games
			
			var injectTimer:Timer = new Timer(500, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, joinGame);
            injectTimer.start();
		}
		public function joinGame(e:TimerEvent) {
			//TODO: Check if subscribed and game exists before joining
			globals.Loader_play.movieClip.gameAPI.JoinPrivateLobby(0); //Join the first game
			socket.getDataAsync("d2mods/api/lobby_joined.php?uid="+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text+"&lid="+target_lobby, createdGame);
		}
		public function test3(event:MouseEvent) { //Dump Globals
			PrintTable(globals);
		}
		public function test4(event:MouseEvent) { //Hook clicks
			globals.Level0.addEventListener(MouseEvent.CLICK, onStageClicked);
		}
		
		public function test5(event:MouseEvent) { //Get Lobbies
			socket.getDataAsync("d2mods/api/lobby_list.php", getLobbyList);
		}
		public function getLobbyList(statusCode:int, data:String) {
			trace("###LOBBY LIST");
			var json = decode(data);
			trace(json);
			var i:int = 0;
			for (i=0; i < json.length; i++) {
				var lobby:Object = json[i];
				trace("Lobby for "+lobby.workshop_id+" detected, with "+lobby.lobby_current_players+"/"+lobby.lobby_max_players);
			}
		}
		public function test6(event:MouseEvent) { //Lobby Status
			trace("###STEAM_ID \""+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text+"\"");
			socket.getDataAsync("d2mods/api/lobby_user_status.php?uid="+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text, getLobbyStatus);
		}
		public function getLobbyStatus(statusCode:int, data:String) {
			trace("###LOBBY STATUS");
			var json:Object = decode(data);
			if (json.error) {
				trace("There was an error: "+json.error);
				return;
			}
			trace("We are in a lobby for "+json.workshop_id+" with to suit a lobby of "+json.lobby_max_players+ " players!");
			if (json.lobby_leader == Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text) {
				target_gamemode = json.workshop_id;
				target_password = json.lobby_pass;
				target_lobby = json.lobby_id;
				test1(new MouseEvent(MouseEvent.CLICK));
			} else {
				if (json.lobby_hosted == 1) {
					trace("JOINING LOBBY "+json.lobby_id);
					target_gamemode = json.workshop_id;
					target_password = json.lobby_pass;
					target_lobby = json.lobby_id;
					test2(new MouseEvent(MouseEvent.CLICK));
				} else {
					trace("Games not ready, why were we called?!");
				}
			}
			trace(data);
		}
		
		public function onStageClicked(event:MouseEvent) {
            // Grab the taget
            var target = event.target;
			
            trace(target.itemName);

            // Grab info
            var thisClass = flash.utils.getQualifiedClassName(target);

            // Print out some debug info
            trace('\n\nDUMP:');
            trace(target);
            trace('Class: '+thisClass);
			trace('Parent tree: {');
			trace("\t" + target.parent.parent.parent.parent.parent.name);
			trace("\t" + target.parent.parent.parent.parent.name);
			trace("\t" + target.parent.parent.parent.name);
			trace("\t" + target.parent.parent.name);
			trace("\t" + target.parent.name);
			trace("}");
            var indent = 0;

            trace('Methods:')
            // Print methods
            for each(var key1 in flash.utils.describeType(target)..method) {
                // Check if this is part of our class
                if(key1.@declaredBy == thisClass) {
                    // Yes, log it
                    trace(strRep("\t", indent+1)+key1.@name+"()");
                }
            }

            trace('Variables:');

            // Check for text
            if("text" in target) {
                trace(strRep("\t", indent+1)+"text: "+target.text);
            }

            // Print variables
            for each(var key1 in flash.utils.describeType(target)..variable) {
                var key = key1.@name;
                var v = target[key];

                // Check if we can print it in one line
                if(isPrintable(v)) {
                    trace(strRep("\t", indent+1)+key+": "+v);
                } else {
                    // Grab the class of it
                    var thisClass = flash.utils.getQualifiedClassName(target);

                    // Open bracket
                    trace(strRep("\t", indent+1)+key+" "+thisClass+": {");

                    // Recurse!
                    trace(strRep("\t", indent+2)+'<not dumped>');

                    // Close bracket
                    trace(strRep("\t", indent+1)+"}");
                }
            }
		}
		public function createTestButton(name:String, callback:Function) {
			var dotoButtonClass:Class = getDefinitionByName("d_RadioButton_2nd_side") as Class;
			var btn = new dotoButtonClass();
			addChild(btn);
			btn.x = 4;
			btn.y = 100 + 30*buttonCount;
			buttonCount = buttonCount + 1;
			btn.label = name;
			btn.addEventListener(MouseEvent.CLICK, callback);
		}
		
		public function onResize(re:ResizeManager) : * {
			trace("Injected by Ash47!\n\n\n");
			x = 0;
			y = 0;
			visible = true;

            trace(re.ScreenWidth);
            trace(re.ScreenHeight);

			this.scaleX = re.ScreenWidth/1080;
            this.scaleY = re.ScreenHeight/1920;
		}
		
				//Stolen from Frota
		        // JSON decoder
        public static function decode( s:String, strict:Boolean = true ):* {
            return new JSONDecoder( s, strict ).getValue();
        }

        // JSON encoder
        public static function encode( o:Object ):String {
            return new JSONEncoder( o ).getString();
        }
				
				
		public function strRep(str, count) {
            var output = "";
            for(var i=0; i<count; i++) {
                output = output + str;
            }

            return output;
        }

        public function isPrintable(t) {
        	if(t == null || t is Number || t is String || t is Boolean || t is Function || t is Array) {
        		return true;
        	}
        	// Check for vectors
        	if(flash.utils.getQualifiedClassName(t).indexOf('__AS3__.vec::Vector') == 0) return true;

        	return false;
        }

        public function PrintTable(t, indent=0, done=null) {
        	var i:int, key, key1, v:*;

        	// Validate input
        	if(isPrintable(t)) {
        		trace("PrintTable called with incorrect arguments!");
        		return;
        	}

        	if(indent == 0) {
        		trace(t.name+" "+t+": {")
        	}

        	// Stop loops
        	done ||= new flash.utils.Dictionary(true);
        	if(done[t]) {
        		trace(strRep("\t", indent)+"<loop object> "+t);
        		return;
        	}
        	done[t] = true;

        	// Grab this class
        	var thisClass = flash.utils.getQualifiedClassName(t);

        	// Print methods
			for each(key1 in flash.utils.describeType(t)..method) {
				// Check if this is part of our class
				if(key1.@declaredBy == thisClass) {
					// Yes, log it
					trace(strRep("\t", indent+1)+key1.@name+"()");
				}
			}

			// Check for text
			if("text" in t) {
				trace(strRep("\t", indent+1)+"text: "+t.text);
			}
			if("label" in t) {
				trace(strRep("\t", indent+1)+"label: "+t.label);
			}

			// Print variables
			for each(key1 in flash.utils.describeType(t)..variable) {
				key = key1.@name;
				v = t[key];

				// Check if we can print it in one line
				if(isPrintable(v)) {
					trace(strRep("\t", indent+1)+key+": "+v);
				} else {
					// Open bracket
					trace(strRep("\t", indent+1)+key+": {");

					// Recurse!
					PrintTable(v, indent+1, done)

					// Close bracket
					trace(strRep("\t", indent+1)+"}");
				}
			}

			// Find other keys
			for(key in t) {
				v = t[key];

				// Check if we can print it in one line
				if(isPrintable(v)) {
					trace(strRep("\t", indent+1)+key+": "+v);
				} else {
					// Open bracket
					trace(strRep("\t", indent+1)+key+": {");

					// Recurse!
					PrintTable(v, indent+1, done)

					// Close bracket
					trace(strRep("\t", indent+1)+"}");
				}
        	}

        	// Get children
        	if(t is MovieClip) {
        		// Loop over children
	        	for(i = 0; i < t.numChildren; i++) {
	        		// Open bracket
					trace(strRep("\t", indent+1)+t.name+" "+t+": {");

					// Recurse!
	        		PrintTable(t.getChildAt(i), indent+1, done);

	        		// Close bracket
					trace(strRep("\t", indent+1)+"}");
	        	}
        	}

        	// Close bracket
        	if(indent == 0) {
        		trace("}");
        	}
        }
	}
	
}
