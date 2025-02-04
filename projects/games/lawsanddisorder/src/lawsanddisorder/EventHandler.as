﻿package lawsanddisorder {

import com.threerings.util.HashMap;
import com.whirled.game.CoinsAwardedEvent;
import com.whirled.game.GameSubControl;
import com.whirled.game.StateChangedEvent;
import com.whirled.net.ElementChangedEvent;
import com.whirled.net.MessageReceivedEvent;
import com.whirled.net.PropertyChangedEvent;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.utils.Timer;

import lawsanddisorder.component.*;

/**
 * Manages property and message events, propagating them out to registered listeners.  Also 
 * handles game end.
 */
public class EventHandler extends EventDispatcher
{
    /** Event that fires when some player's turn just started (including AIs) */
    public static const TURN_CHANGED :String = "turnChanged";
    
    /** Event that fires when the player's turn is ending */
    public static const MY_TURN_ENDED :String = "turnEnded";

    /** Event that fires when the player's turn is starting */
    public static const MY_TURN_STARTED :String = "turnStarted";
    
    /** Event that fires when last round starts, value is the id of the last player */
    public static const END_GAME_PLAYER :String = "endGamePlayer";
    
    /** Event that fires when the server reports the game has ended */
    public static const GAME_ENDED :String = "gameEnded";

    /**
     * Constructor - add event listeners and maybe get the board if it's setup 
     */
    public function EventHandler (ctx :Context)
    {
        _ctx = ctx;
        _ctx.control.game.addEventListener(StateChangedEvent.GAME_ENDED, gameEnded);
        _ctx.control.player.addEventListener(CoinsAwardedEvent.COINS_AWARDED, coinsAwarded);
        _ctx.control.net.addEventListener(PropertyChangedEvent.PROPERTY_CHANGED, propertyChanged);
        _ctx.control.net.addEventListener(ElementChangedEvent.ELEMENT_CHANGED, elementChanged);
        _ctx.control.net.addEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, messageReceived);
    }

    /**
     * Invoke the given function in delay milliseconds.
     */
    public static function startTimer (delayMillis :int, func :Function, numFires :int = 1) :void
    {
        var timer :Timer = new Timer(delayMillis, numFires);
        timer.addEventListener(TimerEvent.TIMER, function (event :Event): void { func(); });
        timer.start();
    }
    
    /**
     * Called when this handler is removed; sever connections to the server
     */
    public function unload () :void
    {
        _ctx.control.game.removeEventListener(StateChangedEvent.GAME_ENDED, gameEnded);
        _ctx.control.player.removeEventListener(CoinsAwardedEvent.COINS_AWARDED, coinsAwarded);
        _ctx.control.net.removeEventListener(PropertyChangedEvent.PROPERTY_CHANGED, propertyChanged);
        _ctx.control.net.removeEventListener(ElementChangedEvent.ELEMENT_CHANGED, elementChanged);
        _ctx.control.net.removeEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, messageReceived);
    }
    
    /**
     * Registers a function to be called when a distributed property is changed.
     */
    public function addDataListener (name :String, listener :Function, index :int = -1) :void
    {
        var key :String = name + "::" + index;
        var listeners :Array = _dataListeners.get(key);
        // key already has a listener, add this one
        if (listeners != null) {
            listeners.push(listener);
        }
        // key doesn't have any listeners yet, add to map
        else {
            listeners = new Array();
            listeners.push(listener);
            _dataListeners.put(key, listeners);
        }
    }

    /**
     * De-registers a function from being called when a distributed property is changed.
     */
    public function removeDataListener (name :String, listener :Function, index :int = -1) :void
    {
        var key :String = name + "::" + index;
        var listeners :Array = _dataListeners.get(key);
        // key has no listeners, oops!
        if (listeners == null) {
            return
        }
        // iterate through and remove our listener
        for (var i :int = 0; i < listeners.length; i++) {
            if (listeners[i] == listener) {
                listeners.splice(i, 1);
            }
        }
        // remove key entirely if that was the only listener
        if (listeners.length == 0) {
            _dataListeners.remove(key);
        }
    }

    /**
     * Registers a function to be called when a game message arrives.
     */
    public function addMessageListener (message :String, listener :Function) :void
    {
        var listeners :Array = _messageListeners.get(message);
        // message already has a listener, add this one
        if (listeners != null) {
            listeners.push(listener);
        }
        // message doesn't have any listeners yet, add to map
        else {
            listeners = new Array();
            listeners.push(listener);
            _messageListeners.put(message, listeners);
        }
    }

    /**
     * De-registers a function from being called when a game message arrives.
     */
    public function removeMessageListener (message :String, listener :Function) :void
    {
        var listeners :Array = _messageListeners.get(message);
        // message has no listeners, oops!
        if (listeners == null) {
            return
        }
        // iterate through and remove our listener
        for (var i :int = 0; i < listeners.length; i++) {
            if (listeners[i] == listener) {
                listeners.splice(i, 1);
            }
        }
        // remove property entirely if that was the only listener
        if (listeners.length == 0) {
            _messageListeners.remove(message);
        }
    }

    /**
     * Wrapper for retrieving data values from the control
     */
    public function getData (propName :String, index :int = -1) :*
    {
        var propertyValue :* = _ctx.control.net.get(propName);
        if (index > -1) {
            if (propertyValue == null) {
                return null;
            }
            else {
              return propertyValue[index];
            }
        }
        else {
            return propertyValue;
        }
    }

    /**
     * Wrapper for setting data values with the control
     */
    public function setData (propName :String, value :Object, index :int = -1, isDictionary :Boolean = false) :void
    {
        if (!_ctx.control.isConnected()) {
            return;
        }
        
        if (index > -1 && isDictionary) {
            _ctx.control.net.setIn(propName, index, value);
        }
        else if (index > -1) {
            _ctx.control.net.setAt(propName, index, value);
        }
        else {
            _ctx.control.net.set(propName, value);
        }
    }

    /**
     * The last round ended, so finally end the game.  Called by the player who ended the game.
     * Calculate the scores and send a message to everyone, awarding flow.
     * Assumes player seats may have changed during the game and rebuilds playerIds array.
     */
    public function endGame () :void
    {
        // tell other players the game has ended to lock the board.
        _ctx.board.endTurnButton.gameEnded();

        var playerIds :Array = [];
        var playerScores :Array = [];

        for each (var player :Player in _ctx.board.players.playerObjects) {
            if (!(player as AIPlayer)) {
                playerIds.push(player.serverId);
                // score = how well you did in comparaison to other players including AI.  
                // 100 = winner, 0 = loser
                playerScores.push(player.getWinningPercentile(false));
            }
        }

        _ctx.control.game.endGameWithScores(playerIds, playerScores, GameSubControl.TO_EACH_THEIR_OWN);
    }

    /**
     * Handler for receiving game end events
     */
    protected function gameEnded (event :StateChangedEvent) :void
    {
        _ctx.gameStarted = false;
        Content.playSound(Content.SFX_GAME_OVER);
        dispatchEvent(new Event(GAME_ENDED));
            
        _ctx.log("Your final score is " + _ctx.player.getWinningPercentile(false));
    }

    /**
     * Handler for receiving coins awarded events
     */
    protected function coinsAwarded (event :CoinsAwardedEvent) :void
    {
        _ctx.notice("Game over - thanks for playing!", true);
    }
    
    /**
     * Called when our distributed game state changes.
     */
    protected function propertyChanged (event :PropertyChangedEvent) :void
    {
        var key :String = event.name + "::" + "-1";
        var dataEvent :DataChangedEvent = new DataChangedEvent(event.name, event.oldValue, event.newValue, -1);
        dispatchDataEvent(key, dataEvent);
    }

    /**
     * Called when an element of a distributed array changes.  Call each listener.
     */
    protected function elementChanged (event :ElementChangedEvent) :void
    {
        var key :String = event.name + "::" + event.index;
        var dataEvent :DataChangedEvent = new DataChangedEvent(event.name, event.oldValue, event.newValue, event.index);
        dispatchDataEvent(key, dataEvent);

        // also send event to listeners who are inerested in a change to any or all elements
        var allKey :String = event.name + "::" + "-1";
        dispatchDataEvent(allKey, dataEvent);
    }

    /**
     * Dispatch the given data changed event to listeners registered with the given key.
     */
    protected function dispatchDataEvent (key :String, event :DataChangedEvent) :void
    {
        var listeners :Array = _dataListeners.get(key);
        if (listeners != null) {
            // iterate through and perform each listener
            for (var i :int = 0; i < listeners.length; i++) {
                var listener :Function = listeners[i];
                listener(event);
            }
        }
    }

    /**
     * Called when a message comes in.  Call each listener function in order.
     */
    protected function messageReceived (event :MessageReceivedEvent) :void
    {
        // convert from Whirled event to our own to reduce dependencies
        var messageEvent :MessageEvent = new MessageEvent(event.name, event.value);
        var listeners :Array = _messageListeners.get(messageEvent.name);
        if (listeners != null) {
            // iterate through and perform each listener
            for (var i :int = 0; i < listeners.length; i++) {
                var listener :Function = listeners[i];
                listener(messageEvent);
            }
        }
    }

    /** Context */
    protected var _ctx :Context;

    /** Map of listener functions for distributed property changes.
     *  Types <String, Array<Function>> */
    protected var _dataListeners :HashMap = new HashMap();

    /** Map of listener functions for game messages.
     *  Types <String, Array<Function>> */
    protected var _messageListeners :HashMap = new HashMap();
}
}
