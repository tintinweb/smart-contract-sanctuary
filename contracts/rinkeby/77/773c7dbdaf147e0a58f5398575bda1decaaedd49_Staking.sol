/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () internal {
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
    constructor () internal {
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


contract Staking is Ownable, Pausable {
    using SafeMath for uint256;

    uint256 public constant REWADS_PERIOD = 90 days;
    uint256 public constant COOLDOWN_PERIOD = 30 days;
    uint256 public constant MAX_BONUS_MULTIPLIER = 6;

    struct Stake {
        uint256 stakeTime;
        uint256 stakeAmount;
        uint256 collectedRewardsTime;
    }

    mapping(address => Stake) public staked;
    uint256 public totalStaked;

    address public wndauToken;
    address public uniswapLPtoken;
    
    uint256 public currentPeriodStart;

    constructor(address _wndau, address _unilp) public {
        wndauToken = _wndau;
        uniswapLPtoken = _unilp;
    }

    function setNextPeriodReward(uint256 _rewardsAmount) external onlyOwner {
        require(_rewardsAmount > 0, "Incorrect amount");
        require(currentPeriodStart == 0 || isCooldown(), "There is active stake period");
        require(block.timestamp > currentPeriodStart, "Next staking period already set");

        IERC20(wndauToken).transferFrom(_msgSender(), address(this), _rewardsAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // stake Uniswap LP tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Incorrect amount");

        Stake storage s = staked[_msgSender()];
        
        // Claim before stake increasement
        if (s.stakeAmount > 0 && isCooldown())
        {
            claim();
        }

        IERC20(uniswapLPtoken).transferFrom(_msgSender(), address(this), _amount);

        s.stakeTime = block.timestamp;
        s.stakeAmount = s.stakeAmount.add(_amount);
        totalStaked = totalStaked.add(_amount);
    }

    // unstake Uniswap LP tokens
    function unstake() external {
        Stake storage s = staked[_msgSender()];

        uint256 _amount = s.stakeAmount;
        require(_amount > 0, "No staked tokens");

        if (isCooldown())
        {
            claim();
        }

        s.stakeAmount = 0;
        totalStaked = totalStaked.sub(_amount);

        IERC20(uniswapLPtoken).transfer(_msgSender(), _amount);
    }

    // claim wNDAU rewards
    function claim() public {
        // Can claim on cooldown period only
        require(isCooldown(), "Can not claim during staking period");

        Stake storage s = staked[_msgSender()];

        // Check that the user hasn't colelcted rewards yet
        require(s.stakeAmount > 0, "No staked tokens");
        if (!hasNotCollected(s.collectedRewardsTime)) {
            return;
        }

        uint256 rewards = calculateUserRewards(_msgSender());
        require(IERC20(wndauToken).balanceOf(address(this)) >= rewards, "Not enough wNDAU on the contract");

        s.collectedRewardsTime = block.timestamp;
        IERC20(wndauToken).transfer(_msgSender(), rewards);

        //Update stake time if it is planned to be prolongated
        s.stakeTime = block.timestamp;
    }

    function calculateUserRewards(address _user) public view returns(uint256) {
        Stake storage s = staked[_user];
        uint256 _stakeTime = s.stakeTime;
        
        // No stake
        if (s.stakeAmount == 0 || _stakeTime == 0) return 0;

        uint256 _currentPeriodStart = currentPeriodStart;
        uint256 _currentPeriodEnd = _currentPeriodStart.add(REWADS_PERIOD);
        
        // If the next period is already set - calculate the previous one
        // It means we are in a cooldown phase
        if (nextPeriodSet()) {
            _currentPeriodEnd = currentPeriodStart.sub(COOLDOWN_PERIOD);
            _currentPeriodStart = _currentPeriodEnd.sub(REWADS_PERIOD);
        }
        
        // Start calculation from the last stake
        if (_stakeTime < _currentPeriodStart) {
            _stakeTime = _currentPeriodStart;
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
        uint256 totalRewards = IERC20(wndauToken).balanceOf(address(this));
        if (totalRewards == 0) return 0;

        uint256 baseRewardAmount = totalRewards.div(MAX_BONUS_MULTIPLIER);

        uint256 multiplier = lockTime.mul(MAX_BONUS_MULTIPLIER).div(REWADS_PERIOD);
        if (multiplier == 0) multiplier = 1;

        // Calculate part of rewards the user has got based on the length of stake
        uint256 stakedDays = lockTime.div(60).div(60);

        return baseRewardAmount.mul(_stakeAmount)
                               .mul(multiplier) // Apply multiplier
                               .mul(stakedDays) // Get part based on the length of stake
                               .div(90)
                               .div(totalStaked); // Get share in pool
    }

    function isCooldown() public view returns(bool) {
        return nextPeriodSet() ||
               block.timestamp > currentPeriodStart.add(REWADS_PERIOD);
    }


    function hasNotCollected(uint256 _rewardsTime) internal view returns(bool) {
        if (_rewardsTime == 0) return true;

        // New staking period is set
        if (nextPeriodSet()) {
            if (_rewardsTime < currentPeriodStart.sub(COOLDOWN_PERIOD)) {
                return true;
            }
        }
        else {
            if (_rewardsTime < currentPeriodStart) return true;
        }

        return false;
    }

    function nextPeriodSet() internal view returns (bool) {
        return currentPeriodStart > block.timestamp;
    }

}