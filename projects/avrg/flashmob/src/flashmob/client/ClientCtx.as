package flashmob.client {

import com.whirled.avrg.*;
import com.whirled.contrib.simplegame.MainLoop;
import com.whirled.contrib.simplegame.audio.AudioManager;
import com.whirled.contrib.simplegame.resource.ResourceManager;

import flash.utils.getTimer;

import flashmob.*;
import flashmob.client.view.BasicYesNoMode;
import flashmob.client.view.GameUIView;
import flashmob.client.view.HitTester;
import flashmob.data.*;
import flashmob.party.*;

public class ClientCtx
{
    public static var mainLoop :MainLoop;
    public static var rsrcs :ResourceManager;
    public static var audio :AudioManager;
    public static var gameCtrl :AVRGameControl;
    public static var localPlayerId :int;
    public static var isPartied :Boolean;
    public static var partyInfo :PartyInfo = new PartyInfo();
    public static var players :PlayerSet;
    public static var inMsg :PartyMsgReceiver;
    public static var outMsg :PartyMsgSender;
    public static var props :PartyPropGetControl;
    public static var spectacle :Spectacle;
    public static var hitTester :HitTester;
    public static var gameUIView :GameUIView;
    public static var avatarMonitor :AvatarMonitor;
    public static var roomBoundsMonitor :RoomBoundsMonitor;

    public static function get localPlayerIndex () :int
    {
        for (var ii :int = 0; ii < players.players.length; ++ii) {
            var playerInfo :PlayerInfo = players.players[ii];
            if (playerInfo.id == localPlayerId) {
                return ii;
            }
        }

        return -1;
    }

    public static function sendAgentMsg (name :String, value :Object = null) :void
    {
        outMsg.sendMessage(name, value);
    }

    public static function get timeNow () :Number
    {
        return flash.utils.getTimer() / 1000;
    }

    public static function getAvatarInfo (playerId :int) :AVRGameAvatar
    {
        return gameCtrl.room.getAvatarInfo(playerId);
    }

    public static function get isPartyLeader () :Boolean
    {
        return (partyInfo != null && partyInfo.leaderId == localPlayerId);
    }

    public static function confirmQuit () :void
    {
        mainLoop.pushMode(new BasicYesNoMode(QUIT_TEXT, quit, mainLoop.popMode));
    }

    public static function quit () :void
    {
        if (gameCtrl.isConnected()) {
            gameCtrl.player.deactivateGame();
        }
    }

    protected static const QUIT_TEXT :String = "If you leave now, you'll cancel the spectacle " +
        "for the entire party! Are you sure?"
}

}
