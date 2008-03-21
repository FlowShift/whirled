package bingo {

import com.whirled.contrib.ColorMatrix;

import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;

public class BingoCardView extends Sprite
{
    public function BingoCardView (card :BingoCard)
    {
        _card = card;

        _bgSprite = new Sprite();
        _fgSprite = new Sprite();

        this.addChild(_bgSprite);
        this.addChild(_fgSprite);

        // draw the board background
        _bgSprite.addChild(new Resources.IMG_BOARD());

        // draw the items
        for (var row :int = 0; row < card.height; ++row) {

            for (var col :int = 0; col < card.width; ++col) {

                var itemView :DisplayObject = this.createItemView(_card.getItemAt(col, row));
                itemView.x = UL_OFFSET.x + ((col + 0.5) * SQUARE_SIZE);
                itemView.y = UL_OFFSET.y + ((row + 0.5) * SQUARE_SIZE);

                _fgSprite.addChild(itemView);
            }
        }

        BingoMain.model.addEventListener(SharedStateChangedEvent.NEW_BALL, handleNewBall);

        this.addEventListener(MouseEvent.MOUSE_DOWN, handleClick);
        this.addEventListener(Event.REMOVED, handleRemoved);
    }

    protected function handleRemoved (e :Event) :void
    {
        BingoMain.model.removeEventListener(SharedStateChangedEvent.NEW_BALL, handleNewBall);
    }

    public function createItemView (item :BingoItem) :DisplayObject
    {
        var sprite :Sprite = new Sprite();
        sprite.mouseChildren = false;
        sprite.mouseEnabled = false;

        if (null != item) {

            var bitmap :Bitmap = new item.itemClass();
            bitmap.x = -(bitmap.width * 0.5);
            bitmap.y = -(bitmap.height * 0.5);

            // does the item require recoloring?
            if (item.requiresTint) {
                var cm :ColorMatrix = new ColorMatrix();
                cm.tint(item.tintColor, item.tintAmount);
                bitmap.filters = [ cm.createFilter() ];
            }

            sprite.addChild(bitmap);
        }

        return sprite;
    }

    protected function handleClick (e :MouseEvent) :void
    {
        // if the round is over, or we've already reached our
        // max-clicks-per-ball limit, don't accept clicks
        if (!BingoMain.model.roundInPlay || (!Constants.ALLOW_CHEATS && _numMatchesThisBall >= Constants.MAX_MATCHES_PER_BALL)) {
            return;
        }

        var col :int = (this.mouseX - UL_OFFSET.x) / SQUARE_SIZE;
        var row :int = (this.mouseY - UL_OFFSET.y) / SQUARE_SIZE;

        if (!(col >= 0 && col < _card.width && row >= 0 && row < _card.height)) {
            return;
        }

        if (!_card.isFilledAt(col, row)) {

            var item :BingoItem = _card.getItemAt(col, row);

            if (null != item && (Constants.ALLOW_CHEATS || item.containsTag(BingoMain.model.curState.ballInPlay))) {
                _card.setFilledAt(col, row);

                // highlight the space
                var highlightClass :Class;
                var offset :Point = new Point();

                // ugh.
                if (col == 0 && row == 0) {
                    highlightClass = Resources.IMG_TOPLEFTHIGHLIGHT;
                    //offset.x =
                } else if (col == _card.width - 1 && row == 0) {
                    highlightClass = Resources.IMG_TOPRIGHTHIGHLIGHT;
                } else if (col == 0 && row == _card.height - 1) {
                    highlightClass = Resources.IMG_BOTTOMLEFTHIGHLIGHT;
                } else if (col == _card.width - 1 && row == _card.height - 1) {
                    highlightClass = Resources.IMG_BOTTOMRIGHTHIGHLIGHT;
                } else {
                    highlightClass = Resources.IMG_CENTERHIGHLIGHT;
                    offset.x = 1;
                    offset.y = 1;
                }

                var hilite :Bitmap = new highlightClass();
                hilite.x = UL_OFFSET.x + offset.x + (col * SQUARE_SIZE);
                hilite.y = UL_OFFSET.y + offset.y + (row * SQUARE_SIZE);

                _bgSprite.addChild(hilite);

                BingoMain.controller.updateBingoButton();

                _numMatchesThisBall += 1;
            }
        }

    }

    protected function handleNewBall (e :Event) :void
    {
        _numMatchesThisBall = 0;
    }

    protected var _bgSprite :Sprite;
    protected var _fgSprite :Sprite;
    protected var _card :BingoCard;
    protected var _numMatchesThisBall :int;

    protected static const SQUARE_SIZE :Number = 62;
    protected static const TARGET_TEXT_WIDTH :Number = 56;
    protected static const STAMP_RADIUS :Number = 20;

    protected static const ALLOWED_STAMP_BLEED :Number = 0;

    protected static const UL_OFFSET :Point = new Point(14, 28);

}

}
