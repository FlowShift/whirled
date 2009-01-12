package flashmob.client {

import com.threerings.util.Log;
import com.whirled.contrib.simplegame.resource.SwfResource;

import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextField;

import flashmob.*;
import flashmob.client.view.*;
import flashmob.data.*;

public class MainMenuMode extends GameDataMode
{
    override protected function setup () :void
    {
        super.setup();

        // create the main UI and make it draggable
        _ui = SwfResource.instantiateMovieClip("Spectacle_UI", "mainUI");
        addObject(new Dragger(_ui["dragmain"], _ui));
        _modeSprite.addChild(_ui);

        var bounds :Rectangle = ClientContext.roomDisplayBounds;
        _ui.x = bounds.left - 120 + (bounds.width * 0.5);
        _ui.y = bounds.top - 150 + (bounds.width * 0.5);

        // wire up buttons
        var creatorModeButton :SimpleButton = _ui["makeyourown"];
        if (ClientContext.isPartyLeader) {
            registerOneShotCallback(creatorModeButton, MouseEvent.CLICK,
                function (...ignored) :void {
                    ClientContext.outMsg.sendMessage(Constants.MSG_C_CREATE_SPEC);
                });

        } else {
            creatorModeButton.visible = false;
        }

        var quitButton :SimpleButton = _ui["close"];
        registerListener(quitButton, MouseEvent.CLICK,
            function (...ignored) :void {
                ClientContext.confirmQuit();
            });

        _prevButton = _ui["prev"];
        registerListener(_prevButton, MouseEvent.CLICK,
            function (...ignored) :void {
                showSpectacleThumbs(_firstVisibleSpecIndex - SPECTACLE_THUMB_ANCHORS.length);
            });

        _nextButton = _ui["next"];
        registerListener(_nextButton, MouseEvent.CLICK,
            function (...ignored) :void {
                showSpectacleThumbs(_firstVisibleSpecIndex + SPECTACLE_THUMB_ANCHORS.length);
            });

        _dataBindings.bindProp(Constants.PROP_AVAIL_SPECTACLES, handleAvailSpectacles,
            SpectacleSet.fromBytes);
        _dataBindings.processAllProperties(ClientContext.props);
    }

    protected function handleAvailSpectacles (specSet :SpectacleSet) :void
    {
        _availSpectacles = specSet;
        showSpectacleThumbs(0);
    }

    protected function showSpectacleThumbs (fromIndex :int) :void
    {
        for (var ii :int = 0; ii < SPECTACLE_THUMB_ANCHORS.length; ++ii) {
            var anchor :MovieClip = _ui[SPECTACLE_THUMB_ANCHORS[ii]];
            if (anchor.numChildren > 0) {
                anchor.removeChildAt(0);
            }

            if (_availSpectacles != null && fromIndex + ii < _availSpectacles.spectacles.length) {
                var spec :Spectacle = _availSpectacles.spectacles[fromIndex + ii];
                var specThumb :MovieClip = SwfResource.instantiateMovieClip("Spectacle_UI",
                    "spectacleThumb");
                var nameTf :TextField = specThumb["specname"];
                nameTf.text = spec.name;

                anchor.addChild(specThumb);

                if (ClientContext.isPartyLeader) {
                    registerOneShotCallback(specThumb, MouseEvent.CLICK,
                        createSpectacleSelectedHandler(spec));
                }
            }
        }

        _prevButton.visible = (_availSpectacles != null && fromIndex > 0);
        _nextButton.visible = (_availSpectacles != null &&
            fromIndex + SPECTACLE_THUMB_ANCHORS.length < _availSpectacles.spectacles.length);

        _firstVisibleSpecIndex = fromIndex;
    }

    protected function createSpectacleSelectedHandler (spectacle :Spectacle) :Function
    {
        return function (...ignored) :void {
            if (!_spectacleSelected) {
                ClientContext.outMsg.sendMessage(Constants.MSG_C_SELECTED_SPEC, spectacle.id);
                _spectacleSelected = true;
            }
        }
    }

    protected function get log () :Log
    {
        return FlashMobClient.log;
    }

    protected var _ui :MovieClip;
    protected var _prevButton :SimpleButton;
    protected var _nextButton :SimpleButton;

    protected var _availSpectacles :SpectacleSet;
    protected var _spectacleSelected :Boolean;
    protected var _firstVisibleSpecIndex :int;

    protected static const SPECTACLE_THUMB_ANCHORS :Array = [
        "locator1",
        "locator2",
        "locator3",
        "locator4"
    ];
}

}