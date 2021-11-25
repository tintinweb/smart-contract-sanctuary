/**
 *Submitted for verification at Etherscan.io on 2021-11-25
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

    IERC20 private _stakingToken;
    IERC20 private _rewardToken;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesBNB;
    mapping(address => uint256) private _timeStaked;
    mapping(address => uint256) private _usersRewarded;

    uint256 private _totalRewards;

    uint256 private _minStakingTime = 30; // in seconds

    uint256 private _rewardMidYear = 10;
    uint256 private _rewardMonth = 20;
    uint256 private _timeInMidY = 180 days;

    modifier isMinTimeStaked(){
        require((_timeStaked[_msgSender()] - block.timestamp) >= _minStakingTime, "Minimum staking time not reached.");
        _;
    }

    constructor(IERC20 stakingToken_, IERC20 rewaredToken_) {
        _stakingToken = stakingToken_;
        _rewardToken = rewaredToken_;
    }

    function minTimeToStake() public view returns(uint256) {
        return _minStakingTime;
    }

    function rewardMidYear() public view returns(uint256) {
        return _rewardMidYear;
    }

    function rewardEachMonth() public view returns(uint256) {
        return _rewardMonth;
    }

    function changeRewardToken(IERC20 newRewardToken_) public onlyOwner {
        _rewardToken = newRewardToken_;
    }

    function changeStakingToken(IERC20 newStakingToken_) public onlyOwner {
        _stakingToken = newStakingToken_;
    } 

    function _calculateReward(address account) internal view returns(uint256) {
        uint256 _rTokenBalanceInPool = _rewardToken.balanceOf(address(this));
        uint256 _sTokenBalanceInPool = _stakingToken.balanceOf(address(this));
        uint256 _stakedBalance = _balances[account];
        uint256 _userStakingTime = _timeStaked[account];
        if(_stakedBalance <= 0 || (block.timestamp - _userStakingTime) <= _minStakingTime) {
            return 0;
        }

        uint256 _rewardPer = 20;
        if((block.timestamp - _userStakingTime) >= _timeInMidY) {
            _rewardPer = 10;
        }
        uint256 _uSInPool = _balances[account].div(_sTokenBalanceInPool).mul(10**2);
        uint256 _uFinalReward = _rTokenBalanceInPool.mul(_uSInPool).div(10**2);
        return _uFinalReward;
    }

    function showReward(address account) public view returns(uint256) {
        return _calculateReward(account);
    }

    function getReward() public isMinTimeStaked {
        uint256 _myReward = _calculateReward(_msgSender());
        require(_myReward > 0, "No reward generated yet");
        require(_rewardToken.balanceOf(address(this)) > 0, "Reward token value in the pool is 0.");
        require(_balances[_msgSender()] > 0, "You have not staked any coin yet.");
        _timeStaked[_msgSender()] = block.timestamp;
        _usersRewarded[_msgSender()] += _myReward;
        _totalRewards += _myReward;
        _rewardToken.transfer(_msgSender(), _myReward);
    }

    function getBackStaking() public {
        require(_balances[_msgSender()] > 0, "Sorry, You have not staked anything yet.");
        uint256 _myBalance = _balances[_msgSender()];
        _balances[_msgSender()] = 0;
        delete(_timeStaked[_msgSender()]);
        _stakingToken.transfer(_msgSender(), _myBalance);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Can not be deposited less than 1.");
        require(_stakingToken.balanceOf(_msgSender()) > 0, "You have nothing to deposit.");
        require(_stakingToken.allowance(_msgSender(), address(this)) >= amount, "Please approve us to spend the amount to stake.");

        _stakingToken.transferFrom(_msgSender(), address(this), amount);
        _timeStaked[_msgSender()] = block.timestamp;
        _balances[_msgSender()] += amount;
    }

    function depositBNB() public payable {
        _balancesBNB[_msgSender()] += msg.value;
    }

    function withdrawBNB(uint256 amount) public {
        require(_balancesBNB[_msgSender()] >= amount, "No BNB Deposits.");
        payable(_msgSender()).transfer(amount);
        _balancesBNB[_msgSender()] -= amount;
    }


    receive() external payable {
        depositBNB();
    }

    function monthlyRewardPer() public view returns(uint256){
        return _rewardMonth;
    }

    function halfYearlyRewardPer() public view returns(uint256) {
        return _rewardMidYear;
    }

    function setRewardPer(uint256 montly, uint256 halfYearly) public onlyOwner {
        _rewardMonth = montly;
        _rewardMidYear = halfYearly;
    }

    function setMinStakingTime(uint256 inSeconds) public onlyOwner {
        _minStakingTime = inSeconds;
    }

    function setMidYearTime(uint256 inSeconds) public onlyOwner {
        _timeInMidY = inSeconds;
    }

    function stakingToken() public view returns(IERC20) {
        return _stakingToken;
    }

    function rewardToken() public view returns(IERC20) {
        return _stakingToken;
    }

}