pragma solidity ^0.4.18;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) public pure returns(uint);

    function maxBalance() public pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) public pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        view
        returns(int);

    function serverForceGameEnd(
        uint8 gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        returns(int);

    function playerForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        returns(int);
}

contract ConflictResolution is ConflictResolutionInterface {
    uint public constant DICE_RANGE = 100;
    uint public constant HOUSE_EDGE = 150;
    uint public constant HOUSE_EDGE_DIVISOR = 10000;

    uint public constant SERVER_TIMEOUT = 2 days;
    uint public constant PLAYER_TIMEOUT = 1 days;

    uint8 public constant GAME_TYPE_DICE = 1;
    uint public constant MAX_BET_VALUE = 1e16; /// max 0.01 ether bet
    uint public constant MIN_BET_VALUE = 1e13; /// min 0.00001 ether bet

    int public constant NOT_ENDED_FINE = 1e15; /// 0.001 ether

    int public constant MAX_BALANCE = int(MAX_BET_VALUE) * 100 * 5;

    modifier onlyValidBet(uint8 _gameType, uint _betNum, uint _betValue) {
        require(isValidBet(_gameType, _betNum, _betValue));
        _;
    }

    modifier onlyValidBalance(int _balance, uint _gameStake) {
        // safe to cast gameStake as range is fixed
        require(-int(_gameStake) <= _balance && _balance < MAX_BALANCE);
        _;
    }

    /**
     * @dev Check if bet is valid.
     * @param _gameType Game type.
     * @param _betNum Number of bet.
     * @param _betValue Value of bet.
     * @return True if bet is valid false otherwise.
     */
    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) public pure returns(bool) {
        return (
            (_gameType == GAME_TYPE_DICE) &&
            (_betNum > 0 && _betNum < DICE_RANGE) &&
            (MIN_BET_VALUE <= _betValue && _betValue <= MAX_BET_VALUE)
        );
    }

    /**
     * @return Max balance.
     */
    function maxBalance() public pure returns(int) {
        return MAX_BALANCE;
    }

    /**
     * Calculate minimum needed house stake.
     */
    function minHouseStake(uint activeGames) public pure returns(uint) {
        return  MathUtil.min(activeGames, 1) * MAX_BET_VALUE * 400;
    }

    /**
     * @dev Calculates game result and returns new balance.
     * @param _gameType Type of game.
     * @param _betNum Bet number.
     * @param _betValue Value of bet.
     * @param _balance Current balance.
     * @param _serverSeed Server&#39;s seed of current round.
     * @param _playerSeed Player&#39;s seed of current round.
     * @return New game session balance.
     */
    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        view
        onlyValidBet(_gameType, _betNum, _betValue)
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        assert(_serverSeed != 0 && _playerSeed != 0);

        int newBalance =  processDiceBet(_betNum, _betValue, _balance, _serverSeed, _playerSeed);

        // do not allow balance below player stake
        int stake = int(_stake);
        if (newBalance < -stake) {
            newBalance = -stake;
        }

        return newBalance;
    }

    /**
     * @dev Force end of game if player does not respond. Only possible after a time period.
     * to give the player a chance to respond.
     * @param _gameType Game type.
     * @param _betNum Bet number.
     * @param _betValue Bet value.
     * @param _balance Current balance.
     * @param _stake Player stake.
     * @param _endInitiatedTime Time server initiated end.
     * @return New game session balance.
     */
    function serverForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        require(_endInitiatedTime + SERVER_TIMEOUT <= block.timestamp);
        require(isValidBet(_gameType, _betNum, _betValue)
                || (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0));


        // following casts and calculations are safe as ranges are fixed
        // assume player has lost
        int newBalance = _balance - int(_betValue);

        // penalize player as he didn&#39;t end game
        newBalance -= NOT_ENDED_FINE;

        // do not allow balance below player stake
        int stake = int(_stake);
        if (newBalance < -stake) {
            newBalance = -stake;
        }

        return newBalance;
    }

    /**
     * @dev Force end of game if server does not respond. Only possible after a time period
     * to give the server a chance to respond.
     * @param _gameType Game type.
     * @param _betNum Bet number.
     * @param _betValue Value of bet.
     * @param _balance Current balance.
     * @param _endInitiatedTime Time server initiated end.
     * @return New game session balance.
     */
    function playerForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint  _stake,
        uint _endInitiatedTime
    )
        public
        view
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        require(_endInitiatedTime + PLAYER_TIMEOUT <= block.timestamp);
        require(isValidBet(_gameType, _betNum, _betValue) ||
                (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0));

        int profit = 0;
        if (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0) {
            // player cancelled game without playing
            profit = 0;
        } else {
            profit = calculateDiceProfit(_betNum, _betValue);
        }

        // penalize server as it didn&#39;t end game
        profit += NOT_ENDED_FINE;

        return _balance + profit;
    }

    /**
     * @dev Calculate new balance after executing bet.
     * @param _serverSeed Server&#39;s seed
     * @param _playerSeed Player&#39;s seed
     * @param _betNum Bet Number.
     * @param _betValue Value of bet.
     * @param _balance Current balance.
     */
    function processDiceBet(
        uint _betNum,
        uint _betValue,
        int _balance,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        private
        pure
        returns (int)
    {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        // check who has won
        bool playerWon = calculateDiceWinner(_serverSeed, _playerSeed, _betNum);

        if (playerWon) {
            int profit = calculateDiceProfit(_betNum, _betValue);
            return _balance + profit;
        } else {
            return _balance - int(_betValue);
        }
    }

    /**
     * @dev Calculate player profit if player has won.
     * @param _betNum Bet number of player.
     * @param _betValue Value of bet.safe
     * @return Players&#39; profit.
     */
    function calculateDiceProfit(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        // convert to gwei as we use gwei as lowest unit
        uint betValue = _betValue / 1e9;

        // safe without safe math as ranges are fixed
        uint totalWon = betValue * DICE_RANGE / _betNum;
        uint houseEdgeValue = totalWon * HOUSE_EDGE / HOUSE_EDGE_DIVISOR;
        int profit = int(totalWon) - int(houseEdgeValue) - int(betValue);

        // convert back to wei and return
        return profit * 1e9;
    }

    /**
     * @dev Calculate winner of dice game.
     * @param _serverSeed Server seed of bet.
     * @param _playerSeed Player seed of bet.
     * @param _betNum Bet number.
     * @return True if player has won false if he lost.
     */
    function calculateDiceWinner(
        bytes32 _serverSeed,
        bytes32 _playerSeed,
        uint _betNum
    )
        private
        pure
        returns(bool)
    {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        bytes32 combinedHash = keccak256(_serverSeed, _playerSeed);
        uint randomNumber = uint(combinedHash) % DICE_RANGE; // bias is negligible
        return randomNumber < _betNum;
    }
}

library MathUtil {
    /**
     * @dev Returns the absolute value of _val.
     * @param _val value
     * @return The absolute value of _val.
     */
    function abs(int _val) internal pure returns(uint) {
        if (_val < 0) {
            return uint(-_val);
        } else {
            return uint(_val);
        }
    }

    /**
     * @dev Calculate maximum.
     */
    function max(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 >= _val2 ? _val1 : _val2;
    }

    /**
     * @dev Calculate minimum.
     */
    function min(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 <= _val2 ? _val1 : _val2;
    }
}