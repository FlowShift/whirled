package starfight {

import flash.events.Event;
import flash.utils.ByteArray;

/**
 * Represents something in the world that ships may interact with.
 */
public class Obstacle extends BoardObject
{
    public static const COLLIDED :String = "Collided";

    /** Constants for types of obstacles. */
    public static const ASTEROID_1 :int = 0;
    public static const ASTEROID_2 :int = 1;
    public static const JUNK :int = 2;
    public static const WALL :int = 3;

    public static const LEFT :int = 0;
    public static const RIGHT :int = 1;
    public static const UP :int = 2;
    public static const DOWN :int = 3;

    public var type :int;
    public var health :Number;
    public var w :int;
    public var h :int;

    public static function readObstacle (bytes :ByteArray) :Obstacle
    {
        var obs :Obstacle = new Obstacle(0, 0, 0);
        obs.reload(bytes);
        return obs;
    }

    public function Obstacle (type :int, x :int, y :int, w :int = 0, h :int = 0) :void
    {
        super(x, y);
        this.type = type;
        health = 1.0;
        this.w = w;
        this.h = h;
    }

    public function shipCollided () :void
    {
        dispatchEvent(new Event(COLLIDED));
    }

    /**
     * Get a value for how much bounce ships should get off the obstacle.
     */
    public function getElasticity () :Number
    {
        // TODO: Something different for different obstacles.
        return 0.75;
    }

    override public function damage (damage :Number) :Boolean
    {
        if (health < 0 || type == WALL) {
            return false;
        }
        health -= damage;
        return health < 0;
    }

    override public function get arrayName () :String
    {
        return Constants.PROP_OBSTACLES;
    }

    override public function fromBytes (bytes :ByteArray) :void
    {
        super.fromBytes(bytes);
        type = bytes.readInt();
        w = bytes.readInt();
        h = bytes.readInt();
    }

    override public function toBytes (bytes :ByteArray = null) :ByteArray
    {
        bytes = super.toBytes(bytes);
        bytes.writeInt(type);
        bytes.writeInt(w);
        bytes.writeInt(h);
        return bytes;
    }
}

}
