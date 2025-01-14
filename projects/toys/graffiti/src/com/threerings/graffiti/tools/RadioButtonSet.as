// $Id$

package com.threerings.graffiti.tools {

import flash.events.EventDispatcher;
import flash.events.MouseEvent;

import com.threerings.util.Log;

[Event(name="buttonSelected", type="RadioEvent")];

public class RadioButtonSet extends EventDispatcher
{
    public function addButton (button :ToggleButton, select :Boolean = false) :void
    {
        var index :int = _buttons.length;
        _buttons.push(button);
        button.button.addEventListener(MouseEvent.MOUSE_DOWN, function (event :MouseEvent) :void {
            buttonClicked(index);
        });
        if (select) {
            buttonClicked(index);
        }
    }

    public function buttonClicked (index :int) :void
    {
        if (_selected != -1) {
            _buttons[_selected].selected = false;
        }
        _buttons[_selected = index].selected = true;

        dispatchEvent(new RadioEvent(RadioEvent.BUTTON_SELECTED, _buttons[_selected].value));
    }

    private static const log :Log = Log.getLog(RadioButtonSet);

    protected var _buttons :Array = [];
    protected var _selected :int = -1;
}
}
