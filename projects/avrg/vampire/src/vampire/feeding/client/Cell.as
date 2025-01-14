package vampire.feeding.client {

import com.threerings.geom.Vector2;
import com.threerings.flashbang.GameObjectRef;
import com.threerings.flashbang.resource.SwfResource;
import com.threerings.flashbang.tasks.*;
import com.threerings.flashbang.util.*;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;

import vampire.client.SpriteUtil;
import vampire.feeding.*;

public class Cell extends CollidableObj
{
    public static const STATE_BIRTH :int = 0;
    public static const STATE_NORMAL :int = 1;
    public static const STATE_PREPARING_TO_EXPLODE :int = 2;
    public static const STATE_AVOID_PLAYER :int = 3;

    public static function createCellSprite (cellType :int, multiplierOrStrain :int,
                                             fromCache :Boolean) :Sprite
    {
        var movie :MovieClip;
        if (cellType == Constants.CELL_SPECIAL) {
            movie = ClientCtx.createSpecialStrainMovie(multiplierOrStrain, fromCache);
            movie.gotoAndStop(1);
        } else {
            movie = ClientCtx.instantiateMovieClip("blood", CELL_MOVIES[cellType], true, fromCache);
            movie.gotoAndPlay(1);
        }

        var sprite :Sprite = SpriteUtil.createSprite();
        sprite.addChild(movie);

        if (cellType == Constants.CELL_MULTIPLIER) {
            sprite.addChild(createMultiplierText(multiplierOrStrain, movie.width, movie.height));
        }

        return sprite;
    }

    public static function createMultiplierText (multiplier :int, width :Number, height :Number)
        :TextField
    {
        var tf :TextField = TextBits.createText(
            String("x" + multiplier),
            1, 0, 0, "center", TextBits.FONT_GARAMOND);

        tf.scaleX = tf.scaleY = Math.min(width / tf.width, height / tf.height);
        tf.x = -tf.width * 0.5;
        tf.y = -tf.height * 0.5;

        return tf;
    }

    public static function getCellRefs (cellType :int = -1) :Array
    {
        return GameCtx.gameMode.getObjectRefsInGroup(getGroupName(cellType));
    }

    public static function getCellCount (cellType :int = -1) :int
    {
        return getCellRefs(cellType).length;
    }

    public static function getCellCollision (obj :CollidableObj, cellType :int = -1) :Cell
    {
        // returns the first cell that collides with the given circle
        var cells :Array = getCellRefs(cellType);

        for each (var cellRef :GameObjectRef in cells) {
            var cell :Cell = cellRef.object as Cell;
            if (cell != null &&
                cell.canCollide &&
                cell.collidesWith(obj)) {
                return cell;
            }
        }

        return null;
    }

    public function Cell (type :int, beingBorn :Boolean, multiplierOrStrain :int)
    {
        _radius = Constants.CELL_RADIUS[type];
        _type = type;

        _multiplier = (type == Constants.CELL_MULTIPLIER ? multiplierOrStrain : 1);
        _specialStrain = (type == Constants.CELL_SPECIAL ? multiplierOrStrain : -1);

        _moveCCW = Rand.nextBoolean(Rand.STREAM_GAME);
        _state = STATE_NORMAL;
        _needsBirth = beingBorn;

        _movieLoadedFromCache = (_type != Constants.CELL_SPECIAL);
        _sprite = createCellSprite(type, multiplierOrStrain, _movieLoadedFromCache);
        _movie = MovieClip(_sprite.getChildAt(0));

        if (_type == Constants.CELL_RED || _type == Constants.CELL_MULTIPLIER) {
            var rotationTime :Number = (_type == Constants.CELL_RED ?
                RED_ROTATION_TIME : BONUS_ROTATION_TIME);
            addTask(new SerialTask(
                new VariableTimedTask(0, 1, Rand.STREAM_GAME),
                new ConstantRotationTask(rotationTime, _moveCCW)));
        }
    }

    override protected function addedToDB () :void
    {
        if (_needsBirth) {
            switch (_type) {
            case Constants.CELL_RED:
                birthRedCell();
                break;

            case Constants.CELL_WHITE:
                birthWhiteCell();
                break;

            case Constants.CELL_SPECIAL:
                birthSpecialCell();
                break;

            case Constants.CELL_MULTIPLIER:
                birthMultiplierCell();
                break;
            }
        }
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    override protected function destroyed () :void
    {
        if (_movieLoadedFromCache) {
            SwfResource.releaseMovieClip(_movie);
        }
        super.destroyed();
    }

    public function attachToCursor (cursor :PlayerCursor) :void
    {
        _attachedTo = cursor.ref;

        if (_type == Constants.CELL_WHITE && !ClientCtx.isCorruption) {
            attachTip(TipFactory.DROP_WHITE);
        }
    }

    public function detachFromCursor () :void
    {
        _attachedTo = GameObjectRef.Null();
        addNamedTask(DETACH_COOLDOWN_TASK, new TimedTask(DETACH_COOLDOWN_TIME));
    }

    public function get isAttachedToCursor () :Boolean
    {
        return (!_attachedTo.isNull);
    }

    protected function attachTip (type :int) :void
    {
        if (!_attachedTip.isNull) {
            _attachedTip.object.destroySelf();
        }

        _attachedTip = GameCtx.tipFactory.createTip(type, this);
    }

    protected function birthRedCell () :void
    {
        _state = STATE_BIRTH;

        // When red cells are born, they burst out of the center of the heart
        this.x = Constants.GAME_CTR.x;
        this.y = Constants.GAME_CTR.y;

        // Hack: put birthed red cells on a different layer, so that they appear under the heart.
        // Pop them up to the cell layer after they're born.
        GameCtx.cellBirthLayer.addChild(this.displayObject);

        // fire out of the heart in a random direction
        var angle :Number = Rand.nextNumberInRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var distRange :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_RED];
        var dist :Number = distRange.next();
        var birthTarget :Vector2 = Vector2.fromAngle(angle, dist).addLocal(Constants.GAME_CTR);

        var thisCell :Cell = this;
        addTask(new SerialTask(
            LocationTask.CreateEaseOut(
                birthTarget.x, birthTarget.y,
                ClientCtx.variantSettings.normalCellBirthTime),
            new FunctionTask(function () :void {
                GameCtx.cellLayer.addChild(thisCell.displayObject);
                _state = STATE_NORMAL;
            })));

        // fade in
        this.alpha = 0;
        addTask(new AlphaTask(1, ClientCtx.variantSettings.normalCellBirthTime));

        attachTip(ClientCtx.isCorruption ? TipFactory.CORRUPTION_AVOID_RED : TipFactory.POP_RED);
    }

    protected function birthWhiteCell () :void
    {
        // pick a random location on the outside of the board
        var angle :Number = Rand.nextNumberInRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var distRange :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_WHITE];
        var dist :Number = distRange.next();
        var loc :Vector2 = Vector2.fromAngle(angle, dist).addLocal(Constants.GAME_CTR);
        this.x = loc.x;
        this.y = loc.y;

        if (ClientCtx.variantSettings.whiteCellBirthTime > 0) {
            _state = STATE_BIRTH;
            this.alpha = 0;
            addTask(new SerialTask(
                new AlphaTask(1, ClientCtx.variantSettings.whiteCellBirthTime),
                new FunctionTask(function () :void {
                    _state = STATE_NORMAL;
                })));

        } else {
            _state = STATE_NORMAL;
        }

        // white cells explode after a bit of time
        _movie.gotoAndStop(1);
        var thisCell :Cell = this;
        addNamedTask(EXPLODE_TASK, new SerialTask(
            new TimedTask(ClientCtx.variantSettings.whiteCellNormalTime),
            new FunctionTask(function () :void {
                _state = STATE_PREPARING_TO_EXPLODE;
            }),
            new ShowFramesTask(_movie, 1, ShowFramesTask.LAST_FRAME,
                               ClientCtx.variantSettings.whiteCellExplodeTime),
            new FunctionTask(function () :void {
                GameObjects.createCorruptionBurst(thisCell, null);
                GameCtx.gameMode.onWhiteCellBurst();
            })));

        if (!ClientCtx.isCorruption) {
            attachTip(TipFactory.GRAB_WHITE);
        }
    }

    protected function birthSpecialCell () :void
    {
        // pick a random location anywhere on the board
        var angle :Number = Rand.nextNumberInRange(0, Math.PI * 2, Rand.STREAM_GAME);
        var distRange :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_SPECIAL];
        var dist :Number = distRange.next();
        var loc :Vector2 = Vector2.fromAngle(angle, dist).addLocal(Constants.GAME_CTR);
        this.x = loc.x;
        this.y = loc.y;

        _state = STATE_BIRTH;

        this.alpha = 0;
        addTask(new SerialTask(
            new AlphaTask(1, ClientCtx.variantSettings.normalCellBirthTime),
            new FunctionTask(function () :void {
                _state = STATE_NORMAL;
            })));

        if (!ClientCtx.isCorruption) {
            attachTip(TipFactory.GET_SPECIAL);
        }
    }

    protected function birthMultiplierCell () :void
    {
        attachTip(ClientCtx.isCorruption ?
            TipFactory.CORRUPTION_MULTIPLIER :
            TipFactory.GET_MULTIPLIER);
    }

    override protected function update (dt :Number) :void
    {
        super.update(dt);

        if (GameCtx.gameOver) {
            this.removeAllTasks();
        } else {
            var cursor :PlayerCursor = _attachedTo.object as PlayerCursor;
            if (cursor == null) {
                if (_state == STATE_NORMAL) {
                    orbitHeart(dt);
                }
            }
        }
    }

    protected function orbitHeart (dt :Number) :void
    {
        // move around the heart
        var curLoc :Vector2 = this.loc;
        var ctrImpulse :Vector2 = (this.orbitMovementType == ORBIT_OUTWARDS ?
            curLoc.subtract(Constants.GAME_CTR) :
            Constants.GAME_CTR.subtract(curLoc));

        var perpImpulse :Vector2 = ctrImpulse.getPerp(_moveCCW);
        perpImpulse.length = 3.5;

        ctrImpulse.length = 2;

        var speed :Number = (_type == Constants.CELL_WHITE ?
                             ClientCtx.variantSettings.whiteCellSpeed :
                             ClientCtx.variantSettings.normalCellSpeed);

        var impulse :Vector2 = (this.orbitMovementType == ORBIT_NORMAL ?
                                perpImpulse :
                                ctrImpulse.add(perpImpulse));
        impulse.length = speed * dt;

        curLoc.x += impulse.x;
        curLoc.y += impulse.y;

        curLoc = GameCtx.clampLoc(curLoc);

        this.x = curLoc.x;
        this.y = curLoc.y;
    }

    protected function followPlayer (dt :Number) :void
    {
        var curLoc :Vector2 = this.loc;
        var v :Vector2 = GameCtx.cursor.loc.subtract(curLoc);
        v.length = SPEED_FOLLOW * dt;
        v.addLocal(curLoc);
        v = GameCtx.clampLoc(v);

        this.x = v.x;
        this.y = v.y;
    }

    protected function avoidPlayer () :void
    {
        var curLoc :Vector2 = this.loc;
        var v :Vector2 = curLoc.subtract(GameCtx.cursor.loc);
        var dist2 :Number = v.lengthSquared;
        if (dist2 < (SPECIAL_CELL_MIN_PLAYER_DISTANCE * SPECIAL_CELL_MIN_PLAYER_DISTANCE)) {
            // Pick a location to run away to
            var newDist :Number = SPECIAL_CELL_AVOID_PLAYER_DISTANCE.next();
            v.length = newDist;
            v.addLocal(curLoc);
            v = GameCtx.clampLoc(v);
            var oldState :int = _state;

            // Run!
            addNamedTask("AvoidPlayer", new SerialTask(
                LocationTask.CreateEaseOut(v.x, v.y, SPECIAL_CELL_AVOID_PLAYER_TIME),
                new FunctionTask(function () :void {
                    _state = oldState;
                })),
                true);

            _state = STATE_AVOID_PLAYER;
        }
    }

    override public function getObjectGroup (groupNum :int) :String
    {
        switch (groupNum) {
        case 0:     return getGroupName(_type);
        case 1:     return getGroupName(-1);
        default:    return super.getObjectGroup(groupNum - 2);
        }
    }

    public function get type () :int
    {
        return _type;
    }

    public function get state () :int
    {
        return _state;
    }

    public function get multiplier () :int
    {
        return _multiplier;
    }

    public function get specialStrain () :int
    {
        return _specialStrain;
    }

    public function get isRedCell () :Boolean
    {
        return _type == Constants.CELL_RED;
    }

    public function get isWhiteCell () :Boolean
    {
        return _type == Constants.CELL_WHITE;
    }

    public function get canCollide () :Boolean
    {
        return true;
    }

    public function get canAttach () :Boolean
    {
        return !(this.hasTasksNamed(DETACH_COOLDOWN_TASK));
    }

    protected function get orbitMovementType () :int
    {
        switch (_type) {
        case Constants.CELL_WHITE:
        case Constants.CELL_SPECIAL:
            return ORBIT_INWARDS;

        case Constants.CELL_MULTIPLIER:
            return ORBIT_NORMAL;

        default:
            return ORBIT_OUTWARDS;
        }
    }

    protected static function getGroupName (cellType :int) :String
    {
        return (cellType < 0 ? "Cell" : "Cell_" + cellType);
    }

    protected var _type :int;
    protected var _state :int;
    protected var _multiplier :int;
    protected var _specialStrain :int;
    protected var _moveCCW :Boolean;
    protected var _attachedTo :GameObjectRef = GameObjectRef.Null();
    protected var _needsBirth :Boolean;

    protected var _sprite :Sprite;
    protected var _movie :MovieClip;
    protected var _movieLoadedFromCache :Boolean;
    protected var _attachedTip :GameObjectRef = GameObjectRef.Null();

    protected static const SPEED_FOLLOW :Number = 60;

    protected static const ORBIT_NORMAL :int = 0;
    protected static const ORBIT_INWARDS :int = 1;
    protected static const ORBIT_OUTWARDS :int = 2;

    protected static const RED_ROTATION_TIME :Number = 3;
    protected static const BONUS_ROTATION_TIME :Number = 1.5;

    protected static const DETACH_COOLDOWN_TIME :Number = 1.5;

    protected static const SPECIAL_CELL_MIN_PLAYER_DISTANCE :Number = 80;
    protected static const SPECIAL_CELL_AVOID_PLAYER_DISTANCE :NumRange =
        new NumRange(90, 100, Rand.STREAM_GAME);
    protected static const SPECIAL_CELL_AVOID_PLAYER_TIME :Number = 0.5;

    protected static const EXPLODE_TASK :String = "Explode";
    protected static const DETACH_COOLDOWN_TASK :String = "DetachCooldown";

    protected static const CELL_MOVIES :Array = [ "cell_red", "cell_white", "cell_coop" ];
}

}
