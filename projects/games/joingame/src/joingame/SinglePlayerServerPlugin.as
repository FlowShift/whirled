package joingame
{
    import com.threerings.util.ArrayUtil;
    import com.threerings.util.ClassUtil;
    import com.threerings.util.HashMap;
    import com.threerings.util.Log;
    import com.whirled.contrib.simplegame.util.Rand;
    import com.whirled.game.GameSubControl;
    
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    
    import joingame.model.JoinGameBoardRepresentation;
    import joingame.model.JoinGameModel;
    import joingame.net.AddPlayerMessage;
    import joingame.net.DeltaRequestMessage;
    import joingame.net.GameOverMessage;
    import joingame.net.GoToObserverModeMessage;
    import joingame.net.PlayerDestroyedMessage;
    import joingame.net.PlayerRemovedMessage;
    import joingame.net.ReplayConfirmMessage;
    import joingame.net.WaveDefeatedMessage;
    
    /**
    * Game state info and methods (including AI) for all single player logic.
    */
    public class SinglePlayerServerPlugin
    {
        private static const log :Log = Log.getLog(SinglePlayerServerPlugin);
        
        protected var _gameModel :JoinGameModel;
        protected var _server :JoingameServer;
        protected var _AITimer :Timer;
        protected var _timeRemaining :HashMap;
//        protected var _gameType :String;
//        protected var _robotLevel :int;
//        public var AppContext.singlePlayerCookie :UserCookieDataSourcePlayer;
        
        /**
        * The robot update timer.
        */
        protected static const UPDATE_TIME :int = 100;                
//        public var playerLevel :int = 1;
        
        protected var currentLowestComputerId :int;
        
        protected var robotId2Level :HashMap;
        
        
        
        public function SinglePlayerServerPlugin( model :JoinGameModel, server :JoingameServer )
        {
            _gameModel = model;
            _server = server;
            _AITimer = new Timer(UPDATE_TIME, 0);
            _AITimer.addEventListener(TimerEvent.TIMER, aiTimer);
            currentLowestComputerId = Constants.SINGLE_PLAYER_STARTING_ROBOT_LEVEL;
            
            _timeRemaining = new HashMap();
            robotId2Level = new HashMap();
        }
        
        internal function handleReplayRequest( playerId :int, cookie :UserCookieDataSourcePlayer, requestedLevel :int) :void
        {
            log.debug("SinglePlayerServerPlugin handleReplayRequest for player=" + playerId);
            createNewSinglePlayerModel( playerId , _gameModel._singlePlayerGameType, cookie, requestedLevel);
            log.debug("sending singleplayer" + ReplayConfirmMessage.NAME);
            startAI();
            AppContext.messageManager.sendMessage( new ReplayConfirmMessage( _gameModel.currentSeatingOrder, _gameModel.getModelMemento()) );
        }
        
        public function startAI () :void
        {
            _AITimer.addEventListener(TimerEvent.TIMER, aiTimer);
            _AITimer.reset();
            _AITimer.start();
        }
        
        public function stopAI () :void
        {
            log.debug("Stopping AI");
            _AITimer.removeEventListener(TimerEvent.TIMER, aiTimer);
            _AITimer.stop();
        }
        
        
        public function destroy() :void
        {
            _AITimer.removeEventListener(TimerEvent.TIMER, aiTimer);
            _AITimer.stop();
        }
        protected function aiTimer( event :TimerEvent ) :void
        {
            if( _gameModel.gameOver ) {
                log.debug("stopping game over in aiTimer due to game over");
                stopAI();
                return;
            }
            
            var board :JoinGameBoardRepresentation;
            var row :int;
            for each (var boardId :int in robotId2Level.keys().slice()){//_gameModel.currentSeatingOrder) {//_gameModel.getComputerIdsAdjacentToHumanPlayer()) {
            
                if( boardId > 0) {
                    continue;//Human player
                }
                _timeRemaining.put( boardId, _timeRemaining.get( boardId) - UPDATE_TIME);
                if( _timeRemaining.get( boardId) > 0) {
                    continue;
                }
                
                board = _gameModel.getBoardForPlayerID( boardId );
                
                if( board == null) {
                    log.error("aiTimer(), but board is null for id=" + boardId);
                    continue;
                }
                
                _timeRemaining.put( boardId, getAIDelay( board._computerPlayerLevel) + Rand.nextIntRange(10, 100, 0));
                
                if( board._state > JoinGameBoardRepresentation.STATE_ACTIVE) {
                    log.error("aiTimer(), but board is getting knocked out");
                    continue;
                }
                
                //During wave attacks, robots not adjecent to the human are idle
                if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_WAVES && 
                        !ArrayUtil.contains(_gameModel.getComputerIdsAdjacentToHumanPlayer(), board.playerID)) {
                    continue;
                }
                
                log.debug("do AI for board=" + board.playerID);
                /**
                * Pretty simple AI.
                * 
                * Choose whether to attack or go up.
                * 
                * Attacks:
                * Choose where to attack.
                *       Compute FROM where on my own board I can attack.
                *           Choose where I have the longest already connected possible joins.
                *       Compute the best place TO attack.
                *       Intersect those.
                *       Find the closest, longest join. 
                * 
                * 
                */
                
                /** Where to to attack FROM
                
                */
//                var foundRowForJoin :Boolean = false;
                
                if( board.changeCurrentPotentialJoin ) {
                    
                    var rowsToAttack :Array;
                    var aimleft :Boolean;
                    if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_WAVES) {
                        var humanId :int = _gameModel.humanPlayerId;
                        aimleft = _gameModel.getPlayerIDToLeftOfPlayer( board.playerID ) == humanId;
                        if( humanId <= 0 ) {
                            log.error("Looking for best rows to attack human, but no human found.");
                            continue;
                        }
                        rowsToAttack = findBestRowsToAttack(humanId);//Row 0 == bottom row.
                    }
                    else if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS) {
                        aimleft = Rand.nextBoolean(0);
                        var idToAttack :int =  aimleft ? _gameModel.getPlayerIDToLeftOfPlayer( board.playerID ) : _gameModel.getPlayerIDToRightOfPlayer( board.playerID );
                        if( idToAttack == 0) {
                            log.error("Looking for best rows to attack, but nobody next to me");
                            continue;
                        }
                        rowsToAttack = findBestRowsToAttack(idToAttack);//Row indices counting from bottom
                    } 
                    
                    
                    
                    
                    //Get the best possible joins for each row.
                    var bestJoinsAndColors :Array = board.getBestJoinLengthAndColorForEachRow();
                    var lengths :Array = bestJoinsAndColors[0] as Array;
                    var colors :Array = bestJoinsAndColors[1] as Array;
                    var row2lengthAndColor :HashMap = new HashMap();
                    //Convert to a easier-to-manage hashmap
                    for( row = 0; row < colors.length; row++) {
                        row2lengthAndColor.put( row, [lengths[row], colors[row]]);
                    }
                    
                    //Try each row to attack.
                    
                    for each ( row in rowsToAttack) {
                        
                        if( Rand.nextBoolean(0)) {
                            continue;//Sometimes we will not attack the best row.
                        }
                        
                        if( row2lengthAndColor.containsKey(row) && (row2lengthAndColor.get( row ) as Array)[0] > 3) {
                            //We can (and will) attack from this row, using this color
                            board.currentPotentialJoinRowCountingFromBottom = row;//board.convertFromBottomYToFromTopY( row);
                            board.currentPotentialJoinColor = (row2lengthAndColor.get( row ) as Array)[1]
                            board.changeCurrentPotentialJoin = false;
//                            foundRowForJoin = true;
                            log.debug("For board " + board.playerID + ", making join at row(from bottom)=" + board.currentPotentialJoinRowCountingFromBottom);
                            break;
                        }
                    }
                    
                   
                    
                    
                }
                
                if( !board.changeCurrentPotentialJoin ) {
                    makeDeltaBasedOnTargetJoin( board, aimleft );
                }
                else {//Ok, no horizontal join found, we'll resort to a vertical join.
                    var foundVerticalJoin :Boolean = false;
                    for( var col :int = 0; col < board._cols; col++) {
                        if( foundVerticalJoin ) { break;}
                        
                        for( var color :int = 0; color < Constants.PIECE_COLORS_ARRAY.length; color++) {
                            var verticalJoinRow :int = board.isVerticalJoinPossible( col, color);
                            if( verticalJoinRow > -1) {
                                
                                makeDeltaForVerticalJoin(board, col, row, color);
                                foundVerticalJoin = true;
                                break;
                            }
                        }
                    }
                }


            }
        }
        
        
        //This is really crude.  Just move the colored piece down as far as it will go.
        protected function makeDeltaForVerticalJoin( board :JoinGameBoardRepresentation, targetCol :int, targetRow :int, color :int) :void
        {
            Log.setLevel(ClassUtil.getClassName(SinglePlayerServerPlugin), Log.DEBUG);
            log.debug(" makeDeltaForVerticalJoin( boardid=" + board.playerID + ", col=" + targetCol + ", row=" + targetRow + ", color=" + color + ")");
            var lowestRowAvailableForJoin :int;
            var row :int;
            var col :int;
            var i :int;
            var j :int;
            
            //Find the lowest row for the given color and starting row.
            for( lowestRowAvailableForJoin = targetRow; lowestRowAvailableForJoin < board._rows; lowestRowAvailableForJoin++) {
                if( board._boardPieceTypes[ board.coordsToIdx(targetCol, lowestRowAvailableForJoin + 1) ] == Constants.PIECE_TYPE_NORMAL) {
                    continue;
                }
                else {
                    break;
                }
            }
            
            //Then find the highest valid piece
            var highestRowWithColoredPiece :int = lowestRowAvailableForJoin;//board._rows;
            for( row = lowestRowAvailableForJoin; row >= 0; row--) {
                if( board._boardPieceTypes[ board.coordsToIdx(targetCol, row) ] != Constants.PIECE_TYPE_NORMAL) {
                    break;
                }
                else if( board._boardPieceColors[ board.coordsToIdx(targetCol, row) ] == color) {
                    highestRowWithColoredPiece = row;
                }
            }
            
            if( highestRowWithColoredPiece >= 0 && highestRowWithColoredPiece < board._rows) {
                var msg :DeltaRequestMessage = new DeltaRequestMessage(board.playerID, 
                    targetCol,
                    highestRowWithColoredPiece,
                    targetCol,
                    lowestRowAvailableForJoin
                    );
                    log.debug("      Attempting vertical join " + msg);
                    
                    if( highestRowWithColoredPiece != lowestRowAvailableForJoin) {
                        _server.handleDeltaRequest( msg);
                    }
                    else {
                        log.warning("Error in makeDeltaForVerticalJoin( boardid=" + board.playerID + ", col=" + targetCol + ", row=" + targetRow + ", color=" + color + ")");
                        log.warning("   rows swapped are the same.");
                        log.debug("  baord:" + board);
                    }
            }
            else {
                log.debug("No vertical join found.");
            }
            Log.setLevel(ClassUtil.getClassName(SinglePlayerServerPlugin), Log.ERROR);
        }
        
        public function checkStateAfterActualPlayerRemoval() :void
        {
            if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS) {
                if( _gameModel.currentSeatingOrder.length <= 1) {
                    log.debug("Stopping AI, " + Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS + ", and only one board");
                    stopAI();
                    handleGameOver();             
                }
            }
            else if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_WAVES) {
                /*If there is no human player, will we watch the end*/
                if( !ArrayUtil.contains(_gameModel.currentSeatingOrder, _gameModel.humanPlayerId)) {
                    trace("Stopping AI, " + Constants.SINGLE_PLAYER_GAME_TYPE_WAVES + ", human defeated");
                    stopAI();
                    handleGameOver();
                }
                else if( _gameModel.currentSeatingOrder.length <= 1 ) {
                    trace("Stopping AI, " + Constants.SINGLE_PLAYER_GAME_TYPE_WAVES + ", and only one board");
                    stopAI();
                    handleGameOver();
//                    AppContext.singlePlayerCookie.highestRobotLevelDefeated++;

                    
                    
                    AppContext.singlePlayerCookie.bestKillsPerDeltaRatio = AppContext.database.getMeanKillsPerDelta(_gameModel.humanPlayerId); 
                    log.debug("AppContext.singlePlayerCookie.bestKillsPerDeltaRatio=" + AppContext.singlePlayerCookie.bestKillsPerDeltaRatio);
                    
//                    log.debug("After wave defeated, player level=" + AppContext.singlePlayerCookie.highestRobotLevelDefeated++);
                    Trophies.handleWaveDefeated( _gameModel, AppContext.singlePlayerCookie );
                    
                    if( AppContext.singlePlayerCookie == null) {
                        log.error("checkStateAfterActualPlayerRemoval(), sending WaveDefeatedMessage, but cookie null");
                    }
                    AppContext.messageManager.sendMessage( new WaveDefeatedMessage(AppContext.singlePlayerCookie.clone()));  
                }
                
            }
            else {
                log.error("checkStateAfterActualPlayerRemoval(), but not doing anything");
            }
            
            
            
//            /*If there is no human player, will we watch the end, or will we end the game*/
//            if( !ArrayUtil.contains(_gameModel.currentSeatingOrder, _gameModel.humanPlayerId)) {
//                
//            }
//            else /*Otherwise if there is only 1 player left, that's the end of the wave..*/
//            if( _gameModel.currentSeatingOrder.length == 1) {
//                
//            }
        }
        
        /**
        * Always attempt to make a size-4-join (for simplicity).
        */
        protected function makeDeltaBasedOnTargetJoin( board :JoinGameBoardRepresentation, aimleft :Boolean ) :void
        {
            
            var targetJoinRowCountingFromTop :int = board.convertFromBottomYToFromTopY(board.currentPotentialJoinRowCountingFromBottom);
            
            var aimLeft :Boolean = aimleft;//_gameModel.getPlayerIDToLeftOfPlayer( board.playerID) > 0;
            var increment :int = aimLeft ? 1 : -1;
            var startCol :int = aimLeft ? 0 : board._cols - 1;
            
            
            //Testing  hacker.  For now, just move the target colors to the row
            log.debug("target color=" + board.currentPotentialJoinColor + ", at row(from top)=" + targetJoinRowCountingFromTop);
            for( var col :int = startCol; col < board._cols && col > -1; col += increment) {
                if( board._boardPieceColors[ board.coordsToIdx(col, targetJoinRowCountingFromTop) ] == board.currentPotentialJoinColor) {
                    log.debug("   there is a color already at loc(" + col + ", " + targetJoinRowCountingFromTop + "), continueing");
                    continue;
                }
                else if( board._boardPieceTypes[ board.coordsToIdx(col, targetJoinRowCountingFromTop) ] != Constants.PIECE_TYPE_NORMAL) {
                    log.debug("   there is shit at loc(" + col + ", " + targetJoinRowCountingFromTop + "), continueing");
                    continue;
                }
                else {
                    log.debug("   what about loc(" + col + ", " + targetJoinRowCountingFromTop + "): contains color? " + board.isColumnContainsColor(col, board.currentPotentialJoinColor));
//                    log.debug( board.idxToX(index) + " should == " + col);
                    var index :int = board.getHorizontallyClosestPieceIndexWithColor( col, targetJoinRowCountingFromTop,  board.currentPotentialJoinColor);
                    log.debug("   index of closest piece=" + index);
                    if( index >= 0 ) {
                        var msg :DeltaRequestMessage = new DeltaRequestMessage(board.playerID, 
                        col,
                        board.idxToY(index),
                        col,
                        targetJoinRowCountingFromTop
                        );
                        log.debug("      Attempting " + msg);
                        _server.handleDeltaRequest( msg);
                        break;
                    }
                    else {
                        log.debug("      Not requesting delta ");
                    }
                }    
            }
            
            
            
            //Get the max/min col indices of the join
            
            //If we are one join
//                     
//                    var opponentRowsToTargetInOrderOfPreference :Array;
//                    
//                    var longestJoinLength :int = 0;
//                    var longestJoinRow :int = 0;
//                    
//                    //From that, choose
//                    for( row = 0; row < aiBoard._rows; row++) {
//                        if( int(lengths[row]) > longestJoinLength) {
//                            longestJoinRow = row;
//                            longestJoinLength = int(lengths[row]);
//                        }
//                    }
//                    aiBoard.currentPotentialJoinColor = colors[longestJoinRow];
//                    aiBoard.currentPotentialJoinLength = longestJoinLength;
//                    aiBoard.currentPotentialJoinRow = longestJoinRow;
//                    aiBoard.changeCurrentPotentialJoin = false;
//                }
//                
//                var colIncrement :int = _gameModel.getPlayerIDToLeftOfPlayer( aiBoard.playerID ) > 0 ? 1 : -1;



                
                
                
                //Now we know the longest join for a row, and the color, lets start making the join
                //making sure we fire it in the right direction.
                
                
//                var msg :DeltaRequestMessage = new DeltaRequestMessage(board.playerID, 
//                    board.idxToX(0),
//                    board.idxToY(0),
//                    board.idxToX(7),
//                    board.idxToY(7)
//                );
//                _server.handleDeltaRequest( msg);
                
                
                
        }
        
        /**
        * Rows count starting from the bottom.
        */
        protected function findBestRowsToAttack(targetId :int) :Array
        {
            var row :int;
            var targets :Array = new Array();
//            if( _gameType == Constants.SINGLE_PLAYER_GAME_TYPE_WAVES) {
//                
//            }
            var board :JoinGameBoardRepresentation = _gameModel.getBoardForPlayerID( targetId ); //_gameModel.humanPlayerId );
            if(board == null) {
                log.warning( "findBestRowsToAttack(), human player board is null, so no target rows returned.");
                return targets;
            }
            
            //We'll just attack the row with the most damage , unless it's fully damaged.
            var rowsAndDamage :HashMap = board.getRowsAndDamage();
            log.debug("rowsSortedByDamage=" +  rowsSortedByDamage );
            
            
            //Order the rows in the best order to attack.
            var rowsSortedByDamage :Array = new Array();
            for( var damage :int = Constants.PUZZLE_STARTING_COLS - 1; damage >= 0; damage--) {
                for each (row in rowsAndDamage.keys()) {
                    if( int(rowsAndDamage.get(row)) >= damage) {
                        rowsSortedByDamage.push( board.convertFromBottomYToFromTopY(row) );
                    }
                }
            }
            if( rowsAndDamage.get( rowsSortedByDamage[0] ) == 0 ) {
                rowsSortedByDamage.unshift( board._rows/2 + (Rand.nextBoolean(0) ? 1 : 2));
            }
            
            
//            if( rowsSortedByDamage[1] == 0) {//If there is no damage, attack the middle
//                rowsSortedByDamage.unshift([ board._rows / 2, 0]);//Add the middle rows.  They are already present in the array, so this is hackery.
//                rowsSortedByDamage.unshift([ (board._rows / 2) + 1, 0]);
//                rowsSortedByDamage.unshift([ (board._rows / 2) - 1, 0]);
//            }
            
//            for( var k :int = 0; k < rowsSortedByDamage.length; k++) {
//                var row :int = (rowsSortedByDamage[k] as Array)[0] as int;
//                row = board.convertFromBottomYToFromTopY(row);
//                if( !ArrayUtil.contains( targets, row)) {
//                    targets.push( row);
//                }
//            }
            
            return rowsSortedByDamage;
        }
        
        internal function playerLeftOrKnockedOut( playerid :int) :void
        {
            if( robotId2Level.containsKey( playerid ) ) {
                robotId2Level.remove( playerid );
            }
            log.debug("Server (Single Player) playerLeftOrKnockedOut( " + playerid + ")");
            if( !ArrayUtil.contains( _gameModel.currentSeatingOrder, playerid)) {
                log.warning("Server playerLeftOrKnockedOut( " + playerid + "), but not in seating order.  Ignoring.");
                return;
            }
            var time :int = getTimer();
            var removePlayerOutAfterDelayTimer :Timer;
            var board :JoinGameBoardRepresentation = _gameModel.getBoardForPlayerID(playerid) as JoinGameBoardRepresentation;
            if( board != null && board._state > JoinGameBoardRepresentation.STATE_ACTIVE) {
                log.debug("Board is already getting knocked out, so ignoring.");
                return;
            }
            if( board != null && board._state == JoinGameBoardRepresentation.STATE_ACTIVE) { 
                    
                if( _gameModel.currentSeatingOrder.length < 2 || playerid > 0 ) { //It's the player getting knocked out
//                    log.debug("Stopping AI"); 
//                    stopAI();
                }       
                
                board._state = JoinGameBoardRepresentation.STATE_GETTING_KNOCKED_OUT;
                AppContext.messageManager.sendMessage( new PlayerDestroyedMessage( playerid));
                
                removePlayerOutAfterDelayTimer = new Timer( Constants.BOARD_DISTRUCTION_TIME * 1000, 1);
                removePlayerOutAfterDelayTimer.addEventListener(TimerEvent.TIMER, removePlayer);
                removePlayerOutAfterDelayTimer.start();
                
                function removePlayer( e :TimerEvent ) :void
                {
                    removePlayerOutAfterDelayTimer.removeEventListener(TimerEvent.TIMER, removePlayer);
                    _gameModel.removePlayer(playerid);
                    
                    AppContext.messageManager.sendMessage( new PlayerRemovedMessage( playerid));
                    if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS && playerid > 0) {
                        AppContext.messageManager.sendMessage( new GoToObserverModeMessage(playerid));
                    }
                    checkStateAfterActualPlayerRemoval();
                }
                
            }
            else { //It's the computer player getting knocked out
                
//                    var lowestComputerId :int = 0;  
//                    var ids :Array =  _gameModel.currentSeatingOrder; 
//                    
//                    var idsToRemove :Array = new Array();
//                    for each (var computerPlayerId :int in ids) {
//                        if( computerPlayerId < 0 ) {
//                            
//                            AppContext.messageManager.sendMessage( new PlayerDestroyedMessage( computerPlayerId));
//                            removePlayerOutAfterDelayTimer = new Timer( Constants.BOARD_DISTRUCTION_TIME * 1000, 1);
//                            
//                            idsToRemove.unshift( computerPlayerId );
//                            removePlayerOutAfterDelayTimer.addEventListener(TimerEvent.TIMER, removeComputerPlayer);
//                            removePlayerOutAfterDelayTimer.start();
//                            
//                            function removeComputerPlayer( e :TimerEvent ) :void
//                            {
//                                var id2Remove :int = idsToRemove.pop();
//                                removePlayerOutAfterDelayTimer.removeEventListener(TimerEvent.TIMER, removePlayer);
//                                _gameModel.removePlayer(id2Remove);
//                                AppContext.messageManager.sendMessage( new PlayerRemovedMessage( id2Remove));
//                            }
//                            
//                        }
//                    }
//                    _gameModel.singlePlayerLevel++;
                    
                    
//                    addNewComputerPlayer();
//                    log.debug("Adding new computer players, lowestComputerId=" + lowestComputerId);
//                    addNewComputerPlayer();
//                    log.debug("Adding new computer players, lowestComputerId=" + lowestComputerId);
                    
                    
                }
        }
        
        /**
        * Creates a number of robot opponents, half above the players current level, half below.
        */
        protected function addNewWave(requestedLevel :int) :void 
        {
            var left :Boolean = true;
//            for( var currentLevel :int = AppContext.singlePlayerCookie.highestRobotLevelDefeated - Constants.SINGLE_PLAYER_NUMBER_OF_OPPONENTS_PER_WAVE / 2;
//                     currentLevel < AppContext.singlePlayerCookie.highestRobotLevelDefeated + Constants.SINGLE_PLAYER_NUMBER_OF_OPPONENTS_PER_WAVE/2; 
//                   currentLevel++) {
            for( var k :int = 0; k < Constants.SINGLE_PLAYER_ROBOTS_PER_WAVE; k++) {
                addNewComputerPlayer(requestedLevel, left);
                left = !left;
            }
        }
        
        /**
        * Creates a number of robot opponents, with the levels ranginfg
        */
        protected function addRobots( number :int, highestLevel :int) :void 
        {
//            //create the array of levels
            var levels :Array = new Array();
            for( var k :int = 0; k < number; k++) {
                levels.push( Rand.nextIntRange( Math.max( 1, highestLevel - 5), highestLevel, 0) );
            }  
            
            //Make sure we have at least two robots of sufficient difficulty.
            levels[0] = highestLevel;
            levels[ levels.length - 1] = highestLevel;
                      
//            
            function shuffle(a :int,b :int) :int {
                return Rand.nextIntRange(0, 2, 0);
            }
            levels.sort(shuffle); 
//            
            var left :Boolean = true;
            for( k = 0; k < number; k++) {
//                var level :int = 1;
//                if( highestLevel > 1) {
//                    level = Rand.nextIntRange( Math.max( 1, highestLevel - 5), highestLevel, 0);
//                }
//                addNewComputerPlayer(level, left);
                addNewComputerPlayer(levels[k], left);
                left = !left;
            }
        }
        
        protected static function getAIDelay( level :int ) :int
        {
            var increment :int = Constants.SINGLE_PLAYER_BASE_AI_TIME_IN_MILLISECS / Constants.SINGLE_PLAYER_MAX_ROBOT_LEVELS;
            var results :int = Constants.SINGLE_PLAYER_BASE_AI_TIME_IN_MILLISECS - (Math.abs(level - 1) * increment);
            
            if( results <= UPDATE_TIME) {
                results = UPDATE_TIME;
            } 
            return results;
        }
        protected function addNewComputerPlayer(level :int, addToLeft :Boolean) :void
        {
            
            //_singlePlayerData.currentLowestComputerId--;
            //The weird stuff for the player id argument is a hack.  It allowes me to get the level
            //even when the board is removed.
            var board :JoinGameBoardRepresentation = _server.createNewRandomBoard( getNewComputerId(level) );
            board._isComputerPlayer = true;
            board._computerPlayerLevel = level;
            log.debug("adding robot player id=" + board.playerID + ", level=" + board._computerPlayerLevel + ", delay=" + getAIDelay(board._computerPlayerLevel));
            _gameModel.addPlayer(board.playerID, board, addToLeft);
            robotId2Level.put( board.playerID, board._computerPlayerLevel);
            
            _timeRemaining.put( board.playerID, getAIDelay(board._computerPlayerLevel));
            AppContext.messageManager.sendMessage( new AddPlayerMessage( board.playerID, true, addToLeft, board.getBoardAsCompactRepresentation()));
        }
        
        public function createNewSinglePlayerModel( playerId :int, gameType :String, userCookie :UserCookieDataSourcePlayer, requestedLevel :int) :void
        {
            AppContext.database.clearAll();
            
            AppContext.singlePlayerCookie = userCookie.clone();
            if( AppContext.singlePlayerCookie == null) {
                log.warning("createNewSinglePlayerModel(" + gameType + "), usercookie is null!!");
            }
            
            AppContext.singlePlayerCookie.currentDeltas = 0;
            AppContext.singlePlayerCookie.currentKills = 0;
            
            robotId2Level.clear();
            
            log.debug("attempting to create single player model");
//            function batch () :void {
                log.debug("createNewSinglePlayerModel( " + playerId + ")" );
                _gameModel.removeAllPlayers();
                _gameModel.addPlayer(playerId, _server.createNewRandomBoard(playerId), true);
                _gameModel.humanPlayerId = playerId;
                _gameModel._singlePlayerGameType = gameType;
//                _robotLevel = AppContext.singlePlayerCookie.highestRobotLevelDefeated;
                if( gameType == Constants.SINGLE_PLAYER_GAME_TYPE_WAVES ) {
                    if( requestedLevel > 0 && requestedLevel < AppContext.singlePlayerCookie.highestRobotLevelDefeated) {
                        addNewWave(requestedLevel);
                    }
                    else {
                        addNewWave(AppContext.singlePlayerCookie.highestRobotLevelDefeated + 1);
                    }
                }
                else if(gameType == Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS) {
                    
                    if(AppContext.singlePlayerCookie.highestRobotLevelDefeated <= 0) {
                        AppContext.singlePlayerCookie.highestRobotLevelDefeated = 1;
                    } 
                    log.debug("addRobots( 6, " + (AppContext.singlePlayerCookie.highestRobotLevelDefeated+1) + ")" );
                     
                    if( requestedLevel > 0 && requestedLevel < AppContext.singlePlayerCookie.highestRobotLevelDefeated) {
                        addRobots(Constants.SINGLE_PLAYER_ROBOTS_TOURNAMENT, requestedLevel);
                    }
                    else {
                    
                        addRobots(Constants.SINGLE_PLAYER_ROBOTS_TOURNAMENT, AppContext.singlePlayerCookie.highestRobotLevelDefeated + 1);
                    }
//                    if( userCookie.highestRobotLevelDefeated == 0) {
//                        log.error("createNewSinglePlayerModel(), selected " + Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS + ", but no level given");
//                    }
//                    else {
//                        
//                    }
                }
                
                _gameModel.setModelIntoPropertySpaces();
//            }
//            
//            if( AppContext.useServerAgent) {
//                AppContext.gameCtrl.net.doBatch( batch );
//            }
//            else {
//                batch();
//            }
            
            
        }
        internal function handleGameOver() :void
        {
            if( _gameModel.gameOver && !_AITimer.running) {
                return;
            }
            trace("Stopping single player game...");
            stopAI();
            _gameModel.gameOver = true;
            /* We assign scores according to an exponential scale, so the winner gets a big pot,
            while those knocked out early get very little. The winner gets half the pot, followed
            by 2nd place getting a quarter, 3rd gets 1/8 and so on.*/
            
            var k :int;
            var i :int;
            var playerIds :Array = new Array();
            var scores :Array = new Array();
            var points :Array = new Array();
            var playerIdsInOrderOfLoss :Array = _gameModel._playerIdsInOrderOfLoss.slice();
            playerIdsInOrderOfLoss.push( _gameModel.currentSeatingOrder[0]);
//            trace("playerIdsInOrderOfLoss=" + playerIdsInOrderOfLoss);
            for( k = 0; k < playerIdsInOrderOfLoss.length; k++) {
                playerIds.push( playerIdsInOrderOfLoss[k] );
                
                if(  playerIdsInOrderOfLoss[k] < 0) {
                    points.push(  getLevelForComputerId(playerIdsInOrderOfLoss[k]) * 50);
                }
                else {
                    points.push( 0 );
                }
            }
//            trace("points=" + points);
//            scores.push( 25 );
            for( k = 0; k < playerIds.length; k++) {
                
                var score :int = 0;
                for( i = 0; i < k; i++) {
                    score += points[i];
                }
                scores.push( score);
                
                //The higher the computer level, the more points it's worth
//                points.push( board._computerPlayerLevel * 50); 
//                scores.push( scoreFunction(k+1) );
//                scores.push( (k+1) * 100 );
            }
//            trace("scores=" + scores);
            
            /* Changed the score due losers in two player games not getting anything. */
            trace("Single player game:\nAwarding scores:\nPlayer\t\t|\tScore\t\t|\tValue\n");
            for( i = playerIds.length - 1; i >= 0; i--) {
                if( int(playerIds[i]) < 0) {
                    trace("Robot " + Math.abs(int(playerIds[i])) + "  \t|\t" + scores[i] + "  \t|\t" + points[i]);    
                }
                else { 
                    trace("Player " + playerIds[i] + "  \t|\t" + scores[i] + "  \t|\t" + points[i]);
                }
            }
            
            var submittedPlayerIds : Array = new Array();
            var submittedScores : Array = new Array();
            for( k  = 0; k < playerIds.length; k++) {
                if( playerIds[k] > 0) {
                    submittedPlayerIds.push( playerIds[k] );
    //                scores.push( scoreFunction(k+1) );
                    submittedScores.push( scores[k] );
                }
            }
            
//            trace("endGameWithScores( " + submittedPlayerIds + ", " + submittedScores + ")");
            if( AppContext.gameCtrl.isConnected()) {
                AppContext.gameCtrl.game.endGameWithScores(submittedPlayerIds, submittedScores, GameSubControl.TO_EACH_THEIR_OWN);
                
            }
            
            //If the player wins, and playing the campaign, check if they go up a level
            if( _gameModel._singlePlayerGameType == Constants.SINGLE_PLAYER_GAME_TYPE_WAVES) {
                
                if( playerIds[ playerIds.length - 1 ] > 0) {
                    //Find the highest robot level, and set the cookie to it
//                    var highestLevelDefeated :int = 1;
                    AppContext.singlePlayerCookie.highestRobotLevelDefeated = Math.max(1, AppContext.singlePlayerCookie.highestRobotLevelDefeated);
                    for( k = 0; k < playerIds.length - 1; k++) {
                        var level :int = getLevelForComputerId(playerIds[k]);
                        if( level >= AppContext.singlePlayerCookie.highestRobotLevelDefeated) {
                            AppContext.singlePlayerCookie.highestRobotLevelDefeated = level;
                        }
                    }
                    //Also count the delta kill ratio
                    
                }
                
            }
            
            log.debug("AppContext.singlePlayerCookie.bestKillsPerDeltaRatio=" + AppContext.singlePlayerCookie.bestKillsPerDeltaRatio);
            AppContext.singlePlayerCookie.bestKillsPerDeltaRatio = AppContext.database.getMeanKillsPerDelta(_gameModel.humanPlayerId); 
            trace("sending " + AppContext.singlePlayerCookie);
            AppContext.messageManager.sendMessage( new GameOverMessage(AppContext.singlePlayerCookie));
            
        }
        
        protected function getNewComputerId( level :int ) :int
        {
            return (-1000 * level) - (++currentLowestComputerId);
        }
        public static function getLevelForComputerId( id :int ) :int
        {
            return int(id /-1000);
        }

    }
}