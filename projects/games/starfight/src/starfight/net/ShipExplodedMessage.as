package starfight.net {

import flash.utils.ByteArray;

import starfight.*;

public class ShipExplodedMessage
    implements GameMessage
{
    public static const NAME :String = "shipExploded";

    public var shipId :int;
    public var shooterId :int;
    public var x :Number;
    public var y :Number;
    public var rotation :Number;

    public static function create (ship :Ship, shooterId :int) :ShipExplodedMessage
    {
        var msg :ShipExplodedMessage = new ShipExplodedMessage();
        msg.shipId = ship.shipId;
        msg.shooterId = shooterId;
        msg.x = ship.boardX;
        msg.y = ship.boardY;
        msg.rotation = ship.rotation;
        return msg;
    }

    public function get name () :String
    {
        return NAME;
    }

    public function toBytes (bytes :ByteArray = null) :ByteArray
    {
        bytes = (bytes != null ? bytes : new ByteArray());

        bytes.writeInt(shipId);
        bytes.writeInt(shooterId);
        bytes.writeFloat(x);
        bytes.writeFloat(y);
        bytes.writeShort(rotation);
        return bytes;
    }

    public function fromBytes (bytes :ByteArray) :void
    {
        shipId = bytes.readInt();
        shooterId = bytes.readInt();
        x = bytes.readFloat();
        y = bytes.readFloat();
        rotation = bytes.readShort();
    }
}

}
