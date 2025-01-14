//
// $Id$

package popcraft.game.puzzle {

import com.threerings.flashbang.objects.SceneObject;
import com.threerings.flashbang.resource.SwfResource;
import com.threerings.flashbang.tasks.*;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.geom.Point;
import flash.text.TextField;

import popcraft.*;

public class ResourceValueAnim extends SceneObject
{
    public function ResourceValueAnim (loc :Point, resourceType :int, amount :int)
    {
        var movieName :String = (amount >= 0 ?
            POS_CLEAR_FEEDBACK_ANIM_NAMES[resourceType] :
            NEG_CLEAR_FEEDBACK_ANIM_NAMES[resourceType]);

        _movie = ClientCtx.instantiateMovieClip("dashboard", movieName, true, true);
        _movie.cacheAsBitmap = true;

        // fill in the text
        var textField :TextField = _movie["feedback"];
        textField.text = String(amount);

        this.x = loc.x;
        this.y = loc.y;
        this.alpha = 1;

        // move up, fade out, and self-destruct;
        addTask(new SerialTask(
            new ParallelTask(
                LocationTask.CreateEaseIn(loc.x, loc.y - 35, 0.6),
                After(0.45, new AlphaTask(0, 0.15))),
            new SelfDestructTask()));
    }

    override public function get displayObject () :DisplayObject
    {
        return _movie;
    }

    override protected function cleanup () :void
    {
        SwfResource.releaseMovieClip(_movie);
        super.cleanup();
    }

    protected var _movie :MovieClip;

    protected static const POS_CLEAR_FEEDBACK_ANIM_NAMES :Array = [
        "feedback_A", "feedback_B", "feedback_C", "feedback_D"
    ];
    protected static const NEG_CLEAR_FEEDBACK_ANIM_NAMES :Array = [
        "feedback_A_negative", "feedback_B_negative", "feedback_C_negative", "feedback_D_negative"
    ];

}

}
