/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

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


pragma solidity >=0.6.10 <0.8.0;


abstract contract CoreUtility {
    using SafeMath for uint256;

    /// @dev UTC time of a day when the fund settles.
    uint256 internal constant SETTLEMENT_TIME = 14 hours;

    /// @dev Return end timestamp of the trading week containing a given timestamp.
    ///
    ///      A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///      and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function _endOfWeek(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp.add(1 weeks) - SETTLEMENT_TIME) / 1 weeks) * 1 weeks + SETTLEMENT_TIME;
    }
}


pragma solidity >=0.6.10 <0.8.0;

interface IBallot {
    struct Voter {
        uint256 amount;
        uint256 unlockTime;
        uint256 weight;
    }

    function count(uint256 timestamp) external view returns (uint256);

    function syncWithVotingEscrow(address account) external;
    // An event emitted when a new proposal is created
    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 amount,
        uint256 indexed unlockTime,
        uint256 indexed weight
    );
}


pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

interface IVotingEscrow {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function token() external view returns (address);

    function maxTime() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        returns (uint256);

    function getLockedBalance(address account) external view returns (LockedBalance memory);
}


pragma solidity >=0.6.10 <0.8.0;





contract InterestRateBallot is IBallot, CoreUtility {
    using SafeMath for uint256;

    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 amount,
        uint256 indexed unlockTime,
        uint256 indexed weight
    );

    uint256 private immutable _maxTime;

    uint256 public stepSize = 0.02e18;
    uint256 public minRange = 0;
    uint256 public maxOption = 3;

    IVotingEscrow public votingEscrow;

    mapping(address => Voter) public voters;

    // unlockTime => amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;
    mapping(uint256 => uint256) public scheduledWeightedUnlock;

    constructor(address votingEscrow_) public {
        votingEscrow = IVotingEscrow(votingEscrow_);
        _maxTime = votingEscrow.maxTime();
    }

    function getWeight(uint256 index) public view returns (uint256) {
        uint256 delta = stepSize.mul(index);
        return minRange.add(delta);
    }

    function getReceipt(address account) external view returns (Voter memory) {
        return voters[account];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceOfAtTimestamp(account, block.timestamp);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupplyAtTimestamp(block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256)
    {
        return _balanceOfAtTimestamp(account, timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _totalSupplyAtTimestamp(timestamp);
    }

    function sumAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _sumAtTimestamp(timestamp);
    }

    function count(uint256 timestamp) external view override returns (uint256) {
        return _averageAtTimestamp(timestamp);
    }

    function cast(uint256 option) external {
        require(option < maxOption, "Invalid option");

        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        Voter memory voter = voters[msg.sender];
        uint256 weight = getWeight(option);
        require(lockedBalance.amount > 0, "Zero value");

        // update scheduled unlock
        scheduledUnlock[voter.unlockTime] = scheduledUnlock[voter.unlockTime].sub(voter.amount);
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].add(
            lockedBalance.amount
        );

        scheduledWeightedUnlock[voter.unlockTime] = scheduledWeightedUnlock[voter.unlockTime].sub(
            voter.amount * voter.weight
        );
        scheduledWeightedUnlock[lockedBalance.unlockTime] = scheduledWeightedUnlock[
            lockedBalance.unlockTime
        ]
            .add(lockedBalance.amount * weight);

        emit Voted(
            msg.sender,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        // update voter amount per account
        voters[msg.sender] = Voter({
            amount: lockedBalance.amount,
            unlockTime: lockedBalance.unlockTime,
            weight: weight
        });
    }

    function syncWithVotingEscrow(address account) external override {
        Voter memory voter = voters[account];
        if (voter.amount == 0) {
            return; // The account did not voted before
        }

        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.amount == 0 || lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        // update scheduled unlock
        scheduledUnlock[voter.unlockTime] = scheduledUnlock[voter.unlockTime].sub(voter.amount);
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].add(
            lockedBalance.amount
        );

        scheduledWeightedUnlock[voter.unlockTime] = scheduledWeightedUnlock[voter.unlockTime].sub(
            voter.amount * voter.weight
        );
        scheduledWeightedUnlock[lockedBalance.unlockTime] = scheduledWeightedUnlock[
            lockedBalance.unlockTime
        ]
            .add(lockedBalance.amount * voter.weight);

        emit Voted(
            account,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        // update voter amount per account
        voters[account].amount = lockedBalance.amount;
        voters[account].unlockTime = lockedBalance.unlockTime;
    }

    function _balanceOfAtTimestamp(address account, uint256 timestamp)
        private
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        Voter memory voter = voters[account];
        if (timestamp > voter.unlockTime) {
            return 0;
        }
        return (voter.amount * (voter.unlockTime - timestamp)) / _maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 total = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            total += (scheduledUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
        }

        return total;
    }

    function _sumAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 sum = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            sum += (scheduledWeightedUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
        }

        return sum;
    }

    function _averageAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 sum = 0;
        uint256 total = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            sum += (scheduledWeightedUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
            total += (scheduledUnlock[weekCursor] * (weekCursor - timestamp)) / _maxTime;
        }

        if (total == 0) {
            return getWeight(maxOption.sub(1) / 2);
        }
        return sum / total;
    }
}