/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);
  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint256);
  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);
  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);
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
  function allowance(address _owner, address spender) external view returns (uint256);
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
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }
  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}
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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
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

contract Staking is Context, Ownable {
    using SafeMath for uint;
    
    struct StakingInfo {
        uint amount;
        uint depositDate;
        uint rewardPercent;
    }
    
    uint public MIN_STAKE_AMOUNT;
    uint public MAX_STAKE_AMOUNT;
    uint public REWARD_DIVIDER = 10**8;
    
    IBEP20 stakingToken;
    uint public rewardPercent; //  percent value for per second  -> set 270 if you want 7% per month reward (because it will be divided by 10^8 for getting the small float number)
    uint public stakeStartDate;
    uint public stakeEndDate;
    
    uint public totalStakes;
    
    string public name = "Staking";
    
    uint public ownerTokensAmount;
    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;
    mapping(address => uint) public stakeholderIndex;

    //  percent value for per second  
    //  set 270 if you want 7% per month reward (because it will be divided by 10^8 for getting the small float number)
    //  7% per month = 7 / (30 * 24 * 60 * 60) ~ 0.00000270 (270 / 10^8)
    constructor(IBEP20 _stakingToken, uint _rewardPercent, uint _minStake, uint _maxStake, uint _stakeStartDate, uint _stakeEndDate) {
        stakingToken = _stakingToken;
        rewardPercent = _rewardPercent;
        MIN_STAKE_AMOUNT = _minStake;
        MAX_STAKE_AMOUNT = _maxStake;
        stakeStartDate =  _stakeStartDate;
        stakeEndDate = _stakeEndDate;
    }
    
    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);
    
    function changeRewardPercent(uint _rewardPercent) public onlyOwner {
        rewardPercent = _rewardPercent;
    }
    
    function changeMINSTAKE(uint _minStake) public onlyOwner {
        MIN_STAKE_AMOUNT = _minStake;
    }
    
    function changeMAXSTAKE(uint _maxStake) public onlyOwner {
        MAX_STAKE_AMOUNT = _maxStake;
    }
    
    function changeStakeStartDate(uint _startDate) public onlyOwner {
        stakeStartDate = _startDate;
    }
    
    function changeStakeEndDate(uint _endDate) public onlyOwner {
        stakeEndDate = _endDate;
    }
   
    function isStakeholder(address _address) public view returns(bool, uint256) {
        uint s = stakeholderIndex[_address]; // 1-based index
        if (s == 0) return (false, 0);
        return (true, s - 1); // return 0-based index
    }
    

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder)
            stakeholders.push(_stakeholder);
    }
    
    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            delete stakeholderIndex[_stakeholder];
            address lastStakeholder = stakeholders[stakeholders.length - 1];
            stakeholderIndex[lastStakeholder] = s+1; // 1-based index
            stakeholders[s] = lastStakeholder;
            stakeholders.pop();
        }
    }    
    
    function stake(uint256 _amount) public {
        require(block.timestamp < stakeStartDate, "Staking Pool is locked for fixed period!");
        require((_amount >= MIN_STAKE_AMOUNT), "Amount is less than Minimum stake limit!");
        require((_amount <= MAX_STAKE_AMOUNT), "Amount is greater than Maximum stake simit!");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        stakes[msg.sender].push(StakingInfo(_amount, block.timestamp ,rewardPercent));
        totalStakes = totalStakes.add(_amount);
        emit Staked(msg.sender, _amount);
    }

    function unstake() public {
        require(block.timestamp > stakeEndDate , "Staking Pool will be unlocked after fixed period!");
        uint withdrawAmount = 0;
        for (uint j = 0; j < stakes[msg.sender].length; j += 1) {
            uint amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            totalStakes = totalStakes.sub(amount);
            
            uint rewardAmount = amount.mul((stakeEndDate - stakeStartDate).mul(stakes[msg.sender][j].rewardPercent));
            rewardAmount = rewardAmount.div(REWARD_DIVIDER);
            withdrawAmount = withdrawAmount.add(rewardAmount.div(100));
           
        }
        
        require(stakingToken.transfer(msg.sender, withdrawAmount), "Not enough tokens in contract!");
        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }
    
    function sendTokens(uint _amount) public onlyOwner {
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
    
    function withdrawTokens(address receiver, uint _amount) public onlyOwner {
        ownerTokensAmount = ownerTokensAmount.sub(_amount);
        require(stakingToken.transfer(receiver, _amount), "Not enough tokens on contract!");
    }
       
}