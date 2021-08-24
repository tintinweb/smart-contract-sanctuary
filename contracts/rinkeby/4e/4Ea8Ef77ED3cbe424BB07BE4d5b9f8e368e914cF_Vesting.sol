// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Vesting
 * @dev The vesting vault contract for the initial token sale
 * Taken from https://github.com/archerdao/governance/blob/master/contracts/Vesting.sol
 */
contract Vesting {
    using SafeMath for uint256;

    /// @notice Grant definition
    struct Grant {
        uint256 amount;
        uint256 totalClaimed;
        uint256 perSecond;          // Reward per second
    }

    struct Pool {
        uint256 startTime;
        uint256 endTime;
        uint256 vestingDuration;    // In seconds
        uint256 amount;             // Total size of pool
        uint256 totalClaimed;
        uint256 grants;             // Amount of investors
    }

    /// @dev Used to translate vesting periods specified in days to seconds
    uint256 constant internal SECONDS_PER_DAY = 86400;

    /// @notice Polka token
    IERC20 public token;

    /// @notice Mapping of recipient address > token grant
    mapping (address => Grant) public tokenGrants;

    /// @notice Current vesting period is the same for all grants.
    /// @dev Each pool has its own contract.
    Pool public pool;

    /// @notice Current owner of this contract
    address public owner;

    /// @notice Event emitted when a new grant is created
    event GrantAdded(address indexed recipient, uint256 indexed amount);
    
    event VestingPeriodAdded(uint256 startTime, uint16 vestingDuration);

    /// @notice Event emitted when tokens are claimed by a recipient from a grant
    event GrantTokensClaimed(address indexed recipient, uint256 indexed amountClaimed);
    
    /// @notice Event emitted when the owner of the vesting contract is updated
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

    /**
     * @notice Construct a new Vesting contract
     * @param _token Address of ARCH token
     */
    constructor(address _token) {
        require(_token != address(0), "Vest::constructor: must be valid token address");
        token = IERC20(_token);
        owner = msg.sender;
    }

    /**
     * @notice Add a new vesting period for this contract.
     * @param vestingDuration The vesting period in days
     * @param startTime The unix timestamp when the grant will start
     */
    function addVestingPeriod(uint256 startTime, uint256 vestingDuration) external {
        require(startTime > 0 && vestingDuration > 0, "0 parameter");
        require(pool.startTime == 0, "Pool added already");
        require(startTime > block.timestamp, "Too early vesting time");
        require(msg.sender == owner, "Vest::addVestingPeriod: not owner");

        require(vestingDuration > 0, "Vest::addTokenGrant: duration must be > 0");
        if (vestingDuration < SECONDS_PER_DAY) {
            require(vestingDuration <= SECONDS_PER_DAY.mul(10).mul(365), "Vest::addTokenGrant: duration more than 10 years");
        } 

        pool.startTime = startTime;
        pool.vestingDuration = vestingDuration;
        pool.endTime = startTime.add(vestingDuration);
    }


    /**
     * @notice Add list of grants in group.
     */
    function addTokenGrants(uint16 grantAmount, address[] memory recipient, uint256[] memory amount) external {
        require(msg.sender == owner, "Vest::addTokenGrants: not owner");
        require(pool.startTime > 0, "Vest::addTokenGrants: no pool");
        require(grantAmount > 0, "Vest::addTokenGrants: zero amount");
        require(grantAmount <= 100, "Vest::addTokenGrants: too many grants");
        require(recipient.length == grantAmount && amount.length == grantAmount, "Vest::addTokenGrants: invalid parameter number");

        uint256 amountSum = 0;
        for (uint16 i = 0; i < grantAmount; i++) {
            require(recipient[i] != address(0), "Vest:addTokenGrants: zero address");
            require(tokenGrants[recipient[i]].amount == 0, "Vest::addTokenGrant: grant already exists for account");

            require(amount[i] > 0, "Vest::addTokenGrant: amount == 0");
            amountSum = amountSum.add(amount[i]);
        }

        // Transfer the grant tokens under the control of the vesting contract
        require(token.transferFrom(owner, address(this), amountSum), "Vest::addTokenGrant: transfer failed");

        for (uint16 i = 0; i < grantAmount; i++) {
 
            Grant memory grant = Grant({
                amount: amount[i],
                totalClaimed: 0,
                perSecond: amount[i].div(pool.vestingDuration)
            });
            tokenGrants[recipient[i]] = grant;
            emit GrantAdded(recipient[i], amount[i]);
        }

        pool.amount = pool.amount.add(amountSum);
    }

    /**
     * @notice Get token grant for recipient
     * @param recipient The address that has a grant
     * @return the grant
     */
    function getTokenGrant(address recipient) public view returns(Grant memory){
        return tokenGrants[recipient];
    }

    function getNow() external view returns(uint256) {
        return block.timestamp;
    }

    /**
     * @notice Calculate the vested and unclaimed tokens available for `recipient` to claim
     * @dev Due to rounding errors once grant duration is reached, returns the entire left grant amount
     * @param recipient The address that has a grant
     * @return The amount recipient can claim
     */
    function calculateGrantClaim(address recipient) public view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (block.timestamp < pool.startTime) {
            return 0;
        }

        uint256 cap = block.timestamp;
        if (cap > pool.endTime) {
            cap = pool.endTime;
        }
        uint256 elapsedTime = cap.sub(pool.startTime);

        // If over vesting duration, all tokens vested
        if (elapsedTime >= pool.vestingDuration) {
            uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);
            return remainingGrant;
        } else {
            uint256 amountVested = tokenGrant.perSecond.mul(elapsedTime);
            uint256 claimableAmount = amountVested.sub(tokenGrant.totalClaimed);
            return claimableAmount;
        }
    }

    /**
     * @notice Calculate the vested (claimed + unclaimed) tokens for `recipient`
     * @param recipient The address that has a grant
     * @return Total vested balance (claimed + unclaimed)
     */
    function vestedBalance(address recipient) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];

        // For grants created with a future start date, that hasn't been reached, return 0, 0
        if (block.timestamp < pool.startTime) {
            return 0;
        }

        uint256 cap = block.timestamp;
        if (cap > pool.endTime) {
            cap = pool.endTime;
        }
 
        // If over vesting duration, all tokens vested
        if (cap == pool.endTime) {
            return tokenGrant.amount;
        } else {
            uint256 elapsedTime = cap.sub(pool.startTime);
            uint256 amountVested = tokenGrant.perSecond.mul(elapsedTime);
            return amountVested;
        }
    }

    /**
     * @notice The balance claimed by `recipient`
     * @param recipient The address that has a grant
     * @return the number of claimed tokens by `recipient`
     */
    function claimedBalance(address recipient) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];
        return tokenGrant.totalClaimed;
    }

    /**
     * @notice Allows a grant recipient to claim their vested tokens
     * @dev Errors if no tokens have vested
     * @dev It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
     * @param recipient The address that has a grant
     */
    function claimVestedTokens(address recipient) external {
        uint256 amountVested = calculateGrantClaim(recipient);
        require(amountVested > 0, "Vest::claimVested: amountVested is 0");

        Grant storage tokenGrant = tokenGrants[recipient];
        
        require(token.transfer(recipient, amountVested), "Vest::claimVested: transfer failed");

        tokenGrant.totalClaimed = uint256(tokenGrant.totalClaimed.add(amountVested));
        pool.totalClaimed = pool.totalClaimed.add(amountVested);

        emit GrantTokensClaimed(recipient, amountVested);
    }

    /**
     * @notice Calculate the number of tokens that will vest per day for the given recipient
     * @param recipient The address that has a grant
     * @return Number of tokens that will vest per day
     */
    function tokensVestedPerDay(address recipient) public view returns(uint256) {
        Grant storage tokenGrant = tokenGrants[recipient];
        return tokenGrant.amount.div(uint256(pool.vestingDuration.div(SECONDS_PER_DAY)));
    }

    /**
     * @notice Change owner of vesting contract
     * @param newOwner New owner address
     */
    function changeOwner(address newOwner) 
        external
    {
        require(msg.sender == owner, "Vest::changeOwner: not owner");
        require(newOwner != address(0) && newOwner != address(this) && newOwner != address(token), "Vest::changeOwner: not valid address");

        address oldOwner = owner;
        owner = newOwner;
        emit ChangedOwner(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}