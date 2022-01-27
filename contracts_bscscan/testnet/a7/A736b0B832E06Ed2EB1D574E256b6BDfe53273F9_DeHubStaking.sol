// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interface/IDehubStaking.sol";
import "./interface/IDeHubRewardsV4.sol";

contract DeHubStaking is Ownable, AccessControl, Pausable, IDehubStaking {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Create a new role identifier for the minter role
  bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");

  // DeHub token contract
  IERC20 public dehubToken;
  // RewardsContract for weekly BNB claiming. This will enable holders to claim
  // their weekly BNB rewards without unstaking their tokens. Staking contract
  // will trigger restricted function passing in the holder address and staking
  // amount.
  IDeHubRewardsV4 public bnbRewardContract;
  // Holds staking pool data
  PoolInfo public pool;
  // Holds every stakers data
  mapping(address => UserInfo) public userInfo;
  // Early withdrawal fee
  uint16 public constant EARLY_WITHDRAW_FEE = 1200;
  // Address for early withdrawal fees to go to
  address public feeWallet;

  /**
   * Sets main DeHub token (can't be updated later).
   * Sets weekly BNB rewards contract (can be updated later, in case of upgrade).
   * Sets staking pool data.
   */
  constructor(
    IERC20 _dehubContractAddress,
    IDeHubRewardsV4 _bnbRewardContract,
    address _feeWallet,
    PoolInfo memory _pool
  ) {
    require(
      _pool.openBlock < _pool.closeBlock,
      "constructor: open/close blocks are wrong"
    );
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    dehubToken = _dehubContractAddress;
    bnbRewardContract = _bnbRewardContract;
    feeWallet = _feeWallet;
    pool = _pool;
  }

  /* -------------------------------------------------------------------------- */
  /*                             External Functions                             */
  /* -------------------------------------------------------------------------- */

  /**
   * @dev Function to update Weekly BNB rewards contract address.
   * This might be needed in case BNB Rewards Contract gets upgraded.
   */
  function setBnbRewardContract(IDeHubRewardsV4 _bnbRewardContract)
    external
    onlyOwner
  {
    bnbRewardContract = _bnbRewardContract;
  }

  /**
   * @dev Function to set early withdrawal fee wallet
   */
  function setFeeWallet(address _feeWallet) external onlyOwner {
    feeWallet = _feeWallet;
  }

  /**
   * @dev Function to fund the staking pool with DeHub tokens.
   * @param _amount Amount of DeHub tokens to be added to the pool for rewards.
   * @param _reflectionsAmount Amount of DeHub tokens to be added to the pool
   * for reflections rewards. This is optional and can be set to 0. You could
   * need this if you have pulled funds from the previous contract because of
   * the emergency and it already had some reflections rewards accumulated
   * Note: can be funded only by the funder.
   */
  function fund(uint256 _amount, uint256 _reflectionsAmount)
    external
    onlyFunder
  {
    address sender = address(msg.sender);
    require(_amount > 0, "fund: amount can't be 0");
    require(
      dehubToken.balanceOf(sender) >= _amount,
      "fund: not enough DeHub tokens"
    );

    uint256 totalAmount = _amount + _reflectionsAmount;
    // Main staking rewards counter
    pool.harvestFund += _amount;

    dehubToken.safeTransferFrom(sender, address(this), totalAmount);
    emit ContractFunded(sender, _amount, _reflectionsAmount);
  }

  /**
   * @notice Harvest the rewards and withdraw tokens.
   * @dev This function can be called only once after the pool has closed and
   * only if user has a stake. It will send out reflections and staking reward
   * plus all of the tokens staked by user.
   */
  function harvestAndWithdraw() external canHarvest whenNotPaused {
    UserInfo storage user = userInfo[msg.sender];
    require(user.harvested == false, "Harvest: already done");
    require(user.amount > 0, "Harvest: no staked tokens");
    (
      uint256 claimableReflection,
      uint256 claimableHarvest
    ) = _updatePoolAndResolveRewards(user, user.amount);
    // Transfer total rewards plus all users staked tokens.
    uint256 total = claimableReflection.add(claimableHarvest).add(user.amount);
    _safeDehubTransfer(msg.sender, total);
    // Decrement pool and user total amounts.
    pool.totalStaked -= user.amount;
    pool.totalStakers--;
    user.amount = 0;
    user.harvested = true;

    emit Harvested(msg.sender, total, claimableReflection, claimableHarvest);
  }

  /**
   * @notice Claim weekly BNB rewards without unstaking the tokens.
   * @dev This function calls DeHubRewards contract as a proxy to trigger BNB
   * send out. Staking contract must be set on the DeHubRewards contract first to
   * be accepted.
   * Note: in addition to the staked amount, we will add reflection share
   * accumulated at the time of the claim.
   * Note: Rewards contract will combine staked and wallet balance amounts.
   */
  function claimBNBRewards() external whenNotPaused {
    UserInfo storage user = userInfo[msg.sender];
    require(user.amount > 0, "claimBNBRewards: No tokens staked.");
    (
      uint256 claimableReflection,
      uint256 claimableHarvest
    ) = _updatePoolAndResolveRewards(user, user.amount);
    // Trigger BNB rewards contract to send out the rewards if possible.
    uint256 bnbShare = IDeHubRewardsV4(bnbRewardContract).sendRewardToStaker(
      msg.sender,
      user.amount.add(claimableReflection).add(claimableHarvest)
    );
    emit ClaimBNBRewards(msg.sender, bnbShare);
  }

  /**
   * @notice Stake DeHub tokens by depositing them to the pool.
   * @dev This function can be called multiple times between pool.openTimeStamp
   * and pool.closeTimeStamp. After that deposits are not accepted anymore.
   * Note: we make sure that upon adding tokens into the pool, we take into
   * account how many tokens and for how long user has been staking already.
   * Based on that we calculate new reflection/staking rewards for that user
   * and store necessary variables for the future deposits/withdrawals.
   */
  function deposit(uint256 _amount) external canDeposit whenNotPaused {
    UserInfo storage user = userInfo[msg.sender];
    uint256 updatedUserAmount = user.amount + _amount;
    (
      uint256 claimableReflection,
      uint256 claimableHarvest
    ) = _updatePoolAndResolveRewards(user, updatedUserAmount);
    // Transfer DeHub tokens to the pool.
    dehubToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    // Increment pool and user total amounts.
    pool.totalStaked += _amount;
    // Increments the total stakers if the user is not already staking.
    if (user.amount == 0) {
      pool.totalStakers++;
    }
    user.amount = updatedUserAmount;

    emit Deposit(msg.sender, _amount, claimableReflection, claimableHarvest);
  }

  /**
   * @notice Early Un-stake DeHub tokens from the pool incuring a fee.
   * @dev This function can be called multiple times between pool.openTimeStamp
   * and pool.closeTimeStamp. After the pool is closed, 'harvestAndWithdraw'
   * should be called instead.
   * Note: we make sure that upon removing tokens from the pool, we take into
   * account how many tokens and for how long user has been staking already.
   * Based on that we calculate new reflection/staking rewards for that user
   * and store necessary variables for the future deposits/withdrawals.
   * Note: we do not give the reflections back to the user at the withdrawal,
   * all the accumulated reflections will be included at the end upon harvest.
   */
  function withdraw(uint256 _amount) external canWithdraw whenNotPaused {
    UserInfo storage user = userInfo[msg.sender];
    require(user.amount >= _amount, "withdraw: amount is too big");
    uint256 updatedUserAmount = user.amount - _amount;
    (
      uint256 claimableReflection,
      uint256 claimableHarvest
    ) = _updatePoolAndResolveRewards(user, updatedUserAmount);
    // Transfer fee from the pool to the fee wallet if fund was not pulled.
    uint256 fee;
    if (!pool.emergencyPull) {
      fee = (_amount * EARLY_WITHDRAW_FEE) / 10000;
      dehubToken.safeTransfer(feeWallet, fee);
    }
    // Transfer rest of the DeHub tokens from the pool to the user.
    dehubToken.safeTransfer(address(msg.sender), _amount.sub(fee));
    // Decrement pool and user total amounts.
    pool.totalStaked -= _amount;
    // Decrement the total stakers if the user has no more tokens staked.
    if (updatedUserAmount == 0) {
      pool.totalStakers--;
    }
    user.amount = updatedUserAmount;

    emit Withdraw(
      msg.sender,
      _amount,
      fee,
      claimableReflection,
      claimableHarvest
    );
  }

  /**
   * @dev Function to withdraw reward funds from the pool.
   * Pulls funded amount and accumulated amount if possible.
   * Note: Can be called only by the owner for the emergency purposes.
   * (e.x.: new contract will need to be deployed upon finding a vulnerability)
   */
  function pullAllReward() external onlyFunder {
    uint256 totalRefl = getTotalReflectionsAccumulated();
    require(
      pool.harvestFund > 0 || totalRefl > 0,
      "pullAllReward: no rewards to pull"
    );
    uint256 balance = dehubToken.balanceOf(address(this));
    // Leave only what belongs to stakers. (reflections will be given back
    // in the new contract).
    uint256 fundsToPull = balance.sub(pool.totalStaked);
    // Send total to the owner and emit event with the amounts so that we can
    // inject it to the new contract later.
    _safeDehubTransfer(address(msg.sender), fundsToPull);
    pool.harvestFund = 0;
    // Toggle emergency pull to enable early user withdrawals.
    pool.emergencyPull = true;

    emit PullAllReward(msg.sender, totalRefl, pool);
  }

  /**
   * @notice Calculate pending harvest amount to date.
   */
  function pendingHarvest(address _user)
    external
    view
    returns (uint256, uint256)
  {
    UserInfo storage user = userInfo[_user];

    uint256 valuePerBlock = _getValuePerBlock(
      pool.lastUpdateBlock,
      block.number
    );

    uint256 share = user.amount.mul(valuePerBlock).div(1e30);
    uint256 harvestPending = user.harvestPending;
    uint256 reflPending = user.reflectionPending;

    if (user.amount > 0) {
      uint256 newHarvestPending = share.sub(user.harvestDebt);
      uint256 newReflPending = share.sub(user.reflectionDebt);
      harvestPending += newHarvestPending;
      reflPending += newReflPending;
    }

    uint256 claimStakeShare = harvestPending.mul(pool.harvestFund).div(1e20);

    uint256 totalReflections = getTotalReflectionsAccumulated();
    uint256 claimReflShare = reflPending.mul(totalReflections).div(1e20);

    return (claimStakeShare, claimReflShare);
  }

  /* -------------------------------------------------------------------------- */
  /*                           External View Functions                          */
  /* -------------------------------------------------------------------------- */

  /**
   * @notice Function to get the projected rewards for a 'msg.sender' at the
   * end of the staking period.
   * @dev Projection doesn't know how the states will change in the future, so
   * it's based on the current state.
   */
  function projectedRewards(address _staker)
    external
    view
    returns (uint256 claimableReflection, uint256 claimableHarvest)
  {
    UserInfo memory user = userInfo[_staker];
    if (user.amount == 0) return (0, 0);

    claimableReflection = (
      user.amount.mul(1e15).mul(getTotalReflectionsAccumulated()).div(
        pool.totalStaked
      )
    );

    claimableHarvest = user.amount.mul(1e15).mul(pool.harvestFund).div(
      pool.totalStaked
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              Public Functions                              */
  /* -------------------------------------------------------------------------- */

  /**
   * @dev Update the pool data with the latest calculations.
   * This function must be called before any new tokens are deposited/withdrawn.
   * The data updated in the pool will be used to re-calculate the rewards.
   */
  function updatePool() public {
    // Update only lastUpdateBlock if no tokens were staked (first deposit)
    if (pool.totalStaked == 0) {
      pool.lastUpdateBlock = block.number;
      return;
    }
    // Update value per block
    pool.valuePerBlock = _getValuePerBlock(pool.lastUpdateBlock, block.number);
    pool.lastUpdateBlock = block.number;

    if (block.number >= pool.closeBlock) {
      pool.reflectionSpanshot = getTotalReflectionsAccumulated();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                            Public View Functions                           */
  /* -------------------------------------------------------------------------- */

  /**
   * @dev Function to get the total amount of reflections accumulated by this contract.
   * Reflections are constantly increasing on each token transaction, so to get the
   * total amount of reflections accumulated by this contract, we need to substract
   * "harvestFund" and "totalStaked" from the token balance of the contract.
   * Note: it can be that somenone will just send DeHub tokens directly to the
   * contract, we can't do much about it and it's not a big deal. All tokens,
   * which are not allocated to "harvestFund" will be considered as reflections.
   */
  function getTotalReflectionsAccumulated() public view returns (uint256) {
    // Check if the snapshot is already created.
    if (pool.reflectionSpanshot > 0) {
      return pool.reflectionSpanshot;
    }
    // If not, calculate it.
    uint256 balance = dehubToken.balanceOf(address(this));
    if (balance == 0) {
      return 0;
    } else if (balance > pool.harvestFund.add(pool.totalStaked)) {
      uint256 totalReflectionsAccumulated = balance.sub(pool.harvestFund).sub(
        pool.totalStaked
      );
      return totalReflectionsAccumulated;
    } else {
      return 0;
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                             Internal Functions                             */
  /* -------------------------------------------------------------------------- */

  /**
   * @dev Safe transfer of RIOs from one address to another, taking into account
   * possible rounding errors
   */
  function _safeDehubTransfer(address _to, uint256 _amount) internal {
    address _from = address(this);
    uint256 dehubBal = dehubToken.balanceOf(_from);
    if (_amount > dehubBal) {
      dehubToken.safeTransfer(_to, dehubBal);
    } else {
      dehubToken.safeTransfer(_to, _amount);
    }
  }

  /**
   * @dev Function to get the distance between two blocks.
   */
  function _getBlockDelta(uint256 _from, uint256 _to)
    internal
    pure
    returns (uint256)
  {
    return _to.sub(_from);
  }

  /**
   * @dev Helper function which calculates the block value per block.
   * Note: keep it as a view.
   */
  function _getValuePerBlock(uint256 _blockFrom, uint256 _blockTo)
    internal
    view
    returns (uint256)
  {
    //    require(_blockFrom < _blockTo, "from block must be bigger");
    uint256 blockDelta = _blockFrom >= pool.closeBlock
      ? 0
      : _getBlockDelta(
        _blockFrom,
        _blockTo < pool.closeBlock ? _blockTo : pool.closeBlock
      );
    uint256 valuePerBlock;
    uint256 totalBlock = pool.closeBlock - pool.openBlock;
    if (pool.totalStaked > 0) {
      valuePerBlock = pool.valuePerBlock.add(
        blockDelta.mul(1e50).div(totalBlock).div(pool.totalStaked)
      );
    }
    return valuePerBlock;
  }

  /**
   * @dev Resolves claimable harvest reward at the requested block.
   * It will update harvest related variables inside user struct and return
   * most up to date claimable share from the harvestFund.
   */
  function _resolveClaimableHarvest(
    UserInfo storage user,
    uint256 updatedUserAmount
  ) internal returns (uint256) {
    uint256 harvShare = user.amount.mul(pool.valuePerBlock).div(1e30);
    // If user is adding tokens on top of his previous stake or removing a portion,
    // then make sure to update his pending amount so that harvest rewards are
    // distributed proportionally from the current block.
    if (user.amount > 0) {
      // Adjust pending reflection based on the current block.
      uint256 newHarvestPending = harvShare.sub(user.harvestDebt);
      user.harvestPending += newHarvestPending;
    }
    // Current harvest rewards share will be saved so it can be substracted from
    // the future rewards share to calculate new newHarvestPending.
    user.harvestDebt = updatedUserAmount.mul(pool.valuePerBlock).div(1e30);

    uint256 claimShare = user.harvestPending.mul(pool.harvestFund).div(1e20);
    return claimShare;
  }

  /**
   * @dev Resolves claimable reflections at the requested block.
   * It will update reflection related variables inside user struct and return
   * most up to date claimable share from the accumulated reflections.
   */
  function _resolveClaimableReflection(
    UserInfo storage user,
    uint256 updatedUserAmount
  ) internal returns (uint256) {
    uint256 reflShare = user.amount.mul(pool.valuePerBlock).div(1e30);
    // If user is adding tokens on top of his previous stake or removing portion,
    // then make sure to update his pending amount so that reflections are
    // distributed proportionally from the current block.
    if (user.amount > 0) {
      // Adjust pending reflection based on the current block.
      uint256 newReflectionPending = reflShare.sub(user.reflectionDebt);
      user.reflectionPending += newReflectionPending;
    }
    // Current reflections share will be saved so it can be substracted from
    // the future reflections share to calculate new newReflectionPending.
    user.reflectionDebt = updatedUserAmount.mul(pool.valuePerBlock).div(1e30);

    uint256 totalReflections = getTotalReflectionsAccumulated();
    uint256 claimShare = user.reflectionPending.mul(totalReflections).div(1e20);
    return claimShare;
  }

  /**
   * @dev Helper function to update the pool and resolve the rewards.
   * It will update the pool and user variables and return the claimable
   * reflection and harvest rewards.
   */
  function _updatePoolAndResolveRewards(
    UserInfo storage user,
    uint256 updatedUserAmount
  ) internal returns (uint256 claimableReflection, uint256 claimableHarvest) {
    // Update the pool before performing the (re)calculations of the reflection
    // rewards. This is necessary so that we know how many blocks have passed
    // since the last claimBNBRewards and can do the math.
    updatePool();
    // Get the claimable reflection amount and update the user variables.
    claimableReflection = _resolveClaimableReflection(user, updatedUserAmount);
    // Get the staking reward amount and update the user variables.
    claimableHarvest = _resolveClaimableHarvest(user, updatedUserAmount);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Modifiers                                 */
  /* -------------------------------------------------------------------------- */

  modifier canDeposit() {
    require(block.number >= pool.openBlock, "Pool: Pool is not opened");
    require(block.number < pool.closeBlock, "Pool: Pool is closed");
    _;
  }

  modifier canHarvest() {
    require(block.number >= pool.closeBlock, "Pool: pool is not closed");
    _;
  }

  modifier canWithdraw() {
    require(block.number >= pool.openBlock, "Pool: Pool is not opened");
    require(block.number < pool.closeBlock, "Pool: Pool is closed");
    _;
  }

  modifier onlyFunder() {
    require(hasRole(FUNDER_ROLE, msg.sender), "Caller is not a funder");
    _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDehubStaking {
  // Info of each user.
  struct UserInfo {
    // Track total staked amount by the holder.
    uint256 amount;
    // Latest amount of reflection debt since last update.
    uint256 reflectionDebt;
    // Latest amount of tokens from reflections which belong to the user.
    uint256 reflectionPending;
    // Latest amount of staking reward debt since last update.
    uint256 harvestDebt;
    // Latest amount of tokens from staking which belong to the user.
    uint256 harvestPending;
    // User harvested toggle, to prevent multiple harvestings.
    bool harvested;
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 openTimeStamp;
    uint256 closeTimeStamp;
    uint256 openBlock;
    uint256 closeBlock;
    // Track total amount of LP tokens in the pool deposited by the holders.
    uint256 totalStaked;
    // Track total users staking in the pool.
    uint256 totalStakers;
    // Reward value per block coefficient.
    uint256 valuePerBlock;
    // Track last time the pool was updated.
    uint256 lastUpdateBlock;
    // Track total funds allocated for rewards.
    uint256 harvestFund;
    // Will be set on a first harvest tx, to freeze accumulated reflection value.
    uint256 reflectionSpanshot;
    // Show if funds and reflections were pulled from the pool due to emergency.
    bool emergencyPull;
  }

  event Deposit(
    address indexed user,
    uint256 amount,
    uint256 claimableReflection,
    uint256 claimableHarvest
  );
  event Withdraw(
    address indexed user,
    uint256 amount,
    uint256 fee,
    uint256 claimableReflection,
    uint256 claimableHarvest
  );
  event ContractFunded(
    address indexed from,
    uint256 amount,
    uint256 reflectionsAmount
  );
  event Harvested(
    address indexed user,
    uint256 amount,
    uint256 claimableReflection,
    uint256 claimableHarvest
  );
  event PullAllReward(address indexed user, uint256 totalRefl, PoolInfo pool);
  event ClaimBNBRewards(address indexed user, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IDeHubRewardsV4 {
  // function bnbAccumulatedForDistribution (  ) external view returns ( uint256 );
  // function calcClaimableShare ( address _holderAddr, uint256 _circulatingSupply, uint256 _lpTokens, uint256 _claimableDistribution, uint256 _stakeAmount ) external view returns ( uint256 );
  // function calcCurrentClaimableShare ( address holderAddr, uint256 stakeAmount ) external view returns ( uint256 );
  // function claimCycleHours (  ) external view returns ( uint256 );
  // function claimReward (  ) external returns ( uint256 );
  // function claimableDistribution (  ) external view returns ( uint256 );
  // function dehubToken (  ) external view returns ( address );
  // function disableRewardDistribution (  ) external returns ( bool );
  // function enableRewardDistribution ( uint256 cycleHours ) external returns ( uint256 );
  // function hasAlreadyClaimed ( address holderAddr ) external view returns ( bool );
  // function hasCyclePassed (  ) external view returns ( bool );
  // function initialize (  ) external;
  // function isDistributionEnabled (  ) external view returns ( bool );
  // function lastCycleResetTimestamp (  ) external view returns ( uint256 );
  // function nextCycleResetTimestamp (  ) external view returns ( uint256 );
  // function owner (  ) external view returns ( address );
  // function pullBnb ( uint256 amount, address to ) external;
  // function renounceOwnership (  ) external;
  // function resetRewardDistribution ( uint256 cycleHours ) external returns ( uint256 );
  // function sendReward ( address holderAddr ) external returns ( uint256 );
  function sendRewardToStaker(address _stakerAddr, uint256 _stakeAmount)
    external
    returns (uint256);

  // function setDehubToken ( address contractAddr ) external;
  // function setLPAddress ( address _lpAddr ) external;
  function setStakingAddress(address _stakingAddress) external;

  function stakingAddress() external view returns (address);
  // function totalClaimed (  ) external view returns ( uint256 );
  // function totalClaimedDuringCycle (  ) external view returns ( uint256 );
  // function transferOwnership ( address newOwner ) external;
  // function uniswapV2Pair (  ) external view returns ( address );
  // function upgradeTo ( address newImplementation ) external;
  // function upgradeToAndCall ( address newImplementation, bytes data ) external;
  // function upgradeToV2 (  ) external;
  // function upgradeToV3 (  ) external;
  // function upgradeToV4 (  ) external;
  // function version (  ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}