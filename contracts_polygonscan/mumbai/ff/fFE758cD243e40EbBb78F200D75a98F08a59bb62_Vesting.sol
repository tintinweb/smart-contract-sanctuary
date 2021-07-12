// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20.sol";

/// @title Firestarter Vesting Contract
/// @author Michael, Daniel Lee
/// @notice You can use this contract for token vesting
/// @dev All function calls are currently implemented without side effects
contract Vesting {
    using SafeMath for uint256;

    struct VestingParams {
        // Name of this tokenomics
        string vestingName;
        // Total amount to be vested
        uint256 amountToBeVested;
        // Percent of tokens initially unlocked
        uint256 initalUnlock;
        // Amount of time in seconds between withdrawal periods.
        uint256 withdrawInterval;
        // Release percent in each withdrawing interval
        uint256 releaseRate;
        // Number of periods before start release.
        uint256 lockPeriod;
    }

    struct VestingInfo {
        // Total amount of tokens to be vested.
        uint256 totalAmount;
        // The amount that has been withdrawn.
        uint256 amountWithdrawn;
    }

    /// @notice 100%
    uint256 public constant maxPercent = 1e10;

    /*************************** Vesting Params *************************/

    /// @notice Total balance of this vesting contract
    uint256 public amountToBeVested;

    /// @notice Name of this vesting
    string public vestingName;

    /// @notice Start time of vesting
    uint256 public startTime;

    /// @notice Amount of time in seconds between withdrawal periods.
    uint256 public withdrawInterval;

    /// @notice Release percent in each withdrawing interval
    uint256 public releaseRate;

    /// @notice Percent of tokens initially unlocked
    uint256 public initialUnlock;

    /// @notice Number of periods before start release.
    uint256 public lockPeriod;

    /// @notice Reward token of the project.
    address public rewardToken;

    /*************************** Status Info *************************/

    /// @notice Owner address(presale)
    address public owner;

    /// @notice Vesting schedule info for each user(presale)
    mapping(address => VestingInfo) public recipients;

    /// @notice Sum of all user's vesting amount
    uint256 public totalVestingAmount;

    /// @notice An event emitted when the vesting schedule is updated.
    event VestingInfoUpdated(address registeredAddress, uint256 totalAmount);

    /// @notice An event emitted when withdraw happens
    event Withdraw(address registeredAddress, uint256 amountWithdrawn);

    /// @notice An event emitted when startTime is set
    event StartTimeSet(uint256 startTime);

    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    constructor(address _rewardToken, VestingParams memory _params) {
        require(_params.withdrawInterval > 0);

        owner = msg.sender;
        rewardToken = _rewardToken;

        vestingName = _params.vestingName;
        amountToBeVested = _params.amountToBeVested;
        initialUnlock = _params.initalUnlock;
        withdrawInterval = _params.withdrawInterval;
        releaseRate = _params.releaseRate;
        lockPeriod = _params.lockPeriod;
    }

    /**
     * @notice Init Presale contract
     * @dev Thic changes the owner to presale
     * @param presale Presale contract address
     */
    function init(address presale) external onlyOwner {
        owner = presale;
        IERC20(rewardToken).approve(presale, type(uint256).max);
    }

    /**
     * @notice Update user vesting information
     * @dev This is called by presale contract
     * @param recp Address of Recipient
     * @param amount Amount of reward token
     */
    function updateRecipient(address recp, uint256 amount) external onlyOwner {
        require(
            startTime == 0 || startTime >= block.timestamp,
            "updateRecipient: Cannot update the receipient after started"
        );
        require(amount > 0, "updateRecipient: Cannot vest 0");

        // remove previous amount and add new amount
        totalVestingAmount = totalVestingAmount
        .sub(recipients[recp].totalAmount)
        .add(amount);

        uint256 depositedAmount = IERC20(rewardToken).balanceOf(address(this));
        require(
            depositedAmount >= totalVestingAmount,
            "updateRecipient: Vesting amount exceeds current balance"
        );

        recipients[recp].totalAmount = amount;

        emit VestingInfoUpdated(recp, amount);
    }

    /**
     * @notice Set vesting start time
     * @dev This should be called before vesting starts
     * @param newStartTime New start time
     */
    function setStartTime(uint256 newStartTime) external onlyOwner {
        // Check if enough amount is deposited to this contract
        // require(IERC20(rewardToken).balanceOf(address(this)) >= amountToBeVested, "setStartTime: Enough amount of reward token should be vested.");

        // Only allow to change start time before the counting starts
        require(
            startTime == 0 || startTime >= block.timestamp,
            "setStartTime: Already started"
        );
        require(
            newStartTime > block.timestamp,
            "setStartTime: Should be time in future"
        );

        startTime = newStartTime;

        emit StartTimeSet(newStartTime);
    }

    /**
     * @notice Withdraw tokens when vesting is ended
     * @dev Anyone can claim their tokens
     * Warning: Take care of re-entrancy attack here.
     * Reward tokens are from not our own, which means
     * re-entrancy can happen when the transfer happens.
     * For now, we do checks-effects-interactsions, but
     * for absolute safety, we may use reentracny guard.
     */
    function withdraw() external {
        VestingInfo storage vestingInfo = recipients[msg.sender];
        if (vestingInfo.totalAmount == 0) return;

        uint256 _vested = vested(msg.sender);
        uint256 _withdrawable = withdrawable(msg.sender);
        vestingInfo.amountWithdrawn = _vested;

        require(_withdrawable > 0, "Nothing to withdraw");
        require(IERC20(rewardToken).transfer(msg.sender, _withdrawable));
        emit Withdraw(msg.sender, _withdrawable);
    }

    /**
     * @notice Returns the amount of vested reward tokens
     * @dev Calculates available amount depending on vesting params
     * @param beneficiary address of the beneficiary
     * @return amount : Amount of vested tokens
     */
    function vested(address beneficiary)
        public
        view
        virtual
        returns (uint256 amount)
    {
        uint256 endTime = startTime.add(lockPeriod);
        VestingInfo memory vestingInfo = recipients[beneficiary];

        if (
            startTime == 0 ||
            vestingInfo.totalAmount == 0 ||
            block.timestamp <= endTime
        ) {
            return 0;
        }

        uint256 initialUnlockAmount = vestingInfo
        .totalAmount
        .mul(initialUnlock)
        .div(maxPercent);

        uint256 unlockRate = vestingInfo
        .totalAmount
        .mul(releaseRate)
        .div(maxPercent)
        .div(withdrawInterval);

        uint256 vestedAmount = unlockRate.mul(block.timestamp.sub(endTime)).add(
            initialUnlockAmount
        );

        if (vestedAmount > vestingInfo.totalAmount) {
            return vestingInfo.totalAmount;
        }
        return vestedAmount;
    }

    /**
     * @notice Return locked amount
     * @return Locked reward token amount
     */
    function locked(address beneficiary) public view returns (uint256) {
        uint256 totalAmount = recipients[beneficiary].totalAmount;
        uint256 vestedAmount = vested(beneficiary);
        return totalAmount.sub(vestedAmount);
    }

    /**
     * @notice Return remaining withdrawable amount
     * @return Remaining vested amount of reward token
     */
    function withdrawable(address beneficiary) public view returns (uint256) {
        uint256 vestedAmount = vested(beneficiary);
        uint256 withdrawnAmount = recipients[beneficiary].amountWithdrawn;
        return vestedAmount.sub(withdrawnAmount);
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}