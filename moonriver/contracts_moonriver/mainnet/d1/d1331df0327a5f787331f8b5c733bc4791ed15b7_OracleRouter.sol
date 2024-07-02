/**
 *Submitted for verification at moonriver.moonscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

pragma solidity ^0.8.0;

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File contracts/interfaces/IBandProtocolOracle.sol

pragma solidity >=0.6.12 <0.9.0;

/**
 * Interface taken from Band Protocol's StdReferenceProxy contract.
 */
interface IBandProtocolOracle {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote) external view returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

// File contracts/interfaces/IChainlinkOracle.sol

pragma solidity >=0.6.12 <0.9.0;

interface IChainlinkOracle {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File contracts/interfaces/IOracleRouter.sol

pragma solidity >=0.6.12 <0.9.0;

interface IOracleRouter {
    function getPrice(bytes32 currencyKey) external view returns (uint);

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        bytes32 destKey
    ) external view returns (uint);
}

// File contracts/interfaces/IUniswapTwapOracle.sol

pragma solidity >=0.6.12 <0.9.0;

interface IUniswapTwapOracle {
    struct PriceWithTime {
        uint192 price;
        uint64 timestamp;
    }

    function getLatestPrice() external view returns (PriceWithTime memory);
}

// File contracts/libraries/SafeDecimalMath.sol

pragma solidity >=0.8.0 <0.9.0;

library SafeDecimalMath {
    uint8 internal constant decimals = 18;
    uint8 internal constant highPrecisionDecimals = 27;

    uint internal constant UNIT = 10**uint(decimals);

    uint internal constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    function unit() internal pure returns (uint) {
        return UNIT;
    }

    function preciseUnit() internal pure returns (uint) {
        return PRECISE_UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        return (x * y) / UNIT;
    }

    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint quotientTimesTen = (x * y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        return (x * UNIT) / y;
    }

    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = (x * (precisionUnit * 10)) / y;

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i * UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR;
    }

    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// File contracts/OracleRouter.sol

pragma solidity =0.8.9;

contract OracleRouter is IOracleRouter, OwnableUpgradeable {
    using SafeCastUpgradeable for int256;
    using SafeDecimalMath for uint256;
    using SafeMathUpgradeable for uint256;

    event GlobalStalePeriodUpdated(uint256 oldStalePeriod, uint256 newStalePeriod);
    event StalePeriodOverrideUpdated(bytes32 currencyKey, uint256 oldStalePeriod, uint256 newStalePeriod);
    event ChainlinkOracleAdded(bytes32 currencyKey, address oracle);
    event BandOracleAdded(bytes32 currencyKey, string bandCurrencyKey, address oracle);
    event UniswapTwapOracleAdded(bytes32 currencyKey, address oracle);
    event TerminalPriceOracleAdded(bytes32 currencyKey, uint160 terminalPrice);
    event OracleRemoved(bytes32 currencyKey, address oracle);

    struct OracleSettings {
        uint8 oracleType;
        address oracleAddress;
    }

    uint256 public globalStalePeriod;
    mapping(bytes32 => uint256) public stalePeriodOverrides;
    mapping(bytes32 => OracleSettings) public oracleSettings;
    mapping(bytes32 => string) public linearCurrencyKeysToBandCurrencyKeys;

    bytes32 public constant LUSD = "cUSD";

    uint8 public constant ORACLE_TYPE_CHAINLINK = 1;
    uint8 public constant ORACLE_TYPE_BAND = 2;
    uint8 public constant ORACLE_TYPE_UNISWAP_TWAP = 3;
    uint8 public constant ORACLE_TYPE_TERMINAL_PRICE = 4;

    uint8 private constant OUTPUT_PRICE_DECIMALS = 18;

    function getPrice(bytes32 currencyKey) external view override returns (uint256) {
        (uint256 price, ) = _getPriceData(currencyKey);
        return price;
    }

    function getPriceAndUpdatedTime(bytes32 currencyKey) external view returns (uint256 price, uint256 time) {
        (price, time) = _getPriceData(currencyKey);
    }

    function isPriceStaled(bytes32 currencyKey) external view returns (bool) {
        if (currencyKey == LUSD) return false;
        (, uint256 time) = _getPriceData(currencyKey);
        return _isUpdateTimeStaled(time, getStalePeriodForCurrency(currencyKey));
    }

    function exchange(
        bytes32 sourceKey,
        uint sourceAmount,
        bytes32 destKey
    ) external view override returns (uint256) {
        if (sourceKey == destKey) return sourceAmount;

        (uint256 sourcePrice, uint256 sourceTime) = _getPriceData(sourceKey);
        (uint256 destPrice, uint256 destTime) = _getPriceData(destKey);

        require(
            !_isUpdateTimeStaled(sourceTime, getStalePeriodForCurrency(sourceKey)) &&
                !_isUpdateTimeStaled(destTime, getStalePeriodForCurrency(destKey)),
            "OracleRouter: staled price data"
        );

        return sourceAmount.multiplyDecimalRound(sourcePrice).divideDecimalRound(destPrice);
    }

    function getStalePeriodForCurrency(bytes32 currencyKey) public view returns (uint256) {
        uint256 overridenPeriod = stalePeriodOverrides[currencyKey];
        return overridenPeriod == 0 ? globalStalePeriod : overridenPeriod;
    }

    function __OracleRouter_init() public initializer {
        __Ownable_init();
    }

    function setGlobalStalePeriod(uint256 newStalePeriod) external onlyOwner {
        uint256 oldStalePeriod = globalStalePeriod;
        globalStalePeriod = newStalePeriod;
        emit GlobalStalePeriodUpdated(oldStalePeriod, newStalePeriod);
    }

    function setStalePeriodOverride(bytes32 currencyKey, uint256 newStalePeriod) external onlyOwner {
        uint256 oldStalePeriod = stalePeriodOverrides[currencyKey];
        stalePeriodOverrides[currencyKey] = newStalePeriod;
        emit StalePeriodOverrideUpdated(currencyKey, oldStalePeriod, newStalePeriod);
    }

    function addChainlinkOracle(
        bytes32 currencyKey,
        address oracleAddress,
        bool removeExisting
    ) external onlyOwner {
        _addChainlinkOracle(currencyKey, oracleAddress, removeExisting);
    }

    function addChainlinkOracles(
        bytes32[] calldata currencyKeys,
        address[] calldata oracleAddresses,
        bool removeExisting
    ) external onlyOwner {
        require(currencyKeys.length == oracleAddresses.length, "OracleRouter: array length mismatch");

        for (uint256 ind = 0; ind < currencyKeys.length; ind++) {
            _addChainlinkOracle(currencyKeys[ind], oracleAddresses[ind], removeExisting);
        }
    }

    function addBandOracle(
        bytes32 currencyKey,
        string calldata bandCurrencyKey,
        address oracleAddress,
        bool removeExisting
    ) external onlyOwner {
        _addBandOracle(currencyKey, bandCurrencyKey, oracleAddress, removeExisting);
    }

    function addBandOracles(
        bytes32[] calldata currencyKeys,
        string[] calldata bandCurrencyKeys,
        address[] calldata oracleAddresses,
        bool removeExisting
    ) external onlyOwner {
        require(
            currencyKeys.length == bandCurrencyKeys.length && bandCurrencyKeys.length == oracleAddresses.length,
            "OracleRouter: array length mismatch"
        );

        for (uint256 ind = 0; ind < currencyKeys.length; ind++) {
            _addBandOracle(currencyKeys[ind], bandCurrencyKeys[ind], oracleAddresses[ind], removeExisting);
        }
    }

    function addUniswapTwapOracle(
        bytes32 currencyKey,
        address oracleAddress,
        bool removeExisting
    ) external onlyOwner {
        _addUniswapTwapOracle(currencyKey, oracleAddress, removeExisting);
    }

    function addUniswapTwapOracles(
        bytes32[] calldata currencyKeys,
        address[] calldata oracleAddresses,
        bool removeExisting
    ) external onlyOwner {
        require(currencyKeys.length == oracleAddresses.length, "OracleRouter: array length mismatch");

        for (uint256 ind = 0; ind < currencyKeys.length; ind++) {
            _addUniswapTwapOracle(currencyKeys[ind], oracleAddresses[ind], removeExisting);
        }
    }

    function addTerminalPriceOracle(
        bytes32 currencyKey,
        uint160 terminalPrice,
        bool removeExisting
    ) external onlyOwner {
        _addTerminalPriceOracle(currencyKey, terminalPrice, removeExisting);
    }

    function addTerminalPriceOracles(
        bytes32[] calldata currencyKeys,
        uint160[] calldata terminalPrices,
        bool removeExisting
    ) external onlyOwner {
        require(currencyKeys.length == terminalPrices.length, "OracleRouter: array length mismatch");

        for (uint256 ind = 0; ind < currencyKeys.length; ind++) {
            _addTerminalPriceOracle(currencyKeys[ind], terminalPrices[ind], removeExisting);
        }
    }

    function removeOracle(bytes32 currencyKey) external onlyOwner {
        _removeOracle(currencyKey);
    }

    function _addChainlinkOracle(
        bytes32 currencyKey,
        address oracleAddress,
        bool removeExisting
    ) private {
        require(currencyKey != bytes32(0), "OracleRouter: empty currency key");
        require(oracleAddress != address(0), "OracleRouter: empty oracle address");

        if (oracleSettings[currencyKey].oracleAddress != address(0)) {
            require(removeExisting, "OracleRouter: oracle already exists");
            _removeOracle(currencyKey);
        }

        oracleSettings[currencyKey] = OracleSettings({oracleType: ORACLE_TYPE_CHAINLINK, oracleAddress: oracleAddress});

        emit ChainlinkOracleAdded(currencyKey, oracleAddress);
    }

    function _addBandOracle(
        bytes32 currencyKey,
        string calldata bandCurrencyKey,
        address oracleAddress,
        bool removeExisting
    ) private {
        require(currencyKey != bytes32(0), "OracleRouter: empty currency key");
        require(bytes(bandCurrencyKey).length != 0, "OracleRouter: empty band currency key");
        require(oracleAddress != address(0), "OracleRouter: empty oracle address");

        if (oracleSettings[currencyKey].oracleAddress != address(0)) {
            require(removeExisting, "OracleRouter: oracle already exists");
            _removeOracle(currencyKey);
        }

        oracleSettings[currencyKey] = OracleSettings({oracleType: ORACLE_TYPE_BAND, oracleAddress: oracleAddress});
        linearCurrencyKeysToBandCurrencyKeys[currencyKey] = bandCurrencyKey;

        emit BandOracleAdded(currencyKey, bandCurrencyKey, oracleAddress);
    }

    function _addUniswapTwapOracle(
        bytes32 currencyKey,
        address oracleAddress,
        bool removeExisting
    ) private {
        require(currencyKey != bytes32(0), "OracleRouter: empty currency key");
        require(oracleAddress != address(0), "OracleRouter: empty oracle address");

        if (oracleSettings[currencyKey].oracleAddress != address(0)) {
            require(removeExisting, "OracleRouter: oracle already exists");
            _removeOracle(currencyKey);
        }

        oracleSettings[currencyKey] = OracleSettings({oracleType: ORACLE_TYPE_UNISWAP_TWAP, oracleAddress: oracleAddress});

        emit UniswapTwapOracleAdded(currencyKey, oracleAddress);
    }

    function _addTerminalPriceOracle(
        bytes32 currencyKey,
        uint160 terminalPrice,
        bool removeExisting
    ) private {
        require(currencyKey != bytes32(0), "OracleRouter: empty currency key");
        require(terminalPrice != 0, "OracleRouter: empty oracle address");

        if (oracleSettings[currencyKey].oracleAddress != address(0)) {
            require(removeExisting, "OracleRouter: oracle already exists");
            _removeOracle(currencyKey);
        }

        // Exploits the `oracleAddress` field to store a 160-bit integer
        oracleSettings[currencyKey] = OracleSettings({
            oracleType: ORACLE_TYPE_TERMINAL_PRICE,
            oracleAddress: address(terminalPrice)
        });

        emit TerminalPriceOracleAdded(currencyKey, terminalPrice);
    }

    function _removeOracle(bytes32 currencyKey) private {
        OracleSettings memory settings = oracleSettings[currencyKey];
        require(settings.oracleAddress != address(0), "OracleRouter: oracle not found");

        delete oracleSettings[currencyKey];

        if (settings.oracleType == ORACLE_TYPE_BAND) {
            delete linearCurrencyKeysToBandCurrencyKeys[currencyKey];
        }

        emit OracleRemoved(currencyKey, settings.oracleAddress);
    }

    function _getPriceData(bytes32 currencyKey) private view returns (uint256 price, uint256 updateTime) {
        if (currencyKey == LUSD) return (SafeDecimalMath.unit(), block.timestamp);

        OracleSettings memory settings = oracleSettings[currencyKey];
        require(settings.oracleAddress != address(0), "OracleRouter: oracle not set");

        if (settings.oracleType == ORACLE_TYPE_CHAINLINK) {
            (, int256 rawAnswer, , uint256 rawUpdateTime, ) = IChainlinkOracle(settings.oracleAddress).latestRoundData();

            uint8 oraclePriceDecimals = IChainlinkOracle(settings.oracleAddress).decimals();
            if (oraclePriceDecimals == OUTPUT_PRICE_DECIMALS) {
                price = rawAnswer.toUint256();
            } else if (oraclePriceDecimals > OUTPUT_PRICE_DECIMALS) {
                // Too many decimals
                price = rawAnswer.toUint256().div(10**uint256(oraclePriceDecimals - OUTPUT_PRICE_DECIMALS));
            } else {
                // Too few decimals
                price = rawAnswer.toUint256().mul(10**uint256(OUTPUT_PRICE_DECIMALS - oraclePriceDecimals));
            }

            updateTime = rawUpdateTime;
        } else if (settings.oracleType == ORACLE_TYPE_BAND) {
            IBandProtocolOracle.ReferenceData memory priceRes = IBandProtocolOracle(settings.oracleAddress).getReferenceData(
                linearCurrencyKeysToBandCurrencyKeys[currencyKey],
                "USD"
            );

            price = priceRes.rate;
            updateTime = priceRes.lastUpdatedBase;
        } else if (settings.oracleType == ORACLE_TYPE_UNISWAP_TWAP) {
            IUniswapTwapOracle.PriceWithTime memory priceRes = IUniswapTwapOracle(settings.oracleAddress).getLatestPrice();

            // Prices from `UniswapTwapOracle` are guaranteed to be 18-decimal
            price = priceRes.price;
            updateTime = priceRes.timestamp;
        } else if (settings.oracleType == ORACLE_TYPE_TERMINAL_PRICE) {
            price = uint256(uint160(settings.oracleAddress));
            updateTime = block.timestamp;
        } else {
            require(false, "OracleRouter: unknown oracle type");
        }
    }

    function _isUpdateTimeStaled(uint256 updateTime, uint256 stalePeriod) private view returns (bool) {
        return updateTime.add(stalePeriod) < block.timestamp;
    }
}