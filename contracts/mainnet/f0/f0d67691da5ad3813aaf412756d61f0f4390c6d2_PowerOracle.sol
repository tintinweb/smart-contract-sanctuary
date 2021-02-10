/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/
// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/upgrades-core/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/SafeCast.sol

pragma solidity >=0.6.0 <0.8.0;


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

// File: contracts/interfaces/IPowerOracle.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPowerOracle {
  enum ReportInterval { LESS_THAN_MIN, OK, GREATER_THAN_MAX }

  function pokeFromReporter(
    uint256 reporterId_,
    string[] memory symbols_,
    bytes calldata rewardOpts
  ) external;

  function pokeFromSlasher(
    uint256 slasherId_,
    string[] memory symbols_,
    bytes calldata rewardOpts
  ) external;

  function poke(string[] memory symbols_) external;

  function slasherHeartbeat(uint256 slasherId) external;

  /*** Owner Interface ***/
  function setPowerPoke(address powerOracleStaking) external;

  function pause() external;

  function unpause() external;

  /*** Viewers ***/
  function getPriceByAsset(address token) external view returns (uint256);

  function getPriceBySymbol(string calldata symbol) external view returns (uint256);

  function getPriceBySymbolHash(bytes32 symbolHash) external view returns (uint256);

  function getUnderlyingPrice(address cToken) external view returns (uint256);

  function assetPrices(address token) external view returns (uint256);
}

// File: contracts/interfaces/IPowerPoke.sol

pragma solidity ^0.6.12;

interface IPowerPoke {
  /*** CLIENT'S CONTRACT INTERFACE ***/
  function authorizeReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporterWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinDeposit_
  ) external view;

  function authorizePoker(uint256 userId_, address pokerKey_) external view;

  function authorizePokerWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinStake_
  ) external view;

  function slashReporter(uint256 slasherId_, uint256 times_) external;

  function reward(
    uint256 userId_,
    uint256 gasUsed_,
    uint256 compensationPlan_,
    bytes calldata pokeOptions_
  ) external;

  /*** CLIENT OWNER INTERFACE ***/
  function transferClientOwnership(address client_, address to_) external;

  function addCredit(address client_, uint256 amount_) external;

  function withdrawCredit(
    address client_,
    address to_,
    uint256 amount_
  ) external;

  function setReportIntervals(
    address client_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setSlasherHeartbeat(address client_, uint256 slasherHeartbeat_) external;

  function setGasPriceLimit(address client_, uint256 gasPriceLimit_) external;

  function setFixedCompensations(
    address client_,
    uint256 eth_,
    uint256 cvp_
  ) external;

  function setBonusPlan(
    address client_,
    uint256 planId_,
    bool active_,
    uint64 bonusNominator_,
    uint64 bonusDenominator_,
    uint64 perGas_
  ) external;

  function setMinimalDeposit(address client_, uint256 defaultMinDeposit_) external;

  /*** POKER INTERFACE ***/
  function withdrawRewards(uint256 userId_, address to_) external;

  function setPokerKeyRewardWithdrawAllowance(uint256 userId_, bool allow_) external;

  /*** OWNER INTERFACE ***/
  function addClient(
    address client_,
    address owner_,
    bool canSlash_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setClientActiveFlag(address client_, bool active_) external;

  function setCanSlashFlag(address client_, bool canSlash) external;

  function setOracle(address oracle_) external;

  function pause() external;

  function unpause() external;

  /*** GETTERS ***/
  function creditOf(address client_) external view returns (uint256);

  function ownerOf(address client_) external view returns (address);

  function getMinMaxReportIntervals(address client_) external view returns (uint256 min, uint256 max);

  function getSlasherHeartbeat(address client_) external view returns (uint256);

  function getGasPriceLimit(address client_) external view returns (uint256);

  function getPokerBonus(
    address client_,
    uint256 bonusPlanId_,
    uint256 gasUsed_,
    uint256 userDeposit_
  ) external view returns (uint256);

  function getGasPriceFor(address client_) external view returns (uint256);
}

// File: contracts/PowerOracleStorageV1.sol

pragma solidity ^0.6.12;


contract PowerOracleStorageV1 {
  struct Price {
    uint128 timestamp;
    uint128 value;
  }

  struct Observation {
    uint256 timestamp;
    uint256 acc;
  }

  /// @notice The linked PowerOracleStaking contract address
  IPowerPoke public powerPoke;

  /// @notice Official prices and timestamps by symbol hash
  mapping(bytes32 => Price) public prices;

  /// @notice Last slasher update time by a user ID
  mapping(uint256 => uint256) public lastSlasherUpdates;

  /// @notice The old observation for each symbolHash
  mapping(bytes32 => Observation) public oldObservations;

  /// @notice The new observation for each symbolHash
  mapping(bytes32 => Observation) public newObservations;
}

// File: contracts/Uniswap/UniswapConfig.sol

pragma solidity ^0.6.10;

interface CErc20 {
    function underlying() external view returns (address);
}

contract UniswapConfig {
    /// @dev Describe how to interpret the fixedPrice in the TokenConfig.
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        address cToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isUniswapReversed;
    }

    /// @notice The max number of tokens this contract is hardcoded to support
    /// @dev Do not change this variable without updating all the fields throughout the contract.
    uint public constant maxTokens = 21;

    /// @notice The number of tokens this contract actually supports
    uint public immutable numTokens;

    address internal immutable cToken00;
    address internal immutable cToken01;
    address internal immutable cToken02;
    address internal immutable cToken03;
    address internal immutable cToken04;
    address internal immutable cToken05;
    address internal immutable cToken06;
    address internal immutable cToken07;
    address internal immutable cToken08;
    address internal immutable cToken09;
    address internal immutable cToken10;
    address internal immutable cToken11;
    address internal immutable cToken12;
    address internal immutable cToken13;
    address internal immutable cToken14;
    address internal immutable cToken15;
    address internal immutable cToken16;
    address internal immutable cToken17;
    address internal immutable cToken18;
    address internal immutable cToken19;
    address internal immutable cToken20;
//    address internal immutable cToken21;
//    address internal immutable cToken22;
//    address internal immutable cToken23;
//    address internal immutable cToken24;
//    address internal immutable cToken25;
//    address internal immutable cToken26;
//    address internal immutable cToken27;
//    address internal immutable cToken28;
//    address internal immutable cToken29;

    address internal immutable underlying00;
    address internal immutable underlying01;
    address internal immutable underlying02;
    address internal immutable underlying03;
    address internal immutable underlying04;
    address internal immutable underlying05;
    address internal immutable underlying06;
    address internal immutable underlying07;
    address internal immutable underlying08;
    address internal immutable underlying09;
    address internal immutable underlying10;
    address internal immutable underlying11;
    address internal immutable underlying12;
    address internal immutable underlying13;
    address internal immutable underlying14;
    address internal immutable underlying15;
    address internal immutable underlying16;
    address internal immutable underlying17;
    address internal immutable underlying18;
    address internal immutable underlying19;
    address internal immutable underlying20;
//    address internal immutable underlying21;
//    address internal immutable underlying22;
//    address internal immutable underlying23;
//    address internal immutable underlying24;
//    address internal immutable underlying25;
//    address internal immutable underlying26;
//    address internal immutable underlying27;
//    address internal immutable underlying28;
//    address internal immutable underlying29;

    bytes32 internal immutable symbolHash00;
    bytes32 internal immutable symbolHash01;
    bytes32 internal immutable symbolHash02;
    bytes32 internal immutable symbolHash03;
    bytes32 internal immutable symbolHash04;
    bytes32 internal immutable symbolHash05;
    bytes32 internal immutable symbolHash06;
    bytes32 internal immutable symbolHash07;
    bytes32 internal immutable symbolHash08;
    bytes32 internal immutable symbolHash09;
    bytes32 internal immutable symbolHash10;
    bytes32 internal immutable symbolHash11;
    bytes32 internal immutable symbolHash12;
    bytes32 internal immutable symbolHash13;
    bytes32 internal immutable symbolHash14;
    bytes32 internal immutable symbolHash15;
    bytes32 internal immutable symbolHash16;
    bytes32 internal immutable symbolHash17;
    bytes32 internal immutable symbolHash18;
    bytes32 internal immutable symbolHash19;
    bytes32 internal immutable symbolHash20;
//    bytes32 internal immutable symbolHash21;
//    bytes32 internal immutable symbolHash22;
//    bytes32 internal immutable symbolHash23;
//    bytes32 internal immutable symbolHash24;
//    bytes32 internal immutable symbolHash25;
//    bytes32 internal immutable symbolHash26;
//    bytes32 internal immutable symbolHash27;
//    bytes32 internal immutable symbolHash28;
//    bytes32 internal immutable symbolHash29;

    uint256 internal immutable baseUnit00;
    uint256 internal immutable baseUnit01;
    uint256 internal immutable baseUnit02;
    uint256 internal immutable baseUnit03;
    uint256 internal immutable baseUnit04;
    uint256 internal immutable baseUnit05;
    uint256 internal immutable baseUnit06;
    uint256 internal immutable baseUnit07;
    uint256 internal immutable baseUnit08;
    uint256 internal immutable baseUnit09;
    uint256 internal immutable baseUnit10;
    uint256 internal immutable baseUnit11;
    uint256 internal immutable baseUnit12;
    uint256 internal immutable baseUnit13;
    uint256 internal immutable baseUnit14;
    uint256 internal immutable baseUnit15;
    uint256 internal immutable baseUnit16;
    uint256 internal immutable baseUnit17;
    uint256 internal immutable baseUnit18;
    uint256 internal immutable baseUnit19;
    uint256 internal immutable baseUnit20;
//    uint256 internal immutable baseUnit21;
//    uint256 internal immutable baseUnit22;
//    uint256 internal immutable baseUnit23;
//    uint256 internal immutable baseUnit24;
//    uint256 internal immutable baseUnit25;
//    uint256 internal immutable baseUnit26;
//    uint256 internal immutable baseUnit27;
//    uint256 internal immutable baseUnit28;
//    uint256 internal immutable baseUnit29;

    PriceSource internal immutable priceSource00;
    PriceSource internal immutable priceSource01;
    PriceSource internal immutable priceSource02;
    PriceSource internal immutable priceSource03;
    PriceSource internal immutable priceSource04;
    PriceSource internal immutable priceSource05;
    PriceSource internal immutable priceSource06;
    PriceSource internal immutable priceSource07;
    PriceSource internal immutable priceSource08;
    PriceSource internal immutable priceSource09;
    PriceSource internal immutable priceSource10;
    PriceSource internal immutable priceSource11;
    PriceSource internal immutable priceSource12;
    PriceSource internal immutable priceSource13;
    PriceSource internal immutable priceSource14;
    PriceSource internal immutable priceSource15;
    PriceSource internal immutable priceSource16;
    PriceSource internal immutable priceSource17;
    PriceSource internal immutable priceSource18;
    PriceSource internal immutable priceSource19;
    PriceSource internal immutable priceSource20;
//    PriceSource internal immutable priceSource21;
//    PriceSource internal immutable priceSource22;
//    PriceSource internal immutable priceSource23;
//    PriceSource internal immutable priceSource24;
//    PriceSource internal immutable priceSource25;
//    PriceSource internal immutable priceSource26;
//    PriceSource internal immutable priceSource27;
//    PriceSource internal immutable priceSource28;
//    PriceSource internal immutable priceSource29;

    uint256 internal immutable fixedPrice00;
    uint256 internal immutable fixedPrice01;
    uint256 internal immutable fixedPrice02;
    uint256 internal immutable fixedPrice03;
    uint256 internal immutable fixedPrice04;
    uint256 internal immutable fixedPrice05;
    uint256 internal immutable fixedPrice06;
    uint256 internal immutable fixedPrice07;
    uint256 internal immutable fixedPrice08;
    uint256 internal immutable fixedPrice09;
    uint256 internal immutable fixedPrice10;
    uint256 internal immutable fixedPrice11;
    uint256 internal immutable fixedPrice12;
    uint256 internal immutable fixedPrice13;
    uint256 internal immutable fixedPrice14;
    uint256 internal immutable fixedPrice15;
    uint256 internal immutable fixedPrice16;
    uint256 internal immutable fixedPrice17;
    uint256 internal immutable fixedPrice18;
    uint256 internal immutable fixedPrice19;
    uint256 internal immutable fixedPrice20;
//    uint256 internal immutable fixedPrice21;
//    uint256 internal immutable fixedPrice22;
//    uint256 internal immutable fixedPrice23;
//    uint256 internal immutable fixedPrice24;
//    uint256 internal immutable fixedPrice25;
//    uint256 internal immutable fixedPrice26;
//    uint256 internal immutable fixedPrice27;
//    uint256 internal immutable fixedPrice28;
//    uint256 internal immutable fixedPrice29;

    address internal immutable uniswapMarket00;
    address internal immutable uniswapMarket01;
    address internal immutable uniswapMarket02;
    address internal immutable uniswapMarket03;
    address internal immutable uniswapMarket04;
    address internal immutable uniswapMarket05;
    address internal immutable uniswapMarket06;
    address internal immutable uniswapMarket07;
    address internal immutable uniswapMarket08;
    address internal immutable uniswapMarket09;
    address internal immutable uniswapMarket10;
    address internal immutable uniswapMarket11;
    address internal immutable uniswapMarket12;
    address internal immutable uniswapMarket13;
    address internal immutable uniswapMarket14;
    address internal immutable uniswapMarket15;
    address internal immutable uniswapMarket16;
    address internal immutable uniswapMarket17;
    address internal immutable uniswapMarket18;
    address internal immutable uniswapMarket19;
    address internal immutable uniswapMarket20;
//    address internal immutable uniswapMarket21;
//    address internal immutable uniswapMarket22;
//    address internal immutable uniswapMarket23;
//    address internal immutable uniswapMarket24;
//    address internal immutable uniswapMarket25;
//    address internal immutable uniswapMarket26;
//    address internal immutable uniswapMarket27;
//    address internal immutable uniswapMarket28;
//    address internal immutable uniswapMarket29;

    bool internal immutable isUniswapReversed00;
    bool internal immutable isUniswapReversed01;
    bool internal immutable isUniswapReversed02;
    bool internal immutable isUniswapReversed03;
    bool internal immutable isUniswapReversed04;
    bool internal immutable isUniswapReversed05;
    bool internal immutable isUniswapReversed06;
    bool internal immutable isUniswapReversed07;
    bool internal immutable isUniswapReversed08;
    bool internal immutable isUniswapReversed09;
    bool internal immutable isUniswapReversed10;
    bool internal immutable isUniswapReversed11;
    bool internal immutable isUniswapReversed12;
    bool internal immutable isUniswapReversed13;
    bool internal immutable isUniswapReversed14;
    bool internal immutable isUniswapReversed15;
    bool internal immutable isUniswapReversed16;
    bool internal immutable isUniswapReversed17;
    bool internal immutable isUniswapReversed18;
    bool internal immutable isUniswapReversed19;
    bool internal immutable isUniswapReversed20;
//    bool internal immutable isUniswapReversed21;
//    bool internal immutable isUniswapReversed22;
//    bool internal immutable isUniswapReversed23;
//    bool internal immutable isUniswapReversed24;
//    bool internal immutable isUniswapReversed25;
//    bool internal immutable isUniswapReversed26;
//    bool internal immutable isUniswapReversed27;
//    bool internal immutable isUniswapReversed28;
//    bool internal immutable isUniswapReversed29;

    /**
     * @notice Construct an immutable store of configs into the contract data
     * @param configs The configs for the supported assets
     */
    constructor(TokenConfig[] memory configs) public {
        require(configs.length <= maxTokens, "MAX_TOKENS");
        numTokens = configs.length;

        cToken00 = get(configs, 0).cToken;
        cToken01 = get(configs, 1).cToken;
        cToken02 = get(configs, 2).cToken;
        cToken03 = get(configs, 3).cToken;
        cToken04 = get(configs, 4).cToken;
        cToken05 = get(configs, 5).cToken;
        cToken06 = get(configs, 6).cToken;
        cToken07 = get(configs, 7).cToken;
        cToken08 = get(configs, 8).cToken;
        cToken09 = get(configs, 9).cToken;
        cToken10 = get(configs, 10).cToken;
        cToken11 = get(configs, 11).cToken;
        cToken12 = get(configs, 12).cToken;
        cToken13 = get(configs, 13).cToken;
        cToken14 = get(configs, 14).cToken;
        cToken15 = get(configs, 15).cToken;
        cToken16 = get(configs, 16).cToken;
        cToken17 = get(configs, 17).cToken;
        cToken18 = get(configs, 18).cToken;
        cToken19 = get(configs, 19).cToken;
        cToken20 = get(configs, 20).cToken;
//        cToken21 = get(configs, 21).cToken;
//        cToken22 = get(configs, 22).cToken;
//        cToken23 = get(configs, 23).cToken;
//        cToken24 = get(configs, 24).cToken;
//        cToken25 = get(configs, 25).cToken;
//        cToken26 = get(configs, 26).cToken;
//        cToken27 = get(configs, 27).cToken;
//        cToken28 = get(configs, 28).cToken;
//        cToken29 = get(configs, 29).cToken;

        underlying00 = get(configs, 0).underlying;
        underlying01 = get(configs, 1).underlying;
        underlying02 = get(configs, 2).underlying;
        underlying03 = get(configs, 3).underlying;
        underlying04 = get(configs, 4).underlying;
        underlying05 = get(configs, 5).underlying;
        underlying06 = get(configs, 6).underlying;
        underlying07 = get(configs, 7).underlying;
        underlying08 = get(configs, 8).underlying;
        underlying09 = get(configs, 9).underlying;
        underlying10 = get(configs, 10).underlying;
        underlying11 = get(configs, 11).underlying;
        underlying12 = get(configs, 12).underlying;
        underlying13 = get(configs, 13).underlying;
        underlying14 = get(configs, 14).underlying;
        underlying15 = get(configs, 15).underlying;
        underlying16 = get(configs, 16).underlying;
        underlying17 = get(configs, 17).underlying;
        underlying18 = get(configs, 18).underlying;
        underlying19 = get(configs, 19).underlying;
        underlying20 = get(configs, 20).underlying;
//        underlying21 = get(configs, 21).underlying;
//        underlying22 = get(configs, 22).underlying;
//        underlying23 = get(configs, 23).underlying;
//        underlying24 = get(configs, 24).underlying;
//        underlying25 = get(configs, 25).underlying;
//        underlying26 = get(configs, 26).underlying;
//        underlying27 = get(configs, 27).underlying;
//        underlying28 = get(configs, 28).underlying;
//        underlying29 = get(configs, 29).underlying;

        symbolHash00 = get(configs, 0).symbolHash;
        symbolHash01 = get(configs, 1).symbolHash;
        symbolHash02 = get(configs, 2).symbolHash;
        symbolHash03 = get(configs, 3).symbolHash;
        symbolHash04 = get(configs, 4).symbolHash;
        symbolHash05 = get(configs, 5).symbolHash;
        symbolHash06 = get(configs, 6).symbolHash;
        symbolHash07 = get(configs, 7).symbolHash;
        symbolHash08 = get(configs, 8).symbolHash;
        symbolHash09 = get(configs, 9).symbolHash;
        symbolHash10 = get(configs, 10).symbolHash;
        symbolHash11 = get(configs, 11).symbolHash;
        symbolHash12 = get(configs, 12).symbolHash;
        symbolHash13 = get(configs, 13).symbolHash;
        symbolHash14 = get(configs, 14).symbolHash;
        symbolHash15 = get(configs, 15).symbolHash;
        symbolHash16 = get(configs, 16).symbolHash;
        symbolHash17 = get(configs, 17).symbolHash;
        symbolHash18 = get(configs, 18).symbolHash;
        symbolHash19 = get(configs, 19).symbolHash;
        symbolHash20 = get(configs, 20).symbolHash;
//        symbolHash21 = get(configs, 21).symbolHash;
//        symbolHash22 = get(configs, 22).symbolHash;
//        symbolHash23 = get(configs, 23).symbolHash;
//        symbolHash24 = get(configs, 24).symbolHash;
//        symbolHash25 = get(configs, 25).symbolHash;
//        symbolHash26 = get(configs, 26).symbolHash;
//        symbolHash27 = get(configs, 27).symbolHash;
//        symbolHash28 = get(configs, 28).symbolHash;
//        symbolHash29 = get(configs, 29).symbolHash;

        baseUnit00 = get(configs, 0).baseUnit;
        baseUnit01 = get(configs, 1).baseUnit;
        baseUnit02 = get(configs, 2).baseUnit;
        baseUnit03 = get(configs, 3).baseUnit;
        baseUnit04 = get(configs, 4).baseUnit;
        baseUnit05 = get(configs, 5).baseUnit;
        baseUnit06 = get(configs, 6).baseUnit;
        baseUnit07 = get(configs, 7).baseUnit;
        baseUnit08 = get(configs, 8).baseUnit;
        baseUnit09 = get(configs, 9).baseUnit;
        baseUnit10 = get(configs, 10).baseUnit;
        baseUnit11 = get(configs, 11).baseUnit;
        baseUnit12 = get(configs, 12).baseUnit;
        baseUnit13 = get(configs, 13).baseUnit;
        baseUnit14 = get(configs, 14).baseUnit;
        baseUnit15 = get(configs, 15).baseUnit;
        baseUnit16 = get(configs, 16).baseUnit;
        baseUnit17 = get(configs, 17).baseUnit;
        baseUnit18 = get(configs, 18).baseUnit;
        baseUnit19 = get(configs, 19).baseUnit;
        baseUnit20 = get(configs, 20).baseUnit;
//        baseUnit21 = get(configs, 21).baseUnit;
//        baseUnit22 = get(configs, 22).baseUnit;
//        baseUnit23 = get(configs, 23).baseUnit;
//        baseUnit24 = get(configs, 24).baseUnit;
//        baseUnit25 = get(configs, 25).baseUnit;
//        baseUnit26 = get(configs, 26).baseUnit;
//        baseUnit27 = get(configs, 27).baseUnit;
//        baseUnit28 = get(configs, 28).baseUnit;
//        baseUnit29 = get(configs, 29).baseUnit;

        priceSource00 = get(configs, 0).priceSource;
        priceSource01 = get(configs, 1).priceSource;
        priceSource02 = get(configs, 2).priceSource;
        priceSource03 = get(configs, 3).priceSource;
        priceSource04 = get(configs, 4).priceSource;
        priceSource05 = get(configs, 5).priceSource;
        priceSource06 = get(configs, 6).priceSource;
        priceSource07 = get(configs, 7).priceSource;
        priceSource08 = get(configs, 8).priceSource;
        priceSource09 = get(configs, 9).priceSource;
        priceSource10 = get(configs, 10).priceSource;
        priceSource11 = get(configs, 11).priceSource;
        priceSource12 = get(configs, 12).priceSource;
        priceSource13 = get(configs, 13).priceSource;
        priceSource14 = get(configs, 14).priceSource;
        priceSource15 = get(configs, 15).priceSource;
        priceSource16 = get(configs, 16).priceSource;
        priceSource17 = get(configs, 17).priceSource;
        priceSource18 = get(configs, 18).priceSource;
        priceSource19 = get(configs, 19).priceSource;
        priceSource20 = get(configs, 20).priceSource;
//        priceSource21 = get(configs, 21).priceSource;
//        priceSource22 = get(configs, 22).priceSource;
//        priceSource23 = get(configs, 23).priceSource;
//        priceSource24 = get(configs, 24).priceSource;
//        priceSource25 = get(configs, 25).priceSource;
//        priceSource26 = get(configs, 26).priceSource;
//        priceSource27 = get(configs, 27).priceSource;
//        priceSource28 = get(configs, 28).priceSource;
//        priceSource29 = get(configs, 29).priceSource;

        fixedPrice00 = get(configs, 0).fixedPrice;
        fixedPrice01 = get(configs, 1).fixedPrice;
        fixedPrice02 = get(configs, 2).fixedPrice;
        fixedPrice03 = get(configs, 3).fixedPrice;
        fixedPrice04 = get(configs, 4).fixedPrice;
        fixedPrice05 = get(configs, 5).fixedPrice;
        fixedPrice06 = get(configs, 6).fixedPrice;
        fixedPrice07 = get(configs, 7).fixedPrice;
        fixedPrice08 = get(configs, 8).fixedPrice;
        fixedPrice09 = get(configs, 9).fixedPrice;
        fixedPrice10 = get(configs, 10).fixedPrice;
        fixedPrice11 = get(configs, 11).fixedPrice;
        fixedPrice12 = get(configs, 12).fixedPrice;
        fixedPrice13 = get(configs, 13).fixedPrice;
        fixedPrice14 = get(configs, 14).fixedPrice;
        fixedPrice15 = get(configs, 15).fixedPrice;
        fixedPrice16 = get(configs, 16).fixedPrice;
        fixedPrice17 = get(configs, 17).fixedPrice;
        fixedPrice18 = get(configs, 18).fixedPrice;
        fixedPrice19 = get(configs, 19).fixedPrice;
        fixedPrice20 = get(configs, 20).fixedPrice;
//        fixedPrice21 = get(configs, 21).fixedPrice;
//        fixedPrice22 = get(configs, 22).fixedPrice;
//        fixedPrice23 = get(configs, 23).fixedPrice;
//        fixedPrice24 = get(configs, 24).fixedPrice;
//        fixedPrice25 = get(configs, 25).fixedPrice;
//        fixedPrice26 = get(configs, 26).fixedPrice;
//        fixedPrice27 = get(configs, 27).fixedPrice;
//        fixedPrice28 = get(configs, 28).fixedPrice;
//        fixedPrice29 = get(configs, 29).fixedPrice;

        uniswapMarket00 = get(configs, 0).uniswapMarket;
        uniswapMarket01 = get(configs, 1).uniswapMarket;
        uniswapMarket02 = get(configs, 2).uniswapMarket;
        uniswapMarket03 = get(configs, 3).uniswapMarket;
        uniswapMarket04 = get(configs, 4).uniswapMarket;
        uniswapMarket05 = get(configs, 5).uniswapMarket;
        uniswapMarket06 = get(configs, 6).uniswapMarket;
        uniswapMarket07 = get(configs, 7).uniswapMarket;
        uniswapMarket08 = get(configs, 8).uniswapMarket;
        uniswapMarket09 = get(configs, 9).uniswapMarket;
        uniswapMarket10 = get(configs, 10).uniswapMarket;
        uniswapMarket11 = get(configs, 11).uniswapMarket;
        uniswapMarket12 = get(configs, 12).uniswapMarket;
        uniswapMarket13 = get(configs, 13).uniswapMarket;
        uniswapMarket14 = get(configs, 14).uniswapMarket;
        uniswapMarket15 = get(configs, 15).uniswapMarket;
        uniswapMarket16 = get(configs, 16).uniswapMarket;
        uniswapMarket17 = get(configs, 17).uniswapMarket;
        uniswapMarket18 = get(configs, 18).uniswapMarket;
        uniswapMarket19 = get(configs, 19).uniswapMarket;
        uniswapMarket20 = get(configs, 20).uniswapMarket;
//        uniswapMarket21 = get(configs, 21).uniswapMarket;
//        uniswapMarket22 = get(configs, 22).uniswapMarket;
//        uniswapMarket23 = get(configs, 23).uniswapMarket;
//        uniswapMarket24 = get(configs, 24).uniswapMarket;
//        uniswapMarket25 = get(configs, 25).uniswapMarket;
//        uniswapMarket26 = get(configs, 26).uniswapMarket;
//        uniswapMarket27 = get(configs, 27).uniswapMarket;
//        uniswapMarket28 = get(configs, 28).uniswapMarket;
//        uniswapMarket29 = get(configs, 29).uniswapMarket;

        isUniswapReversed00 = get(configs, 0).isUniswapReversed;
        isUniswapReversed01 = get(configs, 1).isUniswapReversed;
        isUniswapReversed02 = get(configs, 2).isUniswapReversed;
        isUniswapReversed03 = get(configs, 3).isUniswapReversed;
        isUniswapReversed04 = get(configs, 4).isUniswapReversed;
        isUniswapReversed05 = get(configs, 5).isUniswapReversed;
        isUniswapReversed06 = get(configs, 6).isUniswapReversed;
        isUniswapReversed07 = get(configs, 7).isUniswapReversed;
        isUniswapReversed08 = get(configs, 8).isUniswapReversed;
        isUniswapReversed09 = get(configs, 9).isUniswapReversed;
        isUniswapReversed10 = get(configs, 10).isUniswapReversed;
        isUniswapReversed11 = get(configs, 11).isUniswapReversed;
        isUniswapReversed12 = get(configs, 12).isUniswapReversed;
        isUniswapReversed13 = get(configs, 13).isUniswapReversed;
        isUniswapReversed14 = get(configs, 14).isUniswapReversed;
        isUniswapReversed15 = get(configs, 15).isUniswapReversed;
        isUniswapReversed16 = get(configs, 16).isUniswapReversed;
        isUniswapReversed17 = get(configs, 17).isUniswapReversed;
        isUniswapReversed18 = get(configs, 18).isUniswapReversed;
        isUniswapReversed19 = get(configs, 19).isUniswapReversed;
        isUniswapReversed20 = get(configs, 20).isUniswapReversed;
//        isUniswapReversed21 = get(configs, 21).isUniswapReversed;
//        isUniswapReversed22 = get(configs, 22).isUniswapReversed;
//        isUniswapReversed23 = get(configs, 23).isUniswapReversed;
//        isUniswapReversed24 = get(configs, 24).isUniswapReversed;
//        isUniswapReversed25 = get(configs, 25).isUniswapReversed;
//        isUniswapReversed26 = get(configs, 26).isUniswapReversed;
//        isUniswapReversed27 = get(configs, 27).isUniswapReversed;
//        isUniswapReversed28 = get(configs, 28).isUniswapReversed;
//        isUniswapReversed29 = get(configs, 29).isUniswapReversed;
    }

    function get(TokenConfig[] memory configs, uint i) internal pure returns (TokenConfig memory) {
        if (i < configs.length)
            return configs[i];
        return TokenConfig({
            cToken: address(0),
            underlying: address(0),
            symbolHash: bytes32(0),
            baseUnit: uint256(0),
            priceSource: PriceSource(0),
            fixedPrice: uint256(0),
            uniswapMarket: address(0),
            isUniswapReversed: false
        });
    }

    function getCTokenIndex(address cToken) internal view returns (uint) {
        if (cToken == cToken00) return 0;
        if (cToken == cToken01) return 1;
        if (cToken == cToken02) return 2;
        if (cToken == cToken03) return 3;
        if (cToken == cToken04) return 4;
        if (cToken == cToken05) return 5;
        if (cToken == cToken06) return 6;
        if (cToken == cToken07) return 7;
        if (cToken == cToken08) return 8;
        if (cToken == cToken09) return 9;
        if (cToken == cToken10) return 10;
        if (cToken == cToken11) return 11;
        if (cToken == cToken12) return 12;
        if (cToken == cToken13) return 13;
        if (cToken == cToken14) return 14;
        if (cToken == cToken15) return 15;
        if (cToken == cToken16) return 16;
        if (cToken == cToken17) return 17;
        if (cToken == cToken18) return 18;
        if (cToken == cToken19) return 19;
        if (cToken == cToken20) return 20;
//        if (cToken == cToken21) return 21;
//        if (cToken == cToken22) return 22;
//        if (cToken == cToken23) return 23;
//        if (cToken == cToken24) return 24;
//        if (cToken == cToken25) return 25;
//        if (cToken == cToken26) return 26;
//        if (cToken == cToken27) return 27;
//        if (cToken == cToken28) return 28;
//        if (cToken == cToken29) return 29;

        return uint(-1);
    }

    function getUnderlyingIndex(address underlying) internal view returns (uint) {
        if (underlying == underlying00) return 0;
        if (underlying == underlying01) return 1;
        if (underlying == underlying02) return 2;
        if (underlying == underlying03) return 3;
        if (underlying == underlying04) return 4;
        if (underlying == underlying05) return 5;
        if (underlying == underlying06) return 6;
        if (underlying == underlying07) return 7;
        if (underlying == underlying08) return 8;
        if (underlying == underlying09) return 9;
        if (underlying == underlying10) return 10;
        if (underlying == underlying11) return 11;
        if (underlying == underlying12) return 12;
        if (underlying == underlying13) return 13;
        if (underlying == underlying14) return 14;
        if (underlying == underlying15) return 15;
        if (underlying == underlying16) return 16;
        if (underlying == underlying17) return 17;
        if (underlying == underlying18) return 18;
        if (underlying == underlying19) return 19;
        if (underlying == underlying20) return 20;
//        if (underlying == underlying21) return 21;
//        if (underlying == underlying22) return 22;
//        if (underlying == underlying23) return 23;
//        if (underlying == underlying24) return 24;
//        if (underlying == underlying25) return 25;
//        if (underlying == underlying26) return 26;
//        if (underlying == underlying27) return 27;
//        if (underlying == underlying28) return 28;
//        if (underlying == underlying29) return 29;

        return uint(-1);
    }

    function getSymbolHashIndex(bytes32 symbolHash) internal view returns (uint) {
        if (symbolHash == symbolHash00) return 0;
        if (symbolHash == symbolHash01) return 1;
        if (symbolHash == symbolHash02) return 2;
        if (symbolHash == symbolHash03) return 3;
        if (symbolHash == symbolHash04) return 4;
        if (symbolHash == symbolHash05) return 5;
        if (symbolHash == symbolHash06) return 6;
        if (symbolHash == symbolHash07) return 7;
        if (symbolHash == symbolHash08) return 8;
        if (symbolHash == symbolHash09) return 9;
        if (symbolHash == symbolHash10) return 10;
        if (symbolHash == symbolHash11) return 11;
        if (symbolHash == symbolHash12) return 12;
        if (symbolHash == symbolHash13) return 13;
        if (symbolHash == symbolHash14) return 14;
        if (symbolHash == symbolHash15) return 15;
        if (symbolHash == symbolHash16) return 16;
        if (symbolHash == symbolHash17) return 17;
        if (symbolHash == symbolHash18) return 18;
        if (symbolHash == symbolHash19) return 19;
        if (symbolHash == symbolHash20) return 20;
//        if (symbolHash == symbolHash21) return 21;
//        if (symbolHash == symbolHash22) return 22;
//        if (symbolHash == symbolHash23) return 23;
//        if (symbolHash == symbolHash24) return 24;
//        if (symbolHash == symbolHash25) return 25;
//        if (symbolHash == symbolHash26) return 26;
//        if (symbolHash == symbolHash27) return 27;
//        if (symbolHash == symbolHash28) return 28;
//        if (symbolHash == symbolHash29) return 29;

        return uint(-1);
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < numTokens, "TOKEN_NOT_FOUND");

        if (i == 0) return TokenConfig({cToken: cToken00, underlying: underlying00, symbolHash: symbolHash00, baseUnit: baseUnit00, priceSource: priceSource00, fixedPrice: fixedPrice00, uniswapMarket: uniswapMarket00, isUniswapReversed: isUniswapReversed00});
        if (i == 1) return TokenConfig({cToken: cToken01, underlying: underlying01, symbolHash: symbolHash01, baseUnit: baseUnit01, priceSource: priceSource01, fixedPrice: fixedPrice01, uniswapMarket: uniswapMarket01, isUniswapReversed: isUniswapReversed01});
        if (i == 2) return TokenConfig({cToken: cToken02, underlying: underlying02, symbolHash: symbolHash02, baseUnit: baseUnit02, priceSource: priceSource02, fixedPrice: fixedPrice02, uniswapMarket: uniswapMarket02, isUniswapReversed: isUniswapReversed02});
        if (i == 3) return TokenConfig({cToken: cToken03, underlying: underlying03, symbolHash: symbolHash03, baseUnit: baseUnit03, priceSource: priceSource03, fixedPrice: fixedPrice03, uniswapMarket: uniswapMarket03, isUniswapReversed: isUniswapReversed03});
        if (i == 4) return TokenConfig({cToken: cToken04, underlying: underlying04, symbolHash: symbolHash04, baseUnit: baseUnit04, priceSource: priceSource04, fixedPrice: fixedPrice04, uniswapMarket: uniswapMarket04, isUniswapReversed: isUniswapReversed04});
        if (i == 5) return TokenConfig({cToken: cToken05, underlying: underlying05, symbolHash: symbolHash05, baseUnit: baseUnit05, priceSource: priceSource05, fixedPrice: fixedPrice05, uniswapMarket: uniswapMarket05, isUniswapReversed: isUniswapReversed05});
        if (i == 6) return TokenConfig({cToken: cToken06, underlying: underlying06, symbolHash: symbolHash06, baseUnit: baseUnit06, priceSource: priceSource06, fixedPrice: fixedPrice06, uniswapMarket: uniswapMarket06, isUniswapReversed: isUniswapReversed06});
        if (i == 7) return TokenConfig({cToken: cToken07, underlying: underlying07, symbolHash: symbolHash07, baseUnit: baseUnit07, priceSource: priceSource07, fixedPrice: fixedPrice07, uniswapMarket: uniswapMarket07, isUniswapReversed: isUniswapReversed07});
        if (i == 8) return TokenConfig({cToken: cToken08, underlying: underlying08, symbolHash: symbolHash08, baseUnit: baseUnit08, priceSource: priceSource08, fixedPrice: fixedPrice08, uniswapMarket: uniswapMarket08, isUniswapReversed: isUniswapReversed08});
        if (i == 9) return TokenConfig({cToken: cToken09, underlying: underlying09, symbolHash: symbolHash09, baseUnit: baseUnit09, priceSource: priceSource09, fixedPrice: fixedPrice09, uniswapMarket: uniswapMarket09, isUniswapReversed: isUniswapReversed09});

        if (i == 10) return TokenConfig({cToken: cToken10, underlying: underlying10, symbolHash: symbolHash10, baseUnit: baseUnit10, priceSource: priceSource10, fixedPrice: fixedPrice10, uniswapMarket: uniswapMarket10, isUniswapReversed: isUniswapReversed10});
        if (i == 11) return TokenConfig({cToken: cToken11, underlying: underlying11, symbolHash: symbolHash11, baseUnit: baseUnit11, priceSource: priceSource11, fixedPrice: fixedPrice11, uniswapMarket: uniswapMarket11, isUniswapReversed: isUniswapReversed11});
        if (i == 12) return TokenConfig({cToken: cToken12, underlying: underlying12, symbolHash: symbolHash12, baseUnit: baseUnit12, priceSource: priceSource12, fixedPrice: fixedPrice12, uniswapMarket: uniswapMarket12, isUniswapReversed: isUniswapReversed12});
        if (i == 13) return TokenConfig({cToken: cToken13, underlying: underlying13, symbolHash: symbolHash13, baseUnit: baseUnit13, priceSource: priceSource13, fixedPrice: fixedPrice13, uniswapMarket: uniswapMarket13, isUniswapReversed: isUniswapReversed13});
        if (i == 14) return TokenConfig({cToken: cToken14, underlying: underlying14, symbolHash: symbolHash14, baseUnit: baseUnit14, priceSource: priceSource14, fixedPrice: fixedPrice14, uniswapMarket: uniswapMarket14, isUniswapReversed: isUniswapReversed14});
        if (i == 15) return TokenConfig({cToken: cToken15, underlying: underlying15, symbolHash: symbolHash15, baseUnit: baseUnit15, priceSource: priceSource15, fixedPrice: fixedPrice15, uniswapMarket: uniswapMarket15, isUniswapReversed: isUniswapReversed15});
        if (i == 16) return TokenConfig({cToken: cToken16, underlying: underlying16, symbolHash: symbolHash16, baseUnit: baseUnit16, priceSource: priceSource16, fixedPrice: fixedPrice16, uniswapMarket: uniswapMarket16, isUniswapReversed: isUniswapReversed16});
        if (i == 17) return TokenConfig({cToken: cToken17, underlying: underlying17, symbolHash: symbolHash17, baseUnit: baseUnit17, priceSource: priceSource17, fixedPrice: fixedPrice17, uniswapMarket: uniswapMarket17, isUniswapReversed: isUniswapReversed17});
        if (i == 18) return TokenConfig({cToken: cToken18, underlying: underlying18, symbolHash: symbolHash18, baseUnit: baseUnit18, priceSource: priceSource18, fixedPrice: fixedPrice18, uniswapMarket: uniswapMarket18, isUniswapReversed: isUniswapReversed18});
        if (i == 19) return TokenConfig({cToken: cToken19, underlying: underlying19, symbolHash: symbolHash19, baseUnit: baseUnit19, priceSource: priceSource19, fixedPrice: fixedPrice19, uniswapMarket: uniswapMarket19, isUniswapReversed: isUniswapReversed19});

        if (i == 20) return TokenConfig({cToken: cToken20, underlying: underlying20, symbolHash: symbolHash20, baseUnit: baseUnit20, priceSource: priceSource20, fixedPrice: fixedPrice20, uniswapMarket: uniswapMarket20, isUniswapReversed: isUniswapReversed20});
//        if (i == 21) return TokenConfig({cToken: cToken21, underlying: underlying21, symbolHash: symbolHash21, baseUnit: baseUnit21, priceSource: priceSource21, fixedPrice: fixedPrice21, uniswapMarket: uniswapMarket21, isUniswapReversed: isUniswapReversed21});
//        if (i == 22) return TokenConfig({cToken: cToken22, underlying: underlying22, symbolHash: symbolHash22, baseUnit: baseUnit22, priceSource: priceSource22, fixedPrice: fixedPrice22, uniswapMarket: uniswapMarket22, isUniswapReversed: isUniswapReversed22});
//        if (i == 23) return TokenConfig({cToken: cToken23, underlying: underlying23, symbolHash: symbolHash23, baseUnit: baseUnit23, priceSource: priceSource23, fixedPrice: fixedPrice23, uniswapMarket: uniswapMarket23, isUniswapReversed: isUniswapReversed23});
//        if (i == 24) return TokenConfig({cToken: cToken24, underlying: underlying24, symbolHash: symbolHash24, baseUnit: baseUnit24, priceSource: priceSource24, fixedPrice: fixedPrice24, uniswapMarket: uniswapMarket24, isUniswapReversed: isUniswapReversed24});
//        if (i == 25) return TokenConfig({cToken: cToken25, underlying: underlying25, symbolHash: symbolHash25, baseUnit: baseUnit25, priceSource: priceSource25, fixedPrice: fixedPrice25, uniswapMarket: uniswapMarket25, isUniswapReversed: isUniswapReversed25});
//        if (i == 26) return TokenConfig({cToken: cToken26, underlying: underlying26, symbolHash: symbolHash26, baseUnit: baseUnit26, priceSource: priceSource26, fixedPrice: fixedPrice26, uniswapMarket: uniswapMarket26, isUniswapReversed: isUniswapReversed26});
//        if (i == 27) return TokenConfig({cToken: cToken27, underlying: underlying27, symbolHash: symbolHash27, baseUnit: baseUnit27, priceSource: priceSource27, fixedPrice: fixedPrice27, uniswapMarket: uniswapMarket27, isUniswapReversed: isUniswapReversed27});
//        if (i == 28) return TokenConfig({cToken: cToken28, underlying: underlying28, symbolHash: symbolHash28, baseUnit: baseUnit28, priceSource: priceSource28, fixedPrice: fixedPrice28, uniswapMarket: uniswapMarket28, isUniswapReversed: isUniswapReversed28});
//        if (i == 29) return TokenConfig({cToken: cToken29, underlying: underlying29, symbolHash: symbolHash29, baseUnit: baseUnit29, priceSource: priceSource29, fixedPrice: fixedPrice29, uniswapMarket: uniswapMarket29, isUniswapReversed: isUniswapReversed29});
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    /**
     * @notice Get the config for the symbolHash
     * @param symbolHash The keccack256 of the symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbolHash(bytes32 symbolHash) public view returns (TokenConfig memory) {
        uint index = getSymbolHashIndex(symbolHash);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        revert("TOKEN_NOT_FOUND");
    }

    /**
     * @notice Get the config for the cToken
     * @dev If a config for the cToken is not found, falls back to searching for the underlying.
     * @param cToken The address of the cToken of the config to get
     * @return The config object
     */
    function getTokenConfigByCToken(address cToken) public view returns (TokenConfig memory) {
        uint index = getCTokenIndex(cToken);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(CErc20(cToken).underlying());
    }

    /**
     * @notice Get the config for an underlying asset
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying) public view returns (TokenConfig memory) {
        uint index = getUnderlyingIndex(underlying);
        if (index != uint(-1)) {
            return getTokenConfig(index);
        }

      revert("TOKEN_NOT_FOUND");
    }
}

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// File: contracts/Uniswap/UniswapLib.sol


pragma solidity ^0.6.10;

// Based on code from https://github.com/Uniswap/uniswap-v2-periphery

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
    function decode112with18(uq112x112 memory self) internal pure returns (uint) {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint(self._x) / 5192296858534827;
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: contracts/UniswapTWAPProvider.sol

pragma solidity ^0.6.12;





abstract contract UniswapTWAPProvider is PowerOracleStorageV1, UniswapConfig {
  using FixedPoint for *;
  using SafeMath for uint256;

  /// @notice The number of wei in 1 ETH
  uint public constant ethBaseUnit = 1e18;

  /// @notice A common scaling factor to maintain precision
  uint public constant expScale = 1e18;

  bytes32 internal constant cvpHash = keccak256(abi.encodePacked("CVP"));
  bytes32 internal constant ethHash = keccak256(abi.encodePacked("ETH"));
  bytes32 internal constant rotateHash = keccak256(abi.encodePacked("rotate"));

  /// @notice The event emitted when anchor price is updated
  event AnchorPriceUpdated(string symbol, bytes32 indexed symbolHash, uint anchorPrice, uint oldTimestamp, uint newTimestamp);

  /// @notice The event emitted when the uniswap window changes
  event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

  /// @notice The minimum amount of time in seconds required for the old uniswap price accumulator to be replaced
  uint public immutable anchorPeriod;

  constructor(
    uint anchorPeriod_,
    TokenConfig[] memory configs
  ) public {
    anchorPeriod = anchorPeriod_;

    for (uint i = 0; i < configs.length; i++) {
      TokenConfig memory config = configs[i];
      require(config.baseUnit > 0, "BASE_UNIT_IS_NULL");
      address uniswapMarket = config.uniswapMarket;
      if (config.priceSource == PriceSource.REPORTER) {
        require(uniswapMarket != address(0), "MARKET_IS_NULL");
        bytes32 symbolHash = config.symbolHash;
        uint cumulativePrice = currentCumulativePrice(config);
        oldObservations[symbolHash].timestamp = block.timestamp;
        newObservations[symbolHash].timestamp = block.timestamp;
        oldObservations[symbolHash].acc = cumulativePrice;
        newObservations[symbolHash].acc = cumulativePrice;
        emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
      } else {
        require(uniswapMarket == address(0), "MARKET_IS_NOT_NULL");
      }
    }
  }

  /**
    * @dev Fetches the current token/eth price accumulator from uniswap.
    */
  function currentCumulativePrice(TokenConfig memory config) internal view returns (uint) {
    (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
    if (config.isUniswapReversed) {
      return cumulativePrice1;
    } else {
      return cumulativePrice0;
    }
  }

  /**
   * @dev Fetches the current eth/usd price from uniswap, with 6 decimals of precision.
   *  Conversion factor is 1e18 for eth/usdc market, since we decode uniswap price statically with 18 decimals.
   */
  function fetchEthPrice() internal returns (uint) {
    return fetchAnchorPrice("ETH", getTokenConfigBySymbolHash(ethHash), ethBaseUnit);
  }

  function fetchCvpPrice(uint256 ethPrice) internal returns (uint) {
    return fetchAnchorPrice("CVP", getTokenConfigBySymbolHash(cvpHash), ethPrice);
  }

  /**
   * @dev Fetches the current token/usd price from uniswap, with 6 decimals of precision.
   * @param conversionFactor 1e18 if seeking the ETH price, and a 6 decimal ETH-USDC price in the case of other assets
   */
  function fetchAnchorPrice(string memory symbol, TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
    (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);

    // This should be impossible, but better safe than sorry
    require(block.timestamp > oldTimestamp, "TOO_EARLY");
    uint timeElapsed = block.timestamp - oldTimestamp;

    // Calculate uniswap time-weighted average price
    // Underflow is a property of the accumulators: https://uniswap.org/audit.html#orgc9b3190
    FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
    uint rawUniswapPriceMantissa = priceAverage.decode112with18();
    uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
    uint anchorPrice;

    // Adjust rawUniswapPrice according to the units of the non-ETH asset
    // In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels
    if (config.isUniswapReversed) {
      // unscaledPriceMantissa * ethBaseUnit / config.baseUnit / expScale, but we simplify bc ethBaseUnit == expScale
      anchorPrice = unscaledPriceMantissa / config.baseUnit;
    } else {
      anchorPrice = mul(unscaledPriceMantissa, config.baseUnit) / ethBaseUnit / expScale;
    }

    emit AnchorPriceUpdated(symbol, keccak256(abi.encodePacked(symbol)), anchorPrice, oldTimestamp, block.timestamp);

    return anchorPrice;
  }

  /**
   * @dev Get time-weighted average prices for a token at the current timestamp.
   *  Update new and old observations of lagging window if period elapsed.
   */
  function pokeWindowValues(TokenConfig memory config) internal returns (uint, uint, uint) {
    bytes32 symbolHash = config.symbolHash;
    uint cumulativePrice = currentCumulativePrice(config);

    Observation memory newObservation = newObservations[symbolHash];

    // Update new and old observations if elapsed time is greater than or equal to anchor period
    uint timeElapsed = block.timestamp - newObservation.timestamp;
    if (timeElapsed >= anchorPeriod) {
      oldObservations[symbolHash].timestamp = newObservation.timestamp;
      oldObservations[symbolHash].acc = newObservation.acc;

      newObservations[symbolHash].timestamp = block.timestamp;
      newObservations[symbolHash].acc = cumulativePrice;
      emit UniswapWindowUpdated(config.symbolHash, newObservation.timestamp, block.timestamp, newObservation.acc, cumulativePrice);
    }
    return (cumulativePrice, oldObservations[symbolHash].acc, oldObservations[symbolHash].timestamp);
  }

  /// @dev Overflow proof multiplication
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) return 0;
    uint c = a * b;
    require(c / a == b, "MUL_OVERFLOW");
    return c;
  }
}

// File: contracts/utils/PowerPausable.sol

// A modified version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/utils/Pausable.sol
// with no GSN Context support and no construct

pragma solidity ^0.6.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PowerPausable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "PAUSED");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(_paused, "NOT_PAUSED");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

// File: contracts/utils/PowerOwnable.sol

// A modified version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/access/Ownable.sol
// with no GSN Context support and _transferOwnership internal method

pragma solidity ^0.6.0;

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
contract PowerOwnable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "NOT_THE_OWNER");
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "NEW_OWNER_IS_NULL");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "NEW_OWNER_IS_NULL");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity >=0.6.0 <0.8.0;

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
}

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity ^0.6.12;

interface IUniswapV2Router02 {
  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

// File: contracts/interfaces/IEACAggregatorProxy.sol

pragma solidity ^0.6.12;

interface IEACAggregatorProxy {
  function latestAnswer() external view returns (int256);
}

// File: contracts/interfaces/IPowerPokeStaking.sol

pragma solidity ^0.6.12;

interface IPowerPokeStaking {
  enum UserStatus { UNAUTHORIZED, HDH, MEMBER }

  /*** User Interface ***/
  function createDeposit(uint256 userId_, uint256 amount_) external;

  function executeDeposit(uint256 userId_) external;

  function createWithdrawal(uint256 userId_, uint256 amount_) external;

  function executeWithdrawal(uint256 userId_, address to_) external;

  function createUser(
    address adminKey_,
    address reporterKey_,
    uint256 depositAmount
  ) external;

  function updateUser(
    uint256 userId,
    address adminKey_,
    address reporterKey_
  ) external;

  /*** Owner Interface ***/
  function setSlasher(address slasher) external;

  function setSlashingPct(uint256 slasherRewardPct, uint256 reservoirRewardPct) external;

  function setTimeouts(uint256 depositTimeout_, uint256 withdrawalTimeout_) external;

  function pause() external;

  function unpause() external;

  /*** PowerOracle Contract Interface ***/
  function slashHDH(uint256 slasherId_, uint256 times_) external;

  /*** Permissionless Interface ***/
  function setHDH(uint256 candidateId_) external;

  /*** Viewers ***/
  function getHDHID() external view returns (uint256);

  function getHighestDeposit() external view returns (uint256);

  function getDepositOf(uint256 userId) external view returns (uint256);

  function getPendingDepositOf(uint256 userId_) external view returns (uint256 balance, uint256 timeout);

  function getPendingWithdrawalOf(uint256 userId_) external view returns (uint256 balance, uint256 timeout);

  function getSlashAmount(uint256 slasheeId_, uint256 times_)
    external
    view
    returns (
      uint256 slasherReward,
      uint256 reservoirReward,
      uint256 totalSlash
    );

  function getUserStatus(
    uint256 userId_,
    address reporterKey_,
    uint256 minDeposit_
  ) external view returns (UserStatus);

  function authorizeHDH(uint256 userId_, address reporterKey_) external view;

  function authorizeNonHDH(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) external view;

  function authorizeMember(
    uint256 userId_,
    address reporterKey_,
    uint256 minDeposit_
  ) external view;

  function requireValidAdminKey(uint256 userId_, address adminKey_) external view;

  function requireValidAdminOrPokerKey(uint256 userId_, address adminOrPokerKey_) external view;

  function getLastDepositChange(uint256 userId_) external view returns (uint256);
}

// File: contracts/PowerPokeStakingStorageV1.sol

pragma solidity ^0.6.12;

contract PowerPokeStakingStorageV1 {
  struct User {
    address adminKey;
    address pokerKey;
    uint256 deposit;
    uint256 pendingDeposit;
    uint256 pendingDepositTimeout;
    uint256 pendingWithdrawal;
    uint256 pendingWithdrawalTimeout;
  }

  /// @notice The deposit timeout in seconds
  uint256 public depositTimeout;

  /// @notice The withdrawal timeout in seconds
  uint256 public withdrawalTimeout;

  /// @notice The reservoir which holds CVP tokens
  address public reservoir;

  /// @notice The slasher address (PowerPoke)
  address public slasher;

  /// @notice The total amount of all deposits
  uint256 public totalDeposit;

  /// @notice The share of a slasher in slashed deposit per one outdated asset (1 eth == 1%)
  uint256 public slasherSlashingRewardPct;

  /// @notice The share of the protocol(reservoir) in slashed deposit per one outdated asset (1 eth == 1%)
  uint256 public protocolSlashingRewardPct;

  /// @notice The incremented user ID counter. Is updated only within createUser function call
  uint256 public userIdCounter;

  /// @dev The highest deposit. Usually of the current reporterId. Is safe to be outdated.
  uint256 internal _highestDeposit;

  /// @dev The current highest deposit holder ID.
  uint256 internal _hdhId;

  /// @notice User details by it's ID
  mapping(uint256 => User) public users;

  /// @dev Last deposit change timestamp by user ID
  mapping(uint256 => uint256) internal _lastDepositChange;
}

// File: contracts/PowerPokeStaking.sol

pragma solidity ^0.6.12;








contract PowerPokeStaking is IPowerPokeStaking, PowerOwnable, Initializable, PowerPausable, PowerPokeStakingStorageV1 {
  using SafeMath for uint256;

  uint256 public constant HUNDRED_PCT = 100 ether;

  /// @notice The event emitted when a new user is created
  event CreateUser(uint256 indexed userId, address indexed adminKey, address indexed pokerKey, uint256 initialDeposit);

  /// @notice The event emitted when an existing user is updated
  event UpdateUser(uint256 indexed userId, address indexed adminKey, address indexed pokerKey);

  /// @notice The event emitted when the user creates pending deposit
  event CreateDeposit(
    uint256 indexed userId,
    address indexed depositor,
    uint256 pendingTimeout,
    uint256 amount,
    uint256 pendingDepositAfter
  );

  /// @notice The event emitted when the user transfers his deposit from pending to the active
  event ExecuteDeposit(uint256 indexed userId, uint256 pendingTimeout, uint256 amount, uint256 depositAfter);

  /// @notice The event emitted when the user creates pending deposit
  event CreateWithdrawal(
    uint256 indexed userId,
    uint256 pendingTimeout,
    uint256 amount,
    uint256 pendingWithdrawalAfter,
    uint256 depositAfter
  );

  /// @notice The event emitted when a valid admin key withdraws funds from
  event ExecuteWithdrawal(uint256 indexed userId, address indexed to, uint256 pendingTimeout, uint256 amount);

  /// @notice The event emitted when the owner sets new slashing percent values, where 1ether == 1%
  event SetSlashingPct(uint256 slasherSlashingRewardPct, uint256 protocolSlashingRewardPct);

  /// @notice The event emitted when the owner sets new deposit and withdrawal timeouts
  event SetTimeouts(uint256 depositTimeout, uint256 withdrawalTimeout);

  /// @notice The event emitted when the owner sets a new PowerOracle linked contract
  event SetSlasher(address powerOracle);

  /// @notice The event emitted when an arbitrary user fixes an outdated reporter userId record
  event SetReporter(uint256 indexed reporterId, address indexed msgSender);

  /// @notice The event emitted when the PowerOracle contract requests to slash a user with the given ID
  event Slash(uint256 indexed slasherId, uint256 indexed reporterId, uint256 slasherReward, uint256 reservoirReward);

  /// @notice The event emitted when the existing reporter is replaced with a new one due some reason
  event ReporterChange(
    uint256 indexed prevId,
    uint256 indexed nextId,
    uint256 highestDepositPrev,
    uint256 actualDepositPrev,
    uint256 actualDepositNext
  );

  /// @notice CVP token address
  IERC20 public immutable CVP_TOKEN;

  constructor(address cvpToken_) public {
    require(cvpToken_ != address(0), "CVP_ADDR_IS_0");

    CVP_TOKEN = IERC20(cvpToken_);
  }

  function initialize(
    address owner_,
    address reservoir_,
    address slasher_,
    uint256 slasherSlashingRewardPct_,
    uint256 reservoirSlashingRewardPct_,
    uint256 depositTimeout_,
    uint256 withdrawTimeout_
  ) external initializer {
    require(depositTimeout_ > 0, "DEPOSIT_TIMEOUT_IS_0");
    require(withdrawTimeout_ > 0, "WITHDRAW_TIMEOUT_IS_0");

    _transferOwnership(owner_);
    reservoir = reservoir_;
    slasher = slasher_;
    slasherSlashingRewardPct = slasherSlashingRewardPct_;
    protocolSlashingRewardPct = reservoirSlashingRewardPct_;
    depositTimeout = depositTimeout_;
    withdrawalTimeout = withdrawTimeout_;
  }

  /*** User Interface ***/

  /**
   * @notice An arbitrary user deposits CVP stake to the contract for the given user ID
   * @param userId_ The user ID to make deposit for
   * @param amount_ The amount in CVP tokens to deposit
   */
  function createDeposit(uint256 userId_, uint256 amount_) external override whenNotPaused {
    require(amount_ > 0, "MISSING_AMOUNT");

    User storage user = users[userId_];

    require(user.adminKey != address(0), "INVALID_USER");

    _createDeposit(userId_, amount_);
  }

  function _createDeposit(uint256 userId_, uint256 amount_) internal {
    User storage user = users[userId_];

    uint256 pendingDepositAfter = user.pendingDeposit.add(amount_);
    uint256 timeout = block.timestamp.add(depositTimeout);

    user.pendingDeposit = pendingDepositAfter;
    user.pendingDepositTimeout = timeout;

    emit CreateDeposit(userId_, msg.sender, timeout, amount_, pendingDepositAfter);
    CVP_TOKEN.transferFrom(msg.sender, address(this), amount_);
  }

  function executeDeposit(uint256 userId_) external override {
    User storage user = users[userId_];
    uint256 amount = user.pendingDeposit;
    uint256 pendingDepositTimeout = user.pendingDepositTimeout;

    // check
    require(user.adminKey == msg.sender, "ONLY_ADMIN_ALLOWED");
    require(amount > 0, "NO_PENDING_DEPOSIT");
    require(block.timestamp >= pendingDepositTimeout, "TIMEOUT_NOT_PASSED");

    // increment deposit
    uint256 depositAfter = user.deposit.add(amount);
    user.deposit = depositAfter;
    totalDeposit = totalDeposit.add(amount);

    // reset pending deposit
    user.pendingDeposit = 0;
    user.pendingDepositTimeout = 0;

    _lastDepositChange[userId_] = block.timestamp;

    _trySetHighestDepositHolder(userId_, depositAfter);

    emit ExecuteDeposit(userId_, pendingDepositTimeout, amount, depositAfter);
  }

  function _trySetHighestDepositHolder(uint256 candidateId_, uint256 candidateDepositAfter_) internal {
    uint256 prevHdhID = _hdhId;
    uint256 prevDeposit = users[prevHdhID].deposit;

    if (candidateDepositAfter_ > prevDeposit && prevHdhID != candidateId_) {
      emit ReporterChange(prevHdhID, candidateId_, _highestDeposit, users[prevHdhID].deposit, candidateDepositAfter_);

      _highestDeposit = candidateDepositAfter_;
      _hdhId = candidateId_;
    }
  }

  /**
   * @notice A valid users admin key withdraws the deposited stake form the contract
   * @param userId_ The user ID to withdraw deposit from
   * @param amount_ The amount in CVP tokens to withdraw
   */
  function createWithdrawal(uint256 userId_, uint256 amount_) external override {
    require(amount_ > 0, "MISSING_AMOUNT");

    User storage user = users[userId_];
    require(msg.sender == user.adminKey, "ONLY_ADMIN_ALLOWED");

    // decrement deposit
    uint256 depositBefore = user.deposit;
    require(amount_ <= depositBefore, "AMOUNT_EXCEEDS_DEPOSIT");

    uint256 depositAfter = depositBefore - amount_;
    user.deposit = depositAfter;
    totalDeposit = totalDeposit.sub(amount_);

    // increment pending withdrawal
    uint256 pendingWithdrawalAfter = user.pendingWithdrawal.add(amount_);
    uint256 timeout = block.timestamp.add(withdrawalTimeout);
    user.pendingWithdrawal = pendingWithdrawalAfter;
    user.pendingWithdrawalTimeout = timeout;

    _lastDepositChange[userId_] = block.timestamp;

    emit CreateWithdrawal(userId_, timeout, amount_, pendingWithdrawalAfter, depositAfter);
  }

  function executeWithdrawal(uint256 userId_, address to_) external override {
    require(to_ != address(0), "CANT_WITHDRAW_TO_0");

    User storage user = users[userId_];

    uint256 pendingWithdrawalTimeout = user.pendingWithdrawalTimeout;
    uint256 amount = user.pendingWithdrawal;

    require(msg.sender == user.adminKey, "ONLY_ADMIN_ALLOWED");
    require(amount > 0, "NO_PENDING_WITHDRAWAL");
    require(block.timestamp >= pendingWithdrawalTimeout, "TIMEOUT_NOT_PASSED");

    user.pendingWithdrawal = 0;
    user.pendingWithdrawalTimeout = 0;

    emit ExecuteWithdrawal(userId_, to_, pendingWithdrawalTimeout, amount);
    CVP_TOKEN.transfer(to_, amount);
  }

  /**
   * @notice Creates a new user ID and stores the given keys
   * @param adminKey_ The admin key for the new user
   * @param pokerKey_ The poker key for the new user
   * @param initialDeposit_ The initial deposit to be transferred to this contract
   */
  function createUser(
    address adminKey_,
    address pokerKey_,
    uint256 initialDeposit_
  ) external override whenNotPaused {
    uint256 userId = ++userIdCounter;

    users[userId] = User(adminKey_, pokerKey_, 0, 0, 0, 0, 0);

    emit CreateUser(userId, adminKey_, pokerKey_, initialDeposit_);

    if (initialDeposit_ > 0) {
      _createDeposit(userId, initialDeposit_);
    }
  }

  /**
   * @notice Updates an existing user, only the current adminKey is eligible calling this method.
   * @param adminKey_ The new admin key for the user
   * @param pokerKey_ The new poker key for the user
   */
  function updateUser(
    uint256 userId_,
    address adminKey_,
    address pokerKey_
  ) external override {
    User storage user = users[userId_];
    require(msg.sender == user.adminKey, "ONLY_ADMIN_ALLOWED");

    if (adminKey_ != user.adminKey) {
      user.adminKey = adminKey_;
    }
    if (pokerKey_ != user.pokerKey) {
      user.pokerKey = pokerKey_;
    }

    emit UpdateUser(userId_, adminKey_, pokerKey_);
  }

  /*** SLASHER INTERFACE ***/

  /**
   * @notice Slashes the current reporter if it did not make poke() call during the given report interval
   * @param slasherId_ The slasher ID
   * @param times_ The multiplier for a single slashing percent
   */
  function slashHDH(uint256 slasherId_, uint256 times_) external virtual override {
    require(msg.sender == slasher, "ONLY_SLASHER_ALLOWED");

    uint256 hdhId = _hdhId;
    uint256 hdhDeposit = users[hdhId].deposit;

    (uint256 slasherReward, uint256 reservoirReward, ) = getSlashAmount(hdhId, times_);

    uint256 amount = slasherReward.add(reservoirReward);
    require(hdhDeposit >= amount, "INSUFFICIENT_HDH_DEPOSIT");

    // users[reporterId].deposit = reporterDeposit - slasherReward - reservoirReward;
    users[hdhId].deposit = hdhDeposit.sub(amount);

    // totalDeposit = totalDeposit - reservoirReward; (slasherReward is kept on the contract)
    totalDeposit = totalDeposit.sub(reservoirReward);

    if (slasherReward > 0) {
      // uint256 slasherDepositAfter = users[slasherId_].deposit + slasherReward
      uint256 slasherDepositAfter = users[slasherId_].deposit.add(slasherReward);
      users[slasherId_].deposit = slasherDepositAfter;
      _trySetHighestDepositHolder(slasherId_, slasherDepositAfter);
    }

    if (reservoirReward > 0) {
      CVP_TOKEN.transfer(reservoir, reservoirReward);
    }

    emit Slash(slasherId_, hdhId, slasherReward, reservoirReward);
  }

  /*** OWNER INTERFACE ***/

  /**
   * @notice The owner sets a new slasher address
   * @param slasher_ The slasher address to set
   */
  function setSlasher(address slasher_) external override onlyOwner {
    slasher = slasher_;
    emit SetSlasher(slasher_);
  }

  /**
   * @notice The owner sets the new slashing percent values
   * @param slasherSlashingRewardPct_ The slasher share will be accrued on the slasher's deposit
   * @param protocolSlashingRewardPct_ The protocol share will immediately be transferred to reservoir
   */
  function setSlashingPct(uint256 slasherSlashingRewardPct_, uint256 protocolSlashingRewardPct_)
    external
    override
    onlyOwner
  {
    require(slasherSlashingRewardPct_.add(protocolSlashingRewardPct_) <= HUNDRED_PCT, "INVALID_SUM");

    slasherSlashingRewardPct = slasherSlashingRewardPct_;
    protocolSlashingRewardPct = protocolSlashingRewardPct_;
    emit SetSlashingPct(slasherSlashingRewardPct_, protocolSlashingRewardPct_);
  }

  function setTimeouts(uint256 depositTimeout_, uint256 withdrawalTimeout_) external override onlyOwner {
    depositTimeout = depositTimeout_;
    withdrawalTimeout = withdrawalTimeout_;
    emit SetTimeouts(depositTimeout_, withdrawalTimeout_);
  }

  /**
   * @notice The owner pauses poke*-operations
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice The owner unpauses poke*-operations
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /*** PERMISSIONLESS INTERFACE ***/

  /**
   * @notice Set a given address as a reporter if his deposit is higher than the current highestDeposit
   * @param candidateId_ Te candidate address to try
   */
  function setHDH(uint256 candidateId_) external override {
    uint256 candidateDeposit = users[candidateId_].deposit;
    uint256 prevHdhId = _hdhId;
    uint256 currentReporterDeposit = users[prevHdhId].deposit;

    require(candidateDeposit > currentReporterDeposit, "INSUFFICIENT_CANDIDATE_DEPOSIT");

    emit ReporterChange(prevHdhId, candidateId_, _highestDeposit, currentReporterDeposit, candidateDeposit);
    emit SetReporter(candidateId_, msg.sender);

    _highestDeposit = candidateDeposit;
    _hdhId = candidateId_;
  }

  /*** VIEWERS ***/

  function getHDHID() external view override returns (uint256) {
    return _hdhId;
  }

  function getHighestDeposit() external view override returns (uint256) {
    return _highestDeposit;
  }

  function getDepositOf(uint256 userId_) external view override returns (uint256) {
    return users[userId_].deposit;
  }

  function getPendingDepositOf(uint256 userId_) external view override returns (uint256 balance, uint256 timeout) {
    return (users[userId_].pendingDeposit, users[userId_].pendingDepositTimeout);
  }

  function getPendingWithdrawalOf(uint256 userId_) external view override returns (uint256 balance, uint256 timeout) {
    return (users[userId_].pendingWithdrawal, users[userId_].pendingWithdrawalTimeout);
  }

  function getSlashAmount(uint256 slasheeId_, uint256 times_)
    public
    view
    override
    returns (
      uint256 slasherReward,
      uint256 reservoirReward,
      uint256 totalSlash
    )
  {
    uint256 product = times_.mul(users[slasheeId_].deposit);
    // slasherReward = times_ * reporterDeposit * slasherRewardPct / HUNDRED_PCT;
    slasherReward = product.mul(slasherSlashingRewardPct) / HUNDRED_PCT;
    // reservoirReward = times_ * reporterDeposit * reservoirSlashingRewardPct / HUNDRED_PCT;
    reservoirReward = product.mul(protocolSlashingRewardPct) / HUNDRED_PCT;
    // totalSlash = slasherReward + reservoirReward
    totalSlash = slasherReward.add(reservoirReward);
  }

  function getUserStatus(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) external view override returns (UserStatus) {
    if (userId_ == _hdhId && users[userId_].pokerKey == pokerKey_) {
      return UserStatus.HDH;
    }
    if (users[userId_].deposit >= minDeposit_ && users[userId_].pokerKey == pokerKey_) {
      return UserStatus.MEMBER;
    }
    return UserStatus.UNAUTHORIZED;
  }

  function authorizeHDH(uint256 userId_, address pokerKey_) external view override {
    require(userId_ == _hdhId, "NOT_HDH");
    require(users[userId_].pokerKey == pokerKey_, "INVALID_POKER_KEY");
  }

  function authorizeNonHDH(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) external view override {
    require(userId_ != _hdhId, "IS_HDH");
    authorizeMember(userId_, pokerKey_, minDeposit_);
  }

  function authorizeMember(
    uint256 userId_,
    address pokerKey_,
    uint256 minDeposit_
  ) public view override {
    require(users[userId_].deposit >= minDeposit_, "INSUFFICIENT_DEPOSIT");
    require(users[userId_].pokerKey == pokerKey_, "INVALID_POKER_KEY");
  }

  function requireValidAdminKey(uint256 userId_, address adminKey_) external view override {
    require(users[userId_].adminKey == adminKey_, "INVALID_AMIN_KEY");
  }

  function requireValidAdminOrPokerKey(uint256 userId_, address adminOrPokerKey_) external view override {
    require(
      users[userId_].adminKey == adminOrPokerKey_ || users[userId_].pokerKey == adminOrPokerKey_,
      "INVALID_AMIN_OR_POKER_KEY"
    );
  }

  function getLastDepositChange(uint256 userId_) external view override returns (uint256) {
    return _lastDepositChange[userId_];
  }
}

// File: contracts/PowerPokeStorageV1.sol


pragma solidity ^0.6.12;


contract PowerPokeStorageV1 {
  struct Client {
    bool active;
    bool canSlash;
    bool allowPokerWithdrawingRewards;
    address owner;
    uint256 credit;
    uint256 minReportInterval;
    uint256 maxReportInterval;
    uint256 slasherHeartbeat;
    uint256 gasPriceLimit;
    uint256 defaultMinDeposit;
    uint256 fixedCompensationCVP;
    uint256 fixedCompensationETH;
  }

  struct BonusPlan {
    bool active;
    uint64 bonusNumerator;
    uint64 bonusDenominator;
    uint64 perGas;
  }

  IPowerOracle public oracle;

  uint256 public totalCredits;

  mapping(uint256 => uint256) public rewards;

  mapping(uint256 => bool) public pokerKeyRewardWithdrawAllowance;

  mapping(address => Client) public clients;

  mapping(address => mapping(uint256 => BonusPlan)) public bonusPlans;
}

// File: contracts/PowerPoke.sol

pragma solidity ^0.6.12;














contract PowerPoke is IPowerPoke, PowerOwnable, Initializable, PowerPausable, ReentrancyGuard, PowerPokeStorageV1 {
  using SafeMath for uint256;

  event RewardUser(
    address indexed client,
    uint256 indexed userId,
    uint256 indexed bonusPlan,
    bool compensateInETH,
    uint256 gasUsed,
    uint256 gasPrice,
    uint256 userDeposit,
    uint256 ethPrice,
    uint256 cvpPrice,
    uint256 compensationEvaluationCVP,
    uint256 bonusCVP,
    uint256 earnedCVP,
    uint256 earnedETH
  );

  event TransferClientOwnership(address indexed client, address indexed from, address indexed to);

  event SetReportIntervals(address indexed client, uint256 minReportInterval, uint256 maxReportInterval);

  event SetGasPriceLimit(address indexed client, uint256 gasPriceLimit);

  event SetSlasherHeartbeat(address indexed client, uint256 slasherHeartbeat);

  event SetBonusPlan(
    address indexed client,
    uint256 indexed planId,
    bool indexed active,
    uint64 bonusNominator,
    uint64 bonsuDenominator,
    uint128 perGas
  );

  event SetFixedCompensations(address indexed client, uint256 fixedCompensationETH, uint256 fixedCompensationCVP);

  event SetDefaultMinDeposit(address indexed client, uint256 defaultMinDeposit);

  event WithdrawRewards(uint256 indexed userId, address indexed to, uint256 amount);

  event AddCredit(address indexed client, uint256 amount);

  event WithdrawCredit(address indexed client, address indexed to, uint256 amount);

  event SetOracle(address indexed oracle);

  event AddClient(
    address indexed client,
    address indexed owner,
    bool canSlash,
    uint256 gasPriceLimit,
    uint256 minReportInterval,
    uint256 maxReportInterval,
    uint256 slasherHeartbeat
  );

  event SetClientActiveFlag(address indexed client, bool indexed active);

  event SetCanSlashFlag(address indexed client, bool indexed canSlash);

  event SetPokerKeyRewardWithdrawAllowance(uint256 indexed userId, bool allow);

  struct PokeRewardOptions {
    address to;
    bool compensateInETH;
  }

  struct RewardHelperStruct {
    uint256 gasPrice;
    uint256 ethPrice;
    uint256 cvpPrice;
    uint256 totalInCVP;
    uint256 compensationCVP;
    uint256 bonusCVP;
    uint256 earnedCVP;
    uint256 earnedETH;
  }

  address public immutable WETH_TOKEN;

  IERC20 public immutable CVP_TOKEN;

  IEACAggregatorProxy public immutable FAST_GAS_ORACLE;

  PowerPokeStaking public immutable POWER_POKE_STAKING;

  IUniswapV2Router02 public immutable UNISWAP_ROUTER;

  modifier onlyClientOwner(address client_) {
    require(clients[client_].owner == msg.sender, "ONLY_CLIENT_OWNER");
    _;
  }

  constructor(
    address cvpToken_,
    address wethToken_,
    address fastGasOracle_,
    address uniswapRouter_,
    address powerPokeStaking_
  ) public {
    require(cvpToken_ != address(0), "CVP_ADDR_IS_0");
    require(wethToken_ != address(0), "WETH_ADDR_IS_0");
    require(fastGasOracle_ != address(0), "FAST_GAS_ORACLE_IS_0");
    require(uniswapRouter_ != address(0), "UNISWAP_ROUTER_IS_0");
    require(powerPokeStaking_ != address(0), "POWER_POKE_STAKING_ADDR_IS_0");

    CVP_TOKEN = IERC20(cvpToken_);
    WETH_TOKEN = wethToken_;
    FAST_GAS_ORACLE = IEACAggregatorProxy(fastGasOracle_);
    POWER_POKE_STAKING = PowerPokeStaking(powerPokeStaking_);
    UNISWAP_ROUTER = IUniswapV2Router02(uniswapRouter_);
  }

  function initialize(address owner_, address oracle_) external initializer {
    _transferOwnership(owner_);
    oracle = IPowerOracle(oracle_);
  }

  /*** CLIENT'S CONTRACT INTERFACE ***/
  function authorizeReporter(uint256 userId_, address pokerKey_) external view override {
    POWER_POKE_STAKING.authorizeHDH(userId_, pokerKey_);
  }

  function authorizeNonReporter(uint256 userId_, address pokerKey_) external view override {
    POWER_POKE_STAKING.authorizeNonHDH(userId_, pokerKey_, clients[msg.sender].defaultMinDeposit);
  }

  function authorizeNonReporterWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinDeposit_
  ) external view override {
    POWER_POKE_STAKING.authorizeNonHDH(userId_, pokerKey_, overrideMinDeposit_);
  }

  function authorizePoker(uint256 userId_, address pokerKey_) external view override {
    POWER_POKE_STAKING.authorizeMember(userId_, pokerKey_, clients[msg.sender].defaultMinDeposit);
  }

  function authorizePokerWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinStake_
  ) external view override {
    POWER_POKE_STAKING.authorizeMember(userId_, pokerKey_, overrideMinStake_);
  }

  function slashReporter(uint256 slasherId_, uint256 times_) external override nonReentrant {
    require(clients[msg.sender].active, "INVALID_CLIENT");
    require(clients[msg.sender].canSlash, "CANT_SLASH");
    if (times_ == 0) {
      return;
    }

    POWER_POKE_STAKING.slashHDH(slasherId_, times_);
  }

  function reward(
    uint256 userId_,
    uint256 gasUsed_,
    uint256 compensationPlan_,
    bytes calldata pokeOptions_
  ) external override nonReentrant whenNotPaused {
    RewardHelperStruct memory helper;
    require(clients[msg.sender].active, "INVALID_CLIENT");

    PokeRewardOptions memory opts = abi.decode(pokeOptions_, (PokeRewardOptions));
    if (opts.compensateInETH) {
      gasUsed_ = gasUsed_.add(clients[msg.sender].fixedCompensationETH);
    } else {
      gasUsed_ = gasUsed_.add(clients[msg.sender].fixedCompensationCVP);
    }

    if (gasUsed_ == 0) {
      return;
    }

    helper.ethPrice = oracle.getPriceByAsset(WETH_TOKEN);
    helper.cvpPrice = oracle.getPriceByAsset(address(CVP_TOKEN));

    helper.gasPrice = getGasPriceFor(msg.sender);
    helper.compensationCVP = helper.gasPrice.mul(gasUsed_).mul(helper.ethPrice) / helper.cvpPrice;
    uint256 userDeposit = POWER_POKE_STAKING.getDepositOf(userId_);

    if (userDeposit != 0) {
      helper.bonusCVP = getPokerBonus(msg.sender, compensationPlan_, gasUsed_, userDeposit);
    }

    helper.totalInCVP = helper.compensationCVP.add(helper.bonusCVP);
    require(clients[msg.sender].credit >= helper.totalInCVP, "NOT_ENOUGH_CREDITS");
    clients[msg.sender].credit = clients[msg.sender].credit.sub(helper.totalInCVP);

    if (opts.compensateInETH) {
      helper.earnedCVP = helper.bonusCVP;
      rewards[userId_] = rewards[userId_].add(helper.bonusCVP);
      helper.earnedETH = _payoutCompensationInETH(opts.to, helper.compensationCVP);
    } else {
      helper.earnedCVP = helper.compensationCVP.add(helper.bonusCVP);
      rewards[userId_] = rewards[userId_].add(helper.earnedCVP);
    }

    emit RewardUser(
      msg.sender,
      userId_,
      compensationPlan_,
      opts.compensateInETH,
      gasUsed_,
      helper.gasPrice,
      userDeposit,
      helper.ethPrice,
      helper.cvpPrice,
      helper.compensationCVP,
      helper.bonusCVP,
      helper.earnedCVP,
      helper.earnedETH
    );
  }

  /*** CLIENT OWNER INTERFACE ***/
  function transferClientOwnership(address client_, address to_) external override onlyClientOwner(client_) {
    clients[client_].owner = to_;
    emit TransferClientOwnership(client_, msg.sender, to_);
  }

  function addCredit(address client_, uint256 amount_) external override {
    Client storage client = clients[client_];

    require(client.active, "ONLY_ACTIVE_CLIENT");

    CVP_TOKEN.transferFrom(msg.sender, address(this), amount_);
    client.credit = client.credit.add(amount_);
    totalCredits = totalCredits.add(amount_);

    emit AddCredit(client_, amount_);
  }

  function withdrawCredit(
    address client_,
    address to_,
    uint256 amount_
  ) external override onlyClientOwner(client_) {
    Client storage client = clients[client_];

    client.credit = client.credit.sub(amount_);
    totalCredits = totalCredits.sub(amount_);

    CVP_TOKEN.transfer(to_, amount_);

    emit WithdrawCredit(client_, to_, amount_);
  }

  function setReportIntervals(
    address client_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external override onlyClientOwner(client_) {
    require(maxReportInterval_ > minReportInterval_ && minReportInterval_ > 0, "INVALID_REPORT_INTERVALS");
    clients[client_].minReportInterval = minReportInterval_;
    clients[client_].maxReportInterval = maxReportInterval_;
    emit SetReportIntervals(client_, minReportInterval_, maxReportInterval_);
  }

  function setSlasherHeartbeat(address client_, uint256 slasherHeartbeat_) external override onlyClientOwner(client_) {
    clients[client_].slasherHeartbeat = slasherHeartbeat_;
    emit SetSlasherHeartbeat(client_, slasherHeartbeat_);
  }

  function setGasPriceLimit(address client_, uint256 gasPriceLimit_) external override onlyClientOwner(client_) {
    clients[client_].gasPriceLimit = gasPriceLimit_;
    emit SetGasPriceLimit(client_, gasPriceLimit_);
  }

  function setFixedCompensations(
    address client_,
    uint256 eth_,
    uint256 cvp_
  ) external override onlyClientOwner(client_) {
    clients[client_].fixedCompensationETH = eth_;
    clients[client_].fixedCompensationCVP = cvp_;
    emit SetFixedCompensations(client_, eth_, cvp_);
  }

  function setBonusPlan(
    address client_,
    uint256 planId_,
    bool active_,
    uint64 bonusNominator_,
    uint64 bonusDenominator_,
    uint64 perGas_
  ) external override onlyClientOwner(client_) {
    bonusPlans[client_][planId_] = BonusPlan(active_, bonusNominator_, bonusDenominator_, perGas_);
    emit SetBonusPlan(client_, planId_, active_, bonusNominator_, bonusDenominator_, perGas_);
  }

  function setMinimalDeposit(address client_, uint256 defaultMinDeposit_) external override onlyClientOwner(client_) {
    clients[client_].defaultMinDeposit = defaultMinDeposit_;
    emit SetDefaultMinDeposit(client_, defaultMinDeposit_);
  }

  /*** POKER INTERFACE ***/
  function withdrawRewards(uint256 userId_, address to_) external override {
    if (pokerKeyRewardWithdrawAllowance[userId_] == true) {
      POWER_POKE_STAKING.requireValidAdminOrPokerKey(userId_, msg.sender);
    } else {
      POWER_POKE_STAKING.requireValidAdminKey(userId_, msg.sender);
    }
    require(to_ != address(0), "0_ADDRESS");
    uint256 rewardAmount = rewards[userId_];
    require(rewardAmount > 0, "NOTHING_TO_WITHDRAW");
    rewards[userId_] = 0;

    CVP_TOKEN.transfer(to_, rewardAmount);

    emit WithdrawRewards(userId_, to_, rewardAmount);
  }

  function setPokerKeyRewardWithdrawAllowance(uint256 userId_, bool allow_) external override {
    POWER_POKE_STAKING.requireValidAdminKey(userId_, msg.sender);
    pokerKeyRewardWithdrawAllowance[userId_] = allow_;
    emit SetPokerKeyRewardWithdrawAllowance(userId_, allow_);
  }

  /*** OWNER INTERFACE ***/
  function addClient(
    address client_,
    address owner_,
    bool canSlash_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external override onlyOwner {
    require(maxReportInterval_ > minReportInterval_ && minReportInterval_ > 0, "INVALID_REPORT_INTERVALS");

    Client storage c = clients[client_];
    c.active = true;
    c.canSlash = canSlash_;
    c.owner = owner_;
    c.gasPriceLimit = gasPriceLimit_;
    c.minReportInterval = minReportInterval_;
    c.maxReportInterval = maxReportInterval_;
    c.slasherHeartbeat = uint256(-1);

    emit AddClient(client_, owner_, canSlash_, gasPriceLimit_, minReportInterval_, maxReportInterval_, uint256(-1));
  }

  function setClientActiveFlag(address client_, bool active_) external override onlyOwner {
    clients[client_].active = active_;
    emit SetClientActiveFlag(client_, active_);
  }

  function setCanSlashFlag(address client_, bool canSlash) external override onlyOwner {
    clients[client_].active = canSlash;
    emit SetCanSlashFlag(client_, canSlash);
  }

  function setOracle(address oracle_) external override onlyOwner {
    oracle = IPowerOracle(oracle_);
    emit SetOracle(oracle_);
  }

  /**
   * @notice The owner pauses reward-operation
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice The owner unpauses reward-operation
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /*** INTERNAL HELPERS ***/
  function _payoutCompensationInETH(address _to, uint256 _cvpAmount) internal returns (uint256) {
    CVP_TOKEN.approve(address(UNISWAP_ROUTER), _cvpAmount);

    address[] memory path = new address[](2);
    path[0] = address(CVP_TOKEN);
    path[1] = address(WETH_TOKEN);

    uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForETH(_cvpAmount, uint256(0), path, _to, now.add(1800));
    return amounts[1];
  }

  function _latestFastGas() internal view returns (uint256) {
    return uint256(FAST_GAS_ORACLE.latestAnswer());
  }

  /*** GETTERS ***/
  function creditOf(address client_) external view override returns (uint256) {
    return clients[client_].credit;
  }

  function ownerOf(address client_) external view override returns (address) {
    return clients[client_].owner;
  }

  function getMinMaxReportIntervals(address client_) external view override returns (uint256 min, uint256 max) {
    return (clients[client_].minReportInterval, clients[client_].maxReportInterval);
  }

  function getSlasherHeartbeat(address client_) external view override returns (uint256) {
    return clients[client_].slasherHeartbeat;
  }

  function getGasPriceLimit(address client_) external view override returns (uint256) {
    return clients[client_].gasPriceLimit;
  }

  function getPokerBonus(
    address client_,
    uint256 bonusPlanId_,
    uint256 gasUsed_,
    uint256 userDeposit_
  ) public view override returns (uint256) {
    BonusPlan memory plan = bonusPlans[client_][bonusPlanId_];
    require(plan.active, "INACTIVE_BONUS_PLAN");

    // gasUsed_ * userDeposit_ * plan.bonusNumerator / bonusDenominator / plan.perGas
    return gasUsed_.mul(userDeposit_).mul(plan.bonusNumerator) / plan.bonusDenominator / plan.perGas;
  }

  function getGasPriceFor(address client_) public view override returns (uint256) {
    return Math.min(tx.gasprice, Math.min(_latestFastGas(), clients[client_].gasPriceLimit));
  }
}

// File: contracts/PowerOracle.sol

pragma solidity ^0.6.12;











contract PowerOracle is IPowerOracle, PowerOwnable, Initializable, PowerPausable, UniswapTWAPProvider {
  using SafeMath for uint256;
  using SafeCast for uint256;

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;
  uint256 internal constant COMPENSATION_PLAN_2_ID = 2;
  uint256 public constant HUNDRED_PCT = 100 ether;

  /// @notice The event emitted when a reporter calls a poke operation
  event PokeFromReporter(uint256 indexed reporterId, uint256 tokenCount, uint256 rewardCount);

  /// @notice The event emitted when a slasher executes poke and slashes the current reporter
  event PokeFromSlasher(uint256 indexed slasherId, uint256 tokenCount, uint256 overdueCount);

  /// @notice The event emitted when an arbitrary user calls poke operation
  event Poke(address indexed poker, uint256 tokenCount);

  /// @notice The event emitted when the owner updates the powerOracleStaking address
  event SetPowerPoke(address powerPoke);

  /// @notice The event emitted when the slasher timestamps are updated
  event SlasherHeartbeat(uint256 indexed slasherId, uint256 prevSlasherTimestamp, uint256 newSlasherTimestamp);

  /// @notice CVP token address
  IERC20 public immutable CVP_TOKEN;

  modifier onlyReporter(uint256 reporterId_, bytes calldata rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(reporterId_, msg.sender);
    _;
    uint256 gasUsed = gasStart.sub(gasleft());
    powerPoke.reward(reporterId_, gasUsed, COMPENSATION_PLAN_1_ID, rewardOpts);
  }

  modifier denyContract() {
    require(msg.sender == tx.origin, "CONTRACT_CALL");
    _;
  }

  constructor(
    address cvpToken_,
    uint256 anchorPeriod_,
    TokenConfig[] memory configs
  ) public UniswapTWAPProvider(anchorPeriod_, configs) UniswapConfig(configs) {
    CVP_TOKEN = IERC20(cvpToken_);
  }

  function initialize(address owner_, address powerPoke_) external initializer {
    _transferOwnership(owner_);
    powerPoke = IPowerPoke(powerPoke_);
  }

  /*** Current Poke Interface ***/

  function _fetchEthPrice() internal returns (uint256) {
    bytes32 symbolHash = keccak256(abi.encodePacked("ETH"));
    if (getIntervalStatus(symbolHash) == ReportInterval.LESS_THAN_MIN) {
      return uint256(prices[symbolHash].value);
    }
    uint256 ethPrice = fetchEthPrice();
    _savePrice(symbolHash, ethPrice);
    return ethPrice;
  }

  function _fetchCvpPrice(uint256 ethPrice_) internal returns (uint256) {
    bytes32 symbolHash = keccak256(abi.encodePacked("CVP"));
    if (getIntervalStatus(symbolHash) == ReportInterval.LESS_THAN_MIN) {
      return uint256(prices[symbolHash].value);
    }
    uint256 cvpPrice = fetchCvpPrice(ethPrice_);
    _savePrice(symbolHash, cvpPrice);
    return cvpPrice;
  }

  function _fetchAndSavePrice(
    string memory symbol_,
    uint256 ethPrice_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) internal returns (ReportInterval) {
    TokenConfig memory config = getTokenConfigBySymbol(symbol_);
    require(config.priceSource == PriceSource.REPORTER, "NOT_REPORTER");
    bytes32 symbolHash = keccak256(abi.encodePacked(symbol_));

    ReportInterval intervalStatus = getIntervalStatusForIntervals(symbolHash, minReportInterval_, maxReportInterval_);
    if (intervalStatus == ReportInterval.LESS_THAN_MIN) {
      return intervalStatus;
    }

    uint256 price;
    if (symbolHash == ethHash) {
      price = ethPrice_;
    } else {
      price = fetchAnchorPrice(symbol_, config, ethPrice_);
    }

    _savePrice(symbolHash, price);

    return intervalStatus;
  }

  function _savePrice(bytes32 _symbolHash, uint256 price_) internal {
    prices[_symbolHash] = Price(block.timestamp.toUint128(), price_.toUint128());
  }

  function priceInternal(TokenConfig memory config_) internal view returns (uint256) {
    if (config_.priceSource == PriceSource.REPORTER) return prices[config_.symbolHash].value;
    if (config_.priceSource == PriceSource.FIXED_USD) return config_.fixedPrice;
    if (config_.priceSource == PriceSource.FIXED_ETH) {
      uint256 usdPerEth = prices[ethHash].value;
      require(usdPerEth > 0, "ETH_PRICE_NOT_SET");
      return mul(usdPerEth, config_.fixedPrice) / ethBaseUnit;
    }
    revert("UNSUPPORTED_PRICE_CASE");
  }

  /*** Pokers ***/

  /**
   * @notice A reporter pokes symbols with incentive to be rewarded
   * @param reporterId_ The valid reporter's user ID
   * @param symbols_ Asset symbols to poke
   */
  function pokeFromReporter(
    uint256 reporterId_,
    string[] memory symbols_,
    bytes calldata rewardOpts
  ) external override onlyReporter(reporterId_, rewardOpts) whenNotPaused denyContract {
    uint256 len = symbols_.length;
    require(len > 0, "MISSING_SYMBOLS");

    uint256 ethPrice = _fetchEthPrice();
    _fetchCvpPrice(ethPrice);
    uint256 rewardCount = 0;
    (uint256 minReportInterval, uint256 maxReportInterval) = _getMinMaxReportInterval();

    for (uint256 i = 0; i < len; i++) {
      if (
        _fetchAndSavePrice(symbols_[i], ethPrice, minReportInterval, maxReportInterval) != ReportInterval.LESS_THAN_MIN
      ) {
        rewardCount++;
      }
    }

    require(rewardCount > 0, "NOTHING_UPDATED");

    emit PokeFromReporter(reporterId_, len, rewardCount);
  }

  /**
   * @notice A slasher pokes symbols with incentive to be rewarded
   * @param slasherId_ The slasher's user ID
   * @param symbols_ Asset symbols to poke
   */
  function pokeFromSlasher(
    uint256 slasherId_,
    string[] memory symbols_,
    bytes calldata rewardOpts
  ) external override whenNotPaused denyContract {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(slasherId_, msg.sender);
    uint256 len = symbols_.length;
    require(len > 0, "MISSING_SYMBOLS");

    uint256 ethPrice = _fetchEthPrice();
    _fetchCvpPrice(ethPrice);
    uint256 overdueCount = 0;
    (uint256 minReportInterval, uint256 maxReportInterval) = _getMinMaxReportInterval();

    for (uint256 i = 0; i < len; i++) {
      if (
        _fetchAndSavePrice(symbols_[i], ethPrice, minReportInterval, maxReportInterval) ==
        ReportInterval.GREATER_THAN_MAX
      ) {
        overdueCount++;
      }
    }

    // update with no constraints, compensate & reward
    if (overdueCount > 0) {
      _updateSlasherTimestamp(slasherId_, false);
      powerPoke.slashReporter(slasherId_, overdueCount);

      uint256 gasUsed = gasStart.sub(gasleft());
      powerPoke.reward(slasherId_, gasUsed, COMPENSATION_PLAN_1_ID, rewardOpts);
    } else {
      // treat it as a slasherHeartbeat call, do neither compensate nor reward
      _updateSlasherTimestamp(slasherId_, true);
    }

    emit PokeFromSlasher(slasherId_, len, overdueCount);
  }

  function slasherHeartbeat(uint256 slasherId_) external override whenNotPaused denyContract {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(slasherId_, msg.sender);

    _updateSlasherTimestamp(slasherId_, true);

    PowerPoke.PokeRewardOptions memory opts = PowerPoke.PokeRewardOptions(msg.sender, false);
    bytes memory rewardConfig = abi.encode(opts);
    // reward in CVP
    powerPoke.reward(slasherId_, gasStart.sub(gasleft()), COMPENSATION_PLAN_2_ID, rewardConfig);
  }

  function _updateSlasherTimestamp(uint256 _slasherId, bool assertOnTimeDelta) internal {
    uint256 prevSlasherUpdate = lastSlasherUpdates[_slasherId];

    if (assertOnTimeDelta) {
      uint256 delta = block.timestamp.sub(prevSlasherUpdate);
      require(delta >= powerPoke.getSlasherHeartbeat(address(this)), "BELOW_HEARTBEAT_INTERVAL");
    }

    lastSlasherUpdates[_slasherId] = block.timestamp;
    emit SlasherHeartbeat(_slasherId, prevSlasherUpdate, block.timestamp);
  }

  /**
   * @notice Arbitrary user pokes symbols without being rewarded
   * @param symbols_ Asset symbols to poke
   */
  function poke(string[] memory symbols_) external override whenNotPaused {
    uint256 len = symbols_.length;
    require(len > 0, "MISSING_SYMBOLS");

    uint256 ethPrice = _fetchEthPrice();
    (uint256 minReportInterval, uint256 maxReportInterval) = _getMinMaxReportInterval();

    for (uint256 i = 0; i < len; i++) {
      _fetchAndSavePrice(symbols_[i], ethPrice, minReportInterval, maxReportInterval);
    }

    emit Poke(msg.sender, len);
  }

  /*** Owner Interface ***/

  /**
   * @notice The owner sets a new powerPoke contract
   * @param powerPoke_ The powerPoke contract address
   */
  function setPowerPoke(address powerPoke_) external override onlyOwner {
    powerPoke = PowerPoke(powerPoke_);
    emit SetPowerPoke(powerPoke_);
  }

  /**
   * @notice The owner pauses poke*-operations
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice The owner unpauses poke*-operations
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /*** Viewers ***/

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    return powerPoke.getMinMaxReportIntervals(address(this));
  }

  function getIntervalStatus(bytes32 _symbolHash) public view returns (ReportInterval) {
    (uint256 minReportInterval, uint256 maxReportInterval) = _getMinMaxReportInterval();

    return getIntervalStatusForIntervals(_symbolHash, minReportInterval, maxReportInterval);
  }

  function getIntervalStatusForIntervals(
    bytes32 symbolHash_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) public view returns (ReportInterval) {
    uint256 delta = block.timestamp.sub(prices[symbolHash_].timestamp);

    if (delta < minReportInterval_) {
      return ReportInterval.LESS_THAN_MIN;
    }

    if (delta < maxReportInterval_) {
      return ReportInterval.OK;
    }

    return ReportInterval.GREATER_THAN_MAX;
  }

  /**
   * @notice Get the underlying price of a token
   * @param token_ The token address for price retrieval
   * @return Price denominated in USD, with 6 decimals, for the given asset address
   */
  function getPriceByAsset(address token_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigByUnderlying(token_);
    return priceInternal(config);
  }

  /**
   * @notice Get the official price for a symbol, like "COMP"
   * @param symbol_ The symbol for price retrieval
   * @return Price denominated in USD, with 6 decimals
   */
  function getPriceBySymbol(string calldata symbol_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigBySymbol(symbol_);
    return priceInternal(config);
  }

  /**
   * @notice Get price by a token symbol hash,
   *    like "0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa" for USDC
   * @param symbolHash_ The symbol hash for price retrieval
   * @return Price denominated in USD, with 6 decimals, for the given asset address
   */
  function getPriceBySymbolHash(bytes32 symbolHash_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigBySymbolHash(symbolHash_);
    return priceInternal(config);
  }

  /**
   * @notice Get the underlying price of a cToken
   * @dev Implements the PriceOracle interface for Compound v2.
   * @param cToken_ The cToken address for price retrieval
   * @return Price denominated in USD, with 18 decimals, for the given cToken address
   */
  function getUnderlyingPrice(address cToken_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigByCToken(cToken_);
    // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
    // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
    return mul(1e30, priceInternal(config)) / config.baseUnit;
  }

  /**
   * @notice Get the price by underlying address
   * @dev Implements the old PriceOracle interface for Compound v2.
   * @param token_ The underlying address for price retrieval
   * @return Price denominated in USD, with 18 decimals, for the given underlying address
   */
  function assetPrices(address token_) external view override returns (uint256) {
    TokenConfig memory config = getTokenConfigByUnderlying(token_);
    // Return price in the same format as getUnderlyingPrice, but by token address
    return mul(1e30, priceInternal(config)) / config.baseUnit;
  }
}