//
// $Id$

package popcraft {

import com.threerings.flashbang.*;
import com.threerings.flashbang.resource.*;
import com.threerings.flashbang.util.Rand;
import com.threerings.ui.KeyboardCodes;
import com.threerings.util.EventHandlerManager;
import com.threerings.util.Log;
import com.whirled.game.GameContentEvent;
import com.whirled.game.GameControl;
import com.whirled.game.SizeChangedEvent;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.errors.IllegalOperationError;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Timer;

import popcraft.gamedata.*;
import popcraft.game.*;
import popcraft.game.mpbattle.*;
import popcraft.game.story.*;
import popcraft.net.*;
import popcraft.ui.*;
import popcraft.util.*;

[SWF(width="700", height="500", frameRate="30")]
public class PopCraft extends Sprite
{
    public static var log :Log = Log.getLog(PopCraft);

    public function PopCraft ()
    {
        // Enforce specification of the random stream we're using to prevent sync errors
        Rand.errorOnUnspecifiedStreamId = true;

        ClientCtx.mainSprite = this;

        // setup GameControl
        ClientCtx.gameCtrl = new GameControl(this, false);
        var isConnected :Boolean = ClientCtx.gameCtrl.isConnected();

        ClientCtx.seatingMgr.init(ClientCtx.gameCtrl);
        ClientCtx.lobbyConfig.init(ClientCtx.gameCtrl, ClientCtx.seatingMgr);

        _events.registerListener(this, Event.REMOVED_FROM_STAGE, onQuit);

        // draw a black background
        var g :Graphics = this.graphics;
        g.beginFill(0);
        g.drawRect(0, 0, Constants.SCREEN_SIZE.x, Constants.SCREEN_SIZE.y);
        g.endFill();

        // set a clip rect
        this.scrollRect = new Rectangle(0, 0, Constants.SCREEN_SIZE.x, Constants.SCREEN_SIZE.y);

        // setup simplegame
        _sg = new FlashbangApp(new Config());

        ClientCtx.mainLoop = _sg.ctx.mainLoop;
        ClientCtx.rsrcs = _sg.ctx.rsrcs;
        ClientCtx.audio = _sg.ctx.audio;

        // custom resource factories
        ClientCtx.rsrcs.registerResourceType(Constants.RESTYPE_LEVEL, LevelResource);
        ClientCtx.rsrcs.registerResourceType(Constants.RESTYPE_ENDLESS, EndlessLevelResource);
        ClientCtx.rsrcs.registerResourceType(Constants.RESTYPE_GAMEDATA, GameDataResource);
        ClientCtx.rsrcs.registerResourceType(Constants.RESTYPE_GAMEVARIANTS, GameVariantsResource);

        // sound volume
        ClientCtx.audio.masterControls.volume(
            Constants.DEBUG_DISABLE_AUDIO ? 0 : Constants.SOUND_MASTER_VOLUME);

        // create a new random stream for the puzzle
        ClientCtx.randStreamPuzzle = Rand.addStream();

        // init the cookie manager
        ClientCtx.userCookieMgr = new UserCookieManager(Constants.USER_COOKIE_VERSION);
        ClientCtx.userCookieMgr.addDataSource(ClientCtx.levelMgr);
        ClientCtx.userCookieMgr.addDataSource(ClientCtx.globalPlayerStats);
        ClientCtx.userCookieMgr.addDataSource(ClientCtx.endlessLevelMgr);
        ClientCtx.userCookieMgr.addDataSource(ClientCtx.prizeMgr);
        ClientCtx.userCookieMgr.addDataSource(ClientCtx.savedPlayerBits);

        if (ClientCtx.gameCtrl.isConnected()) {
            // if we're connected to Whirled, keep the game centered and draw a pretty
            // tiled background behind it
            _events.registerListener(ClientCtx.gameCtrl.local, SizeChangedEvent.SIZE_CHANGED,
                handleSizeChanged)

            handleSizeChanged();

            // and don't show the "rematch" button - we have a UI for it in-game
            // (This is now no longer in the API)
            //ClientCtx.gameCtrl.local.setShowReplay(false);

            // get level packs
            ClientCtx.reloadLevelPacks();

            // TEMP: remove me soon - player level packs don't seem to be available
            // immediately after the game starts; wait a few seconds to ask for them.
            var lpTimer :Timer = new Timer(3000, 1);
            lpTimer.addEventListener(TimerEvent.TIMER,
                function (...ignored) :void {
                    ClientCtx.reloadLevelPacks();
                });
            lpTimer.start();

            // if the player purchases level packs while the game is in progress, update our
            // level packs
            _events.registerListener(
                ClientCtx.gameCtrl.player,
                GameContentEvent.PLAYER_CONTENT_ADDED,
                function (...ignored) :void {
                    ClientCtx.reloadLevelPacks();
                },
                false,
                int.MAX_VALUE);
        }

        var keyDispatcher :IEventDispatcher = (isConnected ? ClientCtx.gameCtrl.local : this.stage);
        _sg.run(this, keyDispatcher);

        // Before we kick off our loading mode, we need to load an initial set of resources
        // required to actually show the loading screen.
        Resources.loadInitialResources(
            function () :void {
                ClientCtx.mainLoop.unwindToMode(new LoadingMode());
            },
            function (loadErr :String) :void {
                ClientCtx.mainLoop.unwindToMode(new GenericLoadErrorMode(loadErr));
            });

        _events.registerListener(keyDispatcher, KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    protected function onKeyDown (e :KeyboardEvent) :void
    {
        if (Constants.DEBUG_ALLOW_CHEATS) {
            switch (e.keyCode) {
            case KeyboardCodes.NUMBER_7:
                debugGrantLevelPack(Constants.ACADEMY_LEVEL_PACK_NAME);
                break;

            case KeyboardCodes.NUMBER_8:
                debugGrantLevelPack(Constants.INCIDENT_LEVEL_PACK_NAME);
                break;
            }
        }
    }

    protected function debugGrantLevelPack (levelPackName :String) :void
    {
        // For debug purposes only. Pretend that the player just bought a premium level pack.
        var levelPacks :Array = (ClientCtx.gameCtrl.isConnected() ?
                                 ClientCtx.gameCtrl.player.getPlayerItemPacks().slice() : []);
        levelPacks.push({ ident:levelPackName, name:levelPackName, mediaURL:"", premium:true });
        ClientCtx.playerLevelPacks.init(levelPacks);
        try {
            ClientCtx.gameCtrl.player.dispatchEvent(
                new GameContentEvent(
                    GameContentEvent.PLAYER_CONTENT_ADDED,
                    GameContentEvent.LEVEL_PACK,
                    levelPackName));
        } catch (e :IllegalOperationError) {
            // An unmodified AbstractControl.as will throw an error if anyone else
            // calls dispatchEvent on it. For this code to work, modify your copy of
            // AbstractControl and recompile.
        }
    }

    protected function handleSizeChanged (...ignored) :void
    {
        var size :Point = ClientCtx.gameCtrl.local.getSize();
        ClientCtx.mainSprite.x = (size.x * 0.5) - (Constants.SCREEN_SIZE.x * 0.5);
        ClientCtx.mainSprite.y = (size.y * 0.5) - (Constants.SCREEN_SIZE.y * 0.5);
    }

    protected function onQuit (...ignored) :void
    {
        _events.freeAllHandlers();
        _sg.shutdown();
    }

    public function loadResources (completeCallback :Function, errorCallback :Function) :void
    {
        function loadSingleOrMultiplayerResources () :void {
            if (Resources.queueLevelPackResources(ClientCtx.isMultiplayer ?
                Resources.MP_LEVEL_PACK_RESOURCES :
                Resources.SP_LEVEL_PACK_RESOURCES)) {
                ClientCtx.rsrcs.loadQueuedResources(completeCallback, errorCallback);

            } else {
                completeCallback();
            }
        }

        Resources.loadBaseResources(loadSingleOrMultiplayerResources, errorCallback);
    }

    protected var _events :EventHandlerManager = new EventHandlerManager();
    protected var _sg :FlashbangApp;
}

}

import popcraft.*;
import popcraft.game.*;
import popcraft.ui.GenericLoadingMode;

import com.threerings.flashbang.resource.ResourceManager;
import popcraft.ui.GenericLoadErrorMode;
import com.threerings.flashbang.util.Rand;
import popcraft.game.endless.SavedEndlessGame;
import popcraft.lobby.MultiplayerLobbyMode;

class LoadingMode extends GenericLoadingMode
{
    override protected function setup () :void
    {
        _loadingResources = true;
        ClientCtx.userCookieMgr.readCookie();
        ClientCtx.mainSprite.loadResources(resourceLoadComplete, onLoadError);
    }

    override public function update (dt :Number) :void
    {
        super.update(dt);

        _elapsedTime += dt;
        if (Constants.DEBUG_EXTEND_LOAD_SEQUENCE && _elapsedTime < EXTENDED_LOADING_TIME) {
            return;
        }

        if (!_loadingResources && !ClientCtx.userCookieMgr.isLoadingCookie) {
            if (ClientCtx.seatingMgr.allPlayersPresent) {
                startGame();
            } else {
                this.loadingText = "Waiting for players";
            }
        }
    }

    protected function startGame () :void
    {
        if (ClientCtx.isMultiplayer) {
            ClientCtx.mainLoop.unwindToMode(new MultiplayerLobbyMode());
        } else {
            MainMenuMode.create();
        }

        // award the player any prizes they haven't gotten yet
        ClientCtx.prizeMgr.checkPrizes();
    }

    protected function resourceLoadComplete () :void
    {
        _loadingResources = false;
    }

    protected function onLoadError (err :String) :void
    {
        ClientCtx.mainLoop.unwindToMode(new GenericLoadErrorMode(err));
    }

    protected var _loadingResources :Boolean;
    protected var _elapsedTime :Number = 0;

    protected static const EXTENDED_LOADING_TIME :Number = 3;
}
