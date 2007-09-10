package com.threerings.brawler {

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;

import com.threerings.util.StringUtil;

import com.threerings.brawler.actor.Player;
import com.threerings.brawler.actor.Weapon;

/**
 * Displays the Brawler HUD.
 */
public class HudView extends Sprite
{
    public function HudView (ctrl :BrawlerController, view :BrawlerView, hud :MovieClip)
    {
        _ctrl = ctrl;
        _view = view;
        addChild(_hud = hud);
    }

    /**
     * Called by the view to initialize the hud.
     */
    public function init () :void
    {
        // initialize states
        _hud.respawn.state = "off";
        _hud.fader.gotoAndStop("out");

        // update the room
        updateRoom();

        // update the connection display
        updateConnection();

        // update the all-clear display
        updateClear();

        // if we're not playing, there's not much to show
        if (!_ctrl.amPlaying) {
            _hud.stats.visible = false;
            _hud.score.visible = false;
            return;
        }

        // update the score
        updateScore();

        // update the hit count
        updateHits();
    }

    /**
     * Called by the view on every frame.
     */
    public function enterFrame (elapsed :Number) :void
    {
        // make sure we've created the local player
        var self :Player = _ctrl.self;
        if (self == null) {
            return;
        }
        // update the hit point display
        _hud.stats.hpnum.text = Math.round(self.hp);
        var frame :Number = Math.round((self.hp / self.maxhp) * 100) + 1;
        if (_hud.stats.hp.bar.currentFrame >= frame) {
            _hud.stats.hp.bar.gotoAndStop(frame);
        } else {
            _hud.stats.hp.bar.nextFrame();
        }
        if (_hud.stats.hp.dmg.currentFrame <= frame) {
            _hud.stats.hp.dmg.gotoAndStop(frame);
            _hud.stats.hp.gotoAndStop(2);
        } else {
            _hud.stats.hp.dmg.prevFrame();
            _hud.stats.hp.gotoAndStop(1);
        }

        // display the warning if appropriate
        setState(_hud.hp_warning, (frame <= 20 && !self.dead) ? "on" : "off");

        // update the weapon display
        setState(_hud.stats.exp.weapon.weapon, Weapon.FRAME_LABELS[self.weapon]);

		// update the energy display (the "depleted" frames follow the normal ones)
        var pct :Number = Math.round(self.energy);
        _hud.stats.energy.gotoAndStop((self.depleted ? 101 : 0) + pct + 1);
        _hud.stats.energy.num.text = pct + "%";

        // display the energy warning if depleted
        setState(_hud.energy_warning, self.depleted ? "on" : "off");

        // update the experience display
        var exp :Number = Math.round(self.experience) + 1;
        if (_hud.stats.exp.currentFrame < exp) {
            _hud.stats.exp.nextFrame();
        } else if (_hud.stats.exp.currentFrame > exp) {
            _hud.stats.exp.prevFrame();
        }

        // update the attack bar
        var level :int = self.attackLevel + 1;
        for (var ii :int = 1; ii <= PUNCH_LEVELS; ii++) {
            setState(_hud.attacks["p" + ii], (level < ii) ? "off" : (level == ii ? "next" : "on"));
        }
        level = Math.floor(level * (KICK_LEVELS / PUNCH_LEVELS));
        for (ii = 1; ii <= KICK_LEVELS; ii++) {
            setState(_hud.attacks["k" + ii], (level < ii) ? "off" : (level == ii ? "next" : "on"));
        }
        setState(_hud.attacks.pk, (self.experience == Player.MAX_EXPERIENCE) ? "on" : "off");

        // update the respawn clock
        var respawn :int = self.respawnCountdown;
        if (respawn > 0) {
            setState(_hud.respawn, "on");
            _hud.dc.text = StringUtil.prepad(respawn.toString(), 2, "0");
            _hud.dc.visible = true;

        } else {
            setState(_hud.respawn, "off");
            _hud.dc.visible = false;
        }
    }

    /**
     * Fades in or out.
     */
    public function fade (type :String, callback :Function = null) :void
    {
        _view.animmgr.play(_hud.fader, type, callback);
    }

    /**
     * Updates the connection display.
     */
    public function updateConnection () :void
    {
        _hud.connection.text = _ctrl.control.amInControl() ? "Host" : "Client";
    }

    /**
     * Sets the messages per second display.
     */
    public function updateMPS (mps :Number) :void
    {
        _hud.mps_output.text = "MPS: " + mps;
        _hud.mps_output.textColor = (mps >= 8) ? 0xFF0000 : 0xFFFFFF;
    }

    /**
     * Updates the throttled message queue length display.
     */
    public function updateTBS () :void
    {
        _hud.tbs_output.text = _ctrl.throttle.enqueued;
    }

    /**
     * Sets the frames per second display.
     */
    public function updateFPS (fps :Number) :void
    {
        _hud.fps_output.text = "FPS: " + fps;
        _hud.fps_output.textColor = (fps < 20) ? 0xFF0000 : 0xFFFFFF;
    }

    /**
     * Updates the clock display.
     */
    public function updateClock () :void
    {
        var minutes :Number = Math.floor(_ctrl.clock / 60);
        var seconds :String = (_ctrl.clock % 60).toString();
        _hud.time.text = minutes + "'" + StringUtil.prepad(seconds, 2, "0") + "''";
    }

    /**
     * Returns the contents of the clock display.
     */
    public function get clock () :String
    {
        return _hud.time.text;
    }

    /**
     * Updates the score.
     */
    public function updateScore (increment :int = 0) :void
    {
        _hud.score.text = _ctrl.score;
        if (increment > 0) {
            _hud.score_add.score_add.score_add.text = "+" + increment;
            _hud.score_add.gotoAndPlay("go");
        }
    }

    /**
     * Updates the hit count.
     */
    public function updateHits () :void
    {
        var hits :int = (_ctrl.self == null) ? 0 : _ctrl.self.hits;
        if (hits > 0) {
            _hud.hitcounter.num.hits.text = hits;
            _hud.hitcounter.gotoAndPlay("go");
        } else {
            _hud.hitcounter.gotoAndStop("stop");
        }
    }

    /**
     * Updates the room display.
     */
    public function updateRoom () :void
    {
        _hud.zone.text = _hud.levelname.text + " - ZONE " + _ctrl.room;
    }

    /**
     * Updates the all-clear display.
     */
    public function updateClear () :void
    {
        _hud.go.visible = _ctrl.clear;
    }

    /**
     * Adds a blip to the radar display.
     */
    public function addRadarBlip (blip :Sprite) :void
    {
        _hud.radar.view.addChild(blip);
    }

    /**
     * Removes a blip from the radar display.
     */
    public function removeRadarBlip (blip :Sprite) :void
    {
        _hud.radar.view.removeChild(blip);
    }

    /**
     * Updates the position of a radar blip, given the x coordinate of its target.
     */
    public function updateRadarBlip (blip :Sprite, x :Number) :void
    {
        blip.x = (x / _view.ground.width) * 200;
        blip.y = 0;
    }

    /**
     * Shows that the player's weapon has been damaged.
     */
    public function weaponDamaged () :void
    {
        // returns to idle after showing damage effect
        _hud.stats.exp.weapon.gotoAndPlay("damage");
    }

    /**
     * Goes to the specified label and stops if the clip isn't already there.
     */
    protected static function setState (clip :MovieClip, state :String) :void
    {
        var ostate :String = (clip.state == undefined) ? clip.currentLabel : clip.state;
        if (ostate != state) {
            clip.alpha = 1; // make sure it's visible
            clip.gotoAndStop(clip.state = state);
        }
    }

    /** The Brawler controller. */
    protected var _ctrl :BrawlerController;

    /** The main Brawler view. */
    protected var _view :BrawlerView;

    /** The game hud. */
    protected var _hud :MovieClip;

    /** The number of punch levels in the attack bar. */
    protected static const PUNCH_LEVELS :int = 6;

    /** The number of kick levels in the attack bar. */
    protected static const KICK_LEVELS :int = 3;
}
}
