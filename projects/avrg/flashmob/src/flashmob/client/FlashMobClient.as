//
// $Id$

package flashmob.client {

import com.threerings.util.Log;
import com.whirled.avrg.AVRGameControl;
import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.resource.*;

import flash.display.Sprite;
import flash.events.Event;

import flashmob.*;

[SWF(width="700", height="500")]
public class FlashMobClient extends Sprite
{
    public function FlashMobClient ()
    {
        /*addEventListener(Event.ADDED_TO_STAGE, handleAdded);
        addEventListener(Event.REMOVED_FROM_STAGE, handleUnload);

        // instantiate MainLoop singleton
        new MainLoop(this);
        MainLoop.instance.setup();

        // load resources
        ResourceManager.instance.queueResourceLoad("swf", "ui",     { embeddedClass: Resources.SWF_UI });
        ResourceManager.instance.queueResourceLoad("swf", "board",  { embeddedClass: Resources.SWF_BOARD });
        ResourceManager.instance.queueResourceLoad("swf", "intro",  { embeddedClass: Resources.SWF_INTRO });
        ResourceManager.instance.queueResourceLoad("swf", "help",   { embeddedClass: Resources.SWF_HELP });

        ResourceManager.instance.loadQueuedResources(handleResourcesLoaded, handleResourceLoadError);*/
    }

    /*protected function maybeShowIntro () :void
    {
        if (_addedToStage && _resourcesLoaded) {
            ClientContext.gameCtrl = new AVRGameControl(this);
            ClientContext.gameCtrl.player.addEventListener(AVRGamePlayerEvent.LEFT_ROOM, leftRoom);

            ClientContext.ourPlayerId = (ClientContext.gameCtrl.isConnected()
                ? ClientContext.gameCtrl.player.getPlayerId() : 666);

            ClientContext.items = new BingoItemManager(ClientBingoItems.ITEMS);

            ClientContext.model = new Model();
            ClientContext.model.setup();

            MainLoop.instance.pushMode(new IntroMode());
            MainLoop.instance.run();
        }
    }

    protected function handleResourcesLoaded () :void
    {
        _resourcesLoaded = true;
        this.maybeShowIntro();
    }

    protected function handleResourceLoadError (err :String) :void
    {
        log.warning("Resource load error: " + err);
    }

    protected function handleAdded (event :Event) :void
    {
        log.info("Added to stage: Initializing...");

        _addedToStage = true;
        this.maybeShowIntro();
    }

    protected function handleUnload (event :Event) :void
    {
        log.info("Removed from stage - Unloading...");

        ClientContext.model.destroy();

        MainLoop.instance.shutdown();
    }

    protected function leftRoom (e :Event) :void
    {
        log.debug("leftRoom");
        ClientContext.quit();
    }

    protected var _addedToStage :Boolean;
    protected var _resourcesLoaded :Boolean;

    protected static var log :Log = Log.getLog(BingoMain);*/
}
}
