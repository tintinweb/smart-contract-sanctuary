/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

pragma solidity 0.4.11;

contract managed {
    address public manager;

    function managed() {
        manager = msg.sender;
    }

    modifier onlyManager {
        if (msg.sender != manager) throw;
        _;
    }

    function changeManager(address newManager) onlyManager {
        manager = newManager;
    }
}

contract SafeMath {
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
}

contract TenGame is managed, SafeMath {

    // FIELDS 

    uint public maxGameRange; // range is set from 0 to 100
    uint public maxBetPlayerNum; // max 10 players to bet in a game
    uint public winningCommissionPercent; // contract will take 2% of winner's bet

    Game[] public allGames;
    uint public numOfGames;

    ///  In order to get All-Active-Games:
    ///  Iterate from 0 -> allGames.length in front-end, 
    ///  and skip all finishedGameIDs to get all-active-game IDs. 
    ///  Then use these IDs to call function 'getGameDetail'
    uint[] public finishedGameIDs; 
    uint public numOfFinishedGames;

    /// maybe no use soon (if finishedGameIDs can help getting active-games)
    Game[] public allActiveGames; 


    mapping (address => int) public allPlayerBalances; // how much does each player own (msg.value)
    mapping (address => uint) public allPlayerHostCount; 
    mapping (address => uint) public allPlayerPlayCount; 
    uint public OverallWonAmount; // unit in wei (like msg.value)
    // mapping (uint => uint256) public allGameBalances; // how much a game's pool having (msg.value)

    // TODO: to have Game-played count for each player


    // EVENETS
    event GameAdded(uint gameID, address host, uint amount);
    event Bet1Bet(uint gameID, address betPlayer, uint betNum);
    event GameWon(uint gameID, address winner, uint winAmount);

    // STRUCT
    struct Game {
        uint gameID;
        uint startTime;

        uint betPool; // always use ether as unit, i.e. msg.value
        address host;
        uint startDeposit; // it specifies the size of game
        //uint secretNum;

        //mapping (address => uint) BetRecords; // records of player & his guess number
        uint[] Bets;
        uint numOfBets;
        uint nextBetRate;

        bool gameOver;
        address winner;
        uint winAmount;
    }

    uint[] secretNums;
    
    /// ** uncomment this with above mapping of players to bets ** ///
    // struct Bet {
    //     address betPlayer;
    //     uint betNumber;
    // }

    // MODIFIERS


    // FUNCTIONS
    function TenGame(
        uint _maxGameRange,
        uint _maxBetPlayerNum,
        uint _winningCommissionPercent
    ) {
        maxGameRange = _maxGameRange;
        maxBetPlayerNum = _maxBetPlayerNum;
        winningCommissionPercent = _winningCommissionPercent;
    }

    // when a player host a new game
    function newGame(address _host) payable
        returns (uint gameID)
    {
        // TODO: this function cannot take decimals for _startDeposit.
        // if ((_startDeposit * 1 ether) != msg.value) throw;  // in case someone just direct call this function without paying any ether
        
        if (msg.value < 0.1 ether) throw;

        gameID = allGames.length++;
        Game g = allGames[gameID];
        g.gameID = gameID;
        g.startTime = now;
        g.host = _host;
        g.startDeposit = msg.value;
        g.betPool = msg.value;
        g.nextBetRate = (2 * msg.value) / maxGameRange; // TODO: to have a better betRate formula

        uint rand = getRandomNum();
        secretNums.push(rand);

        allActiveGames.push(g); // assign same game detail to another record
        numOfGames++;

        allPlayerBalances[msg.sender] -= int(msg.value);
        allPlayerHostCount[msg.sender] += 1;
        GameAdded(gameID, _host, msg.value);
    }

    function betGame(uint _gameID, uint _betNum) payable
        returns (uint betID)
    {
        // checking if game exist
        if (_gameID < 0 || _gameID >= allGames.length) throw;

        Game g = allGames[_gameID];

        // check if game is ended
        if (g.gameOver == true) throw;

        // check if game slot full
        if (g.numOfBets >= maxBetPlayerNum) throw;

        // check if cheat payment
        //if (getBetRate(_gameID) > msg.value) throw; 
        if (g.nextBetRate > msg.value) throw; 

        betID = g.Bets.length++;
        g.Bets[betID] = _betNum;
        // g.BetRecords[msg.sender] = _betNum;
        g.numOfBets = g.Bets.length;
        g.nextBetRate += (2 * g.startDeposit) / (maxGameRange * 10);
        g.betPool += msg.value;

        allPlayerBalances[msg.sender] -= int(msg.value);
        allPlayerPlayCount[msg.sender] += 1;
        Bet1Bet(_gameID, msg.sender, _betNum);

        // checking game result:
        if (_betNum == secretNums[_gameID]) // ends if someone wins a bet
        {
            transferPrize(_gameID, msg.sender);
        }
        else if (g.numOfBets >= maxBetPlayerNum) // ends if game reaches maxPlayer
        {
            transferPrize(_gameID, g.host);
        }
    }

    function transferPrize(uint _gameID, address winner) 
    {
        // checking if game exist
        if (_gameID < 0 || _gameID >= allGames.length) throw;

        Game g = allGames[_gameID];

        // set winner and prize
        g.gameOver = true;
        g.winner = winner;
        g.winAmount = g.betPool * (1 - (winningCommissionPercent/100));
        
        // send prize of ether to winner
        if (g.winner.send(g.winAmount)) {
            g.betPool = 0;
            allPlayerBalances[msg.sender] += int(g.winAmount);
            OverallWonAmount += g.winAmount;
            GameWon(_gameID, g.winner, g.winAmount);   
        }

        // remove this game from 'AllActiveGames' records
        delete allActiveGames[_gameID];
        finishedGameIDs.push(_gameID);
        numOfFinishedGames++;
    }


    // GETTER


    // function getBetRate(uint _gameID) returns (uint priceRate)
    // {
    //     // checking if game exist
    //     if (_gameID < 0 || _gameID >= allGames.length) throw;

    //     Game g = allGames[_gameID];

    //     // to determine the next bet price
    //     // uint denominator = (maxGameRange / 2) - (2 * g.numOfBets);
    //     // return g.startDeposit / denominator;
    //     uint denominator = (maxGameRange / 2);
    //     return (g.startDeposit / denominator) * 1.05 * g.numOfBets;
    // }

    function getGameSecretNum(uint _gameID) 
        returns (uint resultNum)
    {
        // checking if game exist
        if (_gameID < 0 || _gameID >= allGames.length) throw;

        Game g = allGames[_gameID];

        if (g.gameOver == true) {
            return secretNums[_gameID];
        }
    }

    function getGameDetail(uint _gameID) public returns(uint, uint, address, uint, uint, uint, uint[])
    {
        // checking if game exist
        if (_gameID < 0 || _gameID >= allGames.length) throw;
        
        Game g = allGames[_gameID];
        
        return (
            g.startTime,
            g.betPool, 
            g.host,
            g.startDeposit,
            g.numOfBets,
            g.nextBetRate,
            g.Bets
            );
    }

    function getTotalNumOfGames() public returns (uint num) 
    {
        return allGames.length;
    }

    function getPlayerBalance(address _playerAdr) 
        returns (int balance)
    {
        return allPlayerBalances[_playerAdr];
    }

    function getRandomNum() returns (uint rand) {
        return uint(block.blockhash(block.number-1))%100 + 1;
    }

    function modifyWinningCommission(uint newPercent) onlyManager
    {
        winningCommissionPercent = newPercent;
    }

    function drain() onlyManager
	{
		if (!manager.send(this.balance)) throw;
	}

    // function getGameBets(uint _gameID) public returns(uint[] bets)
    // {
    //     // checking if game exist
    //     if (_gameID < 0 || _gameID >= allGames.length) throw;
        
    //     Game g = allGames[_gameID];

    //     // check if game is being deleted i.e. empty game detail
    //     if (g.betPool == 0) throw;
        
    //     return (g.Bets);
    // }

    // function getPlayerBetAtGame(uint _gameID, address _playerAdr) public 
    //     returns (uint bet)
    // {
    //     // checking if game exist
    //     if (_gameID < 0 || _gameID >= allGames.length) throw;
        
    //     Game g = allGames[_gameID];

    //     // check if game is being deleted i.e. empty game detail
    //     if (g.betPool == 0) throw;

    //     bet = g.BetRecords[_playerAdr];
    // }

    // function test(uint gameID)  
    // {
    //     testNum1 = allGames.length;

    //     // checking if game exist
    //     if (gameID < 0 || gameID >= allGames.length) throw;
        
    //     testNum2 = gameID + 1;
        

    // }

    // function testDelete(uint gameID) 
    // {
    //     Game g = allGames[gameID];
    //     testNum1 = g.betPool;

    //     delete allGames[gameID];

    //     Game h = allGames[gameID];
    //     testNum2 = h.betPool;
    // }



}