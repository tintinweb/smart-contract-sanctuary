/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^ 0.8.7;

interface IERC20 {

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract StakingContract is Context, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _tStaked;
    address[] private _stakers;
    IERC20 private _sToken;
    IERC20 private _rToken;
    bool private _startRound;
    bool private _startDistribution;
    uint256 private _amountPerMonth;
    uint256 private _dPercentage = 20;
    uint256 private _month;
    uint256 private _round;
    uint256 private _minStakingTime;
    uint256 private _minStakingTimeFirstMonth;
    mapping(uint256 => uint256) private _stakingStartTime;
    uint256 private _totalDistributed;
    mapping(address => mapping(uint256 => bool)) private _withdrawalOfThisMonth;


    constructor(IERC20 sToken_, IERC20 rToken_) {
        _sToken = sToken_;
        _rToken = rToken_;
        _minStakingTime = 300;
        _minStakingTimeFirstMonth = 300;
    }

    function deposit(uint256 amount) public {
        _preValidateDeposit(amount);
        _sToken.transferFrom(_msgSender(), address(this), amount);
        _balances[_msgSender()] += amount;
        if(!_startRound){
            _tStaked[_msgSender()] = block.timestamp;
            _stakers.push(_msgSender());
        }

    }

    function withdrawStaking(uint256 amount) public {
        uint256 balance = _balances[_msgSender()];
        require(balance >= amount, "You have no staking");
        _balances[_msgSender()] -= amount;
        delete(_tStaked[_msgSender()]);
        delete(_tStaked[_msgSender()]);
        _sToken.transfer(_msgSender(), amount);
    }

    function _preValidateDeposit(uint256 amount) internal view {
        require(amount > 0, "Deposit amount is less than 1.");
        require(_sToken.allowance(_msgSender(), address(this)) >= amount, "Please approve us to spend the amount.");
        this;
    }

    function timeStaked(address account) public view returns(uint256) {
        return _tStaked[account];
    }

    function isRoundStarted() public view returns(uint256, bool) {
        return (_round, _startRound);
    }

    function startRound(uint256 round) public onlyOwner {
        require(round > _round, "Round already started.");
        _startRound = true;
        _round += 1;
        _stakingStartTime[_round] = block.timestamp;
    }

    function resetStaking() public onlyOwner {
        _startRound = false;
        _startDistribution = false;
        _month = 0;
        for(uint256 i; i < _stakers.length; i++) {
            _tStaked[_stakers[i]] = block.timestamp;
        }
    }

    function stakingRoundMonth() public view returns(uint256, uint256) {
        return (_round, _month);
    }

    function startMonthlyDistribution() public onlyOwner {
        uint256 balance = _rToken.balanceOf(address(this));
        require(balance > 0, "Not enough reward token balance.");
        if(_month == 0) {
            _amountPerMonth = balance.mul(_dPercentage).div(10**2);
        }
        _startDistribution = true;
        _month += 1;
    }

    function stopDistribution() public onlyOwner {
        _startDistribution = false;
    }

    function changeDistributionPercentage(uint256 newPercentage, uint256 round_) public onlyOwner {
        uint256 rBalance = _rToken.balanceOf(address(this));
        require(rBalance > 0, "Not enough reward token balance.");
        require(!_startDistribution, "Distribution has already started.");
        require(round_ > _round, "This round already set.");
        _dPercentage = newPercentage;
        _amountPerMonth = rBalance.mul(newPercentage).div(10**2);
    }

    function calculateReward(address account) public view returns(uint256){
        uint256 timeSpan = block.timestamp - _tStaked[account];
        if((timeSpan < _minStakingTime) || (_tStaked[account] > _stakingStartTime[_round]) || _balances[account] <= 0) {
            return 0;
        }
        uint256 _tRewardBalance = _rToken.balanceOf(address(this));
        uint256 _tStakingBalance = _sToken.balanceOf(address(this));
        uint256 _myHoldingInPool = _balances[account].mul(10**2).div(_tStakingBalance);
        uint256 _myRewardInPool = _tRewardBalance.mul(_myHoldingInPool).div(10**2);
        return _myRewardInPool;
    }

    function _preValidateRewardWithdraw(address account) internal view {
        uint256 minStakingTime = _minStakingTimeFirstMonth;
        if(_month > 1) {
            minStakingTime = _minStakingTime;
        }
        require(_startDistribution, "Reward distribution of this month is not started.");
        require(_balances[account] > 0, "You have not staked anything yet.");
        require((block.timestamp - _tStaked[account]) > _minStakingTime, "Reward withdraw time not reached");
        require(_tStaked[account] > 0, "You have deposited but missed the staking round.");
        require(!_withdrawalOfThisMonth[account][_month], "Already withdrawn this month.");
        this;
    }

    function withdrawReward() public {
        _preValidateRewardWithdraw(_msgSender());
        uint256 rewardAmount = calculateReward(_msgSender());
        _totalDistributed += rewardAmount;
        _withdrawalOfThisMonth[_msgSender()][_month] = true;
        _tStaked[_msgSender()] = block.timestamp;
        _rToken.transfer(_msgSender(), rewardAmount);
    }

    function checkWithdrawThisMonth(address account) public view returns(bool) {
        return _withdrawalOfThisMonth[account][_month];
    }

    function minStakingTime() public view returns(uint256){
        return _minStakingTime;
    }

}