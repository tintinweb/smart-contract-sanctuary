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

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

// File: contracts/IStaking.sol

pragma solidity 0.5.0;

/**
 * @title Staking interface, as defined by EIP-900.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract IStaking {
    event Staked(address indexed user, uint256 amount, uint256 total, uint256 time, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, uint256 penaltyAmount, bytes data);

    function stake(uint256 amount, uint256 time, bytes calldata data) external;
    function stakeFor(address user, uint256 amount, uint256 time, bytes calldata data) external;
    function unstake(uint256 amount, bytes calldata data) external;
    function unstakeAtIndex(uint256 index, bytes calldata data) external;
    function totalStakedFor(address addr) public view returns (uint256);
    function totalStaked() public view returns (uint256);
    function token() external view returns (address);

    /**
     * @return False. This application does not support staking history.
     */
    function supportsHistory() external pure returns (bool) {
        return false;
    }
}

// File: contracts/TokenPool.sol

pragma solidity 0.5.0;



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
}

// File: contracts/TokenSpring.sol

pragma solidity 0.5.0;






/**
 * @title Token Spring
 * @dev A smart-contract based mechanism to distribute tokens over time, inspired loosely by
 *      Ampleforth Geyser / HEX.
 *
 *      Distribution tokens are added to a locked pool in the contract and become unlocked over time
 *      according to a once-configurable unlock schedule. Once unlocked, they are available to be
 *      claimed by users.
 *
 *      A user may deposit tokens to accrue ownership share over the unlocked pool. This owner share
 *      is a function of the number of tokens deposited as well as the length of the lock time promised.
 *      Specifically, a user's share of the currently-unlocked pool equals their 'sum(lockTime * amount)''
 *      divided by the global 'sum(lockTime * amount)'.
 *
 *      If a user revokes their tokens from the pool too early, there is a penalty that gets applied to the
 *      received funds. The calculation for penalty is: (% of time left / 2) * deposited UNI-V2 LP.
 *      A 10 UNI-V2 LP deposit for 60 days getting removed at 30 days is a 2.5 UNI-V2 LP penalty leaving the
 *      user with 7.5 UNI-V2 LP only and no rewards, losing 25% of their initial liquidity. The penalty amount
 *      immediately gets deposited towards a designated penatly address. This encourages dedicated stakers and follows
 *      very loosely to a traditional certificate of deposit
 *
 */
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
    uint256 public maxLockTimeSeconds = 90 days;

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

    /**
     * @param stakingToken The token users deposit as stake.
     * @param distributionToken The token users receive as they unstake.
     * @param maxUnlockSchedules Max number of unlock stages, to guard against hitting gas limit.
     * @param startBonus_ Starting time bonus, BONUS_DECIMALS fixed point.
     *                    e.g. 25% means user gets 25% of max distribution tokens.
     * @param bonusPeriodSec_ Length of time for bonus to increase linearly to max.
     * @param initialSharesPerToken Number of shares to mint per staking token on first stake.
     */
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
    }

    /**
     * @param penaltyAddress_ The penalty address to use for penalties.
     */

    function setPenaltyAddress(address penaltyAddress_)
        external
        onlyOwner
    {
        penaltyAddress = penaltyAddress_;
        emit LogPenaltyAddressUpdated(penaltyAddress_);
    }

    /**
     * @param maxLockTimeSeconds_ The max time allowed to lock a contract.
     */

    function setMaxLockTimeSeconds(uint256 maxLockTimeSeconds_)
        external
        onlyOwner
    {
        maxLockTimeSeconds = maxLockTimeSeconds_;
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

    /**
     * @dev Transfers amount of deposit tokens from the user.
     * @param amount Number of deposit tokens to stake.
     * @param data Not used.
     */
    function stake(uint256 amount, uint256 time, bytes calldata data) external {
        _stakeFor(msg.sender, msg.sender, amount, time);
    }

    /**
     * @dev Transfers amount of deposit tokens from the caller on behalf of user.
     * @param user User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     * @param data Not used.
     */
    function stakeFor(address user, uint256 amount, uint256 time, bytes calldata data) external {
        _stakeFor(msg.sender, user, amount, time);
    }


    /**
     * @dev Private implementation of staking methods.
     * @param staker User address who deposits tokens to stake.
     * @param beneficiary User address who gains credit for this stake operation.
     * @param amount Number of deposit tokens to stake.
     * @param time Seconds added to current time for the expiration time.
     */
    function _stakeFor(address staker, address beneficiary, uint256 amount, uint256 time) private {
        require(amount > 0, 'TokenSpring: stake amount is zero');
        require(beneficiary != address(0), 'TokenSpring: beneficiary is zero address');
        require(totalStakingShares == 0 || totalStaked() > 0,
                'TokenSpring: Invalid state. Staking shares exist, but no staking tokens do');
        require(time > 0, 'TokenSpring: expiration time is too soon');

        uint256 expiryTime = now.add(time);

        // restrict the max lock time to prevent attackers from setting a ceiling limit
        if(time > maxLockTimeSeconds){
          expiryTime = now.add(maxLockTimeSeconds);
        }

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

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @param data Not used.
     */
    function unstake(uint256 amount, bytes calldata data) external {
        _unstake(amount);
    }

    /**
     * @dev Unstakes a contract at specific index. User also receives their
     * alotted number of distribution tokens.
     * @param index Index of staking contract.
     * @param data Not used.
     */
    function unstakeAtIndex(uint256 index, bytes calldata data) external {
        _unstakeAtIndex(index);
    }

    /**
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens that would be rewarded.
     */
    function unstakeQuery(uint256 amount) public returns (uint256) {
        return _unstake(amount);
    }

    /**
     * @param index Index of staking contract.
     * @return The total number of distribution tokens that would be rewarded.
     */
    function unstakeAtIndexQuery(uint256 index) public returns (uint256) {
        return _unstakeAtIndex(index);
    }

    /**
     * @dev Unstakes a certain amount of previously deposited tokens. User also receives their
     * alotted number of distribution tokens.
     * @param amount Number of deposit tokens to unstake / withdraw.
     * @return The total number of distribution tokens rewarded.
     */
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


    /**
     * @dev Unstakes a certain index of previously deposited contract. User also receives their
     * alotted number of distribution tokens.
     * @param index Index of contract to withdraw.
     * @return The total number of distribution tokens rewarded.
     */
    function _unstakeAtIndex(uint256 index) private returns (uint256) {
        unlockTokens();

        // checks
        require(totalStakedFor(msg.sender) > 0,
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

        // reset the array, remove the index we are unstaking
        for (uint256 i = index; i < accountStakes.length-1; i++){
            accountStakes[i] = accountStakes[i+1];
        }

        accountStakes.length--;

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

    /**
     * @param addr The user to look up staking information for.
     * @return The number of staking tokens deposited for addr.
     */
    function totalStakedFor(address addr) public view returns (uint256) {
        return totalStakingShares > 0 ?
            totalStaked().mul(_userTotals[addr].stakingShares).div(totalStakingShares) : 0;
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
     * @dev An internally callable function to update the accounting state of the system with staking information.
     *      Global state and state for the caller are updated.
     * @return [0] balance of the locked pool
     * @return [1] balance of the unlocked pool
     * @return [2] caller's staking share seconds
     * @return [3] global staking share seconds
     * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
     * @return [5] block timestamp
     */
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

    /**
     * @dev A globally callable function to get the accounting state of the system.
     * @return [0] balance of the locked pool
     * @return [1] balance of the unlocked pool
     * @return [2] caller's staking share seconds
     * @return [3] global staking share seconds
     * @return [4] Rewards caller has accumulated, optimistically assumes max time-bonus.
     * @return [5] block timestamp
     */
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

    /**
     * @dev A globally callable function to get the staking contracts of an address.
     * @return [0] contracts of the address
     * @return [1] block timestamp
     */
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
            require(_lockedPool.transfer(address(_unlockedPool), unlockedTokens),
                'TokenSpring: transfer out of locked pool failed');
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