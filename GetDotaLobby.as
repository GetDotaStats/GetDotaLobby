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
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	import flash.globalization.DateTimeStyle;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;
	import flash.display.Loader;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.display.DisplayObject;
	
	public class GetDotaLobby extends MovieClip {
		// Game API related stuff
        public var gameAPI:Object;
        public var globals:Object;
        public var elementName:String;
		
		private var version:String = "0.17";
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
		
		public var scalingTopBarPanel:MovieClip;
		public var joinPanelBg:MovieClip;
		public var optionsPanelBg:MovieClip;
		
		public var originalXScale = -1;
		public var originalYScale = -1;
		
		public var lastReload:Date = null;
		public var lobbyData:Object = new Object();
		public var currentOptions:Array;
		
		public var gmiToModID:Object;
		public var gmiToProvider:Object;
		public var gmiToLobbyProvider:Object;
		public var gmiToName:Object;
		public var gmiToOptions:Object;
		
		public var retryCount:int = -1;
		public var currentUrl:String = "";
		public var lobbyState:Object;
		public var lobbyStateTimer:Timer;
		
		public var fields:Vector.<Object> = new Vector.<Object>();
		
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
		
		public function traceLB(obj:Object){
			trace(obj);
			var now:Date = new Date();
			var ds:String = String(now.hours);
			if (now.hours < 10)
				ds = "0" + ds;
			ds += ":";
			if (now.minutes < 10)
				ds += "0";
			ds += now.minutes + ":";
				
			if (now.seconds < 10)
				ds += "0";
			ds += now.seconds + ".";
				
			if (now.milliseconds < 10)
				ds += "00";
			else if (now.milliseconds < 100)
				ds += "0";
			ds += now.milliseconds;
			
			
			logPanel.logText.text += "[" + ds + "] " + obj.toString() + "\n";
			logPanel.logText.textField.scrollV = logPanel.logText.textField.maxScrollV;
		}
		
		public function test8(){
			traceLB('8 called');
			
			PrintTable(globals.Loader_chat.movieClip);
			globals.Loader_chat.movieClip.gameAPI.ChatLinkClicked("http://steamcommunity.com/sharedfiles/filedetails/?id=299093466");
		}
		
		public function test7(){
			traceLB('7 called');
			
			var loader:Loader = new Loader();
			//loader.addEventListener(Event.COMPLETE, loadComplete, false, 0, true);
			//loader.addEventListener(Event.INIT, loadInit, false, 0, true);
			//loader.load(new URLRequest("play-helicopter-game.swf"));
			//loader.load(new URLRequest("12d2475d.swf"));
			loader.load(new URLRequest("FastestInvoker.swf"));
			trace("LOADER");
			
			var waitToLoadTimer:Timer = new Timer(500,0);
			var loadComplete:Function = function(e:Event){
				trace("LOAD COMPLETE");
				//PrintTable(loader);
				trace("adding child");
				
				var mc:MovieClip = new MovieClip();
				mc.x = 500;
				mc.y = 400;
				
				var panelClass:Class = getDefinitionByName("DB_inset") as Class;
				var panel:MovieClip = new panelClass();
				panel.visible = true;
				panel.enabled = true;
				panel.y = -5;
				//panel.x = 500;
				//panel.y = 400;
				panel.width = loader.width + 15;
				panel.height = loader.height + 15;
				
				var indentClass:Class = getDefinitionByName("indent_hilite") as Class;
				var indent:MovieClip = new indentClass();
				indent.y = -35;
				indent.height = 30;
				//indent.alpha += 15;
				indent.width = loader.width + 14;
				
				var outerClass:Class = getDefinitionByName("DB4_outerpanel") as Class;
				var outer:MovieClip = new outerClass();
				outer.y = -30;
				outer.height = 35+loader.height;
				outer.width = loader.width + 18;
				
				var title:TextField = createTextField(22, 0xFFFFFF, TextFormatAlign.CENTER);
				title.y = -32;
				title.width = loader.width + 18;
				//title.height = 26;
				
				var close:CloseButton = new CloseButton();
				close.width = 16;
				close.height = 16;
				close.y = -25;
				close.x = loader.width + 12;
				
				mc.addChild(outer);
				mc.addChild(title);
				mc.addChild(panel);
				mc.addChild(loader);
				mc.addChild(indent);
				mc.addChild(close);
				
				var dragging:Boolean = false;
				
				var handleDown:Function = function(event:MouseEvent){
					if (event.target == outer || event.target == indent || event.target == title){
						dragging = true;
						mc.startDrag();
					}
				};
				
				var handleUp:Function = function(event:MouseEvent){
					if (dragging)
						mc.stopDrag();
				}; 
				
				mc.addEventListener(MouseEvent.MOUSE_DOWN, handleDown);
				mc.addEventListener(MouseEvent.MOUSE_UP, handleUp);
				
				globals.Loader_top_bar.movieClip.addChild(mc);
				trace("making mcl");
				var mcl:Minigame = loader.content as Minigame;
				trace("MCL");
				PrintTable(mcl);
				trace("MCLLL");
				//mcl.radiantVictory.visible = true;
				//mcl.direVictory.visible = true;
				
				var gameCloseClicked:Function = function(e:MouseEvent){
					if (mcl.close())
						mc.visible = false;
				};
				
				close.addEventListener(MouseEvent.CLICK, gameCloseClicked);
				
				title.text = mcl.title;
				mcl.initialize(globals, gameAPI);
			};
			
			var loadInit:Function = function(e:Event){
				trace("LOAD INIT");
			};
			
			var waitToLoad:Function = function(e:TimerEvent){
				trace("WAIT TO LOAD");
				if (loader.content != null){
					waitToLoadTimer.stop();
					loadInit(e);
					loadComplete(e);
				}
			};
			
			waitToLoadTimer.addEventListener(TimerEvent.TIMER, waitToLoad);//, false, 0, true);
			waitToLoadTimer.start();
			trace("wait load started");
		}
		
		public function onLoaded() : void {
			//traceLB("injected by SinZ!\n\n\n");
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
				createTestButton("Test 8", test8);
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
			
			// Scaling top bar container panel
			scalingTopBarPanel = new MovieClip();
			globals.Loader_top_bar.movieClip.addChild(scalingTopBarPanel);
			scalingTopBarPanel.x = 0;
			scalingTopBarPanel.y = 0;
			scalingTopBarPanel.width = 1600;
			scalingTopBarPanel.height = 900;
			scalingTopBarPanel.scaleX = 1;
			scalingTopBarPanel.scaleY = 1;
			scalingTopBarPanel.visible = true;
			
			// Place help panel
			joinPanelBg = new bgClass();
			joinPanelBg.width = joinPanel.width;
			joinPanelBg.height = joinPanel.height;
			globals.Loader_play_matchmaking_status.movieClip.play_matchmaking_status.addChild(joinPanelBg);
			joinPanelBg.x = joinPanel.width / 2 - 15;
			joinPanelBg.visible = false;
			
			this.removeChild(joinPanel);
			joinPanel.x = joinPanel.width / 2 - 15;
			joinPanel.y = 0;
			joinPanel.visible = false;
			globals.Loader_play_matchmaking_status.movieClip.play_matchmaking_status.addChild(joinPanel);
			
			
			// Log panel background
			mc = new bgClass();
			logPanel.addChildAt(mc, 0);
			mc.visible = true;
			mc.width = logPanel.width;
			mc.height = logPanel.height;
			
			// Log button
			this.removeChild(logButton);
			scalingTopBarPanel.addChild(logButton);
			logButton.x = 75;
			logButton.y = 2;
			logButton.gotoAndStop(1);
			var logRollOver:Function = function(e:MouseEvent){logButton.gotoAndStop(2);};
			var logRollOut:Function = function(e:MouseEvent){logButton.gotoAndStop(1);};
			logButton.addEventListener(MouseEvent.CLICK, showLogPanel, false, 0, true);
			logButton.addEventListener(MouseEvent.ROLL_OVER, logRollOver, false, 0, true);
			logButton.addEventListener(MouseEvent.ROLL_OUT, logRollOut, false, 0, true);
			
			// Log panel
			this.removeChild(logPanel);
			scalingTopBarPanel.addChild(logPanel);
			logPanel.x = 800 - logPanel.width / 2;
			logPanel.y = 450 - logPanel.height / 2;
			logPanel.visible = false;
			logPanel.closeButton.addEventListener(MouseEvent.CLICK, closeClicked, false, 0, true);
			
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
			//this.lobbyClip.refreshClip.scaleX = 1.0;
			//this.lobbyClip.refreshClip.scaleY = 1.0;
			this.lobbyClip.refreshClip.addEventListener(MouseEvent.CLICK, getLobbyList, false, 0, true);
			
			this.lobbyClip.lobbies.content.x = 5;
			this.lobbyClip.lobbies.contentMask.x = -10;
			this.lobbyClip.lobbies.contentMask.y = 15;
			this.lobbyClip.lobbies.contentMask.width = 915;
			this.lobbyClip.lobbies.contentMask.height = 494;
			
			// Options panel	
			mc2 = new bgClass2();
			optionsPanelBg = new MovieClip();
			optionsPanelBg.addChild(mc2);
			//this.addChild(lobbyBrowserClip);
			globals.Loader_top_bar.movieClip.addChild(optionsPanelBg);
			
			this.optionsPanel.x = 0;
			this.optionsPanel.y = 0;
			this.removeChild(this.optionsPanel);
			optionsPanelBg.addChild(this.optionsPanel);
			this.optionsPanel.closeButton.addEventListener(MouseEvent.CLICK, closeClicked, false, 0, true);
			
			optionsPanelBg.visible = false;
			optionsPanelBg.width = this.optionsPanel.width;
			optionsPanelBg.height = this.optionsPanel.height;
			optionsPanelBg.scaleX = 1;
			optionsPanelBg.scaleY = 1;
			
			mc2.width = this.optionsPanel.width;
			mc2.height = this.optionsPanel.height;
			
			this.optionsPanel.options = replaceWithValveComponent(this.optionsPanel.options, "ScrollViewTest", true, 0);
			sb = new sbClass();
			sb.enabled = true;
			sb.visible = true;
			
			this.optionsPanel.addChild(sb);

			this.optionsPanel.options.scrollBar = sb;
			this.optionsPanel.options.enabled = true;
			this.optionsPanel.options.visible = true;
			
			panel = new panelClass();
			panel.visible = true;
			panel.enabled = true;
			
			panel.x = this.optionsPanel.options.content.x;
			panel.y = this.optionsPanel.options.content.y;
			panel.width = 505;
			panel.height = 333;
			this.optionsPanel.options.addChildAt(panel, 0);
			this.optionsPanel.options.content.removeChild(this.optionsPanel.options.content.Offline);
			this.optionsPanel.options.content.removeChild(this.optionsPanel.options.content.Online);
			this.optionsPanel.options.content.removeChild(this.optionsPanel.options.content.PlayingDota);
			this.optionsPanel.options.content.removeChild(this.optionsPanel.options.content.Pending);
			
			sb.x = this.optionsPanel.options.width + this.optionsPanel.options.x - sb.width;
			sb.y = this.optionsPanel.options.y;
			sb.height = 333;
			
			this.optionsPanel.options.content.x = 5;
			this.optionsPanel.options.contentMask.x = -10;
			this.optionsPanel.options.contentMask.y = 15;
			this.optionsPanel.options.contentMask.width = 505;
			this.optionsPanel.options.contentMask.height = 305;
			
			// Create Lobby button
			this.optionsPanel.hostGameButton = replaceWithValveComponent(this.optionsPanel.hostGameButton, "button_big");
			this.optionsPanel.hostGameButton.x = 252 - this.optionsPanel.hostGameButton.width / 2;
			this.optionsPanel.hostGameButton.textField.text = "CREATE LOBBY";
			this.optionsPanel.hostGameButton.label = "CREATE LOBBY";
			this.optionsPanel.hostGameButton.addEventListener(MouseEvent.CLICK, test1, false, 0 ,true);
			
			
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
			
			var oldLeaveButton:Function = globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton;
			globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton = function(){
				joinPanel.visible = false;
				joinPanelBg.visible = false;
				oldLeaveButton();
			};
			
			var cleanUp:Function = function(e:TimerEvent){
				for (var index:int=0; index < fields.length; index++){
					var field = fields[index];
					//PrintTable(field);
					var dt:uint = new Date().time;
					//trace(dt);
					
					if (field.field == null || field.field.parent == null){
						delete fields[index];
					}
					else if (dt > field.timeout){
						field.field.parent.removeChild(field.field);
						delete fields[index];
					}
				}
			};
			
			var cleanUpTimer:Timer = new Timer(2000,0);
			cleanUpTimer.addEventListener(TimerEvent.TIMER, cleanUp);
			cleanUpTimer.start();
			
			//Lets check if we launched dota for a real reason
			test6(new MouseEvent(MouseEvent.CLICK));
			
			Globals.instance.resizeManager.AddListener(this);
		}
		
		public function checkVersionCall(e:TimerEvent){
			socket.getDataAsync("d2mods/api/lobby_version.txt", checkVersion, D2HTTPSocket.totalZeroComplete);
		}
		
		public function checkVersion(statusCode:int, data:String){
			traceLB("##checkVersion");
			traceLB("Client Version: " + version + "  --  Newest Version: " + data);
			var ver = Number(data);
			var currentVersion = Number(version);
			
			if (ver > currentVersion){
				traceLB("not up to date");
				
				var tf:TextField = errorPanel("Lobby Explorer plugin is out of date.  Copy this link to your browser to update.");
				var link:String = "https://github.com/GetDotaStats/GetDotaLobby/raw/lobbybrowser/play_weekend_tourney.zip";
				traceLB(link);
				
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
			
			traceLB("ErrorPanel generated: " + message);
			
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
				field.parent.removeChild(mc);
		 	};
			
			var tweenStart:Function = function(event:TimerEvent){
				var tween:Tween = new Tween(field, "alpha", null, 1, 0, 1, true);
				tween.start();
				tween.addEventListener(TweenEvent.MOTION_FINISH, tweenEnd, false, 0, true);
			};
			
			var timer:Timer = new Timer(timeout, 1);
			timer.addEventListener(TimerEvent.TIMER, tweenStart, false, 0, true);
			timer.start();

			var ti:uint = (new Date().time) + timeout;
			fields.push({timeout:ti, field:field});
			
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
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			
			this.hostClip.mapNameClip.setDataProvider(this.gmiToProvider[gmi]);
			this.hostClip.mapNameClip.setSelectedIndex(0);
			// Lobbyclip too
		}
		
		public function lobbyModeChange(event:ListEvent){
			var gmi:Number = this.lobbyClip.gameModeClip.menuList.dataProvider[this.lobbyClip.gameModeClip.selectedIndex].data;
			
			this.lobbyClip.mapNameClip.setDataProvider(this.gmiToLobbyProvider[gmi]);
			this.lobbyClip.mapNameClip.setSelectedIndex(0);
			
			redrawLobbyList();
		}
		
		public function closeClicked(event:MouseEvent){
			hostGameClip.visible = false;
			lobbyBrowserClip.visible = false;
			logPanel.visible =false;
			optionsPanelBg.visible = false;
			currentOptions = new Array();
		}
		
		public function hostGame(event:MouseEvent){
			hostGameClip.visible = true;
			lobbyBrowserClip.visible = false;
			logPanel.visible = false;
			optionsPanelBg.visible = false;
			currentOptions = new Array();
			
			if (!versionChecked){
				versionChecked = true;
				checkVersionCall(null);
			}
		}
		
		public function lobbyBrowser(event:MouseEvent){
			hostGameClip.visible = false;
			lobbyBrowserClip.visible = true;
			logPanel.visible = false;
			optionsPanelBg.visible = false;
			currentOptions = new Array();
			
			if (this.lobbyClip.refreshClip.enabled){
				getLobbyList();
			}
			else{
				if (!versionChecked){
					versionChecked = true;
					checkVersionCall(null);
				}
			}
		}
		
		public function showLogPanel(event:MouseEvent){
			hostGameClip.visible = false;
			lobbyBrowserClip.visible = false;
			logPanel.visible = !logPanel.visible;
			optionsPanelBg.visible = false;
			currentOptions = new Array();
		}
		
		public function createLobbyClick(event:MouseEvent){
			// Generate random 16 character password all upper case
			this.target_password = "";
			for (var i:int = 0; i<10; i++)
				this.target_password += String.fromCharCode(Math.floor(Math.random() * 26) + 65);
			
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			this.hostGameClip.visible = false;
			
			if (gmiToOptions[gmi] == null)
				test1(event);
			else{
				this.optionsPanelBg.visible = true;
				redrawOptions();
			}
		}
		
		public function test1(event:MouseEvent) { //Create Game
			this.hostGameClip.visible = false;
			this.optionsPanelBg.visible = false;
			globals.Loader_top_bar.movieClip.gameAPI.DashboardSwitchToSection(2); //Set topbar to DASHBOARD_SECTION_PLAY
			globals.Loader_play.movieClip.setCurrentTab(12); //Set tab to CustomGames
			
			globals.Loader_custom_games.movieClip.setCustomGameModeListStyle(0); //We want rows, not grid
			globals.Loader_custom_games.movieClip.setCurrentCustomGameSubTab(0); //We want gamemodes, not lobbies
			globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeSortingComboChanged(5); //Typical valve, requires gameAPI for it to work
			
			
			
			if(globals.Loader_custom_games.movieClip.CustomGames.ModeList.PreviousButton.visible){
				globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeListPreviousPageClicked();
			}
				
			//var nextPageTimer:Timer = new Timer(50, 1);
			//nextPageTimer.addEventListener(TimerEvent.TIMER, createGame);
			//nextPageTimer.start();
			
			var pageFlip:Function = function(e:TimerEvent){
				if(globals.Loader_custom_games.movieClip.CustomGames.ModeList.PreviousButton.visible){
					globals.Loader_custom_games.movieClip.gameAPI.OnCustomGameModeListPreviousPageClicked();
					var repeatTimer:Timer = new Timer(50, 1);
					repeatTimer.addEventListener(TimerEvent.TIMER, pageFlip);
					repeatTimer.start();
					return;
				}
				else
				{
					createGame(e);
				}
			};
			
			var injectTimer:Timer = new Timer(50, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, pageFlip);
            injectTimer.start();
		}
		
		public function createGame(e:TimerEvent) {
			traceLB("##PAGE COUNT: "+ globals.Loader_custom_games.movieClip.CustomGames.ModeList.PageLabel.text);
			var nextPages:int = 1;
			var regex:RegExp = /(\d+).+(\d+)/;
			var pages:String = globals.Loader_custom_games.movieClip.CustomGames.ModeList.PageLabel.text;
			pages = pages.substr(pages.lastIndexOf(":"));
			var groups:Array = regex.exec(pages);
			nextPages = int(groups[2]);
			traceLB(nextPages);
			
			//For testing, lets just do Legends of Dota
			//PrintTable(globals.Loader_custom_games.movieClip.CustomGames.ModeList);
			var i:int;
			var haventFoundGame:Boolean = true;
			// Pull the game mode from the combo box
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			
			for (i=0; i < 12; i++) {
				var obj = globals.Loader_custom_games.movieClip.CustomGames.ModeList.Rows["row"+i].FlyOutButton;
				
				if (obj.GameModeID == false) {
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
				//traceLB("Geez, git good");
				if (int(groups[1]) == nextPages){
					//traceLB('super done'); // no more pages
					var tf:TextField = errorPanel("Game Mode not found.  Copy this link to your browser to subscribe.");
					var link:String = "http://steamcommunity.com/sharedfiles/filedetails/?id=" + gmi;
					traceLB(link);
					
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
			
			var tweenEnd:Function = function(e:TweenEvent){
				if (field.parent != null)
					field.parent.removeChild(field);
		 	};
			
			var tween:Tween = new Tween(field, "alpha", null, 1, 0, 2, true);
			tween.addEventListener(TweenEvent.MOTION_FINISH, tweenEnd, false, 0, true);
			tween.stop();
			
			
			
			var focusOut:Function = function(event:FocusEvent){
				//removeTimer.start();
				tween.resume();
			};
			
			var focusIn:Function = function(event:FocusEvent){
				tween.stop();
			}

			field.addEventListener(FocusEvent.FOCUS_IN, focusIn, false, 0, true);
			field.addEventListener(FocusEvent.FOCUS_OUT, focusOut, false, 0, true);
			
			var ti:uint = (new Date().time) + 8000;
			fields.push({timeout:ti, field:field});
			
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
						traceLB("FOUND, setting index");
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
				+ "&un=" + escape(lobbyState.hostName)
				+ "&lv=" + version;
			
			
			if (currentOptions.length > 0){
				try{
					var lo:Object = new Object();
					for (var id:Object in currentOptions){
						var option = currentOptions[id];
						if (option.type == "dropdown"){
							lo[option.name] = option.control.menuList.dataProvider.requestItemAt(option.control.selectedIndex).data;
						}
						else if (option.type == "checkbox"){
							lo[option.name] = option.control.selected;
						}
						else if (option.type == "textbox"){
							lo[option.name] = option.control.text;
						}
					}
					
					currentUrl += "&lo=" + escape(encode(lo));
					currentOptions = new Array();
				}catch(err:Error){
					traceLB("Options encoding failure.");
					traceLB(err.getStackTrace());
				}
			}
			
			registerLobby();
		}
		
		public function registerLobby(){
			socket.getDataAsync(currentUrl, createdGame);
		}
		
		public function createdGame(statusCode:int, data:String) {
			traceLB("##CREATED_GAME");
			traceLB("Status code: " + statusCode);
			//if (globals.Loader_popups.movieClip.visible)
//				globals.Loader_popups.movieClip.beginClose();

			var json = null;
			var fail:Boolean = false;
			traceLB(data);
			try{
				json = decode(data);
			}
			catch(err:Error){
				traceLB("JSON decode failure");
				traceLB(err.getStackTrace());
				fail = true;
			}
				
			if (fail || statusCode != 200){
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
			
			if (json.error != null){
				traceLB("error: " + json.error);
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
			
			var count:int = 0;
			
			var stateWatcher:Function = function(event:TimerEvent){
				traceLB("statewatcher");
				var state:Object = new Object();
				var i:int = 0;
				var practiceLobby = globals.Loader_practicelobby.movieClip.PracticeLobby;
				var account:uint = 0;
				
				var keepaliveCallback:Function = function(statusCode:int, data:String) {
					traceLB("##keepalivecallback");
					traceLB(statusCode + " -- " + data);
					
					var json = null;
					var fail:Boolean = false;
					try{
						json = decode(data);
						if (json.error != null){
							errorPanel("Keepalive failure: " + json.error);
						}
						else if (json.lobby_active == 0){
							errorPanel("Lobby Timed Out!  It is no longer possible to join this lobby via the browser.");
						}
					}catch(err:Error){
						fail = true;
						traceLB(err.getStackTrace());
						//errorPanel("Keepalive call failed");
					}
				};
				
				if (count % 20 == 0){
					socket.getDataAsync("d2mods/api/lobby_keep_alive.php?lid=" + lobbyState.lid + "&t=" + lobbyState.token, keepaliveCallback);
				}
				count++;
				
				//traceLB('----');
				//traceLB("Pools");
				for (i=0; i<12; i++){
					//traceLB(i + " -- " + practiceLobby["PlayerPool" + i].visible + " -- " + practiceLobby["PlayerPool" + i].accountID + " -- " + practiceLobby["PlayerPool" + i].KickButton.visible);
					if (practiceLobby["PlayerPool" + i].visible && practiceLobby["PlayerPool" + i].accountID)
						state[practiceLobby["PlayerPool" + i].accountID] = practiceLobby["PlayerPool" + i].Player.PlayerNameIngame.text; //true;
				}				
				//traceLB('----');
				//traceLB('Broadcasters');
				for (i=0; i<6; i++){
					//traceLB(i)
					for (var j:int = 0; j<4; j++){
						/*traceLB("\t" + j + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].visible 
							  + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].accountID
							  + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].Player.visible
							  + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].Player.PlayerNameIngame.visible
							  + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].Player.PlayerNameIngame.text
							  + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].Player.PlayerNameOver.visible
							  + " -- " + practiceLobby["Broadcaster" + i]["Player" + j].Player.PlayerNameOver.text);*/
						if (practiceLobby["Broadcaster" + i]["Player" + j].visible && practiceLobby["Broadcaster" + i]["Player" + j].accountID)
							state[practiceLobby["Broadcaster" + i]["Player" + j].accountID] = practiceLobby["Broadcaster" + i]["Player" + j].Player.PlayerNameIngame.text //true;
					}
				}
				//traceLB('----');
				//traceLB('Players');
				for (i=0; i<10; i++){
					/*traceLB(i + " -- " + practiceLobby["Player" + i].visible + practiceLobby["Player" + i].accountID
						  + " -- " + practiceLobby["Player" + i].PlayerName.visible
						  + " -- " + practiceLobby["Player" + i].PlayerName.PlayerNameIngame.visible
						  + " -- " + practiceLobby["Player" + i].PlayerName.PlayerNameIngame.text
						  + " -- " + practiceLobby["Player" + i].PlayerName.PlayerNameOver.visible
						  + " -- " + practiceLobby["Player" + i].PlayerName.PlayerNameOver.text
						  + " -- " + practiceLobby["Player" + i].JoinTeamButton.visible
						  + " -- " + practiceLobby["Player" + i].KickButton.visible);*/
					if (practiceLobby["Player" + i].PlayerName.visible && practiceLobby["Player" + i].accountID)
						state[practiceLobby["Player" + i].accountID] = practiceLobby["Player" + i].PlayerName.PlayerNameIngame.text; // true
				}
				
				var nextState:Object = new Object();
				var key:Object;
				//traceLB('=======');
				//traceLB('=======');
				
				//PrintTable(state);
				
				for (key in lobbyState.players){
					if (state[key] != null){
						// no change
						nextState[key] = state[key];
						delete state[key];
					}
					else{
						retryAsyncCall("d2mods/api/lobby_left.php?uid=" + key + "&lid=" + lobbyState.lid + "&un=" + escape(lobbyState.players[key]) + "&t=" + lobbyState.token, "Player left registration failure");
					}
				}
				
				//PrintTable(state);
				
				for (key in state){
					// new account
					nextState[key] = state[key];
					retryAsyncCall("d2mods/api/lobby_joined.php?uid=" + key + "&lid=" + lobbyState.lid + "&un=" + escape(state[key]) + "&t=" + lobbyState.token, "Player join registration failure");
				}
				
				//PrintTable(nextState);
				//traceLB("-----");
				
				lobbyState.players = nextState;
				
				// Check lobby settings
				var lname:String = globals.Loader_lobby_settings.movieClip.LobbySettings.gamenamefield.text;
				var lpass:String = globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.text;
				var lmap:String = globals.Loader_lobby_settings.movieClip.LobbySettings.CustomMapsDropDown.label;
				//traceLB("lname: " + lname);
				//traceLB("lpass: " + lpass);
				//traceLB("lmap: " + lmap);
				
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
					retryAsyncCall("d2mods/api/lobby_update.php?lid=" + lobbyState.lid + "&map=" + escape(lobbyState.map)
								+ "&mp=" + lobbyState.maxPlayers + "&r=" + lobbyState.region
								+ "&ln=" + escape(lobbyState.lobbyName) + "&t=" + lobbyState.token, "Settings update registration failure");
				}
			};
			
			lobbyStateTimer = new Timer(3000);
			lobbyStateTimer.addEventListener(TimerEvent.TIMER, stateWatcher, false, 0, true);
			lobbyStateTimer.start();
			
			globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.visible = false;
			
			var oldLeaveButton = globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton;
			var oldStartButton = globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton;
			var oldButton1 = globals.Loader_popups.movieClip.gameAPI.Button1Clicked;
			//var oldButton1 = globals.Loader_popups.movieClip.onButton1Clicked;
			var quitDesc:String = globals.GameInterface.Translate("#DOTA_ConfirmQuitDesc");
			
			globals.Loader_popups.movieClip.gameAPI.Button1Clicked = function (){
				traceLB("Button 1 pressed");
				traceLB(quitDesc);
				traceLB(globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.text);
				
				if (globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.text != quitDesc){
					oldButton1();
					return;
				}
				
				lobbyStateTimer.stop();
				traceLB("QUITTING TIME")
				var doneRegistration:Function = function(statusCode:int, data:String){		
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
				traceLB("leave game hit");
				retryAsyncCall("d2mods/api/lobby_close.php?lid=" + lobbyState.lid + "&t=" + lobbyState.token, "Lobby close failure");
				oldLeaveButton();
				globals.Loader_practicelobby.movieClip.gameAPI.LeaveButton = oldLeaveButton;
				globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton = oldStartButton;
				globals.Loader_popups.movieClip.gameAPI.Button1Clicked = oldButton1;
				globals.Loader_lobby_settings.movieClip.LobbySettings.passwordInput.visible = true;
			};
			
			globals.Loader_practicelobby.movieClip.gameAPI.StartGameButton = function (){
				lobbyStateTimer.stop();
				traceLB("start game hit");
				var doneRegistration:Function = function(statusCode:int, data:String){
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
			traceLB(retries + " retryAsyncCall: " + url);
			var retryAsyncCallback:Function = function(statusCode:int, data:String){
				traceLB("###retryAsyncCallback");
				traceLB("Status code: " + statusCode);
				
				var json = null;
				var fail:Boolean = false;
				try{
					json = decode(data);
				}catch(err:Error){
					traceLB(err.getStackTrace());
					fail = true;
				}
				traceLB(data);
				
				if (fail || statusCode != 200){
					// Rerun? show failure
					errorPanel(failureString + ": " + statusCode + "-- Retrying...", 1000);
					
					var retryFunction:Function = function(event:TimerEvent){
						retryAsyncCall(url, failureString, retries, successCallback, failureCallback);
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
			//traceLB(pass);
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
				traceLB("NO GAME FOUND"); // Probably should pop that up
				errorPanel("No Lobby Found.  The game may have begun or been closed.");
				return;
			}
			
			globals.Loader_play.movieClip.gameAPI.JoinPrivateLobby(0); //Join the first game
			
			var injectTimer:Timer = new Timer(1000, 1);
            injectTimer.addEventListener(TimerEvent.TIMER, checkForMissingMode);
            injectTimer.start();
			
			joinPanel.visible = true;
			joinPanelBg.visible = true;
		}
		
		public function checkForMissingMode(e:TimerEvent){
			var requiredMode:String = globals.GameInterface.Translate("#lobby_game_mode_required_desc");
			requiredMode = requiredMode.substr(0, requiredMode.indexOf("\""));
			var rxGMI = /(\d+)/gi;
			
			var msg:String = globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.text;
			
			if (globals.Loader_popups.movieClip.visible && 
				globals.Loader_popups.movieClip.AnimatingPanel.visible &&
				globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.visible &&
				globals.Loader_popups.movieClip.AnimatingPanel.GlimmerAnim.Messages.MSG_Generic.Msg.visible && msg.indexOf(requiredMode) >= 0){
				//globals.Loader_popups.movieClip.onOKClicked(new ButtonEvent(ButtonEvent.CLICK));
				var gmi:String = rxGMI.exec(msg)[1];
				
				var tf:TextField = errorPanel("Game Mode not found.  Copy this link to your browser to subscribe.");
				var link:String = "http://steamcommunity.com/sharedfiles/filedetails/?id=" + gmi;
				traceLB(link);
				
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
			traceLB("REENABLE");
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
			traceLB("###GetLobbyList");
			traceLB("Status code: " + statusCode);
			if (statusCode != 200){
				errorPanel("List Retrieval Failure: " + statusCode);
				// Rerun? show failure
				if (!versionChecked){
					versionChecked = true;
					var waitTimer2:Timer = new Timer(4000, 1);
					waitTimer2.addEventListener(TimerEvent.TIMER, checkVersionCall, false, 0, true);
					waitTimer2.start();
				}
				return;
			}
			var fail:Boolean = false;
			var json = null;
			try{
				json = decode(data);
			}catch(err:Error){
				fail = true;
				traceLB(err.getStackTrace());
			}
			
			var ld:Object = new Object();
			var refreshTime:Number = new Date().time + 5000;
			
			if (!fail && json.error == null){
				for (var i:int=0; i< json.length; i++){
					var lobby:Object = json[i];
					lobby.refreshTime = refreshTime;
					ld[lobby.lobby_id] = lobby;
				}
				if (!versionChecked){
					versionChecked = true;
					checkVersionCall(new TimerEvent(TimerEvent.TIMER));
				}
			}
			else{
				traceLB("NO ACTIVE LOBBIES");
				if (json.error)
					errorPanel(json.error);
				else
					errorPanel("Unable to retrieve lobby list from server.  Please try again");
				
				if (!versionChecked){
					versionChecked = true;
					var waitTimer:Timer = new Timer(4000, 1);
					waitTimer.addEventListener(TimerEvent.TIMER, checkVersionCall, false, 0, true);
					waitTimer.start();
				}
			}
			
			this.lobbyData = ld;
			
			redrawLobbyList();
		}
		
		public function redrawLobbyList(){
			traceLB("##redrawLobby");
			
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
		
		public function redrawOptions(){
			traceLB("##redrawOptions");
			
			var content:MovieClip = this.optionsPanel.options.content;
			for (var i:int = content.numChildren-1; i>=0; i--){
				content.removeChildAt(i);
			}
			
			// Get Mod Option info
			var gmi:Number = this.hostClip.gameModeClip.menuList.dataProvider[this.hostClip.gameModeClip.selectedIndex].data;
			var opts = gmiToOptions[gmi];
			/*var opts = decode('[{"type":"dropdown","label":"Game Mode","name":"gamemode","default":"All Pick","options":[{"label":"All Pick","data":"1"},{"label":"Single Draft","data":"2"}, {"label":"Mirror Draft","data":"3"}, {"label":"All Random","data":"4"}]},{"type":"dropdown","label":"Max Slots","name":"maxslots","default":"6 slots","options":[{"label":"4 Slots","data":"4"},{"label":"5 Slots","data":"5"}, {"label":"6 Slots","data":"6"}]},{"type":"dropdown","label":"Max Skills","name":"maxskills","default":"6 Skills","options":[{"label":"No Regular Abilities","data":"0"},{"label":"1 Regular Ability","data":"1"}, {"label":"2 Regular Abilities","data":"2"}, {"label":"3 Regular Abilities","data":"3"}, {"label":"4 Regular Abilities","data":"4"}, {"label":"5 Regular Abilities","data":"5"}, {"label":"6 Regular Abilities","data":"6"}]},{"type":"dropdown","label":"Max Ults","name":"maxults","default":"2 Ultimate Abilities","options":[{"label":"No Ultimate Abilities","data":"0"},{"label":"1 Ultimate Skill","data":"1"}, {"label":"2 Ultimate Abilities","data":"2"}, {"label":"3 Ultimate Abilities","data":"3"}, {"label":"4 Ultimate Abilities","data":"4"}, {"label":"5 Ultimate Abilities","data":"5"}, {"label":"6 Ultimate Abilities","data":"6"}]},{"type":"dropdown","label":"Max Bans","name":"maxbans","default":"5 Bans Each","options":[{"label":"No Bans","data":"0"},{"label":"1 Ban Each","data":"1"}, {"label":"2 Bans Each","data":"2"}, {"label":"3 Bans Each","data":"3"}, {"label":"5 Bans Each","data":"5"}, {"label":"10 Bans Each","data":"10"}, {"label":"15 Bans Each","data":"15"}, {"label":"20 Bans Each","data":"20"}, {"label":"Host Banning","data":"-1"}]},{"type":"checkbox","label":"Block Troll Combos","name":"blocktrollcombos","default":true},{"type":"dropdown","label":"Starting Level","name":"startinglevel","default":"Level 1","options":[{"label":"Level 1","data":"1"},{"label":"Level 6","data":"6"}, {"label":"Level 11","data":"11"}, {"label":"Level 16","data":"16"}, {"label":"Level 25","data":"25"}]},{"type":"checkbox","label":"Enable Easy Mode","name":"useeasymode","default":false},{"type":"checkbox","label":"Hide Enemy Picks","name":"hideenemypicks","default":true},{"type":"dropdown","label":"Bonus Starting Gold","name":"bonusstartinggold","default":"None","options":[{"label":"0g","data":"0"},{"label":"250g","data":"250"}, {"label":"500g","data":"500"}, {"label":"1000g","data":"1000"}, {"label":"2500g","data":"2500"}, {"label":"5000g","data":"5000g"}, {"label":"10000g","data":"10000"}, {"label":"25000g","data":"25000"}, {"label":"50000g","data":"50000"}, {"label":"100000","data":"100000"}]},{"type":"dropdown","label":"Unique Skills","name":"uniqueskills","default":"Off","options":[{"label":"Off","data":"0"},{"label":"Unique Team Skills","data":"1"}, {"label":"Unique Global Skills","data":"3"}]},'
							  +'{"type":"dropdown","label":"Game Mode","name":"gamemode","default":"All Pick","options":[{"label":"All Pick","data":"1"},{"label":"Single Draft","data":"2"}, {"label":"Mirror Draft","data":"3"}, {"label":"All Random","data":"4"}]},{"type":"dropdown","label":"Max Slots","name":"maxslots","default":"6 slots","options":[{"label":"4 Slots","data":"4"},{"label":"5 Slots","data":"5"}, {"label":"6 Slots","data":"6"}]},{"type":"dropdown","label":"Max Skills","name":"maxskills","default":"6 Skills","options":[{"label":"No Regular Abilities","data":"0"},{"label":"1 Regular Ability","data":"1"}, {"label":"2 Regular Abilities","data":"2"}, {"label":"3 Regular Abilities","data":"3"}, {"label":"4 Regular Abilities","data":"4"}, {"label":"5 Regular Abilities","data":"5"}, {"label":"6 Regular Abilities","data":"6"}]},{"type":"dropdown","label":"Max Ults","name":"maxults","default":"2 Ultimate Abilities","options":[{"label":"No Ultimate Abilities","data":"0"},{"label":"1 Ultimate Skill","data":"1"}, {"label":"2 Ultimate Abilities","data":"2"}, {"label":"3 Ultimate Abilities","data":"3"}, {"label":"4 Ultimate Abilities","data":"4"}, {"label":"5 Ultimate Abilities","data":"5"}, {"label":"6 Ultimate Abilities","data":"6"}]},{"type":"dropdown","label":"Max Bans","name":"maxbans","default":"5 Bans Each","options":[{"label":"No Bans","data":"0"},{"label":"1 Ban Each","data":"1"}, {"label":"2 Bans Each","data":"2"}, {"label":"3 Bans Each","data":"3"}, {"label":"5 Bans Each","data":"5"}, {"label":"10 Bans Each","data":"10"}, {"label":"15 Bans Each","data":"15"}, {"label":"20 Bans Each","data":"20"}, {"label":"Host Banning","data":"-1"}]},{"type":"checkbox","label":"Block Troll Combos","name":"blocktrollcombos","default":true},{"type":"dropdown","label":"Starting Level","name":"startinglevel","default":"Level 1","options":[{"label":"Level 1","data":"1"},{"label":"Level 6","data":"6"}, {"label":"Level 11","data":"11"}, {"label":"Level 16","data":"16"}, {"label":"Level 25","data":"25"}]},{"type":"checkbox","label":"Enable Easy Mode","name":"useeasymode","default":false},{"type":"checkbox","label":"Hide Enemy Picks","name":"hideenemypicks","default":true},{"type":"dropdown","label":"Bonus Starting Gold","name":"bonusstartinggold","default":"None","options":[{"label":"0g","data":"0"},{"label":"250g","data":"250"}, {"label":"500g","data":"500"}, {"label":"1000g","data":"1000"}, {"label":"2500g","data":"2500"}, {"label":"5000g","data":"5000g"}, {"label":"10000g","data":"10000"}, {"label":"25000g","data":"25000"}, {"label":"50000g","data":"50000"}, {"label":"100000","data":"100000"}]},{"type":"dropdown","label":"Unique Skills","name":"uniqueskills","default":"Off","options":[{"label":"Off","data":"0"},{"label":"Unique Team Skills","data":"1"}, {"label":"Unique Global Skills","data":"3"}]},{"type":"textbox","label":"Text Box Test","name":"textTest","default":"Default Text"}]');
							  */
			
			var searchFilter:String = this.lobbySearchField.text;
			var modeFilter:Number = this.lobbyClip.gameModeClip.menuList.dataProvider[this.lobbyClip.gameModeClip.selectedIndex].data
			var mapFilter:String = this.lobbyClip.mapNameClip.menuList.dataProvider[this.lobbyClip.mapNameClip.selectedIndex].data
			var regionFilter:Number = this.lobbyClip.regionClip.menuList.dataProvider[this.lobbyClip.regionClip.selectedIndex].data
			
			currentOptions = new Array();
			
			var curY:int = 15;
			for (var id:Object in opts){
				var option:Object = opts[id];
				if (option == null)
					continue;
					
				var curOpt = new Object();
				curOpt.name = option.name;
				curOpt.type = option.type;
				curOpt.textField = createTextField();
				
				var bgClass:Class = getDefinitionByName("DB_inset") as Class;
				var checkClass:Class = getDefinitionByName("DotaCheckBoxDota") as Class;
				var mc:MovieClip;
				
				if (option.type == "dropdown"){
					mc = new bgClass();
					this.addChild(mc);
					curOpt.control = replaceWithValveComponent(mc, "ComboBoxSkinned");
					curOpt.control.rowHeight = 24;
					var dp:DataProvider = new DataProvider(option.options)
					curOpt.control.visibleRows = dp.length;
					if (dp.length > 6){
						curOpt.control.visibleRows = 6;
						curOpt.control.showScrollBar = true;
					}
					curOpt.control.setDataProvider(dp);
					curOpt.control.setSelectedIndex(0);
					for (var j:int=0; j<dp.length; j++){
						if (dp.requestItemAt(j).label == option.default){
							curOpt.control.setSelectedIndex(j);
							break;
						}
					}
					
					curOpt.control.visible = true;
					curOpt.control.x = 530 * .45;
					curOpt.control.y = curY;
					curOpt.control.width = 530 * .50 - 10 - this.optionsPanel.options.scrollBar.width;
				}
				else if (option.type == "checkbox"){
					curOpt.control = new checkClass();
					curOpt.control.enabled = true;
					if (option.default)
						curOpt.control.selected = true;
					else
						curOpt.control.selected = false;
					
					curOpt.control.visible = true;
					curOpt.control.x = 530 * .45;
					curOpt.control.y = curY;
					curOpt.control.label = "";
					//curOpt.control.width = 530 * .50 - 10 - this.optionsPanel.options.scrollBar.width;
				}
				else if (option.type == "textbox"){
					mc = new bgClass();
					mc.visible = true;
					mc.x = 530 * .45;
					mc.y = curY;
					mc.width = 530 * .50 - 10 - this.optionsPanel.options.scrollBar.width;
					mc.height = 24;
					this.optionsPanel.options.content.addChild(mc);
					curOpt.control = createTextInput(mc, 16);
					curOpt.control.text = option.default;
					
					curOpt.control.visible = true;
					curOpt.control.x = 530 * .45;
					curOpt.control.y = curY;
					curOpt.control.width = 530 * .50 - 10 - this.optionsPanel.options.scrollBar.width;
				}
				currentOptions.push(curOpt);
				
				curOpt.textField.visible = true;
				curOpt.textField.x = 10;
				curOpt.textField.y = curY;
				curOpt.textField.width = 533 * .35;
				curOpt.textField.text = option.label;
				
				
				this.optionsPanel.options.content.addChild(curOpt.textField);
				this.optionsPanel.options.content.addChild(curOpt.control);
				
				curY += 8 + curOpt.control.height;
			}
			
			this.optionsPanel.options.updateScrollBar();
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
					traceLB("###LobbyRefresh");
					traceLB("Status code: " + statusCode);
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
			traceLB("###GetMods");
			traceLB("Status code: " + statusCode);
			
			var fail:Boolean = false;
			var json = null;
			try{
				json = decode(data);
			}catch(err:Error){
				fail = true;
				traceLB(err.getStackTrace());
			}
			//traceLB(data);
			
			if (fail || statusCode != 200){
				// Rerun? show failure
				traceLB("FAILED: " + data);
				if (retryCount == -1)
					retryCount = 2;
					
				retryCount--;
				if (retryCount == -1){
					errorPanel("Unable Connect to GetDotaStats for Mod List: " + statusCode + " -- Custom Lobbies disabled.");
					return;
				}
				errorPanel("Unable Connect to GetDotaStats for Mod List: " + statusCode + " -- Retrying...");
				
				var retryTimer:Timer = new Timer(3000, 1);
				retryTimer.addEventListener(TimerEvent.TIMER, getPopularMods);
				retryTimer.start();
				
				return;
			}
			
			
			this.modsProvider = new DataProvider();
			this.lobbyModsProvider = new DataProvider();
			this.lobbyModsProvider.push({label:"<ANY MODE>", data:-1});
			this.gmiToModID = new Object();
			this.gmiToProvider = new Object();
			this.gmiToLobbyProvider = new Object();
			this.gmiToLobbyProvider[-1] = new DataProvider();
			this.gmiToLobbyProvider[-1].push({label:"<ANY MAP>", data:"*"});
			this.gmiToName = new Object();
			this.gmiToOptions = new Object();
			
			for (var i:int=0; i< json.length;i++){
				var mod:Object = json[i];
				var gameModeId:Number = Number(mod.workshopID);
				var gdsModId:Number = Number(mod.modID);
				
				this.modsProvider.push({label:mod.modName, data:gameModeId});
				this.lobbyModsProvider.push({label:mod.modName, data:gameModeId});
				this.gmiToModID[gameModeId] = gdsModId;
				this.gmiToName[gameModeId] = mod.modName;
				
				if (mod.mod_options_enabled){
					try{
						this.gmiToOptions[gameModeId] = decode(mod.mod_options);
					}
					catch(err:Error){
						traceLB("Unable to decode options: '" + mod.mod_options + "'");
						traceLB(err.getStackTrace());
					}
				}
				
				this.gmiToProvider[gameModeId] = new DataProvider();
				this.gmiToLobbyProvider[gameModeId] = new DataProvider();
				this.gmiToLobbyProvider[gameModeId].push({label:"<ANY MAP>", data:"*"});
				
				//traceLB(mod.mod_maps);
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
			traceLB("###GetMods");
			var json = decode(data);
			//traceLB(data);
			
			var rxId:RegExp = /id=(\d+)/ig;
			this.modsProvider = new DataProvider();
			
			for (var i:int=0; i< json.length;i++){
				var mod:Object = json[i];
				//traceLB(mod.modName + " -- " + mod.workshopLink + " -- " + mod.modInfo);
				//traceLB(Number(rxId.exec(mod.workshopLink)[1]));
				var gameModeId:Number = Number(rxId.exec(mod.workshopLink)[1]);
				
				rxId = /id=(\d+)/ig;
				//traceLB(rxId.exec(mod.modInfo)[1]);
				var gdsModId:Number = Number(rxId.exec(mod.modInfo)[1]);
				//traceLB(gameModeId + " -- " + gdsModId);
				//traceLB('----');
				
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
			traceLB("###STEAM_ID \""+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text+"\"");
			socket.getDataAsync("d2mods/api/lobby_user_status.php?uid="+Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text, getLobbyStatus);
		}
		public function getLobbyStatus(statusCode:int, data:String) {
			traceLB("###LOBBY STATUS");
			var json:Object = decode(data);
			if (json.error) {
				traceLB("Not in a lobby");
				//traceLB("Result: "+json.error);
				return;
			}
			traceLB("We are in a lobby for "+json.workshop_id+" with to suit a lobby of "+json.lobby_max_players+ " players!");
			if (json.lobby_leader == Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text) {
				target_gamemode = json.workshop_id;
				target_password = json.lobby_pass;
				target_lobby = json.lobby_id;
				test1(new MouseEvent(MouseEvent.CLICK));
			} else {
				if (json.lobby_hosted == 1) {
					traceLB("JOINING LOBBY "+json.lobby_id);
					target_gamemode = json.workshop_id;
					target_lobby = json.lobby_id;
					test2(new MouseEvent(MouseEvent.CLICK), json.lobby_pass);
				} else {
					traceLB("Games not ready, why were we called?!");
				}
			}
			traceLB(data);
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
		
		public function createTextField(size:uint = 18, color:uint = 0xFFFFFF, align:String = TextFormatAlign.LEFT) : TextField{
			var tf:TextFormat = globals.Loader_chat.movieClip.chat_main.chat.ChatInputBox.textField.getTextFormat();
			var field:TextField = new TextField();
			field.height = size + 4;
			field.width = 200;

			tf.size = size;
			tf.color = color;
			tf.align = align;
			//tf.font = "$TextFont*"; // Dunno what do on this
			field.setTextFormat(tf);
			field.defaultTextFormat = tf;
			field.autoSize = "none";
			field.maxChars = 0;
			//field.type = TextFieldType.DYNAMIC;
			
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
			//traceLB("Injected by Ash47!\n\n\n");
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
			traceLB("ratio: " + correctedRatio);

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
			
			optionsPanelBg.scaleX = correctedRatio;
			optionsPanelBg.scaleY = correctedRatio;
			optionsPanelBg.x = (re.ScreenWidth / 2 - optionsPanelBg.width / 2);//re.ScreenWidth * .3;
			offset = (this.optionsPanel.options.content.height - 333) * correctedRatio;
			if (offset < 0)
				offset = 0;
			optionsPanelBg.y = (re.ScreenHeight - optionsPanelBg.height + offset) / 2;//re.ScreenHeight * .25;
		
			scalingTopBarPanel.scaleX = correctedRatio;
			scalingTopBarPanel.scaleY = correctedRatio;
			logPanel.x = re.ScreenWidth / 2 - logPanel.width * scalingTopBarPanel.scaleX / 2;
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
