//
// $Id$

package popcraft.game.endless {

import popcraft.*;

public class SpEndlessGameOverMode extends SpEndlessLevelSelectModeBase
{
    public function SpEndlessGameOverMode ()
    {
        super(GAME_OVER_MODE);
    }

    override protected function setup () :void
    {
        super.setup();

        EndlessGameCtx.endGameAndSendScores();
    }

}

}
