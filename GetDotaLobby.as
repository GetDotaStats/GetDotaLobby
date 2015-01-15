﻿package  {
	
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
	import scaleform.clik.controls.*;
	import flash.geom.Point;
	import scaleform.gfx.DisplayObjectEx;
	import scaleform.gfx.Extensions;
	import scaleform.gfx.MouseEventEx;
	import scaleform.gfx.InteractiveObjectEx;
	import fl.motion.Color;
	import flash.text.TextFormat;
	import scaleform.gfx.TextFieldEx;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldType;
	import scaleform.clik.data.DataProvider;
	
	import dota2Net.D2HTTPSocket;
	import com.adobe.serialization.json.*;
	import flashx.textLayout.formats.BackgroundColor;
	import flash.geom.ColorTransform;
	import scaleform.clik.events.ListEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.FocusEvent;
	import flash.ui.Keyboard;
	import fl.transitions.TweenEvent;
	import fl.transitions.Tween;
	import flash.net.URLVariables;
	import flash.net.URLLoaderDataFormat;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	
	public class GetDotaLobby extends MovieClip {
		// Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;
		
		private var version:String = "0.1";
		private var DEBUG:Boolean = false;
		private var versionChecked:Boolean = false;
		
		public var buttonCount:int = 1;
		public var correctedRatio:Number = 1;
		public var screenWidth:Number = 1600;
		public var screenHeight:Number = 900;
		
		public var hostGameClip:MovieClip;
		public var lobbyBrowserClip:MovieClip;
		public var lobbyNameField:TextField;
		public var mapNameField:TextField;
		public var lobbyMapNameField:TextField;
		public var lobbySearchField:TextField;
		
		public var originalXScale = -1;
		public var originalYScale = -1;
		
		public var lastReload:Date = null;
		public var lobbyData:Object = new Object();
		
		public var gmiToModID:Object;
		public var gmiToProvider:Object;
		public var gmiToLobbyProvider:Object;
		public var gmiToName:Object;
		
		public var retryCount:int = -1;
		public var currentUrl:String = "";
		public var lobbyState:Object;
		public var lobbyStateTimer:Timer;
		
		public var modsProvider:DataProvider = new DataProvider();
		public var lobbyModsProvider:DataProvider = new DataProvider();
		public var regionProvider:DataProvider = new DataProvider(
				[{"label": "US East", "data":1},
				 {"label": "US West", "data":2},
				 {"label": "EU West", "data":3},
				 {"label": "EU East", "data":4},
				 {"label": "Russia", "data":5},
				 {"label": "China", "data":6},
				 {"label": "Australia", "data":7},
				 {"label": "SE Asia", "data":8},
				 {"label": "Peru", "data":9},
				 {"label": "South America", "data":10},
				 {"label": "Middle East", "data":11},
				 {"label": "South Africa", "data":12}]);
				 
		public var lobbyRegionProvider:DataProvider = new DataProvider(
				[{"label": "<ANY REGION>", "data":-1},
				 {"label": "US East", "data":1},
				 {"label": "US West", "data":2},
				 {"label": "EU West", "data":3},
				 {"label": "EU East", "data":4},
				 {"label": "Russia", "data":5},
				 {"label": "China", "data":6},
				 {"label": "Australia", "data":7},
				 {"label": "SE Asia", "data":8},
				 {"label": "Peru", "data":9},
				 {"label": "South America", "data":10},
				 {"label": "Middle East", "data":11},
				 {"label": "South Africa", "data":12}]);
		
		//These are test values, when API is available, read from them
		//var target_gamemode:int = 322254016; //Shitwars
		var target_gamemode:int; //Warchasers
		var target_password:String;
		var target_lobby:int;
		
		var socket:D2HTTPSocket;
		
		var clickTarget:Object = null;
		var clickedOnce:Boolean = false;
		var dclickTimer:Timer = new Timer(150, 1);
		
		public function GetDotaLobby() {
			// constructor code
		}
		
		public function test7(){
			trace('7 called');
			//trace(globals.Loader_lobby_settings.movieClip.LobbySettings.CustomMapsDropDown.selectedIndex);
			//globals.Loader_lobby_settings.movieClip.LobbySettings.CustomMapsDropDown.setSelectedIndex(1);
			//trace(globals.Loader_lobby_settings.movieClip.LobbySettings.CustomMapsDropDown.selectedIndex);
			//trace(this.hostClip.gameModeClip.selectedIndex);
			//this.hostClip.gameModeClip.setSelectedIndex(1);
			//trace(this.hostClip.gameModeClip.selectedIndex);
			//invalidate();
			
			errorPanel("This is an error, I wonder how long it should be");
		}
		
		public function onLoaded() : void {
			trace("injected by SinZ!\n\n\n");
			socket = new D2HTTPSocket("getdotastats.com", "176.31.182.87");
			this.gameAPI.OnReady();
			
			if (DEBUG){
				createTestButton("Create Game", test1);
				createTestButton("Join Game", test2);
				createTestButton("Dump Globals", test3);
				createTestButton("hook clicks", test4);
				createTestButton("Get Lobbies", test5);
				createTestButton("Lobby Status", test6);
				createTestButton("CMDD", test7);
			}
			
			
			//  backdrop for host game panel
			var bgClass:Class = getDefinitionByName("DB_inset") as Class;
			var mc = new bgClass();
			
			// Play tab buttons
			var but:MovieClip = createTestButton("HOST CUSTOM LOBBY", hostGame);
			var but2:MovieClip = createTestButton("CUSTOM LOBBY BROWSER", lobbyBrowser);
			this.removeChild(but);
			this.removeChild(but2);
			
			var customButton:MovieClip = globals.Loader_play.movieClip.PlayWindow.PlayMain.Nav.tab12;
			
			but.x = customButton.x;
			but.y = customButton.y + 50;
			but2.x = customButton.x;
			but2.y = but.y + but.height + 2;
			globals.Loader_play.movieClip.PlayWindow.PlayMain.Nav.addChild(but);
			globals.Loader_play.movieClip.PlayWindow.PlayMain.Nav.addChild(but2);
			
			
			mc = new bgClass();
			hostGameClip = new MovieClip();
			hostGameClip.addChild(mc);
			//this.addChild(hostGameClip);
			globals.Loader_top_bar.movieClip.addChild(hostGameClip);
			
			hostGameClip.visible = false;
			hostGameClip.width = 1600 * .4;
			hostGameClip.height = 900 * .5;
			hostGameClip.x = 1600 * .3;
			hostGameClip.y = 900 * .25;
			hostGameClip.scaleX = 1;
			hostGameClip.scaleY = 1;		
			
			mc.width = 1600 * .4;
			mc.height = 900 * .5;
			
			// Move in stage panel to backdrop
			this.hostClip.x = 0;
			this.hostClip.y = 0;
			this.removeChild(this.hostClip);
			hostGameClip.addChild(this.hostClip);
			this.hostClip.closeButton.addEventListener(MouseEvent.CLICK, closeClicked, false, 0, true);
			
			// Version string
			this.hostClip.versionText.text = "Ver " + version;
			this.lobbyClip.versionText.text = "Ver " + version;
			
			// Create Lobby button
			this.hostClip.hostGameButton = replaceWithValveComponent(this.hostClip.hostGameButton, "button_big");
			this.hostClip.hostGameButton.x = 320 - this.hostClip.hostGameButton.width / 2;
			this.hostClip.hostGameButton.textField.text = "CREATE LOBBY";
			this.hostClip.hostGameButton.label = "CREATE LOBBY";
			this.hostClip.hostGameButton.addEventListener(MouseEvent.CLICK, createLobbyClick, false, 0 ,true);
			
			// Lobby name Input box
			this.lobbyNameField = createTextInput(this.hostClip.lobbyNameClip);
			this.hostClip.addChild(this.lobbyNameField);
			
			// Create gamemode dropdown
			this.hostClip.gameModeClip = replaceWithValveComponent(this.hostClip.gameModeClip, "ComboBoxSkinned", true);
			this.hostClip.gameModeClip.rowHeight = 24;
			this.hostClip.gameModeClip.visibleRows = 15;
			this.hostClip.gameModeClip.showScrollBar = true;
			this.hostClip.gameModeClip.setDataProvider(this.modsProvider);
			/*this.hostClip.gameModeClip.setDataProvider(new DataProvider(
				[{"label": "Reflex", "data":299093466},
				 {"label": "Warchasers", "data":300989405},
				 {"label": "Legends of Dota", "data":300989405},
				 {"label": "Clash of the Titans", "data":310942705}]));*/
			this.hostClip.gameModeClip.setSelectedIndex(0);
			this.hostClip.gameModeClip.menuList.addEventListener(ListEvent.INDEX_CHANGE, hostModeChange, false, 0, true);
			
			// Create Map Name input box
			//this.mapNameField = createTextInput(this.hostClip.mapNameClip, 14);
			//this.hostClip.addChild(this.mapNameField);
			this.hostClip.mapNameClip = replaceWithValveComponent(this.hostClip.mapNameClip, "ComboBoxSkinned", true);
			this.hostClip.mapNameClip.rowHeight = 24;
			
			// Create Region dropdown
			this.hostClip.regionClip = replaceWithValveComponent(this.hostClip.regionClip, "ComboBoxSkinned", true);
			this.hostClip.regionClip.rowHeight = 24;
			this.hostClip.regionClip.setDataProvider(this.regionProvider);
			this.hostClip.regionClip.setSelectedIndex(0);
			
			// Create Min dropdown
			this.hostClip.maxClip = replaceWithValveComponent(this.hostClip.maxClip, "ComboBoxSkinned", true);
			this.hostClip.maxClip.rowHeight = 24;
			this.hostClip.maxClip.visibleRows = 10;
			this.hostClip.maxClip.showScrollBar = true;
			this.hostClip.maxClip.setDataProvider(new DataProvider(
				[{"label": "2", "data":2},
				 {"label": "3", "data":3},
				 {"label": "4", "data":4},
				 {"label": "5", "data":5},
				 {"label": "6", "data":6},
				 {"label": "7", "data":7},
				 {"label": "8", "data":8},
				 {"label": "9", "data":9},
				 {"label": "10", "data":10},
				 {"label": "11", "data":11},
				 {"label": "12", "data":12},
				 {"label": "13", "data":13},
				 {"label": "14", "data":14},
				 {"label": "15", "data":15},
				 {"label": "16", "data":16},
				 {"label": "17", "data":17},
				 {"label": "18", "data":18},
				 {"label": "19", "data":19},
				 {"label": "20", "data":20}]));
			this.hostClip.maxClip.setSelectedIndex(8);
			
			
			
			
			
			// Create lobby browser backdrop
			var bgClass2 = getDefinitionByName("DB4_outerpanel") as Class;
			var mc2 = new bgClass2();
			lobbyBrowserClip = new MovieClip();
			lobbyBrowserClip.addChild(mc2);
			//this.addChild(lobbyBrowserClip);
			globals.Loader_top_bar.movieClip.addChild(lobbyBrowserClip);
			
			this.lobbyClip.x = 0;
			this.lobbyClip.y = 0;
			this.removeChild(this.lobbyClip);
			lobbyBrowserClip.addChild(this.lobbyClip);
			this.lobbyClip.closeButton.addEventListener(MouseEvent.CLICK, closeClicked, false, 0, true);
			
			lobbyBrowserClip.visible = false;
			lobbyBrowserClip.width = 1600 * .6;
			lobbyBrowserClip.height = 900 * .7;
			lobbyBrowserClip.x = 1600 * .2;
			lobbyBrowserClip.y = 900 * .15;
			lobbyBrowserClip.scaleX = 1;
			lobbyBrowserClip.scaleY = 1;
			
			mc2.width = 1600 * .6;
			mc2.height = 900 * .7;
			
			// Create Mode dropdown
			this.lobbyClip.gameModeClip = replaceWithValveComponent(this.lobbyClip.gameModeClip, "ComboBoxSkinned", true);
			this.lobbyClip.gameModeClip.rowHeight = 24;
			this.lobbyClip.gameModeClip.visibleRows = 15;
			this.lobbyClip.gameModeClip.showScrollBar = true;
			this.lobbyClip.gameModeClip.setDataProvider(this.modsProvider);
			this.lobbyClip.gameModeClip.setSelectedIndex(0);
			this.lobbyClip.gameModeClip.menuList.addEventListener(ListEvent.INDEX_CHANGE, lobbyModeChange, false, 0, true);
			
			// Lobby name Input box
			this.lobbySearchField = createTextInput(this.lobbyClip.searchClip, 14);
			this.lobbyClip.addChild(this.lobbySearchField);
			this.lobbySearchField.addEventListener(KeyboardEvent.KEY_DOWN, lobbySearchKeyDown, false, 0, true);
			this.lobbySearchField.addEventListener(FocusEvent.FOCUS_OUT, redrawLobbyList, false, 0, true);
			
			// Create Map Name input box
			//this.lobbyMapNameField = createTextInput(this.lobbyClip.mapNameClip, 14);
			//this.lobbyClip.addChild(this.lobbyMapNameField);
			this.lobbyClip.mapNameClip = replaceWithValveComponent(this.lobbyClip.mapNameClip, "ComboBoxSkinned", true);
			this.lobbyClip.mapNameClip.rowHeight = 24;
			this.lobbyClip.mapNameClip.setDataProvider(new DataProvider());
			this.lobbyClip.mapNameClip.setSelectedIndex(0);
			this.lobbyClip.mapNameClip.menuList.addEventListener(ListEvent.INDEX_CHANGE, redrawLobbyList, false, 0, true);
			
			// Create Region dropdown
			this.lobbyClip.regionClip = replaceWithValveComponent(this.lobbyClip.regionClip, "ComboBoxSkinned", true);
			this.lobbyClip.regionClip.rowHeight = 24;
			this.lobbyClip.regionClip.setDataProvider(this.lobbyRegionProvider);
			this.lobbyClip.regionClip.setSelectedIndex(0);
			this.lobbyClip.regionClip.menuList.addEventListener(ListEvent.INDEX_CHANGE, redrawLobbyList, false, 0, true);
			
			// Create Lobby scrolling lobby view
			this.lobbyClip.lobbies = replaceWithValveComponent(this.lobbyClip.lobbies, "ScrollViewTest", true, 0);
			var sbClass:Class = getDefinitionByName("ScrollBarDota") as Class;
			var sb:MovieClip = new sbClass();
			sb.enabled = true;
			sb.visible = true;
			
			this.lobbyClip.addChild(sb);

			this.lobbyClip.lobbies.scrollBar = sb;
			this.lobbyClip.lobbies.enabled = true;
			this.lobbyClip.lobbies.visible = true;
			this.lobbyClip.lobbies.content.removeChild(this.lobbyClip.lobbies.content.Offline);
			this.lobbyClip.lobbies.content.removeChild(this.lobbyClip.lobbies.content.Online);
			this.lobbyClip.lobbies.content.removeChild(this.lobbyClip.lobbies.content.PlayingDota);
			this.lobbyClip.lobbies.content.removeChild(this.lobbyClip.lobbies.content.Pending);
			
			var panelClass:Class = getDefinitionByName("DB_inset") as Class;
			var panel:MovieClip = new panelClass();
			panel.visible = true;
			panel.enabled = true;
			
			panel.x = this.lobbyClip.lobbies.content.x;
			panel.y = this.lobbyClip.lobbies.content.y;
			panel.width = 930;
			panel.height = 509;
			this.lobbyClip.lobbies.addChildAt(panel, 0);
			
			sb.x = this.lobbyClip.lobbies.width + this.lobbyClip.lobbies.x - sb.width;
			sb.y = this.lobbyClip.lobbies.y;
			sb.height = 509;
			
			this.lobbyClip.removeChild(this.lobbyClip.exLobby);
			//this.lobbyClip.exLobby.x = 10;
			//this.lobbyClip.exLobby.y = 15;
			//this.lobbyClip.lobbies.content.addChild(this.lobbyClip.exLobby);
			//this.lobbyClip.exLobby.visible = true;			
			
			this.lobbyClip.refreshClip = replaceWithValveComponent(this.lobbyClip.refreshClip, "ButtonRefresh2", true);
			this.lobbyClip.refreshClip.addEventListener(MouseEvent.CLICK, getLobbyList, false, 0, true);
			
			this.lobbyClip.lobbies.content.x = 5;
			this.lobbyClip.lobbies.contentMask.x = -10;
			this.lobbyClip.lobbies.contentMask.y = 15;
			this.lobbyClip.lobbies.contentMask.width = 915;
			this.lobbyClip.lobbies.contentMask.height = 494;
			
			getPopularMods();
			
			var waitTimer:Timer = new Timer(1500, 1);
			waitTimer.addEventListener(TimerEvent.TIMER, waitLoad, false, 0, true);
			waitTimer.start();
			
			var topBarFunc:Function = this.gameAPI.DashboardSwitchToSection;
			this.gameAPI.DashboardSwitchToSection = function(tab:int){
				this.gameAPI.DashboardSwitchToSection(this.DASHBOARD_SECTION_PLAY)
				if (tab != 2)
					closeClicked(null);
					
				topBarFunc(tab);
			}
			
			//Lets check if we launched dota for a real reason
			test6(new MouseEvent(MouseEvent.CLICK));
			
			Globals.instance.resizeManager.AddListener(this);
		}
		
		public function checkVersionCall(e:TimerEvent){
			socket.getDataAsync("d2mods/api/lobby_version.txt", checkVersion);
		}
		
		public function checkVersion(statusCode:int, data:String){
			trace("##checkVersion");
			trace(data);
			var ver = Number(data);
			var currentVersion = Number(version);
			
			if (ver > currentVersion){
				trace("not up to date");
				
				var tf:TextField = errorPanel("Lobby Explorer plugin is out of date.  Copy this link to your browser to update.");
				var link:String = "http://getdotastats.com/#d2mods__lobby_guide";
				trace(link);
				
				var mc:MovieClip = new MovieClip();
				mc.x = tf.x;
				mc.y = tf.y + tf.height + 15;
				mc.width = tf.width;
				mc.height = tf.height;
				mc.visible = true;
				tf.parent.addChild(mc);
				
				var field:TextField = createLinkPanel(mc, link);
				tf.parent.addChild(field);
			}
		}
		
		public function errorPanel(message:String, timeout:Number = 3000, color:uint = 0xFF0000, size:int = 30, align:String = TextFormatAlign.CENTER) : TextField{
			//  backdrop for host game panel
			var bgClass:Class = getDefinitionByName("DB_inset") as Class;
			
			var mc = new bgClass();
			//this.addChild(mc);
			mc.x = 300;
			mc.y = 100;
			mc.height = 160;
			mc.width = 600;
			
			
			//globals.Loader_top_bar.movieClip.addChild(mc);
			//this.addChild(mc);
			
			
			var tf:TextFormat = globals.Loader_chat.movieClip.chat_main.chat.ChatInputBox.textField.getTextFormat();
			var field:TextField = new TextField();
			
			field.height = this.screenHeight * .10;
			field.width = this.screenWidth * .4;
			field.y = this.screenHeight * .06;
			field.x = this.screenWidth * .3;
			
			//field.x = 0;
			//mc.width * .1;
			//field.height = mc.height * .8;
			//field.width = mc.width * .8;
			field.scaleX = correctedRatio;
			field.scaleY = correctedRatio;
			
			//field.y = mc.height * .1 + (field.height - field.textHeight) / 2
			

			tf.size = size;
			tf.color = color;
			tf.align = align;
			//tf.font = "$TextFont*"; // Dunno what do on this
			field.setTextFormat(tf);
			field.defaultTextFormat = tf;
			field.autoSize = "none";
			field.maxChars = 0;
			field.background = true;
			field.backgroundColor = 0x222222;
			field.border = true;
			field.borderColor = 0x000000;
			//field.type = TextFieldType.DYNAMIC;
			
			//mc.addChild(field);
			globals.Loader_top_bar.movieClip.addChild(field);
			field.visible = true;
			field.text = message;
			field.height = field.textHeight + 10 * correctedRatio;
			field.width = field.textWidth + 30 * correctedRatio;
			field.x = (screenWidth - field.width) / 2;
			
			//mc.visible = true;
			
			var tweenEnd:Function = function(e:TweenEvent){
				trace("tween finish");
				field.parent.removeChild(mc);
		 	};
			
			var tweenStart:Function = function(event:TimerEvent){
				trace("tween start");
				var tween:Tween = new Tween(field, "alpha", null, 1, 0, 1, true);
				tween.start();
				tween.addEventListener(TweenEvent.MOTION_FINISH, tweenEnd, false, 0, true);
			};
			
			var timer:Timer = new Timer(timeout, 1);
			timer.addEventListener(TimerEvent.TIMER, tweenStart, false, 0, true);
			timer.start();
			
			return field;
		}
		
		public function waitLoad(event:TimerEvent){
			/*var curY:int = 15;
			for (var i:int = 0; i<40; i++){
				var clip:LobbyEntry = new LobbyEntry();
				clip.lobbyName.text = "Lobby " + i;
				
				Globals.instance.LoadImageWithCallback("img://[M" 
					+ Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text
					+ "]",clip.hostIcon,true, null);
				
				clip.visible = true;
				clip.x = 10;
				clip.y = curY;
				clip.width = this.lobbyClip.exLobby.width;
				
				this.lobbyClip.lobbies.content.addChild(clip);
				
				curY += 2 + clip.height;
			}
			
			this.lobbyClip.lobbies.updateScrollBar();*/
		}
		
		public function lobbySearchKeyDown(event:KeyboardEvent){
			if (event.keyCode == Keyboard.ENTER)
				stage.focus = stage;
		}
		
		public function hostModeChange(event:ListEvent){
			trace("hostmodechange");
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			
			this.hostClip.mapNameClip.setDataProvider(this.gmiToProvider[gmi]);
			this.hostClip.mapNameClip.setSelectedIndex(0);
			// Lobbyclip too
		}
		
		public function lobbyModeChange(event:ListEvent){
			trace("lobbymodechange");
			var gmi:Number = this.lobbyClip.gameModeClip.menuList.dataProvider[this.lobbyClip.gameModeClip.selectedIndex].data;
			
			this.lobbyClip.mapNameClip.setDataProvider(this.gmiToLobbyProvider[gmi]);
			this.lobbyClip.mapNameClip.setSelectedIndex(0);
			
			redrawLobbyList();
		}
		
		public function closeClicked(event:MouseEvent){
			trace("Close Clicked");
			hostGameClip.visible = false;
			lobbyBrowserClip.visible = false;
		}
		
		public function hostGame(event:MouseEvent){
			trace("CLICKED host game");
			hostGameClip.visible = true;
			lobbyBrowserClip.visible = false;
			
			if (!versionChecked){
				versionChecked = true;
				checkVersionCall(null);
			}
		}
		
		public function lobbyBrowser(event:MouseEvent){
			trace("CLICKED");
			hostGameClip.visible = false;
			lobbyBrowserClip.visible = true;
			
			if (this.lobbyClip.refreshClip.enabled){
				getLobbyList();
				if (!versionChecked){
					versionChecked = true;
					var waitTimer2:Timer = new Timer(5000, 1);
					waitTimer2.addEventListener(TimerEvent.TIMER, checkVersionCall, false, 0, true);
					waitTimer2.start();
				}
			}
			else{
				if (!versionChecked){
					versionChecked = true;
					checkVersionCall(null);
				}
			}
		}
		
		public function createLobbyClick(event:MouseEvent){
			// Generate random 16 character password all upper case
			this.target_password = "";
			for (var i:int = 0; i<10; i++)
				this.target_password += String.fromCharCode(Math.floor(Math.random() * 26) + 65);
			
			test1(event);
			this.hostGameClip.visible = false;
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
		public function createGame(e:TimerEvent) {
			trace("##PAGE COUNT: "+ globals.Loader_custom_games.movieClip.CustomGames.ModeList.PageLabel.text);
			var nextPages:int = 1;
			var regex:RegExp = /(\d+).+(\d+)/ig;
			var pages:String = globals.Loader_custom_games.movieClip.CustomGames.ModeList.PageLabel.text;
			var groups:Array = regex.exec(pages);
			nextPages = int(groups[2]);
			trace(nextPages);
			
			//For testing, lets just do Legends of Dota
			//PrintTable(globals.Loader_custom_games.movieClip.CustomGames.ModeList);
			var i:int;
			var haventFoundGame:Boolean = true;
			// Pull the game mode from the combo box
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			
			for (i=0; i < 12; i++) {
				var obj = globals.Loader_custom_games.movieClip.CustomGames.ModeList.Rows["row"+i].FlyOutButton;
				
				if (obj.GameModeID == false) {
					trace("ROW "+i+" IS A LIE!!");
					continue;
				}
				
				if (obj.GameModeID == gmi) { //TODO: Get this from GDS_API Warchasers 310942705,  LOD 300989405, reflex 299093466
					haventFoundGame = false;
					//Lets test with WarChasers
					globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeFlyoutClicked(obj.row,obj.GameModeID);
					var injectTimer:Timer = new Timer(50, 1);
					injectTimer.addEventListener(TimerEvent.TIMER, createGame2);
					injectTimer.start();
				}
			}
			if (haventFoundGame) {
				trace("Geez, git good");
				if (int(groups[1]) == nextPages){
					trace('super done'); // no more pages
					var tf:TextField = errorPanel("Game Mode not found.  Copy this link to your browser to subscribe.");
					var link:String = "http://steamcommunity.com/sharedfiles/filedetails/?id=" + gmi;
					trace(link);
					
					var mc:MovieClip = new MovieClip();
					mc.x = tf.x;
					mc.y = tf.y + tf.height + 15;
					mc.width = tf.width;
					mc.height = tf.height;
					mc.visible = true;
					tf.parent.addChild(mc);
					
					var field:TextField = createLinkPanel(mc, link);
					tf.parent.addChild(field);
					
					return;
				}
				
				globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeListNextPageClicked();
				
				var nextPageTimer:Timer = new Timer(50, 1);
				nextPageTimer.addEventListener(TimerEvent.TIMER, createGame);
				nextPageTimer.start();
			}
		}
		
		public function createLinkPanel(mc:MovieClip, link:String):TextField{
			var field:TextField = createTextInput(mc, 28, 0xDDDDDD, TextFormatAlign.CENTER);
			field.text = link;
			field.setSelection(0, field.length);
			field.visible = true;
			stage.focus = field;
			
			field.maxChars = 0;
			field.type = TextFieldType.DYNAMIC;
			field.background = true;
			field.backgroundColor = 0x222222;
			field.border = true;
			field.selectable = true;
			field.borderColor = 0x000000;
			field.scaleX = correctedRatio;
			field.scaleY = correctedRatio;
			field.height = field.textHeight + 10 * correctedRatio;
			field.width = field.textWidth + 30 * correctedRatio;
			field.x = (screenWidth - field.width) / 2;
			
			var focusOut:Function = function(event:FocusEvent){
				field.parent.removeChild(field);
			};
			
			field.addEventListener(FocusEvent.FOCUS_OUT, focusOut, false, 0, true);
			return field;
		}
		
		public function createGame2(e:TimerEvent) {
			globals.Loader_dashboard_overlay.movieClip.onCustomGameCreateLobbyButtonClicked(new ButtonEvent(ButtonEvent.CLICK));
			var injectTimer:Timer = new Timer(300, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, createGame3);
            injectTimer.start();
		}
		public function createGame3(e:TimerEvent) {
			globals.Loader_popups.movieClip.onButton1Clicked(new ButtonEvent(ButtonEvent.CLICK));
			var injectTimer:Timer = new Timer(150, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, createGame4);
            injectTimer.start();
		}
		public function createGame4(e:TimerEvent) {
			globals.Loader_popups.movieClip.onButton1Clicked(new ButtonEvent(ButtonEvent.CLICK));
			var lobbyName:String = this.lobbyNameField.text;
			if (lobbyName == "")
				lobbyName = "Custom Lobby";
				
			lobbyName = lobbyName.substr(0, 50);
				
			globals.Loader_lobby_settings.movieClip.LobbySettings.gamenamefield.text = lobbyName;
			globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.text = this.target_password;
			var cmdd:MovieClip = globals.Loader_lobby_settings.movieClip.LobbySettings.CustomMapsDropDown;
			var map:String = this.hostClip.mapNameClip.menuList.dataProvider.requestItemAt(this.hostClip.mapNameClip.selectedIndex).label;
			var mapName:String = map;
			
			if (cmdd.menuList.dataProvider.length == 0){
				// override_vpk and missing addoninfo is on, let's fill the provider
				cmdd.setDataProvider(this.hostClip.mapNameClip.menuList.dataProvider);
				cmdd.setSelectedIndex(this.hostClip.mapNameClip.selectedIndex);
			}
			else{
				// Let the actual in game list be authoritative if present, and set the index if found
				for (var i:int = 0;i < cmdd.menuList.dataProvider.length; i++){
					var o:Object = cmdd.menuList.dataProvider.requestItemAt(i);
					if (map == o.label){
						trace("FOUND, setting index");
						cmdd.setSelectedIndex(i);
						break;
					}
				}
			}
			globals.Loader_lobby_settings.movieClip.CustomMapName = map; //This gets around override_vpk and scrub mod devs
			
			globals.Loader_lobby_settings.movieClip.onConfirmSetupClicked(new ButtonEvent(ButtonEvent.CLICK));
			
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			var modID:Number = gmiToModID[gmi];
			
			lobbyState = new Object();
			lobbyState.map = mapName;
			lobbyState.maxPlayers = this.hostClip.maxClip.menuList.dataProvider.requestItemAt(this.hostClip.maxClip.selectedIndex).label;
			lobbyState.region = this.hostClip.regionClip.menuList.dataProvider.requestItemAt(this.hostClip.regionClip.selectedIndex).data
			lobbyState.lobbyName = lobbyName;
			lobbyState.pass = this.target_password;
			lobbyState.hostName = Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.Player.PlayerNameIngame.text;
			
			currentUrl = "d2mods/api/lobby_created.php?uid="+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text
				+ "&mid=" + modID
				+ "&wid=" + gmi
				+ "&map=" + escape(mapName)
				+ "&p=" + this.target_password
				+ "&mp=" + lobbyState.maxPlayers
				+ "&r=" + lobbyState.region
				+ "&ln=" + escape(lobbyName)
				+ "&un=" + escape(lobbyState.hostName);
			
			registerLobby();
		}
		
		public function registerLobby(){
			socket.getDataAsync(currentUrl, createdGame);
		}
		
		public function createdGame(statusCode:int, data:String) {
			trace("##CREATED_GAME");
			trace("Status code: " + statusCode);
			//if (globals.Loader_popups.movieClip.visible)
//				globals.Loader_popups.movieClip.beginClose();
				
			if (statusCode != 200){
				// Rerun? show failure
				if (retryCount == -1)
					retryCount = 2;
					
				retryCount--;
				if (retryCount == -1){
					errorPanel("Unable to register lobby: " + statusCode + " -- Not registered.");
					return;
				}
				errorPanel("Unable to register lobby: " + statusCode + " -- Retrying...");
				
				var retry:Timer = new Timer(3000, 1);
				retry.addEventListener(TimerEvent.TIMER, registerLobby);
				retry.start();
				
				return;
			}
			
			var json = decode(data);
			trace(data);
			
			if (json.error != null){
				trace("error: " + json.error);
				errorPanel("Lobby registration failed: " + json.error);
				return;
			}
			
			lobbyState.token = json.token;
			lobbyState.lid = json.lobby_id;
			lobbyState.players = new Object();
			
			//socket.getDataAsync("d2mods/api/lobby_joined.php?uid="+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text+"&lid="+target_lobby, createdGame);
			
			// Handle lobby watching and lobby_updates
			/*var oldSetPlayer = globals.Loader_practicelobby.movieClip.setPlayer;
			globals.Loader_practicelobby.movieClip.setPlayer = function (param1:int, param2:String, param3:uint, param4:String, param5:Boolean, param6:Boolean){
				var acct:uint = param3;
				
				oldSetPlayer(param1, param2, param3, param4, param5, param6);
			};
			
			var oldSetBroadcaster = globals.Loader_practicelobby.movieClip.setBroadcaster;
			globals.Loader_practicelobby.movieClip.setBroadcaster = function (param1:int, param2:int, param3:String, param4:uint){
				var acct:uint = param4;
				
				oldSetBroadcaster(param1, param2, param3, param4);
			};
			
			var oldSetPlayerPool = globals.Loader_practicelobby.movieClip.setPlayerPool;
			globals.Loader_practicelobby.movieClip.setPlayerPool = function (param1:int, param2:String, param3:uint, param4:Boolean){
				var acct:uint = param3;
				
				oldSetPlayerPool(param1, param2, param3, param4);
			};*/
			
			var stateWatcher:Function = function(event:TimerEvent){
				trace("statewatcher");
				var state:Object = new Object();
				var i:int = 0;
				var practiceLobby = globals.Loader_practicelobby.movieClip.PracticeLobby;
				var account:uint = 0;
				
				for (i=0; i<12; i++){
					if (practiceLobby["PlayerPool" + i].visible && practiceLobby["PlayerPool" + i].accountID)
						state[practiceLobby["PlayerPool" + i].accountID] = practiceLobby["PlayerPool" + i].Player.PlayerNameIngame.text; //true;
				}				
				for (i=0; i<6; i++){
					for (var j:int = 0; j<4; j++){
						if (practiceLobby["Broadcaster" + i]["Player" + j].visible && practiceLobby["Broadcaster" + i]["Player" + j].accountID)
							state[practiceLobby["Broadcaster" + i]["Player" + j].accountID] = practiceLobby["Broadcaster" + i]["Player" + j].Player.PlayerNameIngame.text //true;
					}
				}
				for (i=0; i<10; i++){
					if (practiceLobby["Player" + i].visible && practiceLobby["Player" + i].accountID)
						state[practiceLobby["Player" + i].accountID] = practiceLobby["Player" + i].PlayerName.PlayerNameIngame.text; // true
				}
				
				var nextState:Object = new Object();
				var key:Object;
				
				//PrintTable(state);
				
				for (key in lobbyState.players){
					if (state[key] != null){
						// no change
						nextState[key] = state[key];
						delete state[key];
					}
					else{
						retryAsyncCall("d2mods/api/lobby_left.php?uid=" + key + "&lid=" + lobbyState.lid + "&un=" + lobbyState.players[key] + "&t=" + lobbyState.token, "Player left registration failure");
					}
				}
				
				//PrintTable(state);
				
				for (key in state){
					// new account
					nextState[key] = state[key];
					retryAsyncCall("d2mods/api/lobby_joined.php?uid=" + key + "&lid=" + lobbyState.lid + "&un=" + state[key] + "&t=" + lobbyState.token, "Player join registration failure");
				}
				
				//PrintTable(nextState);
				//trace("-----");
				
				lobbyState.players = nextState;
				
				// Check lobby settings
				var lname:String = globals.Loader_lobby_settings.movieClip.LobbySettings.gamenamefield.text;
				var lpass:String = globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.text;
				var lmap:String = globals.Loader_lobby_settings.movieClip.LobbySettings.CustomMapsDropDown.label;
				//trace("lname: " + lname);
				//trace("lpass: " + lpass);
				//trace("lmap: " + lmap);
				
				var dirty:Boolean = false;
				if (lobbyState.lobbyName != lname){
					dirty = true;
					lobbyState.lobbyName = lname;
				}
				if (lobbyState.map != lmap){
					dirty = true;
					lobbyState.map = lmap;
				}
				if (lobbyState.pass != lpass){
					dirty = true;
					lobbyState.pass = lpass;
				}
				
				if (dirty){
					retryAsyncCall("d2mods/api/lobby_update.php?lid=" + lobbyState.lid + "&map=" + lobbyState.map
								+ "&mp=" + lobbyState.maxPlayers + "&r=" + lobbyState.region
								+ "&ln=" + lobbyState.lobbyName + "&t=" + lobbyState.token, "Settings update registration failure");
				}
			};
			
			lobbyStateTimer = new Timer(3000);
			lobbyStateTimer.addEventListener(TimerEvent.TIMER, stateWatcher, false, 0, true);
			lobbyStateTimer.start();
			
			globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.visible = false;
			
			var oldLeaveButton = globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton;
			var oldStartButton = globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton;
			var oldButton1 = globals.Loader_popups.movieClip.gameAPI.Button1Clicked;
			var quitDesc:String = globals.GameInterface.Translate("#DOTA_ConfirmQuitDesc");
			
			globals.Loader_popups.movieClip.gameAPI.Button1Clicked = function (){
				trace("Button 1 pressed");
				trace(quitDesc);
				trace(globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.text);
				
				if (globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.text != quitDesc){
					oldButton1();
					return;
				}
				
				lobbyStateTimer.stop();
				trace("QUITING TIME")
				var doneRegistration:Function = function(){		
					oldButton1();
					globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton = oldLeaveButton;
					globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton = oldStartButton;
					globals.Loader_popups.movieClip.gameAPI.Button1Clicked = oldButton1;
					globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.visible = true;
				};
				
				retryAsyncCall("d2mods/api/lobby_close.php?lid=" + lobbyState.lid + "&t=" + lobbyState.token, "Exiting failure", 2, doneRegistration, doneRegistration);
			};
			
			globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton = function (){
				lobbyStateTimer.stop();
				retryAsyncCall("d2mods/api/lobby_close.php?lid=" + lobbyState.lid + "&t=" + lobbyState.token, "Lobby close failure");
				oldLeaveButton();
				globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton = oldLeaveButton;
				globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton = oldStartButton;
				globals.Loader_popups.movieClip.gameAPI.Button1Clicked = oldButton1;
				globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.visible = true;
			};
			
			globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton = function (){
				lobbyStateTimer.stop();
				var doneRegistration:Function = function(){
					oldStartButton();
					globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton = oldLeaveButton;
					globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton = oldStartButton;
					globals.Loader_popups.movieClip.gameAPI.Button1Clicked = oldButton1;
					globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.visible = true;
				};
				
				retryAsyncCall("d2mods/api/lobby_close.php?lid=" + lobbyState.lid + "&t=" + lobbyState.token, "Lobby close failure", 2, doneRegistration, doneRegistration);
			};
 		}
		
		public function retryAsyncCall(url:String, failureString:String, retries:int = 2, successCallback:Function = null, failureCallback:Function = null){
			trace(retries + " retryAsyncCall: " + url);
			var retryAsyncCallback:Function = function(statusCode:int, data:String){
				trace("###retryAsyncCallback");
				trace("Status code: " + statusCode);
				if (statusCode != 200){
					// Rerun? show failure
					errorPanel(failureString + ": " + statusCode + "-- Retrying...", 1000);
					
					var retryFunction:Function = function(event:TimerEvent){
						retryAsyncCall(url, failureString, retries);
					};
					
					retries--;
					if (retries == 0)
						errorPanel(failureString + ": " + statusCode + "-- FAILED", 1000);
						if (failureCallback != null)
							failureCallback(statusCode, data);
						return;
					
					var retryTimer:Timer = new Timer(1000, 1);
					retryTimer.addEventListener(TimerEvent.TIMER, retryFunction, false, 0, true);
					retryTimer.start();
					return;
				}
				
				var json = decode(data);
				trace(data);
				
				if (json.error != null){
					errorPanel(failureString + ": " + json.error);
					if (failureCallback != null)
						failureCallback(statusCode, data);
					return;
				}
				
				if (successCallback != null)
					successCallback(statusCode, data);
			};
			socket.getDataAsync(url, retryAsyncCallback);
		}
		
		public function test2(event:MouseEvent, pass:String = "asdf") { //Join Game
			trace(pass);
			globals.Loader_play.movieClip.gameAPI.SetPracticeLobbyFilter(pass); //Set password
			
			globals.Loader_top_bar.movieClip.gameAPI.DashboardSwitchToSection(2); //Set topbar to DASHBOARD_SECTION_PLAY
			globals.Loader_play.movieClip.setCurrentTab(3); //Set tab to Find Lobbies
			globals.Loader_play.movieClip.setCurrentFindLobbyTab(3); //Set tab to Private Games
			
			var injectTimer:Timer = new Timer(700, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, joinGame);
            injectTimer.start();
		}
		public function joinGame(e:TimerEvent) {
			if (!globals.Loader_play.movieClip.PlayWindow.PlayMain.FindLobby.PrivateContent.game0.visible){
				trace("NO GAME FOUND"); // Probably should pop that up
				errorPanel("No Lobby Found.  The game may have begun or been closed.");
				return;
			}
			
			globals.Loader_play.movieClip.gameAPI.JoinPrivateLobby(0); //Join the first game
			
			var injectTimer:Timer = new Timer(500, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, checkForMissingMode);
            injectTimer.start();
		}
		
		public function checkForMissingMode(e:TimerEvent){
			var requiredMode:String = globals.GameInterface.Translate("#lobby_game_mode_required_desc");
			requiredMode = requiredMode.substr(0, requiredMode.indexOf("\""));
			var rxGMI = /(\d+)/gi;
			
			var msg:String = globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.text;
			if (globals.Loader_popups.movieClip.visible && 
				globals.Loader_popups.movieClip.AnimatingPanel.visible &&
				globals.Loader_popups.movieClip.GlimmerAnim.visible &&
				globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.visible && msg.indexOf(requiredMode) >= 0){
				//globals.Loader_popups.movieClip.onOKClicked(new ButtonEvent(ButtonEvent.CLICK));
				var gmi:String = rxGMI.exec(msg)[1];
				
				var tf:TextField = errorPanel("Game Mode not found.  Copy this link to your browser to subscribe.");
				var link:String = "http://steamcommunity.com/sharedfiles/filedetails/?id=" + gmi;
				trace(link);
				
				var mc:MovieClip = new MovieClip();
				mc.x = tf.x;
				mc.y = this.screenHeight * .45;
				mc.width = tf.width;
				mc.height = tf.height;
				mc.visible = true;
				tf.parent.addChild(mc);
				
				var field:TextField = createLinkPanel(mc, link);
				tf.parent.addChild(field);
			}
		}
		
		public function test3(event:MouseEvent) { //Dump Globals
			PrintTable(globals);
		}
		public function test4(event:MouseEvent) { //Hook clicks
			globals.Level0.addEventListener(MouseEvent.CLICK, onStageClicked);
		}
		
		public function reenableRefresh(event:TimerEvent){
			trace("REENABLE");
			this.lobbyClip.refreshClip.enabled = true;
		}
		
		public function getLobbyList(){
			socket.getDataAsync("d2mods/api/lobby_list.php", getLobbyListCallback);
			
			this.lobbyClip.refreshClip.enabled = false;
			var refreshTimer:Timer = new Timer(5000, 1);
			refreshTimer.addEventListener(TimerEvent.TIMER, reenableRefresh, false, 0, true);
			refreshTimer.start();
			
			/*var s:String = '[{"lobby_id":80,"mod_id":13,"workshop_id":333644472,"lobby_current_players":1,"lobby_max_players":4,"lobby_leader":68903670,"lobby_active":0,"lobby_hosted":1,"lobby_pass":"SJJ73N2FL8","lobby_map":"bomberman2", "lobby_name":"Lobby 1", "lobby_leader_name":"BMD","lobby_region":2},' 
						 + '{"lobby_id":55,"mod_id":13,"workshop_id":333644472,"lobby_current_players":3,"lobby_max_players":6,"lobby_leader":68903670,"lobby_active":0,"lobby_hosted":1,"lobby_pass":"SJJ73N2FL9","lobby_map":"bomberman2", "lobby_name":"Lobby 2", "lobby_leader_name":"BMD","lobby_region":3},'
						 + '{"lobby_id":117,"mod_id":11,"workshop_id":310066170,"lobby_max_players":8,"lobby_leader":68903670,"lobby_hosted":1,"lobby_pass":"5YBKZGPX9H","lobby_map":"template_map","lobby_current_players":3,"lobby_name":"Lobby 4","lobby_leader_name":"BMD","lobby_region":4},'
						 + '{"lobby_id":118,"mod_id":11,"workshop_id":310066170,"lobby_max_players":8,"lobby_leader":68903670,"lobby_hosted":1,"lobby_pass":"5YBKZGPX9G","lobby_map":"template_map","lobby_current_players":3,"lobby_name":"Lobby 6","lobby_leader_name":"BMD","lobby_region":4},'
						 + '{"lobby_id":131,"mod_id":7,"workshop_id":299093466,"lobby_name":"Custom Lobby #131","lobby_max_players":6,"lobby_leader":68903670,"lobby_hosted":1,"lobby_pass":"UMBLRMRQ3C","lobby_map":"arena","lobby_current_players":1,"lobby_leader_name":"BMD","lobby_region":6},'
						 + '{"lobby_id":133,"mod_id":7,"workshop_id":299093466,"lobby_name":"Custom Lobby #132","lobby_max_players":8,"lobby_leader":68903670,"lobby_hosted":1,"lobby_pass":"UMBLRMRQ3E","lobby_map":"reflex","lobby_current_players":4,"lobby_leader_name":"BMD","lobby_region":0},'
						 + '{"lobby_id":137,"mod_id":7,"workshop_id":299093466,"lobby_name":"Custom Lobby #137","lobby_max_players":7,"lobby_leader":68903670,"lobby_hosted":1,"lobby_pass":"UMBLRMRQ3D","lobby_map":"glacier","lobby_current_players":3,"lobby_leader_name":"BMD","lobby_region":10},'
						 + '{"lobby_id":130,"mod_id":27,"workshop_id":305278898,"lobby_name":"Custom Lobby #130","lobby_max_players":3,"lobby_leader":28755155,"lobby_hosted":1,"lobby_pass":"HKH7J2Z6DR","lobby_map":"epic_boss_fight","lobby_current_players":0,"lobby_leader_name":"Jimmy@#%@#%","lobby_region":7},'
						 + '{"lobby_id":116,"mod_id":11,"workshop_id":310066170,"lobby_max_players":10,"lobby_leader":68903670,"lobby_hosted":1,"lobby_pass":"5YBKZGPX9D","lobby_map":"template_map","lobby_current_players":2,"lobby_name":"Lobby 5","lobby_leader_name":"BMD","lobby_region":1}]';
			getLobbyListCallback(200, s);*/
		}
		
		public function getLobbyListCallback(statusCode:int, data:String) {
			trace("###GetLobbyList");
			trace("Status code: " + statusCode);
			if (statusCode != 200){
				errorPanel("List Retrieval Failure: " + statusCode);
				// Rerun? show failure
				return;
			}
			var json = decode(data);
			
			var ld:Object = new Object();
			var refreshTime:Number = new Date().time + 5000;
			
			if (json.error == null){
				for (var i:int=0; i< json.length; i++){
					var lobby:Object = json[i];
					lobby.refreshTime = refreshTime;
					ld[lobby.lobby_id] = lobby;
				}
			}
			else{
				trace("NO ACTIVE LOBBIES");
				errorPanel(json.error);
			}
			
			this.lobbyData = ld;
			
			redrawLobbyList();
		}
		
		public function redrawLobbyList(){
			trace("##redrawLobby");
			
			var content:MovieClip = this.lobbyClip.lobbies.content;
			for (var i:int = content.numChildren-1; i>=0; i--){
				content.removeChildAt(i);
			}
			
			var searchFilter:String = this.lobbySearchField.text;
			var modeFilter:Number = this.lobbyClip.gameModeClip.menuList.dataProvider[this.lobbyClip.gameModeClip.selectedIndex].data
			var mapFilter:String = this.lobbyClip.mapNameClip.menuList.dataProvider[this.lobbyClip.mapNameClip.selectedIndex].data
			var regionFilter:Number = this.lobbyClip.regionClip.menuList.dataProvider[this.lobbyClip.regionClip.selectedIndex].data
			
			var curY:int = 15;
			for (var lobbyID:Object in lobbyData){
				var lobby:Object = lobbyData[lobbyID];
				if (lobby == null)
					continue;
				var clip:LobbyEntry = new LobbyEntry();
				//clip.doubleClickEnabled = true;
				//clip.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickLobby, false, 0, true);
				clip.addEventListener(MouseEvent.CLICK, clickLobby, false, 0, true);
				clip.lobbyID = int(lobbyID);
				clip.lobbyName.text = lobby.lobby_name;
				clip.host.text = lobby.lobby_leader_name;
				clip.mode.text = gmiToName[lobby.workshop_id];
				clip.map.text = lobby.lobby_map;
				if (lobby.lobby_region == 0)
					clip.region.text = "Global";
				else
					clip.region.text = this.lobbyClip.regionClip.menuList.dataProvider[lobby.lobby_region].label
				clip.players.text = lobby.lobby_current_players + " / " + lobby.lobby_max_players;
				if (lobby.lobby_current_players >= lobby.lobby_max_players)
					clip.players.textColor = 0xAA0000;
				if (lobby.lobby_current_players <= 1)
					clip.players.textColor = 0xAAAAAA;
				
				Globals.instance.LoadImageWithCallback("img://[M" 
					+ lobby.lobby_leader
					+ "]",clip.hostIcon,true, null);
					
				lobby.clip = clip;
				
				
				var searchTest:Boolean = (searchFilter == "" || lobby.lobby_name.indexOf(searchFilter) >= 0
										  || lobby.lobby_leader_name.indexOf(searchFilter) >= 0
										  || clip.mode.text.indexOf(searchFilter) >= 0
										  || clip.map.text.indexOf(searchFilter) >= 0
										  || clip.region.text.indexOf(searchFilter) >= 0);
				
				// Filter test
				clip.visible = (lobby.lobby_hosted == 1)
							&& searchTest
							&& (modeFilter == -1 || modeFilter == lobby.workshop_id)
							&& (mapFilter == "*" || mapFilter == lobby.lobby_map)
							&& (regionFilter == -1 || regionFilter == lobby.lobby_region);
				if (clip.visible){
					clip.visible = true;
					clip.x = 10;
					clip.y = curY;
					clip.width = this.lobbyClip.exLobby.width;
					
					this.lobbyClip.lobbies.content.addChild(clip);
					
					curY += 2 + clip.height;
				}
			}
			
			this.lobbyClip.lobbies.updateScrollBar();
		}
		
		public function refreshLobby(event:MouseEvent){
			var lid:int = event.currentTarget.lobbyID;
			var lobby:Object = lobbyData[lid];
			var now:Number = new Date().time;
			
			if (lobby.refreshTime && now < lobby.refreshTime){
				return;
			}
			
			socket.getDataAsync("d2mods/api/lobby_status.php?lid=" + lid, 
				function (statusCode:int, data:String){
					trace("###LobbyRefresh");
					trace("Status code: " + statusCode);
					if (statusCode != 200){
						// Rerun? show failure
						errorPanel("Lobby Refresh Failure: " + statusCode);
						return;
					}
					
					var json = decode(data);
					
					if (json.error != null){
						delete lobbyData[lid];
						redrawLobbyList();
						return;
					}
					
					var lobby:Object = lobbyData[json.lobby_id];
					if (lobby == null)
						return;
					
					json.lobby_current_players = json.lobby_players.length;
					json.refreshTime = new Date().time + 5000;
					lobbyData[json.lobby_id] = json;
					
					redrawLobbyList();
			});
		}
		
		public function clickLobby(event:MouseEvent){
			if (this.clickedOnce && this.clickTarget == event.currentTarget){
				doubleClickLobby(event);
				return;
			}
			
			dclickTimer.stop();
			dclickTimer = new Timer(250, 1);
			dclickTimer.addEventListener(TimerEvent.TIMER, doubleClickExpire);
			dclickTimer.start();
			
			refreshLobby(event);
			
			this.clickedOnce = true;
			this.clickTarget = event.currentTarget;
		}
		
		public function doubleClickExpire(event:TimerEvent){
			this.clickedOnce = false;
		}
		
		public function doubleClickLobby(event:MouseEvent){
			var lid:int = event.currentTarget.lobbyID;
			var lobby:Object = lobbyData[lid];
			
			if (lobby.lobby_current_players >= lobby.lobby_max_players)
				return;
			
			lobbyBrowserClip.visible = false;
			var me:MouseEvent = new MouseEvent(MouseEvent.CLICK);
			test2(me, lobby.lobby_pass);
		}
		
		public function getPopularMods(){
			//socket.getDataAsync("d2mods/api/popular_mods.php", getPopularModsCallback);
			socket.getDataAsync("d2mods/api/lobby_mod_list.php", getPopularModsCallback);
		}
		
		public function getPopularModsCallback(statusCode:int, data:String) {
			trace("###GetMods");
			trace("Status code: " + statusCode);
			if (statusCode != 200){
				// Rerun? show failure
				if (retryCount == -1)
					retryCount = 2;
					
				retryCount--;
				if (retryCount == -1){
					errorPanel("Unable Connect to GetDotaStats for Mod List: " + statusCode + " -- Custom Lobbies disabled.");
					return;
				}
				errorPanel("Unable Connect to GetDotaStats for Mod List: " + statusCode + " -- Retrying...");
				
				var retry:Timer = new Timer(3000, 1);
				retry.addEventListener(TimerEvent.TIMER, getPopularMods);
				retry.start();
				
				return;
			}
			var json = decode(data);
			//trace(data);
			
			this.modsProvider = new DataProvider();
			this.lobbyModsProvider = new DataProvider();
			this.lobbyModsProvider.push({label:"<ANY MODE>", data:-1});
			this.gmiToModID = new Object();
			this.gmiToProvider = new Object();
			this.gmiToLobbyProvider = new Object();
			this.gmiToLobbyProvider[-1] = new DataProvider();
			this.gmiToLobbyProvider[-1].push({label:"<ANY MAP>", data:"*"});
			this.gmiToName = new Object();
			
			for (var i:int=0; i< json.length;i++){
				var mod:Object = json[i];
				var gameModeId:Number = Number(mod.workshopID);
				var gdsModId:Number = Number(mod.modID);
				
				this.modsProvider.push({label:mod.modName, data:gameModeId});
				this.lobbyModsProvider.push({label:mod.modName, data:gameModeId});
				this.gmiToModID[gameModeId] = gdsModId;
				this.gmiToName[gameModeId] = mod.modName;
				
				
				this.gmiToProvider[gameModeId] = new DataProvider();
				this.gmiToLobbyProvider[gameModeId] = new DataProvider();
				this.gmiToLobbyProvider[gameModeId].push({label:"<ANY MAP>", data:"*"});
				
				//trace(mod.mod_maps);
				var split:Array = mod.mod_maps.split(/,/);
				for (var j:int = 0; j<split.length; j++){
					var rxQuote:RegExp = /"([^"]+)"/ig
					var map:String = rxQuote.exec(split[j])[1];
					this.gmiToProvider[gameModeId].push({label:map, data:map});
					this.gmiToLobbyProvider[gameModeId].push({label:map, data:map});
				}
			}
			
			this.hostClip.gameModeClip.setDataProvider(this.modsProvider);
			this.hostClip.gameModeClip.setSelectedIndex(0);
			this.lobbyClip.gameModeClip.setDataProvider(this.lobbyModsProvider);
			this.lobbyClip.gameModeClip.setSelectedIndex(0);
			
			hostModeChange(null);
			lobbyModeChange(null);
		}
		
		/*public function getPopularModsCallback(statusCode:int, data:String) {
			trace("###GetMods");
			var json = decode(data);
			//trace(data);
			
			var rxId:RegExp = /id=(\d+)/ig;
			this.modsProvider = new DataProvider();
			
			for (var i:int=0; i< json.length;i++){
				var mod:Object = json[i];
				//trace(mod.modName + " -- " + mod.workshopLink + " -- " + mod.modInfo);
				//trace(Number(rxId.exec(mod.workshopLink)[1]));
				var gameModeId:Number = Number(rxId.exec(mod.workshopLink)[1]);
				
				rxId = /id=(\d+)/ig;
				//trace(rxId.exec(mod.modInfo)[1]);
				var gdsModId:Number = Number(rxId.exec(mod.modInfo)[1]);
				//trace(gameModeId + " -- " + gdsModId);
				//trace('----');
				
				this.modsProvider.push({label:mod.modName, data:gameModeId});
			}
			
			this.hostClip.gameModeClip.setDataProvider(this.modsProvider);
			this.hostClip.gameModeClip.setSelectedIndex(0);
			this.lobbyClip.gameModeClip.setDataProvider(this.modsProvider);
			this.lobbyClip.gameModeClip.setSelectedIndex(0);
		}*/
		
		public function test5(event:MouseEvent) { //Get Lobbies
			//socket.getDataAsync("d2mods/api/lobby_list.php", getLobbyList);
			
			getLobbyList();
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
					target_lobby = json.lobby_id;
					test2(new MouseEvent(MouseEvent.CLICK), json.lobby_pass);
				} else {
					trace("Games not ready, why were we called?!");
				}
			}
			trace(data);
		}
		
		// JSON decoder
        public static function decode( s:String, strict:Boolean = true ):* {
            return new JSONDecoder( s, strict ).getValue();
        }

        // JSON encoder
        public static function encode( o:Object ):String {
            return new JSONEncoder( o ).getString();
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
			try{trace("\t" + target.parent.parent.parent.parent.parent.parent.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.parent.parent.parent.parent.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.parent.parent.parent.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.parent.parent.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.parent.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.parent.name);}catch(e){}
			try{trace("\t" + target.parent.name);}catch(e){}
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
            for each(var key2 in flash.utils.describeType(target)..variable) {
                var key = key2.@name;
                var v = target[key];

                // Check if we can print it in one line
                if(isPrintable(v)) {
                    trace(strRep("\t", indent+1)+key+": "+v);
                } else {
                    // Grab the class of it
                    var thisClass2 = flash.utils.getQualifiedClassName(target);

                    // Open bracket
                    trace(strRep("\t", indent+1)+key+" "+thisClass2+": {");

                    // Recurse!
                    trace(strRep("\t", indent+2)+'<not dumped>');

                    // Close bracket
                    trace(strRep("\t", indent+1)+"}");
                }
            }
			
			trace('Dump:');
			PrintTable(target);
		}
		public function createTestButton(name:String, callback:Function) : MovieClip {
			var dotoButtonClass:Class = getDefinitionByName("d_RadioButton_2nd_side") as Class;
			var btn = new dotoButtonClass();
			addChild(btn);
			btn.x = 4;
			btn.y = 100 + 30*buttonCount;
			buttonCount = buttonCount + 1;
			btn.label = name;
			btn.addEventListener(MouseEvent.CLICK, callback);
			
			return btn;
		}
		
		public function createTextInput(replacement:MovieClip, size:uint = 18, color:uint = 0xBBBBBB, align:String = TextFormatAlign.LEFT) : TextField{
			var mc:MovieClip = replaceWithValveComponent(replacement, "DB_inset", true);
			var tf:TextFormat = globals.Loader_chat.movieClip.chat_main.chat.ChatInputBox.textField.getTextFormat();
			var field:TextField = new TextField();
			field.x = mc.x + 5;
			var offset:Number = (22 - size) / 2;
			if (offset < 0)
				offset = 0;
			field.y = mc.y + offset;
			field.height = mc.height;
			field.width = mc.width - 10;

			tf.size = size;
			tf.color = color;
			tf.align = align;
			//tf.font = "$TextFont*"; // Dunno what do on this
			field.setTextFormat(tf);
			field.defaultTextFormat = tf;
			field.autoSize = "none";
			field.maxChars = 0;
			field.type = TextFieldType.INPUT;
			
			//this.hostClip.addChild(field);
			field.visible = true;
			field.text = "";
			
			return field;
		}
		
		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false, addAt:int = -1) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			if (addAt == -1)
				parent.addChild(newObject);
			else
				parent.addChildAt(newObject, 0);
			
			return newObject;
		}
		
		public function onResize(re:ResizeManager) : * {
			trace("Injected by Ash47!\n\n\n");
			var rm = Globals.instance.resizeManager;
			var currentRatio:Number =  re.ScreenWidth / re.ScreenHeight;
			var divided:Number;
			visible = true;
			
			var originalHeight:Number = 900;
					
			if(currentRatio < 1.5)
			{
				// 4:3
				divided = currentRatio * 3 / 4.0;
			}
			else if(re.Is16by9()){
				// 16:9
				divided = currentRatio * 9 / 16.0;
			} else {
				// 16:10
				divided = currentRatio * 10 / 16.0;
			}
							
			correctedRatio =  re.ScreenHeight / originalHeight * divided;
			this.screenHeight = re.ScreenHeight;
			this.screenWidth = re.ScreenWidth;
			trace("ratio: " + correctedRatio);

			this.scaleX = correctedRatio;
            this.scaleY = correctedRatio;
			
			hostGameClip.scaleX = correctedRatio;
			hostGameClip.scaleY = correctedRatio;
			hostGameClip.x = (re.ScreenWidth / 2 - hostGameClip.width / 2);//re.ScreenWidth * .3;
			hostGameClip.y = (re.ScreenHeight / 2 - hostGameClip.height / 2);//re.ScreenHeight * .25;
			
			lobbyBrowserClip.scaleX = correctedRatio;
			lobbyBrowserClip.scaleY = correctedRatio;
			lobbyBrowserClip.x = (re.ScreenWidth / 2 - lobbyBrowserClip.width / 2);//re.ScreenWidth * .3;
			var offset:int = (this.lobbyClip.lobbies.content.height - 509) * correctedRatio;
			if (offset < 0)
				offset = 0;
			lobbyBrowserClip.y = (re.ScreenHeight - lobbyBrowserClip.height + offset) / 2;//re.ScreenHeight * .25;
		
		}
		
				//Stolen from Frota
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
