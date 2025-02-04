package starfight {

import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.threerings.util.StringUtil;
import com.whirled.contrib.ManagedTimer;
import com.whirled.contrib.TimerManager;
import com.whirled.game.GameControl;
import com.whirled.game.OccupantChangedEvent;
import com.whirled.net.MessageReceivedEvent;
import com.whirled.net.PropertyChangedEvent;

import flash.events.TimerEvent;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import starfight.net.CreateMineMessage;
import starfight.net.ShipShotMessage;

public class GameController
{
    public function GameController (gameCtrl :GameControl)
    {
        _gameCtrl = gameCtrl;

        _gameCtrl.net.addEventListener(PropertyChangedEvent.PROPERTY_CHANGED, propertyChanged);
        _gameCtrl.game.addEventListener(OccupantChangedEvent.OCCUPANT_LEFT, occupantLeft);

        AppContext.msgs.addEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, messageReceived);

        _timers = new TimerManager();
    }

    public function shutdown () :void
    {
        if (_gameCtrl.isConnected()) {
            _gameCtrl.net.removeEventListener(PropertyChangedEvent.PROPERTY_CHANGED, propertyChanged);
            _gameCtrl.game.removeEventListener(OccupantChangedEvent.OCCUPANT_LEFT, occupantLeft);
        }

        AppContext.msgs.removeEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, messageReceived);

        _timers.shutdown();
    }

    public function get timers () :TimerManager
    {
        return _timers;
    }

    public function get gameState () :int
    {
        return _gameState;
    }

    public function run () :void
    {
        throw new Error("abstract");
    }

    public function createShip (shipId :int, playerName :String, clientData :ClientShipData = null)
        :Ship
    {
        throw new Error("abstract");
    }

    protected function beginGame () :void
    {
        _shots = [];

        // Set up our ticker that will control movement.
        startScreenTimer();
        _lastTickTime = getTimer();
        _running = true;
    }

    protected function startScreenTimer () :void
    {
        if (_screenTimer == null) {
            _screenTimer = _timers.createTimer(1000/30, 0, tick);
            _screenTimer.start();
        }
    }

    protected function stopScreenTimer () :void
    {
        if (_screenTimer != null) {
            _screenTimer.cancel();
            _screenTimer = null;
        }
    }

    /**
     * Return the key used to store the ship for a given player ID.
     */
    protected function shipKey (id :int) :String
    {
        return Constants.PROP_SHIP_PREFIX + id;
    }

    /**
     * Return whether the key is that for a ship.
     */
    protected function isShipKey (key :String) :Boolean
    {
        return StringUtil.startsWith(key, Constants.PROP_SHIP_PREFIX);
    }

    /**
     * Extracts and returns the ID from a ship's key.
     */
    protected function shipKeyId (key :String) :int
    {
        return int(key.substr(Constants.PROP_SHIP_PREFIX.length));
    }

    protected function shipDataKey (id :int) :String
    {
        return Constants.PROP_SHIPDATA_PREFIX + id;
    }

    protected function isShipDataKey (key :String) :Boolean
    {
        return StringUtil.startsWith(key, Constants.PROP_SHIPDATA_PREFIX);
    }

    protected function shipDataKeyId (key :String) :int
    {
        return int(key.substr(Constants.PROP_SHIPDATA_PREFIX.length));
    }

    protected function propertyChanged (event :PropertyChangedEvent) :void
    {
        if (_running && isShipKey(event.name)) {
            shipChanged(shipKeyId(event.name), ByteArray(event.newValue));
        }
    }

    protected function gameStateChanged (newGameState :int) :void
    {
        if (newGameState != _gameState) {
            _gameState = newGameState;
            if (_gameState == Constants.STATE_IN_ROUND) {
                roundStarted();
            } else if (_gameState == Constants.STATE_POST_ROUND) {
                roundEnded();
            }
        }
    }

    protected function shipChanged (shipId :int, bytes :ByteArray) :void
    {
        var occName :String = _gameCtrl.game.getOccupantName(shipId);
        if (bytes == null) {
            removeShip(shipId);

        } else {
            var ship :Ship = getShip(shipId);
            bytes.position = 0;
            if (ship == null) {
                ship = createShip(shipId, occName, ClientShipData.fromBytes(bytes));
                addShip(shipId, ship);

            } else {
                ship.updateForReport(ClientShipData.fromBytes(bytes));
            }
        }
    }

    public function addShip (id :int, ship :Ship) :void
    {
        var oldValue :* = _ships.put(id, ship);
        if (oldValue !== undefined) {
            throw new Error("Tried to add a ship that already existed [id=" + id + "]");
        }
        _population++;
    }

    public function removeShip (id :int) :Ship
    {
        var remShip :Ship = _ships.remove(id);
        if (remShip != null) {
            AppContext.local.feedback(remShip.playerName + " left the game.");
            _population--;
        }

        return remShip;
    }

    public function getShip (id :int) :Ship
    {
        return _ships.get(id);
    }

    public function numShips () :int
    {
        return _ships.size();
    }

    /**
     * Performs the round starting events.
     */
    protected function roundStarted () :void
    {
        AppContext.local.feedback("Round starting...");
        _stateTimeMs = Constants.ROUND_TIME_MS;
        AppContext.scores.clearAll();
    }

    protected function roundEnded () :void
    {
        stopScreenTimer();

        for each (var ship :Ship in _ships.values()) {
            ship.roundEnded();
        }
        AppContext.board.roundEnded();
    }

    protected function messageReceived (event :MessageReceivedEvent) :void
    {
        if (_running) {
            if (event.value is ShipShotMessage) {
                var shipMsg :ShipShotMessage = ShipShotMessage(event.value);
                Constants.getShipType(shipMsg.shipTypeId).doShot(shipMsg);
            } else if (event.value is CreateMineMessage) {
                var mineMsg :CreateMineMessage = CreateMineMessage(event.value);
                AppContext.board.addMine(new Mine(mineMsg.shipId, mineMsg.boardX, mineMsg.boardY,
                    mineMsg.power));
            }
        }
    }

    public function createLaserShot (x :Number, y :Number, angle :Number, length :Number,
            shipId :int, damage :Number, ttl :Number, shipType :int, tShipId :int) :LaserShot
    {
        var shot :LaserShot = new LaserShot(x, y, angle, length, shipId, damage, ttl, shipType,
            tShipId);
        addShot(shot);

        return shot;
    }

    public function createMissileShot (x :Number, y :Number, vel :Number, angle :Number,
        shipId :int, damage :Number, ttl :Number, shipType :int,
        shotClip :Class = null, explodeClip :Class = null) :MissileShot
    {
        var shot :MissileShot = new MissileShot(x, y, vel, angle, shipId, damage, ttl, shipType);
        addShot(shot);

        return shot;
    }

    public function createTorpedoShot (x :Number, y :Number, vel :Number, angle :Number,
        shipId :int, damage :Number, ttl :Number, shipType :int) :TorpedoShot
    {
        var shot :TorpedoShot =
            new TorpedoShot(x, y, vel, angle, shipId, damage, ttl, shipType);

        addShot(shot);

        return shot;
    }

    protected function addShot (shot :Shot) :void
    {
        _shots.push(shot);
    }

    protected function removeShot (index :int) :void
    {
        _shots.splice(index, 1);
    }

    public function awardTrophy (name :String) :void
    {
        _gameCtrl.player.awardTrophy(name);
    }

    /**
     * Register that a ship was hit at the location.
     */
    public function hitShip (ship :Ship, x :Number, y :Number, shooterId :int, damage :Number) :void
    {
    }

    /**
     * Register that an obstacle was hit.
     */
    public function hitObs (obj :BoardObject, x :Number, y :Number, shooterId :int,
        damage :Number) :void
    {
    }

    protected function occupantLeft (event :OccupantChangedEvent) :void
    {
        removeShip(event.occupantId);
    }

    /**
     * Send a message to the server about our shot.
     */
    public function sendMessage (name :String, args :Array) :void
    {
        _gameCtrl.net.sendMessage(name, args);
    }

    /**
     * Returns all the ships within a certain distance of the supplied coordinates.
     */
    public function findShips (x :Number, y :Number, dist :Number) :Array
    {
        var dist2 :Number = dist * dist;
        var nearShips :Array = new Array();
        for each (var ship :Ship in _ships.values()) {
            if (ship != null) {
                if ((ship.boardX-x)*(ship.boardX-x) + (ship.boardY-y)*(ship.boardY-y) < dist2) {
                    nearShips[nearShips.length] = ship;
                }
            }
        }
        return nearShips;
    }

    /**
     * When our screen updater timer ticks...
     */
    public function tick (event :TimerEvent) :void
    {
        var now :int = getTimer();
        update(now - _lastTickTime);
        _lastTickTime = now;
    }

    protected function update (time :int) :void
    {
        _stateTimeMs -= time;

        // Update all ships.
        for each (var ship :Ship in _ships.values()) {
            if (ship != null) {
                ship.update(time);
            }
        }

        AppContext.board.update(time);

        // Update all live shots.
        var completed :Array = []; // Array<Shot>
        for each (var shot :Shot in _shots) {
            if (shot != null) {
                shot.update(AppContext.board, time);
                if (shot.complete) {
                    completed.push(shot);
                }
            }
        }

        // Remove any that were done.
        for each (shot in completed) {
            removeShot(_shots.indexOf(shot));
        }
    }

    protected function setImmediate (propName :String, value :Object) :void
    {
        _gameCtrl.net.set(propName, value, true);
    }

    public function get ships () :Map
    {
        return _ships;
    }

    protected var _timers :TimerManager;
    protected var _gameCtrl :GameControl;
    protected var _running :Boolean;
    protected var _gameState :int;
    protected var _ships :Map = Maps.newMapOf(int); // HashMap<int, Ship>
    protected var _shots :Array = []; // Array<Shot>
    protected var _shipUpdateTime :int;
    protected var _lastTickTime :int;
    protected var _stateTimeMs :int;
    protected var _population :int;
    protected var _screenTimer :ManagedTimer;

    protected static const log :Log = Log.getLog(GameController);

    /** This could be more dynamic. */
    protected static const MIN_TILES_PER_POWERUP :int = 250;

    /** Amount of time to wait between sending time updates. */
    protected static const TIME_WAIT :int = 10000;
}

}
