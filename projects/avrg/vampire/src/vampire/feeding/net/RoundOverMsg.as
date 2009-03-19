package vampire.feeding.net {

import com.threerings.util.HashMap;
import com.whirled.contrib.simplegame.net.Message;

import flash.utils.ByteArray;

public class RoundOverMsg
    implements Message
{
    public static const NAME :String = "RoundOver";

    public var scores :HashMap; // Map<playerId, score>
    public var preyBloodStart :Number;
    public var preyBloodEnd :Number;

    public static function create (scores :HashMap, preyBloodStart :Number,
        preyBloodEnd :Number) :RoundOverMsg
    {
        var msg :RoundOverMsg = new RoundOverMsg();
        msg.scores = scores;
        msg.preyBloodStart = preyBloodStart;
        msg.preyBloodEnd = preyBloodEnd;

        return msg;
    }

    public function get totalScore () :int
    {
        var score :int;
        scores.forEach(
            function (playerId :int, playerScore :int) :void {
                score += playerScore;
            });
        return score;
    }

    public function toBytes (ba :ByteArray = null) :ByteArray
    {
        if (ba == null) {
            ba = new ByteArray();
        }

        ba.writeByte(scores.size());
        scores.forEach(
            function (playerId :int, score :int) :void {
                ba.writeInt(playerId);
                ba.writeInt(score);
            });

        ba.writeFloat(preyBloodStart);
        ba.writeFloat(preyBloodEnd);

        return ba;
    }

    public function fromBytes (ba :ByteArray) :void
    {
        scores = new HashMap();

        var numScores :int = ba.readByte();
        for (var ii :int = 0; ii < numScores; ++ii) {
            var playerId :int = ba.readInt();
            var score :int = ba.readInt();
            scores.put(playerId, score);
        }

        preyBloodStart = ba.readFloat();
        preyBloodEnd = ba.readFloat();
    }

    public function get name () :String
    {
        return NAME;
    }
}

}
