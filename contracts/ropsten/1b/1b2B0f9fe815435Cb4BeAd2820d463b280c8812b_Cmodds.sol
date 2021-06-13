/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Cmodds {

    enum BetType {Back, Lay}
    enum Selection {Open, Home, Away, Draw}
    enum BetStatus {Unmachted, Matched, Closed, Win, Lose}
    enum GameStatus {Open, Complete}
      
    struct Game {
        address owner;
        string objectId;
        GameStatus status;
        Selection winner;
    }

    struct Bet {
        address addr;
        uint256 amount;
        uint256 odds;
        Selection selection;
        BetType betType;
        BetStatus status;
    }
    
 
    /// hold the game data
    Game game;
    /// hold all unmatched bets
    mapping(BetType => mapping(Selection => Bet[])) unmatchedBets;
    /// hold all back bets by matched index
    mapping(uint => Bet[]) backBets;
     /// hold all lay bets by matched index
    mapping(uint => Bet[]) layBets;
    /// matched index to connect lay and back bets
    uint matchedIndex;
    
    /// Unmatched bet has been placed.
    event UnmatchedBetPlaced(string eventId, address addr, uint256 amount, uint256 odds, Selection selection, BetType betType);
    /// Matched bet has been placed.
    event MatchedBetPlaced(string eventId, address addr, uint256 amount, uint256 odds, Selection selection, BetType betType);
    /// Unmatched bet has been removed.
    event UnmatchedBetRemoved(string eventId, address addr, uint256 amount, uint256 odds, Selection selection, BetType betType);
    
    /// Game has already ended.
    error GameAlreadyEnded();
    /// Bet Amount of `amount` to low.
    error AmountToLow(uint amount);
    /// Odds of `odds` to low.
    error OddsToLow(uint256 odds);
    /// Only Owner can call.
    error OnlyOwner();
    
    
    /// check if amount is greater then zero
    modifier amountGreaterZero(uint _amount) {
        if(_amount <= 0) revert AmountToLow(_amount);
        _;
    }
    
    /// check if valid odds
    modifier checkOdds(uint256 _odds) {
        if(_odds <= 1 ether) revert OddsToLow(_odds);
        _;
    }
    
    /// check if valid odds
    modifier checkGameRunning() {
        if(game.status == GameStatus.Complete) revert GameAlreadyEnded();
        _;
    }
    
    /// check if address is from game owner
    modifier onlyOwner(address _addr) {
        if(_addr != game.owner) revert OnlyOwner();
        _;
    }
    

    /// Create game struct and init vars
    constructor(string memory _objectId) {
        game.owner = msg.sender;
        game.objectId = _objectId;
        game.status = GameStatus.Open;
        game.winner = Selection.Open;
        matchedIndex = 0;
    }
    
    /// Set winner selection side and trigger payout
    function setWinner (Selection _winner) public onlyOwner(msg.sender) checkGameRunning() {
        game.winner = _winner;
        payout();
        game.status = GameStatus.Complete;
    }

    /// Public function for placing back bet -> msg.value = bet amount
    function createBackBet(uint256 _odds, uint256 _amount, Selection _selection) public payable checkGameRunning() amountGreaterZero(msg.value) checkOdds(_odds) {
        require(_amount == msg.value, "Amount and send value are not equal!");
        placeBet(msg.sender, _amount, _odds, _selection, BetType.Back);
    }

    /// Public function for placing lay bet -> msg.value = bet liqidity
    function createLayBet(uint256 _odds, uint256 _amount, Selection _selection) public payable checkGameRunning() amountGreaterZero(msg.value) checkOdds(_odds) {
        uint256 liqidity = (_amount * (_odds - 1 ether) / 1 ether);
        require(liqidity == msg.value, "Liqidity and send value are not equal!");
        placeBet(msg.sender, _amount, _odds, _selection, BetType.Lay);
    }
    
    /// Internal function for placing and matching all bets
    function placeBet(address _addr, uint256 _amount, uint256 _odds, Selection _selection, BetType _betType) internal {
          
        // Get opposite bet type
        BetType oppositeType = _betType;
        if(BetType.Back == _betType){
            oppositeType = BetType.Lay;
        } else if(BetType.Lay == _betType) {
            oppositeType = BetType.Back;
        }
        
        // Get all unmatched bets from the same selection and the opposite bet type
        Bet[] storage unmatchedBetsArray = unmatchedBets[oppositeType][_selection];
        uint unmatchedBetsLength = unmatchedBetsArray.length;
        
        
        if(unmatchedBetsLength != 0){
            bool canMatch = false;
            uint256 amountLeft = _amount;
            
            // check if an unmatched bet can be matched with this _ bet
            for (uint i=0; i < unmatchedBetsLength; i++) {
                
                if(unmatchedBetsArray[i].odds == _odds){
                    
                    // match 1 to 1 if amount is same
                    if(unmatchedBetsArray[i].amount == amountLeft) {
                        canMatch = true;
                        Bet storage matchingWith = unmatchedBetsArray[i];
                        Bet memory myBet = Bet(_addr, amountLeft, _odds, _selection, _betType, BetStatus.Unmachted);

                        // push back and lay bets to mapping
                        if(BetType.Back == _betType) {
                            backBets[matchedIndex].push(myBet);
                            layBets[matchedIndex].push(matchingWith);
                        } else if (BetType.Lay == _betType) {
                            backBets[matchedIndex].push(matchingWith);
                            layBets[matchedIndex].push(myBet);
                        }
                        
                        emit MatchedBetPlaced(game.objectId, myBet.addr, myBet.amount, myBet.odds, myBet.selection, myBet.betType);
                        emit MatchedBetPlaced(game.objectId, matchingWith.addr, matchingWith.amount, matchingWith.odds, matchingWith.selection, matchingWith.betType);
                        
                        // delete matching bet from unmatchedBets
                        delete unmatchedBets[oppositeType][_selection][i];
                        
                        // increment matched index
                        matchedIndex++;
                        amountLeft = 0;
                    } 
                     // match 1 to 1 if unmatched amount is higher
                    else if (unmatchedBetsArray[i].amount > amountLeft) {
                        canMatch = true;
                        Bet storage matchingWith = unmatchedBetsArray[i];
                        Bet memory myBet = Bet(_addr, amountLeft, _odds, _selection, _betType, BetStatus.Unmachted);
                        matchingWith.amount =  matchingWith.amount - amountLeft;
                        
                        // push back and lay bets to mapping
                        if(BetType.Back == _betType) {
                            backBets[matchedIndex].push(myBet);
                            layBets[matchedIndex].push(matchingWith);
                        } else if (BetType.Lay == _betType) {
                            backBets[matchedIndex].push(matchingWith);
                            layBets[matchedIndex].push(myBet);
                        }
                        
                        emit MatchedBetPlaced(game.objectId, myBet.addr, myBet.amount, myBet.odds, myBet.selection, myBet.betType);
                        emit MatchedBetPlaced(game.objectId, matchingWith.addr, myBet.amount, matchingWith.odds, matchingWith.selection, matchingWith.betType);
                        
                        // increment matched index
                        matchedIndex++;
                        amountLeft = 0;
                    }
              
                    // break if bet is matched
                    if(amountLeft == 0){
                        break;
                    }
                    
                }
            }
            
            if(!canMatch) {
                placeUnmatchedBet(_addr, _amount ,_odds, _selection, _betType);
            }
        } else {
             // if nothing to match, place unmatched bet
            placeUnmatchedBet(_addr, _amount, _odds, _selection, _betType);
        }
    }
  
    /// Internal function for placing unmatched bet
    function placeUnmatchedBet(address _addr, uint256 _amount, uint256 _odds, Selection _selection, BetType _betType) internal {
        Bet memory _bet = Bet(_addr,_amount, _odds, _selection, _betType, BetStatus.Unmachted);
        unmatchedBets[_betType][_selection].push(_bet);
        emit UnmatchedBetPlaced(game.objectId, _addr, _amount, _odds, _selection, _betType);
    }
  
  
    /// Public function for removing unmatched bet
    function removeUnmatchedBet(uint256 _odds, uint256 _amount, Selection _selection, BetType _betType) public returns (bool) {
        
        // Get all unmatched bets with this _ type and selection
        Bet[] storage _bets = unmatchedBets[_betType][_selection];
        uint betsLength = _bets.length;
    
        if(betsLength > 0){
            for (uint i=0; i < betsLength; i++) {
                
                // skip if address is not from sender
                if(_bets[i].addr != msg.sender){
                    continue;
                }
                
                // check if this _ bet exits in contract, emit event, send amount back and remove from contract
                if(_bets[i].amount == _amount && _bets[i].odds == _odds  && _bets[i].odds == _odds && _bets[i].selection == _selection  && _bets[i].betType == _betType && _bets[i].status == BetStatus.Unmachted) {
                    emit UnmatchedBetRemoved(game.objectId, msg.sender, _amount, _odds, _selection, _betType);
                    payable(msg.sender).transfer(_amount);
                    delete unmatchedBets[_betType][_selection][i];
                    return true;
                }
            }
        }
        return false;
    }
  
  
    /// Internal function for paying all sides from all matched bets for the game
    function payout () internal {
        for (uint i=0; i < matchedIndex; i++) {
                
            // Get all matched back bets for current index
            Bet[] storage currentBackBets = backBets[i];
            uint currentBackBetsLength = currentBackBets.length;
            
            for (uint y=0; y < currentBackBetsLength; y++) {
                
                // Check if back bet has won and send money
                if(currentBackBets[y].selection == game.winner) {
                    uint256 amount = (currentBackBets[y].amount * (currentBackBets[y].odds - 1 ether)  / 1 ether );
                    payable(currentBackBets[y].addr).transfer(amount);
                    currentBackBets[y].status = BetStatus.Win;
                }
            }
            
            // Get all matched lay bets for current index
            Bet[] storage currentLayBets = layBets[i];
            uint currentLayBetsLength = currentLayBets.length;
            
            for (uint y=0; y < currentLayBetsLength; y++) {
                
                // Check if lay bet has won and send money
                if(currentLayBets[y].selection != game.winner) {
                    uint256 amount = currentLayBets[y].amount;
                    payable(currentLayBets[y].addr).transfer(amount);
                    currentLayBets[y].status = BetStatus.Win;
                }
            }
        }
    }
}