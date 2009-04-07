﻿package vampire.avatar {

import com.whirled.AvatarControl;
import com.whirled.ControlEvent;
import com.whirled.contrib.ColorMatrix;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.filters.BitmapFilter;
import flash.filters.ColorMatrixFilter;
import flash.utils.ByteArray;

public class VampireBody extends MovieClipBody
{
    public static const UPSELL :int = 0;
    public static const CONFIGURABLE :int = 1;

    public function VampireBody (ctrl :AvatarControl,
                                 media :MovieClip,
                                 configPanelType :int,
                                 hairNames :Array,
                                 topNames :Array,
                                 shoeNames :Array,
                                 upsellItemId :int,
                                 width :int, height :int = -1)
    {
        super(ctrl, media, width, height);

        _configPanelType = configPanelType;

        _hairNames = hairNames;
        _topNames = topNames;
        _shoeNames = shoeNames;

        _upsellItemId = upsellItemId;

        // Entity memory-based configuration
        loadConfig();
        if (_ctrl.hasControl()) {
            _ctrl.registerCustomConfig(createConfigPanel);
        }

        _ctrl.addEventListener(ControlEvent.MEMORY_CHANGED,
            function (e :ControlEvent) :void {
                if (e.name == MEMORY_CONFIG) {
                    loadConfig();
                }
            });

        //Notify the game when we arrive at a movement destination
        _movementNotifier = new AvatarEndMovementNotifier(_ctrl);

        //Register custom properties
        if(_ctrl.hasControl()) {
            _ctrl.registerPropertyProvider(propertyProvider);
        }
    }

    protected function propertyProvider (key :String) :Object
    {
        switch(key) {

            case ENTITY_PROPERTY_IS_LEGAL_AVATAR:
                return true;

           default://The rest of the properties are provided by the movement notifier.
                return _movementNotifier.propertyProvider(key);
        }
    }

    protected function createConfigPanel () :Sprite
    {
        switch (_configPanelType) {
        case CONFIGURABLE:
            return new VampatarConfigPanel(
                _hairNames,
                _topNames,
                _shoeNames,
                _curConfig,
                function (newConfig :VampatarConfig) :void {
                    saveConfig(newConfig);
                    applyConfig(newConfig);
                });

        case UPSELL:
            return new VampatarUpsellPanel(_ctrl, _upsellItemId);
        }

        return null;
    }

    protected function loadConfig () :void
    {
        var config :VampatarConfig = new VampatarConfig();
        var bytes :ByteArray = _ctrl.getMemory(MEMORY_CONFIG) as ByteArray;
        if (bytes != null) {
            try {
                bytes.position = 0;
                config.fromBytes(bytes);
            } catch (e :Error) {
                log.warning("Error loading VampatarConfig", e);
            }
        }

        applyConfig(config);
    }

    protected function saveConfig (config :VampatarConfig) :void
    {
        _ctrl.setMemory(MEMORY_CONFIG, config.toBytes(),
            function (success :Boolean) :void {
                if (!success) {
                    log.warning("Failed to save VampatarConfig!");
                }
            });
    }

    protected function applyConfig (config :VampatarConfig) :void
    {
        _curConfig = config;
        var allMovies :Array = getAllMovies();
        selectCurConfigFrames(allMovies);
        applyCurConfigFilters(allMovies);
    }

    protected function selectCurConfigFrames (movies :Array) :void
    {
        //log.info("Selecting frames for " + movies.length + " movies");

        for each (var movie :MovieClip in movies) {
            // Shirt
            selectFrame(movie, [ "torso", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "neck", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "hips", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "breasts", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "breasts", "skin" ], _curConfig.topNumber);
            selectFrame(movie, [ "bicepL", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "bicepR", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "bicepL", "skin" ], _curConfig.topNumber);
            selectFrame(movie, [ "bicepR", "skin" ], _curConfig.topNumber);
            selectFrame(movie, [ "forearmL", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "forearmR", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "forearmL", "skin" ], _curConfig.topNumber);
            selectFrame(movie, [ "forearmR", "skin" ], _curConfig.topNumber);
            selectFrame(movie, [ "handL", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "handR", "shirt" ], _curConfig.topNumber);
            selectFrame(movie, [ "handL", "skin" ], _curConfig.topNumber);
            selectFrame(movie, [ "handR", "skin" ], _curConfig.topNumber);

            // Hair
            selectFrame(movie, [ "head", "scalp", "scalp" ], _curConfig.hairNumber);
            selectFrame(movie, [ "bangs", "bangs" ], _curConfig.hairNumber);
            selectFrame(movie, [ "hairL", "hairL" ], _curConfig.hairNumber);
            selectFrame(movie, [ "hairR", "hairR" ], _curConfig.hairNumber);
            selectFrame(movie, [ "hair", "hair" ], _curConfig.hairNumber);
            selectFrame(movie, [ "hairTips", "hairTips" ], _curConfig.hairNumber);

            // Shoes
            selectFrame(movie, [ "footL", "shoes" ], _curConfig.shoesNumber);
            selectFrame(movie, [ "footR", "shoes" ], _curConfig.shoesNumber);
            selectFrame(movie, [ "footL", "skin" ], _curConfig.shoesNumber);
            selectFrame(movie, [ "footR", "skin" ], _curConfig.shoesNumber);
            selectFrame(movie, [ "calfL", "shoes" ], _curConfig.shoesNumber);
            selectFrame(movie, [ "calfR", "shoes" ], _curConfig.shoesNumber);
        }
    }

    protected function applyCurConfigFilters (movies :Array) :void
    {
        //log.info("Applying filters to " + movies.length + " movies");

        var skinFilter :ColorMatrixFilter = createColorFilter(_curConfig.skinColor);
        var hairFilter :ColorMatrixFilter = createColorFilter(_curConfig.hairColor);
        var shirtFilter :ColorMatrixFilter = createColorFilter(_curConfig.topColor);
        var pantsFilter :ColorMatrixFilter = createColorFilter(_curConfig.pantsColor);
        var shoesFilter :ColorMatrixFilter = createColorFilter(_curConfig.shoesColor);

        for each (var movie :MovieClip in movies) {
            // Skin color
            applyFilter(movie, [ "head", "head" ], skinFilter);
            applyFilter(movie, [ "head", "ear" ], skinFilter);
            applyFilter(movie, [ "neck", "skin" ], skinFilter);
            applyFilter(movie, [ "bicepL", "skin" ], skinFilter);
            applyFilter(movie, [ "bicepR", "skin" ], skinFilter);
            applyFilter(movie, [ "forearmL", "skin" ], skinFilter);
            applyFilter(movie, [ "forearmR", "skin" ], skinFilter);
            applyFilter(movie, [ "handL", "skin" ], skinFilter);
            applyFilter(movie, [ "handR", "skin" ], skinFilter);
            applyFilter(movie, [ "breasts", "skin" ], skinFilter);
            applyFilter(movie, [ "torso", "skin" ], skinFilter);
            applyFilter(movie, [ "hips", "skin" ], skinFilter);
            applyFilter(movie, [ "calfL", "skin" ], skinFilter);
            applyFilter(movie, [ "calfR", "skin" ], skinFilter);
            applyFilter(movie, [ "footL", "skin" ], skinFilter);
            applyFilter(movie, [ "footR", "skin" ], skinFilter);

            // Hair color
            applyFilter(movie, [ "head", "scalp", "scalp", ], hairFilter);
            applyFilter(movie, [ "head", "eyebrows", ], hairFilter);
            applyFilter(movie, [ "hairTips", "hairTips", ], hairFilter);
            applyFilter(movie, [ "bangs", "bangs", ], hairFilter);
            applyFilter(movie, [ "hairL", "hairL", ], hairFilter);
            applyFilter(movie, [ "hairR", "hairR", ], hairFilter);
            applyFilter(movie, [ "hair", "hair", ], hairFilter);

            // Shirt color
            applyFilter(movie, [ "neck", "shirt", ], shirtFilter);
            applyFilter(movie, [ "bicepL", "shirt", ], shirtFilter);
            applyFilter(movie, [ "bicepR", "shirt", ], shirtFilter);
            applyFilter(movie, [ "forearmL", "shirt", ], shirtFilter);
            applyFilter(movie, [ "forearmR", "shirt", ], shirtFilter);
            applyFilter(movie, [ "handL", "shirt", ], shirtFilter);
            applyFilter(movie, [ "handR", "shirt", ], shirtFilter);
            applyFilter(movie, [ "breasts", "shirt", ], shirtFilter);
            applyFilter(movie, [ "torso", "shirt", ], shirtFilter);
            applyFilter(movie, [ "hips", "shirt", ], shirtFilter);

            // Pants color
            applyFilter(movie, [ "hips", "pants", ], pantsFilter);
            applyFilter(movie, [ "thighL", "pants", ], pantsFilter);
            applyFilter(movie, [ "thighR", "pants", ], pantsFilter);
            applyFilter(movie, [ "calfL", "pants", ], pantsFilter);
            applyFilter(movie, [ "calfR", "pants", ], pantsFilter);
            applyFilter(movie, [ "footL", "pants", ], pantsFilter);
            applyFilter(movie, [ "footR", "pants", ], pantsFilter);

            // Shoes color
            applyFilter(movie, [ "calfL", "shoes", ], shoesFilter);
            applyFilter(movie, [ "calfR", "shoes", ], shoesFilter);
            applyFilter(movie, [ "footL", "shoes", ], shoesFilter);
            applyFilter(movie, [ "footR", "shoes", ], shoesFilter);
        }
    }

    override protected function playMovie (movie :MovieClip) :void
    {
        super.playMovie(movie);

        if (movie != null) {
            //log.info("Restarting movies");
            // recursively restart all movies
            restartAllMovies(movie);
            // and reselect our configurations
            selectCurConfigFrames([ movie ]);
        }
    }

    protected static function restartAllMovies (disp :DisplayObjectContainer) :void
    {
        if (disp is MovieClip) {
            (disp as MovieClip).gotoAndPlay(1);
        }

        for (var ii :int = 0; ii < disp.numChildren; ++ii) {
            var child :DisplayObject = disp.getChildAt(ii);
            if (child is DisplayObjectContainer) {
                restartAllMovies(child as DisplayObjectContainer);
            }
        }
    }

    protected static function findChild (movie :MovieClip, childPath :Array) :MovieClip
    {
        var child :MovieClip = movie;
        for each (var pathElt :String in childPath) {
            child = child[pathElt];
            if (child == null) {
                break;
            }
        }

        return child;
    }

    protected static function selectFrame (movie :MovieClip, childPath :Array,
                                           frameNumber :int) :void
    {
        var child :MovieClip = findChild(movie, childPath);
        if (child != null) {
            child.gotoAndStop(frameNumber);
        }
    }

    protected static function applyFilter (movie :MovieClip, childPath :Array,
                                           filter :BitmapFilter) :void
    {
        var child :MovieClip = findChild(movie, childPath);
        if (child != null) {
            child.filters = [ filter ];
        }
    }

    protected static function createColorFilter (color :uint) :ColorMatrixFilter
    {
        return new ColorMatrix().colorize(color).createFilter();
    }

    protected var _curConfig :VampatarConfig;
    protected var _configPanelType :int;
    protected var _hairNames :Array;
    protected var _topNames :Array;
    protected var _shoeNames :Array;
    protected var _upsellItemId :int;

    /**Notify the game when we arrive at a movement destination*/
    protected var _movementNotifier :AvatarEndMovementNotifier;

    protected static const MEMORY_CONFIG :String = "VampatarConfig";

    /** You must wear a level avatar to play the game */
    public static const ENTITY_PROPERTY_IS_LEGAL_AVATAR :String = "IsLegalVampireAvatar";
}

}
