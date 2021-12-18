/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract LotteryLandStaking is Ownable {
    
    using SafeMath for uint256;
    
    struct StakerInfo {
        uint256 amount;
        uint256 startStakeTime;
        uint256 count;
        uint256[] amounts;
        uint256[] times;
    }
      uint256 public stakingStart;
      uint256 public stakingEnd;
      uint256 public stakingClosed;
    
    uint256 public currentStakers;
    uint256 public minimumStake;
    IERC20 dnxcToken;                    // token being staked
    
    address private _rewardDistributor;
    mapping(address => StakerInfo) public stakerInfo;
    uint256 internal fee;
    bool paused;
    bool emergencyUnstake;
    
    constructor(uint256 _minimumStake, uint256 _stakingStart, uint256 _stakingClosed, uint256 _stakingEnd, IERC20 _dnxcToken) 
     {
        
        minimumStake = _minimumStake;
        stakingStart = _stakingStart;
        stakingClosed = _stakingClosed;
        stakingEnd = _stakingEnd;
        paused = true;
        
        dnxcToken = _dnxcToken;
        _rewardDistributor = address(owner());
    }
    
    function changePause(bool _pause) onlyOwner public {
        paused = _pause;
    }
    
    function changeEmergency(bool _emergencyUnstake) onlyOwner public {
        emergencyUnstake = _emergencyUnstake;
    }
    
    function changeDistributor(address _address) onlyOwner public {
        _rewardDistributor = _address;
    }
    
    function changeEndTime(uint256 endTime) public onlyOwner {
      stakingEnd = endTime;
    }
    function changeCloseTime(uint256 closeTime) public onlyOwner {
      stakingClosed = closeTime;
    }
    function changeStartTime(uint256 startTime) public onlyOwner {
      stakingStart = startTime;
    }
    function changeMinimumStake(uint256 p_stake) public onlyOwner {
      minimumStake = p_stake;
    }
      
    function stake(uint256 _amount) public payable {
        require (paused == false, "E09");
        require (block.timestamp >= stakingStart, "E07");
        require (block.timestamp <= stakingClosed, "E08");
        require (_amount % minimumStake == 0, 'E10');
        
        StakerInfo storage user = stakerInfo[msg.sender];
        require (user.amount.add(_amount) >= minimumStake, "E01");
        require (dnxcToken.transferFrom(msg.sender, address(this), _amount), "E02");
        
        uint256 count = _amount.div(minimumStake);
        
        if (user.amount == 0) {
            user.startStakeTime = block.timestamp;
        }
        
        user.amount = user.amount.add(_amount);
        user.count = user.count.add(count);
        user.amounts.push(user.amount);
        user.times.push(block.timestamp);
    }
    
    function unstake() public {
        
        require (emergencyUnstake || block.timestamp >= stakingEnd || block.timestamp <= stakingClosed, "E08");
        StakerInfo storage user = stakerInfo[msg.sender];
        
        dnxcToken.transfer(
            msg.sender,
            user.amount
        );
        
        currentStakers = currentStakers.sub(user.count);
        user.amount = 0;
        user.count = 0;
    }
    
    function getUsersAmounts(address _user) public view returns (uint256[] memory) {
        StakerInfo storage user = stakerInfo[_user];
        return user.amounts;
    }
    
    
    function getUsersTimes(address _user) public view returns (uint256[] memory) {
        StakerInfo storage user = stakerInfo[_user];
        return user.times;
    }
    
    function getTimestampOfStartedStaking(address _user) public view returns (uint256) {
        StakerInfo storage user = stakerInfo[_user];
        return user.startStakeTime;
    }
    
    function withdrawFees() onlyOwner external {
        require(payable(msg.sender).send(address(this).balance));
    }
    

}