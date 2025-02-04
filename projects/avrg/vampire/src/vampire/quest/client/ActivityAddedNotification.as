package vampire.quest.client {

import com.threerings.flashbang.objects.SceneObject;
import com.threerings.flashbang.tasks.*;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;

import vampire.client.SpriteUtil;
import vampire.quest.*;

public class ActivityAddedNotification extends SceneObject
{
    public function ActivityAddedNotification (activity :ActivityDesc)
    {
        _activity = activity;
        _sprite = SpriteUtil.createSprite();
    }

    override protected function addedToDB () :void
    {
        var movie :MovieClip = ClientCtx.instantiateMovieClip("quest", "popup_sitequest");

        var contents :MovieClip = movie["contents"];
        var tfLocation :TextField = contents["context_name"];
        var tfActivity :TextField = contents["item_name"];

        tfLocation.text = "New Location";
        tfActivity.text = _activity.displayName;

        var burst :MovieClip = contents["complete_burst"];
        var checkmark :MovieClip = contents["complete_check"];
        burst.parent.removeChild(burst);
        checkmark.parent.removeChild(checkmark);

        _sprite.addChild(movie);
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    protected var _sprite :Sprite;
    protected var _activity :ActivityDesc
}

}
