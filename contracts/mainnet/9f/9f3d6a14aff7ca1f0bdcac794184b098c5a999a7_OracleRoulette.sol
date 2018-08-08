pragma solidity ^0.4.23;

contract RouletteRules {
    function getTotalBetAmount(bytes32 first16, bytes32 second16) public pure returns(uint totalBetAmount);
    function getBetResult(bytes32 betTypes, bytes32 first16, bytes32 second16, uint wheelResult) public view returns(uint wonAmount);
}

contract OracleRoulette {

    //*********************************************
    // Infrastructure
    //*********************************************

    RouletteRules rouletteRules;
    address developer;
    address operator;
    // enable or disable contract
    // cannot place new bets if enabled
    bool shouldGateGuard;
    // save timestamp for gate guard
    uint sinceGateGuarded;

    constructor(address _rouletteRules) public payable {
        rouletteRules = RouletteRules(_rouletteRules);
        developer = msg.sender;
        operator = msg.sender;
        shouldGateGuard = false;
        // set as the max value
        sinceGateGuarded = ~uint(0);
    }

    modifier onlyDeveloper() {
        require(msg.sender == developer);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    modifier onlyDeveloperOrOperator() {
        require(msg.sender == developer || msg.sender == operator);
        _;
    }

    modifier shouldGateGuardForEffectiveTime() {
        // This is to protect players
        // preventing the owner from running away with the contract balance
        // when players are still playing the game.
        // This function can only be operated
        // after specified minutes has passed since gate guard is up.
        require(shouldGateGuard == true && (sinceGateGuarded - now) > 10 minutes);
        _;
    }

    function changeDeveloper(address newDeveloper) external onlyDeveloper {
        developer = newDeveloper;
    }

    function changeOperator(address newOperator) external onlyDeveloper {
        operator = newOperator;
    }

    function setShouldGateGuard(bool flag) external onlyDeveloperOrOperator {
        if (flag) sinceGateGuarded = now;
        shouldGateGuard = flag;
    }

    function setRouletteRules(address _newRouletteRules) external onlyDeveloperOrOperator shouldGateGuardForEffectiveTime {
        rouletteRules = RouletteRules(_newRouletteRules);
    }

    // only be called in case the contract may need to be destroyed
    function destroyContract() external onlyDeveloper shouldGateGuardForEffectiveTime {
        selfdestruct(developer);
    }

    // only be called for maintenance reasons
    function withdrawFund(uint amount) external onlyDeveloper shouldGateGuardForEffectiveTime {
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }

    // for fund deposit
    // make contract payable
    function () external payable {}

    //*********************************************
    // Game Settings & House State Variables
    //*********************************************

    uint BET_UNIT = 0.0002 ether;
    uint BLOCK_TARGET_DELAY = 0;
    // EVM is only able to store hashes of latest 256 blocks
    uint constant MAXIMUM_DISTANCE_FROM_BLOCK_TARGET_DELAY = 250;
    uint MAX_BET = 1 ether;
    uint MAX_GAME_PER_BLOCK = 10;

    function setBetUnit(uint newBetUnitInWei) external onlyDeveloperOrOperator shouldGateGuardForEffectiveTime {
        require(newBetUnitInWei > 0);
        BET_UNIT = newBetUnitInWei;
    }

    function setBlockTargetDelay(uint newTargetDelay) external onlyDeveloperOrOperator {
        require(newTargetDelay >= 0);
        BLOCK_TARGET_DELAY = newTargetDelay;
    }

    function setMaxBet(uint newMaxBet) external onlyDeveloperOrOperator {
        MAX_BET = newMaxBet;
    }

    function setMaxGamePerBlock(uint newMaxGamePerBlock) external onlyDeveloperOrOperator {
        MAX_GAME_PER_BLOCK = newMaxGamePerBlock;
    }

    //*********************************************
    // Service Interface
    //*********************************************

    event GameError(address player, string message);
    event GameStarted(address player, uint gameId, uint targetBlock);
    event GameEnded(address player, uint wheelResult, uint wonAmount);

    function placeBet(bytes32 betTypes, bytes32 first16, bytes32 second16) external payable {
        // check gate guard
        if (shouldGateGuard == true) {
            emit GameError(msg.sender, "Entrance not allowed!");
            revert();
        }

        // check if the received ether is the same as specified in the bets
        uint betAmount = rouletteRules.getTotalBetAmount(first16, second16) * BET_UNIT;
        // if the amount does not match
        if (betAmount == 0 || msg.value != betAmount || msg.value > MAX_BET) {
            emit GameError(msg.sender, "Wrong bet amount!");
            revert();
        }

        // set target block
        // current block number + target delay
        uint targetBlock = block.number + BLOCK_TARGET_DELAY;

        // check if MAX_GAME_PER_BLOCK is reached
        uint historyLength = gameHistory.length;
        if (historyLength > 0) {
            uint counter;
            for (uint i = historyLength - 1; i >= 0; i--) {
                if (gameHistory[i].targetBlock == targetBlock) {
                    counter++;
                    if (counter > MAX_GAME_PER_BLOCK) {
                        emit GameError(msg.sender, "Reached max game per block!");
                        revert();
                    }
                } else break;
            }
        }

        // start a new game
        // init wheelResult with number 100
        Game memory newGame = Game(uint8(GameStatus.PENDING), 100, msg.sender, targetBlock, betTypes, first16, second16);
        uint gameId = gameHistory.push(newGame) - 1;
        emit GameStarted(msg.sender, gameId, targetBlock);
    }

    function resolveBet(uint gameId) external {
        // get game from history
        Game storage game = gameHistory[gameId];

        // should not proceed if game status is not PENDING
        if (game.status != uint(GameStatus.PENDING)) {
            emit GameError(game.player, "Game is not pending!");
            revert();
        }

        // see if current block is early/late enough to get the block hash
        // if it&#39;s too early to resolve bet
        if (block.number <= game.targetBlock) {
            emit GameError(game.player, "Too early to resolve bet!");
            revert();
        }
        // if it&#39;s too late to retrieve the block hash
        if (block.number - game.targetBlock > MAXIMUM_DISTANCE_FROM_BLOCK_TARGET_DELAY) {
            // mark game status as rejected
            game.status = uint8(GameStatus.REJECTED);
            emit GameError(game.player, "Too late to resolve bet!");
            revert();
        }

        // get hash of set target block
        bytes32 blockHash = blockhash(game.targetBlock);
        // double check that the queried hash is not zero
        if (blockHash == 0) {
            // mark game status as rejected
            game.status = uint8(GameStatus.REJECTED);
            emit GameError(game.player, "blockhash() returned zero!");
            revert();
        }

        // generate random number of 0~36
        // blockhash of target block, address of game player, address of contract as source of entropy
        game.wheelResult = uint8(keccak256(blockHash, game.player, address(this))) % 37;

        // resolve won amount
        uint wonAmount = rouletteRules.getBetResult(game.betTypes, game.first16, game.second16, game.wheelResult) * BET_UNIT;
        // set status first to prevent possible reentrancy attack within same transaction
        game.status = uint8(GameStatus.RESOLVED);
        // transfer if the amount is bigger than 0
        if (wonAmount > 0) {
            game.player.transfer(wonAmount);
        }
        emit GameEnded(game.player, game.wheelResult, wonAmount);
    }

    //*********************************************
    // Game Interface
    //*********************************************

    Game[] private gameHistory;

    enum GameStatus {
        INITIAL,
        PENDING,
        RESOLVED,
        REJECTED
    }

    struct Game {
        uint8 status;
        uint8 wheelResult;
        address player;
        uint256 targetBlock;
        // one byte specifies one bet type
        bytes32 betTypes;
        // two bytes per bet amount on each type
        bytes32 first16;
        bytes32 second16;
    }

    //*********************************************
    // Query Functions
    //*********************************************

    function queryGameStatus(uint gameId) external view returns(uint8) {
        Game memory game = gameHistory[gameId];
        return uint8(game.status);
    }

    function queryBetUnit() external view returns(uint) {
        return BET_UNIT;
    }

    function queryGameHistory(uint gameId) external view returns(
        address player, uint256 targetBlock, uint8 status, uint8 wheelResult,
        bytes32 betTypes, bytes32 first16, bytes32 second16
    ) {
        Game memory g = gameHistory[gameId];
        player = g.player;
        targetBlock = g.targetBlock;
        status = g.status;
        wheelResult = g.wheelResult;
        betTypes = g.betTypes;
        first16 = g.first16;
        second16 = g.second16;
    }

    function queryGameHistoryLength() external view returns(uint length) {
        return gameHistory.length;
    }
}