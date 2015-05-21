package  {
	
	import flash.display.MovieClip;
	import flash.utils.ByteArray;
	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.serialization.json.JSONEncoder;
	import flash.utils.getDefinitionByName;
	import flash.text.TextField;
	import flash.events.MouseEvent;
	import flash.text.TextFormatAlign;
	import ValveLib.Globals;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import scaleform.gfx.TextFieldEx;
	import ValveLib.Events.InputBoxEvent;
	import ValveLib.Controls.InputBox;
	import flash.events.FocusEvent;
	import flash.events.TextEvent;
	import flash.text.StyleSheet;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.geom.Point;
	import scaleform.clik.controls.ScrollBar;
	import flash.text.TextFieldAutoSize;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import scaleform.gfx.FocusManager;
	import scaleform.clik.managers.FocusHandler;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	
	public class LXChat extends MovieClip {
		private var mgs:MGSocket = null;
		private var BATCH_TIMER = 250;
		private var BACKLOG = 30000;
		private var MSG_HISTORY = 30;
		private var CONN_TIMEOUT = 6000;
		private var ROSTER_BATCH_COUNT = 5;
		
		private var lx = null;
		
		private var panel:MovieClip;
		private var indent:MovieClip;
		private var outer:MovieClip;
		private var container:MovieClip;
		private var closeButton:MovieClip;
		private var title:TextField;
		private var resizeClip:MovieClip;
		
		private var historyBG:MovieClip;
		private var history:MovieClip;
		private var rosterBG:MovieClip;
		private var roster:MovieClip;
		private var input:InputBox;
		private var inputBG:MovieClip;
		private var participantsButton:MovieClip;
		
		private var batchCount = ROSTER_BATCH_COUNT - 1;
		private var rosterUnclean:Boolean = true;
		private var rosterShown:Boolean = true;
		private var resizeStartX:Number;
		private var resizeStartY:Number;
		private var resizeScrollLock:Boolean;
		private var dragging:Boolean = false;
		private var chatOpts:Object;
		private var asdf:int = 1128;
		
		private var connectionIP:String = "71.179.179.140";
		//private var connectionIP:String = "96.244.208.108";
		//private var connectionIP:String = "192.168.222.3";
		private var curChannel:String = "home";
		private var id = null;
		private var userName:String = null;
		private var authed:Boolean = false;
		private var authToken:String = null;
		private var role:int = MGSocket.ROLE_USER;
		private var channelText:Object = {};
		private var channelRosterNames:Object = {};
		private var channelRosterIds:Object = {};
		private var channelMessageHistory:Object = {};
		private var messageHistoryIndex:int = 0;
		private var batchTimer:Timer;
		private var lastBatchTime:Number = 0;
		private var timeoutTimer:Timer;
		private var lobbyLinkUser = null;
		private var canJoinLobby:Boolean = true;
		private var showUserNotifications:Boolean = false;
		
		
		private var substitutions = {"BabyRage":20,
									"Baku":20,
									"BibleThump":20,
									"ChaChing":20,
									"DankMeme":20,
									"DansGame":20,
									"DendiFace":20,
									"EleGiggle":20,
									"EmoTA":20,
									"EvilLenny":13,
									"FailFish":20,
									"FrankerZ":20,
									"FrogGod":20,
									"GreyFace":20,
									"HandsomeDevil":20,
									"HollaHolla":20,
									"Impossibru":20,
									"JohnMadden":20,
									"KAPOW":20,
									"Kappa":20,
									"Keepo":20,
									"Kreygasm":20,
									"LastWord":20,
									"LordGaben":20,
									"MyllDerp":20,
									"NoyaHammer":20,
									"PeonSad":20,
									"PJSalt":20,
									"PogChamp":20,
									"PromNight":20,
									"PureSkill":20,
									"PWizzy":20,
									"RoyMander":20,
									"ShhQuiet":20,
									"SleepyTime":20,
									"SMOrc":20,
									"SmugCourier":20,
									"SnoozeFest":20,
									"TeamGomez":20,
									"TinkerFi":20,
									"TrashMio":20,
									"TrollFace":20,
									"UltraSin":20,
									"VolvoPls":9,
									"WinWaker":20};
									
		//BabyRage Baku BibleThump ChaChing DankMeme DansGame DendiFace EleGiggle EmoTA EvilLenny FailFish FrankerZ FrogGod GreyFace HandsomeDevil HollaHolla Impossibru JohnMadden KAPOW Kappa Keepo Kreygasm LastWord LordGaben MyllDerp NoyaHammer PeonSad PJSalt PogChamp PromNight PureSkill PWizzy RoyMander ShhQuiet SleepyTime SMOrc SmugCourier SnoozeFest TeamGomez TinkerFi TrashMio TrollFace UltraSin VolvoPls WinWaker
		
		/*  TODO
			- add password display to host in LX
			- share with chat button on host display
			- silent mute/ban/ipban info adds
			- batch roster stuff, maytbe check batch fixer for delay causing
			- add dansgame emote
			- role api on lobbybot
			- 
			
			-x Fixed join channel after auth i think
			-x Messages in the room mentioning your name are now highlighted
			-x Added escaping to ban/mute/ipban lists
			-x Rewrote the string replacement/regex functions in scaleform to handle Unicode better
			-x Added emotes.
			
			- refire /connect on focus
			- custom lobby warning shows on regular games, shouldn't
			- tab completion
		*/
		
		public function LXChat(lx:*, authToken:String = null) {
			// constructor code
			trace("LXChat constructed");
			trace(asdf);
			this.id = int(Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text);
			this.userName = Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.Player.PlayerNameIngame.text;
			this.lx = lx;
			this.authToken = authToken;
			
			// panels
			container = new MovieClip();
			
			var panelClass:Class = getDefinitionByName("DB_inset") as Class;
			panel = new panelClass();
			panel.visible = true;
			panel.enabled = true;
			panel.y = -5;
			
			var indentClass:Class = getDefinitionByName("indent_hilite") as Class;
			indent = new indentClass();
			indent.y = -35;
			indent.height = 30;
			
			var outerClass:Class = getDefinitionByName("DB4_outerpanel") as Class;
			outer = new outerClass();
			outer.y = -30;
			
			title = lx.createTextField(22, 0xFFFFFF, TextFormatAlign.CENTER);
			title.y = -32;
			title.text = "LX Chat";
			
			var closeClass:Class = getDefinitionByName("CloseButton") as Class;
			closeButton = new closeClass();
			closeButton.width = 16;
			closeButton.height = 16;
			closeButton.y = -26;
			
			var participantClass:Class = getDefinitionByName("s_ToggleParticipantsButton") as Class;
			participantsButton = new participantClass();
			//participantsButton.width = 16;
			//participantsButton.height = 16;
			participantsButton.y = -27;
			participantsButton.label = "";
			participantsButton.scaleX = 1.2;
			participantsButton.scaleY = 1.2;
			
			inputBG = new panelClass();
			inputBG.height = 35;
			inputBG.x = 5;
			
			
			var tf:TextFormat = Globals.instance.Loader_chat.movieClip.chat_main.chat.ChatInputBox.textField.getTextFormat();
			var ibClass:Class = getDefinitionByName("InputBoxSkinned") as Class;
			
			input = new ibClass() as InputBox;
			input.x = inputBG.x + 10;
			input.height = inputBG.height;
			
			tf.size = 16;
			tf.color = 0xFFFFFF;
			tf.align = TextFormatAlign.LEFT;
			tf.font = "$TextFont";
			
			input.textField.styleSheet = null;
			input.defaultTextFormat = tf;
			input.textField.setTextFormat(tf);
			input.textField.defaultTextFormat = tf;
			//input.textField.autoSize = "none";
			input.maxChars = 400;
			//input.textField.type = TextFieldType.INPUT;
			
			TextFieldEx.setVerticalAlign(input.textField, TextFieldEx.VALIGN_CENTER);
			
			//this.hostClip.addChild(field);
			input.visible = true;
			input.text = "";
			
			
			historyBG = new panelClass();
			historyBG.x = 5;
			
			
			var historyClass:Class = getDefinitionByName("s_history") as Class;
			history = new historyClass();
			history.x = historyBG.x + 2
			history.sb.width += 4;
			
			
			var ss:StyleSheet = new StyleSheet();
         	ss.setStyle("a:link",{"textDecoration":"none"});
         	ss.setStyle("a:hover",{"textDecoration":"underline"});
			history.taChat.styleSheet = ss;
			
			rosterBG = new panelClass();
			rosterBG.width = 140;
			
			roster = new historyClass();
			roster.sb.width += 4;
			roster.sb.x = rosterBG.width - 2 - roster.sb.width;
			
			ss = new StyleSheet();
			ss.setStyle("a:link",{"textDecoration":"none"});
         	ss.setStyle("a:hover",{"textDecoration":"underline"});
         	//ss.setStyle("a:hover",{color:"#FFFFFF", "textDecoration":"none"});
			roster.taChat.styleSheet = ss;
			//roster.taChat.wordWrap = false;
			//roster.taChat.autoSize = TextFieldAutoSize.LEFT;
			
			var chatMask:Sprite = new Sprite();
			chatMask.graphics.beginFill(0xFF0000);
			chatMask.graphics.drawRect(0, 0, rosterBG.width - 25, 100);
			roster.addChild(chatMask);
			roster.taChat.mask = chatMask;
			
			var resizeClass:Class = getDefinitionByName("ResizeClip") as Class;
			resizeClip = new resizeClass();
			
			container.addChild(outer);
			container.addChild(title);
			container.addChild(panel);
			container.addChild(indent);
			container.addChild(inputBG);
			container.addChild(input);
			container.addChild(historyBG);
			container.addChild(history);
			container.addChild(rosterBG);
			container.addChild(roster);
			container.addChild(participantsButton);
			container.addChild(closeButton);
			container.addChild(resizeClip);
			
			trace("1");
			
			
			
			var subs = new Array;
			var i:int = 0;
			for (var word in substitutions){
				var yoff = substitutions[word];
				var imgClass = getDefinitionByName(word + ".png") as Class;
				var img = new imgClass();
				subs[i] = { subString:word + " ", image:img, baseLineY:yoff, id:"sm=" + word };
				i++;
			}
			//subs[0] = { subString:"Kappa ", image:kappa, baseLineY:20, id:"sm=Kappa" };
			TextFieldEx.setImageSubstitutions(history.taChat, subs);
			
			trace("=====");
			/*for (var b in Globals.instance.Loader_chat.movieClip.histories){
				trace(b);
				var c = Globals.instance.Loader_chat.movieClip.histories[b];
				if (c.hasOwnProperty("taChat")){
					trace(c.taChat.htmlText);
					trace("---------");
				}
			}*/
			trace("=====");
			
			chatOpts = lx.lxOptions.Chat;
			if (chatOpts == null){
				//lx.screenWidth * .65 - container.width / 2 * lx.correctedRatio;
				//lx.screenHeight * .5 - container.height / 2 * lx.correctedRatio;
				var clip = Globals.instance.Loader_chat.movieClip.chat_main.chat.bg;
				var point = clip.localToGlobal(new Point(0,0));
				var point2 = clip.localToGlobal(new Point(clip.width, clip.height));
				var xpos = point.x
				var ypos = point.y + 85 * lx.correctedRatio;
				
				var xratio = 1;
				switch(clip.width){
					case 540:
						// 16:9
						xratio = .92;
						break;
					case 372:
						// 16:10
						xratio = 1.3;
						break;
					case 272:
						// 4:3
						xratio = 1.77;
				}
				var wid = (point2.x - point.x) / lx.correctedRatio * xratio;
				var hei = (point2.y - point.y) / lx.correctedRatio * 1.46;
				trace(wid, " -- ", hei);
				chatOpts = {X:xpos, Y:ypos, Width:wid, Height:hei, ShowRoster:"1", ShowUserNotifications:"0"};
				lx.lxOptions.Chat = chatOpts;
				saveChatOpts();
			}
			
			if (chatOpts.X + chatOpts.Width * lx.correctedRatio > lx.screenWidth)
				chatOpts.X = lx.screenWidth - chatOpts.Width;
			if (chatOpts.Y + chatOpts.Height * lx.correctedRatio > lx.screenHeight)
				chatOpts.Y = lx.screenHeight - chatOpts.Height;
			rosterShown = chatOpts.ShowRoster == "1"
			if (chatOpts.ShowUserNotifications == null){
				chatOpts.ShowUserNotifications = "0";
				saveChatOpts();
			}
			showUserNotifications = chatOpts.ShowUserNotifications == "1";
			
			if (!rosterShown){
				roster.visible = false;
				rosterBG.visible = false;
			}
			
			resizeWindow(chatOpts.Width, chatOpts.Height);
			
			container.addEventListener(MouseEvent.MOUSE_DOWN, handleDragDown);
			container.addEventListener(MouseEvent.MOUSE_UP, handleDragUp);
			resizeClip.addEventListener(MouseEvent.MOUSE_DOWN, handleResizeDown);
			closeButton.addEventListener(MouseEvent.CLICK, gameCloseClicked);
			participantsButton.addEventListener(MouseEvent.CLICK, rosterToggle);
			input.addEventListener(InputBoxEvent.TEXT_SUBMITTED, commandInput);
			input.addEventListener(TextEvent.TEXT_INPUT, fixFormat);
			history.taChat.addEventListener(TextEvent.LINK, chatLinkClicked);
			roster.taChat.addEventListener(TextEvent.LINK, chatLinkClicked);
			
			input.addEventListener(FocusEvent.FOCUS_IN, inputFocusIn);
			input.addEventListener(FocusEvent.FOCUS_OUT, inputFocusOut);
			
			/*if (minigameLastPositions[gameName] != null){
				container.x = minigameLastPositions[gameName].x;
				container.y = minigameLastPositions[gameName].y;
			}*/
			//else{
				container.x = chatOpts.X;
				container.y = chatOpts.Y;
			//}
			
			Globals.instance.Loader_top_bar.movieClip.addChildAt(container, Globals.instance.Loader_top_bar.movieClip.getChildIndex(lx.scalingTopBarPanel) - 1);
			
			channelText[curChannel] = "";
			
			lastBatchTime = new Date().time;
			batchTimer = new Timer(BATCH_TIMER, 0);
			batchTimer.addEventListener(TimerEvent.TIMER, batchText);
			batchTimer.start();
			
			connect();
		}
		
		public override function get visible():Boolean{
			return container.visible;
		}
		public override function set visible(value:Boolean):void{
			container.visible = value;
		}
		
		public override function get scaleX():Number{
			return container.scaleX;
		}
		public override function set scaleX(value:Number):void{
			container.scaleX = value;
		}
		
		public override function get scaleY():Number{
			return container.scaleY;
		}
		public override function set scaleY(value:Number):void{
			container.scaleY = value;
		}
		
		private function keyListener(e:KeyboardEvent){
			if (e.keyCode == Keyboard.UP){
				if (!channelMessageHistory[curChannel] || messageHistoryIndex == channelMessageHistory[curChannel].length - 1)
					return;
					
				if (messageHistoryIndex == 0)
					channelMessageHistory[curChannel][0] = input.text;
				
				messageHistoryIndex++;
				input.text = channelMessageHistory[curChannel][messageHistoryIndex];
			}
			else if (e.keyCode == Keyboard.DOWN){
				if (!channelMessageHistory[curChannel] || messageHistoryIndex == 0)
					return;
				
				messageHistoryIndex--;
				input.text = channelMessageHistory[curChannel][messageHistoryIndex];
			}
			else{
				return;
			}
			
			inputToEnd();
		}
		
		private function inputFocusIn(e:FocusEvent){
			lx.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener)
			//input.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private function inputFocusOut(e:FocusEvent){
			lx.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private function handleDragDown(event:MouseEvent){
			if (event.target == outer || event.target == indent || event.target == title){
				dragging = true;
				container.startDrag();
			}
		}
			
		private function handleDragUp(event:MouseEvent){
			if (dragging)
				container.stopDrag();
			
			chatOpts.X = container.x;
			chatOpts.Y = container.y;
			saveChatOpts();
		}
		
		private function handleResizeMove(event:MouseEvent){
			var p:Point = container.localToGlobal(new Point(0,0));
			
			var newX = event.stageX - p.x;
			var newY = event.stageY - p.y;
			if (newX < 325)
				newX = 325;
			if (newY < 150)
				newY = 150;
			resizeWindow(newX / lx.correctedRatio, newY / lx.correctedRatio);
			
			if (resizeScrollLock)
				history.taChat.scrollV = history.taChat.maxScrollV;
		}
		
		private function handleResizeDown(event:MouseEvent){
			resizeStartX = event.stageX;
			resizeStartY = event.stageY;
			resizeScrollLock = history.taChat.scrollV == history.taChat.maxScrollV;
			lx.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleResizeMove);
			lx.stage.addEventListener(MouseEvent.MOUSE_UP, handleResizeUp);
		}
			
		private function handleResizeUp(event:MouseEvent){
			lx.stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleResizeMove);
			lx.stage.removeEventListener(MouseEvent.MOUSE_UP, handleResizeUp);
			
			chatOpts.Width = panel.width - 15;
			chatOpts.Height = panel.height - 15;
			saveChatOpts();
		}
		
		private function gameCloseClicked(e:MouseEvent){
			container.visible = false;
		}
		
		private function rosterToggle(e:MouseEvent){
			var scrollBottom = history.taChat.scrollV == history.taChat.maxScrollV;
			historyBG.width += rosterBG.width * ((rosterShown) ? 1 : -1);
			
			rosterShown = !rosterShown;
			rosterBG.visible = rosterShown;
			roster.visible = rosterShown;
			chatOpts.ShowRoster = (rosterShown) ? "1" : "0";
			
			resizeWindow(panel.width - 15, panel.height - 15);
			drawRoster();
			saveChatOpts();
			
			if (scrollBottom)
				history.taChat.scrollV = history.taChat.maxScrollV;
		}
		
		private function fixFormat(e:TextEvent){
			var tf:TextFormat = input.textField.getTextFormat();
			tf.size = 16;
			input.textField.setTextFormat(tf);
			input.textField.defaultTextFormat = tf;
			//input.removeEventListener(FocusEvent.FOCUS_IN, focused);
		}
		
		private function chatLinkClicked(e:TextEvent) : *
		{
			trace("clicked: " + e.text);
			
			if (e.text.match(/a[0-9]+/)){
				var replace = "";
				if (input.text.match(/^\s*$/)){
					replace = "/msg ";
					input.text = "";
				}
				var uid = e.text.substr(1);
				var user = channelRosterIds[curChannel][uid];
				if (user != null){
					if (user.name.indexOf(" ") >= 0 || user.name.charAt(0) == "\""){
						var str = "";
						for (var i=0; i<user.name.length; i++){
							var ch = user.name.charAt(i);
							if (ch == "\"" || ch == "\\"){
								str += "\\";
							}
							str += ch;
						}
						input.text += replace + "\"" + str + "\" ";
					}
					else
						input.text += replace + user.name + " ";
					fixFormat(null);
					
					lx.stage.focus = input;
					inputToEnd();
				}
				
				Globals.instance.Loader_chat.movieClip.gameAPI.ChatLinkClicked(e.text);
			}
			else if (e.text.match(/l([0-9]+):([0-9]+)/)){
				if (canJoinLobby){
					var groups = e.text.match(/l([0-9]+):([0-9]+)/);
					
					var lobbyid = groups[1];
					lobbyLinkUser = groups[2];
					
					appendText("<i>Attempting to join lobby.</i>");
					mgs.writeJSON({type:"joinLobby", fromUser:id, toUser:lobbyLinkUser, lobby:lobbyid}, MGSocket.GAME_JSON);
					canJoinLobby = false;
					
					var fun:Function = function(e:TimerEvent){
						canJoinLobby = true;
					}
					var timer:Timer = new Timer(2000,1);
					timer.addEventListener(TimerEvent.TIMER, fun);
					timer.start();
				}
			}
		}
		
		public function appendText(text:String, batch:Boolean = false){
			if (text.charAt(text.length - 1) == "\n")
				channelText[curChannel] += text;
			else
				channelText[curChannel] += text + "\n";
			
			var length:int = channelText[curChannel].length;
			if (length > BACKLOG){
				channelText[curChannel] = channelText[curChannel].substring(length - BACKLOG);
				var offset:int = channelText[curChannel].indexOf("\n") + 1;
				channelText[curChannel] = channelText[curChannel].substring(offset);
			}
			
			if (batch)
				batchText(null);
		}
		
		private function batchText(e:TimerEvent){
			batchCount++;
			if (batchCount >= ROSTER_BATCH_COUNT){
				batchCount = 0;
				drawRoster();
			}
			lastBatchTime = new Date().time;
			var scrollBottom = history.taChat.scrollV == history.taChat.maxScrollV;
			
			history.taChat.htmlText = channelText[curChannel];
			
			if (scrollBottom)
				history.taChat.scrollV = history.taChat.maxScrollV;
		}
		
		private function commandInput(e:InputBoxEvent){
			if (input.text == "")
				return;
				
			var line = input.text;
			input.text = "";
			
			if (channelMessageHistory[curChannel] == null)
				channelMessageHistory[curChannel] = [];
			
			channelMessageHistory[curChannel][0] = line;
			if (channelMessageHistory[curChannel].unshift("") > MSG_HISTORY)
				channelMessageHistory[curChannel].pop();
			
			messageHistoryIndex = 0;
			
			var groups = line.match(/^\/connect/);
			if (groups){
			  if (mgs == null)
			  	connect();
			  else
			  	appendText("<B><font size='14' color='#FF0000'>Already connected to the chat server.</font></B>");
			  return;
			}
			
			groups = line.match(/^\/\?/);
			if (groups || line.match(/^\/help/)){
				appendText("<font size='10'>&nbsp;&nbsp;<font color='#FFFFFF'>/connect</font> -- Connect to the server");
				
				switch(role){
					case MGSocket.ROLE_ADMIN:
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/own [NAME]</font> -- Change [NAME] to owner");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/unown [NAME]</font> -- Remove owner from [NAME]");
					case MGSocket.ROLE_OWNER:
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/mod [NAME]</font> -- Change [NAME] to moderator");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/unmod [NAME]</font> -- Remove moderator from [NAME]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/ipban [NAME] [REASON]</font> -- IP BAN [NAME] with [REASON]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/unipban [INDEX]</font> -- Lift the IP Ban given by the IP Ban List [INDEX]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/ipbanlist</font> -- List of IP bans");
					case MGSocket.ROLE_MODERATOR:
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/mute [NAME] [TIME] [REASON]</font> -- Mute [NAME] for [TIME] (1m,8h,1d,etc) with [REASON]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/unmute [NAME]/[ID]</font> -- Unmute user with [NAME] or [ID]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/ban [NAME] [TIME] [REASON]</font> -- Ban [NAME] for [TIME] (1m,8h,1d,etc) with [REASON]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/unban [NAME]/[ID]</font> -- Unban user with [NAME] or [ID]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/kick [NAME] [REASON]</font> -- Kick [NAME] with [REASON]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/warn [NAME] [REASON]</font> -- Warn [NAME] with [REASON] - Has no direct effect");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/banlist</font> -- List of bans");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/mutelist</font> -- List of mutes");
					default:
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/msg [NAME] MESSAGE</font> -- Send private message to [NAME]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/whois [NAME]</font> -- See details about [NAME]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/ignore [NAME]</font> -- Ignore messages from [NAME]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/unignore [NAME]/[ID]</font> -- Unignore message from [NAME]");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/ignorelist</font> -- List of ignored users");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/ping</font> -- Display your ping to the server");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/notifications</font> -- Toggle displaying user join/leave/disconnects");
						appendText("&nbsp;&nbsp;<font color='#FFFFFF'>/disconnect</font> -- Disconnect from server</font>", true);
						break;
				}
				
				return;
			}
			
			if (mgs == null){
				appendText("<B><font size='14' color='#FF0000'>Not currently connected to the chat server.  Type \"<font color='#FFFFFF'>/connect</font>\" to connect.</font></B>");
				return;
			}
			
			var type = MGSocket.SYSTEM_JSON;
			var obj = null;
			var msg;
			var chan;
			var user;
			var str:String;
			var ret;
			var uid;
			var time;
			
			if (line.charAt(0) == '/'){
				// command
				switch(role){
					case MGSocket.ROLE_ADMIN:
						groups = line.match(/^\/own (.+)/);
						if (groups && line.length >= 6){
							str = line.substring(5);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"ownUser", channel:curChannel, fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/unown (.+)/);
						if (groups && line.length >= 8){
							str = line.substring(7);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"unownUser", channel:curChannel, fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
					case MGSocket.ROLE_OWNER:
						groups = line.match(/^\/mod (.+)/);
						if (groups && line.length >= 6){
							str = line.substring(5);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"modUser", channel:curChannel, fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/unmod (.+)/);
						if (groups && line.length >= 8){
							str = line.substring(7);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"unmodUser", channel:curChannel, fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/ipban (.+)/);
						if (groups && line.length >= 8){
							str = line.substring(7);
							ret = splitInputMessage(str);
							user = ret.user;
							msg = ret.msg;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"ipbanUser", fromUser:id, user:Number(uid), reason:msg};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/unipban (.+)/);
						if (groups && line.length >= 10){
							str = line.substring(9);
							//ret = splitInputMessage(str);
							//user = ret.user;
							//uid = channelRosterNames[curChannel][user];
							
							if (!Number(str)){
								appendText("<font size='12' color='#FFFFFF'>No index given.</font>", true);
								return;
							}
							
							obj = {type:"unipbanUser", fromUser:id, index:Number(str)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/ipbanlist/);
						if (groups){
							obj = {type:"ipbanList", fromUser:id};
							type = MGSocket.GAME_JSON;
						}
					case MGSocket.ROLE_MODERATOR:
						groups = line.match(/^\/mute (.+)/);
						if (groups && line.length >= 7){
							str = line.substring(6);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							msg = ret.msg;
							
							if (msg.indexOf(" ") > 0){
								time = msg.substring(0, msg.indexOf(" "));
								msg = msg.substring(msg.indexOf(" ") + 1);
							}
							else{
								time = msg;
								msg = "";
							}
							time = getTimeDelta(time);
							if (time == null){
								appendText("<font size='12' color='#FFFFFF'>Invalid time given.</font>", true);
								return;
							}
							
							
							if (uid == null){
								uid = user;
								if (!Number(uid) || channelRosterIds[curChannel][user] == null){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							
							obj = {type:"muteUser", fromUser:id, user:Number(uid), time:time, reason:msg};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/unmute (.+)/);
						if (groups && line.length >= 9){
							str = line.substring(8);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"unmuteUser", fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/ban (.+)/);
						if (groups && line.length >= 6){
							str = line.substring(5);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							msg = ret.msg;
							
							if (msg.indexOf(" ") > 0){
								time = msg.substring(0, msg.indexOf(" "));
								msg = msg.substring(msg.indexOf(" ") + 1);
							}
							else{
								time = msg;
								msg = "";
							}
							time = getTimeDelta(time);
							if (time == null){
								appendText("<font size='12' color='#FFFFFF'>Invalid time given.</font>", true);
								return;
							}
							
							
							if (uid == null){
								uid = user;
								if (!Number(uid) || channelRosterIds[curChannel][user] == null){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"banUser", fromUser:id, user:Number(uid), time:time, reason:msg};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/unban (.+)/);
						if (groups && line.length >= 8){
							str = line.substring(7);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
							}
							else if (!Number(uid)){
								appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
								return;
							}
							
							obj = {type:"unbanUser", fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/kick (.+)/);
						if (groups && line.length >= 7){
							str = line.substring(6);
							ret = splitInputMessage(str);
							user = ret.user;
							msg = ret.msg;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"kickUser", fromUser:id, user:Number(uid), reason:msg};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/warn (.+)/);
						if (groups && line.length >= 7){
							str = line.substring(6);
							ret = splitInputMessage(str);
							user = ret.user;
							msg = ret.msg;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								uid = user;
								if (!Number(uid)){
									appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
									return;
								}
							}
							
							obj = {type:"warnUser", fromUser:id, user:Number(uid), reason:msg, toChannel:curChannel};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/banlist/);
						if (groups){
							obj = {type:"banList", fromUser:id};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/mutelist/);
						if (groups){
							obj = {type:"muteList", fromUser:id};
							type = MGSocket.GAME_JSON;
						}
					case MGSocket.ROLE_USER:
						groups = line.match(/^\/msg (.+)/);
						if (groups && line.length >= 6){
							str = line.substring(5);
							var replace:String = "/msg ";
							ret = splitInputMessage(str);
							replace += ret.replace;
							user = ret.user;
							msg = ret.msg;							
							
							uid = channelRosterNames[curChannel][user];
							if (uid == null){
								appendText("<B><font color='#FFFFFF' size='14'>No user found.</font></B>", true);
								return;
							}
							
							input.text = replace;
							inputToEnd();
							
							if (msg == "")
								return;
							
							obj = {type:"msg", fromUser:id, toUser:Number(uid), msg:msg};
							type = MGSocket.GAME_JSON;
							appendText(getTimeString() + "<font color='#FF33CC' size='14'>[To " + getUserString(obj.toUser, "") + "] " + escapeTags(obj.msg) + " </font>\n", true);
						}
						
						groups = line.match(/^\/disconnect/);
						if (groups){
							obj = {type:"disconnect"};
							type = MGSocket.SYSTEM_JSON;
							
							appendText("<i><font size='12'>Disconnecting...</font></i>", true);
							
							var timeoutFun:Function = function(ev:TimerEvent){
								onClosed(new MGEvent(MGEvent.CLOSED, {type:"close", error:"Unable to reach server.  Disconnecting."}));
							};
							
							timeoutTimer = new Timer(5000, 1);
							timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeoutFun);
							timeoutTimer.start();
						}
						
						groups = line.match(/^\/ping/);
						if (groups){
							var curPing = mgs.getPing();
							appendText("<B><font color='#FFFFFF' size='14'>PING: " + mgs.getPing() + " ms</font></B>", true);
							mgs.write(new ByteArray(), MGSocket.PING_NOCLOSE);
						}
						
						groups = line.match(/^\/whois (.+)/);
						if (groups && line.length >= 8){
							str = line.substring(7);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (uid == null){
								appendText("<font size='12' color='#FFFFFF'>No user found.</font>", true);
								return;
							}
							
							obj = {type:"whois", fromUser:id, user:Number(uid)};
							type = MGSocket.GAME_JSON;
						}
						
						groups = line.match(/^\/ignore (.+)/);
						if (groups && line.length >= 9){
							str = line.substring(8);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (!chatOpts.hasOwnProperty("Ignored"))
								chatOpts.Ignored = {};
								
							if (uid == null){
								appendText("<font size='12' color='#FFFFFF'>No user found to ignore.</font>", true);
								return;
							}
							
							chatOpts.Ignored[uid] = user;
							appendText("<font size='12' color='#FFFFFF'>" + chatOpts.Ignored[uid] + "@" + uid + " is ignored.</font>", true);
							saveChatOpts();
						}
						
						groups = line.match(/^\/unignore (.+)/);
						if (groups && line.length >= 11){
							str = line.substring(10);
							ret = splitInputMessage(str);
							user = ret.user;
							uid = channelRosterNames[curChannel][user];
							
							if (!chatOpts.hasOwnProperty("Ignored"))
								chatOpts.Ignored = {};
							
							if (chatOpts.Ignored[uid]){
								appendText("<font size='12' color='#FFFFFF'>" + chatOpts.Ignored[uid] + "@" + uid + " is unignored.</font>", true);
								delete chatOpts.Ignored[uid];
							} else if (chatOpts.Ignored[user]){
								appendText("<font size='12' color='#FFFFFF'>" + chatOpts.Ignored[user] + "@" + user + " is unignored.</font>", true);
								delete chatOpts.Ignored[user];
							}
							else{
								appendText("<font size='12' color='#FFFFFF'>No user found to unignore.</font>", true);
								return;
							}
							
							saveChatOpts();
						}
						
						groups = line.match(/^\/ignorelist/);
						if (groups){
							if (!chatOpts.hasOwnProperty("Ignored"))
								chatOpts.Ignored = {};
							
							appendText("<font size='12' color='#FFFFFF'>&nbsp;&nbsp;Ignored:</font><font size='10'>");
							for (var ignoreId in chatOpts.Ignored){
								if (channelRosterIds[curChannel][ignoreId])
									appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + channelRosterIds[curChannel][ignoreId].name + "@" + ignoreId + "\n");
								else{
									var ignoredName = chatOpts.Ignored[ignoreId];
									appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + ignoredName + "@" + ignoreId + "\n");
								}
							}
							appendText("</font>", true);
						}
						
						groups = line.match(/^\/notifications/);
						if (groups){
							showUserNotifications = !showUserNotifications;
							chatOpts.ShowUserNotifications = (showUserNotifications) ? "1" : "0";
							var shown = (showUserNotifications) ? "shown" : "hidden";
							saveChatOpts();
							appendText("<font size='12' color='#FFFFFF'>User Notifications now " + shown + "</font>", true);
						}
						break;
				}
				
				/*groups = line.match(/^\/test (.+)/);
				if (groups){
					str = line.substring(6);
					//steam://connect/<IP>[:port]
					lx.SetupLink(str);
					//ret = splitInputMessage(str);
					//trace((new JSONEncoder(ret)).getString());
					//appendText('<IMG SRC="img://(A:36:' + groups[1] + ':100:0)resource/flash3/images/emoticons/dchorse.png" WIDTH="30" HEIGHT="30" ALIGN="baseline"/>');
					//appendText('<font size="16"><IMG SRC="img://(A:21:26816:100:0)resource/flash3/images/emoticons/sad.png" WIDTH="18" HEIGHT="18" ALIGN="baseline"></font>');
				}*/
				
				
				
				if (obj != null)
					mgs.writeJSON(obj, type);
			}
			else{
			  obj = {type:"msg", fromUser:this.id, toChannel:curChannel, msg:line};
			  type = MGSocket.GAME_JSON;
			  mgs.writeJSON(obj, type);
			  
			  var date = getTimeString();
			  var from = getUserString(id);
			  var text = " <font size='14'>" + escapeTags(line) + " </font>\n";
			  appendText(date + from + text, true);
			}

			
		}
		
		public function connect(){
			if (mgs != null)
				mgs.close();
			
			this.id = int(Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.steamIDNumber.text);
			this.userName = Globals.instance.Loader_profile_mini.movieClip.ProfileMini_main.ProfileMini.Persona.Player.PlayerNameIngame.text;
			
			if (this.id == 0){
				appendText("<I><font color='#FFFFFF' size='14'>Unable to connect to server... Please try again.</font></I>", true);
				return;
			}
			mgs = new MGSocket();		
			
			mgs.connect(connectionIP, 7123, id, userName, Number(lx.version), authToken);
			authed = false;
			role = MGSocket.ROLE_USER;
			
			mgs.addEventListener(MGEvent.JSON, onJson);
			mgs.addEventListener(MGEvent.BINARY, onBinary);
			mgs.addEventListener(MGEvent.ERROR, onError);
			mgs.addEventListener(MGEvent.CLOSED, onClosed);
			mgs.addEventListener(Event.CONNECT, onConnected);
			mgs.addEventListener(MGEvent.USER_DISCONNECTED, onUserDisconnected);
			mgs.addEventListener(MGEvent.USER_JOINCHANNEL, onUserJoinChannel);
			mgs.addEventListener(MGEvent.USER_LEAVECHANNEL, onUserLeaveChannel);
			mgs.addEventListener(MGEvent.AUTH_SUCCESS, onAuthSuccess);
			mgs.addEventListener(MGEvent.ROLE_CHANGE, onRoleChange);
			
			appendText("<I><font color='#FFFFFF' size='14'>Connecting to server...</font></I>", true);
			
			timeoutTimer = new Timer(CONN_TIMEOUT, 1);
			timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, connectionTimeout);
			timeoutTimer.start();
		}
		
		private function connectionTimeout(e:TimerEvent){
			appendText("<I><font color='#FFFFFF' size='14'>Connection timed out.  The server may be down or unreachable currently.</font></I>", true);
			
			try{
				mgs.close();
			}catch(e:Error){trace(e);}
			
			roster.taChat.htmlText = "";
			
			mgs = null;
		}
		
		private function checkBatcher(){
			var now:Number = new Date().time;
			if (now > (lastBatchTime + BATCH_TIMER * 6)){
				if (batchTimer != null){
					batchTimer.removeEventListener(TimerEvent.TIMER, batchText);
					batchTimer.stop();
					batchTimer = null;
				}
				
				batchTimer = new Timer(BATCH_TIMER, 0);
				batchTimer.addEventListener(TimerEvent.TIMER, batchText);
				batchTimer.start();
				
				batchCount = ROSTER_BATCH_COUNT - 1;
			}
		}
		
		private function onJson(e:MGEvent){
			var obj:Object = e.object;
			var type:uint = e.typeCode;
			checkBatcher();
			
			//history.taChat.htmlText += type + " -- " + json;
			
			if (obj.hasOwnProperty("type")){
				switch(obj.type){
					case "roster":
						channelRosterIds[curChannel] = obj.roster;
						channelRosterNames[curChannel] = {};
						var count = 0;
						for (var rosterid:String in obj.roster){
							fixUserNames(rosterid, obj.roster[rosterid]);
							count++;
						}
						
						participantsButton.label = String(count);
						
						rosterUnclean = true;
						//appendText((new JSONEncoder(channelRosterIds)).getString() + "\n");
						//appendText((new JSONEncoder(channelRosterNames)).getString() + "\n");
						break;
					case "msg":
						if (obj.hasOwnProperty("toUser")){
							var toUser = obj.toUser;
							if (chatOpts.Ignored && chatOpts.Ignored[obj.fromUser])
								return;
								
							if (toUser == id){
								appendText(getTimeString() + "<font color='#FF33CC' size='14'>[From " + getUserString(obj.fromUser, "") + "] " + escapeTags(obj.msg) + " </font>\n");
							}
						}
						else if (obj.hasOwnProperty("toChannel")){
							if (chatOpts.Ignored && chatOpts.Ignored[obj.fromUser])
								return;
								
							var toChannel = obj.toChannel;
							var colorStr = "";
							if (obj.msg.indexOf(userName) >= 0)
								colorStr = " color='#04CC00'";
								
							if (toChannel == curChannel){
								appendText(getTimeString() + getUserString(obj.fromUser) + " <font size='14'" + colorStr + ">" + escapeTags(obj.msg) + " </font>\n");
							}
						}
						break;
					case "whois":
						appendText("<font size='12' color='#FFFFFF'>&nbsp;&nbsp;Whois:</font><font size='10'>");
						for (var property in obj){
							if (property != "type")
								appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + property + ": " + fixedReplace(escapeTags(obj[property]), {" ":"&nbsp;"}) + "\n");
						}
						appendText("</font>", true);
						break;
					case "info":
						appendText("<B><font color='#FFFFFF' size='14'>" + escapeTags(obj.msg) + "</font></B>", true);
						break;
					case "joinLobby":
						if (obj.fromUser == lobbyLinkUser){
							lx.test2(null, obj.password);
						}
						break;
					case "newLobby":
						//{"type":"newLobby","toChannel":"home","lobby":37288,"fromUser":174613209,"modId":52,"workshopId":402418945,"name":"test","region":1,"hostname":"BMD","map":"couriermadness"}
						
						appendText("<A HREF='event:l" + obj.lobby + ":" + obj.fromUser + "'><font color='#00BFFF' size='14'><B>[</B></font><font color='#E18700' size='14'>" + lx.gmiToName[obj.workshopId] + "</font><font color='#00BFFF' size='14'><B>] </B>"
								   + fixedReplace(escapeTags(obj.name), {" ":"&nbsp;"}) + " <B>&lt;" + lx.lobbyRegionProvider.requestItemAt(obj.region).label + "&gt;</B>"
								   + " by </font><b><font color='#FFFFFF' size='14'>" + fixedReplace(escapeTags(obj.hostname), {" ":"&nbsp;"}) + "</font></b></A>");
						break;
					case "ipbanList":
						appendText("<font size='12' color='#FFFFFF'>&nbsp;&nbsp;IP Ban List:</font><font size='10'>");
						for (var ipban in obj.ipbanList){
							appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + ipban + " -- " + fixedReplace(escapeTags(obj.ipbanList[ipban]), {" ":"&nbsp;"}) + "\n");
						}
						appendText("</font>", true);
						break;
					case "banList":
						appendText("<font size='12' color='#FFFFFF'>&nbsp;&nbsp;Ban List:</font><font size='10'>");
						for (var ban in obj.banList){
							if (channelRosterIds[curChannel][ban])
								appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + fixedReplace(escapeTags(channelRosterIds[curChannel][ban].name), {" ":"&nbsp;"}) + "@" + ban + " - " + fixedReplace(escapeTags(obj.banList[ban]), {" ":"&nbsp;"}) + "\n");
							else{
								appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + ban + " - " + fixedReplace(escapeTags(obj.banList[ban]), {" ":"&nbsp;"}) + "\n");
							}
						}
						appendText("</font>", true);
						break;
					case "muteList":
						appendText("<font size='12' color='#FFFFFF'>&nbsp;&nbsp;Mute List:</font><font size='10'>");
						for (var mute in obj.muteList){
							if (channelRosterIds[curChannel][mute])
								appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + fixedReplace(escapeTags(channelRosterIds[curChannel][mute].name), {" ":"&nbsp;"}) + "@" + mute + " - " + fixedReplace(escapeTags(obj.muteList[mute]), {" ":"&nbsp;"}) + "\n");
							else{
								appendText("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + mute + " - " + fixedReplace(escapeTags(obj.muteList[mute]), {" ":"&nbsp;"}) + "\n");
							}
						}
						appendText("</font>", true);
						break;
					case "banUser":
						//channel:name, user:user.ID, byUser:byUser.ID, reason:reason, time:time
						var user = channelRosterIds[curChannel][obj.user];
						var reason = (obj.reason == "") ? "" : "(" + obj.reason + ")";
						
						appendText(getTimeString() +  "<b><font color='#E18700' size='14'>" + getUserString(obj.user, "") + " was <font color='#FF0000'>BANNED</font> by " + getUserString(obj.byUser, "")
								   + " for " + msToStringTime(obj.time) + " " + fixedReplace(escapeTags(reason), {" ":"&nbsp;"}) + "</font></b>", true);
						
						delete channelRosterIds[curChannel][obj.user];
						delete channelRosterNames[curChannel][user.name];
						
						participantsButton.label = String(Number(participantsButton.label) - 1)
						rosterUnclean = true;
						break;
					case "muteUser":
						//channel:name, user:user.ID, byUser:byUser.ID, reason:reason, time:time
						user = channelRosterIds[curChannel][obj.user];
						reason = (obj.reason == "") ? "" : "(" + obj.reason + ")";
						
						appendText(getTimeString() +  "<b><font color='#E18700' size='14'>" + getUserString(obj.user, "") + " was <font color='#00FF00'>MUTED</font>  by " + getUserString(obj.byUser, "")
								   + " for " + msToStringTime(obj.time) + " " + fixedReplace(escapeTags(reason), {" ":"&nbsp;"}) + "</font></b>", true);
						break;
					case "warnUser":
						//channel:name, user:user.ID, fromUser:fromUser.ID, reason:reason
						user = channelRosterIds[curChannel][obj.user];
						reason = (obj.reason == "") ? "" : "(" + obj.reason + ")";
						
						appendText(getTimeString() +  "<b><font color='#E18700' size='14'>" + getUserString(obj.user, "") + " was <font color='#A000A0'>WARNED</font>  by " + getUserString(obj.fromUser, " ")
								   + fixedReplace(escapeTags(reason), {" ":"&nbsp;"}) + "</font></b>", true);
						break;
					case "kickUser":
						///channel:name, user:user.ID, byUser:byUser.ID, reason:reason
						user = channelRosterIds[curChannel][obj.user];
						
						reason = (obj.reason == "") ? "" : "(" + obj.reason + ")";
						
						appendText(getTimeString() +  "<b><font color='#E18700' size='14'>" + getUserString(obj.user, "") + " was KICKED by " + getUserString(obj.byUser, " ")
								   + fixedReplace(escapeTags(reason), {" ":"&nbsp;"}) + "</font></b>", true);
						
						delete channelRosterIds[curChannel][obj.user];
						delete channelRosterNames[curChannel][user.name];
						
						participantsButton.label = String(Number(participantsButton.label) - 1)
						rosterUnclean = true;
						break;
				}
			}
			else{
				var json:String = (new JSONEncoder(obj)).getString();
				appendText("<B><font color='#AAAAAA' size='14'>Error: no 'type' -- " + escapeTags(json) + "</font></B>");
			}
			
		}
		
		private function onBinary(e:MGEvent){
			var ba:ByteArray = e.object as ByteArray;
			var type:uint = e.typeCode;
			
			lx.traceLX(type + " -- " + ba.length);
		}
		
		private function onError(e:MGEvent){
			var obj:Object = e.object;
			appendText("<B><font color='#FF0000' size='14'>Error: " + escapeTags(obj.error) + "</font></B>", true);
		}
		
		private function onClosed(e:MGEvent){
			if (timeoutTimer != null){
				timeoutTimer.stop();
				timeoutTimer = null;
			}
			var obj:Object = e.object;
			if (obj.hasOwnProperty("error"))
				appendText("<B><font color='#FF0000' size='14'>Error: " + escapeTags(obj.error) + "</font></B>");
			appendText("<B><font color='#FF0000' size='14'>Connection was closed.  Type \"<font color='#FFFFFF'>/connect</font>\" to reconnect.</font></B>", true);
			
			try{
				mgs.close();
			}catch(e:Error){trace(e);}
			
			roster.taChat.htmlText = "";
			participantsButton.label = "";
			
			mgs = null;
		}
		
		private function onUserDisconnected(e:MGEvent){
			var obj:Object = e.object;
			var user = channelRosterIds[curChannel][obj.fromUser];
			checkBatcher();
			
			var extra = "";
			if (role >= MGSocket.ROLE_MODERATOR)
				extra = "@" + obj.fromUser;
			
			if (showUserNotifications)
				appendText(getTimeString() +  "<i>" + getUserString(obj.fromUser, "") + extra + " <font size='10' color='#FFFFFF'>disconnected from the server.</font></i>");
									 
			delete channelRosterIds[curChannel][obj.fromUser];
			delete channelRosterNames[curChannel][user.name];
			
			participantsButton.label = String(Number(participantsButton.label) - 1)
			rosterUnclean = true;
		}
		
		private function onUserJoinChannel(e:MGEvent){
			var obj:Object = e.object;
			var user = {role:obj.role, name:obj.name};
			checkBatcher();
			
			var extra = "";
			if (role >= MGSocket.ROLE_MODERATOR)
				extra = "@" + obj.fromUser;
									 
			channelRosterIds[curChannel][obj.fromUser] = user;
			//channelRosterNames[curChannel][user.name] = obj.fromUser;
			fixUserNames(obj.fromUser, user);
			
			if (showUserNotifications)
				appendText(getTimeString() +  "<i>" + getUserString(obj.fromUser, "") + extra + " <font size='10' color='#FFFFFF'>joined the room.</font></i>");
			
			participantsButton.label = String(Number(participantsButton.label) + 1)
			rosterUnclean = true;
		}
		
		private function onUserLeaveChannel(e:MGEvent){
			var obj:Object = e.object;
			var user = channelRosterIds[curChannel][obj.fromUser];
			checkBatcher();
			
			var extra = "";
			if (role >= MGSocket.ROLE_MODERATOR)
				extra = "@" + obj.fromUser;
			
			if (showUserNotifications)
				appendText(getTimeString() + "<i>" + getUserString(obj.fromUser, "") + extra + " <font size='10' color='#FFFFFF'>left the room.</font></i>");
									 
			delete channelRosterIds[curChannel][obj.fromUser];
			delete channelRosterNames[curChannel][user.name];
			
			participantsButton.label = String(Number(participantsButton.label) - 1)
			rosterUnclean = true;
		}
		
				
		private function onAuthSuccess(e:MGEvent){
			appendText(getTimeString() + "<i><font size='14' color='#FFFFFF'>You successfully authenticated.</font></i>");
			authed = true;
		}
		
		private function onRoleChange(e:MGEvent){
			var obj:Object = e.object;
			var user = channelRosterIds[curChannel][obj.user];
									 
			if (channelRosterIds[curChannel][obj.user] != null)
				channelRosterIds[curChannel][obj.user].role = obj.role;
				
			if (obj.user == this.id)
				this.role = obj.role;
			
			rosterUnclean = true;
		}
		
		private function onConnected(e:Event){
			timeoutTimer.stop();
			timeoutTimer = null;
			
			mgs.writeJSON({type:"joinChannel", fromUser:id, channel:curChannel, name:userName}, MGSocket.SYSTEM_JSON);
			mgs.writeJSON({type:"getRoster", fromUser:id, channel:curChannel}, MGSocket.SYSTEM_JSON);
			
			appendText("<b><font color='#FFFFFF' size='14'>Connected! Type '/?' or '/help' to see commands.</font></b>", true);
		}
		
		public function close(){
			if (mgs != null){
				try{
					mgs.close();
				}catch(e:Error){trace(e);}
				
				mgs.removeEventListener(MGEvent.JSON, onJson);
				mgs.removeEventListener(MGEvent.BINARY, onBinary);
				mgs.removeEventListener(MGEvent.ERROR, onError);
				mgs.removeEventListener(MGEvent.CLOSED, onClosed);
				mgs.removeEventListener(Event.CONNECT, onConnected);
				mgs.removeEventListener(MGEvent.USER_DISCONNECTED, onUserDisconnected);
				mgs.removeEventListener(MGEvent.USER_JOINCHANNEL, onUserJoinChannel);
				mgs.removeEventListener(MGEvent.USER_LEAVECHANNEL, onUserLeaveChannel);
			}
			
			Globals.instance.Loader_top_bar.movieClip.removeChild(container);
			container.removeEventListener(MouseEvent.MOUSE_DOWN, handleDragDown);
			container.removeEventListener(MouseEvent.MOUSE_UP, handleDragUp);
			closeButton.removeEventListener(MouseEvent.CLICK, gameCloseClicked);
			
			batchTimer.removeEventListener(TimerEvent.TIMER, batchText);
			batchTimer.stop();
			
			lx.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyListener);
			
			participantsButton.label = "";
			mgs = null;
			authed = false;
			batchTimer = null;
		}
		
		private function caretToEnd(et:TimerEvent){
			input.textField.setSelection(input.textField.length, input.textField.length);
		}
		
		private function updateScrollBar(sb:*){
			sb.position = sb.position - 1;
			sb.position = sb.position + 1;
		}
		
		private function drawRoster(){
			var admins = "";
			var owners = "";
			var moderators = "";
			var users = "";
			
			if (!rosterShown || !rosterUnclean)
				return;
			
			rosterUnclean = false;
			var a:Array = new Array();
			for (var key:String in channelRosterNames[curChannel]){
				a.push(key);
			}
			a.sort();
			
			for (var index in a){
				var id = channelRosterNames[curChannel][a[index]];
				var user = channelRosterIds[curChannel][id];
				switch(user.role){
					case MGSocket.ROLE_USER:
						users += "<font color='#FFFFFF' size='10'><A HREF='event:a" + id + "'><B>" + escapeTags(user.name) + "</B></A></font>\n";
						break;
					case MGSocket.ROLE_MODERATOR:
						moderators += "<font color='#33CC33' size='10'><A HREF='event:a" + id + "'><B>" + escapeTags(user.name) + "</B></A></font>\n";
						break;
					case MGSocket.ROLE_OWNER:
						owners += "<font color='#8855EE' size='10'><A HREF='event:a" + id + "'><B>" + escapeTags(user.name) + "</B></A></font>\n";
						break;
					case MGSocket.ROLE_ADMIN:
						admins += "<font color='#FFD700' size='10'><A HREF='event:a" + id + "'><B>" + escapeTags(user.name) + "</B></A></font>\n";
						break;
				}
			}
			
			//trace("ROSTER DRAW");
			//trace(admins + owners + moderators + users);
			roster.taChat.htmlText = admins + owners + moderators + users;
		}
		
		private function escapeTags(str:String):String{
			//return str.replace(/&/g, "&amp;").replace(/>/g, "&gt;").replace(/</g, "&lt;");
			return fixedReplace(str, {"&":"&amp;", "<":"&lt;", ">":"&gt;"});
		}
		
		private function fixedReplace(str:String, repl:Object):String{
			var result = "";
			var sectionStart = 0;
			var current = 0;
			while (current != str.length){
				var c = str.charAt(current);
				var replace = repl[c];
				
				if (replace != null){
					result += str.substring(sectionStart, current) + replace;
					sectionStart = current+1;
				}
				
				current++;
			}
			
			result += str.substring(sectionStart);
			
			return result;
		}
		
		private function getTimeString():String{
			var now:Date = new Date();
			var ds:String = String(now.hours);
			if (now.hours < 10)
				ds = "0" + ds;
			ds += ":";
			if (now.minutes < 10)
				ds += "0";
			ds += now.minutes + ":";
			
			return "<font size='8' color='#aaaaaa'>" + ds + "</font> ";
		}
		
		private function getUserString(userID:Number, append:String = ":"):String{
			var user = channelRosterIds[curChannel][userID];
			if (append == " ")
				append = "&nbsp;"
			if (user == null)
				return "<font size='14' color='#FFFFFF'><A HREF=''>null</A>:</font> ";
			else{
				var color:String = getRoleColor(user.role);
				//var color:String = getRoleColor(Math.floor(Math.random() * (1 + MGSocket.ROLE_ADMIN)));
				
				return "<font size='14' color='" + color + "'><A HREF='event:a" + userID + "'><B>" + fixedReplace(escapeTags(user.name), {" ":"&nbsp;"}) + "</B></A>" + append + "</font>";
			}
		}
		
		private function getRoleColor(role:Number):String{
			var color:String = "#FFFFFF";
			switch(role){
				case MGSocket.ROLE_USER:
					color = "#FFFFFF";
					break;
				case MGSocket.ROLE_MODERATOR:
					color = "#33CC33";
					break;
				case MGSocket.ROLE_OWNER:
					color = "#8855EE";
					break;
				case MGSocket.ROLE_ADMIN:
					color = "#FFD700";
					break;
			}
			
			return color;
		}
		
		private function fixUserNames(id, user){
			if (channelRosterNames[curChannel][user.name] == null){
				channelRosterNames[curChannel][user.name] = id;
				return;
			}
			
			var curUserId = channelRosterNames[curChannel][user.name];
			var curUser = channelRosterIds[curChannel][curUserId];
			/*if (user.role > curUser.role){
				curUser.name += "-";
				fixUserNames(curUserId, curUser);
				return;
			}*/
			
			user.name += "-";
			fixUserNames(id, user);
		}
		
		private function inputToEnd(){
			var timer:Timer = new Timer(10, 1);
			timer.addEventListener(TimerEvent.TIMER, caretToEnd);
			timer.start();
		}
		
		private function saveChatOpts(){
			Globals.instance.GameInterface.SaveKVFile(lx.lxOptions, 'resource/flash3/options.kv', 'Options');
		}
		
		private function getTimeDelta(str:String):*{
			var groups = str.toLowerCase().match(/(\d+)(s|m|h|d)/);
			if (!groups)
				return null;
			
			var val = Number(groups[1]);
			switch(groups[2]){
				case "s":
					val *= 1000;
					break;
				case "m":
					val *= 1000 * 60;
					break;
				case "h":
					val *= 1000 * 60 * 60;
					break;
				case "d":
					val *= 1000 * 60 * 60 * 24;
					break;
			}
			
			return val;
		}
		
		private function msToStringTime(ms):String{
			var unit = " seconds";
			ms /= 1000;
			if (ms > 60){
				unit = " minutes";
				ms /= 60;
				if (ms > 60){
					unit = " hours";
					ms /= 60;
					if (ms > 24){
						unit = " days";
						ms /= 24;
						if (ms > 365){
							unit = " years";
							ms /= 365;
						}
					}
				}
			}
		
			ms = Math.floor(ms * 100) / 100.0;
			if (ms == 1.00)
				return ms + unit.substr(0, unit.length - 1);
			return ms + unit;
		}
		
		private function splitInputMessage(str:String):Object{
			var user;
			var msg;
			var replace;
			if (str.charAt(0) == '"'){
				// quoted name
				var end = 1;
				var found = false;
				var escape = false;
				while (end != str.length){
					var c = str.charAt(end);
					if (escape){
						escape = false;
					}
					else if (c == "\\"){
						escape = true;
					}
					else if (c == "\""){
						found = true;
						break;
					}
					end++;
				}
				if (!found){
					user = str.substr(1);
					msg = "";
					replace = "\"" + user + "\" ";
				}
				else{
					replace = "\"" + str.substring(1,end) + "\" ";
					user = "";
					escape = false;
					for (var i=1; i<end; i++){
						var ch = str.charAt(i);
						if (escape){
							escape = false;
							if (ch != "\"" && ch != "\\")
								user += ch;
						}
						else if (ch == "\\"){
							escape = true;
							continue;
						}
						user += ch;
					}
					//user = str.substr(1, end - 1).replace(/\\/g, "\\").replace(/\\"/g, "\"");
					msg = str.substr(end + 1);
					if (msg.charAt(0) == ' ')
						msg = msg.substr(1);
				}
			}
			else{
				if (str.indexOf(" ") > 0){
					user = str.substr(0, str.indexOf(" "));
					msg = str.substr(str.indexOf(" ") + 1);
				}
				else{
					user = str;
					msg = "";
				}
				
				replace = user + " ";
			}

			trace("user: " + user + " -- msg: " + msg + " -- replace: " + replace);
			return {user:user, msg:msg, replace:replace};
		}
		
		public function resizeWindow(wid:Number = -1, hei:Number = -1) : void {
			/*if (wid == -1)
				wid = minigame.width;
			if (hei == -1)
				hei = minigame.height;*/
			panel.width = wid + 15;
			panel.height = hei + 15;
			
			indent.width = wid + 14;
			
			outer.height = hei + 45;
			outer.width = wid + 18;
			
			title.width = wid + 18;
			
			closeButton.x = wid + 12;
			participantsButton.x = closeButton.x - participantsButton.width - 10;
			
			inputBG.width = wid - 25;
			inputBG.y = hei - 30;
			
			input.y = inputBG.y;
			input.width = inputBG.width - 20;
			
			historyBG.width = wid - rosterBG.width * ((rosterShown) ? 1 : 0);
			historyBG.height = hei - inputBG.height;
			
			history.taChat.width = historyBG.width - 16 - history.sb.width;
			history.sb.x = historyBG.width - 2 - history.sb.width;
			history.sb.height = historyBG.height - 4;
			history.taChat.height = historyBG.height - 4;	
			
			rosterBG.x = historyBG.x + historyBG.width + 5;
			rosterBG.height = historyBG.height;
			
			roster.x = rosterBG.x + 4;
			roster.sb.height = rosterBG.height - 4;
			roster.taChat.height = rosterBG.height - 4;	
			
			roster.taChat.mask.height = roster.taChat.height;
			
			resizeClip.x = wid + 12;
			resizeClip.y = hei + 8;
			
			updateScrollBar(history.sb);
			updateScrollBar(roster.sb);
		}
	}
	
}
