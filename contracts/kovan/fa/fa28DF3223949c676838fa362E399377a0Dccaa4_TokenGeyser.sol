pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./roles/Ownable.sol";
import "./interfaces/IStaking.sol";
import "./TokenPool.sol";


/**
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by Compound and Uniswap.
 *
 *  Distribution tokens are added to a locked pool in the contract and become unlocked over time according to a once-configurable unlock schedule. Once unlocked, they are available to be claimed by users.
 *
 *  A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share is a function of the number of tokens deposited as well as the length of time deposited.
 *
 *  Specifically, a user's share of the currently-unlocked pool equals their "deposit-seconds" divided by the global "deposit-seconds". This aligns the new token distribution with long term supporters of the project, addressing one of the major drawbacks of simple airdrops.
 *
 *  More background and motivation available at:
 *  https://github.com/ampleforth/RFCs/blob/master/RFCs/rfc-1.md
 */
contract TokenGeyser is IStaking, Ownable
{
  using SafeMath for uint;


  // single stake for user; user may have multiple.
  struct Stake
  {
    uint stakingShares;
    uint timestampSec;
  }

  // caches aggregated values from the User->Stake[] map to save computation.
  // if lastAccountingTimestampSec is 0, there's no entry for that user.
  struct UserTotals
  {
    uint stakingShares;
    uint stakingShareSeconds;
    uint lastAccountingTimestampSec;
  }

  // locked/unlocked state
  struct UnlockSchedule
  {
    uint initialLockedShares;
    uint unlockedShares;
    uint lastUnlockTimestampSec;
    uint endAtSec;
    uint durationSec;
  }


  TokenPool private _lockedPool;
  TokenPool private _unlockedPool;
  TokenPool private _stakingPool;

  UnlockSchedule[] public unlockSchedules;


  // time-bonus params
  uint public startBonus = 0;
  uint public bonusPeriodSec = 0;
  uint public constant BONUS_DECIMALS = 2;


  // global accounting state
  uint public totalLockedShares = 0;
  uint public totalStakingShares = 0;
  uint private _maxUnlockSchedules = 0;
  uint private _initialSharesPerToken = 0;
  uint private _totalStakingShareSeconds = 0;
  uint private _lastAccountingTimestampSec = now;


  // timestamp ordered stakes for each user, earliest to latest.
  mapping(address => Stake[]) private _userStakes;

  // staking values per user
  mapping(address => UserTotals) private _userTotals;

  mapping(address => uint) public initStakeTimestamps;


  event Staked(address indexed user, uint amount, uint total, bytes data);
  event Unstaked(address indexed user, uint amount, uint total, bytes data);

  event TokensClaimed(address indexed user, uint amount);
  event TokensLocked(uint amount, uint durationSec, uint total);
  event TokensUnlocked(uint amount, uint remainingLocked);


  /**
   * @param stakingToken The token users deposit as stake.
   * @param distributionToken The token users receive as they unstake.
   * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
   * @param startBonus_ Starting time bonus, BONUS_DECIMALS fixed point. e.g. 25% means user gets 25% of max distribution tokens.
   * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
   * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
   */
  constructor(IERC20 stakingToken, IERC20 distributionToken, uint maxUnlockSchedules, uint startBonus_, uint bonusPeriodSec_, uint initialSharesPerToken) public
  {
    // start bonus must be <= 100%
    require(startBonus_ <= 10 ** BONUS_DECIMALS, "TokenGeyser: start bonus too high");
    // if no period is desired, set startBonus = 100% & bonusPeriod to small val like 1sec.
    require(bonusPeriodSec_ != 0, "TokenGeyser: bonus period is 0");
    require(initialSharesPerToken > 0, "TokenGeyser: initialSharesPerToken is 0");

    _stakingPool = new TokenPool(stakingToken);
    _lockedPool = new TokenPool(distributionToken);
    _unlockedPool = new TokenPool(distributionToken);

    startBonus = startBonus_;
    bonusPeriodSec = bonusPeriodSec_;
    _maxUnlockSchedules = maxUnlockSchedules;
    _initialSharesPerToken = initialSharesPerToken;
  }


  /**
   * @dev Returns the number of unlockable shares from a given schedule. The returned value depends on the time since the last unlock. This function updates schedule accounting, but does not actually transfer any tokens.
   *
   * @param s Index of the unlock schedule.
   *
   * @return The number of unlocked shares.
   */
  function unlockScheduleShares(uint s) private returns (uint)
  {
    UnlockSchedule storage schedule = unlockSchedules[s];

    if (schedule.unlockedShares >= schedule.initialLockedShares)
    {
      return 0;
    }

    uint sharesToUnlock = 0;

    // Special case to handle any leftover dust from integer division
    if (now >= schedule.endAtSec)
    {
      sharesToUnlock = (schedule.initialLockedShares.sub(schedule.unlockedShares));
      schedule.lastUnlockTimestampSec = schedule.endAtSec;
    }
    else
    {
      sharesToUnlock = now.sub(schedule.lastUnlockTimestampSec).mul(schedule.initialLockedShares).div(schedule.durationSec);

      schedule.lastUnlockTimestampSec = now;
    }

    schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);

    return sharesToUnlock;
  }

  /**
   * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the previously defined unlock schedules. Publicly callable.
   *
   * @return Number of newly unlocked distribution tokens.
   */
  function unlockTokens() public returns (uint)
  {
    uint unlockedTokens = 0;
    uint lockedTokens = totalLocked();

    if (totalLockedShares == 0)
    {
      unlockedTokens = lockedTokens;
    }
    else
    {
      uint unlockedShares = 0;

      for (uint s = 0; s < unlockSchedules.length; s++)
      {
        unlockedShares = unlockedShares.add(unlockScheduleShares(s));
      }

      unlockedTokens = unlockedShares.mul(lockedTokens).div(totalLockedShares);
      totalLockedShares = totalLockedShares.sub(unlockedShares);
    }

    if (unlockedTokens > 0)
    {
      require(_lockedPool.transfer(address(_unlockedPool), unlockedTokens), "TokenGeyser: tx out of locked pool failed");

      emit TokensUnlocked(unlockedTokens, totalLocked());
    }

    return unlockedTokens;
  }

  /**
   * @dev A globally callable function to update the accounting state of the system.
   *      Global state and state for the caller are updated.
   *
   * @return [0] balance of the locked pool
   * @return [1] balance of the unlocked pool
   * @return [2] caller's staking share seconds
   * @return [3] global staking share seconds
   * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
   *
   * @return [5] block timestamp
   */
  function updateAccounting() public returns (uint, uint, uint, uint, uint, uint)
  {
    unlockTokens();


    uint newStakingShareSeconds = now.sub(_lastAccountingTimestampSec).mul(totalStakingShares);

    _totalStakingShareSeconds = _totalStakingShareSeconds.add(newStakingShareSeconds);
    _lastAccountingTimestampSec = now;


    UserTotals storage totals = _userTotals[msg.sender];

    uint newUserStakingShareSeconds = now.sub(totals.lastAccountingTimestampSec).mul(totals.stakingShares);

    totals.stakingShareSeconds = totals.stakingShareSeconds.add(newUserStakingShareSeconds);
    totals.lastAccountingTimestampSec = now;

    uint totalUserRewards = (_totalStakingShareSeconds > 0) ? totalUnlocked().mul(totals.stakingShareSeconds).div(_totalStakingShareSeconds) : 0;

    return (totalLocked(), totalUnlocked(), totals.stakingShareSeconds, _totalStakingShareSeconds, totalUserRewards, now);
  }

  /**
   * @dev allows the contract owner to add more locked distribution tokens, along with the associated "unlock schedule". These locked tokens immediately begin unlocking linearly over the duration of durationSec timeframe.
   *
   * @param amount Number of distribution tokens to lock. These are transferred from the caller.
   *
   * @param durationSec Length of time to linear unlock the tokens.
   */
  function lockTokens(uint amount, uint durationSec) external onlyOwner
  {
    require(unlockSchedules.length < _maxUnlockSchedules, "TokenGeyser: reached max unlock schedules");

    // update lockedTokens amount before using it in computations after.
    updateAccounting();

    UnlockSchedule memory schedule;

    uint lockedTokens = totalLocked();
    uint mintedLockedShares = (lockedTokens > 0) ? totalLockedShares.mul(amount).div(lockedTokens) : amount.mul(_initialSharesPerToken);


    schedule.initialLockedShares = mintedLockedShares;
    schedule.lastUnlockTimestampSec = now;
    schedule.endAtSec = now.add(durationSec);
    schedule.durationSec = durationSec;
    unlockSchedules.push(schedule);

    totalLockedShares = totalLockedShares.add(mintedLockedShares);

    require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount), "TokenGeyser: transfer into locked pool failed");

    emit TokensLocked(amount, durationSec, totalLocked());
  }


  /**
   * @dev Transfers amount of deposit tokens from the user.
   * @param amount Number of deposit tokens to stake.
   * @param data Not used.
   */
  function stake(uint amount, bytes calldata data) external
  {
    _stakeFor(msg.sender, msg.sender, amount);
  }

  /**
   * @dev Transfers amount of deposit tokens from the caller on behalf of user.
   * @param user User address who gains credit for this stake operation.
   * @param amount Number of deposit tokens to stake.
   * @param data Not used.
   */
  function stakeFor(address user, uint amount, bytes calldata data) external onlyOwner
  {
    _stakeFor(msg.sender, user, amount);
  }

  /**
   * @dev Private implementation of staking methods.
   * @param staker User address who deposits tokens to stake.
   * @param beneficiary User address who gains credit for this stake operation.
   * @param amount Number of deposit tokens to stake.
   */
  function _stakeFor(address staker, address beneficiary, uint amount) private
  {
    require(amount > 0, "TokenGeyser: stake amt is 0");
    require(beneficiary != address(0), "TokenGeyser: beneficiary is 0 addr");
    require(totalStakingShares == 0 || totalStaked() > 0, "TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do");


    if (initStakeTimestamps[beneficiary] == 0)
    {
      initStakeTimestamps[beneficiary] = now;
    }


    uint mintedStakingShares = (totalStakingShares > 0) ? totalStakingShares.mul(amount).div(totalStaked()) : amount.mul(_initialSharesPerToken);


    require(mintedStakingShares > 0, "TokenGeyser: Stake too small");

    updateAccounting();


    UserTotals storage totals = _userTotals[beneficiary];

    totals.stakingShares = totals.stakingShares.add(mintedStakingShares);
    totals.lastAccountingTimestampSec = now;


    Stake memory newStake = Stake(mintedStakingShares, now);

    _userStakes[beneficiary].push(newStake);
    totalStakingShares = totalStakingShares.add(mintedStakingShares);

    require(_stakingPool.token().transferFrom(staker, address(_stakingPool), amount), "TokenGeyser: tx into staking pool failed");

    emit Staked(beneficiary, amount, totalStakedFor(beneficiary), "");
  }


  /**
   * @dev Applies an additional time-bonus to a distribution amount. This is necessary to encourage long-term deposits instead of constant unstake/restakes.
   * The bonus-multiplier is the result of a linear function that starts at startBonus and ends at 100% over bonusPeriodSec, then stays at 100% thereafter.

   * @param currentRewardTokens The current number of distribution tokens already allotted for this unstake op. Any bonuses are already applied.

   * @param stakingShareSeconds The stakingShare-seconds that are being burned for new distribution tokens.

   * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate the time-bonus.

   * @return Updated amount of distribution tokens to award, with any bonus included on the newly added tokens.
   */
  function computeNewReward(uint currentRewardTokens, uint stakingShareSeconds, uint stakeTimeSec) private view returns (uint)
  {
    uint newRewardTokens = totalUnlocked().mul(stakingShareSeconds).div(_totalStakingShareSeconds);

    if (stakeTimeSec >= bonusPeriodSec)
    {
      return currentRewardTokens.add(newRewardTokens);
    }

    uint oneHundredPct = 10 ** BONUS_DECIMALS;
    uint bonusedReward = startBonus.add(oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(bonusPeriodSec)).mul(newRewardTokens).div(oneHundredPct);

    return currentRewardTokens.add(bonusedReward);
  }

  /**
   * @dev Unstakes a certain amount of previously deposited tokens. User also receives their allotted number of distribution tokens.
   * @param amount Number of deposit tokens to unstake / withdraw.
   * @param data Not used.
   */
  function unstake(uint amount, bytes calldata data) external
  {
    _unstake(amount);
  }

  /**
   * @param amount Number of deposit tokens to unstake / withdraw.
   * @return The total number of distribution tokens that would be rewarded.
   */
  function unstakeQuery(uint amount) public returns (uint)
  {
    return _unstake(amount);
  }

  /**
   * @dev Unstakes a certain amount of previously deposited tokens. User also receives their allotted number of distribution tokens.
   * @param amount Number of deposit tokens to unstake / withdraw.

   * @return The total number of distribution tokens rewarded.
   */
  function _unstake(uint amount) private returns (uint)
  {
    uint initStakeTimestamp = initStakeTimestamps[msg.sender];

    require(now > initStakeTimestamp.add(10 days), "TokenGeyser: in cooldown");

    updateAccounting();

    require(amount > 0, "TokenGeyser: unstake amt is 0");
    require(totalStakedFor(msg.sender) >= amount, "TokenGeyser: unstake amt > total user stakes");

    uint stakingSharesToBurn = totalStakingShares.mul(amount).div(totalStaked());

    require(stakingSharesToBurn > 0, "TokenGeyser: unstake too small");


    UserTotals storage totals = _userTotals[msg.sender];
    Stake[] storage accountStakes = _userStakes[msg.sender];

    // redeem from most recent stake and go backwards in time.
    uint rewardAmount = 0;
    uint stakingShareSecondsToBurn = 0;
    uint sharesLeftToBurn = stakingSharesToBurn;

    while (sharesLeftToBurn > 0)
    {
      Stake storage lastStake = accountStakes[accountStakes.length - 1];
      uint stakeTimeSec = now.sub(lastStake.timestampSec);
      uint newStakingShareSecondsToBurn = 0;

      if (lastStake.stakingShares <= sharesLeftToBurn)
      {
        // fully redeem a past stake
        newStakingShareSecondsToBurn = lastStake.stakingShares.mul(stakeTimeSec);
        rewardAmount = computeNewReward(rewardAmount, newStakingShareSecondsToBurn, stakeTimeSec);
        stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(newStakingShareSecondsToBurn);
        sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.stakingShares);
        accountStakes.length--;
      }
      else
      {
        // partially redeem a past stake
        newStakingShareSecondsToBurn = sharesLeftToBurn.mul(stakeTimeSec);
        rewardAmount = computeNewReward(rewardAmount, newStakingShareSecondsToBurn, stakeTimeSec);
        stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(newStakingShareSecondsToBurn);
        lastStake.stakingShares = lastStake.stakingShares.sub(sharesLeftToBurn);
        sharesLeftToBurn = 0;
      }
    }

    totals.stakingShareSeconds = totals.stakingShareSeconds.sub(stakingShareSecondsToBurn);
    totals.stakingShares = totals.stakingShares.sub(stakingSharesToBurn);


    _totalStakingShareSeconds = _totalStakingShareSeconds.sub(stakingShareSecondsToBurn);
    totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);


    uint unstakeFee = amount.mul(100).div(10000);

    if (now >= initStakeTimestamp.add(45 days))
    {
      unstakeFee = amount.mul(75).div(10000);
    }

    require(_stakingPool.transfer(owner(), unstakeFee), "TokenGeyser: err tx'ing fee");

    require(_stakingPool.transfer(msg.sender, amount.sub(unstakeFee)), "TokenGeyser: tx out of staking pool failed");
    require(_unlockedPool.transfer(msg.sender, rewardAmount), "TokenGeyser: tx out of unlocked pool failed");

    emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), "");
    emit TokensClaimed(msg.sender, rewardAmount);

    require(totalStakingShares == 0 || totalStaked() > 0, "TokenGeyser: Err unstaking. Staking shares exist, but no staking tokens do");

    return rewardAmount;
  }


  /**
   * @param addr  user to look up staking information for.
   * @return The number of staking tokens deposited for addr.
   */
  function totalStakedFor(address addr) public view returns (uint)
  {
    return totalStakingShares > 0 ? totalStaked().mul(_userTotals[addr].stakingShares).div(totalStakingShares) : 0;
  }

  /**
   * @return The total number of deposit tokens staked globally, by all users.
   */
  function totalStaked() public view returns (uint)
  {
    return _stakingPool.balance();
  }

  /**
   * @return Total number of locked distribution tokens.
   */
  function totalLocked() public view returns (uint)
  {
    return _lockedPool.balance();
  }

  /**
   * @return Total number of unlocked distribution tokens.
   */
  function totalUnlocked() public view returns (uint)
  {
    return _unlockedPool.balance();
  }

  /**
   * @return Number of unlock schedules.
   */
  function unlockScheduleCount() public view returns (uint)
  {
    return unlockSchedules.length;
  }


  // getUserTotals, getTotalStakingShareSeconds, getLastAccountingTimestamp functions added for Yield

  /**
   * @param addr  user to look up staking information for

   * @return The UserStakes for this address
   */
  function getUserStakes(address addr) public view returns (Stake[] memory)
  {
    Stake[] memory userStakes = _userStakes[addr];

    return userStakes;
  }

  /**
   * @param addr user to look up staking information for

   * @return The UserTotals for this address.
   */
  function getUserTotals(address addr) public view returns (UserTotals memory)
  {
    UserTotals memory userTotals = _userTotals[addr];

    return userTotals;
  }

  /**
   * @return The total staking share seconds
   */
  function getTotalStakingShareSeconds() public view returns (uint256)
  {
    return _totalStakingShareSeconds;
  }

  /**
   * @return The last global accounting timestamp.
   */
  function getLastAccountingTimestamp() public view returns (uint256)
  {
    return _lastAccountingTimestampSec;
  }

  /**
   * @return The token users receive as they unstake.
   */
  function getDistributionToken() public view returns (IERC20)
  {
    assert(_unlockedPool.token() == _lockedPool.token());

    return _unlockedPool.token();
  }

  /**
   * @return The token users deposit as stake.
   */
  function getStakingToken() public view returns (IERC20)
  {
    return _stakingPool.token();
  }

  /**
   * @dev Note that this application has a staking token as well as a distribution token, which may be different. This function is required by EIP-900.

   * @return The deposit token used for staking.
   */
  function token() external view returns (address)
  {
    return address(getStakingToken());
  }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity 0.5.17;


contract Ownable
{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  modifier onlyOwner()
  {
    require(isOwner(), "!owner");
    _;
  }

  constructor () internal
  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address)
  {
    return _owner;
  }

  function isOwner() public view returns (bool)
  {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));

    _owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner
  {
    require(_newOwner != address(0), "0 addy");

    emit OwnershipTransferred(_owner, _newOwner);

    _owner = _newOwner;
  }
}

pragma solidity 0.5.17;


/**
 * @title Staking interface, as defined by EIP-900.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract IStaking
{
  event Staked(address indexed user, uint amount, uint total, bytes data);
  event Unstaked(address indexed user, uint amount, uint total, bytes data);

  function stake(uint amount, bytes calldata data) external;

  function stakeFor(address user, uint amount, bytes calldata data) external;

  function unstake(uint amount, bytes calldata data) external;

  function totalStakedFor(address addr) public view returns (uint);

  function totalStaked() public view returns (uint);

  function token() external view returns (address);

  /**
   * @return false. This application does not support staking history.
   */
  function supportsHistory() external pure returns (bool)
  {
    return false;
  }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./roles/Ownable.sol";


/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable
{
  IERC20 public token;


  constructor(IERC20 _token) public
  {
    token = _token;
  }

  function balance() public view returns (uint)
  {
    return token.balanceOf(address(this));
  }

  function transfer(address _to, uint _value) external onlyOwner returns (bool)
  {
    return token.transfer(_to, _value);
  }
}