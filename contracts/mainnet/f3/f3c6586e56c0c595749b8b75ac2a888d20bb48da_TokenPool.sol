// File: contracts/contracts/math/SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens in existence.
     */

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/TokenPool.sol

pragma solidity 0.5.16;



/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value) external onlyOwner returns (bool) {
        return token.transfer(to, value);
    }

    function rescueFunds(address tokenToRescue, address to, uint256 amount) external onlyOwner returns (bool) {
        require(address(token) != tokenToRescue, 'TokenPool: Cannot claim token held by the contract');

        return IERC20(tokenToRescue).transfer(to, amount);
    }
}

// File: contracts/LiquidityMining.sol

pragma solidity 0.5.16;

pragma experimental ABIEncoderV2;






/**
 * @title Token Geyser
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by
 *      Compound and Uniswap.
 *
 *      Distribution tokens are added to a locked pool in the contract and become unlocked over time
 *      according to a once-configurable unlock schedule. Once unlocked, they are available to be
 *      claimed by users.
 *
 *      A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share
 *      is a function of the number of tokens deposited as well as the length of time deposited.
 *      Specifically, a user's share of the currently-unlocked pool equals their "deposit-seconds"
 *      divided by the global "deposit-seconds". This aligns the new token distribution with long
 *      term supporters of the project, addressing one of the major drawbacks of simple airdrops.
 *
 *      More background and motivation available at:
 *      https://github.com/ampleforth/RFCs/blob/master/RFCs/rfc-1.md
 */
contract LiquidityMining is Ownable {
  using SafeMath for uint256;

  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(
    address indexed user,
    uint256 amount,
    uint256 total,
    bytes data
  );
  event TokensClaimed(address indexed user, uint256 amount);
  event TokensLocked(uint256 amount, uint256 durationSec, uint256 total);
  // amount: Unlocked tokens, total: Total locked tokens
  event TokensUnlocked(uint256 amount, uint256 total);

  TokenPool private _stakingPool;
  TokenPool private _unlockedPool;
  TokenPool private _lockedPool;

  //
  // Time-bonus params
  //
  uint256 public constant BONUS_DECIMALS = 2;
  uint256 public startBonus = 0;
  uint256 public bonusPeriodSec = 0;

  //
  // Global accounting state
  //
  uint256 public totalLockedShares = 0;
  uint256 public totalStakingShares = 0;
  uint256 private _totalStakingShareSeconds = 0;
  uint256 private _lastAccountingTimestampSec = now;
  uint256 private _maxUnlockSchedules = 0;
  uint256 private _initialSharesPerToken = 0;

  //
  // User accounting state
  //
  // Represents a single stake for a user. A user may have multiple.
  struct Stake {
    uint256 stakingShares;
    uint256 timestampSec;
  }

  // Caches aggregated values from the User->Stake[] map to save computation.
  // If lastAccountingTimestampSec is 0, there's no entry for that user.
  struct UserTotals {
    uint256 stakingShares;
    uint256 stakingShareSeconds;
    uint256 lastAccountingTimestampSec;
  }

  // Aggregated staking values per user
  mapping(address => UserTotals) private _userTotals;

  // The collection of stakes for each user. Ordered by timestamp, earliest to latest.
  mapping(address => Stake[]) private _userStakes;

  //
  // Locked/Unlocked Accounting state
  //
  struct UnlockSchedule {
    uint256 initialLockedShares;
    uint256 unlockedShares;
    uint256 lastUnlockTimestampSec;
    uint256 endAtSec;
    uint256 durationSec;
  }

  UnlockSchedule[] public unlockSchedules;

  /**
   * @param stakingToken The token users deposit as stake.
   * @param distributionToken The token users receive as they unstake.
   * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
   * @param startBonus_ Starting time bonus, BONUS_DECIMALS fixed point.
   *                    e.g. 25% means user gets 25% of max distribution tokens.
   * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
   * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
   */
  constructor(
    address stakingToken,
    address distributionToken,
    uint256 maxUnlockSchedules,
    uint256 startBonus_,
    uint256 bonusPeriodSec_,
    uint256 initialSharesPerToken
  ) public {
    // The start bonus must be some fraction of the max. (i.e. <= 100%)
    require(
      startBonus_ <= 10**BONUS_DECIMALS,
      "TokenGeyser: start bonus too high"
    );
    // If no period is desired, instead set startBonus = 100%
    // and bonusPeriod to a small value like 1sec.
    require(bonusPeriodSec_ != 0, "TokenGeyser: bonus period is zero");
    require(
      initialSharesPerToken > 0,
      "TokenGeyser: initialSharesPerToken is zero"
    );

    _stakingPool = new TokenPool(IERC20(stakingToken));
    _unlockedPool = new TokenPool(IERC20(distributionToken));
    _lockedPool = new TokenPool(IERC20(distributionToken));
    startBonus = startBonus_;
    bonusPeriodSec = bonusPeriodSec_;
    _maxUnlockSchedules = maxUnlockSchedules;
    _initialSharesPerToken = initialSharesPerToken;
  }

  /**
   * @return The token users deposit as stake.
   */
  function getStakingToken() public view returns (IERC20) {
    return _stakingPool.token();
  }

  /**
   * @return The token users receive as they unstake.
   */
  function getDistributionToken() public view returns (IERC20) {
    assert(_unlockedPool.token() == _lockedPool.token());
    return _unlockedPool.token();
  }


  function stake(uint256 amount) external {
    _stakeFor(msg.sender, msg.sender, amount);
  }


  function stakeFor(
    address user,
    uint256 amount
   
  ) external onlyOwner {
    _stakeFor(msg.sender, user, amount);
  }

  /**
   * @dev Private implementation of staking methods.
   * @param staker User address who deposits tokens to stake.
   * @param beneficiary User address who gains credit for this stake operation.
   * @param amount Number of deposit tokens to stake.
   */
  function _stakeFor(
    address staker,
    address beneficiary,
    uint256 amount
  ) private {
    require(amount > 0, "TokenGeyser: stake amount is zero");
    require(
      beneficiary != address(0),
      "TokenGeyser: beneficiary is zero address"
    );
    require(
      totalStakingShares == 0 || totalStaked() > 0,
      "TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do"
    );

    uint256 mintedStakingShares = (totalStakingShares > 0)
      ? totalStakingShares.mul(amount).div(totalStaked())
      : amount.mul(_initialSharesPerToken);
    require(mintedStakingShares > 0, "TokenGeyser: Stake amount is too small");

    updateAccounting();

    // 1. User Accounting
    _userTotals[beneficiary].stakingShares = _userTotals[beneficiary]
      .stakingShares
      .add(mintedStakingShares);
    _userTotals[beneficiary].lastAccountingTimestampSec = now;

    Stake memory newStake = Stake(mintedStakingShares, now);
    _userStakes[beneficiary].push(newStake);

    // 2. Global Accounting
    totalStakingShares = totalStakingShares.add(mintedStakingShares);
    // Already set in updateAccounting()
    // _lastAccountingTimestampSec = now;

    // interactions
    require(
      _stakingPool.token().transferFrom(staker, address(_stakingPool), amount),
      "TokenGeyser: transfer into staking pool failed"
    );

    emit Staked(beneficiary, amount, totalStakedFor(beneficiary), "");
  }


  function unstake(uint256 amount) external {
    _unstake(amount);
  }

  /**
   * @param amount Number of deposit tokens to unstake / withdraw.
   * @return The total number of distribution tokens that would be rewarded.
   */
  function unstakeQuery(uint256 amount) public returns (uint256) {
    return _unstake(amount);
  }

  /**
   * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
   * alotted number of distribution tokens.
   * @param amount Number of deposit tokens to unstake / withdraw.
   * @return The total number of distribution tokens rewarded.
   */
  function _unstake(uint256 amount) private returns (uint256) {
    updateAccounting();

    // checks
    require(amount > 0, "TokenGeyser: unstake amount is zero");
    require(
      totalStakedFor(msg.sender) >= amount,
      "TokenGeyser: unstake amount is greater than total user stakes"
    );
    uint256 stakingSharesToBurn = totalStakingShares.mul(amount).div(
      totalStaked()
    );
    require(
      stakingSharesToBurn > 0,
      "TokenGeyser: Unable to unstake amount this small"
    );

    // Redeem from most recent stake and go backwards in time.
    uint256 stakingShareSecondsToBurn = 0;
    uint256 sharesLeftToBurn = stakingSharesToBurn;
    uint256 rewardAmount = 0;
    while (sharesLeftToBurn > 0) {
      Stake storage lastStake = _userStakes[msg.sender][_userStakes[msg.sender]
        .length - 1];
      uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
      uint256 newStakingShareSecondsToBurn = 0;
      if (lastStake.stakingShares <= sharesLeftToBurn) {
        // fully redeem a past stake
        newStakingShareSecondsToBurn = lastStake.stakingShares.mul(
          stakeTimeSec
        );
        rewardAmount = computeNewReward(
          rewardAmount,
          newStakingShareSecondsToBurn,
          stakeTimeSec
        );
        stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
          newStakingShareSecondsToBurn
        );
        sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.stakingShares);
        _userStakes[msg.sender].length--;
      } else {
        // partially redeem a past stake
        newStakingShareSecondsToBurn = sharesLeftToBurn.mul(stakeTimeSec);
        rewardAmount = computeNewReward(
          rewardAmount,
          newStakingShareSecondsToBurn,
          stakeTimeSec
        );
        stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(
          newStakingShareSecondsToBurn
        );
        lastStake.stakingShares = lastStake.stakingShares.sub(sharesLeftToBurn);
        sharesLeftToBurn = 0;
      }
    }
    _userTotals[msg.sender].stakingShareSeconds = _userTotals[msg.sender]
      .stakingShareSeconds
      .sub(stakingShareSecondsToBurn);
    _userTotals[msg.sender].stakingShares = _userTotals[msg.sender]
      .stakingShares
      .sub(stakingSharesToBurn);
    // Already set in updateAccounting
    // totals.lastAccountingTimestampSec = now;

    // 2. Global Accounting
    _totalStakingShareSeconds = _totalStakingShareSeconds.sub(
      stakingShareSecondsToBurn
    );
    totalStakingShares = totalStakingShares.sub(stakingSharesToBurn);
    // Already set in updateAccounting
    // _lastAccountingTimestampSec = now;

    // interactions
    require(
      _stakingPool.transfer(msg.sender, amount),
      "TokenGeyser: transfer out of staking pool failed"
    );
    require(
      _unlockedPool.transfer(msg.sender, rewardAmount),
      "TokenGeyser: transfer out of unlocked pool failed"
    );

    emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), "");
    emit TokensClaimed(msg.sender, rewardAmount);

    require(
      totalStakingShares == 0 || totalStaked() > 0,
      "TokenGeyser: Error unstaking. Staking shares exist, but no staking tokens do"
    );
    return rewardAmount;
  }

  /**
   * @dev Applies an additional time-bonus to a distribution amount. This is necessary to
   *      encourage long-term deposits instead of constant unstake/restakes.
   *      The bonus-multiplier is the result of a linear function that starts at startBonus and
   *      ends at 100% over bonusPeriodSec, then stays at 100% thereafter.
   * @param currentRewardTokens The current number of distribution tokens already alotted for this
   *                            unstake op. Any bonuses are already applied.
   * @param stakingShareSeconds The stakingShare-seconds that are being burned for new
   *                            distribution tokens.
   * @param stakeTimeSec Length of time for which the tokens were staked. Needed to calculate
   *                     the time-bonus.
   * @return Updated amount of distribution tokens to award, with any bonus included on the
   *         newly added tokens.
   */
  function computeNewReward(
    uint256 currentRewardTokens,
    uint256 stakingShareSeconds,
    uint256 stakeTimeSec
  ) private view returns (uint256) {
    uint256 newRewardTokens = totalUnlocked().mul(stakingShareSeconds).div(
      _totalStakingShareSeconds
    );

    if (stakeTimeSec >= bonusPeriodSec) {
      return currentRewardTokens.add(newRewardTokens);
    }

    uint256 oneHundredPct = 10**BONUS_DECIMALS;
    uint256 bonusedReward = startBonus
      .add(oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(bonusPeriodSec))
      .mul(newRewardTokens)
      .div(oneHundredPct);
    return currentRewardTokens.add(bonusedReward);
  }

  /**
   * @param addr The user to look up staking information for.
   * @return The number of staking tokens deposited for addr.
   */
  function totalStakedFor(address addr) public view returns (uint256) {
    return
      totalStakingShares > 0
        ? totalStaked().mul(_userTotals[addr].stakingShares).div(
          totalStakingShares
        )
        : 0;
  }

  function totalShares() public view returns (uint256) {
    return totalStakingShares;
  }

  function userStakingShares(address addr) public view returns (uint256) {
    return _userTotals[addr].stakingShares;
  }

  /**
   * @return The total number of deposit tokens staked globally, by all users.
   */
  function totalStaked() public view returns (uint256) {
    return _stakingPool.balance();
  }

  /**
   * @dev Note that this application has a staking token as well as a distribution token, which
   * may be different. This function is required by EIP-900.
   * @return The deposit token used for staking.
   */
  function token() external view returns (address) {
    return address(getStakingToken());
  }

  /**
   * @dev A globally callable function to update the accounting state of the system.
   *      Global state and state for the caller are updated.
   * @return [0] balance of the locked pool
   * @return [1] balance of the unlocked pool
   * @return [2] caller's staking share seconds
   * @return [3] global staking share seconds
   * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
   * @return [5] block timestamp
   */
  function updateAccounting()
    public
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    unlockTokens();

    // Global accounting
    uint256 newStakingShareSeconds = now.sub(_lastAccountingTimestampSec).mul(
      totalStakingShares
    );
    _totalStakingShareSeconds = _totalStakingShareSeconds.add(
      newStakingShareSeconds
    );
    _lastAccountingTimestampSec = now;

    // User Accounting
    uint256 newUserStakingShareSeconds = now
      .sub(_userTotals[msg.sender].lastAccountingTimestampSec)
      .mul(_userTotals[msg.sender].stakingShares);
    _userTotals[msg.sender].stakingShareSeconds = _userTotals[msg.sender]
      .stakingShareSeconds
      .add(newUserStakingShareSeconds);
    _userTotals[msg.sender].lastAccountingTimestampSec = now;

    uint256 totalUserRewards = (_totalStakingShareSeconds > 0)
      ? totalUnlocked().mul(_userTotals[msg.sender].stakingShareSeconds).div(
        _totalStakingShareSeconds
      )
      : 0;

    return (
      totalLocked(),
      totalUnlocked(),
      _userTotals[msg.sender].stakingShareSeconds,
      _totalStakingShareSeconds,
      totalUserRewards,
      now
    );
  }

  /**
   * @return Total number of locked distribution tokens.
   */
  function totalLocked() public view returns (uint256) {
    return _lockedPool.balance();
  }

  /**
   * @return Total number of unlocked distribution tokens.
   */
  function totalUnlocked() public view returns (uint256) {
    return _unlockedPool.balance();
  }

  /**
   * @return Number of unlock schedules.
   */
  function unlockScheduleCount() public view returns (uint256) {
    return unlockSchedules.length;
  }

  /**
   * @dev This funcion allows the contract owner to add more locked distribution tokens, along
   *      with the associated "unlock schedule". These locked tokens immediately begin unlocking
   *      linearly over the duraction of durationSec timeframe.
   * @param amount Number of distribution tokens to lock. These are transferred from the caller.
   * @param durationSec Length of time to linear unlock the tokens.
   */
  function lockTokens(uint256 amount, uint256 durationSec) external onlyOwner {
    require(
      unlockSchedules.length < _maxUnlockSchedules,
      "TokenGeyser: reached maximum unlock schedules"
    );

    // Update lockedTokens amount before using it in computations after.
    updateAccounting();

    uint256 lockedTokens = totalLocked();
    uint256 mintedLockedShares = (lockedTokens > 0)
      ? totalLockedShares.mul(amount).div(lockedTokens)
      : amount.mul(_initialSharesPerToken);

    UnlockSchedule memory schedule;
    schedule.initialLockedShares = mintedLockedShares;
    schedule.lastUnlockTimestampSec = now;
    schedule.endAtSec = now.add(durationSec);
    schedule.durationSec = durationSec;
    unlockSchedules.push(schedule);

    totalLockedShares = totalLockedShares.add(mintedLockedShares);

    require(
      _lockedPool.token().transferFrom(
        msg.sender,
        address(_lockedPool),
        amount
      ),
      "TokenGeyser: transfer into locked pool failed"
    );
    emit TokensLocked(amount, durationSec, totalLocked());
  }

  /**
   * @dev Moves distribution tokens from the locked pool to the unlocked pool, according to the
   *      previously defined unlock schedules. Publicly callable.
   * @return Number of newly unlocked distribution tokens.
   */
  function unlockTokens() public returns (uint256) {
    uint256 unlockedTokens = 0;
    uint256 lockedTokens = totalLocked();

    if (totalLockedShares == 0) {
      unlockedTokens = lockedTokens;
    } else {
      uint256 unlockedShares = 0;
      for (uint256 s = 0; s < unlockSchedules.length; s++) {
        unlockedShares = unlockedShares.add(unlockScheduleShares(s));
      }
      unlockedTokens = unlockedShares.mul(lockedTokens).div(totalLockedShares);
      totalLockedShares = totalLockedShares.sub(unlockedShares);
    }

    if (unlockedTokens > 0) {
      require(
        _lockedPool.transfer(address(_unlockedPool), unlockedTokens),
        "TokenGeyser: transfer out of locked pool failed"
      );
      emit TokensUnlocked(unlockedTokens, totalLocked());
    }

    return unlockedTokens;
  }

  /**
   * @dev Returns the number of unlockable shares from a given schedule. The returned value
   *      depends on the time since the last unlock. This function updates schedule accounting,
   *      but does not actually transfer any tokens.
   * @param s Index of the unlock schedule.
   * @return The number of unlocked shares.
   */
  function unlockScheduleShares(uint256 s) private returns (uint256) {
    UnlockSchedule storage schedule = unlockSchedules[s];

    if (schedule.unlockedShares >= schedule.initialLockedShares) {
      return 0;
    }

    uint256 sharesToUnlock = 0;
    // Special case to handle any leftover dust from integer division
    if (now >= schedule.endAtSec) {
      sharesToUnlock = (
        schedule.initialLockedShares.sub(schedule.unlockedShares)
      );
      schedule.lastUnlockTimestampSec = schedule.endAtSec;
    } else {
      sharesToUnlock = now
        .sub(schedule.lastUnlockTimestampSec)
        .mul(schedule.initialLockedShares)
        .div(schedule.durationSec);
      schedule.lastUnlockTimestampSec = now;
    }

    schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);
    return sharesToUnlock;
  }

  /**
   * @dev Lets the owner rescue funds air-dropped to the staking pool.
   * @param tokenToRescue Address of the token to be rescued.
   * @param to Address to which the rescued funds are to be sent.
   * @param amount Amount of tokens to be rescued.
   * @return Transfer success.
   */
  function rescueFundsFromStakingPool(
    address tokenToRescue,
    address to,
    uint256 amount
  ) public onlyOwner returns (bool) {
    return _stakingPool.rescueFunds(tokenToRescue, to, amount);
  }
}