// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./AuctionStorage.sol";

contract Auction is AuctionStorage {
    using SafeMath for uint256;

    constructor(uint256 _bettingPeriod, uint256 _taskSettlementPeriod) {
        require(_bettingPeriod != 0, "INVALID_BETTING_PERIOD");
        require(_taskSettlementPeriod != 0, "INVALID_BETTING_PERIOD");

        bettingPeriod = _bettingPeriod;
        taskSettlementPeriod = _taskSettlementPeriod;
    }

    function updateBettingPeriod(uint256 _bettingPeriod) external onlyOwner {
        require(_bettingPeriod != 0, "INVALID_BETTING_PERIOD");
        bettingPeriod = _bettingPeriod;

        emit BettingPeriodUpdated(_bettingPeriod);
    }

    function updateTaskSettlementPeriod(uint256 _taskSettlementPeriod)
        external
        onlyOwner
    {
        require(_taskSettlementPeriod != 0, "INVALID_SETTLEMENT_PERIOD");
        taskSettlementPeriod = _taskSettlementPeriod;
        emit TaskSettlementPeriodUpdated(_taskSettlementPeriod);
    }

    function updateMinBetStake(uint256 _minBetStake) external onlyOwner {
        require(_minBetStake != 0, "INVALID_MIN_BET_STAKE");
        MIN_BET_STAKE = _minBetStake;
        emit BetStakeUpdated(_minBetStake);
    }

    function createTask(bytes32 taskDescription, uint256 timeLimit) external {
        require(taskDescription != bytes32(0), "NEED_TASK_DESCRIPTION");
        require(timeLimit != 0, "TIME_LIMIT_CANNOT_BE_ZERO");

        taskId = taskId + 1;

        Task storage _task = tasks[taskId];
        _task.taskDescription = taskDescription;
        _task.taskTimeLimit = timeLimit;
        _task.taskStartTime = block.timestamp;
        _task.taskOwner = msg.sender;

        emit TaskCreated(
            msg.sender,
            taskId,
            taskDescription,
            timeLimit,
            block.timestamp
        );
    }

    function bet(uint256 taskId, uint256 bidAmount) external payable {
        Task storage task = tasks[taskId];
        require(getState(taskId) == States.BETTING, "NOT_IN_BETTING_STATE");
        require(msg.value >= MIN_BET_STAKE, "NEED_MIN_STAKE");
        require(bidAmount != 0, "BET_AMOUNT_CANNOT_BE_ZERO");
        address previousWorker;
        uint256 previousBet;
        if (task.bidAmount > 0) {
            require(bidAmount < task.bidAmount, "BET_AMOUNT_HIGH");
            previousWorker = task.workerSelected;
            previousBet = task.amountStaked;
        }

        task.amountStaked = msg.value;
        task.bidAmount = bidAmount;
        task.workerSelected = msg.sender;

        if (previousBet > 0) safeTransferETH(previousWorker, previousBet);

        emit BetPlaced(msg.sender, msg.value, taskId);
    }

    function submitTask(uint256 taskId, bytes32 work) external {
        require(
            getState(taskId) == States.WORK_IN_PROGRESS,
            "WORK_CANNOT_BE_SUBMITTED"
        );
        Task storage task = tasks[taskId];
        task.submittedWork = work;
    }

    function settleWork(uint256 taskId) external payable {
        States state = getState(taskId);
        Task storage task = tasks[taskId];

        require(
            state == States.TASK_SUBMITTED || state == States.SLASHED,
            "CANNOT_BE_SETTLED"
        );
        require(!task.isSettled, "ALREADY_SETTLED");

        address paidTo;
        uint256 amountPaid = task.amountStaked.add(msg.value);

        if (state == States.TASK_SUBMITTED) {
            require(msg.value >= task.bidAmount, "NO_PAYMENT_RECEIVED");
            paidTo = task.workerSelected;
        } else if (state == States.SLASHED) {
            paidTo = task.taskOwner;
        }

        task.isSettled = true;

        safeTransferETH(paidTo, amountPaid);
        emit TaskSettled(taskId, paidTo, amountPaid);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function getState(uint256 taskId) public view returns (States) {
        Task memory task = tasks[taskId];

        if (task.taskOwner == address(0)) {
            return States.INVALID;
        }

        if (block.timestamp <= bettingPeriod.add(task.taskStartTime)) {
            return States.BETTING;
        }

        if (task.bidAmount == 0) {
            return States.CANCELLED;
        }

        if (task.submittedWork != bytes32(0)) {
            return States.TASK_SUBMITTED;
        }

        if (
            block.timestamp >
            (task.taskStartTime).add(bettingPeriod).add(task.taskTimeLimit).add(
                taskSettlementPeriod
            )
        ) {
            return States.SLASHED;
        }

        return States.WORK_IN_PROGRESS;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AuctionStorage is Ownable {
    enum States {
        BETTING,
        WORK_IN_PROGRESS,
        TASK_SUBMITTED,
        CANCELLED,
        SLASHED,
        INVALID
    }

    struct Task {
        address taskOwner;
        bytes32 taskDescription;
        uint256 taskStartTime;
        uint256 taskTimeLimit;
        address workerSelected;
        uint256 bidAmount;
        uint256 amountStaked;
        bytes32 submittedWork;
        bool isSettled;
    }

    mapping(uint256 => Task) public tasks;

    uint256 public bettingPeriod;
    uint256 public taskSettlementPeriod;
    uint256 public taskId;
    uint256 public MIN_BET_STAKE = 10**8;

    event BettingPeriodUpdated(uint256 bettingPeriod);
    event TaskSettlementPeriodUpdated(uint256 taskSettlementPeriod);
    event BetStakeUpdated(uint256 betStake);
    event TaskCreated(
        address taskOwner,
        uint256 taskId,
        bytes32 taskDescription,
        uint256 timeLimit,
        uint256 creationTimestamp
    );
    event BetPlaced(address indexed bidder, uint256 betAmount, uint256 taskId);
    event TaskSettled(
        uint256 taskId,
        address indexed paidTo,
        uint256 amountPaid
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}