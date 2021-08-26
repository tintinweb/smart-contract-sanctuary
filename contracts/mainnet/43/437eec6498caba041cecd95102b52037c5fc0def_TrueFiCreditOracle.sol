// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface ITrueFiCreditOracle {
    enum Status {Eligible, OnHold, Ineligible}

    function status(address account) external view returns (Status);

    function score(address account) external view returns (uint8);

    function maxBorrowerLimit(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /**
     * @dev Return true if and only if the contract has been initialized
     * @return whether the contract has been initialized
     */
    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Context} from "Context.sol";

import {Initializable} from "Initializable.sol";

/**
 * @title UpgradeableClaimable
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. Since
 * this contract combines Claimable and UpgradableOwnable contracts, ownership
 * can be later change via 2 step method {transferOwnership} and {claimOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract UpgradeableClaimable is Initializable, Context {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting a custom initial owner of choice.
     * @param __owner Initial owner of contract to be set.
     */
    function initialize(address __owner) internal initializer {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Math} from "Math.sol";
import {SafeMath} from "SafeMath.sol";
import {ITrueFiCreditOracle} from "ITrueFiCreditOracle.sol";
import {UpgradeableClaimable} from "UpgradeableClaimable.sol";

/**
 * @title TrueFiCreditOracle
 * @dev Contract which allows the storage of credit scores for TrueFi borrower accounts.
 *
 * Eligible accounts transition to OnHold after creditUpdatePeriod since their last credit update.
 * OnHold accounts cannot borrow. They transition to Ineligible after gracePeriod.
 * Ineligible accounts cannot borrow. If they owe outstanding debt, we can trigger a technical default.
 *
 * Score manager can update scores, but only owner can override eligibility Status
 *
 * Statuses:
 * - Eligible: Account can borrow from TrueFi
 * - OnHold: Account cannot borrow additional funds from TrueFi
 * - Ineligible: Account cannot borrow from TrueFi, and account can enter default
 */
contract TrueFiCreditOracle is ITrueFiCreditOracle, UpgradeableClaimable {
    using SafeMath for uint256;

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    // @dev Track credit scores for an account
    mapping(address => uint8) public override score;

    // @dev Track max borrowing limit for an account
    mapping(address => uint256) public override maxBorrowerLimit;

    // @dev Manager role authorized to set credit scores
    address public manager;

    // @dev Timestamp (in seconds since Unix epoch) when score eligibility expires
    mapping(address => uint256) public eligibleUntilTime;

    // @dev Duration in seconds between mandatory credit score updates
    uint256 public creditUpdatePeriod;

    // @dev Grace period in seconds before OnHold transitions to Ineligible
    uint256 public gracePeriod;

    // ======= STORAGE DECLARATION END ============

    /// @dev emit `newManager` when manager changed
    event ManagerChanged(address newManager);

    /// @dev emit `account`, `newScore` when score changed
    event ScoreChanged(address indexed account, uint8 indexed newScore);

    /// @dev emit `account`, `newMaxBorrowerLimit` when max borrow limit changed
    event MaxBorrowerLimitChanged(address indexed account, uint256 newMaxBorrowerLimit);

    /// @dev emit `account`, `timestamp` when eligibility time changed
    event EligibleUntilTimeChanged(address indexed account, uint256 timestamp);

    /// @dev emit `newCreditUpdatePeriod` when credit update period changed
    event CreditUpdatePeriodChanged(uint256 newCreditUpdatePeriod);

    /// @dev emit `newGracePeriod` when grace period changed
    event GracePeriodChanged(uint256 newGracePeriod);

    /// @dev initialize
    function initialize() public initializer {
        UpgradeableClaimable.initialize(msg.sender);
        manager = msg.sender;
        creditUpdatePeriod = 31 days;
        gracePeriod = 3 days;
    }

    // @dev only credit score manager
    modifier onlyManager() {
        require(msg.sender == manager, "TrueFiCreditOracle: Caller is not the manager");
        _;
    }

    /// @dev set credit update period to `newCreditUpdatePeriod`
    function setCreditUpdatePeriod(uint256 newCreditUpdatePeriod) external onlyOwner {
        creditUpdatePeriod = newCreditUpdatePeriod;
        emit CreditUpdatePeriodChanged(newCreditUpdatePeriod);
    }

    /// @dev set grace period to `newGracePeriod`
    function setGracePeriod(uint256 newGracePeriod) external onlyOwner {
        gracePeriod = newGracePeriod;
        emit GracePeriodChanged(newGracePeriod);
    }

    /**
     * @dev Get borrow status of `account`
     * @param account Account to get borrow status for
     * @return Borrow status for `account`
     */
    function status(address account) external override view returns (Status) {
        if (block.timestamp < eligibleUntilTime[account]) {
            return Status.Eligible;
        } else if (block.timestamp.sub(gracePeriod) < eligibleUntilTime[account]) {
            return Status.OnHold;
        }
        return Status.Ineligible;
    }

    /**
     * @dev Set `newScore` value for `account`
     * Scores are stored as uint8 allowing scores of 0-255
     */
    function setScore(address account, uint8 newScore) public onlyManager {
        _setEligibleUntilTime(account, Math.max(eligibleUntilTime[account], block.timestamp.add(creditUpdatePeriod)));
        score[account] = newScore;
        emit ScoreChanged(account, newScore);
    }

    /**
     * @dev Set `newMaxBorrowerLimit` value for `account`
     */
    function setMaxBorrowerLimit(address account, uint256 newMaxBorrowerLimit) public onlyManager {
        _setEligibleUntilTime(account, Math.max(eligibleUntilTime[account], block.timestamp.add(creditUpdatePeriod)));
        maxBorrowerLimit[account] = newMaxBorrowerLimit;
        emit MaxBorrowerLimitChanged(account, newMaxBorrowerLimit);
    }

    /**
     * @dev Set new manager for updating scores
     */
    function setManager(address newManager) public onlyOwner {
        manager = newManager;
        emit ManagerChanged(newManager);
    }

    /**
     * @dev Manually override Eligible status duration
     */
    function setEligibleForDuration(address account, uint256 duration) external onlyOwner {
        _setEligibleUntilTime(account, block.timestamp.add(duration));
    }

    /**
     * @dev Manually override status to OnHold
     */
    function setOnHold(address account) external onlyOwner {
        _setEligibleUntilTime(account, block.timestamp);
    }

    /**
     * @dev Manually override status to Ineligible
     */
    function setIneligible(address account) external onlyOwner {
        _setEligibleUntilTime(account, block.timestamp.sub(gracePeriod));
    }

    /// @dev internal function to set eligible until time
    function _setEligibleUntilTime(address account, uint256 timestamp) private {
        eligibleUntilTime[account] = timestamp;
        emit EligibleUntilTimeChanged(account, timestamp);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}