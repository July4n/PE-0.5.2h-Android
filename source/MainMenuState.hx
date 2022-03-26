package;

import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
//import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.4.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<Alphabet>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = ['story_mode', 'freeplay', #if MODS_ALLOWED 'mods', #end, 'credits', 'options'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	override public function create():Void
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		//add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		//add(magenta);
		magenta.scrollFactor.set();

		var bob:FlxSprite = new FlxSprite();
		bob.frames = Paths.getSparrowAtlas('menubob');
		bob.animation.addByPrefix('bop', 'bobmenu', 24, true);
		bob.animation.play('bop');
		bob.updateHitbox();
		bob.screenCenter(X);
		add(bob);

		menuItems = new FlxTypedGroup<Alphabet>();
		add(menuItems);

		for (i in 0...optionShit.length) 
		{
			var newAlphabet:Alphabet = new Alphabet(0, 0, optionShit[i], true, false);
			newAlphabet.screenCenter();
			newAlphabet.x = 35;
			newAlphabet.y += (110 * (i - (optionShit.length / 2))) + 50;
			newAlphabet.alpha = 0.6;
			newAlphabet.ID = i;
			menuItems.add(newAlphabet);
		}

		menuItems.members[curSelected].alpha = 1;

		FlxG.camera.follow(camFollowPos, null, 1);


		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "The bob ass pack", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		changeItem();

		updateSelection();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

                #if android
	        addVirtualPad(UP_DOWN, A_B);
                #end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;
	var lastCurSelected:Int = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		//var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);
		//camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				//FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				//FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
                                if (optionShit[curSelected] == 'discord')
				{
					//if (ClientPrefs.flashing)
						//FlxFlicker.flicker(magenta, 1.1, 0.15, false);
					FlxG.sound.play(Paths.sound('confirmMenuBell'));
					CoolUtil.browserLoad('https://docs.google.com/document/d/19W-9DXnepN11LwaYJAbg8pZFZigrWRrJl5RoOtx6Oyo/edit');
					//FlxG.camera.flash(0xFF9271fd, 1.6);
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenuBell'));

					//if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:Alphabet)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[Math.floor(curSelected)];

								switch (daChoice)
								{
									case 'story_mode':
										//FlxG.camera.fade(0xFFf9cf4f, 1.6, false);
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										//FlxG.camera.fade(0xFF9271fd, 1.6, false);
										MusicBeatState.switchState(new FreeplayState());
                                                                        #if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										//FlxG.camera.fade(0xFFf9cf4f, 1.6, false);
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										//FlxG.camera.fade(0xFFe0e0e0, 1.6, false);
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										//FlxG.camera.fade(0xFFfd719b, 1.6, false);
										MusicBeatState.switchState(new OptionsState());
								}
							});
						}
					});
				}
			}
			else if (FlxG.keys.anyJustPressed(debugKeys) #if android || _virtualpad.buttonE.justPressed #end)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

	}

	function changeItem(huh:Int = 0) 
	{
		curSelected += huh;
		if (curSelected < 0)
			curSelected = optionShit.length - 1;
		if (curSelected >= optionShit.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in menuItems.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}

	private function updateSelection()
	{
		// reset all selections
		menuItems.forEach(function(spr:FlxSprite) {spr.alpha = 0.6;});
		
		// set the sprites and all of the current selection
		menuItems.members[curSelected].alpha = 1;
		lastCurSelected = Math.floor(curSelected);
	}
}
