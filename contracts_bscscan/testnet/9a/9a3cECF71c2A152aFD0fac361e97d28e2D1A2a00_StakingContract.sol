//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './IRewardToken.sol';

contract StakingContract is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  // Token given as reward for staking
  IRewardToken public immutable rewardToken;
  // Token deposited for staking
  IERC20 public immutable stakedToken;

  // Total staked token balance
  uint256 public totalStakedSupply;
  // Staked LP token balance of each user
  mapping(address => uint256) public stakedBalances;
  // First deposit timestamp of each user
  mapping(address => uint256) public firstDepositTimestamps;
  // Used for calculating the latest rewards. Resets after each reward claim.
  mapping(address => uint256) public rewardCalculationStartTimestamps;
  // The pending rewards, saved each time user tops up staked balance
  mapping(address => uint256) public pendingRewardsUpToLastDeposit;

  // Yearly mint rate per staked token
  uint256 public immutable APRM;
  // Basis points of staked token processing fee taken when user withdraws
  uint256 public immutable processingFeeForStakedToken;

  // Minimum number of tokens that can be staked
  uint256 public minimumStakeAmount;
  // Minimum stake time to receive rewards after the first deposit
  uint256 public minimumStakeTime;
  // Address of fee vault
  address public feeVaultAddress;

  bool public depositsPaused;
  bool public withdrawalsPaused;

  event Deposit(address indexed account, uint256 indexed amount);
  event Withdrawal(address indexed account, uint256 indexed amount);
  event EmergencyWithdrawal(address indexed account, uint256 indexed amount);
  event RewardClaim(address indexed account, uint256 indexed amount);
  event DepositsPaused(bool indexed paused);
  event WithdrawalsPaused(bool indexed paused);

  constructor(
    address _rewardToken,
    address _stakedToken,
    uint256 _APRM,
    uint256 _minimumStakeAmount,
    uint256 _minimumStakeTime,
    uint256 _processingFeeForStakedToken,
    address _feeVaultAddress
  ) {
    rewardToken = IRewardToken(_rewardToken);
    stakedToken = IERC20(_stakedToken);
    APRM = _APRM;
    minimumStakeAmount = _minimumStakeAmount;
    minimumStakeTime = _minimumStakeTime;
    processingFeeForStakedToken = _processingFeeForStakedToken;
    feeVaultAddress = _feeVaultAddress;
    depositsPaused = false;
    withdrawalsPaused = false;
  }

  /**
   * @dev Throws if deposit is paused.
   */
  modifier whenDepositNotPaused() {
    require(!depositsPaused, 'DEPOSITS ARE PAUSED');
    _;
  }

  /**
   * @dev Throws if withdraw is paused.
   */
  modifier whenWithdrawNotPaused() {
    require(!withdrawalsPaused, 'WITHDRAWS ARE PAUSED');
    _;
  }

  /**
   * Allows user to deposit the token for staking and earn reward token, calculated with the APRM.
   * To be able to deposit user should give allowance to the staking contract and
   * deposit at least the minimum stake amount.
   */
  function deposit(uint256 amount) external nonReentrant whenDepositNotPaused {
    require(amount <= stakedToken.allowance(msg.sender, address(this)), 'NOT ENOUGH ALLOWANCE');
    require(amount <= stakedToken.balanceOf(msg.sender), 'NOT ENOUGH TOKEN BALANCE');
    require(amount >= minimumStakeAmount, 'AMOUNT CANNOT BE SMALLER THAN MINIMUM AMOUNT');

    uint256 balanceOfAccount = stakedBalances[msg.sender];

    if (balanceOfAccount > 0) {
      // Adds all pending rewards to pending rewards of the account.
      pendingRewardsUpToLastDeposit[msg.sender] = calculateTotalPendingRewards(msg.sender);
    }

    // Adds amount to total supply and balance of the account, sets timestamps of the account.
    totalStakedSupply = totalStakedSupply.add(amount);
    stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
    if (firstDepositTimestamps[msg.sender] == 0) {
      firstDepositTimestamps[msg.sender] = block.timestamp;
    }
    rewardCalculationStartTimestamps[msg.sender] = block.timestamp;

    // Receives tokens from the account.
    bool success = stakedToken.transferFrom(msg.sender, address(this), amount);
    require(success, 'TRANSFER_FROM REVERTED');

    emit Deposit(msg.sender, amount);
  }

  /**
   * Claim pending rewards if minimum stake time has passed since the first deposit.
   */
  function claimRewards() external nonReentrant whenWithdrawNotPaused {
    uint256 userBalance = stakedBalances[msg.sender];
    require(userBalance > 0, 'NO STAKED BALANCE');
    require(
      (block.timestamp - firstDepositTimestamps[msg.sender]) >= minimumStakeTime,
      'MINIMUM STAKE TIME HAS NOT PASSED'
    );

    uint256 totalRewardsAmount = calculateTotalPendingRewards(msg.sender);
    require(totalRewardsAmount > 0, 'NO PENDING REWARDS');

    rewardCalculationStartTimestamps[msg.sender] = block.timestamp;
    pendingRewardsUpToLastDeposit[msg.sender] = 0;

    // Mints total rewards amount for the user and fee vault.
    rewardToken.mint(msg.sender, totalRewardsAmount);
    rewardToken.mint(feeVaultAddress, totalRewardsAmount);
    emit RewardClaim(msg.sender, totalRewardsAmount);
  }

  /**
   * Withdraws all tokens of an account and rewards.
   */
  function withdraw() external nonReentrant whenWithdrawNotPaused {
    uint256 userBalance = stakedBalances[msg.sender];
    require(userBalance > 0, 'NO STAKED BALANCE');

    // Calculate total rewards amount (if minimumStakeTime has passed), and reset timestamp and pending rewards of the account
    uint256 totalRewardsAmount;
    if (block.timestamp - firstDepositTimestamps[msg.sender] >= minimumStakeTime) {
      totalRewardsAmount = calculateTotalPendingRewards(msg.sender);
    }
    rewardCalculationStartTimestamps[msg.sender] = 0;
    pendingRewardsUpToLastDeposit[msg.sender] = 0;
    firstDepositTimestamps[msg.sender] = 0;

    // Substract amount from total supply and reset balance of the account.
    totalStakedSupply = totalStakedSupply.sub(userBalance);
    stakedBalances[msg.sender] = 0;

    // Send staked tokens to the user account and fees to feeVault.
    uint256 stakeTokenFee = userBalance.mul(processingFeeForStakedToken).div(10000);
    uint256 stakeTokenAmountAfterFee = userBalance.sub(stakeTokenFee);
    bool transferToSender = stakedToken.transfer(msg.sender, stakeTokenAmountAfterFee);
    bool transferToVault = stakedToken.transfer(feeVaultAddress, stakeTokenFee);
    require(transferToSender && transferToVault, 'TRANSFER REVERTED');
    emit Withdrawal(msg.sender, stakeTokenAmountAfterFee);

    if (totalRewardsAmount > 0) {
      // Mints total rewards amount for the user and fee vault.
      rewardToken.mint(msg.sender, totalRewardsAmount);
      rewardToken.mint(feeVaultAddress, totalRewardsAmount);
      emit RewardClaim(msg.sender, totalRewardsAmount);
    }
  }

  /**
   * Withdraws all tokens of an account immediately without a reward.
   */
  function emergencyWithdraw() external nonReentrant {
    uint256 userBalance = stakedBalances[msg.sender];
    require(userBalance > 0, 'NO STAKED BALANCE');

    // Substract amount from total supply and resets all data of the account.
    totalStakedSupply = totalStakedSupply.sub(userBalance);
    stakedBalances[msg.sender] = 0;
    firstDepositTimestamps[msg.sender] = 0;
    rewardCalculationStartTimestamps[msg.sender] = 0;
    pendingRewardsUpToLastDeposit[msg.sender] = 0;

    // Sends tokens to the account and fees to vault.
    uint256 stakeTokenFee = userBalance.mul(processingFeeForStakedToken).div(10000);
    uint256 stakeTokenAmountAfterFee = userBalance.sub(stakeTokenFee);
    bool transferToSender = stakedToken.transfer(msg.sender, stakeTokenAmountAfterFee);
    bool transferToVault = stakedToken.transfer(feeVaultAddress, stakeTokenFee);
    require(transferToSender && transferToVault, 'TRANSFER REVERTED');
    emit EmergencyWithdrawal(msg.sender, stakeTokenAmountAfterFee);
  }

  /**
   * Calculate rewards.
   */
  function calculateLatestRewards(address userAddress) public view returns (uint256) {
    // Subtract current time from starting time and convert the timestamp to the day.
    uint256 dayCount = (block.timestamp - rewardCalculationStartTimestamps[userAddress]).div(60).div(60).div(24);
    // Calculate yearly mint rate.
    uint256 yearlyMint = stakedBalances[userAddress].mul(APRM).div(10000);
    // Calculate total amount of interest.
    uint256 rewards = yearlyMint.div(365).mul(dayCount);

    return rewards;
  }

  /**
   * Return total pending rewards.
   */
  function calculateTotalPendingRewards(address userAddress) public view returns (uint256) {
    uint256 pendingSinceLastDeposit = calculateLatestRewards(userAddress);
    return pendingSinceLastDeposit.add(pendingRewardsUpToLastDeposit[userAddress]);
  }

  /**
   * Set Minimum Stake Amount.
   */
  function setMinimumStakeAmount(uint256 _minimumStakeAmount) public onlyOwner {
    minimumStakeAmount = _minimumStakeAmount;
  }

  /**
   * Set Minimum Stake Time.
   */
  function setMinimumStakeTime(uint256 _minimumStakeTime) public onlyOwner {
    minimumStakeTime = _minimumStakeTime;
  }

  /**
   * Set Processing Fee Vault Address.
   */
  function setFeeVaultAddress(address _address) public onlyOwner {
    feeVaultAddress = _address;
  }

  /**
   * Pause/unpause deposits.
   */
  function pauseDeposits(bool pause) public onlyOwner {
    depositsPaused = pause;
    emit DepositsPaused(pause);
  }

  /**
   * Pause/unpause withdrawals.
   */
  function pauseWithdrawals(bool pause) public onlyOwner {
    withdrawalsPaused = pause;
    emit WithdrawalsPaused(pause);
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
    constructor () {
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

    constructor () {
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

interface IRewardToken {
  function giveMintingConsent() external;

  function removeMintingConsent() external;

  function proposeMinter(address proposedMinterAddress) external;

  function approveProposedMinter(address proposedMinterAddress) external;

  function proposeMinterRemoval(address minterAddress) external;

  function approveMinterRemoval(address minterAddress) external;

  function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}