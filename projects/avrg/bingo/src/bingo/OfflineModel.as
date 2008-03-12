package bingo {

public class OfflineModel extends Model
{
    override public function trySetNewState (newState :SharedState) :void
    {
        // in offline mode, we can convert state change requests
        // directly into state changes
        
        this.setState(newState);
    }
    
    override public function trySetNewScores (newScores :Scoreboard) :void
    {
        this.setScores(newScores);
    }
    
    override public function tryCallBingo () :void
    {
        var newState :SharedState = _curState.clone();
        newState.roundWinnerId = BingoMain.ourPlayerId;
        
        this.setState(newState);
    }
}

}