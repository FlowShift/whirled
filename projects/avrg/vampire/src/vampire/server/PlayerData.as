package vampire.server
{

import com.threerings.util.ArrayUtil;
import com.threerings.util.ClassUtil;
import com.threerings.util.Hashable;
import com.threerings.util.Log;
import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.avrg.OfflinePlayerPropertyControl;
import com.whirled.avrg.PlayerSubControlBase;
import com.whirled.avrg.PlayerSubControlServer;
import com.threerings.util.EventHandlerManager;
import com.threerings.flashbang.ObjectMessage;

import flash.utils.ByteArray;

import vampire.Util;
import vampire.data.Codes;
import vampire.data.Logic;
import vampire.data.VConstants;


/**
 * Handles data persistance and event handling, such as listening to enter room events.
 * Current state data is persisted into player and room props on update().  This is called from the
 * VServer a few times per second, reducing unnecessary network traffic.
 *
 */
public class PlayerData extends EventHandlerManager
    implements Hashable
{
    public function PlayerData (ctrl :PlayerSubControlBase)
    {
        if (ctrl == null) {
            log.error("Bad! PlayerData(null).  What happened to the PlayerSubControlServer?  Expect random failures everywhere.");
            return;
        }

        _ctrl = ctrl;
        _playerId = ctrl.getPlayerId();

        log.info("Logging in", "playerId", playerId, "_ctrl.props.get(Codes.PLAYER_PROP_NAME)", _ctrl.props.get(Codes.PLAYER_PROP_NAME));

        registerListener(_ctrl, AVRGamePlayerEvent.ENTERED_ROOM, enteredRoom);
        registerListener(_ctrl, AVRGamePlayerEvent.LEFT_ROOM, leftRoom);
//        registerListener(_ctrl, AVRGamePlayerEvent.TASK_COMPLETED, handleTaskCompleted);


        if (isNaN(xp)) {
            xp = 0;
        }

        //Make sure we are not over the limit, due to changing level requirements.
        if (xp > Logic.maxXPGivenXPAndInvites(xp, invites)) {
            xp = Logic.maxXPGivenXPAndInvites(xp, invites);
        }

        //Better empty than null
        if (progenyIds == null) {
            progenyIds = [];
        }



        log.info("Logging in", "playerId", playerId,
                "name", name,
                "_ctrl.getPlayerName()", _ctrl.getPlayerName(),
                "_ctrl.props.get(Codes.PLAYER_PROP_NAME)", _ctrl.props.get(Codes.PLAYER_PROP_NAME),
                "xp",  xp,
                "level", level,
                "sire", sire,
                "progeny", progenyIds,
                "bloodbond", bloodbond,
                "bloodbondName", bloodbondName
                );

        Trophies.checkMinionTrophies(this);
        Trophies.checkInviteTrophies(this);
    }

//    protected function handleTaskCompleted (e :AVRGamePlayerEvent) :void
//    {
//        log.debug("handleTaskCompleted", "e", e);
//        switch (e.name) {
//            case Codes.TASK_FEEDING:
//            var coins :int = e.value as int;
//            //Notify the analyser
//            ServerContext.server.sendMessageToNamedObject(
//                new ObjectMessage(AnalyserServer.MSG_RECEIVED_FEEDING_COINS_PAYOUT, [playerId, coins]),
//                AnalyserServer.NAME);
//            break;
//        }
//    }

    public function get feedingData () :ByteArray
    {
        return _ctrl.props.get(Codes.PLAYER_PROP_FEEDING_DATA) as ByteArray;
    }

    public function get lineage () :ByteArray
    {
        return _lineage;
    }

    public function set lineage (b :ByteArray) :void
    {
        _lineage = b;
    }

    public function addFeedback (msg :String, priority :int = 1) :void
    {
        ServerContext.feedback.addFeedback(msg, playerId, priority);
    }

    public function get ctrl () :PlayerSubControlBase
    {
        return _ctrl;
    }

    /**
    * For debugging purposes have both sctrl and ctrl.
    * That way I can run PlayerData instances on the client for testing.
    */
    public function get sctrl () :PlayerSubControlServer
    {
        return _ctrl as PlayerSubControlServer;
    }

    public function get playerId () :int
    {
        return _playerId;
    }

    public function equals (other :Object) :Boolean
    {
        if (this == other) {
            return true;
        }
        if (other == null || !ClassUtil.isSameClass(this, other)) {
            return false;
        }
        return PlayerData(other).playerId == _playerId;
    }

    public function hashCode () :int
    {
        return _playerId;
    }

    public function toString () :String
    {
        return "Player [playerId=" + _playerId
            + ", name=" + name
            + ", roomId=" +
            (room != null ? room.roomId : "null")
            + ", xp=" + xp
            + ", level=" + level
            + ", bloodbond=" + bloodbond
            + ", sire=" + sire
            + ", progeny=" + progenyIds
            + "]";
    }

    public function shutdown () :void
    {
        freeAllHandlers();

        //Make sure the player has left any feeding games
        if (_room != null) {
            _room.playerLeft(this);
        }

        _room = null;
        _ctrl = null;
    }

    public function set xp (newxp :Number) :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_XP, Logic.maxXPGivenXPAndInvites(newxp, invites), true);
    }

    protected function get targetPlayer () :PlayerData
    {
        if (ServerContext.server.isPlayer(targetId)) {
            return ServerContext.server.getPlayer(targetId);
        }
        return null;
    }

    public function get avatar () :AVRGameAvatar
    {
        if (room == null || room.ctrl == null || !room.ctrl.isConnected() ||
            !room.ctrl.isPlayerHere(playerId) || _ctrl == null || !_ctrl.isConnected()) {
            return null;
        }
        return room.ctrl.getAvatarInfo(playerId);
    }

    protected function enteredRoom (evt :AVRGamePlayerEvent) :void
    {
        log.info(" Player entered room", "player", toString());

        var thisPlayer :PlayerData = this;
        _room = ServerContext.server.getRoom(int(evt.value));
        ServerContext.server.ctrl.doBatch(function () :void {
            try {
                if (_room != null) {
                    ServerContext.server.dispatchEvent(
                        new GameEvent(GameEvent.PLAYER_ENTERED_ROOM, thisPlayer,
                            _room));
                    _room.playerEntered(thisPlayer);
                }
                else {
                    log.error("WTF, enteredRoom called, but room == null???");
                }
            }
            catch(err:Error)
            {
                log.error(err.getStackTrace());
            }
        });
    }


    protected function leftRoom (evt :AVRGamePlayerEvent) :void
    {
        log.debug(name + " leftRoom");
        var thisPlayer :PlayerData = this;
        ServerContext.server.ctrl.doBatch(function () :void {
            if (_room != null) {

                _room.playerLeft(thisPlayer);
                if (_room.roomId == evt.value) {
                    _room = null;
                } else {
                    log.warning("The room we're supposedly leaving is not the one we think we're in",
                                "ourRoomId", _room.roomId, "eventRoomId", evt.value);
                }
            }

        });
        _room = null;
    }

    public function get room () :Room
    {
        return _room;
    }

    public function set targetId (id :int) :void
    {
        _targetId = id;
    }

    public function set invites (inv :int) :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_INVITES, inv, true);
        xp = xp;
        Trophies.checkInviteTrophies(this);
    }

    public function set targetLocation (location :Array) :void
    {
        _targetLocation = location;
    }

    public function set feedingData(bytes :ByteArray) :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_FEEDING_DATA, bytes, true);
    }

    public function addToInviteTally (addition :int = 1) :void
    {
        invites += addition;
    }

    public function removeBloodBond () :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_BLOODBOND, 0, true);
        _ctrl.props.set(Codes.PLAYER_PROP_BLOODBOND_NAME, "", true);
    }

    public function set bloodBond (newbloodbond :int) :void
    {
        // update our runtime state
        if (newbloodbond == bloodbond) {
            log.debug("set bloodBond ignoring: " + newbloodbond + "==" + bloodbond);
            return;
        }

        var oldBloodBond :int = bloodbond;
        _ctrl.props.set(Codes.PLAYER_PROP_BLOODBOND, newbloodbond, true);

        if (oldBloodBond != 0) {//Remove the blood bond from the other player.
            if (ServerContext.server.isPlayer(oldBloodBond)) {
                var oldPartner :PlayerData = ServerContext.server.getPlayer(oldBloodBond);
                oldPartner.removeBloodBond();
            }
            else {//Load from database
                ServerContext.ctrl.loadOfflinePlayer(oldBloodBond,
                    function (props :OfflinePlayerPropertyControl) :void {
                        props.set(Codes.PLAYER_PROP_BLOODBOND, 0);
                        props.set(Codes.PLAYER_PROP_BLOODBOND_NAME, "");
                    },
                    function (failureCause :Object) :void {
                        log.warning("Eek! Sending message to offline player failed!", "cause", failureCause); ;
                    });


            }

        }


        if (newbloodbond != 0 && ServerContext.server.isPlayer(newbloodbond)) {//Set the name too
            var bloodBondedPlayer :PlayerData = ServerContext.server.getPlayer(newbloodbond);
            if (bloodBondedPlayer != null) {
                bloodbondName = bloodBondedPlayer.name;
            }
            else {
                log.error("Major error: setBloodBonded(" + bloodbond + "), but no Player, so cannot set name");
            }
        }
    }

    public function set sire (newsire :int) :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_SIRE, newsire, true);
    }


    public function get name () :String
    {
        return _ctrl.getPlayerName();
    }

    public function get level () :int
    {
        return Logic.levelGivenCurrentXpAndInvites(xp, invites);
    }

    public function get xp () :Number
    {
        return _ctrl.props.get(Codes.PLAYER_PROP_XP) as Number;
    }

    public function get bloodbond () :int
    {
        return _ctrl.props.get(Codes.PLAYER_PROP_BLOODBOND) as int;
    }

    public function get bloodbondName () :String
    {
        return _ctrl.props.get(Codes.PLAYER_PROP_BLOODBOND_NAME) as String;
    }

    public function set bloodbondName (name :String) :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_BLOODBOND_NAME, name, true);
    }

    public function get sire () :int
    {
        return _ctrl.props.get(Codes.PLAYER_PROP_SIRE) as int;
    }

    public function get invites () :int
    {
        return _ctrl.props.get(Codes.PLAYER_PROP_INVITES) as int;
    }

    public function get targetId() :int
    {
        return _targetId;
    }
    public function get targetLocation() :Array
    {
        return _targetLocation;
    }

    public function get progenyIds() :Array
    {
        var progeny :Array = _ctrl.props.get(Codes.PLAYER_PROP_INVITES) as Array;
        if (progeny == null) {
            return [];
        }
        return progeny;
    }

    public function set progenyIds(p :Array) :void
    {
        _ctrl.props.set(Codes.PLAYER_PROP_PROGENY_IDS, p, true);
        Trophies.checkMinionTrophies(this);
    }

    public function addProgeny (progenyId :int) :void
    {
        var p :Array = progenyIds.slice();
        if (p == null) {
            p = new Array();
        }
        if (!ArrayUtil.contains(p, progenyId)) {
            p.push(progenyId);
        }
        p.sort();
        progenyIds = p;
    }

    public function get location () :Array
    {
        if (room == null || room.ctrl == null || room.ctrl.getAvatarInfo(playerId) == null) {
            return null;
        }
        var avatar :AVRGameAvatar = room.ctrl.getAvatarInfo(playerId);
        return [avatar.x, avatar.y, avatar.z, avatar.orientation];
    }

    public function addXPBonusNotification (bonus :Number) :void
    {
        _xpFeedback += bonus;
        var now :Number = new Date().time;
        if (now - _previousXPFeedbackNotificationTime >= MINIMUM_XP_NOTIFICATION_INTERVAL_MS) {
            _previousXPFeedbackNotificationTime = now;
            if (_xpFeedback >= 1) {
                addFeedback("You gained " + Util.formatNumberForFeedback(_xpFeedback) +
                        " experience from your descendents!");
                _xpFeedback = 0;
            }

        }
    }




    //Basic variables
    protected var _room :Room;
    protected var _ctrl :PlayerSubControlBase;
    protected var _playerId :int;

    //Non-persistant variables
    protected var _targetId :int;
    protected var _targetLocation :Array;
    protected var _feedback :Array = [];
    protected var _previousXPFeedbackNotificationTime :Number = 0;
    protected var _xpFeedback :Number = 0;
    protected var _lineage :ByteArray;

    public static const MINIMUM_XP_NOTIFICATION_INTERVAL_MS :Number = 5*60*1000;

    protected static const log :Log = Log.getLog(PlayerData);

}
}
