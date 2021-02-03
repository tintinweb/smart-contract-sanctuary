/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.5.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/IStaking.sol

contract IStaking {
    event Staked(address indexed user, uint256 amount, uint256 total, uint256 time, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, uint256 penaltyAmount, bytes data);

    function stake(uint256 amount, bytes calldata data) external;
    function stakeFor(address user, uint256 amount, bytes calldata data) external;
    function unstake(uint256 amount, bytes calldata data) external;
    function unstakeAtIndex(uint256 index, bytes calldata data) external;
    function totalStakedFor(address addr) public view returns (uint256);
    function totalStaked() public view returns (uint256);
    function token() external view returns (address);

    function supportsHistory() external pure returns (bool) {
        return false;
    }
}

// File: contracts/TokenPool.sol

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
}

// File: contracts/TokenSpring.sol

contract TokenSpring is IStaking, Ownable {
    using SafeMath for uint256;

    event Staked(address indexed user, uint256 amount, uint256 total, uint256 time, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, uint256 penaltyAmount, bytes data);
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensLocked(uint256 amount, uint256 durationSec, uint256 total);
    // amount: Unlocked tokens, total: Total locked tokens
    event TokensUnlocked(uint256 amount, uint256 total);

    event LogPenaltyAddressUpdated(address penaltyAddress_);

    TokenPool private _stakingPool;
    TokenPool private _unlockedPool;
    TokenPool private _lockedPool;

    //
    // Time-bonus params
    //
    uint256 public constant BONUS_DECIMALS = 2;
    uint256 public startBonus = 0;
    uint256 public bonusPeriodSec = 0;
    uint256 public lockTimeSeconds = 30 days;

    //
    // Global accounting state
    //
    uint256 public totalLockedShares = 0;
    uint256 public totalStakingShares = 0;
    uint256 private _totalStakingShareSeconds = 0;
    uint256 private _maxUnlockSchedules = 0;
    uint256 private _initialSharesPerToken = 0;

    //
    // User accounting state
    //
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        uint256 stakingShares;
        uint256 timestampSec;
        uint256 lockTimestampSec;
    }

    // Caches aggregated values from the User->Stake[] map to save computation.
    // If lastAccountingTimestampSec is 0, there's no entry for that user.
    struct UserTotals {
        uint256 stakingShares;
        uint256 stakingShareSeconds;
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

    // This address receives all penalty UNI-V2 LP tokens
    address public penaltyAddress;

    constructor(IERC20 stakingToken, IERC20 distributionToken, uint256 maxUnlockSchedules,
                uint256 startBonus_, uint256 bonusPeriodSec_, uint256 initialSharesPerToken) public {
        // The start bonus must be some fraction of the max. (i.e. <= 100%)
        require(startBonus_ <= 10**BONUS_DECIMALS, 'TokenSpring: start bonus too high');
        // If no period is desired, instead set startBonus = 100%
        // and bonusPeriod to a small value like 1sec.
        require(bonusPeriodSec_ != 0, 'TokenSpring: bonus period is zero');
        require(initialSharesPerToken > 0, 'TokenSpring: initialSharesPerToken is zero');

        _stakingPool = new TokenPool(stakingToken);
        _unlockedPool = new TokenPool(distributionToken);
        _lockedPool = new TokenPool(distributionToken);
        startBonus = startBonus_;
        bonusPeriodSec = bonusPeriodSec_;
        _maxUnlockSchedules = maxUnlockSchedules;
        _initialSharesPerToken = initialSharesPerToken;
        lockTimeSeconds = 30 days;
    }

    function setPenaltyAddress(address penaltyAddress_)
        external
        onlyOwner
    {
        penaltyAddress = penaltyAddress_;
        emit LogPenaltyAddressUpdated(penaltyAddress_);
    }

    function setLockTimeSeconds(uint256 lockTimeSeconds_)
        external
        onlyOwner
    {
        lockTimeSeconds = lockTimeSeconds_;
    }

    function getStakingToken() public view returns (IERC20) {
        return _stakingPool.token();
    }

    function getDistributionToken() public view returns (IERC20) {
        assert(_unlockedPool.token() == _lockedPool.token());
        return _unlockedPool.token();
    }

    function stake(uint256 amount, bytes calldata data) external {
        _stakeFor(msg.sender, msg.sender, amount);
    }

    function stakeFor(address user, uint256 amount, bytes calldata data) external {
        _stakeFor(msg.sender, user, amount);
    }

    function _stakeFor(address staker, address beneficiary, uint256 amount) private {
        require(amount > 0, 'TokenSpring: stake amount is zero');
        require(beneficiary != address(0), 'TokenSpring: beneficiary is zero address');
        require(totalStakingShares == 0 || totalStaked() > 0,
                'TokenSpring: Invalid state. Staking shares exist, but no staking tokens do');

        uint256 expiryTime = now.add(lockTimeSeconds);

        uint256 mintedStakingShares = (totalStakingShares > 0)
            ? totalStakingShares.mul(amount).div(totalStaked())
            : amount.mul(_initialSharesPerToken);
        require(mintedStakingShares > 0, 'TokenSpring: Stake amount is too small');

        // 1. User Accounting
        UserTotals storage totals = _userTotals[beneficiary];
        totals.stakingShares = totals.stakingShares.add(mintedStakingShares);

        Stake memory newStake = Stake(mintedStakingShares, now, expiryTime);
        _userStakes[beneficiary].push(newStake);

        // 2. Global Accounting
        totalStakingShares = totalStakingShares.add(mintedStakingShares);

        // interactions
        require(_stakingPool.token().transferFrom(staker, address(_stakingPool), amount),
            'TokenSpring: transfer into staking pool failed');

        // set global and user weights after CD is deposited
        updateAccounting(expiryTime, mintedStakingShares);

        emit Staked(beneficiary, amount, totalStakedFor(beneficiary), expiryTime, "");
    }

    function unstake(uint256 amount, bytes calldata data) external {
        _unstake(amount);
    }

    function unstakeAtIndex(uint256 index, bytes calldata data) external {
        _unstakeAtIndex(index);
    }

    function unstakeQuery(uint256 amount) public returns (uint256) {
        return _unstake(amount);
    }

    function unstakeAtIndexQuery(uint256 index) public returns (uint256) {
        return _unstakeAtIndex(index);
    }

    function _unstake(uint256 amount) private returns (uint256) {
        //updateAccounting();
        unlockTokens();

        // checks
        require(amount > 0, 'TokenSpring: unstake amount is zero');
        require(totalStakedFor(msg.sender) >= amount,
            'TokenSpring: unstake amount is greater than total user stakes');
        uint256 stakingSharesToBurn = totalStakingShares.mul(amount).div(totalStaked());
        require(stakingSharesToBurn > 0, 'TokenSpring: Unable to unstake amount this small');

        // 1. User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        Stake[] storage accountStakes = _userStakes[msg.sender];

        // Redeem from most recent stake and go backwards in time.
        uint256 stakingShareSecondsToBurn = 0;
        uint256 sharesLeftToBurn = stakingSharesToBurn;
        uint256 rewardAmount = 0;
        uint256 penaltyAmount = 0;
        uint256 totalAmount = 0;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = accountStakes[accountStakes.length - 1];
            // normalized amount from this CD
            uint256 newAmount = lastStake.stakingShares.mul(totalStaked()).div(totalStakingShares);
            totalAmount = totalAmount.add(newAmount);
            uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
            uint256 stakeTimeSecCalculated = lastStake.lockTimestampSec.sub(lastStake.timestampSec);
            uint256 newStakingShareSecondsToBurn = 0;

            // MUST fully redeem a past stake, CD gets destroyed
            newStakingShareSecondsToBurn = lastStake.stakingShares.mul(stakeTimeSecCalculated);
            stakingShareSecondsToBurn = stakingShareSecondsToBurn.add(newStakingShareSecondsToBurn);

            if(lastStake.stakingShares > sharesLeftToBurn){
              sharesLeftToBurn = 0;
            } else {
              sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.stakingShares);
            }

            // Need to be penalized
            if(lastStake.lockTimestampSec > now){
              // amountOfThisStake * (totalLock - actualLock)/totalLock) / 2
              penaltyAmount = penaltyAmount.add(stakeTimeSecCalculated.sub(stakeTimeSec).mul(newAmount).div(stakeTimeSecCalculated).div(2));
            } else {
              // this contract was fulfilled, make sure to pay out the reward based on the calculated time
              rewardAmount = computeNewReward(rewardAmount, newStakingShareSecondsToBurn, stakeTimeSecCalculated);
            }

            accountStakes.length--;
        }

        totals.stakingShareSeconds = totals.stakingShareSeconds.sub(stakingShareSecondsToBurn);
        totals.stakingShares = totals.stakingShares.sub(totalStakingShares.mul(totalAmount).div(totalStaked()));

        // 2. Global Accounting
        _totalStakingShareSeconds = _totalStakingShareSeconds.sub(stakingShareSecondsToBurn);
        totalStakingShares = totalStakingShares.sub(totalStakingShares.mul(totalAmount).div(totalStaked()));

        // what the staker should receive
        uint256 amountMinusPenalty = totalAmount.sub(penaltyAmount);
        require(totalAmount >= penaltyAmount, 'TokenSpring: penalty amount exceeds amount being redeemed');

        // just because we have penalties, does not mean we do not have rewards to pay out
        if(rewardAmount > 0) {
          // this unstake has no penalty, pay out the rewards
          require(_unlockedPool.transfer(msg.sender, rewardAmount),
              'TokenSpring: transfer out of unlocked pool failed');
        }

        // pay out the contract deposit amount minus any penalty
        require(_stakingPool.transfer(msg.sender, amountMinusPenalty),
            'TokenSpring: transfer out of staking pool failed');

        if(penaltyAmount > 0){
          // need to send penalty amount to the pool
          require(_stakingPool.transfer(penaltyAddress, penaltyAmount),
            'TokenSpring: transfer into staking pool failed');
        }

        emit Unstaked(msg.sender, amountMinusPenalty, totalStakedFor(msg.sender), penaltyAmount, "");
        emit TokensClaimed(msg.sender, rewardAmount);

        require(totalStakingShares == 0 || totalStaked() > 0,
                "TokenSpring: Error unstaking. Staking shares exist, but no staking tokens do");
        return rewardAmount;
    }

    function _unstakeAtIndex(uint256 index) private returns (uint256) {
        unlockTokens();

        // checks
        require(totalStakedFor(msg.sender) >= 0,
            'TokenSpring: user has zero staked');

        // 1. User Accounting
        UserTotals storage totals = _userTotals[msg.sender];
        Stake[] storage accountStakes = _userStakes[msg.sender];

        require(accountStakes.length > index,
            'TokenSpring: unstake index is not available');

        Stake storage lastStake = accountStakes[index];

        // Redeem from most recent stake and go backwards in time.
        uint256 stakingShareSecondsToBurn = 0;
        uint256 rewardAmount = 0;
        uint256 penaltyAmount = 0;
        // normalized amount from this CD
        uint256 totalAmount = lastStake.stakingShares.mul(totalStaked()).div(totalStakingShares);
        require(totalAmount > 0, 'TokenSpring: unstake index amount is zero');

        uint256 stakeTimeSec = now.sub(lastStake.timestampSec);
        uint256 stakeTimeSecCalculated = lastStake.lockTimestampSec.sub(lastStake.timestampSec);

        // MUST fully redeem a past stake, CD gets destroyed
        stakingShareSecondsToBurn = lastStake.stakingShares.mul(stakeTimeSecCalculated);

        // Need to be penalized
        if(lastStake.lockTimestampSec > now){
          // amountOfThisStake * (totalLock - actualLock)/totalLock) / 2
          penaltyAmount = penaltyAmount.add(stakeTimeSecCalculated.sub(stakeTimeSec).mul(totalAmount).div(stakeTimeSecCalculated).div(2));
        } else {
          // this contract was fulfilled, make sure to pay out the reward based on the calculated time
          rewardAmount = computeNewReward(rewardAmount, stakingShareSecondsToBurn, stakeTimeSecCalculated);
        }

        delete accountStakes[index];

        totals.stakingShareSeconds = totals.stakingShareSeconds.sub(stakingShareSecondsToBurn);
        totals.stakingShares = totals.stakingShares.sub(totalStakingShares.mul(totalAmount).div(totalStaked()));

        // 2. Global Accounting
        _totalStakingShareSeconds = _totalStakingShareSeconds.sub(stakingShareSecondsToBurn);
        totalStakingShares = totalStakingShares.sub(totalStakingShares.mul(totalAmount).div(totalStaked()));

        // what the staker should receive
        uint256 amountMinusPenalty = totalAmount.sub(penaltyAmount);
        require(totalAmount >= penaltyAmount, 'TokenSpring: penalty amount exceeds amount being redeemed');

        // just because we have penalties, does not mean we do not have rewards to pay out
        if(rewardAmount > 0) {
          // this unstake has no penalty, pay out the rewards
          require(_unlockedPool.transfer(msg.sender, rewardAmount),
              'TokenSpring: transfer out of unlocked pool failed');
        }

        // pay out the contract deposit amount minus any penalty
        require(_stakingPool.transfer(msg.sender, amountMinusPenalty),
            'TokenSpring: transfer out of staking pool failed');

        if(penaltyAmount > 0){
          // need to send penalty amount to the pool
          require(_stakingPool.transfer(penaltyAddress, penaltyAmount),
            'TokenSpring: transfer into staking pool failed');
        }

        emit Unstaked(msg.sender, amountMinusPenalty, totalStakedFor(msg.sender), penaltyAmount, "");
        emit TokensClaimed(msg.sender, rewardAmount);

        require(totalStakingShares == 0 || totalStaked() > 0,
                "TokenSpring: Error unstaking. Staking shares exist, but no staking tokens do");
        return rewardAmount;
    }

    function computeNewReward(uint256 currentRewardTokens,
                                uint256 stakingShareSeconds,
                                uint256 stakeTimeSec) private view returns (uint256) {

        uint256 newRewardTokens =
            totalUnlocked()
            .mul(stakingShareSeconds)
            .div(_totalStakingShareSeconds);

        if (stakeTimeSec >= bonusPeriodSec) {
            return currentRewardTokens.add(newRewardTokens);
        }

        uint256 oneHundredPct = 10**BONUS_DECIMALS;
        uint256 bonusedReward =
            startBonus
            .add(oneHundredPct.sub(startBonus).mul(stakeTimeSec).div(bonusPeriodSec))
            .mul(newRewardTokens)
            .div(oneHundredPct);
        return currentRewardTokens.add(bonusedReward);
    }


    function totalStakedFor(address addr) public view returns (uint256) {
        return totalStakingShares > 0 ?
            totalStaked().mul(_userTotals[addr].stakingShares).div(totalStakingShares) : 0;
    }


    function totalStaked() public view returns (uint256) {
        return _stakingPool.balance();
    }


    function token() external view returns (address) {
        return address(getStakingToken());
    }

    function updateAccounting(uint256 timeForContract, uint256 amountForContract) internal returns (
        uint256, uint256, uint256, uint256, uint256, uint256) {

        unlockTokens();

        // Global accounting, should ONLY happen on new stake
        uint256 newStakingShareSeconds =
            timeForContract
            .sub(now)
            .mul(amountForContract);
        _totalStakingShareSeconds = _totalStakingShareSeconds.add(newStakingShareSeconds);

        // User Accounting, should ONLY happen on new stake
        UserTotals storage totals = _userTotals[msg.sender];
        uint256 newUserStakingShareSeconds =
            timeForContract
            .sub(now)
            .mul(amountForContract);
        totals.stakingShareSeconds =
            totals.stakingShareSeconds
            .add(newUserStakingShareSeconds);

        uint256 totalUserRewards = (_totalStakingShareSeconds > 0)
            ? totalUnlocked().mul(totals.stakingShareSeconds).div(_totalStakingShareSeconds)
            : 0;

        return (
            totalLocked(),
            totalUnlocked(),
            totals.stakingShareSeconds,
            _totalStakingShareSeconds,
            totalUserRewards,
            now
        );
    }

    function getAccounting() public returns (
        uint256, uint256, uint256, uint256, uint256, uint256) {

        unlockTokens();

        // User Accounting
        UserTotals storage totals = _userTotals[msg.sender];

        uint256 totalUserRewards = (_totalStakingShareSeconds > 0)
            ? totalUnlocked().mul(totals.stakingShareSeconds).div(_totalStakingShareSeconds)
            : 0;

        return (
            totalLocked(),
            totalUnlocked(),
            totals.stakingShareSeconds,
            _totalStakingShareSeconds,
            totalUserRewards,
            now
        );
    }

    function getContractAtIndex(address addr, uint256 index) public view returns (uint256, uint256, uint256) {
        // User Accounting
        Stake[] storage accountStakes = _userStakes[addr];
        uint256 stakingShares = 0;
        uint256 timestampSec = 0;
        uint256 lockTimestampSec = 0;

        if(accountStakes.length > index){
          Stake storage indexStake = accountStakes[index];
          stakingShares = indexStake.stakingShares;
          timestampSec = indexStake.timestampSec;
          lockTimestampSec = indexStake.lockTimestampSec;
        }

        return (
            stakingShares,
            timestampSec,
            lockTimestampSec
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
        require(unlockSchedules.length < _maxUnlockSchedules,
            'TokenSpring: reached maximum unlock schedules');

        // Update lockedTokens amount before using it in computations after.
        //updateAccounting();
        unlockTokens();

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

        require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), amount),
            'TokenSpring: transfer into locked pool failed');
        emit TokensLocked(amount, durationSec, totalLocked());
    }


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
            require(_lockedPool.transfer(address(_unlockedPool), unlockedTokens),
                'TokenSpring: transfer out of locked pool failed');
            emit TokensUnlocked(unlockedTokens, totalLocked());
        }

        return unlockedTokens;
    }


    function unlockScheduleShares(uint256 s) private returns (uint256) {
        UnlockSchedule storage schedule = unlockSchedules[s];

        if(schedule.unlockedShares >= schedule.initialLockedShares) {
            return 0;
        }

        uint256 sharesToUnlock = 0;
        // Special case to handle any leftover dust from integer division
        if (now >= schedule.endAtSec) {
            sharesToUnlock = (schedule.initialLockedShares.sub(schedule.unlockedShares));
            schedule.lastUnlockTimestampSec = schedule.endAtSec;
        } else {
            sharesToUnlock = now.sub(schedule.lastUnlockTimestampSec)
                .mul(schedule.initialLockedShares)
                .div(schedule.durationSec);
            schedule.lastUnlockTimestampSec = now;
        }

        schedule.unlockedShares = schedule.unlockedShares.add(sharesToUnlock);
        return sharesToUnlock;
    }
}