package ghostbusters.client.fight.common {

import com.whirled.contrib.simplegame.resource.*;

public class Resources
{
    public static function get instance () :Resources
    {
        if (null == g_instance) {
            new Resources();
        }

        return g_instance;
    }

    public function Resources ()
    {
        if (null != g_instance) {
            throw new Error("Resources is a singleton class and cannot be instantiated more than once");
        }

        g_instance = this;
    }

    public function loadAll (completeCallback :Function, errorCallback :Function = null) :void
    {
        if (_loaded) {
            completeCallback();
            return;
        }

        _loaded = true;

        // for now, just naively load all resources we might need.
        // change this if it becomes too much of a burden.

        ResourceManager.instance.queueResourceLoad("swf", "intro.screen", { embeddedClass: SWF_INTROSCREEN });
        ResourceManager.instance.queueResourceLoad("swf", "outro.screen", { embeddedClass: SWF_OUTROSCREEN });

        ResourceManager.instance.queueResourceLoad("swf", "lantern.heart", { embeddedClass: SWF_HEART });

//        ResourceManager.instance.queueResourceLoad("image", "ouija.planchette", { embeddedClass: IMAGE_PLANCHETTE });
        ResourceManager.instance.queueResourceLoad("swf", "ouija.board", { embeddedClass: SWF_BOARD });
        ResourceManager.instance.queueResourceLoad("swf", "ouija.timer", { embeddedClass: SWF_TIMER });
//        ResourceManager.instance.queueResourceLoad("image", "ouija.pictoboard", { embeddedClass: IMAGE_PICTOBOARD });

//        ResourceManager.instance.queueResourceLoad("swf", "potions.board", { embeddedClass: SWF_HUEANDCRYBOARD });

        ResourceManager.instance.queueResourceLoad("swf", "spiritshell.board", { embeddedClass: SWF_SPIRITSHELL });
        ResourceManager.instance.queueResourceLoad("swf", "iraq.board", { embeddedClass: SWF_IRAQ_BOARD });
        

        ResourceManager.instance.loadQueuedResources(completeCallback, errorCallback);
    }

    public function get isLoading () :Boolean
    {
        return ResourceManager.instance.isLoading;
    }

    protected var _loaded :Boolean;

    protected static var g_instance :Resources;

    /* intro/outro */
    [Embed(source="../../../../../rsrc/Microgames/gameDirections.swf", mimeType="application/octet-stream")]
    protected static const SWF_INTROSCREEN :Class;

    [Embed(source="../../../../../rsrc/Microgames/minigame_outro.swf", mimeType="application/octet-stream")]
    protected static const SWF_OUTROSCREEN :Class;

    [Embed(source="../../../../../rsrc/Microgames/heart.swf", mimeType="application/octet-stream")]
    protected static const SWF_HEART :Class;

    /* Ouija */
//    [Embed(source="../../../../../rsrc/Fonts/DelitschAntiqua.ttf", fontName="DelitschAntiqua")]
//    public static const FONT_GAME :Class;
//
//    public static const OUIJA_FONT_NAME :String = "DelitschAntiqua";

//    [Embed(source="../../../../../rsrc/Microgames/ouijaplanchette.png", mimeType="application/octet-stream")]
//    protected static const IMAGE_PLANCHETTE :Class;

    [Embed(source="../../../../../rsrc/Microgames/Ouija_animated_01.swf", mimeType="application/octet-stream")]
    protected static const SWF_BOARD :Class;

    [Embed(source="../../../../../rsrc/Microgames/Ouija_timer_10fnew.swf", mimeType="application/octet-stream")]
    protected static const SWF_TIMER :Class;

//    [Embed(source="../../../../../rsrc/Microgames/pictogeistboard.png", mimeType="application/octet-stream")]
//    protected static const IMAGE_PICTOBOARD :Class;

    /* Plasma */
    [Embed(source="../../../../../rsrc/Microgames/blaster_ghost.swf", mimeType="application/octet-stream")]
    protected static const SWF_SPIRITSHELL :Class;

    /* Potions */
//    [Embed(source="../../../../../rsrc/Microgames/ectopotions_code_no_opening.swf", mimeType="application/octet-stream")]
//    protected static const SWF_HUEANDCRYBOARD :Class;
    
    /* Iraq */
    [Embed(source="../../../../../rsrc/Microgames/Iraq.swf", mimeType="application/octet-stream")]
    protected static const SWF_IRAQ_BOARD:Class;

}

}
