// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { BlockContext } from "./utils/BlockContext.sol";
import { PerpFiOwnableUpgrade } from "./utils/PerpFiOwnableUpgrade.sol";
import { Decimal, SafeMath } from "./utils/Decimal.sol";
import { IPriceFeed } from "./interface/IPriceFeed.sol";

contract ChainlinkL1 is PerpFiOwnableUpgrade, BlockContext {
    using SafeMath for uint256;
    using Decimal for Decimal.decimal;

    uint256 private constant TOKEN_DIGIT = 10**18;

    event PriceFeedL2Changed(address priceFeedL2);
    event PriceUpdateMessageIdSent(bytes32 messageId);
    event PriceUpdated(uint80 roundId, uint256 price, uint256 timestamp);

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    // key by currency symbol, eg ETH
    mapping(bytes32 => AggregatorV3Interface) public priceFeedMap;
    bytes32[] public priceFeedKeys;
    address public priceFeedL2Address;
    mapping(bytes32 => uint256) public prevTimestampMap;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //
    function initialize(address _priceFeedL2) public initializer {
        __Ownable_init();
        setPriceFeedL2(_priceFeedL2);
    }

    function setPriceFeedL2(address _priceFeedL2) public onlyOwner {
        requireNonEmptyAddress(_priceFeedL2);
        priceFeedL2Address = _priceFeedL2;
        emit PriceFeedL2Changed(_priceFeedL2);
    }

    function addAggregator(bytes32 _priceFeedKey, address _aggregator) external onlyOwner {
        requireNonEmptyAddress(_aggregator);
        if (address(priceFeedMap[_priceFeedKey]) == address(0)) {
            priceFeedKeys.push(_priceFeedKey);
        }
        priceFeedMap[_priceFeedKey] = AggregatorV3Interface(_aggregator);
    }

    function removeAggregator(bytes32 _priceFeedKey) external onlyOwner {
        requireNonEmptyAddress(address(getAggregator(_priceFeedKey)));
        delete priceFeedMap[_priceFeedKey];

        uint256 length = priceFeedKeys.length;
        for (uint256 i; i < length; i++) {
            if (priceFeedKeys[i] == _priceFeedKey) {
                // if the removal item is the last one, just `pop`
                if (i != length - 1) {
                    priceFeedKeys[i] = priceFeedKeys[length - 1];
                }
                priceFeedKeys.pop();
                break;
            }
        }
    }

    function getAggregator(bytes32 _priceFeedKey) public view returns (AggregatorV3Interface) {
        return priceFeedMap[_priceFeedKey];
    }

    //
    // INTERFACE IMPLEMENTATION
    //

    function updateLatestRoundData(bytes32 _priceFeedKey) external {
        AggregatorV3Interface aggregator = getAggregator(_priceFeedKey);
        requireNonEmptyAddress(address(aggregator));

        (uint80 roundId, int256 price, , uint256 timestamp, ) = aggregator.latestRoundData();
        require(timestamp > prevTimestampMap[_priceFeedKey], "incorrect timestamp");
        require(price >= 0, "negative answer");

        uint8 decimals = aggregator.decimals();

        Decimal.decimal memory decimalPrice = Decimal.decimal(formatDecimals(uint256(price), decimals));

        IPriceFeed(priceFeedL2Address).setLatestData(_priceFeedKey, decimalPrice.toUint(), timestamp, roundId);

        emit PriceUpdated(roundId, decimalPrice.toUint(), timestamp);

        prevTimestampMap[_priceFeedKey] = timestamp;
    }

    //
    // REQUIRE FUNCTIONS
    //

    function requireNonEmptyAddress(address _addr) internal pure {
        require(_addr != address(0), "empty address");
    }

    //
    // INTERNAL VIEW FUNCTIONS
    //
    function formatDecimals(uint256 _price, uint8 _decimals) internal pure returns (uint256) {
        return _price.mul(TOKEN_DIGIT).div(10**uint256(_decimals));
    }
}

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { ContextUpgradeSafe } from "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

// copy from openzeppelin Ownable, only modify how the owner transfer
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
contract PerpFiOwnableUpgrade is ContextUpgradeSafe {
    address private _owner;
    address private _candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function candidate() public view returns (address) {
        return _candidate;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "PerpFiOwnableUpgrade: caller is not the owner");
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
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "PerpFiOwnableUpgrade: zero address");
        require(newOwner != _owner, "PerpFiOwnableUpgrade: same as original");
        require(newOwner != _candidate, "PerpFiOwnableUpgrade: same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "PerpFiOwnableUpgrade: candidate is zero address");
        require(_candidate == _msgSender(), "PerpFiOwnableUpgrade: not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { DecimalMath } from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;
    using SafeMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

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

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMath for uint256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(unit(decimals)).div(y);
    }
}