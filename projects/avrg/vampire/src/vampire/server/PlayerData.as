package vampire.server
{

import com.threerings.util.ArrayUtil;
import com.threerings.util.ClassUtil;
import com.threerings.util.Hashable;
import com.threerings.util.Log;
import com.whirled.avrg.AVRGameAvatar;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.avrg.OfflinePlayerPropertyControl;
import com.whirled.avrg.PlayerSubControlServer;
import com.whirled.contrib.EventHandlerManager;

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
    public function PlayerData (ctrl :PlayerSubControlServer)
    {
        if (ctrl == null) {
            log.error("Bad! PlayerData(null).  What happened to the PlayerSubControlServer?  Expect random failures everywhere.");
            return;
        }

        _ctrl = ctrl;

        //Setup the data container.  This will only update values that are changed.
        _propsUndater = new PlayerPropertiesUpdater(_ctrl, Codes.PLAYER_PROPS_UPDATED);

        _playerId = ctrl.getPlayerId();

        registerListener(_ctrl, AVRGamePlayerEvent.ENTERED_ROOM, enteredRoom);
        registerListener(_ctrl, AVRGamePlayerEvent.LEFT_ROOM, leftRoom);

        //Start in the default state
        _state = VConstants.AVATAR_STATE_DEFAULT;

        if (isNaN(xp)) {
            xp = 0;
        }

        log.info("Logging in", "playerId", playerId,
//                "blood", blood,
//                "maxBlood",  maxBlood,
                "xp",  xp,
                "level", level,
                "sire", sire,
                "bloodbond", bloodbond,
                "bloodbondName", bloodbondName
                );//, "time", new Date(time).toTimeString()

        Trophies.checkMinionTrophies(this);
        Trophies.checkInviteTrophies(this);
    }

    public function get feedingData () :ByteArray
    {
        return _propsUndater.get(Codes.PLAYER_PROP_FEEDING_DATA) as ByteArray;
    }

    public function addFeedback (msg :String) :void
    {
        _feedback.push(msg);
    }

    public function get ctrl () :PlayerSubControlServer
    {
        return _ctrl;
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
            + ", level=" + level
//            + ", blood=" + blood + "/" + maxBlood
            + ", bloodbond=" + bloodbond
            + ", targetId=" + targetId
            + ", sire=" + sire
            + ", xp=" + xp
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
        _propsUndater.put(Codes.PLAYER_PROP_XP, Math.min(xp, Logic.maxXPGivenXPAndInvites(xp, invites)));
    }

    public function set state (action :String) :void
    {
        _state = action;
    }

    protected function get targetPlayer () :PlayerData
    {
        if (ServerContext.server.isPlayer(targetId)) {
            return ServerContext.server.getPlayer(targetId);
        }
        return null;
    }

    protected function get isTargetPlayer () :Boolean
    {
        return ServerContext.server.isPlayer(targetId);
    }

    public function get avatar () :AVRGameAvatar
    {
        if (room == null || room.ctrl == null || !room.ctrl.isConnected() ||
            !room.ctrl.isPlayerHere(playerId) || _ctrl == null || !_ctrl.isConnected()) {
            return null;
        }
        return room.ctrl.getAvatarInfo(playerId);
    }

    protected function get targetOfTargetPlayer() :int
    {
        if (!isTargetPlayer) {
            return 0;
        }
        return targetPlayer.targetId;
    }

    protected function get isTargetTargetingMe() :Boolean
    {
        if (!isTargetPlayer) {
            return false;
        }
        return targetPlayer.targetId == playerId;
    }


    protected function enteredRoom (evt :AVRGamePlayerEvent) :void
    {
        log.info(" Player entered room", "player", toString());

        var thisPlayer :PlayerData = this;
        _room = ServerContext.server.getRoom(int(evt.value));
        ServerContext.server.control.doBatch(function () :void {
            try {
                if (_room != null) {
                    _room.playerEntered(thisPlayer);
                    ServerContext.lineage.playerEnteredRoom(thisPlayer, _room);
                    thisPlayer.state = VConstants.PLAYER_STATE_DEFAULT;
                    ServerLogic.updateAvatarState(thisPlayer);
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
        ServerContext.server.control.doBatch(function () :void {
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

    public function updateRoom() :void
    {
        try {

            if (_ctrl == null || !_ctrl.isConnected()) {
                log.error("setIntoRoomProps() but ", "_ctrl", _ctrl);
                return;
            }

            if (_room == null || _room.ctrl == null || !_room.ctrl.isConnected()) {
                log.error("setIntoRoomProps() but ", "room", room);
                return;
            }

            //Copy the feedback to the room
            if (_feedback.length > 0) {
                for each (var msg :String in _feedback) {
                    room.addFeedback(msg, playerId);
                }
                _feedback.splice(0);
            }

        }
        catch(err :Error) {
            log.error(err.getStackTrace());
        }
    }

    public function set targetId (id :int) :void
    {
        _targetId = id;
    }

    public function set invites (inv :int) :void
    {
        _propsUndater.put(Codes.PLAYER_PROP_INVITES, inv);
    }

    public function set targetLocation (location :Array) :void
    {
        _targetLocation = location;
    }

    public function set feedingData(bytes :ByteArray) :void
    {
        _propsUndater.put(Codes.PLAYER_PROP_FEEDING_DATA, bytes);
    }

    public function addToInviteTally (addition :int = 1) :void
    {
        invites += addition;
    }

    public function removeBloodBond () :void
    {
        _propsUndater.put(Codes.PLAYER_PROP_BLOODBOND, 0);
        _propsUndater.put(Codes.PLAYER_PROP_BLOODBOND_NAME, "");
    }

    public function set bloodBond (newbloodbond :int) :void
    {
        // update our runtime state
        if (newbloodbond == bloodbond) {
            log.debug("set bloodBond ignoring: " + newbloodbond + "==" + bloodbond);
            return;
        }

        var oldBloodBond :int = bloodbond;
        _propsUndater.put(Codes.PLAYER_PROP_BLOODBOND, newbloodbond);

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
        _propsUndater.put(Codes.PLAYER_PROP_SIRE, newsire);
    }

    public function get state () :String
    {
        return _state;
    }

    public function get name () :String
    {
        if (_ctrl != null && _ctrl.isConnected()) {
            return _ctrl.getPlayerName();
        }
        return "";
    }

    public function get level () :int
    {
        return Logic.levelGivenCurrentXpAndInvites(xp);
    }

    public function get xp () :Number
    {
        return _propsUndater.get(Codes.PLAYER_PROP_XP) as Number;
    }

    public function get bloodbond () :int
    {
        return _propsUndater.get(Codes.PLAYER_PROP_BLOODBOND) as int;
    }

    public function get bloodbondName () :String
    {
        return _propsUndater.get(Codes.PLAYER_PROP_BLOODBOND_NAME) as String;
    }

    public function set bloodbondName (name :String) :void
    {
        _propsUndater.put(Codes.PLAYER_PROP_BLOODBOND_NAME, name);
    }

    public function get sire () :int
    {
        return _propsUndater.get(Codes.PLAYER_PROP_SIRE) as int;
    }

    public function get invites () :int
    {
        return _propsUndater.get(Codes.PLAYER_PROP_INVITES) as int;
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
        return [];//_progenyIds;
    }

    public function get location () :Array
    {
        if (room == null || room.ctrl == null || room.ctrl.getAvatarInfo(playerId) == null) {
            return null;
        }
        var avatar :AVRGameAvatar = room.ctrl.getAvatarInfo(playerId);
        return [avatar.x, avatar.y, avatar.z, avatar.orientation];
    }

    //This update comes from the server and only occurs a few times per second.
    public function update (dt :Number) :void
    {
        //Bundle up the xp notifications
        _xpFeedbackTime += dt;
        if (_xpFeedbackTime >= VConstants.NOTIFICATION_TIME_XP) {
            _xpFeedbackTime = 0;
            if (_xpFeedback >= 1) {
                addFeedback("You gained " + Util.formatNumberForFeedback(_xpFeedback) +
                        " experience from your descendents!");
                _xpFeedback = 0;
            }
        }

        if (_propsUndater.isNeedingUpdate(Codes.PLAYER_PROP_INVITES)) {
            Trophies.checkInviteTrophies(this);
        }

        if (_propsUndater.isNeedingUpdate(Codes.PLAYER_PROP_LINEAGE)) {
            Trophies.checkMinionTrophies(this);
        }

        _propsUndater.update(dt);
    }

    /**
    * We never delete the progeny array, only add to it.
    * This is because the Lineage is changing from only the sire stored with the player, to
    * both sires and progeny.  However, players must log on at least once for the changes to
    * occur.
    */
    public function updateProgeny(progeny :Array) :void
    {
//        for each (var newProgenyId :int in progeny) {
//            if (!ArrayUtil.contains(_progenyIds, newProgenyId)) {
//                _progenyIds.push(newProgenyId);
//            }
//        }
//        _progenyIds = _progenyIds.sort();
//        Trophies.checkMinionTrophies(this);
    }

    public function isVictim() :Boolean
    {
        if (state != VConstants.AVATAR_STATE_BARED) {
            return false;
        }

        var predator :PlayerData = ServerContext.server.getPlayer(targetId);
        if (predator == null) {
            return false;
        }

        if (predator.state == VConstants.AVATAR_STATE_FEEDING && predator.targetId == playerId) {
            return true;
        }
        return false;
    }

    public function addXPBonusNotification (bonus :Number) :void
    {
        _xpFeedback += bonus;
    }

    //Basic variables
    protected var _room :Room;
    protected var _ctrl :PlayerSubControlServer;
    protected var _playerId :int;

    //Non-persistant variables
    protected var _state :String;
    protected var _targetId :int;
    protected var _targetLocation :Array;
    protected var _feedback :Array = [];
    protected var _xpFeedbackTime :Number = 0;
    protected var _xpFeedback :Number = 0;

    //Stores props copied to the client
    protected var _propsUndater :PlayerPropertiesUpdater;

    protected static const log :Log = Log.getLog(PlayerData);

}
}