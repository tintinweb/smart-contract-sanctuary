/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// SPDX-License-Identifier: --🦉--

//File Context.sol
pragma solidity =0.8.0;

contract Context {

    /**
     * @dev returns address executing the method
     */
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /**
     * @dev returns data passed into the method
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//File SafeMath.sol

pragma solidity =0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


//File Events.sol
pragma solidity =0.8.0;

contract Events {

    event Reward(
        address indexed to,
        uint256 value
    );

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdded(uint256 pid, uint256 publishDate);
}

//File IERC20.sol
pragma solidity =0.8.0;

interface IERC20 {
    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//File Ownable.sol
pragma solidity =0.8.0;
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
  address internal _owner;

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

//File GameReward.sol
pragma solidity =0.8.0;

contract QuizStake is Ownable, Events {
    using SafeMath for uint256;
    
    address public qdropToken;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 poolStatus;
        uint256 userNumber;
        uint256 depositedAmount;
        uint256 assignedReward;
        uint256 rewardsAmount;
        uint256 poolTimestamp;
        uint256 startDate;
        uint256 publishDate;
    }
    
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    constructor (address _qdropToken) {
        qdropToken = _qdropToken;
    }
    
    
    /**
     * @notice modifier to check if pid is valid
     *
     * @param _pid: pool Id
     */
    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    /**
     * @notice function to add pool for new Quiz
     *
     * @param _startDate: Timestamp of Quiz start date
     * @param _publishDate: Timestamp of Quiz publish date
     */
    function addPool(uint256 _startDate, uint256 _publishDate) external onlyOwner returns (uint256){
        uint256 pid = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                poolStatus: 1, //1: new Quiz was published, 2: new Quiz finished
                userNumber: 0,
                depositedAmount: 0,
                assignedReward: 0,
                rewardsAmount: 0,
                poolTimestamp: block.timestamp,
                startDate: _startDate,
                publishDate: _publishDate
            })
        );
        emit PoolAdded(pid, _publishDate);
        
        return (poolInfo.length-1);
    }
    
    /**
     * @notice publish a pool by the owner(change the )
     *
     * @param pid: ID of pool
     */
    function publishPool(uint256 pid) external onlyOwner {
       PoolInfo storage pool = poolInfo[pid];
       require(block.timestamp > pool.publishDate, "The publish date has not expired yet");
       require(pool.poolStatus == 1, "The pool has already published");
       
       pool.rewardsAmount = pool.depositedAmount; 
       pool.assignedReward = pool.depositedAmount; 
       pool.poolStatus = 2;
    }
    
    /**
     * @notice add the reward to the selected user by the owner
     *
     * @param _to: address of the user
     * @param amount: amount of reward
     */
    function addReward(uint256 pid, address _to, uint256 amount) public onlyOwner {
        require(poolInfo[pid].poolStatus == 2, "The Quiz has not published yet");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_to];
        
        require(amount <= pool.assignedReward, "The pool does not have the fund to assign the reward.");
        pool.assignedReward = pool.assignedReward - amount;
        user.rewardDebt = amount;

        emit Reward(_to,    amount);
    }
    
    /**
     * @notice withdraw the token from a certain pool by the owner
     *
     * @param amount: amount of token
     */
    function withdrawToken(uint256 amount) external onlyOwner {
       IERC20(qdropToken).transfer(msg.sender, amount);
    }
    
    /**
     * @notice deposit token to a certain pool
     *
     * @param pid: Pool Id
     * @param amount: Amount of token to deposit
     */
    function deposit(uint256 pid, uint256 amount) external validatePoolByPid(pid) {
        require(poolInfo[pid].poolStatus == 1, "The Quiz had already finished");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount == 0, "The user had already deposited");
        if (amount > 0) {
            IERC20(qdropToken).approve(address(msg.sender), amount);
            IERC20(qdropToken).transferFrom(address(msg.sender), address(this), amount);
            pool.depositedAmount = pool.depositedAmount + (amount);
            pool.userNumber = pool.userNumber + 1;
            user.amount = amount;
        }
        emit Deposit(msg.sender, pid, amount);
    }

    /**
     * @notice claim rewards from a certain pool
     *
     * @param pid: Pool Id
     */
    function claim(uint256 pid) external validatePoolByPid(pid) {
        require(poolInfo[pid].poolStatus == 2, "The Quiz has not published yet");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.rewardDebt > 0, "The user does not have the reward");
        if (user.rewardDebt > 0) {
            IERC20(qdropToken).transfer(msg.sender, user.rewardDebt);
            emit Claim(msg.sender, pid, user.rewardDebt);
            user.rewardDebt = 0;
            pool.rewardsAmount = pool.rewardsAmount - (user.rewardDebt);
        }
    }

    /**
     * @notice get the number of pool in this contract
     *
     */
    function getPoolNumber() public view returns(uint256) {
        return poolInfo.length;
    }
    
     /**
     * @notice get total balance
     */
    function getBalance() public view returns(uint256) {
        uint256 balance = IERC20(qdropToken).balanceOf(address(this));
        return balance;
    }
    
    /**
     * @notice get the parameters(status, depositedAmount) of a certain pool
     *
     * @param pid: Pool Id
     */
    function getPoolStatus(uint256 pid) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        PoolInfo storage pool = poolInfo[pid];
        return (pool.poolStatus, pool.userNumber, pool.depositedAmount, pool.assignedReward, pool.rewardsAmount, pool.poolTimestamp, pool.startDate, pool.publishDate);
    }
    
    /**
     * @notice get the status(depositedAmount, rewardDebt) of a user in a certain pool
     *
     * @param pid: Pool Id
     * @param _user: user address
     */
    function getUserStatus(uint256 pid, address _user) public view returns(uint256, uint256) {
        UserInfo storage user = userInfo[pid][_user];
        return (user.amount, user.rewardDebt);
    }


}