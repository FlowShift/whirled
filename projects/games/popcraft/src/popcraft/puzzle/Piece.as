package popcraft.puzzle {

import com.whirled.contrib.simplegame.objects.*;
import com.whirled.contrib.simplegame.resource.*;
import com.whirled.contrib.simplegame.tasks.*;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;

import popcraft.*;
import popcraft.util.*;

public class Piece extends SceneObject
{
    public function Piece (resourceType :int, boardIndex :int)
    {
        this.resourceType = resourceType;

        _boardIndex = boardIndex;
    }

    // from SceneObject
    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    public function get boardIndex () :int
    {
        return _boardIndex;
    }

    public function set boardIndex (newIndex :int) :void
    {
        _boardIndex = newIndex;
    }

    public function get resourceType () :int
    {
        return _resourceType;
    }

    public function set resourceType (newType :int) :void
    {
        // load the piece classes if they aren't already loaded
        if (null == SWF_CLASSES) {
            SWF_CLASSES = [];
            var swf :SwfResource = (ResourceManager.instance.getResource("puzzlePieces") as SwfResource);
            for each (var className :String in SWF_CLASS_NAMES) {
                SWF_CLASSES.push(swf.getClass(className));
            }
        }

        _resourceType = newType;

        var pieceClass :Class = SWF_CLASSES[newType];
        var pieceMovie :MovieClip = new pieceClass();

        pieceMovie.x = -(pieceMovie.width * 0.5);
        pieceMovie.y = -(pieceMovie.height * 0.5);

        pieceMovie.cacheAsBitmap = true;

        _sprite = SpriteUtil.createSprite();
        _sprite.addChild(pieceMovie);
    }

    protected var _boardIndex :int;

    protected var _resourceType :int;
    protected var _sprite :Sprite;

    protected static var SWF_CLASSES :Array;
    protected static const SWF_CLASS_NAMES :Array = [ "A", "B", "C", "D" ];
}

}
