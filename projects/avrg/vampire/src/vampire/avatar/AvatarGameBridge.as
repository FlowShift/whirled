﻿package vampire.avatar{import com.threerings.flash.MathUtil;import com.threerings.util.ArrayUtil;import com.threerings.util.HashMap;import com.threerings.util.Log;import com.threerings.util.StringBuilder;import com.whirled.AvatarControl;import com.whirled.ControlEvent;import com.whirled.EntityControl;import com.whirled.contrib.EventHandlerManager;import flash.events.Event;import flash.events.TimerEvent;import flash.utils.Timer;import vampire.data.VConstants;/** * Monitors other room entities and reports to the AVRG game client * the closest avatar (not necessarily playing the game). * */public class AvatarGameBridge{    /**    *    * applyColorScheme: a function to change the avatar color state.    *   e.g. applyColorScheme( Constants.COLOR_SCHEME_VAMPIRE)    */    public function AvatarGameBridge( ctrl :AvatarControl, applyColorScheme :Function)    {        _ctrl = ctrl;        _colorSchemeFunction = applyColorScheme;        _ctrl.registerPropertyProvider(propertyProvider);//        _ctrl.registerPropertyProvider(vampireStatePropertyProvider);//        _ctrl.registerPropertyProvider(locationChangedPropertyProvider);        //All entities listen for color change signals//        _events.registerListener(_ctrl, ControlEvent.SIGNAL_RECEIVED, handleSignalReceived);        //Only the controlling instance updates entity locations.        if( _ctrl.hasControl()) {    //        _ctrl.addEventListener(ControlEvent.STATE_CHANGED, handleStateChange);            _events.registerListener(_ctrl, ControlEvent.CHAT_RECEIVED, handleChatReceived);            _events.registerListener(_ctrl, ControlEvent.ENTITY_ENTERED, handleEntityEntered );            _events.registerListener(_ctrl, ControlEvent.ENTITY_LEFT, handleEntityLeft );            _events.registerListener(_ctrl, ControlEvent.ENTITY_MOVED, handleEntityMoved);            _ctrl.setTickInterval(UPDATE_INTERVAL_MS);            _events.registerListener(_ctrl, TimerEvent.TIMER, update);        }        else {            trace("warning, we think this avatar, playerid=" + playerId + " is not in control, so no listeners.");        }//        trace("playerid=" + playerId + ", entityId=" + _ctrl.getMyEntityId());        _events.registerListener(_ctrl, Event.UNLOAD, handleUnload);        trace("When we load, avatar locations:");        storeAllCurrentAvatarLocations(true);    }    protected function propertyProvider(key :String) :Object    {        switch( key ) {            case ENTITY_PROPERTY_AVATAR_LOCATIONS:                _isLocationsChanged = false;                var locationData :Array = new Array();                _userLocations.forEach(function( userId :int, data :Array) :void {                    locationData.push( [userId, data] );                });                return locationData;            case ENTITY_PROPERTY_IS_AVATAR_ARRIVED_AT_DESTINATION:                //If true, reset to false                if( _isUserArrivedAtDestination ) {                    _isUserArrivedAtDestination = false;                    return true;                }                return false;            case ENTITY_PROPERTY_VAMPIRE_STATE:                return _colorSchemeFunction() as Object;            case ENTITY_PROPERTY_IS_LOCATIONS_CHANGED:                return _isLocationsChanged;            case ENTITY_PROPERTY_CHAT_TARGETS:                return _chatRecord.validPlayerIds;            case ENTITY_PROPERTY_RESET_LOCATIONS:                resetLocations();                return true;            case ENTITY_PROPERTY_CURRENT_COLOR_SCHEME:                return _currentColorScheme;           case ENTITY_PROPERTY_CHANGE_COLOR_SCHEME_FUNCTION:                return _colorSchemeFunction as Object;            case ENTITY_PROPERTY_SETFREEZE_FUNCTION:                return setFreeze as Object;            case ENTITY_PROPERTY_SETSTATE_FUNCTION:                return setState as Object;            case ENTITY_PROPERTY_SETTARGET_FUNCTION:                return setTarget as Object;            case ENTITY_PROPERTY_IS_LEGAL_AVATAR:                return true;           default:                return null;        }    }    protected function update(...ignored) :void    {        _chatRecord.update();    }    protected function setTarget( targetId :int) :void    {        trace("Setting target");        _targetId = targetId;    }    protected function setFreeze( frozen :Boolean) :void    {        _isFrozen = frozen;    }    protected function setState( newState :String ) :void    {        _ctrl.setState( newState );    }    protected function changeColorScheme( scheme :String ) :void    {//        trace("changeColorScheme(" + scheme + ")");        if( _colorSchemeFunction != null && scheme != null) {            _colorSchemeFunction( scheme );        }    }    protected function resetLocations() :void    {//        trace("resetLocations()");        _userLocations.clear();        _isLocationsChanged = true;        storeAllCurrentAvatarLocations( true );    }//    protected function vampireStatePropertyProvider(key :String) :Object//    {//        trace("vampireStatePropertyProvider(" + key + ")");//        if( key == ENTITY_PROPERTY_VAMPIRE_STATE ) {//            trace("vampireStatePropertyProvider(" + key + "), returning _colorSchemeFunction");//            return _colorSchemeFunction;//        }//        return null;//    }////    protected function locationChangedPropertyProvider(key :String) :Object//    {//        trace("locationChangedPropertyProvider(" + key + ")");//        if( key == ENTITY_PROPERTY_IS_LOCATIONS_CHANGED ) {//            trace("locationChangedPropertyProvider(" + key + "), returning _isLocationsChanged=" + _isLocationsChanged);//            return _isLocationsChanged;//        }//        return null;//    }    protected function setUserLocation( userId :int, location :Array, hotspot :Array ) :void    {        if( !ArrayUtil.equals( location, [0,0,0] ) ) {//            trace("Setting " + userId + " location=" + location );            _userLocations.put( userId, [location, hotspot] );        }    }    protected function handleUnload( ...ignored ) :void    {        _colorSchemeFunction = null;        _events.freeAllHandlers();    }//    protected function sendSignalEntityMoved( entityId :String ) :void//    {//        var userIdMoved :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, entityId));//        //If entityLocation == null, this means the entity has left the room//        var entityLocation :Array = _userLocations.get( userIdMoved ) as Array;//        var entityHotspot :Array = _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOT, entityId) as Array;//        trace("sendSignalEntityMoved(" + userIdMoved + "), sending signal", "location", entityLocation, "hotspot", entityHotspot);////        _userLocations.put( userIdMoved, entityLocation.slice() );////        _ctrl.sendSignal( Constants.SIGNAL_AVATAR_MOVED, [userIdMoved, entityLocation, entityHotspot]);//    }//    protected function handleEntityEntered (e :ControlEvent) :void    {//        trace("entity entered", "e", e);        if( !_ctrl.hasControl()) {            return;        }        //We only care about avatars.        if( _ctrl.getEntityProperty( EntityControl.PROP_TYPE, e.name) != EntityControl.TYPE_AVATAR) {            return;        }        _isLocationsChanged = true;        var userIdMoved :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, e.name));        //If we've entered a room, clear all the previous data.        if( userIdMoved == playerId ) {//            _playerIds.splice(0);            resetLocations();//            storeAllCurrentAvatarLocations(true);        }        else {            var actualLocation :Array = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, e.name) as Array;            var hotspot :Array = _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOT, e.name) as Array;            setUserLocation( userIdMoved, actualLocation, hotspot );//            _userLocations.put( userIdMoved, [actualLocation, hotspot] );        }//        sendLocationsOfAvatars(false);        //We only care about avatars.//        if( _ctrl.getEntityProperty( EntityControl.PROP_TYPE, e.name) != EntityControl.TYPE_AVATAR) {//            return;//        }//        trace("\n" + playerId + " "  + ControlEvent.ENTITY_ENTERED);//        computeClosestAvatar(e);    }    protected function handleEntityLeft (e :ControlEvent) :void    {        if( !_ctrl.hasControl()) {            return;        }        //We only care about avatars.        if( _ctrl.getEntityProperty( EntityControl.PROP_TYPE, e.name) != EntityControl.TYPE_AVATAR) {            return;        }        _isLocationsChanged = true;        var userIdMoved :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, e.name));        //The the server that the non-player has left the game.        _userLocations.remove( userIdMoved );        _userLocationsTempWhileMoving.remove( userIdMoved );//        _chatRecord.chats.remove( userIdMoved );//        _ctrl.sendSignal( Constants.SIGNAL_NON_PLAYER_LEFT_ROOM, userIdMoved);//        sendSignalEntityMoved( e.name );//        _ctrl.sendSignal( Constants.SIGNAL_NON_PLAYER_MOVED, [userIdMoved, null]);//        trace("\n" + playerId + " "  + ControlEvent.ENTITY_LEFT);//        computeClosestAvatar(e);    }//    protected function sendLocationsOfAvatars( onlyAvatarsWithChangedLocations :Boolean = true) :void//    {//        trace("sendLocationsOfAvatars()");//        for each( var entityId :String in _ctrl.getEntityIds(EntityControl.TYPE_AVATAR)) {////            var entityUserId :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, entityId));//////            if( entityUserId == playerId ) {////                continue;////            }////            if( !onlyAvatarsWithChangedLocations || !_userLocations.containsKey( entityUserId )) {//                var entityLocation :Array = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, entityId) as Array;////                var entityHotspot :Array = _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOTL, entityId) as Array;//                _userLocations.put( entityUserId, entityLocation.slice() );//                sendSignalEntityMoved( entityId );//                trace("   Sending " + entityUserId + "=" + entityLocation);////                _ctrl.sendSignal( Constants.SIGNAL_NON_PLAYER_MOVED, [entityUserId, entityLocation, entityHotspot]);//            }////        }//    }    protected function storeAllCurrentAvatarLocations(reset :Boolean = false) :void    {//        trace("storeAllCurrentAvatarLocations()");        _isLocationsChanged = true;        if( reset ) {            _userLocations.clear();        }        for each( var entityId :String in _ctrl.getEntityIds(EntityControl.TYPE_AVATAR)) {            var entityUserId :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, entityId));            var entityLocation :Array = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, entityId) as Array;            var entityHotspot :Array = _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOT, entityId) as Array;            setUserLocation( entityUserId, entityLocation.slice(), entityHotspot );//            _userLocations.put( entityUserId, [entityLocation.slice(), entityHotspot] );        }//        trace(this.toString());    }    protected function handleEntityMoved (e :ControlEvent) :void    {//        trace( "handleEntityMoved( " + e + ") me:" + this);        if( !_ctrl.hasControl()) {            return;        }        //We only care about avatars.        if( _ctrl.getEntityProperty( EntityControl.PROP_TYPE, e.name) != EntityControl.TYPE_AVATAR) {            return;        }        storeAllCurrentAvatarLocations();        _isLocationsChanged = true;//        sendLocationsOfAvatars();        var userIdMoved :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, e.name));        var userHotspot :Array = _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOT, e.name) as Array;//        trace("\nVampireAvatarController handleEntityMoved!, hotspot=" + _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOT, e.name));//        trace( playerId + " e=" + e);        //e.value == null means the avatar has arrived at it's location.        if( e.value == null) {//Only compute closest avatars when this avatar has arrived at location            //We only report the non-players, as the game knows where the players are            var actualLocation :Array = _userLocationsTempWhileMoving.get( userIdMoved ) as Array;            //Notify listeners that we have arrived at our destination            if( userIdMoved == playerId ) {                _isUserArrivedAtDestination = true;                //And adjust our angle to our targets, if we have a target                //If our location is the same as our targets, we have the same orientation                //otherwise, we want to face our target                if( _targetId > 0 ) {                    var targetEntityId :String = getEntityId( _targetId );                    var targetLocation :Array = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, targetEntityId) as Array;                    //If we are not the first predator, standing slightly behind the target, make                    //sure we are facing the same orientation as th target.  If we aren't the first                    //pred, face the target                    var distance :Number = MathUtil.distance( actualLocation[0], actualLocation[2], targetLocation[0], targetLocation[2] );                    if( distance <= MINIMUM_FIRST_TARGET_DISTANCE ) {                        var targetorientation :Number = Number(_ctrl.getEntityProperty(                            EntityControl.PROP_ORIENTATION, targetEntityId));                        _ctrl.setLogicalLocation(actualLocation[0], actualLocation[1], actualLocation[2], targetorientation );                    }                    else {                        var faceTargetOrientation :Number = targetLocation[0] < actualLocation[0] ? 270 : 90;                        _ctrl.setLogicalLocation(actualLocation[0], actualLocation[1], actualLocation[2], faceTargetOrientation );                    }                    //Reset our target                    _targetId = -1;                }            }            if( actualLocation == null ) {//                trace("entityLocation == null, so getting location from avatar props");                actualLocation = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, e.name) as Array;                if(actualLocation) {                    actualLocation = actualLocation.slice();                }            }            setUserLocation( userIdMoved, actualLocation, userHotspot );//            _userLocations.put( userIdMoved, [actualLocation, userHotspot] );//            if( actualLocation != null) {//!isPlayer( userIdMoved ) &&////                sendSignalEntityMoved( e.name );//            }//            else {//                trace("handleEntityMoved, but entityLocation in null");//            }//            computeClosestAvatar(e);//            //If we arrived at out destination, notify the server, who may initiate the feeding animation//            if( int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, e.name)) == playerId) {//                trace( "handleEntityMoved(), we have arrived!");//                _ctrl.sendSignal( Constants.SIGNAL_PLAYER_ARRIVED_AT_DESTINATION, playerId);//            }        }        else {            //Because when the entity arrives, the locaiton info is stale, this holds a record of the correct location.            var entityLocation :Array = e.value as Array;            if( entityLocation != null) {                _userLocationsTempWhileMoving.put( userIdMoved, entityLocation.slice() );            }            else {                log.error("handleEntityMoved(" + e + "), but location value could not be coerced to an Array.");            }            setUserLocation( userIdMoved, null, userHotspot );//            _userLocations.put( userIdMoved, [null, userHotspot] );//            trace("  e.value != null, beginning of move, storing but not sending location");//            var targetEntityId :String = getEntityId( _targetId );//            var targetLocation :Array = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, targetEntityId) as Array;////            if( userIdMoved ==//            _ctrl.sendSignal( Constants.SIGNAL_CLOSEST_ENTITY, [playerId, 0, "", null, 0, targetLocation]);        }//        trace( "  end handleEntityMoved() me:" + this);        //Check all entities    }//    /**//     * Respond to signals from the room//     *///    protected function handleSignalReceived (e :ControlEvent) :void//    {////        //Update our target//        var data :Array;//        switch( e.name ) {////            case Constants.SIGNAL_PLAYER_TARGET ://                if( !_ctrl.hasControl()) {//                    return;//                }//                data = e.value as Array;//                if( data[0] == playerId) {//                    _targetId = data[1] as int;//                }//                break;////            case Constants.SIGNAL_CHANGE_COLOR_SCHEME://                data = e.value as Array;//                if( data != null && data.length >= 2) {//                    if( data[0] == playerId && _colorSchemeFunction != null) {////                        trace("calling _colorSchemeFunction from bridge");//                        _colorSchemeFunction( data[1] );//                    }//                }//                else {//                    trace("WTF, signal " + e);//                }//                break;//            case Constants.SIGNAL_PLAYER_IDS://                if( !_ctrl.hasControl()) {//                    return;//                }////                _playerIds = e.value as Array;////                trace("Avatar got playerids=" + _playerIds + ", sending avatar locations");//                //If player ids are sent, send all entity locations to the server, as this//                //could mean the game has started in this room, and receiving this signal//                //indicates that the room is up and running.//                sendLocationsOfAvatars(false);//                break;//            default:////                trace("Ignoring signal " + e);//                break;////        }//    }//    protected function isPlayer( userId :int ) :Boolean//    {//        return ArrayUtil.contains( _playerIds, userId );//    }    /**     * This is called when the user selects a different state.     */    protected function handleStateChange (event :ControlEvent) :void    {//        trace("\nVampireAvatarController changing state=" + event.name+ "!\n");        _state = event.name;    }    protected function handleChatReceived( e :ControlEvent) :void    {        var chatterId :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, e.name));        _chatRecord.playerChatted( chatterId );    }    protected function get playerId() :int    {        return int(_ctrl.getEntityProperty(EntityControl.PROP_MEMBER_ID));    }//    protected function computeClosestAvatar( e :ControlEvent ) :void//    {//        if( _ctrl == null || !_ctrl.isConnected() ) {//            log.error("computeClosestAvatar(), ctrl=" + _ctrl + ", _ctrl.isConnected()=" + _ctrl.isConnected());//            return;//        }//////        if( e.value == null) {////            return;////        }//        var userIdMoved :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, e.name));////        trace("   computeClosestAvatar(), userIdMoved=" + userIdMoved + ", myId=" + playerId);////        var myLocation :Array = _ctrl.getLogicalLocation();////        trace("   myLocation from ctrl, location=" + myLocation);//        if( userIdMoved == playerId && e != null && e.value != null) {//            myLocation = e.value as Array;////            trace("   oh, I'm the entity in the event, myLocation=" + myLocation);//        }//        var closestUserId :int = 0;//        var closestEntityId :String;//        var closestUserDistance :Number = Number.MAX_VALUE;//        var closestLocation :Array;//        var myX :Number = myLocation[0] as Number;//        var myZ :Number = myLocation[2] as Number;////        trace("    me(" + myX + ", " + myZ + ")");////        var entityLocation :Array;//        for each( var entityId :String in _ctrl.getEntityIds(EntityControl.TYPE_AVATAR)) {////            var entityUserId :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, entityId));////            if( entityUserId == playerId ) {//                continue;//            }////            entityLocation = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, entityId) as Array;////            trace("     for entityUserId=" + entityUserId + ", loc=" + entityLocation);////            if( entityUserId == userIdMoved && e != null && e.value != null) {//                entityLocation = e.value as Array;////                trace("     oh, its the entity in the event, " + entityUserId + " location=" + entityLocation);//            }////            if( entityLocation != null) {//                var distance :Number = MathUtil.distance( myX, myZ, entityLocation[0], entityLocation[2]);//                if( !isNaN(distance)) {//                    if( distance < closestUserDistance) {//                        closestUserDistance = distance;//                        closestUserId = entityUserId;//                        closestEntityId = entityId;//                        closestLocation = entityLocation.slice();//                    }//                }////            }//        }////////        trace("    Closests userId=" + closestUserId);////        trace("    Closests user name=" + _ctrl.getViewerName(closestUserId));//        var targetEntityId :String = getEntityId( _targetId );//        var targetLocation :Array = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, targetEntityId) as Array;//        if(closestUserId == 0) {//            _ctrl.sendSignal( Constants.SIGNAL_CLOSEST_ENTITY, [playerId, 0, "", null, 0, targetLocation]);//        }//        else if( closestUserId > 0 && closestUserId != playerId  ){//closestUserId != _closestUserId) {////            trace("     sending closestUserId=" + closestUserId);//            _closestUserId = closestUserId;////            entityLocation = _ctrl.getEntityProperty( EntityControl.PROP_LOCATION_LOGICAL, closestEntityId) as Array;////            trace("      for _closestUserId=" + _closestUserId + ", loc=" + entityLocation);////            if( _closestUserId == userIdMoved && e != null && e.value != null) {////                entityLocation = e.value as Array;////                trace("     oh, its the entity in the event, " + _closestUserId + " location=" + entityLocation);////            }////            trace("      closestLocation=" + closestLocation);////            var entityHeight :Number = (_ctrl.getEntityProperty( EntityControl.PROP_DIMENSIONS, closestEntityId) as Array)[1];////            var entityHotspot :Array = _ctrl.getEntityProperty( EntityControl.PROP_HOTSPOT, closestEntityId) as Array;////////            trace("      entityHeight=" + entityHeight);//            _ctrl.sendSignal( Constants.SIGNAL_CLOSEST_ENTITY, [playerId, closestUserId, _ctrl.getViewerName(closestUserId), closestLocation, entityHotspot, targetLocation]);//        }//////    }    public function getEntityId( userId :int ) :String    {        for each( var entityId :String in _ctrl.getEntityIds(EntityControl.TYPE_AVATAR)) {            var entityUserId :int = int(_ctrl.getEntityProperty( EntityControl.PROP_MEMBER_ID, entityId));            if( userId == entityUserId) {                return entityId            }        }        return null;    }//    public function trace( s :String) :void//    {//        if( playerId == 23340) {//            trace(s);//        }//    }    public function get state() :String    {        return _state;    }    public function toString() :String    {        var sb :StringBuilder = new StringBuilder("\nCurrent stored avatar locations:");        _userLocations.forEach( function( userId :int, location :Array) :void {            sb.append("\n   " + userId + "     " + location );        });        return sb.toString();    }//    protected var _playerIds :Array = [];    protected var _userLocations :HashMap = new HashMap();    protected var _userLocationsTempWhileMoving :HashMap = new HashMap();    protected var _isLocationsChanged :Boolean = false;    protected var _isUserArrivedAtDestination :Boolean = false;    protected var _currentColorScheme :String;    protected var _colorSchemeFunction :Function;    protected var _ctrl :AvatarControl;    protected var _state :String = VConstants.GAME_MODE_NOTHING;    protected var _chatRecord :ChatRecord = new ChatRecord();    protected var _isFrozen :Boolean = false;    protected var _targetId :int = -1;//    protected var _targetId :int;//    protected var _closestUserId :int;//    protected var _closestUserLocation :Array;    protected var _events :EventHandlerManager = new EventHandlerManager();//    protected var _remote :RemoteEntity;    /**Used to gather room avatar locations*/    public static const ENTITY_PROPERTY_AVATAR_LOCATIONS :String = "AvatarLocations";    /**Used to gather arriving at location events*/    public static const ENTITY_PROPERTY_IS_AVATAR_ARRIVED_AT_DESTINATION :String = "AvatarArivedAtLocation";    /**For providing a function to change vampire avatar colors*/    public static const ENTITY_PROPERTY_VAMPIRE_STATE :String = "VampireState";    /**For providing a function to change vampire avatar colors*/    public static const ENTITY_PROPERTY_IS_LOCATIONS_CHANGED :String = "IsLocationsChanged";    /**Manually reset the locations*/    public static const ENTITY_PROPERTY_RESET_LOCATIONS:String = "ResetLocations";    /**For providing a function to change vampire avatar colors*///    public static const ENTITY_PROPERTY_CHAT_RECORDS :String = "ChatRecords";    /**For providing a function to change vampire avatar colors*/    public static const ENTITY_PROPERTY_CURRENT_COLOR_SCHEME :String = "ColorScheme";    /**For providing a function to change vampire avatar colors*/    public static const ENTITY_PROPERTY_CHANGE_COLOR_SCHEME_FUNCTION :String = "ColorSchemeFunction";    /**For providing a function to freeze the avatar animation*/    public static const ENTITY_PROPERTY_SETFREEZE_FUNCTION :String = "SetFreezeFunction";    /**For providing a function to change avatar states*/    public static const ENTITY_PROPERTY_SETSTATE_FUNCTION :String = "SetStateFunction";    /**For providing a function to change avatar states*/    public static const ENTITY_PROPERTY_SETTARGET_FUNCTION :String = "SetTargetFunction";    /**We record who chatted when.  This is used to provide valid  */    public static const ENTITY_PROPERTY_CHAT_TARGETS :String = "ChatTargets";    /**We record who chatted when.  This is used to provide valid  */    public static const ENTITY_PROPERTY_IS_LEGAL_AVATAR :String = "IsLegalAvatar";    protected static const UPDATE_INTERVAL_MS :Number = 1000;    /**    * When this avatar arrives at it's destination, and it has a target, check how far away    * we are from the target location.  If we are below this distance, we must be the first    * predator (standing directly behind the target).  If we are greater than this distance,    * we must have our orientation changed to face the target.    */    public static const MINIMUM_FIRST_TARGET_DISTANCE :Number = MathUtil.distance(0, 0, VConstants.FEEDING_LOGICAL_X_OFFSET, VConstants.FEEDING_LOGICAL_Z_OFFSET) + 0.01;    protected static const log :Log = Log.getLog( AvatarGameBridge );}}