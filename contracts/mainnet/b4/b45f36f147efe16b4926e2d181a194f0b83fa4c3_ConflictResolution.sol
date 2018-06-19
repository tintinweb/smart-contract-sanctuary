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

    uint public constant SERVER_TIMEOUT = 6 hours;
    uint public constant PLAYER_TIMEOUT = 6 hours;

    uint8 public constant DICE_LOWER = 1; ///< @dev dice game lower number wins
    uint8 public constant DICE_HIGHER = 2; ///< @dev dice game higher number wins

    uint public constant MAX_BET_VALUE = 2e16; /// max 0.02 ether bet
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
        bool validValue = MIN_BET_VALUE <= _betValue && _betValue <= MAX_BET_VALUE;
        bool validGame = false;

        if (_gameType == DICE_LOWER) {
            validGame = _betNum > 0 && _betNum < DICE_RANGE - 1;
        } else if (_gameType == DICE_HIGHER) {
            validGame = _betNum > 0 && _betNum < DICE_RANGE - 1;
        } else {
            validGame = false;
        }

        return validValue && validGame;
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

        int newBalance =  processBet(_gameType, _betNum, _betValue, _balance, _serverSeed, _playerSeed);

        // do not allow balance below player stake
        int stake = int(_stake); // safe to cast as stake range is fixed
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
        int stake = int(_stake); // safe to cast as stake range is fixed
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
            profit = int(calculateProfit(_gameType, _betNum, _betValue)); // safe to cast as ranges are limited
        }

        // penalize server as it didn&#39;t end game
        profit += NOT_ENDED_FINE;

        return _balance + profit;
    }

    /**
     * @dev Calculate new balance after executing bet.
     * @param _gameType game type.
     * @param _betNum Bet Number.
     * @param _betValue Value of bet.
     * @param _balance Current balance.
     * @param _serverSeed Server&#39;s seed
     * @param _playerSeed Player&#39;s seed
     * return new balance.
     */
    function processBet(
        uint8 _gameType,
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
        bool won = hasPlayerWon(_gameType, _betNum, _serverSeed, _playerSeed);
        if (!won) {
            return _balance - int(_betValue); // safe to cast as ranges are fixed
        } else {
            int profit = calculateProfit(_gameType, _betNum, _betValue);
            return _balance + profit;
        }
    }

    /**
     * @dev Calculate player profit.
     * @param _gameType type of game.
     * @param _betNum bet numbe.
     * @param _betValue bet value.
     * return profit of player
     */
    function calculateProfit(uint8 _gameType, uint _betNum, uint _betValue) private pure returns(int) {
        uint betValueInGwei = _betValue / 1e9; // convert to gwei
        int res = 0;

        if (_gameType == DICE_LOWER) {
            res = calculateProfitGameType1(_betNum, betValueInGwei);
        } else if (_gameType == DICE_HIGHER) {
            res = calculateProfitGameType2(_betNum, betValueInGwei);
        } else {
            assert(false);
        }
        return res * 1e9; // convert to wei
    }

    /**
     * Calculate player profit from total won.
     * @param _totalWon player winning in gwei.
     * @return player profit in gwei.
     */
    function calcProfitFromTotalWon(uint _totalWon, uint _betValue) private pure returns(int) {
        // safe to multiply as _totalWon range is fixed.
        uint houseEdgeValue = _totalWon * HOUSE_EDGE / HOUSE_EDGE_DIVISOR;

        // safe to cast as all value ranges are fixed
        return int(_totalWon) - int(houseEdgeValue) - int(_betValue);
    }

    /**
     * @dev Calculate player profit if player has won for game type 1 (dice lower wins).
     * @param _betNum Bet number of player.
     * @param _betValue Value of bet in gwei.
     * @return Players&#39; profit.
     */
    function calculateProfitGameType1(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        // safe as ranges are fixed
        uint totalWon = _betValue * DICE_RANGE / _betNum;
        return calcProfitFromTotalWon(totalWon, _betValue);
    }

    /**
     * @dev Calculate player profit if player has won for game type 2 (dice lower wins).
     * @param _betNum Bet number of player.
     * @param _betValue Value of bet in gwei.
     * @return Players&#39; profit.
     */
    function calculateProfitGameType2(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum >= 0 && _betNum < DICE_RANGE - 1);

        // safe as ranges are fixed
        uint totalWon = _betValue * DICE_RANGE / (DICE_RANGE - _betNum - 1);
        return calcProfitFromTotalWon(totalWon, _betValue);
    }

    /**
     * @dev Check if player hash won or lost.
     * @return true if player has won.
     */
    function hasPlayerWon(
        uint8 _gameType,
        uint _betNum,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        private
        pure
        returns(bool)
    {
        bytes32 combinedHash = keccak256(_serverSeed, _playerSeed);
        uint randNum = uint(combinedHash);

        if (_gameType == 1) {
            return calculateWinnerGameType1(randNum, _betNum);
        } else if (_gameType == 2) {
            return calculateWinnerGameType2(randNum, _betNum);
        } else {
            assert(false);
        }
    }

    /**
     * @dev Calculate winner of game type 1 (roll lower).
     * @param _randomNum 256 bit random number.
     * @param _betNum Bet number.
     * @return True if player has won false if he lost.
     */
    function calculateWinnerGameType1(uint _randomNum, uint _betNum) private pure returns(bool) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        uint resultNum = _randomNum % DICE_RANGE; // bias is negligible
        return resultNum < _betNum;
    }

    /**
     * @dev Calculate winner of game type 2 (roll higher).
     * @param _randomNum 256 bit random number.
     * @param _betNum Bet number.
     * @return True if player has won false if he lost.
     */
    function calculateWinnerGameType2(uint _randomNum, uint _betNum) private pure returns(bool) {
        assert(_betNum >= 0 && _betNum < DICE_RANGE - 1);

        uint resultNum = _randomNum % DICE_RANGE; // bias is negligible
        return resultNum > _betNum;
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