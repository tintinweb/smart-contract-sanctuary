/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

// File: contracts/oracle/RegularIntervalOracleInterface.sol




/**
 * @dev Interface of the regular interval price oracle.
 */
interface RegularIntervalOracleInterface {
  function setPrice(uint256 roundId) external returns (bool);

  function setOptimizedParameters(uint16 lambdaE4) external returns (bool);

  function updateQuantsAddress(address quantsAddress) external returns (bool);

  function getNormalizedTimeStamp(uint256 timestamp)
    external
    view
    returns (uint256);

  function getDecimals() external view returns (uint8);

  function getInterval() external view returns (uint256);

  function getLatestTimestamp() external view returns (uint256);

  function getOldestTimestamp() external view returns (uint256);

  function getVolatility() external view returns (uint256 volE8);

  function getInfo() external view returns (address chainlink, address quants);

  function getPrice() external view returns (uint256);

  function setSequentialPrices(uint256[] calldata roundIds)
    external
    returns (bool);

  function getPriceTimeOf(uint256 unixtime) external view returns (uint256);

  function getVolatilityTimeOf(uint256 unixtime)
    external
    view
    returns (uint256 volE8);

  function getCurrentParameters()
    external
    view
    returns (uint16 lambdaE4, uint16 dataNum);

  function getVolatility(uint64 untilMaturity)
    external
    view
    returns (uint64 volatilityE8);
}

// File: contracts/ChainLinkAggregator/ChainLinkAggregatorInterface.sol




// https://github.com/smartcontractkit/chainlink/blob/feature/whitelisted-interface/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
// https://github.com/smartcontractkit/chainlink/blob/feature/whitelisted-interface/evm-contracts/src/v0.6/interfaces/AggregatorInterface.sol
interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (
      uint256 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/SafeCast.sol






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
library SafeCast {

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

// File: @openzeppelin/contracts/math/SafeMath.sol





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
library SafeMath {
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/oracle/RegularIntervalOracle.sol








/**
 * @dev Record chainlink price once a day
 */
contract RegularIntervalOracle is RegularIntervalOracleInterface {
  using SafeCast for uint16;
  using SafeCast for uint32;
  using SafeCast for uint256;
  using SafeMath for uint256;

  struct PriceData {
    uint64 priceE8;
    uint64 ewmaVolatilityE8;
  }

  // Max ETH Price = $1 million per ETH
  int256 constant MAX_VALID_ETHPRICE = 10**14;
  // 1 year in sec
  uint256 constant ONE_YEAR_IN_SEC = 3600 * 24 * 365;

  /* ========== CONSTANT VARIABLES ========== */
  AggregatorInterface internal immutable _chainlinkOracle;
  uint256 internal immutable _interval;
  uint8 internal immutable _decimals;
  uint128 internal immutable _timeCorrectionFactor;
  uint128 internal immutable _oldestTimestamp;
  uint16 internal immutable _dataNum;

  /* ========== STATE VARIABLES ========== */
  address internal _quantsAddress;
  uint256 internal _latestTimestamp;
  mapping(uint256 => PriceData) internal _regularIntervalPriceData;
  uint16 internal lambdaE4;

  event LambdaChanged(uint16 newLambda);
  event QuantsChanged(address newQuantsAddress);

  /* ========== CONSTRUCTOR ========== */

  /**
   * @param quantsAddress can set optimized parameters
   * @param chainlinkOracleAddress Chainlink price oracle
   * @param startTimestamp Recording timestamp is startTimestamp +- n * interval
   * @param interval Daily record = 3600*24
   * @param decimals Decimals of price
   */
  constructor(
    uint8 decimals,
    uint16 initialLambdaE4,
    uint16 initialDataNum,
    uint32 initialVolE4,
    address quantsAddress,
    address chainlinkOracleAddress,
    uint256 startTimestamp,
    uint256 interval,
    uint256 initialRoundId
  ) {
    _dataNum = initialDataNum;
    lambdaE4 = initialLambdaE4;
    _quantsAddress = quantsAddress;
    _chainlinkOracle = AggregatorInterface(chainlinkOracleAddress);
    _interval = interval;
    _decimals = decimals;
    _timeCorrectionFactor = uint128(startTimestamp % interval);
    initialRoundId = _getValidRoundIDWithAggregator(
      initialRoundId,
      startTimestamp,
      AggregatorInterface(chainlinkOracleAddress)
    );
    int256 priceE8 =
      _getPriceFromChainlinkWithAggregator(
        initialRoundId,
        AggregatorInterface(chainlinkOracleAddress)
      );
    _regularIntervalPriceData[startTimestamp] = PriceData(
      uint256(priceE8).toUint64(),
      uint64(initialVolE4)
    );
    _latestTimestamp = uint128(startTimestamp);
    _oldestTimestamp = uint128(startTimestamp);
    require(initialDataNum > 1, "Error: InitialDataNum should be more than 1");
    require(
      quantsAddress != address(0),
      "Error: Invalid initial quant address"
    );
    require(
      chainlinkOracleAddress != address(0),
      "Error: Invalid chainlink address"
    );
    require(interval != 0, "Error: Interval should be more than 0");
  }

  /* ========== MUTABLE FUNCTIONS ========== */

  /**
   * @notice Set new price
   * @dev Prices must be updated by regular interval
   * @param roundId is chainlink roundId
   */
  function setPrice(uint256 roundId) public override returns (bool) {
    _latestTimestamp += _interval;
    require(
      _latestTimestamp <= block.timestamp,
      "Error: This function should be after interval"
    );
    //If next oldestTimestamp == _latestTimestamp

    roundId = _getValidRoundID(roundId, _latestTimestamp);
    _setPrice(roundId, _latestTimestamp);
    return true;
  }

  /**
   * @notice Set sequential prices
   * @param roundIds Array of roundIds which contain the first timestamp after the regular interval timestamp
   */
  function setSequentialPrices(uint256[] calldata roundIds)
    external
    override
    returns (bool)
  {
    uint256 roundIdsLength = roundIds.length;
    uint256 normalizedCurrentTimestamp =
      getNormalizedTimeStamp(block.timestamp);
    require(
      _latestTimestamp <= normalizedCurrentTimestamp,
      "Error: This function should be after interval"
    );
    // If length of roundIds is too short or too long, return false
    if (
      (normalizedCurrentTimestamp - _latestTimestamp) / _interval <
      roundIdsLength ||
      roundIdsLength < 2
    ) {
      return false;
    }

    for (uint256 i = 0; i < roundIdsLength; i++) {
      setPrice(roundIds[i]);
    }
    return true;
  }

  /**
   * @notice Set optimized parameters for EWMA only by quants address
   * Recalculate latest Volatility with new lambda
   * Recalculation starts from price at `latestTimestamp - _dataNum * _interval`
   */
  function setOptimizedParameters(uint16 newLambdaE4)
    external
    override
    onlyQuants
    returns (bool)
  {
    require(
      newLambdaE4 > 9000 && newLambdaE4 < 10000,
      "new lambda is out of valid range"
    );
    require(
      (_latestTimestamp - _oldestTimestamp) / _interval > _dataNum,
      "Error: Insufficient number of data registered"
    );
    lambdaE4 = newLambdaE4;
    uint256 oldTimestamp = _latestTimestamp - _dataNum * _interval;
    uint256 pNew = _getPrice(oldTimestamp + _interval);
    uint256 updatedVol = _getVolatility(oldTimestamp);
    for (uint256 i = 0; i < _dataNum - 1; i++) {
      updatedVol = _getEwmaVolatility(oldTimestamp, pNew, updatedVol);
      oldTimestamp += _interval;
      pNew = _getPrice(oldTimestamp + _interval);
    }

    _regularIntervalPriceData[_latestTimestamp].ewmaVolatilityE8 = updatedVol
      .toUint64();
    emit LambdaChanged(newLambdaE4);
    return true;
  }

  /**
   * @notice Update quants address only by quants address
   */
  function updateQuantsAddress(address quantsAddress)
    external
    override
    onlyQuants
    returns (bool)
  {
    _quantsAddress = quantsAddress;
    require(quantsAddress != address(0), "Error: Invalid new quant address");
    emit QuantsChanged(quantsAddress);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyQuants() {
    require(msg.sender == _quantsAddress, "only quants address can call");
    _;
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
   * @return price at the `unixtime`
   */
  function _getPrice(uint256 unixtime) internal view returns (uint256) {
    return _regularIntervalPriceData[unixtime].priceE8;
  }

  /**
   * @return Volatility at the `unixtime`
   */
  function _getVolatility(uint256 unixtime) internal view returns (uint256) {
    return _regularIntervalPriceData[unixtime].ewmaVolatilityE8;
  }

  /**
   * @notice Get annualized ewma volatility.
   * @param oldTimestamp is the previous term to calculate volatility
   */
  function _getEwmaVolatility(
    uint256 oldTimestamp,
    uint256 pNew,
    uint256 oldVolE8
  ) internal view returns (uint256 volE8) {
    uint256 pOld = _getPrice(oldTimestamp);
    uint256 rrE8 =
      pNew >= pOld
        ? ((pNew * (10**4)) / pOld - (10**4))**2
        : ((10**4) - (pNew * (10**4)) / pOld)**2;
    uint256 vol_2E16 =
      (oldVolE8**2 * lambdaE4) /
        10**4 +
        (10**4 - lambdaE4) *
        rrE8 *
        (ONE_YEAR_IN_SEC / _interval) *
        10**4;
    volE8 = _sqrt(vol_2E16);
  }

  /**
   * @dev Calcurate an approximation of the square root of x by Babylonian method.
   */
  function _sqrt(uint256 x) internal pure returns (uint256 y) {
    if (x > 3) {
      uint256 z = x / 2 + 1;
      y = x;
      while (z < y) {
        y = z;
        z = (x / z + z) / 2;
      }
    } else if (x != 0) {
      y = 1;
    }
  }

  function _getValidRoundID(uint256 hintID, uint256 targetTimeStamp)
    internal
    view
    returns (uint256 roundID)
  {
    return
      _getValidRoundIDWithAggregator(hintID, targetTimeStamp, _chainlinkOracle);
  }

  function _getValidRoundIDWithAggregator(
    uint256 hintID,
    uint256 targetTimeStamp,
    AggregatorInterface _chainlinkAggregator
  ) internal view returns (uint256 roundID) {
    if (hintID == 0) {
      hintID = _chainlinkAggregator.latestRound();
    }
    uint256 timeStampOfHintID = _chainlinkAggregator.getTimestamp(hintID);
    require(
      timeStampOfHintID >= targetTimeStamp,
      "Hint round or Latest round should be registered after target time"
    );
    require(hintID != 0, "Invalid hint ID");
    for (uint256 index = hintID - 1; index > 0; index--) {
      uint256 timestamp = _chainlinkAggregator.getTimestamp(index);
      if (timestamp != 0 && timestamp <= targetTimeStamp) {
        return index + 1;
      }
    }
    require(false, "No valid round ID found");
  }

  function _setPrice(uint256 roundId, uint256 timeStamp) internal {
    int256 priceE8 = _getPriceFromChainlink(roundId);
    require(priceE8 > 0, "Should return valid price");
    uint256 ewmaVolatilityE8 =
      _getEwmaVolatility(
        timeStamp - _interval,
        uint256(priceE8),
        _getVolatility(timeStamp - _interval)
      );
    _regularIntervalPriceData[timeStamp] = PriceData(
      uint256(priceE8).toUint64(),
      ewmaVolatilityE8.toUint64()
    );
  }

  function _getPriceFromChainlink(uint256 roundId)
    internal
    view
    returns (int256 priceE8)
  {
    return _getPriceFromChainlinkWithAggregator(roundId, _chainlinkOracle);
  }

  function _getPriceFromChainlinkWithAggregator(
    uint256 roundId,
    AggregatorInterface _chainlinkAggregator
  ) internal view returns (int256 priceE8) {
    while (true) {
      priceE8 = _chainlinkAggregator.getAnswer(roundId);
      if (priceE8 > 0 && priceE8 < MAX_VALID_ETHPRICE) {
        break;
      }
      roundId -= 1;
    }
  }

  /* ========== CALL FUNCTIONS ========== */

  /**
   * @notice Calculate normalized timestamp to get valid value
   */
  function getNormalizedTimeStamp(uint256 timestamp)
    public
    view
    override
    returns (uint256)
  {
    // L79
    return
      ((timestamp.sub(_timeCorrectionFactor)) / _interval) *
      _interval +
      _timeCorrectionFactor;
  }

  function getInfo()
    external
    view
    override
    returns (address chainlink, address quants)
  {
    return (address(_chainlinkOracle), _quantsAddress);
  }

  /**
   * @return Decimals of price
   */
  function getDecimals() external view override returns (uint8) {
    return _decimals;
  }

  /**
   * @return Interval of historical data
   */
  function getInterval() external view override returns (uint256) {
    return _interval;
  }

  /**
   * @return Latest timestamp in this oracle
   */
  function getLatestTimestamp() external view override returns (uint256) {
    return _latestTimestamp;
  }

  /**
   * @return Oldest timestamp in this oracle
   */
  function getOldestTimestamp() external view override returns (uint256) {
    return _oldestTimestamp;
  }

  function getPrice() external view override returns (uint256) {
    return _getPrice(_latestTimestamp);
  }

  function getCurrentParameters()
    external
    view
    override
    returns (uint16 lambda, uint16 dataNum)
  {
    return (lambdaE4, _dataNum);
  }

  function getPriceTimeOf(uint256 unixtime)
    external
    view
    override
    returns (uint256)
  {
    uint256 normalizedUnixtime = getNormalizedTimeStamp(unixtime);
    return _getPrice(normalizedUnixtime);
  }

  function _getCurrentVolatility() internal view returns (uint256 volE8) {
    uint256 latestRound = _chainlinkOracle.latestRound();
    uint256 latestVolatility = _getVolatility(_latestTimestamp);
    uint256 currentVolatility =
      _getEwmaVolatility(
        _latestTimestamp,
        uint256(_getPriceFromChainlink(latestRound)),
        _getVolatility(_latestTimestamp)
      );
    volE8 = latestVolatility >= currentVolatility
      ? latestVolatility
      : currentVolatility;
  }

  /**
   * @notice Calculate lastest ewmaVolatility
   * @dev Calculate new volatility with chainlink price at latest round
   * @param volE8 Return the larger of `latestVolatility` and `currentVolatility`
   */
  function getVolatility() external view override returns (uint256 volE8) {
    volE8 = _getCurrentVolatility();
  }

  /**
   * @notice This function has the same interface with Lien Volatility Oracle
   */
  function getVolatility(uint64)
    external
    view
    override
    returns (uint64 volatilityE8)
  {
    uint256 volE8 = _getCurrentVolatility();
    return volE8.toUint64();
  }

  /**
   * @notice Get registered ewmaVolatility of given timestamp
   */
  function getVolatilityTimeOf(uint256 unixtime)
    external
    view
    override
    returns (uint256 volE8)
  {
    uint256 normalizedUnixtime = getNormalizedTimeStamp(unixtime);
    return _regularIntervalPriceData[normalizedUnixtime].ewmaVolatilityE8;
  }
}