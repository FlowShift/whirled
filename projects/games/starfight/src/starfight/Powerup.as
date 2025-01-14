package starfight {

import flash.events.Event;
import flash.utils.ByteArray;

public class Powerup extends BoardObject
{
    public static const CONSUMED :String = "Consumed";
    public static const DESTROYED :String = "Destroyed";

    // NB - don't increase the number of powerups beyond 8 without changing ShipData
    public static const SHIELDS :int = 0;
    public static const SPEED :int = 1;
    public static const SPREAD :int = 2;
    public static const HEALTH :int = 3;
    public static const COUNT :int = 3;

    public var type :int;

    public static function readPowerup (bytes :ByteArray) :Powerup
    {
        var powerup :Powerup = new Powerup(0, 0, 0);
        powerup.reload(bytes);
        return powerup;
    }

    public function Powerup (type :int, boardX :int, boardY :int) :void
    {
        super(boardX, boardY);
        this.type = type;
    }

    public function consume () :void
    {
        dispatchEvent(new Event(CONSUMED));
    }

    public function destroyed () :void
    {
        dispatchEvent(new Event(DESTROYED));
    }

    override public function toBytes (bytes :ByteArray = null) :ByteArray
    {
        super.toBytes(bytes);
        bytes.writeByte(type);
        return bytes;
    }

    override public function fromBytes (bytes :ByteArray) :void
    {
        super.fromBytes(bytes);
        type = bytes.readByte();
    }
}

}
