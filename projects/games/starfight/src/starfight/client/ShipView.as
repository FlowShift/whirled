package starfight.client {

import com.threerings.util.Log;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import starfight.*;

public class ShipView extends Sprite
{
    public function ShipView (ship :ClientShip)
    {
        _ship = ship;

        updateShipType();

        // Add our name as a textfield
        if (_ship.playerName != null) {
            var nameText :TextField = new TextField();
            nameText.autoSize = TextFieldAutoSize.CENTER;
            nameText.selectable = false;
            nameText.x = 0;
            nameText.y = TEXT_OFFSET;

            var format:TextFormat = new TextFormat();
            format.font = GameView.gameFont.fontName;
            format.color = (_ship.isOwnShip || _ship.shipId < 0) ? Constants.CYAN : Constants.RED;
            format.size = 10;
            format.rightMargin = 3;
            nameText.defaultTextFormat = format;
            nameText.embedFonts = true;
            nameText.antiAliasType = AntiAliasType.ADVANCED;
            nameText.text = _ship.playerName;
            addChild(nameText);
        }
    }

    protected function updateShipType () :void
    {
        if (_shipParent != null) {
            removeChild(_shipParent);
        }

        _shipParent = new Sprite();
        addChild(_shipParent);

        var shipType :ShipType = _ship.shipType;

        // Set up our animation.
        var shipResources :ShipTypeResources = ClientConstants.getShipResources(_ship.shipTypeId);
        _shipMovie = MovieClip(new shipResources.shipAnim());
        _shieldMovie = MovieClip(new shipResources.shieldAnim());

        setAnimMode(IDLE, true);
        _shipMovie.x = _shipMovie.width/2;
        _shipMovie.y = -_shipMovie.height/2;
        _shipMovie.rotation = 90;
        _shipParent.addChild(_shipMovie);

        _shieldMovie.gotoAndStop(1);
        _shieldMovie.rotation = 90;
        _shipParent.addChild(_shieldMovie);

        _shipParent.scaleX = shipType.size + 0.1;
        _shipParent.scaleY = shipType.size + 0.1;

        stopSounds();

        if (_ship.isOwnShip) {
            _shieldSound = new SoundLoop(Resources.getSound("shields.wav"));
            _thrusterForwardSound = new SoundLoop(Resources.getSound("thruster.wav"));
            _thrusterReverseSound = new SoundLoop(Resources.getSound("thruster_retro2.wav"));
            _engineSound = new SoundLoop(shipResources.engineSound);

        } else {
            _shieldSound = null;
            _thrusterForwardSound = null;
            _thrusterReverseSound = null;
            _engineSound = null;
        }

        _curShipTypeId = _ship.shipTypeId;
        _lastShipState = -1;
    }

    public function keyPressed (event :KeyboardEvent) :void
    {
        if (!_ship.isAlive) {
            return;
        }

        if (event.keyCode == KV_LEFT || event.keyCode == KV_A) {
            _ship.turning = ClientShip.LEFT_TURN;
        } else if (event.keyCode == KV_RIGHT || event.keyCode == KV_D) {
            _ship.turning = ClientShip.RIGHT_TURN;
        } else if (event.keyCode == KV_UP || event.keyCode == KV_W) {
            _ship.moving = ClientShip.FORWARD;
        } else if (event.keyCode == KV_DOWN || event.keyCode == KV_S) {
           _ship.moving = ClientShip.REVERSE;
        } else if (event.keyCode == KV_SPACE) {
            _ship.firing = true;
        } else if (event.keyCode == KV_B || event.keyCode == KV_SHIFT) {
            _ship.secondaryFiring = true;
        }
    }

    public function keyReleased (event :KeyboardEvent) :void
    {
        if (!_ship.isAlive) {
            return;
        }

        if (event.keyCode == KV_LEFT || event.keyCode == KV_A) {
            _ship.turning = ClientShip.NO_TURN;
        } else if (event.keyCode == KV_RIGHT || event.keyCode == KV_D) {
            _ship.turning = ClientShip.NO_TURN;
        } else if (event.keyCode == KV_UP || event.keyCode == KV_W) {
            _ship.moving = ClientShip.NO_MOVE;
        } else if (event.keyCode == KV_DOWN || event.keyCode == KV_S) {
            _ship.moving = ClientShip.NO_MOVE;
        } else if (event.keyCode == KV_SPACE) {
            _ship.firing = false;
        } else if (event.keyCode == KV_B || event.keyCode == KV_SHIFT) {
            _ship.secondaryFiring = false;
        }
    }

    public function updateDisplayState (boardCenterX :Number, boardCenterY: Number) :void
    {
        var shipState :int = _ship.state;
        visible = (shipState != Ship.STATE_DEAD);

        if (shipState == Ship.STATE_DEAD) {
            stopSounds();

        } else {
            if (_ship.shipTypeId != _curShipTypeId) {
                updateShipType();
            }

            // position on the screen
            x = ((_ship.boardX - boardCenterX) * Constants.PIXELS_PER_TILE) +
                (Constants.GAME_WIDTH * 0.5);
            y = ((_ship.boardY - boardCenterY) * Constants.PIXELS_PER_TILE) +
                (Constants.GAME_HEIGHT * 0.5);

            _shipParent.rotation = _ship.rotation;

            _shieldMovie.visible = (_ship.shieldHealth > 0);

            // determine animation state
            var newAnimMode :int;
            switch (shipState) {
            case Ship.STATE_SPAWN:
                if (shipState != _lastShipState) {
                    playSpawnMovie();
                }
                newAnimMode = IDLE;
                break;

            case Ship.STATE_WARP_BEGIN:
                newAnimMode = WARP_BEGIN;
                break;

            case Ship.STATE_WARP_END:
                newAnimMode = WARP_END;
                break;

            default:
                var accel :Number = _ship.accel;
                var hasSpeed :Boolean = _ship.hasPowerup(Powerup.SPEED);
                if (accel > 0.0) {
                    newAnimMode = hasSpeed ? FORWARD_FAST : FORWARD;
                } else if (accel < 0.0) {
                    newAnimMode = hasSpeed ? REVERSE_FAST : REVERSE;
                } else {
                    newAnimMode = IDLE;
                }
                break;
            }

            setAnimMode(newAnimMode, false);

            if (_ship.isOwnShip) {
                _engineSound.play(true);
                _shieldSound.play(_shieldMovie.visible);
                _thrusterForwardSound.play(_ship.accel > 0);
                _thrusterReverseSound.play(_ship.accel < 0);

                if (lostPowerup(_ship.powerups, _oldPowerups)) {
                    ClientContext.game.playSoundAt(Resources.getSound("powerup_empty.wav"),
                        _ship.boardX, _ship.boardY);
                }

                _oldPowerups = _ship.powerups;
            }
        }

        _lastShipState = shipState;
    }

    protected static function lostPowerup (newPowerups :int, oldPowerups :int) :Boolean
    {
        for (var ii :int = 0; ii < Powerup.COUNT; ii++) {
            if (Ship.hasPowerup(oldPowerups, ii) && !Ship.hasPowerup(newPowerups, ii)) {
                return true;
            }
        }

        return false;
    }

    protected function setAnimMode (mode :int, force :Boolean) :void
    {
        if (force || _animMode != mode) {
            _shipMovie.gotoAndPlay(ANIM_MODES[mode]);
            _animMode = mode;
        }
    }

    protected function playSpawnMovie () :void
    {
        ClientContext.game.playSoundAt(
            ClientConstants.getShipResources(_ship.shipTypeId).spawnSound,
            _ship.boardX, _ship.boardY);

        var spawnClip :MovieClip = MovieClip(new (Resources.getClass("ship_spawn"))());
        addChild(spawnClip);
        spawnClip.addEventListener(Event.COMPLETE, function complete (event :Event) :void {
            spawnClip.removeEventListener(Event.COMPLETE, arguments.callee);
            removeChild(event.target as MovieClip);
        });
    }

    protected function stopSounds () :void
    {
        if (_thrusterForwardSound != null) {
            _thrusterForwardSound.stop();
        }

        if (_thrusterReverseSound != null) {
            _thrusterReverseSound.stop();
        }

        if (_shieldSound != null) {
            _shieldSound.stop();
        }

        if (_engineSound != null) {
            _engineSound.stop();
        }

    }

    protected var _ship :ClientShip;
    protected var _curShipTypeId :int = -1;

    /** The sprite with our ship graphics in it. */
    protected var _shipParent :Sprite;

    /** Animations. */
    protected var _shipMovie :MovieClip;
    protected var _shieldMovie :MovieClip;

    protected var _animMode :int;

    protected var _lastShipState :int = -1;

    protected var _oldPowerups :int;

    /** Sounds currently being played - only play sounds for ownship. Note
     * that due to stupid looping behavior these need to be MovieClips to keep
     * from getting gaps between loops. */
    protected var _engineSound :SoundLoop;
    protected var _thrusterForwardSound :SoundLoop;
    protected var _thrusterReverseSound :SoundLoop;
    protected var _shieldSound :SoundLoop;

    protected static const log :Log = Log.getLog(ShipView);

    /** "frames" within the actionscript for movement animations. */
    protected static const IDLE :int = 0;
    protected static const FORWARD :int = 2;
    protected static const REVERSE :int = 1;
    protected static const FORWARD_FAST :int = 3;
    protected static const REVERSE_FAST :int = 4;
    protected static const SELECT :int = 5;
    protected static const WARP_BEGIN :int = 6;
    protected static const WARP_END :int = 7;

    /** Some useful key codes. */
    protected static const KV_LEFT :uint = 37;
    protected static const KV_UP :uint = 38;
    protected static const KV_RIGHT :uint = 39;
    protected static const KV_DOWN :uint = 40;
    protected static const KV_SPACE :uint = 32;
    protected static const KV_ENTER :uint = 13;
    protected static const KV_A :uint = 65;
    protected static const KV_B :uint = 66;
    protected static const KV_D :uint = 68;
    protected static const KV_S :uint = 83;
    protected static const KV_W :uint = 87;
    protected static const KV_X :uint = 88;
    protected static const KV_SHIFT :uint = 16;

    protected static const TEXT_OFFSET :int = 25;

    protected static const ANIM_MODES :Array = [
        "ship", "retro", "thrust", "super_thrust", "super_retro", "select", "warp_begin", "warp_end"
    ];
}

}
