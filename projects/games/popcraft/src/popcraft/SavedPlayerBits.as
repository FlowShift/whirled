//
// $Id$

package popcraft {

import flash.utils.ByteArray;

/**
 * Stores random bits of player data that don't have anywhere else to live.
 */
public class SavedPlayerBits
    implements UserCookieDataSource
{
    // Cookie > 0
    public var hasFreeStoryMode :Boolean;
    // Cookie >= 2
    public var hasAskedToResetEndlessLevels :Boolean;
    // Cookie >= 3
    public var favoriteColor :uint;
    public var favoritePortrait :String;

    public function SavedPlayerBits ()
    {
        init();
    }

    public function writeCookieData (cookie :ByteArray) :void
    {
        cookie.writeBoolean(hasFreeStoryMode);
        cookie.writeBoolean(hasAskedToResetEndlessLevels);
        cookie.writeUnsignedInt(favoriteColor);
        cookie.writeUTF(favoritePortrait);
    }

    public function readCookieData (version :int, cookie :ByteArray) :void
    {
        init();

        if (version == 0) {
            // If the cookie version is 0, we're upgrading an original-version cookie, which means
            // this player was playing the game before we started charging for the second half
            // of the game. If the player has gotten past level 7, we let them continue to play
            // the story mode for free (though they still have to pay to unlock Endless Mode).
            hasFreeStoryMode =
                (ClientCtx.levelMgr.highestUnlockedLevelIndex >= Constants.NUM_FREE_SP_LEVELS);

        } else {
            hasFreeStoryMode = cookie.readBoolean();
        }

        if (version >= 2) {
            hasAskedToResetEndlessLevels = cookie.readBoolean();
        } else {
            // if the cookie version is < 2, and the player doesn't have any saved games,
            // we'll never need to ask them to reset.
            hasAskedToResetEndlessLevels =
                (ClientCtx.endlessLevelMgr.savedMpGames.numSaves == 0 &&
                 ClientCtx.endlessLevelMgr.savedSpGames.numSaves == 0);
        }

        if (version >= 3) {
            favoriteColor = cookie.readUnsignedInt();
            favoritePortrait = cookie.readUTF();
        }
    }

    public function get minCookieVersion () :int
    {
        return 0;
    }

    public function cookieReadFailed () :Boolean
    {
        init();
        return true;
    }

    public function init () :void
    {
        hasFreeStoryMode = false;
        hasAskedToResetEndlessLevels = false;
        favoriteColor = Constants.RANDOM_COLOR;
        favoritePortrait = Constants.DEFAULT_PORTRAIT;
    }
}

}
