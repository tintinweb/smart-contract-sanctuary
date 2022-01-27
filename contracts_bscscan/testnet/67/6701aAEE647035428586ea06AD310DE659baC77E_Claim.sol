// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Claim
 * @author gotbit
 */

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    function transferOwnership(address newOwner_) external onlyOwner {
        require(newOwner_ != address(0), 'You cant tranfer ownerships to address 0x0');
        require(newOwner_ != owner, 'You cant transfer ownerships to yourself');
        emit OwnershipTransferred(owner, newOwner_);
        owner = newOwner_;
    }
}

contract Claim is Ownable {
    using SafeMath for uint256;
    IERC20 public token;

    uint256 public start;
    uint256 public finish;
    uint256 public totalBank;

    struct User {
        uint256 bank;
        uint256 claimed;
        uint256 debt; // Unclaimed from previous program
        uint256 finish; // Compare with global finish to determine if user is in current 2nd+ program
    }

    mapping(address => User) public users;

    event Started(uint256 timestamp, uint256 rewardsDuration, address who);
    event Claimed(address indexed who, uint256 amount);
    event SetBank(address indexed who, uint256 bank, uint256 debt);
    event RecoveredERC20(address owner, uint256 amount);
    event RecoveredAnotherERC20(IERC20 token, address owner, uint256 amount);

    constructor(address owner_, IERC20 token_) {
        owner = owner_;
        token = token_;
    }

    function claim() external returns (bool) {
        address who = msg.sender;
        User storage user = users[who];
        uint256 absoluteClaimable = getAbsoluteClaimable(who);
        uint256 amount = (absoluteClaimable + user.debt) - user.claimed;

        require(amount > 0, 'You dont have LIME to harvest');
        require(token.balanceOf(address(this)) >= amount, 'Not enough tokens on contract');
        require(token.transfer(who, amount), 'Transfer issue');

        totalBank -= amount;
        user.debt = 0;
        user.claimed = absoluteClaimable;

        emit Claimed(who, amount);
        return true;
    }

    function getAbsoluteClaimable(address who) public view returns (uint256) {
        User storage user = users[who];

        // No program or user never participated
        if (start == 0 || user.finish == 0) return 0;

        if (user.finish == finish) {
            // Nth program, and user is included in last activated program
            uint256 lastApplicableTime = getCurrentTime();
            if (lastApplicableTime >= finish) return user.bank;
            if (lastApplicableTime <= start.add((finish.sub(start).div(3))))
                // 10% per part for the first 2 parts of six parts
                return user.bank.mul(lastApplicableTime.sub(start)).div(finish.sub(start)).mul(3).div(5);
            else
                // 20% per part for the rest 4 parts of six parts
                return user.bank
                .mul(lastApplicableTime.mul(6).sub(finish).sub(start.mul(5)))
                .div(finish.sub(start).mul(5));
        } else {
            // Nth program, and user is not included in last activated program
            // always true in this case:
            // getCurrentTime() > user.finish
            return user.bank;
        }
    }

    // For UI
    function getActualClaimable(address who) public view returns (uint256) {
        return (getAbsoluteClaimable(who) + users[who].debt) - users[who].claimed;
    }

    function infoBundle(address who)
    public
    view
    returns (
        User memory uInfo,
        uint256 uBalance,
        uint256 uClaimable,
        uint256 cBalance,
        uint256 cStart,
        uint256 cFinish,
        uint256 cBank
    )
    {
        uInfo = users[who];
        uBalance = token.balanceOf(who);
        uClaimable = getActualClaimable(who);
        cBalance = token.balanceOf(address(this));
        cStart = start;
        cFinish = finish;
        cBank = totalBank;
    }

    function setRewards(
        address[] memory whos,
        uint256[] memory banks,
        uint256 durationDays
    ) public onlyOwner {
        require(whos.length == banks.length, 'Different lengths');

        require(getCurrentTime() > finish, 'Claiming programm is already started. Wait for its end');
        start = getCurrentTime();
        finish = start + (durationDays * (1 days));

        for (uint256 i = 0; i < whos.length; i++) {
            address who = whos[i];
            uint256 bank = banks[i];
            uint256 debt = (users[who].bank + users[who].debt) - users[who].claimed;

            users[who] = User({bank : bank, claimed : 0, debt : debt, finish : finish});
            emit SetBank(who, bank, debt);

            totalBank += bank;
        }

        emit Started(start, durationDays, msg.sender);
    }

    function recoverERC20(uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= totalBank + amount, 'RecoverERC20 error: Not enough balance on contract');
        require(token.transfer(owner, amount), 'Transfer issue');
        emit RecoveredERC20(owner, amount);
    }

    function recoverAnotherERC20(IERC20 token_, uint256 amount) external onlyOwner {
        require(token_ != token, 'For recovering main token use another function');
        require(token_.balanceOf(address(this)) >= amount, 'RecoverAnotherERC20 error: Not enough balance on contract');
        require(token_.transfer(owner, amount), 'Transfer issue');
        emit RecoveredAnotherERC20(token_, owner, amount);
    }

    function getCurrentTime()
    internal
    virtual
    view
    returns (uint256){
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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