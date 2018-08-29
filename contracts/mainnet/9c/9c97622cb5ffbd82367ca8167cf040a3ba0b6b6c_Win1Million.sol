pragma solidity ^0.4.22;

pragma solidity ^0.4.22;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Win1Million {
    
    using SafeMath for uint256;
    
    address owner;
    address bankAddress;
    
    bool gamePaused = false;
    uint256 public houseEdge = 5;
    uint256 public bankBalance;
    uint256 public minGamePlayAmount = 30000000000000000;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    modifier onlyBanker() {
        require(bankAddress == msg.sender);
        _;
    }
    modifier whenNotPaused() {
        require(gamePaused == false);
        _;
    }
    modifier correctAnswers(uint256 barId, string _answer1, string _answer2, string _answer3) {
        require(compareStrings(gameBars[barId].answer1, _answer1));
        require(compareStrings(gameBars[barId].answer2, _answer2));
        require(compareStrings(gameBars[barId].answer3, _answer3));
        _;
    }
    
    struct Bar {
        uint256     Limit;          // max amount of wei for this gamePaused
        uint256     CurrentGameId;
        string      answer1;
        string      answer2;
        string      answer3;
    }
    
    struct Game {
        uint256                         BarId;
        uint256                         CurrentTotal;
        mapping(address => uint256)     PlayerBidMap;
        address[]                       PlayerAddressList;
    }
    
    struct Winner {
        address     winner;
        uint256     amount;
        uint256     timestamp;
        uint256     barId;
        uint256     gameId;
    }

    Bar[]       public  gameBars;
    Game[]      public  games;
    Winner[]    public  winners;
    
    mapping (address => uint256) playerPendingWithdrawals;
    
    function getWinnersLen() public view returns(uint256) {
        return winners.length;
    }
    
    // helper function so we can extrat list of all players at the end of each game...
    function getGamesPlayers(uint256 gameId) public view returns(address[]){
        return games[gameId].PlayerAddressList;
    }
    // and then enumerate through them and get their respective bids...
    function getGamesPlayerBids(uint256 gameId, address playerAddress) public view returns(uint256){
        return games[gameId].PlayerBidMap[playerAddress];
    }
    
    constructor() public {
        owner = msg.sender;
        bankAddress = owner;
        
        // ensure we are above gameBars[0] 
        gameBars.push(Bar(0,0,"","",""));
        
        // and for games[0]
        address[] memory _addressList;
        games.push(Game(0,0,_addressList));
        
    }
    
    event uintEvent(
        uint256 eventUint
        );
        
    event gameComplete(
        uint256 gameId
        );
        

    // Should only be used on estimate gas to check if the players bid
    // will be acceptable and not be over the game limit...
    // Should not be used to send Ether!
    function playGameCheckBid(uint256 barId) public whenNotPaused payable {
        uint256 houseAmt = (msg.value.div(100)).mul(houseEdge);
        uint256 gameAmt = (msg.value.div(100)).mul(100-houseEdge);
        uint256 currentGameId = gameBars[barId].CurrentGameId;
        //emit uintEvent(gameAmt);
        //emit uintEvent(gameBars[barId].CurrentGameId);
        //emit uintEvent(games[currentGameId].CurrentTotal);
        //emit uintEvent(games[currentGameId].CurrentTotal.add(gameAmt));
        //emit uintEvent(gameBars[barId].Limit);
        
        if(gameBars[barId].CurrentGameId == 0) {
            if(gameAmt > gameBars[barId].Limit) {
                // gameAmt must be min bet only!
                require(msg.value == minGamePlayAmount);
            }
            //require(gameAmt <= gameBars[barId].Limit);
            
        } else {
            currentGameId = gameBars[barId].CurrentGameId;
            require(games[currentGameId].BarId > 0); // Ensure it hasn&#39;t been closed already
            if(games[currentGameId].CurrentTotal.add(gameAmt) > gameBars[barId].Limit) {
                // gameAmt must be min bet only!
                require(msg.value == minGamePlayAmount);
            }
            //require(games[currentGameId].CurrentTotal.add(gameAmt) <= gameBars[barId].Limit); // Can&#39;t over bid = game full and closing
        }

    }

    
    // houseEdge goes to bankBalance, rest goes into game pot...
    // answers submitted encrypted from website but can be replayed by users - issue?
    // present as:
    // Q1: What color are often the domes of churches in Russia?
    // Q2: What is the national animal of Albania?
    // Q3: How many oscars did the Titanic movie win?
    // Solve the above questions or decipher the answers from the blockchain!
    // https://www.quiz-questions.net/film.php
    function playGame(uint256 barId,
            string _answer1, string _answer2, string _answer3) public 
            whenNotPaused 
            correctAnswers(barId, _answer1, _answer2, _answer3) 
            payable {
        require(msg.value >= minGamePlayAmount);
        
        // check if a game is in play for this bar...
        uint256 houseAmt = (msg.value.div(100)).mul(houseEdge);
        uint256 gameAmt = (msg.value.div(100)).mul(100-houseEdge);
        uint256 currentGameId = 0;
        
        
        if(gameBars[barId].CurrentGameId == 0) {
            
            //require(gameAmt <= gameBars[barId].Limit); // Can&#39;t over bid = game full and closing
            if(gameAmt > gameBars[barId].Limit) {
                // gameAmt must be min bet only!
                require(msg.value == minGamePlayAmount);
            }
            
            // create new game...
            address[] memory _addressList;
            games.push(Game(barId, gameAmt, _addressList));
            currentGameId = games.length-1;
            
            gameBars[barId].CurrentGameId = currentGameId;
            
        } else {
            currentGameId = gameBars[barId].CurrentGameId;
            require(games[currentGameId].BarId > 0); // Ensure it hasn&#39;t been closed already
            if(games[currentGameId].CurrentTotal.add(gameAmt) > gameBars[barId].Limit) {
                // gameAmt must be min bet only!
                require(msg.value == minGamePlayAmount);
            }
            //require(games[currentGameId].CurrentTotal.add(gameAmt) <= gameBars[barId].Limit); // Can&#39;t over bid = game full and closing
            
            games[currentGameId].CurrentTotal = games[currentGameId].CurrentTotal.add(gameAmt);    
        }
        
        
        
        if(games[currentGameId].PlayerBidMap[msg.sender] == 0) {
            // Add to the PlayerAddressList...
            // Above check avoids duplicates
            games[currentGameId].PlayerAddressList.push(msg.sender);
        }
        
        // Increase the player bid map...
        games[currentGameId].PlayerBidMap[msg.sender] = games[currentGameId].PlayerBidMap[msg.sender].add(gameAmt);
        
        // Increase bankBalance...
        bankBalance+=houseAmt;
        
        // is the game complete??
        if(games[currentGameId].CurrentTotal >= gameBars[barId].Limit) {

            emit gameComplete(gameBars[barId].CurrentGameId);
            gameBars[barId].CurrentGameId = 0;
        }
        
        
    }
    event completeGameResult(
            uint256 indexed gameId,
            uint256 indexed barId,
            uint256 winningNumber,
            string  proof,
            address winnersAddress,
            uint256 winningAmount,
            uint256 timestamp
        );
    
    // using NotaryProxy to generate random numbers with proofs stored in logs so they can be traced back
    // publish list of players addresses - random number selection (With proof) and then how it was selected
    
    function completeGame(uint256 gameId, uint256 _winningNumber, string _proof, address winner) public onlyOwner {


        
        if(!winner.send(games[gameId].CurrentTotal)){
            // need to add to a retry list...
            
            playerPendingWithdrawals[winner] = playerPendingWithdrawals[winner].add(games[gameId].CurrentTotal);
        }
        
        // Add to the winners array...
        winners.push(Winner(
                winner,
                games[gameId].CurrentTotal,
                now,
                games[gameId].BarId,
                gameId
            ));
        
        emit completeGameResult(
                gameId,
                games[gameId].BarId,
                _winningNumber,
                _proof,
                winner,
                games[gameId].CurrentTotal,
                now
            );
        
        // reset the bar state...
        gameBars[games[gameId].BarId].CurrentGameId = 0;
        // delete the game 
        //delete games[gameId];
        

        
    }
    
    event cancelGame(
            uint256 indexed gameId,
            uint256 indexed barId,
            uint256 amountReturned,
            address playerAddress
            
        );
    // players can cancel their participation in a game as long as it hasn&#39;t completed
    // they lose their houseEdge fee (And pay any gas of course)
    function player_cancelGame(uint256 barId) public {
        address _playerAddr = msg.sender;
        uint256 _gameId = gameBars[barId].CurrentGameId;
        uint256 _gamePlayerBalance = games[_gameId].PlayerBidMap[_playerAddr];
        
        if(_gamePlayerBalance > 0){
            // reset player bid amount
            games[_gameId].PlayerBidMap[_playerAddr] = 1; // set to 1 wei to avoid duplicates
            games[_gameId].CurrentTotal -= _gamePlayerBalance;
            
            if(!_playerAddr.send(_gamePlayerBalance)){
                // need to add to a retry list...
                playerPendingWithdrawals[_playerAddr] = playerPendingWithdrawals[_playerAddr].add(_gamePlayerBalance);
            } 
        } 
        
        emit cancelGame(
            _gameId,
            barId,
            _gamePlayerBalance,
            _playerAddr
            );
    }
    
    
    function player_withdrawPendingTransactions() public
        returns (bool)
     {
        uint withdrawAmount = playerPendingWithdrawals[msg.sender];
        playerPendingWithdrawals[msg.sender] = 0;

        if (msg.sender.call.value(withdrawAmount)()) {
            return true;
        } else {
            /* if send failed revert playerPendingWithdrawals[msg.sender] = 0; */
            /* player can try to withdraw again later */
            playerPendingWithdrawals[msg.sender] = withdrawAmount;
            return false;
        }
    }
    // wei: 1000000000000000000
    // to 100 = / 10000000000000000 (16 zeros)
    
/*
    function _generate_seed(uint256 _gameId) internal view returns(uint256) {
        bytes32 _hash;
        for(uint256 c = 0; c < games[_gameId].PlayerAddressList.length; c++) {
            _hash = keccak256(_hash, games[_gameId].PlayerAddressList[c]);
        }
        return bytes32ToUInt256(_hash);
    }
*/

    uint256 internal gameOpUint;
    function gameOp() public returns(uint256) {
        return gameOpUint;
    }
    function private_SetPause(bool _gamePaused) public onlyOwner {
        gamePaused = _gamePaused;
    }
    // 10=9.5/ $3800 Eth pot = 0.5 eth = $200
    // 20=19/ $7600 eth pot = 1 eth $400
    // 100=975.5/ $39,000 eth pot = 2.5 eth $1000
    // 200=190/ $76,000 eth pot = 10 eth =  $4000
    // 500=475/ $190,000 eth pot = 25 eth = $10k
    // winnings @ $400/eth
    // 

    function private_AddGameBar(uint256 _limit, 
                    string _answer1, string _answer2, string _answer3) public onlyOwner {

        gameBars.push(Bar(_limit, 0, _answer1, _answer2, _answer3));
        emit uintEvent(gameBars.length);
    }
    function private_DelGameBar(uint256 barId) public onlyOwner {
        if(gameBars[barId].CurrentGameId > 0){
            delete games[gameBars[barId].CurrentGameId];
        }
        delete gameBars[barId];
    }

    // Used to rebalance a game when the ETH/USD rate changes
    function private_UpdateGameBarLimit(uint256 barId, uint256 _limit) public onlyOwner {
        gameBars[barId].Limit = _limit;
    }
    function private_setHouseEdge(uint256 _houseEdge) public onlyOwner {
        houseEdge = _houseEdge;
    }
    function private_setMinGamePlayAmount(uint256 _minGamePlayAmount) onlyOwner {
        minGamePlayAmount = _minGamePlayAmount;
    }
    function private_setBankAddress(address _bankAddress) public onlyOwner {
        bankAddress = _bankAddress;
    }
    function private_withdrawBankFunds(address _whereTo) public onlyBanker {
        if(_whereTo.send(bankBalance)) {
            bankBalance = 0;
        }
    }
    function private_withdrawBankFunds(address _whereTo, uint256 _amount) public onlyBanker {
        if(_whereTo.send(_amount)){
            bankBalance-=_amount;
        }
    }
    function private_kill() public onlyOwner {
        selfdestruct(owner);
    }
    
    
    function compareStrings (string a, string b) internal pure returns (bool){
        return keccak256(a) == keccak256(b);
    }

}