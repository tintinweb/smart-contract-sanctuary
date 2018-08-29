pragma solidity ^0.4.24;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) external pure returns(uint);

    function maxBalance() external pure returns(int);

    function conflictEndFine() external pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) external pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _userSeed
    )
        external
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
        external
        view
        returns(int);

    function userForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        external
        view
        returns(int);
}

contract ConflictResolution is ConflictResolutionInterface {
    using SafeCast for int;
    using SafeCast for uint;
    using SafeMath for int;
    using SafeMath for uint;

    uint public constant DICE_RANGE = 100;
    uint public constant HOUSE_EDGE = 150;
    uint public constant HOUSE_EDGE_DIVISOR = 10000;

    uint public constant SERVER_TIMEOUT = 6 hours;
    uint public constant USER_TIMEOUT = 6 hours;

    uint8 public constant DICE_LOWER = 1; ///< @dev dice game lower number wins
    uint8 public constant DICE_HIGHER = 2; ///< @dev dice game higher number wins

    uint public constant MAX_BET_VALUE = 2e16; /// max 0.02 ether bet
    uint public constant MIN_BET_VALUE = 1e13; /// min 0.00001 ether bet
    uint public constant MIN_BANKROLL = 15e18;

    int public constant NOT_ENDED_FINE = 1e15; /// 0.001 ether

    int public constant CONFLICT_END_FINE = 1e15; /// 0.001 ether

    uint public constant PROBABILITY_DIVISOR = 10000;

    int public constant MAX_BALANCE = int(MIN_BANKROLL / 2);

    modifier onlyValidBet(uint8 _gameType, uint _betNum, uint _betValue) {
        require(isValidBet(_gameType, _betNum, _betValue), "inv bet");
        _;
    }

    modifier onlyValidBalance(int _balance, uint _gameStake) {
        require(-_gameStake.castToInt() <= _balance && _balance <= MAX_BALANCE, "inv balance");
        _;
    }

    /**
     * @dev Calc max bet we allow
     * We definitely do not allow bets greater than kelly criterion would allow.
     * The max bet is further restricted on backend.
     * Calculation: e: houseEdge, q Probability for house to win, p probability for user to win, b bankroll.
     * f = e / (1/q * (e+1) - 1)
     * => f =  e / ((1/(1-p) * (e+1) - 1)
     * => maxBet = f * (1/(1-p) - 1) (ignoring houseEdge factor (e + 1)) * b
     * => maxBet = e / ((1/(1-p) * (e+1) - 1) * (1/(1-p) - 1) * b
     * => maxBet = e * p / (e+p) * b
     *
     * @param _winProbability winProbability.
     * @return max allowed bet.
     */
    function maxBet(uint _winProbability) public pure returns(uint) {
        assert(0 < _winProbability && _winProbability < PROBABILITY_DIVISOR);

        uint enumerator = HOUSE_EDGE.mul(_winProbability).mul(MIN_BANKROLL);
        uint denominator = HOUSE_EDGE.mul(PROBABILITY_DIVISOR).add(_winProbability.mul(HOUSE_EDGE_DIVISOR));

        return enumerator.div(denominator).add(5e15).div(1e16).mul(1e16); // round to multiple of 0.01 Ether
    }

    /**
     * @dev Check if bet is valid.
     * @param _gameType Game type.
     * @param _betNum Number of bet.
     * @param _betValue Value of bet.
     * @return True if bet is valid false otherwise.
     */
    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) public pure returns(bool) {
        bool validMinBetValue = MIN_BET_VALUE <= _betValue;
        bool validGame = false;

        if (_gameType == DICE_LOWER) {
            validGame = _betNum > 0 && _betNum < DICE_RANGE - 1;
            validGame = validGame && _betValue <= maxBet(_betNum * PROBABILITY_DIVISOR / DICE_RANGE);
        } else if (_gameType == DICE_HIGHER) {
            validGame = _betNum > 0 && _betNum < DICE_RANGE - 1;
            validGame = validGame && _betValue <= maxBet((DICE_RANGE - _betNum - 1) * PROBABILITY_DIVISOR / DICE_RANGE);
        } else {
            validGame = false;
        }

        return validMinBetValue && validGame;
    }

    /**
     * @return Conflict end fine.
     */
    function conflictEndFine() public pure returns(int) {
        return CONFLICT_END_FINE;
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
        return  MathUtil.min(activeGames, 1) * MIN_BANKROLL;
    }

    /**
     * @dev Calculates game result and returns new balance.
     * @param _gameType Type of game.
     * @param _betNum Bet number.
     * @param _betValue Value of bet.
     * @param _balance Current balance.
     * @param _serverSeed Server&#39;s seed of current round.
     * @param _userSeed User&#39;s seed of current round.
     * @return New game session balance.
     */
    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _userSeed
    )
        public
        view
        onlyValidBet(_gameType, _betNum, _betValue)
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        require(_serverSeed != 0 && _userSeed != 0, "inv seeds");

        int newBalance =  processBet(_gameType, _betNum, _betValue, _balance, _serverSeed, _userSeed);

        // user need to pay a fee when conflict ended.
        // this ensures a malicious, rich user can not just generate game sessions and then wait
        // for us to end the game session and then confirm the session status, so
        // we would have to pay a high gas fee without profit.
        newBalance = newBalance.sub(CONFLICT_END_FINE);

        // do not allow balance below user stake
        int stake = _stake.castToInt();
        if (newBalance < -stake) {
            newBalance = -stake;
        }

        return newBalance;
    }

    /**
     * @dev Force end of game if user does not respond. Only possible after a time period.
     * to give the user a chance to respond.
     * @param _gameType Game type.
     * @param _betNum Bet number.
     * @param _betValue Bet value.
     * @param _balance Current balance.
     * @param _stake User stake.
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
        require(_endInitiatedTime + SERVER_TIMEOUT <= block.timestamp, "too low timeout");
        require(isValidBet(_gameType, _betNum, _betValue)
                || (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0), "inv bet");


        // assume user has lost
        int newBalance = _balance.sub(_betValue.castToInt());

        // penalize user as he didn&#39;t end game
        newBalance = newBalance.sub(NOT_ENDED_FINE);

        // do not allow balance below user stake
        int stake = _stake.castToInt();
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
    function userForceGameEnd(
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
        require(_endInitiatedTime + USER_TIMEOUT <= block.timestamp, "too low timeout");
        require(isValidBet(_gameType, _betNum, _betValue)
            || (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0), "inv bet");

        int profit = 0;
        if (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0) {
            // user cancelled game without playing
            profit = 0;
        } else {
            profit = calculateProfit(_gameType, _betNum, _betValue); // safe to cast as ranges are limited
        }

        // penalize server as it didn&#39;t end game
        profit = profit.add(NOT_ENDED_FINE);

        return _balance.add(profit);
    }

    /**
     * @dev Calculate new balance after executing bet.
     * @param _gameType game type.
     * @param _betNum Bet Number.
     * @param _betValue Value of bet.
     * @param _balance Current balance.
     * @param _serverSeed Server&#39;s seed
     * @param _userSeed User&#39;s seed
     * return new balance.
     */
    function processBet(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        bytes32 _serverSeed,
        bytes32 _userSeed
    )
        public
        pure
        returns (int)
    {
        bool won = hasUserWon(_gameType, _betNum, _serverSeed, _userSeed);
        if (!won) {
            return _balance.sub(_betValue.castToInt());
        } else {
            int profit = calculateProfit(_gameType, _betNum, _betValue);
            return _balance.add(profit);
        }
    }

    /**
     * @dev Calculate user profit.
     * @param _gameType type of game.
     * @param _betNum bet numbe.
     * @param _betValue bet value.
     * return profit of user
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
        return res.mul(1e9); // convert to wei
    }

    /**
     * Calculate user profit from total won.
     * @param _totalWon user winning in gwei.
     * @return user profit in gwei.
     */
    function calcProfitFromTotalWon(uint _totalWon, uint _betValue) private pure returns(int) {
        uint houseEdgeValue = _totalWon.mul(HOUSE_EDGE).div(HOUSE_EDGE_DIVISOR);

        return _totalWon.castToInt().sub(houseEdgeValue.castToInt()).sub(_betValue.castToInt());
    }

    /**
     * @dev Calculate user profit if user has won for game type 1 (dice lower wins).
     * @param _betNum Bet number of user.
     * @param _betValue Value of bet in gwei.
     * @return Users&#39; profit.
     */
    function calculateProfitGameType1(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        uint totalWon = _betValue.mul(DICE_RANGE).div(_betNum);
        return calcProfitFromTotalWon(totalWon, _betValue);
    }

    /**
     * @dev Calculate user profit if user has won for game type 2 (dice lower wins).
     * @param _betNum Bet number of user.
     * @param _betValue Value of bet in gwei.
     * @return Users&#39; profit.
     */
    function calculateProfitGameType2(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum >= 0 && _betNum < DICE_RANGE - 1);

        // safe as ranges are fixed
        uint totalWon = _betValue.mul(DICE_RANGE).div(DICE_RANGE.sub(_betNum).sub(1));
        return calcProfitFromTotalWon(totalWon, _betValue);
    }

    /**
     * @dev Check if user hash won or lost.
     * @return true if user has won.
     */
    function hasUserWon(
        uint8 _gameType,
        uint _betNum,
        bytes32 _serverSeed,
        bytes32 _userSeed
    )
        public
        pure
        returns(bool)
    {
        bytes32 combinedHash = keccak256(abi.encodePacked(_serverSeed, _userSeed));
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
     * @return True if user has won false if he lost.
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
     * @return True if user has won false if he lost.
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

library SafeCast {
    /**
     * Cast unsigned a to signed a.
     */
    function castToInt(uint a) internal pure returns(int) {
        assert(a < (1 << 255));
        return int(a);
    }

    /**
     * Cast signed a to unsigned a.
     */
    function castToUint(int a) internal pure returns(uint) {
        assert(a >= 0);
        return uint(a);
    }
}

library SafeMath {

    /**
    * @dev Multiplies two unsigned integers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Multiplies two signed integers, throws on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        int256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Integer division of two signed integers, truncating the quotient.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // Overflow only happens when the smallest negative int is multiplied by -1.
        int256 INT256_MIN = int256((uint256(1) << 255));
        assert(a != INT256_MIN || b != - 1);
        return a / b;
    }

    /**
    * @dev Subtracts two unsigned integers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Subtracts two signed integers, throws on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        assert((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
    * @dev Adds two unsigned integers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev Adds two signed integers, throws on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        assert((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
}