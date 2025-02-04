package starfight {

public class TorpedoShot extends Shot {

    /** Velocity. */
    public var xVel :Number;
    public var yVel :Number;

    public function TorpedoShot (x :Number, y :Number, vel :Number, angle :Number,
            shipId :int, damage :Number, ttl :Number, shipType :int) :void
    {
        super(x, y, shipId, damage, ttl, shipType);

        this.xVel = vel * Math.cos(angle);
        this.yVel = vel * Math.sin(angle);
    }

    /**
     * Allow our shot to update itself.
     */
    override public function update (board :BoardController, time :Number) :void
    {
        time /= 1000;
        // Update our time to live and destroy if appropriate.
        ttl -= time;
        if (ttl < 0) {
            complete = true;
            time += ttl;
        }

        // See if we're already inside an obstacle, since we could potentially have
        //  been shot just inside the edge of one - if so, explode immediately.
        var inObs :Obstacle = board.getObstacleAt(int(boardX), int(boardY));
        if (inObs != null) {
            AppContext.game.hitObs(inObs, boardX, boardY, shipId, damage);
            complete = true;
            return;
        }

        var wasp :WaspShipType = Constants.SHIP_TYPE_WASP;

        var coll :Collision = board.getCollision(boardX, boardY, boardX + xVel*time,
                boardY + yVel*time, WaspShipType.SECONDARY_SHOT_RANGE, shipId, 2);

        if (coll == null) {
            coll = board.getCollision(boardX, boardY, boardX + xVel*time,
                    boardY + yVel*time, wasp.secondaryShotSize, shipId, 0);
        }

        if (coll == null) {
            boardX += xVel*time;
            boardY += yVel*time;
        } else {
            var hitX :Number = boardX + xVel * coll.time * time;
            var hitY :Number = boardY + yVel * coll.time * time;
            if (coll.hit is Ship) {
                var ship :Ship = Ship(coll.hit);
                AppContext.game.hitShip(ship, hitX, hitY, shipId, damage);

            } else {
                var obs :Obstacle = Obstacle(coll.hit);
                AppContext.game.hitObs(obs, hitX, hitY, shipId, damage);
            }

            hit(hitX, hitY);
            complete = true;
        }
    }
}
}
