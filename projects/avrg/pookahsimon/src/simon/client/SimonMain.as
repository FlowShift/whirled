//
// $Id$

package simon.client {

import com.threerings.util.Log;
import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGameControl;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.contrib.simplegame.Config;
import com.whirled.contrib.simplegame.MainLoop;
import com.whirled.contrib.simplegame.SimpleGame;

import flash.display.Sprite;
import flash.events.Event;

import simon.data.Constants;

[SWF(width="700", height="500")]
public class SimonMain extends Sprite
{
    public static var log :Log = Log.getLog("simon");

    public static var control :AVRGameControl;
    public static var model :Model;

    public static var localPlayerId :int;

    public static function get localPlayerName () :String
    {
        return SimonMain.getPlayerName(localPlayerId);
    }

    public static function quit () :void
    {
        if (control.isConnected()) {
            control.player.setAvatarState("Default");
            control.player.deactivateGame();
        }
    }

    public function SimonMain ()
    {
        log.info("Simon verson " + Constants.VERSION);

        addEventListener(Event.ADDED_TO_STAGE, handleAdded);
        addEventListener(Event.REMOVED_FROM_STAGE, handleUnload);

        // instantiate MainLoop singleton
        var config :Config = new Config();
        config.hostSprite = this;
        _sg = new SimpleGame(config);
        ClientCtx.mainLoop = _sg.ctx.mainLoop;
        ClientCtx.rsrcs = _sg.ctx.rsrcs;
        ClientCtx.audio = _sg.ctx.audio;

        // load resources
        Resources.load(handleResourcesLoaded, handleResourceLoadError);

        // hook up controller
        control = new AVRGameControl(this);
        control.player.addEventListener(AVRGamePlayerEvent.ENTERED_ROOM, enteredRoom);
        control.player.addEventListener(AVRGamePlayerEvent.LEFT_ROOM, leftRoom);

        log = Log.getLog("simon.client (" + control.player.getPlayerId() + ")");
        Model.log = log;
    }

    protected function handleResourcesLoaded () :void
    {
        log.info("Resources loaded");
        _resourcesLoaded = true;
        this.maybeBeginGame();
    }

    protected function handleResourceLoadError (err :String) :void
    {
        log.warning("Resource load error: " + err);
    }

    protected function maybeBeginGame () :void
    {
        if (_addedToStage && _resourcesLoaded && _enteredRoom) {
            model.setup();

            control.agent.sendMessage(Constants.MSG_PLAYERREADY);

            _sg.run();
            ClientCtx.mainLoop.pushMode(new GameMode());
        }
    }

    public static function getPlayerName (playerId :int) :String
    {
        if (control.isConnected()) {
            var avatar :AVRGameAvatar = control.room.getAvatarInfo(playerId);
            if (null != avatar) {
                return avatar.name;
            }
        }

        return "player " + playerId.toString();
    }

    protected function handleAdded (event :Event) :void
    {
        log.info("Added to stage: Initializing...");

        log.info(control.isConnected() ? "playing online game" : "playing offline game");

        model = new Model();

        // TODO: formalize initialization?
        localPlayerId = (control.isConnected() ? control.player.getPlayerId() : 666);

        _addedToStage = true;

        this.maybeBeginGame();
    }

    protected function handleUnload (event :Event) :void
    {
        log.info("Removed from stage - Unloading...");

        model.destroy();

        _sg.shutdown();
    }

    protected function enteredRoom (e :AVRGamePlayerEvent) :void
    {
        log.info("Entered room");
        _enteredRoom = true;
        maybeBeginGame();
    }

    protected function leftRoom (e :AVRGamePlayerEvent) :void
    {
        log.info("left room");
        if (control.isConnected()) {
            // Just set the avatar state, the server will deactivate us
            control.player.setAvatarState("Default");
        }

        // TODO: hide ui
    }

    protected var _sg :SimpleGame;
    protected var _addedToStage :Boolean;
    protected var _resourcesLoaded :Boolean;
    protected var _enteredRoom :Boolean;
}

}
