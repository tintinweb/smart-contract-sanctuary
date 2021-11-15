// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
library SafeMath16 {
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
    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
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
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function sub(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b <= a, errorMessage);
        uint16 c = a - b;

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
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint16 c = a * b;
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
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function div(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b > 0, errorMessage);
        uint16 c = a / b;
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
    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
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
    function mod(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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
library SafeMath80 {
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
    function add(uint80 a, uint80 b) internal pure returns (uint80) {
        uint80 c = a + b;
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
    function sub(uint80 a, uint80 b) internal pure returns (uint80) {
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
    function sub(uint80 a, uint80 b, string memory errorMessage) internal pure returns (uint80) {
        require(b <= a, errorMessage);
        uint80 c = a - b;

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
    function mul(uint80 a, uint80 b) internal pure returns (uint80) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint80 c = a * b;
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
    function div(uint80 a, uint80 b) internal pure returns (uint80) {
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
    function div(uint80 a, uint80 b, string memory errorMessage) internal pure returns (uint80) {
        require(b > 0, errorMessage);
        uint80 c = a / b;
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
    function mod(uint80 a, uint80 b) internal pure returns (uint80) {
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
    function mod(uint80 a, uint80 b, string memory errorMessage) internal pure returns (uint80) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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
library SafeMath168 {
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
    function add(uint168 a, uint168 b) internal pure returns (uint168) {
        uint168 c = a + b;
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
    function sub(uint168 a, uint168 b) internal pure returns (uint168) {
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
    function sub(uint168 a, uint168 b, string memory errorMessage) internal pure returns (uint168) {
        require(b <= a, errorMessage);
        uint168 c = a - b;

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
    function mul(uint168 a, uint168 b) internal pure returns (uint168) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint168 c = a * b;
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
    function div(uint168 a, uint168 b) internal pure returns (uint168) {
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
    function div(uint168 a, uint168 b, string memory errorMessage) internal pure returns (uint168) {
        require(b > 0, errorMessage);
        uint168 c = a / b;
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
    function mod(uint168 a, uint168 b) internal pure returns (uint168) {
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
    function mod(uint168 a, uint168 b, string memory errorMessage) internal pure returns (uint168) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../v1/utils/SafeMath80.sol";
import "../v1/utils/SafeMath16.sol";
import "../v3/utils/SafeMath168.sol";

import "./interfaces/IFeesCalculatorV4.sol";

contract FeesCalculatorV4 is IFeesCalculatorV4, Ownable {

    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath168 for uint168;

    uint256 private constant PRECISION_DECIMALS = 1e10;

    uint256 private constant FUNDING_FEE_MIN_RATE = 2000;
    uint256 private constant FUNDING_FEE_MAX_RATE = 100000;
    uint256 private constant FUNDING_FEE_BASE_PERIOD = 1 days;

    uint256 private constant MAX_FUNDING_FEE_PERCENTAGE = 1000000;

    uint16 private constant MAX_CVI_VALUE = 20000;
    uint16 private constant CVI_DECIMALS = 100;

    uint16 private constant MAX_FUNDING_FEE_CVI_THRESHOLD = 55;
    uint16 private constant MIN_FUDNING_FEE_CVI_THRESHOLD = 150;
    uint16 private constant FUNDING_FEE_DIVISION_FACTOR = 5;

    uint16 private constant MAX_PERCENTAGE = 10000;

    uint16 private constant COLATERAL_VALUES_NUM = 101; // From 0.00 to 1.00 inclusive

    uint16 public override depositFeePercent = 0;
    uint16 public override withdrawFeePercent = 0;
    uint16 public override openPositionFeePercent = 15;
    uint16 public openPositionLPFeePercent = 15;
    uint16 public override buyingPremiumFeeMaxPercent = 1000;
    uint16 public override closePositionFeePercent = 30;

    uint16 public buyingPremiumThreshold = 6500; // 1.0 is MAX_PERCENTAGE = 10000

    uint16 public closePositionMaxFeePercent = 300;

    uint16 public maxTurbulenceFeePercentToTrim = 100;
    uint16 public turbulenceStepPercent = 1000;
    uint16 public override turbulenceIndicatorPercent = 0;

    uint256 public oracleHeartbeatPeriod = 55 minutes;
    uint256 public closePositionFeeDecayPeriod = 24 hours;
    uint256 public fundingFeeConstantRate = 3000;

    uint16 public turbulenceDeviationThresholdPercent = 7000; // 1.0 is MAX_PERCENTAGE = 10000
    uint16 public turbulenceDeviationPercentage = 500; // 1.0 is MAX_PERCENTAGE = 10000

    address public turbulenceUpdator;

    uint16[] public collateralToBuyingPremiumMapping = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 8, 9, 11, 14, 16, 20, 24, 29, 35, 42, 52, 63, 77, 94, 115, 140, 172, 212, 261, 323, 399, 495, 615, 765, 953, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000];

    modifier onlyTurbulenceUpdator {
        require(msg.sender == turbulenceUpdator, "Not allowed");
        _;
    }

    function updateTurbulenceIndicatorPercent(uint256 _totalTime, uint256 _newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) external override onlyTurbulenceUpdator returns (uint16 updatedTurbulenceIndicatorPercent) {
        uint256 totalHeartbeats = _totalTime / oracleHeartbeatPeriod;
        updatedTurbulenceIndicatorPercent = calculateTurbulenceIndicatorPercent(totalHeartbeats, _newRounds, _lastCVIValue, _currCVIValue);

        if (updatedTurbulenceIndicatorPercent != turbulenceIndicatorPercent) {
            turbulenceIndicatorPercent = updatedTurbulenceIndicatorPercent;
        }
    }

    function setTurbulenceUpdator(address _newUpdator) external override onlyOwner {
        turbulenceUpdator = _newUpdator;
    }

    function setDepositFee(uint16 _newDepositFeePercentage) external override onlyOwner {
        require(_newDepositFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        depositFeePercent = _newDepositFeePercentage;
    }

    function setWithdrawFee(uint16 _newWithdrawFeePercentage) external override onlyOwner {
        require(_newWithdrawFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        withdrawFeePercent = _newWithdrawFeePercentage;
    }

    function setOpenPositionFee(uint16 _newOpenPositionFeePercentage) external override onlyOwner {
        require(_newOpenPositionFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        openPositionFeePercent = _newOpenPositionFeePercentage;
    }

    function setClosePositionFee(uint16 _newClosePositionFeePercentage) external override onlyOwner {
        require(_newClosePositionFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        require(_newClosePositionFeePercentage <= closePositionMaxFeePercent, "Min fee above max fee");
        closePositionFeePercent = _newClosePositionFeePercentage;
    }

    function setOpenPositionLPFee(uint16 _newOpenPositionLPFeePercent) external onlyOwner {
        require(_newOpenPositionLPFeePercent < MAX_PERCENTAGE, "Fee exceeds maximum");
        openPositionLPFeePercent = _newOpenPositionLPFeePercent;
    }

    function setClosePositionMaxFee(uint16 _newClosePositionMaxFeePercentage) external override onlyOwner {
        require(_newClosePositionMaxFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        require(_newClosePositionMaxFeePercentage >= closePositionFeePercent, "Max fee below min fee");
        closePositionMaxFeePercent = _newClosePositionMaxFeePercentage;
    }

    function setClosePositionFeeDecay(uint256 _newClosePositionFeeDecayPeriod) external override onlyOwner {
        require(_newClosePositionFeeDecayPeriod > 0, "Period must be positive");
        closePositionFeeDecayPeriod = _newClosePositionFeeDecayPeriod;
    }

    function setOracleHeartbeatPeriod(uint256 _newOracleHeartbeatPeriod) external override onlyOwner {
        require(_newOracleHeartbeatPeriod > 0, "Heartbeat must be positive");
        oracleHeartbeatPeriod = _newOracleHeartbeatPeriod;
    }

    function setBuyingPremiumFeeMax(uint16 _newBuyingPremiumFeeMaxPercentage) external override onlyOwner {
        require(_newBuyingPremiumFeeMaxPercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        buyingPremiumFeeMaxPercent = _newBuyingPremiumFeeMaxPercentage;
    }

    function setBuyingPremiumThreshold(uint16 _newBuyingPremiumThreshold) external override onlyOwner {
        require(_newBuyingPremiumThreshold < MAX_PERCENTAGE, "Threshold exceeds maximum");
        buyingPremiumThreshold = _newBuyingPremiumThreshold;   
    }

    function setTurbulenceStep(uint16 _newTurbulenceStepPercentage) external override onlyOwner {
        require(_newTurbulenceStepPercentage < MAX_PERCENTAGE, "Step exceeds maximum");
        turbulenceStepPercent = _newTurbulenceStepPercentage;
    }
    
    function setMaxTurbulenceFeePercentToTrim(uint16 _newMaxTurbulenceFeePercentToTrim) external override onlyOwner {
        require(_newMaxTurbulenceFeePercentToTrim < MAX_PERCENTAGE, "Fee exceeds maximum");
        maxTurbulenceFeePercentToTrim = _newMaxTurbulenceFeePercentToTrim;
    }

     function setTurbulenceDeviationThresholdPercent(uint16 _newTurbulenceDeviationThresholdPercent) external override onlyOwner {
        require(_newTurbulenceDeviationThresholdPercent < MAX_PERCENTAGE, "Threshold exceeds maximum");
        turbulenceDeviationThresholdPercent = _newTurbulenceDeviationThresholdPercent;
    }

    function setTurbulenceDeviationPercent(uint16 _newTurbulenceDeviationPercentage) external override onlyOwner {
        require(_newTurbulenceDeviationPercentage < MAX_PERCENTAGE, "Deviation exceeds maximum");
        turbulenceDeviationPercentage = _newTurbulenceDeviationPercentage;
    }

    function setFundingFeeConstantRate(uint16 _newfundingFeeConstantRate) external onlyOwner {
        require(_newfundingFeeConstantRate < FUNDING_FEE_MAX_RATE, "Fee exceeds maximum");
        fundingFeeConstantRate = _newfundingFeeConstantRate;
    }

    function setCollateralToBuyingPremiumMapping(uint16[] calldata _newCollateralToBuyingPremiumMapping) external override onlyOwner {
        require(_newCollateralToBuyingPremiumMapping.length == COLATERAL_VALUES_NUM, "Bad mapping size");
        collateralToBuyingPremiumMapping = _newCollateralToBuyingPremiumMapping;
    }

    function calculateTurbulenceIndicatorPercent(uint256 totalHeartbeats, uint256 newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) public view override returns (uint16) {
        uint16 updatedTurbulenceIndicatorPercent = turbulenceIndicatorPercent;

        uint256 CVIDeltaPercent = uint256(_currCVIValue > _lastCVIValue ? _currCVIValue - _lastCVIValue : _lastCVIValue - _currCVIValue).mul(MAX_PERCENTAGE).div(_lastCVIValue);
        uint256 maxAllowedTurbulenceTimes = CVIDeltaPercent.mul(MAX_PERCENTAGE).div(uint256(turbulenceDeviationThresholdPercent).mul(turbulenceDeviationPercentage));

        uint256 decayTimes = 0;
        uint256 turbulenceTimes = 0;
        if (newRounds > totalHeartbeats) {
            turbulenceTimes = newRounds - totalHeartbeats;
            turbulenceTimes = turbulenceTimes >  maxAllowedTurbulenceTimes ? maxAllowedTurbulenceTimes : turbulenceTimes;
            decayTimes = newRounds - turbulenceTimes;
        } else {
            decayTimes = newRounds;
        }

        for (uint256 i = 0; i < decayTimes; i++) {
            updatedTurbulenceIndicatorPercent = updatedTurbulenceIndicatorPercent / 2;
        }

        if (updatedTurbulenceIndicatorPercent < maxTurbulenceFeePercentToTrim) {
            updatedTurbulenceIndicatorPercent = 0;
        }

        for (uint256 i = 0; i < turbulenceTimes; i++) {
            updatedTurbulenceIndicatorPercent = updatedTurbulenceIndicatorPercent.add(uint16(uint256(buyingPremiumFeeMaxPercent).mul(turbulenceStepPercent) / MAX_PERCENTAGE));
        }

        if (updatedTurbulenceIndicatorPercent > buyingPremiumFeeMaxPercent) {
            updatedTurbulenceIndicatorPercent = buyingPremiumFeeMaxPercent;
        }

        return updatedTurbulenceIndicatorPercent;
    }

    function calculateBuyingPremiumFee(uint168 _tokenAmount, uint8 _leverage, uint256 _collateralRatio) external view override returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage) {
        (buyingPremiumFee, combinedPremiumFeePercentage) =  _calculateBuyingPremiumFeeWithTurbulence(_tokenAmount, _leverage, _collateralRatio, turbulenceIndicatorPercent);
    }
    
    function calculateBuyingPremiumFeeWithTurbulence(uint168 _tokenAmount, uint8 _leverage, uint256 _collateralRatio, uint16 _turbulenceIndicatorPercent) external view override returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage) {
        (buyingPremiumFee, combinedPremiumFeePercentage) = _calculateBuyingPremiumFeeWithTurbulence(_tokenAmount, _leverage, _collateralRatio, _turbulenceIndicatorPercent);
    }

    function calculateSingleUnitFundingFee(CVIValue[] calldata _cviValues) external override view returns (uint256 fundingFee) {
        for (uint8 i = 0; i < _cviValues.length; i++) {
            fundingFee = fundingFee.add(calculateSingleUnitPeriodFundingFee(_cviValues[i]));
        }
    }

    function calculateSingleUnitPeriodFundingFee(CVIValue memory _cviValue) private view returns (uint256 fundingFee) {
        if (_cviValue.cviValue == 0 || _cviValue.period == 0) {
            return 0;
        }

        uint256 fundingFeeRatePercents = FUNDING_FEE_MAX_RATE;
        uint16 integerCVIValue = _cviValue.cviValue / CVI_DECIMALS;
        if (integerCVIValue > MAX_FUNDING_FEE_CVI_THRESHOLD) {
            if (integerCVIValue >= MIN_FUDNING_FEE_CVI_THRESHOLD) {
                fundingFeeRatePercents = FUNDING_FEE_MIN_RATE;
            } else {
                // Defining as memory to keep function pure and save storage space + reads
                uint24[5] memory fundingFeeCoefficients = [100000, 114869, 131950, 151571, 174110];

                uint256 exponent = (integerCVIValue - MAX_FUNDING_FEE_CVI_THRESHOLD) / FUNDING_FEE_DIVISION_FACTOR;
                uint256 coefficientIndex = (integerCVIValue - MAX_FUNDING_FEE_CVI_THRESHOLD) % FUNDING_FEE_DIVISION_FACTOR;

                // Note: overflow is not possible as the exponent can only get larger, and other parts are constants
                // However, 2 ** exponent can overflow if cvi value is wrong
                require(exponent < 256, "exponent overflow");
                fundingFeeRatePercents = (PRECISION_DECIMALS / (2 ** exponent) / fundingFeeCoefficients[coefficientIndex]) + 
                    fundingFeeConstantRate;

                if (fundingFeeRatePercents > FUNDING_FEE_MAX_RATE) {
                    fundingFeeRatePercents = FUNDING_FEE_MAX_RATE;
                }
            }
        }

        return PRECISION_DECIMALS.mul(uint256(_cviValue.cviValue)).mul(fundingFeeRatePercents).mul(_cviValue.period) /
            FUNDING_FEE_BASE_PERIOD / MAX_CVI_VALUE / MAX_FUNDING_FEE_PERCENTAGE;
    }

    function calculateClosePositionFeePercent(uint256 creationTimestamp) external view override returns (uint16) {
        if (block.timestamp.sub(creationTimestamp) >= closePositionFeeDecayPeriod) {
            return closePositionFeePercent;
        }

        uint16 decay = uint16(uint256(closePositionMaxFeePercent - closePositionFeePercent).mul(block.timestamp.sub(creationTimestamp)) / 
            closePositionFeeDecayPeriod);
        return closePositionMaxFeePercent.sub(decay);
    }

    function calculateWithdrawFeePercent(uint256) external view override returns (uint16) {
        return withdrawFeePercent;
    }

    function openPositionFees() external view override returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult) {
        openPositionFeePercentResult = openPositionFeePercent;
        buyingPremiumFeeMaxPercentResult = buyingPremiumFeeMaxPercent;
    }

    function _calculateBuyingPremiumFeeWithTurbulence(uint168 _tokenAmount, uint8 _leverage, uint256 _collateralRatio, uint16 _turbulenceIndicatorPercent) private view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage) {
        uint168 buyingPremiumFeePercentage = 0;
        if (_collateralRatio >= PRECISION_DECIMALS) {
            buyingPremiumFeePercentage = buyingPremiumFeeMaxPercent;
        } else {
            if (_collateralRatio >= uint256(buyingPremiumThreshold).mul(PRECISION_DECIMALS) / MAX_PERCENTAGE) {
                buyingPremiumFeePercentage = collateralToBuyingPremiumMapping[_collateralRatio * 10**2 / PRECISION_DECIMALS];
            }
        }

        combinedPremiumFeePercentage = uint16(openPositionLPFeePercent).add(_turbulenceIndicatorPercent).add(uint16(buyingPremiumFeePercentage));
        if (combinedPremiumFeePercentage > buyingPremiumFeeMaxPercent) {
            combinedPremiumFeePercentage = buyingPremiumFeeMaxPercent;
        }
        
        uint256 __buyingPremiumFee = uint256(_tokenAmount.mul(_leverage)).mul(combinedPremiumFeePercentage) / MAX_PERCENTAGE;
        buyingPremiumFee = uint168(__buyingPremiumFee);
        require(__buyingPremiumFee == buyingPremiumFee, "Too much tokens");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

interface IFeesCalculatorV4 {

    struct CVIValue {
        uint256 period;
        uint16 cviValue;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint16 lastCVIValue, uint16 currCVIValue) external returns (uint16 _updateTurbulenceIndicatorPercent);

    function setTurbulenceUpdator(address newUpdator) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;
    function setTurbulenceDeviationThresholdPercent(uint16 newTurbulenceDeviationThresholdPercent) external;
    function setTurbulenceDeviationPercent(uint16 newTurbulenceDeviationPercentage) external;
    function setCollateralToBuyingPremiumMapping(uint16[] calldata newCollateralToBuyingPremiumMapping) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalHeartbeats, uint256 newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithTurbulence(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio, uint16 _turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    
    function calculateSingleUnitFundingFee(CVIValue[] calldata cviValues) external view returns (uint256 fundingFee);
    function calculateClosePositionFeePercent(uint256 creationTimestamp) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function buyingPremiumFeeMaxPercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
}

