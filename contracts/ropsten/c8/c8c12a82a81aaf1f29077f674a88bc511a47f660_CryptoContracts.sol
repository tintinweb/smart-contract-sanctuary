pragma solidity ^0.4.22;
//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

/**
 * Crypto Contracts.
 */
// contract CryptoContracts is usingOraclize {
contract CryptoContracts {
    uint256 private commissionPercentage = 8;
    address owner;
    bool checkOwner = false;
    Game[] private games;
    mapping(bytes32 => uint) queriesForGames;
    enum GameStatus {Active, Closed}

    //struct to contain Bet properties
    struct Bet {
        uint BetId;
        mapping(address => uint256) BettorDeposit;
        uint256 Jackpot;
        bytes32 betName;
        string externalId;
    }

    // struct to contain game properties
    struct Game {
        uint gameId;
        string title;
        Bet[] Bets;
        uint256 minBetPrice;
        uint256 maxBetPrice;
        uint256 commission;
        uint finalPrice;
        uint winningBet;
        GameStatus status;
        address creator;
        uint startTime;
        uint endTime;
        uint BetPeriod; //period user can join in seconds
        uint callbackPeriod; //period Game will be ended in seconds
        string oracleUrl;
        string externalId;
        bytes32 queryId;
    }

    // modifiers
    modifier onlyOwner {
        if (owner != msg.sender) revert();
        _;
    }
    modifier onlyLive(uint gameId) {
        Game storage a = games[gameId];
        if (a.status != GameStatus.Active) {
            revert();
        }
        _;
    }

    // Events
    event GameCreated(uint gameId,
        string title,
        string externalId,
        string oracleUrl,
        uint callbackPeriod,
        uint BetPeriod,
        uint256 minBetPrice,
        uint256 maxBetPrice,
        uint startTime,
        address creator,
        GameStatus status
    );

    event BetPlaced(uint gameId,
        uint BetId,
        address Bettor,
        uint256 amount,
        string externalId
    );

    event GameEnded(uint gameId,
        uint winningBet,
        uint endTime,
        GameStatus status
    );

    event LogFailure(uint gameId, string message);
    event LogMessage(uint gameId, string message);
    event ContractCreated(address owner);
    event Transfer(address receiver, uint256 amount);

    // constructor
    constructor () public {
        owner = msg.sender;
        emit ContractCreated(msg.sender);
    }

    function setCheckOwner(bool check) public onlyOwner{
        checkOwner = check;
    }

    /**
     * Create a new game.
     */
    function createGame(
        string title,
        string externalId,
        bytes32[] betNames,
        string oracleUrl,
        uint callbackPeriod,
        uint BetPeriod,
        uint256 minBetPrice,
        uint256 maxBetPrice,
        uint256 commission) public payable returns (uint gameId){

        if (checkOwner) {
            if (owner != msg.sender) revert();
        }

        // uint price = oraclize_getPrice("URL");
        // if (price > msg.value) {
        //     emit LogFailure(gameId, "Amount must be greater than oraclize price");
        //     revert();
        // }

        gameId = games.length++;
        Game storage a = games[gameId];
        for(uint i = 0; i < betNames.length; i++) {
            creatGameBet(gameId, betNames[i]);
        }
        a.gameId = gameId;
        a.commission = commission;
        a.BetPeriod = BetPeriod;
        a.creator = msg.sender;
        a.callbackPeriod = callbackPeriod;
        a.title = title;
        a.oracleUrl = oracleUrl;
        a.externalId = externalId;
        a.minBetPrice = minBetPrice;
        a.maxBetPrice = maxBetPrice;
        a.startTime = block.timestamp;
        a.status = GameStatus.Active;
        emit GameCreated(gameId, title, externalId, oracleUrl, callbackPeriod, BetPeriod, minBetPrice, maxBetPrice, a.startTime, msg.sender, GameStatus.Active);
        // updatePrice(callbackPeriod, gameId, oracleUrl);

        return gameId;
    }

    function creatGameBet(uint gameId, bytes32 betName) internal onlyLive(gameId) {
            Game storage game = games[gameId];
            uint betId = game.Bets.length++;
            Bet storage b = game.Bets[betId];
            b.BetId = betId;
            b.betName = betName;
    }

    //Note: user can only bet 0 or 2, can&#39;t bet tie (1)
    function placeBet(uint gameId, uint BetId, string externalId) payable public onlyLive(gameId) returns (bool success) {
        Game storage a = games[gameId];
        //limit bet price range, but user can bet multiple times to exceed max
        if (msg.value < a.minBetPrice || msg.value > a.maxBetPrice) {
            emit LogFailure(gameId, "Amount must be between minBetPrice and maxBetPrice");
            revert();
        }
        if (now > a.startTime + a.BetPeriod * 1 seconds) {
            emit LogFailure(gameId, "The Bet period has closed.   No more Bets may be placed for this game");
            revert();
        }

        Bet storage b = a.Bets[BetId];
        b.BetId = BetId;
        b.BettorDeposit[msg.sender] = b.BettorDeposit[msg.sender] + msg.value;
        b.externalId = externalId;
        b.Jackpot = b.Jackpot + msg.value;
        emit BetPlaced(gameId, BetId, msg.sender, msg.value, b.externalId);
        return true;
    }

    /**
     * Call to Oracle to fetch final price from Oracle service
    */
    // function updatePrice(uint callbackPeriod, uint gameId, string oracleUrl) internal {
    //     uint price = oraclize_getPrice("URL");
    //     address myAddress = this;
    //     if (price > myAddress.balance) {
    //         emit LogMessage(gameId, "Oraclize query was NOT sent, please add some ETH to cover for the query fee");
    //         gameCancelled(gameId);
    //     } else {
    //         emit LogMessage(gameId, strConcat("Oraclize query was sent, standing by for the answer: ", oracleUrl));
    //         bytes32 queryId = oraclize_query(callbackPeriod, "URL", oracleUrl);
    //         queriesForGames[queryId] = gameId;
    //         oraclize_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
    //     }
    // }

    /**
     * Oraclize Callback
    */
    // function __callback(bytes32 myid, string result) public {
    //     if (msg.sender != oraclize_cbAddress()) revert();
    //     uint gameId = queriesForGames[myid];
    //     endGame(gameId, parseInt(result,2));
    // }

    function gameCancelled(uint gameId) internal {
        uint endTime = now;
        Game storage game = games[gameId];
        game.finalPrice = 0;
        game.status = GameStatus.Closed;
        game.endTime = endTime;
        // for (uint j = 0; j < game.BettorDeposit.length; j++) {
        //     Bet storage invalidBet = game.Bets[j];
        //     invalidBet.Betder.transfer(invalidBet.amount);
        // }
        
        emit GameEnded(
            gameId,
            0,
            endTime,
            GameStatus.Closed);

    }
    
    function claimReward(uint gameId) public  {
        uint256 RewardAmount = getReward(gameId);
        if(RewardAmount > 0){
            msg.sender.transfer(RewardAmount);// sends ether to the claimer
            emit Transfer(msg.sender, RewardAmount);  
        }
    }

    //ToDo: updat final pirce,  
    //get start and final price or get price change
    //NOTE: 
    //0: tie
    //1: down
    //2: up
    function declareWinner(uint gameId) internal {
        Game storage game = games[gameId];
        if(game.finalPrice > 0) {
            game.winningBet = 2;
        } else if (game.finalPrice < 0) {
            game.winningBet = 1;
        } else { //if no user vote 1 or 2, also treat is tie
            game.winningBet = 0;
        }
        
        // uint winningBetIdx = 0;
       // Bet storage winningBet = game.Bets[0];
        // uint closestGuess = abs(game.finalPrice, winningBet.BetPrice);
        // for (uint i = 1; i < game.Bets.length; i++) {
        //     Bet storage currentBet = game.Bets[i];
        //     uint guess = abs(game.finalPrice, currentBet.BetPrice);
        //     if (guess < closestGuess || (guess == closestGuess && currentBet.timestamp < winningBet.timestamp)) {
        //         winningBet = currentBet;
        //         closestGuess = guess;
        //         winningBetIdx = i;
        //     }
        // }
        // game.winningBet=winningBetIdx;
        // uint commission = (game.jackpot * commissionPercentage)/100;
        // uint totalWinnings = game.jackpot - commission;
        // game.totalWinnings = totalWinnings;
        // game.commission = commission;
        // winningBet.Betder.transfer(totalWinnings); // send the winner their earnings
        
        emit GameEnded(
            game.gameId,
            game.winningBet,
            game.endTime,
            GameStatus.Closed);
    }

    function endGame(uint gameId, uint finalPrice) internal {
        uint endTime = now;
        Game storage game = games[gameId];
        game.finalPrice = finalPrice;
        
        game.status = GameStatus.Closed;
        game.endTime = endTime;
        if (game.Bets.length > 0){
            declareWinner(gameId);
        }else{
            emit GameEnded(
                gameId,
                game.winningBet,
                game.endTime,
                GameStatus.Closed);
        }
    }


    // read only functions
    function abs(uint a, uint b) public pure returns (uint256) {
        if (b > a) {
            return b - a;
        } else {
            return a - b;
        }
    }

    function getGameResultPrice(uint gameId) public view returns (uint256) {
        Game storage a = games[gameId];
        return a.finalPrice;
    }

    function getGameCount() public view returns (uint256) {
        return games.length;
    }

    function getGameInfo(uint idx) public view returns (
        uint gameId,
        string title,
        string oracleUrl,
        string externalId,
        address creator,
        uint BetPeriod, // in seconds
        uint callbackPeriod // in seconds
        ) {
        Game storage a = games[idx];
        return (a.gameId, a.title, a.oracleUrl, a.externalId, a.creator, a.BetPeriod, a.callbackPeriod);
    }

    function getGameStatus(uint idx) public view returns (
        uint gameId,
        uint startTime,
        uint finalPrice,
        GameStatus status,
        uint endTime) {
        Game storage a = games[idx];
        return (a.gameId, a.startTime, a.finalPrice, a.status, a.endTime);
    }

    function getBetCount(uint gameId) public view returns (uint256) {
        Game storage a = games[gameId];
        return a.Bets.length;
    }
    
    function getBetInfo(uint gameId, uint betId) public view returns (
        bytes32 betName) {
        Game storage a = games[gameId];
        return (a.Bets[betId].betName);
    }

    function getBettorInfo(uint gameId, uint BetId, address bettorAdd) public view returns (
        uint256 amount,
        bytes32 betName,
        string externalId) {
        Game storage a = games[gameId];
        Bet storage b = a.Bets[BetId];
        return (b.BettorDeposit[bettorAdd], b.betName, b.externalId);
    }

    /**
   * Get the result of a game
   */
    function getGameResult(uint gameId) public view returns (
        uint commission,
        uint finalPrice,
        uint endTime,
        GameStatus status,
        uint startTime) {
        Game storage a = games[gameId];
        return (a.commission, a.finalPrice,
        a.endTime, a.status,a.startTime);
    }

    function getReward(uint gameId) public view returns (
        uint RewardAmount
    ) {
        Game storage game = games[gameId];
        uint256 counterReward = 0;
        uint weight = 0;
        //case 1: price went down
        if(game.winningBet == 1 && game.Bets[1].BettorDeposit[msg.sender] > 0) { 
            weight = game.Bets[1].BettorDeposit[msg.sender]/game.Bets[1].Jackpot;
            counterReward = game.Bets[2].Jackpot*(1-game.commission/100)*weight;//in wei
            RewardAmount = game.Bets[1].BettorDeposit[msg.sender] + counterReward;
        }
        //case 2: price went up
        else if(game.winningBet == 2 && game.Bets[2].BettorDeposit[msg.sender] > 0) { 
            weight = game.Bets[2].BettorDeposit[msg.sender]/game.Bets[2].Jackpot;
            counterReward = game.Bets[1].Jackpot*(1-game.commission/100)*weight;//in wei
            RewardAmount = game.Bets[2].BettorDeposit[msg.sender] + counterReward;
        }
        //case tie:
        else if(game.winningBet == 0) {
            RewardAmount = game.Bets[1].BettorDeposit[msg.sender] + game.Bets[2].BettorDeposit[msg.sender];
        }
        //Case others: for looser
        else {
            RewardAmount = 0;
        }
        return RewardAmount;
    }
}