// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED



pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import '../interfaces/IRates.sol';
import '../utils/Governed.sol';
import '../utils/Time.sol';
import '../../library/SignedSafeMath.sol';
import '../../library/Math.sol';
import '../utils/CoinSafeCast.sol';
import '../utils/CoinSafeMath.sol';
import '../utils/SafeMath64.sol';

contract Rates is IRates, Governed, Time {
    using Math for uint64;
    using SafeMath64 for uint64;
    using Math for uint256;
    using CoinSafeMath for uint128;
    using CoinSafeMath for uint256;
    using SignedSafeMath for int256;
    using CoinSafeCast for uint256;



    uint128 public validRangeForRawPrices = 0.2e18;

    uint64 public minTimeBetweenUpdates = 690 minutes;


    uint64 public maxPriceAge = 3 hours;

    struct InterestRateParameters {
        uint128 acceptableError;
        uint128 errorInterval;
        uint128 interestRateStep;
        uint64 maxSteps;
        int128 minRate;
        int128 maxRate;
    }

    InterestRateParameters public interestRateParameters;

    struct RateData {
        int rate;
        uint64 stepsOff;
        uint64 nextUpdateTime;
        uint128 rewardCount;
    }


    RateData public currentRateData;


    IUniswapV2Pair[] public pair;

    IUniswapV2Pair public collateralPair;

    function _initHook() internal override {
        interestRateParameters = InterestRateParameters({
            acceptableError: 0.001e18,
            errorInterval: 0.005e18,
            interestRateStep: 0.005e18,
            maxSteps: 5,
            minRate: -0.1e18,
            maxRate: 0.5e18
        });

        currentRateData = RateData({
            rate: 0.03e18,
            stepsOff: 0,
            nextUpdateTime: _currentTime().add(minTimeBetweenUpdates),
            rewardCount: 10000e18
        });

        bytes4[9] memory validUpdates = [
            this.setValidRangeForRawPrices.selector,
            this.setAcceptableError.selector,
            this.setErrorInterval.selector,
            this.setInterestRateStep.selector,
            this.setMinTimeBetweenUpdates.selector,
            this.setMaxSteps.selector,
            this.setMaxPriceAge.selector,
            this.setMinRate.selector,
            this.setMaxRate.selector];

        for(uint i = 0; i < validUpdates.length; i++) _validUpdate[validUpdates[i]] = true;
    }

    bool private setupComplete;

    function completeSetup() external override onlyGovernor {
        require(!setupComplete);
        setupComplete = true;

        pair = governor.getReferencePairs();
        collateralPair = governor.collateralPair();
    }

    function update() external lockProtocol runnable {
        require(currentRateData.nextUpdateTime <= _currentTime(), 'PegManager/update: Update not ready.');

        IPrices prices = governor.prices();
        uint64 _maxPriceAge = maxPriceAge;


        (uint price0,,) = prices.systemObtainReferencePrice(pair[0], type(uint64).max, _maxPriceAge, true);
        (uint price1,,) = prices.systemObtainReferencePrice(pair[1], type(uint64).max, _maxPriceAge, true);
        (uint price2,,) = prices.systemObtainReferencePrice(pair[2], type(uint64).max, _maxPriceAge, true);


        prices.systemObtainCollateralPrice(0, 0, false);


        uint price = _calculatePriceImpl(price0, price1, price2, validRangeForRawPrices);

        RateData memory newRateData = _calculateRates(currentRateData, interestRateParameters, price);


        newRateData.rewardCount = getRewardCount().toUint128();
        newRateData.nextUpdateTime = _futureTime(minTimeBetweenUpdates);


        currentRateData = newRateData;


        governor.mintCNP(msg.sender, newRateData.rewardCount);

        emit RateUpdated(newRateData.rate, price, newRateData.rewardCount, newRateData.nextUpdateTime);
    }

    function currentPredictedInterestRateUpdate() external view returns (
        uint price,
        RateData memory predictedRateData
    ) {
        IPrices prices = governor.prices();


        (uint price0) = prices.viewCurrentTwappedPrice(pair[0], true);
        (uint price1) = prices.viewCurrentTwappedPrice(pair[1], true);
        (uint price2) = prices.viewCurrentTwappedPrice(pair[2], true);

        price = _calculatePriceImpl(price0, price1, price2, validRangeForRawPrices);
        predictedRateData = _calculateRates(currentRateData, interestRateParameters, price);
    }

    function getRewardCount() public view returns (uint newRewardCount) {

        uint64 time = _currentTime();
        uint64 nextUpdateTime = currentRateData.nextUpdateTime;
        if (time < nextUpdateTime) return 0;

        uint rewardCount = currentRateData.rewardCount;
        uint halfReward = rewardCount / 2;




        newRewardCount = halfReward + halfReward.mulDiv(time - nextUpdateTime, 30 minutes);

        newRewardCount = newRewardCount.min(rewardCount.mul(10));
    }


    function maxSteps() external view override returns (uint64) {
        return interestRateParameters.maxSteps;
    }


    function positiveInterestRate() external view override returns (bool) {
        return currentRateData.rate > 0;
    }


    function interestRateAbsoluteValue() external view override returns (uint) {
        int rate = currentRateData.rate;
        return uint(rate < 0 ? -rate : rate);
    }


    function stepsOff() external view override returns (uint64) {
        return currentRateData.stepsOff;
    }

    function _calculatePriceImpl(
        uint price0,
        uint price1,
        uint price2,
        uint _validRangeForRawPrices
    ) internal pure returns (uint) {

        uint minPrice = CoinSafeMath.ONE.sub(_validRangeForRawPrices);
        uint maxPrice = CoinSafeMath.ONE.add(_validRangeForRawPrices);

        bool price0valid;
        bool price1valid;
        bool price2valid;
        uint countValidPrices;


        if (minPrice < price0 && price0 < maxPrice) {
            price0valid = true;
            countValidPrices++;
        }
        if (minPrice < price1 && price1 < maxPrice) {
            price1valid = true;
            countValidPrices++;
        }
        if (minPrice < price2 && price2 < maxPrice) {
            price2valid = true;
            countValidPrices++;
        }

        if (countValidPrices == 3 || countValidPrices == 0) {


            if (price0 > price1) (price0, price1) = (price1, price0);
            if (price1 > price2) (price1, price2) = (price2, price1);
            if (price0 > price1) (price0, price1) = (price1, price0);
            return price1;
        } else if (countValidPrices == 2) {

            if (!price0valid) return price1.average(price2);
            if (!price1valid) return price0.average(price2);
            if (!price2valid) return price0.average(price1);
        } else if (countValidPrices == 1) {

            if (price0valid) return price0;
            if (price1valid) return price1;
            if (price2valid) return price2;
        }


        revert('Calculate price error.');
    }

    function _calculateRates(
        RateData memory _currentRateData,
        InterestRateParameters memory rp,
        uint price
    ) internal pure returns (RateData memory newRateData) {
        newRateData = _currentRateData;



        bool tooLow = price > CoinSafeMath.ONE;
        uint error = tooLow ? price - CoinSafeMath.ONE : CoinSafeMath.ONE - price;


        if (error < rp.acceptableError) {
            newRateData.stepsOff = 0;
        } else {

            newRateData.stepsOff = (rp.maxSteps.min((error / rp.errorInterval) + 1)).toUint64();


            int adjustmentAmount = rp.interestRateStep.mul(newRateData.stepsOff).toInt256();


            newRateData.rate = tooLow
                ? newRateData.rate.add(adjustmentAmount)
                : newRateData.rate.sub(adjustmentAmount);
        }


        if (newRateData.rate < rp.minRate) newRateData.rate = rp.minRate;
        if (newRateData.rate > rp.maxRate) newRateData.rate = rp.maxRate;
    }


    function testContractLock() external lockContract {
        testContractLock2();
    }


    function testContractLock2() public lockContract {}


    function testProtocolLock() external lockProtocol {
        testProtocolLock2();
    }


    function testProtocolLock2() public lockProtocol {}

    function setAcceptableError(uint128 error) external onlyGovernor {
        require(error < CoinSafeMath.ONE, 'Invalid value');
        interestRateParameters.acceptableError = error;
        emit ParameterUpdated128('acceptableError', error);
    }

    function setErrorInterval(uint128 interval) external onlyGovernor {
        require(0 < interval && interval < CoinSafeMath.ONE, 'Invalid value');
        interestRateParameters.errorInterval = interval;
        emit ParameterUpdated128('errorInterval', interval);
    }

    function setInterestRateStep(uint128 step) external override onlyGovernor {
        require(step < CoinSafeMath.ONE, 'Invalid value');
        interestRateParameters.interestRateStep = step;
        emit ParameterUpdated128('interestRateStep', step);
    }

    function setMaxSteps(uint64 steps) external onlyGovernor {
        interestRateParameters.maxSteps = steps;
        emit ParameterUpdated64('maxSteps', steps);
    }


    function setMinRate(int128 min) external onlyGovernor {
        interestRateParameters.minRate = min;
        emit ParameterUpdatedInt128('minRate', min);
    }

    function setMaxRate(int128 max) external onlyGovernor {
        interestRateParameters.maxRate = max;
        emit ParameterUpdatedInt128('maxRate', max);
    }

    function setValidRangeForRawPrices(uint128 range) external onlyGovernor {
        validRangeForRawPrices = range;
        require(validRangeForRawPrices < CoinSafeMath.ONE, 'Invalid value');
        emit ParameterUpdated128('validRangeForRawPrices', range);
    }


    function setMinTimeBetweenUpdates(uint64 time) external onlyGovernor {
        minTimeBetweenUpdates = time;
        require(minTimeBetweenUpdates > 0, 'Invalid value');
        emit ParameterUpdated64('minTimeBetweenUpdates', time);
    }

    function setMaxPriceAge(uint64 age) external onlyGovernor {
        maxPriceAge = age;
        require(90 minutes < maxPriceAge, 'Invalid value');
        emit ParameterUpdated64('maxPriceAge', age);
    }

    function stop() external override onlyGovernor {
        _stopImpl();
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


interface IRates {
    function positiveInterestRate() external view returns (bool);
    function interestRateAbsoluteValue() external view returns (uint);
    function stepsOff() external view returns (uint64);
    function maxSteps() external view returns (uint64);

    function setInterestRateStep(uint128 step) external;
    function completeSetup() external;
    function stop() external;

    event RateUpdated(int interestRate, uint price, uint rewardCount, uint64 nextUpdateTime);
    event ParameterUpdated64(string indexed paramName, uint64 value);
    event ParameterUpdated128(string indexed paramName, uint128 value);
    event ParameterUpdatedInt128(string indexed paramName, int128 value);
}

interface AccruesInterest {
    function accrueInterest() external;
}

// Copyright (c) 2020. All Rights Reserved
// adapted from OpenZeppelin v3.1.0 Ownable.sol
// SPDX-License-Identifier: UNLICENSED




pragma solidity =0.7.4;

import '../interfaces/IGovernor.sol';
import './DelayedStart.sol';


abstract contract Governed is DelayedStart {


    IGovernor public governor;

    bool public stopped;

    address public deployer;


    IAccounting internal accounting;

    ICoin internal coin;

    IProtocolLock internal protocolLock;

    event Initialized(address indexed governor);
    event Stopped();

    constructor () {
        deployer = msg.sender;
    }

    function init(IGovernor _governor) external {
        require(msg.sender == deployer, 'Governed: Init not authorized.');
        delete deployer;

        governor = _governor;

        accounting = governor.accounting();
        coin = governor.coin();
        protocolLock = governor.protocolLock();

        _initHook();

        emit Initialized(address(_governor));
    }

    function _initHook() internal virtual { }

    function _stopImpl() internal {
        stopped = true;
        emit Stopped();
    }

    mapping(bytes4 => bool) internal _validUpdate;

    function validUpdate(bytes4 action) external view returns (bool) {
        return _validUpdate[action];
    }

    modifier onlyGovernor() {
        require(msg.sender == address(governor), 'Governed: Not Authorized.');
        _;
    }

    modifier runnable() {
        require(START_TIME < block.timestamp || msg.sender == governor.protocolDeployer(),
            'Governed: Protocol has not started.');
        require(!stopped, 'Governed: Contract is stopped.');
        require(!governor.isShutdown(), 'Governed: Not available during shutdown.');
        _;
    }

    modifier notStopped() {
        require(!stopped, 'Governed: Contract is stopped.');
        _;
    }

    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;
    uint private _status = _NOT_ENTERED;

    modifier lockContract() {
        require(_status != _ENTERED, 'LockContract: Reentrant call.');
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }


    modifier lockProtocol() {
        protocolLock.enter();

        require(_status != _ENTERED, 'LockContract: Reentrant call.');
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;

        protocolLock.exit();
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED



pragma solidity =0.7.4;

import './CoinSafeCast.sol';
import './SafeMath64.sol';
import './DelayedStart.sol';


abstract contract Time {
    using SafeMath64 for uint64;
    using CoinSafeCast for uint256;


    function _currentTime() internal view returns (uint64 time) {
        time = block.timestamp.toUint64();
    }


    function _futureTime(uint64 addition) internal view returns (uint64 time) {
        time = _currentTime().add(addition);
    }
}

abstract contract PeriodTime is Time, DelayedStart {
    using SafeMath64 for uint64;


    uint64 public immutable periodLength;

    uint64 public immutable firstPeriod;


    constructor (uint64 _periodLength) {
        firstPeriod = (START_TIME / _periodLength) - 1;
        periodLength = _periodLength;
    }

    function currentPeriod() external view returns (uint64 period) {
        period = _currentPeriod();
    }


    function _currentPeriod() internal view returns (uint64 period) {
        uint64 time = _currentTime();

        period = time < START_TIME
            ? 1
            : (time / periodLength) - firstPeriod;
    }

    function _periodToTime(uint64 period) internal view returns (uint64 time) {
        time = periodLength.mul(firstPeriod.add(period));
    }

    function _timeToPeriod(uint64 time) internal view returns (uint64 period) {
        period = time < START_TIME
            ? 1
            : (time / periodLength).sub(firstPeriod);
    }
}

// SPDX-License-Identifier: MIT
// one modification: updated compile target to 0.7.0

pragma solidity =0.7.4;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

        /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.1.0
// updated compile target
// Added square root method from Uniswap.

pragma solidity =0.7.4;


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// NOTE: modified compiler version to 0.7.4 and added toUint192, toUint160, and toUint96

pragma solidity =0.7.4;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library CoinSafeCast {
    // =======================================
    // ============= UNSIGNED ================
    // =======================================
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value < 2**224, "SafeCast: value doesn\'t fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value < 2**192, "SafeCast: value doesn\'t fit in 192 bits");
        return uint192(value);
    }
    
    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value < 2**160, "SafeCast: value doesn\'t fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value < 2**112, "SafeCast: value doesn\'t fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "SafeCast: value doesn\'t fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    // =====================================
    // ============= SIGNED ================
    // =====================================
    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    // =================================================
    // ============= SIGNED <> UNSIGNED ================
    // =================================================
    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }


    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.1.0
// modification: updated compile target to 0.7.4, added three of my own scaled functions at end.




pragma solidity =0.7.4;

library CoinSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }


    uint256 public constant ONE = 1e18;

    function _div(uint256 a, uint256 b) internal pure returns (uint256 r) {
        if (a == 0) return 0;
        require(b != 0, 'SafeMath: division by zero');
        r = a * ONE;
        require(r / a == ONE, 'SafeMath: multiplication overflow');
        r = r / b;
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
        if (a == 0 || b == 0) return 0;
        r = a * b;
        require(r / a == b, 'SafeMath: multiplication overflow');
        r = r / ONE;
    }

    function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 r) {
        if (a == 0 || b == 0) return 0;
        require(c != 0, 'SafeMath: division by zero');
        r = a * b;
        require(r / a == b, 'SafeMath: multiplication overflow');
        r = r / c;
    }
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.2.0
// === updated compile target, and changed all uint256 to uint64

pragma solidity =0.7.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath64 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b <= a, errorMessage);
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint64 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b > 0, errorMessage);
        uint64 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


import './IAccounting.sol';
import './IAuctions.sol';
import './ICNP.sol';
import './ICoin.sol';
import './ICoinPositionNFT.sol';
import './IEnforcedDecentralization.sol';
import './ILendCoin.sol';
import './ILiquidations.sol';
import './IMarket.sol';
import './IPrices.sol';
import './IProtocolLock.sol';
import './IRates.sol';
import './IRewards.sol';
import './ISettlement.sol';
import './ITokenAllocations.sol';

import '../../library/interfaces/IERC20.sol';


interface IGovernor {
    function isShutdown() external view returns (bool);
    function shutdownTime() external view returns (uint64);
    function currentDailyRewardCount() external view returns (uint count);
    function distributedCNP() external view returns (uint circulating);
    function protocolDeployer() external view returns (address);

    function protocolPair() external view returns(IUniswapV2Pair);
    function collateralPair() external view returns(IUniswapV2Pair);
    function getReferencePairs() external view returns(IUniswapV2Pair[] memory);

    function accounting() external view returns (IAccounting);
    function auctions() external view returns (IAuctions);
    function cnp() external view returns (ICNP);
    function coin() external view returns (ICoin);
    function coinPositionNFT() external view returns (ICoinPositionNFT);
    function enforcedDecentralization() external view returns (IEnforcedDecentralization);
    function lendCoin() external view returns (ILendCoin);
    function liquidations() external view returns (ILiquidations);
    function market() external view returns (IMarket);
    function prices() external view returns (IPrices);
    function protocolLock() external view returns (IProtocolLock);
    function rates() external view returns (IRates);
    function rewards() external view returns (IRewards);
    function settlement() external view returns (ISettlement);
    function timelock() external view returns (address);
    function tokenAllocations() external view returns (ITokenAllocations);

    function requireDebtWriteAccess(address caller) external view;
    function requirePositionWriteAccess(address caller) external view;
    function requirePairTokenWriteAccess(address caller) external view;
    function requireCoinReservesBurnAccess(address caller) external view;
    function requireStoredCollateralAccess(address caller) external view;
    function requirePriceAccess(address caller) external view;

    function execute(
        address target,
        string memory signature,
        bytes memory data
    ) external returns (bool success, bytes memory returnData);
    function executeShutdown() external;
    function upgradeProtocol(address newGovernor) external;

    function mintCNP(address to, uint count) external;
    function distributeLiquidityRewards(address to, uint count) external;

    function upgradeAuctions(IAuctions _auctions) external;
    function upgradeLiquidations(ILiquidations _liquidations) external;
    function upgradeMarket(IMarket _market) external;
    function upgradePrices(IPrices _prices) external;
    function upgradeRates(IRates _rates) external;
    function upgradeRewards(IRewards _rewards) external;
    function upgradeSettlement(ISettlement _settlement) external;

    event AdminUpdated(address indexed from, address indexed to);
    event AllocationAllotted(address indexed allocation, uint allotment);
    event ContractUpgraded(string indexed contractName, address indexed contractAddress);
    event ShutdownTokensLocked(address indexed locker, uint count);
    event ShutdownTokensUnlocked(address indexed locker, uint count);
    event EmergencyShutdownExecuted(uint emergencyShutdownTokensBurned, uint64 shutdownTime);
    event ShutdownExecuted();
    event ProtocolUpgraded(address indexed newGovernor);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;

abstract contract DelayedStart {
    uint64 constant public START_TIME = 1614315471;
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED




pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import '../../library/interfaces/IUniswapV2Pair.sol';
import './IGovernor.sol';


interface IAccounting {

    function getLiquidationAccount() external view returns (LiquidationAccount memory lqAcct);
    function setLiquidationAccount(LiquidationAccount memory lqAcct) external;
    function getBasicPositionInfo(uint64 positionID) external view returns (uint debtCount, uint collateralCount);
    function getPosition(uint64 positionID) external view returns (DebtPosition memory acct);
    function setPosition(uint64 positionID, DebtPosition memory dp) external;
    function sendCollateral(address account, uint count) external;
    function sendLentCoin(address dest, uint count) external;


    function debt() external view returns (uint);
    function getSystemDebtInfo() external view returns (SystemDebtInfo memory);
    function setSystemDebtInfo(SystemDebtInfo memory _systemDebtInfo) external;
    function increaseDebt(uint count) external;
    function decreaseDebt(uint count) external;


    function getPairTokenPosition(address owner, IUniswapV2Pair pair) external view returns (PairTokenPosition memory);
    function setPairTokenPosition(address owner, IUniswapV2Pair pair, PairTokenPosition memory pt) external;
    function getRewardStatus(IUniswapV2Pair pair) external view returns (RewardStatus memory rs);
    function setRewardStatus(IUniswapV2Pair pair, RewardStatus memory rs) external;
    function distributePairTokens(address to, IUniswapV2Pair pair, uint count) external;




    struct SystemDebtInfo {
        uint debt;
        uint totalCNPRewards;
        uint cumulativeDebt;
        uint debtExchangeRate;
    }

    struct SystemDebtInfoStorage {
        uint128 debt;
        uint128 cumulativeDebt;
        uint128 debtExchangeRate;
        uint128 totalCNPRewards;
    }


    struct DebtPosition {
        uint startCumulativeDebt;
        uint collateral;
        uint debt;
        uint startDebtExchangeRate;
        uint startCNPRewards;
        uint64 lastTimeUpdated;
        uint64 lastBorrowTime;
        uint32 collateralizationBand;
        uint64 collateralizationBandIndex;
    }

    struct DebtPositionStorage {
        uint startCumulativeDebt;
        uint128 collateral;
        uint128 debt;
        uint128 startDebtExchangeRate;
        uint128 startCNPRewards;
        uint64 lastTimeUpdated;
        uint64 lastBorrowTime;
        uint32 collateralizationBand;
        uint64 collateralizationBandIndex;
    }

    struct LiquidationAccount {
        uint startDebtExchangeRate;
        uint collateral;
        uint debt;
    }

    struct LiquidationAccountStorage {
        uint128 startDebtExchangeRate;
        uint128 collateral;
        uint debt;
    }


    struct RewardStatus {
        uint totalRewards;
        uint cumulativeLPTokenCount;
    }

    struct RewardStatusStorage {
        uint96 totalRewards;
        uint160 cumulativeLPTokenCount;
    }

    struct PairTokenPosition {
        uint totalRewards;
        uint count;
        uint cumulativeLPTokenCount;
        uint64 lastTimeRewarded;
    }

    struct PairTokenPositionStorage {
        uint128 totalRewards;
        uint128 count;
        uint224 cumulativeLPTokenCount;
        uint32 lastTimeRewarded;
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED




pragma solidity =0.7.4;


interface IAuctions {

    function latestAuctionCompletionTime() external view returns (uint64);


    struct Auction {
        uint count;
        uint bid;
        address bidder;
        uint64 endTime;
        uint64 maxEndTime;
    }


    function stop() external;


    event SurplusAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event DeficitAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event SurplusAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event DeficitAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event SurplusAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event DeficitAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;

import '../../library/interfaces/IERC20.sol';


interface ICNP is IERC20 {
    // ==================== SYSTEM FUNCTIONS ======================
    function mintTo(address to, uint count) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function addGovernor(address newGovernor) external;
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;

import '../../library/interfaces/IERC20.sol';


interface ICoin is IERC20 {
    function reserves() external view returns (uint);

    function distributeReserves(address dest, uint count) external;
    function burnReserves(uint count) external;
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;

    event ParameterUpdated(string indexed paramName, uint value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;

import '../../library/interfaces/IERC721.sol';
import '../../library/interfaces/IERC721Metadata.sol';


interface ICoinPositionNFT is IERC721, IERC721Metadata {
    function mintTo(address to) external returns (uint64 id);

    function isApprovedOrOwner(address account, uint tokenId) external view returns (bool r);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


interface IEnforcedDecentralization {
    function validateAction(address target, string memory signature) external view returns (bool);
    function transferEmergencyShutdownTokens(address dest, uint count) external;

    event UpgradeLockDelayed(uint64 locktime, uint8 delaysRemaining);
    event UpdateLockDelayed(uint64 locktime, uint8 delaysRemaining);
    event ActionBlacklisted(string indexed signature);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;

import '../../library/interfaces/IERC20.sol';


interface ILendCoin is IERC20 {
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


import './IAccounting.sol';
import './IGovernor.sol';

interface ILiquidations {
    function stop() external;

    struct LqInfo {
        uint discoverReward;
        uint liquidateReward;
        uint price;
        address discoverer;
        address priceInitializer;
        address account;
        uint8 collateral;
    }

    struct DiscoverLiquidationInfo {
        IAccounting.LiquidationAccount lqAcct;
        uint discoverReward;
        uint rewardsRemaining;
        uint collateralizationRequirement;
    }

    event UndercollatPositionDiscovered(
        uint64 indexed positionID,
        uint debtCount,
        uint collateralCount,
        uint price);
    event Liquidated(uint baseTokensToRepay, uint collateralToReceive);
    event CoveredUnbackedDebt(uint price, uint positionDebt, uint positionCollateral);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);

}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import '../../library/interfaces/IUniswapV2Pair.sol';
import './IGovernor.sol';
import './IAccounting.sol';


interface IMarket {
    function collateralizationRequirement() external view returns (uint ratio);
    function lastPeriodGlobalInterestAccrued() external view returns (uint64 period);

    function systemNotifyCollateralPriceUpdated(uint price) external;
    function systemGetUpdatedPosition(uint64 positionID) external returns (IAccounting.DebtPosition memory position);
    function systemAccrueInterest() external;

    function stop() external;

    struct CalculatedInterestInfo {
        uint newDebt;
        uint newExchangeRate;
        uint additionalReserves;
        uint additionalLends;
        uint reducedReserves;
    }

    event Lend(address indexed account, uint coinCount, uint lendTokenCount);
    event Unlend(address indexed account, uint coinCount, uint lendTokenCount);
    event NewPositionCreated(address indexed creator, uint64 indexed positionID);
    event Borrow(
        address indexed borrower,
        uint64 indexed positionID,
        uint borrowAmount,
        uint collateralIncrease);
    event Payback(
        address indexed caller,
        uint64 indexed positionID,
        uint debtPaidBack,
        uint collateralWithdrawn
    );

    event InterestAccrued(uint64 indexed period, uint64 periods, uint newDebt, uint rewardCount, uint cumulativeDebt, uint debtExchangeRate);
    event PositionUpdated(uint indexed positionID, uint64 indexed period, uint debtAfter, uint cnpRewards);

    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;

import '../../library/interfaces/IUniswapV2Pair.sol';


interface IPrices {
    function viewPrice(
        IUniswapV2Pair pair,
        bool normalizeDecimals
    ) external view returns (uint price, uint64 priceTime, uint64 twapTime);
    function viewCurrentTwappedPrice(
        IUniswapV2Pair pair,
        bool normalizeDecimals
    ) external view returns (uint price);

    function systemObtainCollateralPrice(
        uint64 maxTwapTime,
        uint64 maxAge,
        bool normalizePrice
    ) external returns (uint returnPrice, uint64 returnStartTime, uint64 newEndTime);

    function systemObtainReferencePrice(
        IUniswapV2Pair pair,
        uint64 maxTwapTime,
        uint64 maxAge,
        bool normalizePrice
    ) external returns (uint returnPrice, uint64 returnStartTime, uint64 newEndTime);

    function completeSetup() external;
    function stop() external;

    struct PriceInfo {
        uint price;
        uint cumulative;
        uint64 startTime;
        uint64 endTime;
        uint48 t0DecimalMultiplier;
        uint48 t1DecimalMultiplier;
        bool coinIsToken0;
    }

    // ==================== EVENTS ======================
    event PriceUpdated(address indexed pair, uint price, uint cumulative);
    event ParameterUpdated64(string indexed paramName, uint64 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


interface IProtocolLock {
    function enter() external;
    function exit() external;

    function authorizeCaller(address caller) external;
    function unauthorizeCaller(address caller) external;

    event CallerAuthorized(address indexed caller);
    event CallerUnauthorized(address indexed caller);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


import './IGovernor.sol';
import '../../library/interfaces/IUniswapV2Pair.sol';

interface IRewards {
    function maxDebtSupported() external view returns (uint additionalDebt);
    function systemNotifyPriceUpdated(IUniswapV2Pair pair, uint price) external;
    function borrowRewardsPortion() external view returns (uint);
    function completeSetup() external;

    function stop() external;

    event PairTokensLocked(address indexed sender, address indexed pair, uint count);
    event PairTokensUnlocked(address indexed sender, address indexed pair, uint count);
    event ShutdownPairTokensUnlocked(address indexed sender, address indexed pair, uint count);
    event RewardsAccrued(uint count, uint64 periods);
    event RewardsDistributed(address indexed account, uint64 indexed period, uint cnpRewards);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


interface ISettlement {
    function stakeTokensForNoPriceConfidence(uint countCNPToStake) external;
    function unstakeTokensForNoPriceConfidence() external;

    function setEthPriceProvider(IPriceProvider aggregator) external;
    function stop() external;

    event SettlementInitialized(uint settlementDiscoveryStartTime);
    event StakedNoConfidenceTokens(address indexed account, uint count);
    event UnstakedNoConfidenceTokens(address indexed account, uint count);
    event NoConfidenceConfirmed(address indexed account);

    event SettlementWithdrawCollateral(uint64 indexed positionID, address indexed owner, uint collateralToWithdraw);
    event SettlementCollateralForCoin(uint64 indexed positionID, address indexed caller, uint coinCount, uint collateralCount);

    event ParameterUpdatedAddress(string indexed paramName, address indexed _address);
}

interface IPriceProvider {
  function decimals() external view returns (uint8);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.4;


interface ITokenAllocations {
    function approveAllocation(uint) external;
    function availableAllocations() external returns (uint);
    function burnCNP(uint) external;

    struct TokenAllocation {
        address allocatee;
        uint64 startTime;
        uint64 endTime;
        bool approved;
        uint count;
        uint claimed;
        string allocationPurpose;
    }

    event AllocationCreated(address indexed creator, uint indexed id, uint64 startTime, uint64 endTime, uint count, string purpose);
    event AllocationApproved(uint indexed id);
    event AllocationClaimed(uint indexed id, uint amount);
    event CNPBurned(uint burnAmount);
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.1.0

pragma solidity =0.7.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Copied from @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol
// SPDX-License-Identifier: GPL-3.0-only

pragma solidity =0.7.4;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.2.0
// === updated compile target

pragma solidity =0.7.4;


import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.2.0
// === updated compile target

pragma solidity =0.7.4;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// adapted from OpenZeppelin v3.2.0
// === updated compile target

pragma solidity =0.7.4;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}