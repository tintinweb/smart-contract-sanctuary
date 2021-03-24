/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: contracts/TokenPool.sol

pragma solidity 0.5.0;


contract TokenPool {
    IERC20 public token;

    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(IERC20 _token) public {
        token = _token;
        _owner = msg.sender;
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

// File: contracts/TokenGeyser.sol

pragma solidity 0.5.0;




contract TokenGeyser {
    using SafeMath for uint256;

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensLocked(uint256 amount, uint256 durationSec, uint256 total);
    event TokensAdded(uint256 amount, uint256 total);
    event TokensUnlocked(uint256 amount, uint256 total);

    TokenPool private _stakingPool;
    TokenPool private _unlockedPool;
    TokenPool private _lockedPool;

    //
    // Time-bonus params
    //
    uint256 public startBonus = 0;
    uint256 public bonusPeriodSec = 0;

    //
    // Global accounting state
    //
    uint256 public totalLockedTokens = 0;
    uint256 public totalStakingTokens = 0;
    uint256 private _totalStakingTokensSeconds = 0;
    uint256 private _lastAccountingTimestampSec = now;

    //
    // User accounting state
    //
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        uint256 stakingTokens;
        uint256 timestampSec;
    }

    // Caches aggregated values from the User->Stake[] map to save computation.
    // If lastAccountingTimestampSec is 0, there's no entry for that user.
    struct UserTotals {
        uint256 stakingTokens;
        uint256 stakingTokensSeconds;
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
        uint256 initialLockedTokens;
        uint256 unlockedTokens;
        uint256 lastUnlockTimestampSec;
        uint256 endAtSec;
        uint256 durationSec;
    }

    UnlockSchedule[] public unlockSchedules;

    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(IERC20 stakingToken, IERC20 distributionToken, uint256 _startBonus, uint256 _bonusPeriod) public {
        _stakingPool = new TokenPool(stakingToken);
        _unlockedPool = new TokenPool(distributionToken);
        _lockedPool = new TokenPool(distributionToken);
        startBonus = _startBonus; //33;
        bonusPeriodSec = _bonusPeriod; //5184000; // 60 days
        _owner = msg.sender;
    }

    function getStakingToken() public view returns (IERC20) {
        return _stakingPool.token();
    }

    function getDistributionToken() public view returns (IERC20) {
        return _unlockedPool.token();
    }

    function stake(uint256 amount, bytes calldata data) external {
        _stakeFor(msg.sender, msg.sender, amount);
    }

    function _stakeFor(address staker, address beneficiary, uint256 amount) private {
        require(amount > 0, 'TokenGeyser: stake amount is zero');
        require(beneficiary != address(0), 'TokenGeyser: beneficiary is zero address');
        require(totalStakingTokens == 0 || totalStaked() > 0,
                'TokenGeyser: Invalid state. Staking shares exist, but no staking tokens do');

        require(amount > 0, 'TokenGeyser: Stake amount is too small');

        updateAccounting();

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];
        totals.stakingTokens = totals.stakingTokens.add(amount);
        totals.lastAccountingTimestampSec = now;

        Stake memory newStake = Stake(amount, now);
        _userStakes[beneficiary].push(newStake);

        // 2. Global Accounting
        totalStakingTokens = totalStakingTokens.add(amount);

        // interactions
        require(_stakingPool.token().transferFrom(staker, address(_stakingPool), amount),
            'TokenGeyser: transfer into staking pool failed');

        emit Staked(beneficiary, amount, totalStakedFor(beneficiary), "");
    }

    function unstake(uint256 amount, bytes calldata data) external {
        _unstake(amount);
    }

    function unstakeQuery(uint256 amount) public returns (uint256) {
        return _unstake(amount);
    }

    function _unstake(uint256 amount) private returns (uint256) {
        updateAccounting();
        // checks
        require(amount > 0, 'TokenGeyser: unstake amount is zero');
        require(totalStakedFor(msg.sender) >= amount,
            'TokenGeyser: unstake amount is greater than total user stakes');

        // 1. User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        Stake[] storage accountStakes = _userStakes[msg.sender];

        // Redeem from most recent stake and go backwards in time.
        uint256 stakingTokensSecondsToBurn = 0;
        uint256 sharesLeftToBurn = amount;
        uint256 rewardAmount = 0;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = accountStakes[accountStakes.length - 1];
            uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
            uint256 newstakingTokensSecondsToBurn = 0;
            if (lastStake.stakingTokens <= sharesLeftToBurn) {
                // fully redeem a past stake
                newstakingTokensSecondsToBurn = lastStake.stakingTokens.mul(stakeTimeSec);
                rewardAmount = computeNewReward(rewardAmount, newstakingTokensSecondsToBurn, stakeTimeSec);
                stakingTokensSecondsToBurn = stakingTokensSecondsToBurn.add(newstakingTokensSecondsToBurn);
                sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.stakingTokens);
                accountStakes.length--;
            } else {
                // partially redeem a past stake
                newstakingTokensSecondsToBurn = sharesLeftToBurn.mul(stakeTimeSec);
                rewardAmount = computeNewReward(rewardAmount, newstakingTokensSecondsToBurn, stakeTimeSec);
                stakingTokensSecondsToBurn = stakingTokensSecondsToBurn.add(newstakingTokensSecondsToBurn);
                lastStake.stakingTokens = lastStake.stakingTokens.sub(sharesLeftToBurn);
                sharesLeftToBurn = 0;
            }
        }
        totals.stakingTokensSeconds = totals.stakingTokensSeconds.sub(stakingTokensSecondsToBurn);
        totals.stakingTokens = totals.stakingTokens.sub(amount);

        // 2. Global Accounting
        _totalStakingTokensSeconds = _totalStakingTokensSeconds.sub(stakingTokensSecondsToBurn);
        totalStakingTokens = totalStakingTokens.sub(amount);

        // unlock 99% only, leave 1% locked as a liquidity tax
        uint256 amountMinusTax = amount.mul(99).div(100);
        uint256 amountTax = amount.sub(amountMinusTax);
        // interactions
        require(_stakingPool.transfer(msg.sender, amountMinusTax),
            'TokenGeyser: transfer out of staking pool failed');
        require(_stakingPool.transfer(address(this), amountTax),
            'TokenGeyser: transfer out of staking pool failed');
        require(_unlockedPool.transfer(msg.sender, rewardAmount),
            'TokenGeyser: transfer out of unlocked pool failed');

        emit Unstaked(msg.sender, amountMinusTax, totalStakedFor(msg.sender), "");
        emit TokensClaimed(msg.sender, rewardAmount);

        require(totalStakingTokens == 0 || totalStaked() > 0,
                "TokenGeyser: Error unstaking. Staking shares exist, but no staking tokens do");
        return rewardAmount;
    }

    function computeNewReward(uint256 currentRewardTokens, uint256 stakingTokensSeconds, uint256 stakeTimeSec) private view returns (uint256) {

        uint256 newRewardTokens = totalUnlocked().mul(stakingTokensSeconds).div(_totalStakingTokensSeconds);

        if (stakeTimeSec >= bonusPeriodSec) {
            return currentRewardTokens.add(newRewardTokens);
        }

        uint256 oneHundredPct = 100;
        uint256 bonusedReward =
            startBonus
            .add(oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(bonusPeriodSec))
            .mul(newRewardTokens)
            .div(oneHundredPct);
        return currentRewardTokens.add(bonusedReward);
    }

    function totalStakedFor(address addr) public view returns (uint256) {
        return totalStakingTokens > 0 ?
            totalStaked().mul(_userTotals[addr].stakingTokens).div(totalStakingTokens) : 0;
    }

    function totalStaked() public view returns (uint256) {
        return _stakingPool.balance();
    }

    function token() external view returns (address) {
        return address(getStakingToken());
    }

    function updateAccounting() public returns (uint256, uint256, uint256, uint256, uint256, uint256) {

        unlockTokens();

        // Global accounting
        uint256 newstakingTokensSeconds =
            now
            .sub(_lastAccountingTimestampSec)
            .mul(totalStakingTokens);
        _totalStakingTokensSeconds = _totalStakingTokensSeconds.add(newstakingTokensSeconds);
        _lastAccountingTimestampSec = now;

        // User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        uint256 newUserstakingTokensSeconds =
            now
            .sub(totals.lastAccountingTimestampSec)
            .mul(totals.stakingTokens);
        totals.stakingTokensSeconds =
            totals.stakingTokensSeconds
            .add(newUserstakingTokensSeconds);
        totals.lastAccountingTimestampSec = now;

        uint256 totalUserRewards = (_totalStakingTokensSeconds > 0)
            ? totalUnlocked().mul(totals.stakingTokensSeconds).div(_totalStakingTokensSeconds)
            : 0;

        return (
            totalLocked(),
            totalUnlocked(),
            totals.stakingTokensSeconds,
            _totalStakingTokensSeconds,
            totalUserRewards,
            now
        );
    }

    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }

    function totalUnlocked() public view returns (uint256) {
        return _unlockedPool.balance();
    }

    function unlockScheduleCount() public view returns (uint256) {
        return unlockSchedules.length;
    }

    function lockTokens(uint256 amount, uint256 durationSec) external onlyOwner {
        // Update lockedTokens amount before using it in computations after.
        updateAccounting();

        uint256 lockedTokens = totalLocked();

        UnlockSchedule memory schedule;
        schedule.initialLockedTokens = amount;
        schedule.lastUnlockTimestampSec = now;
        schedule.endAtSec = now.add(durationSec);
        schedule.durationSec = durationSec;
        unlockSchedules.push(schedule);

        totalLockedTokens = lockedTokens.add(amount);

        require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount),
            'TokenGeyser: transfer into locked pool failed');
        emit TokensLocked(amount, durationSec, totalLocked());
    }

    function addTokens(uint256 amount) external {
        UnlockSchedule storage schedule = unlockSchedules[unlockSchedules.length - 1];

        // if we don't have an active schedule, create one
        if(schedule.endAtSec < now){
          uint256 lockedTokens = totalLocked();

          UnlockSchedule memory schedule;
          schedule.initialLockedTokens = amount;
          schedule.lastUnlockTimestampSec = now;
          schedule.endAtSec = now.add(60 * 60 * 24 * 135);
          schedule.durationSec = 60 * 60 * 24 * 135;
          unlockSchedules.push(schedule);

          totalLockedTokens = lockedTokens.add(amount);

          require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount),
              'TokenGeyser: transfer into locked pool failed');
          emit TokensLocked(amount, 60 * 60 * 24 * 135, totalLocked());
        } else {
          // normalize the amount weight to offset lost time
          uint256 mintedLockedShares = amount.mul(schedule.durationSec.div(schedule.endAtSec.sub(now)));
          schedule.initialLockedTokens = schedule.initialLockedTokens.add(mintedLockedShares);

          uint256 balanceBefore = _lockedPool.token().balanceOf(address(_lockedPool));
          require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount),
              'TokenGeyser: transfer into locked pool failed');
          uint256 balanceAfter = _lockedPool.token().balanceOf(address(_lockedPool));

          totalLockedTokens = totalLockedTokens.add(balanceAfter.sub(balanceBefore));
          emit TokensAdded(balanceAfter.sub(balanceBefore), totalLocked());
        }

    }

    function unlockTokens() public returns (uint256) {
        uint256 unlockedTokens = 0;

        if (totalLockedTokens == 0) {
            unlockedTokens = totalLocked();
        } else {
            for (uint256 s = 0; s < unlockSchedules.length; s++) {
                unlockedTokens = unlockedTokens.add(unlockScheduleShares(s));
            }
            totalLockedTokens = totalLockedTokens.sub(unlockedTokens);
        }

        if (unlockedTokens > 0) {
            require(_lockedPool.transfer(address(_unlockedPool), unlockedTokens),
                'TokenGeyser: transfer out of locked pool failed');
            emit TokensUnlocked(unlockedTokens, totalLocked());
        }

        return unlockedTokens;
    }

    function unlockScheduleShares(uint256 s) private returns (uint256) {
        UnlockSchedule storage schedule = unlockSchedules[s];

        if(schedule.unlockedTokens >= schedule.initialLockedTokens) {
            return 0;
        }

        uint256 sharesToUnlock = 0;
        // Special case to handle any leftover dust from integer division
        if (now >= schedule.endAtSec) {
            sharesToUnlock = (schedule.initialLockedTokens.sub(schedule.unlockedTokens));
            schedule.lastUnlockTimestampSec = schedule.endAtSec;
        } else {
            sharesToUnlock = now.sub(schedule.lastUnlockTimestampSec)
                .mul(schedule.initialLockedTokens)
                .div(schedule.durationSec);
            schedule.lastUnlockTimestampSec = now;
        }

        schedule.unlockedTokens = schedule.unlockedTokens.add(sharesToUnlock);
        return sharesToUnlock;
    }

    function rescueFundsFromStakingPool(address tokenToRescue, address to, uint256 amount) public onlyOwner returns (bool) {
        return _stakingPool.rescueFunds(tokenToRescue, to, amount);
    }
}