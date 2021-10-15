// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Initializable.sol";

interface IStaking {
    // Views
    function balanceOf(address account) external view returns (uint256);

    function unclaimedRewardsOf(address account)
        external
        view
        returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function restakeRewards() external;

    function claimRewards() external;

    // Only Owner
    function switchFees(
        bool _takeStakeFee,
        bool _takeUnstakeFee,
        bool _takeRestakeFee
    ) external;

    function switchRewards(bool enableRewards) external;

    function emergencyWithdrawRewards(address emergencyAddress, uint256 amount)
        external;

    // Events
    event Staked(address account, uint256 amount);
    event Unstaked(address account, uint256 amount);
    event RestakedRewards(address account, uint256 amount);
    event ClaimedRewards(address account, uint256 amount);
    event PayedFee(address account, uint256 amount);
    event SwitchedFees(
        bool _takeStakeFee,
        bool _takeUnstakeFee,
        bool _takeRestakeFee
    );
    event SwitchedRewards(bool enableRewards);
    event RewardsWithdrawnEmergently(address emergencyAddress, uint256 amount);
}

contract PLEStaking is Ownable, Pausable, Initializable, IStaking {
    using SafeMath for uint256;

    IERC20 public token = IERC20(0x36Bf64F3bbF6C0b5483f3A9f5f794bc91B104a06);
    address public feeAddress = 0xF508b3f4b0300bF1a5b0227A2578D3613d909425;

    // rewards & fees
    uint256 public constant REWARD_RATE = 4000; // 40.00% APY
    uint256 public constant STAKE_FEE_RATE = 150; // 1.50% staking fee
    uint256 public constant UNSTAKE_FEE_RATE = 50; // 0.50% unstaking fee
    uint256 public constant RESTAKE_FEE_RATE = 50; // 0.50% restaking fee
    bool public takeStakeFee;
    bool public takeUnstakeFee;
    bool public takeRestakeFee;
    uint256 public stopRewardsBlock;
    uint256 public availableRewards;

    // stake holders
    struct StakeHolder {
        uint256 stakedTokens;
        uint256 lastClaimedBlock;
        uint256 totalEarnedTokens;
    }
    uint256 public totalStaked;
    mapping(address => StakeHolder) public stakeHolders;

    // Views
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return stakeHolders[account].stakedTokens;
    }

    function unclaimedRewardsOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _calculateUnclaimedRewards(account);
    }

    /**
     * Rewards Calculation:
     * rewards = (stakedTokens * blockDiff * rewardRatePerBlock)
     * rewardRatePerBlock =
     * 4000 (REWARD_RATE)
     * ------------------
     * 10000 * 365 (days/Y) * 24 (H/day) * 60 (M/H) * 4 (Blocks/M) = 21024e6
     */
    function _calculateUnclaimedRewards(address account)
        private
        view
        returns (uint256)
    {
        uint256 stakedTokens = stakeHolders[account].stakedTokens;
        if (stakedTokens == 0) return 0;
        // block diff calculation
        uint256 blockDiff = stakeHolders[account].lastClaimedBlock;
        if (stopRewardsBlock == 0) {
            blockDiff = block.number.sub(blockDiff);
        } else {
            if (stopRewardsBlock <= blockDiff) return 0;
            blockDiff = stopRewardsBlock.sub(blockDiff);
        }
        // rewards calculation
        uint256 unclaimedRewards = stakedTokens.mul(blockDiff).mul(REWARD_RATE);
        unclaimedRewards = unclaimedRewards.div(21024e6); // Audit: for gas efficieny
        if (unclaimedRewards > availableRewards) return 0;
        return unclaimedRewards;
    }

    // Mutative
    function stake(uint256 amount)
        external
        override
        whenNotPaused
        onlyInitialized
    {
        require(amount > 0, "Cannot stake 0 tokens");
        if (stakeHolders[msg.sender].stakedTokens > 0) {
            _restakeRewards(); // Audit: return value not check purposely
        } else {
            stakeHolders[msg.sender].lastClaimedBlock = block.number;
        }
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Could not transfer tokens from msg.sender to staking contract"
        );
        uint256 amountAfterFees = _takeFees(
            amount,
            takeStakeFee,
            STAKE_FEE_RATE
        );
        stakeHolders[msg.sender].stakedTokens = stakeHolders[msg.sender]
            .stakedTokens
            .add(amountAfterFees);
        totalStaked = totalStaked.add(amountAfterFees);
        emit Staked(msg.sender, amountAfterFees);
    }

    function unstake(uint256 amount)
        external
        override
        whenNotPaused
        onlyInitialized
    {
        require(amount > 0, "Cannot unstake 0 tokens");
        require(
            stakeHolders[msg.sender].stakedTokens >= amount,
            "Not enough tokens to unstake"
        );
        uint256 unclaimedRewards = _getRewards();
        stakeHolders[msg.sender].stakedTokens = stakeHolders[msg.sender]
            .stakedTokens
            .sub(amount);
        totalStaked = totalStaked.sub(amount);
        uint256 amountAfterFees = _takeFees(
            amount,
            takeUnstakeFee,
            UNSTAKE_FEE_RATE
        );
        if (unclaimedRewards > 0) {
            amountAfterFees = amountAfterFees.add(unclaimedRewards);
            emit ClaimedRewards(msg.sender, unclaimedRewards);
        }
        require(
            token.transfer(msg.sender, amountAfterFees),
            "Could not transfer tokens from staking contract to msg.sender"
        );
        emit Unstaked(msg.sender, amountAfterFees.sub(unclaimedRewards));
    }

    function restakeRewards() external override whenNotPaused onlyInitialized {
        require(_restakeRewards(), "Not rewards to restake");
    }

    function claimRewards() external override whenNotPaused onlyInitialized {
        uint256 unclaimedRewards = _getRewards();
        require(unclaimedRewards > 0, "Not rewards to claim");
        require(
            token.transfer(msg.sender, unclaimedRewards),
            "Could not transfer rewards from staking contract to msg.sender"
        );
        emit ClaimedRewards(msg.sender, unclaimedRewards);
    }

    // Mutative & Private
    function _restakeRewards() private returns (bool) {
        uint256 unclaimedRewards = _getRewards();
        if (unclaimedRewards == 0) return false;
        unclaimedRewards = _takeFees(
            unclaimedRewards,
            takeRestakeFee,
            RESTAKE_FEE_RATE
        );
        stakeHolders[msg.sender].stakedTokens = stakeHolders[msg.sender]
            .stakedTokens
            .add(unclaimedRewards);
        totalStaked = totalStaked.add(unclaimedRewards);
        emit RestakedRewards(msg.sender, unclaimedRewards);
        return true;
    }

    function _getRewards() private returns (uint256) {
        uint256 unclaimedRewards = _calculateUnclaimedRewards(msg.sender);
        if (unclaimedRewards == 0) return 0;
        availableRewards = availableRewards.sub(unclaimedRewards);
        stakeHolders[msg.sender].lastClaimedBlock = block.number;
        stakeHolders[msg.sender].totalEarnedTokens = stakeHolders[msg.sender]
            .totalEarnedTokens
            .add(unclaimedRewards);
        return unclaimedRewards;
    }

    function _takeFees(
        uint256 amount,
        bool takeFee,
        uint256 feeRate
    ) private returns (uint256) {
        if (takeFee) {
            uint256 fee = (amount.mul(feeRate)).div(1e4);
            require(token.transfer(feeAddress, fee), "Could not transfer fees");
            emit PayedFee(msg.sender, fee);
            return amount.sub(fee);
        }
        return amount;
    }

    // Only Owner
    function init() external onlyOwner whenNotPaused notInitialized {
        require(
            token.transferFrom(msg.sender, address(this), 8e6 ether),
            "Could not transfer 8,000,000 as rewards"
        );
        availableRewards = 8e6 ether;
        stopRewardsBlock = 0;
        takeStakeFee = false;
        takeUnstakeFee = true;
        takeRestakeFee = true;
        _init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function switchFees(
        bool _takeStakeFee,
        bool _takeUnstakeFee,
        bool _takeRestakeFee
    ) external override onlyOwner onlyInitialized {
        takeStakeFee = _takeStakeFee;
        takeUnstakeFee = _takeUnstakeFee;
        takeRestakeFee = _takeRestakeFee;
        emit SwitchedFees(_takeStakeFee, _takeUnstakeFee, _takeRestakeFee);
    }

    function switchRewards(bool enableRewards)
        external
        override
        onlyOwner
        onlyInitialized
    {
        if (enableRewards) {
            stopRewardsBlock = 0;
        } else {
            stopRewardsBlock = block.number;
        }
        emit SwitchedRewards(enableRewards);
    }

    function emergencyWithdrawRewards(address emergencyAddress, uint256 amount)
        external
        override
        onlyOwner
        onlyInitialized
    {
        require(
            availableRewards >= amount,
            "No available rewards for emergent withdrawal"
        );
        require(
            token.transfer(emergencyAddress, amount),
            "Could not transfer tokens"
        );
        availableRewards = availableRewards.sub(amount);
        emit RewardsWithdrawnEmergently(emergencyAddress, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Initializable is Context {

    event Initialized(address account);

    bool private _initialized;

    constructor() {
        _initialized = false;
    }

    function initialized() public view virtual returns (bool) {
        return _initialized;
    }

    modifier notInitialized() {
        require(!initialized(), "Initializable: Already initialized");
        _;
    }

    modifier onlyInitialized() {
        require(initialized(), "Initializable: Not initialized");
        _;
    }

    function _init() internal virtual notInitialized {
        _initialized = true;
        emit Initialized(_msgSender());
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
}