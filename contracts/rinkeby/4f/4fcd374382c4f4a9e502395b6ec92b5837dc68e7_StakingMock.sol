/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract Staking {
    using SafeMath for uint256;

    uint256 public REWARDS_PERIOD = 90 days;
    uint256 public COOLDOWN_PERIOD = 30 days;
    uint256 public constant MAX_BONUS_MULTIPLIER = 6;

    struct Stake {
        uint256 stakeTime;
        uint256 stakeAmount;
        uint256 collectedRewardsTime;
    }

    mapping(address => Stake) public staked;
    uint256 public totalStaked;
    mapping(uint256 => uint256) public roundRewards;
    mapping(uint256 => uint256) public stakedInRound;
    uint256 roundNum;

    address public wndauToken;
    address public uniswapLPtoken;
    
    uint256 public currentPeriodStart;

    address internal multisigCaller;

    modifier onlyMultisig() {
        require(msg.sender == multisigCaller, "Only multisigned");
        _;
    }

    constructor(address _multisigCaller, address _wndau, address _unilp) public {
        wndauToken = _wndau;
        uniswapLPtoken = _unilp;
        multisigCaller = _multisigCaller;
    }

    function setNextPeriod() external virtual onlyMultisig {
        require(currentPeriodStart == 0 || isCooldown(), "There is active stake period");
        require(block.timestamp > currentPeriodStart + REWARDS_PERIOD + COOLDOWN_PERIOD, "Too early to start");
        

        currentPeriodStart = block.timestamp;
        stakedInRound[roundNum + 1] = stakedInRound[roundNum + 1].add(stakedInRound[roundNum]);
        roundNum += 1;
        roundRewards[roundNum] = IERC20(wndauToken).balanceOf(address(this));
    }

    function getWndau(address _recepient) external virtual onlyMultisig {
        require(isCooldown(), "Can not withdraw during staking period");

        roundRewards[roundNum] = 0;
        roundRewards[roundNum.sub(1)] = 0;
        IERC20(wndauToken).transfer(_recepient, IERC20(wndauToken).balanceOf(address(this)));
    }

    function resetRewards(uint256 _roundNum) external virtual onlyMultisig {
        require(_roundNum > 0 && _roundNum <= roundNum, "Incorrect round num");
        roundRewards[_roundNum] = IERC20(wndauToken).balanceOf(address(this));
    }

    // stake Uniswap LP tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Incorrect amount");

        Stake storage s = staked[msg.sender];
        
        // Claim before stake increasement
        if (s.stakeAmount > 0 && isCooldown())
        {
            claim();
        }

        IERC20(uniswapLPtoken).transferFrom(msg.sender, address(this), _amount);

        s.stakeTime = block.timestamp;
        s.stakeAmount = s.stakeAmount.add(_amount);
        totalStaked = totalStaked.add(_amount);

        if (isCooldown() && block.number > currentPeriodStart) {
            stakedInRound[roundNum + 1] = stakedInRound[roundNum + 1].add(_amount);
        }
        else {
            stakedInRound[roundNum] = stakedInRound[roundNum].add(_amount);
        }
    }

    // unstake Uniswap LP tokens
    function unstake() external {
        Stake storage s = staked[msg.sender];

        uint256 _amount = s.stakeAmount;
        require(_amount > 0, "No staked tokens");

        if (isCooldown())
        {
            claim();
        }
        else
        {
            stakedInRound[getCurrentRound()] = stakedInRound[getCurrentRound()].sub(_amount);
        }

        s.stakeAmount = 0;
        s.stakeTime = 0;
        s.collectedRewardsTime = 0;
        totalStaked = totalStaked.sub(_amount);

        IERC20(uniswapLPtoken).transfer(msg.sender, _amount);
    }

    // claim wNDAU rewards
    function claim() public {
        // Can claim on cooldown period only
        require(isCooldown(), "Can not claim during staking period");

        Stake storage s = staked[msg.sender];

        // Check that the user hasn't colelcted rewards yet
        require(s.stakeAmount > 0, "No staked tokens");
        if (!hasNotCollected(s.collectedRewardsTime)) {
            return;
        }

        uint256 rewards = calculateUserRewards(msg.sender);

        if (rewards == 0) {
            return;
        }

        require(IERC20(wndauToken).balanceOf(address(this)) >= rewards, "Not enough wNDAU on the contract");

        s.collectedRewardsTime = block.timestamp;
        //Update stake time if it is planned to be prolongated
        s.stakeTime = block.timestamp;

        IERC20(wndauToken).transfer(msg.sender, rewards);
    }

    function calculateUserRewards(address _user) public view returns(uint256) {
        Stake storage s = staked[_user];
        uint256 _stakeTime = s.stakeTime;
        
        // No stake
        if (s.stakeAmount == 0 || _stakeTime == 0) return 0;
        if (currentPeriodStart == 0) return 0; // No period started

        uint256 _currentPeriodEnd = currentPeriodStart.add(REWARDS_PERIOD);
        
        // Start calculation from the last stake
        if (_stakeTime < currentPeriodStart) {
            _stakeTime = currentPeriodStart;
        }

        // if in cooldown period
        if (_stakeTime > _currentPeriodEnd) return 0; // Staked in current cooldown
        if (s.collectedRewardsTime > _currentPeriodEnd) return 0; // Already collected reward

        // Check how long are funds staked
        uint256 lockTime;

        if (block.timestamp > _currentPeriodEnd) {
            lockTime = _currentPeriodEnd.sub(_stakeTime);
        }
        else {
            lockTime = block.timestamp.sub(_stakeTime);
        }

        return calculateRewardsWithBonus(lockTime, s.stakeAmount);
    }


    function calculateRewardsWithBonus(uint256 lockTime, uint256 _stakeAmount) public view returns(uint256) {
        uint256 currentRoundReward = roundRewards[getCurrentRound()];
        if (currentRoundReward == 0) return 0;
        uint256 curStake = stakedInRound[getCurrentRound()];
        if (curStake == 0) return 0;

        uint256 baseRewardAmount = currentRoundReward.div(MAX_BONUS_MULTIPLIER);

        uint256 multiplier = lockTime.mul(MAX_BONUS_MULTIPLIER).div(REWARDS_PERIOD) + 1;

        if (multiplier > 6) multiplier = 6;

        return baseRewardAmount.mul(_stakeAmount)
                               .mul(multiplier) // Apply multiplier
                               .mul(lockTime) // Get part based on the length of stake
                               .div(REWARDS_PERIOD)
                               .div(curStake); // Get share in pool
    }

    function isCooldown() public view returns(bool) {
        return block.timestamp < currentPeriodStart || block.timestamp > currentPeriodStart.add(REWARDS_PERIOD);
    }


    function hasNotCollected(uint256 _rewardsTime) internal view returns(bool) {
        if (_rewardsTime == 0) return true;

        if (_rewardsTime < currentPeriodStart) return true;

        return false;
    }

    function getCurrentRound() internal view returns(uint256) {
        if (block.number < currentPeriodStart) {
            return roundNum - 1;
        }
        else {
            return roundNum;
        }
    }

}

contract StakingMock is Staking {
    constructor(address _multisigCaller, address _wndau, address _unilp) public Staking(_multisigCaller, _wndau, _unilp) {
    }

    function setNextPeriod() external override {
        require(currentPeriodStart == 0 || isCooldown(), "There is active stake period");
        require(block.timestamp > currentPeriodStart + REWARDS_PERIOD + COOLDOWN_PERIOD, "Too early to start");
        

        currentPeriodStart = block.timestamp;
        stakedInRound[roundNum + 1] = stakedInRound[roundNum + 1].add(stakedInRound[roundNum]);
        roundNum += 1;
        roundRewards[roundNum] = IERC20(wndauToken).balanceOf(address(this));
    }


    function setRewardsPeriod(uint256 _rewardsPeriod) external {
        REWARDS_PERIOD = _rewardsPeriod;
    }
    
    function setCooldownPeriod(uint256 _cooldownPeriod) external {
        COOLDOWN_PERIOD = _cooldownPeriod;
    }

    function getWndau(address _recepient) external override {
        require(isCooldown(), "Can not withdraw during staking period");

        roundRewards[getCurrentRound()] = 0;
        IERC20(wndauToken).transfer(_recepient, IERC20(wndauToken).balanceOf(address(this)));
    }

    function resetRewards(uint256 _roundNum) external override {
        require(_roundNum > 0 && _roundNum <= roundNum, "Incorrect round num");
        roundRewards[_roundNum] = IERC20(wndauToken).balanceOf(address(this));
    }

}