/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
   

    function _msgData() internal view virtual returns (bytes memory) {
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize () public virtual {
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
}

contract Initializable  {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


contract MasterChef is Context,Ownable,Initializable {
    using SafeMath for uint256;
 

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BLACKs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBlackPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBlackPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BLACKs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BLACKs distribution occurs.
        uint256 accBlackPerShare; // Accumulated BLACKs per share, times 1e9. See below.
    }

    // The BLACK TOKEN!
    IBEP20 public black;
   
    // Dev address.
    address public communitywallet;
    // BLACK tokens created per block.
    uint256 public blackPerBlock;
    // Bonus muliplier for early black makers.
    uint256 public BONUS_MULTIPLIER;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping  (address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BLACK mining starts.
    uint256 public startBlock;
    //Todo maxlimit may be change
    uint256 public constant  maxStakeAmount = 1000000 * 10**9;
    //Todo lockperiod may be change 
    // Once holder stakes maxStakeAmount, then he will not be able to stake any more coins for this time period
    uint256 public constant stakingLockPeriod = 2 weeks;
    //Todo withdrawLockupPeriod may be change 
    // Once holder stakes coins, he can unstake only after below time period
    uint256 public constant withdrawLockPeriod = 1 days;
    //Contract deployment time
    uint256 public startTime;
    //Date on which stakers start getting rewards 
    uint256 public rewardStartDate;
    //Todo maxrewardlimit fixed
    uint256 public minRewardBalanceToClaim;
    
    // latest Staking time +  withdrawLockPeriod,  to find when can I unstake
    mapping(address => uint256) public holderUnstakeRemainingTime;
    
    // once staking amount reaches maxStakeAmount, then it stores (current block time + stakingLockPeriod)
    mapping (address => uint256) private holderNextStakingAllowedTime;
    
    // Holds the running staking balance for each holder for staking lock, here balance of a user can reach to 
    // a maximum of maxStakeAmount
    mapping(address => uint256) private holdersRunningStakeBalance;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user,  uint256 amount);
    
    function initialize ()  public override  initializer{
        Ownable.initialize();
        startBlock = block.number;
        startTime = block.timestamp;
        //TODO change rewardStartdate
        rewardStartDate = block.timestamp + 2 minutes;
        poolInfo.allocPoint=1000;
        poolInfo.lastRewardBlock= startBlock;
        poolInfo.accBlackPerShare= 0;
        totalAllocPoint = 1000;
        minRewardBalanceToClaim = 100 * 10**9 ;
        BONUS_MULTIPLIER = 1;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }
   
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
        //TODO change 1 days to double rewards period
        if((holderUnstakeRemainingTime[msg.sender] - withdrawLockPeriod) >= (startTime + 1 days) ){
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        }
        else{
            return _to.sub(_from).mul(BONUS_MULTIPLIER * 2);
        }
    }

    // View function to see pending BLACKs on frontend.
    function pendingBlack(address _user) external view returns (uint256) {
        if(rewardStartDate <= block.timestamp ){
            PoolInfo storage pool = poolInfo;
            UserInfo storage user = userInfo[_user];
            uint256 accBlackPerShare = pool.accBlackPerShare;
            uint256 totalStakedTokens = pool.lpToken.balanceOf(address(this));
            if (block.number > pool.lastRewardBlock && totalStakedTokens != 0) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 blackReward = multiplier.mul(blackPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                accBlackPerShare = accBlackPerShare.add(blackReward.mul(1e9).div(totalStakedTokens));
            }
            return user.amount.mul(accBlackPerShare).div(1e9).sub(user.rewardDebt);
        }
        else
            return 0;
        
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 blackReward = multiplier.mul(blackPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accBlackPerShare = pool.accBlackPerShare.add(blackReward.mul(1e9).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BLACK allocation
    function deposit(uint256 _amount) public {
        require(!lock(msg.sender),"Sender is in locking state !");
        require(_amount > 0, "Deposit amount cannot be less than zero !");
	    checkStakeLimit(_amount);
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 stakedAmount =(_amount * 90)/100;
        user.amount = user.amount.add(stakedAmount);
        holderUnstakeRemainingTime[msg.sender]= block.timestamp + withdrawLockPeriod;
        bool flag = pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        require(flag, "Deposit unsuccessful, hence aborting the transaction !");
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(1e9);
        emit Deposit(msg.sender, stakedAmount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) public {
        require(rewardStartDate <= block.timestamp,"Rewards allocation period yet to start !" );
        require (holderUnstakeRemainingTime[msg.sender] <= block.timestamp, "Holder is in locked state !");
        require(_amount > 0, "withdraw amount cannot be less than zero !");
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Insufficient balance !");
        updatePool();
        uint256  currentUserBalance=user.amount;
        uint256 CurrentRewardBalance= user.rewardDebt;
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(1e9);
        uint256 pending = currentUserBalance.mul(pool.accBlackPerShare).div(1e9).sub(CurrentRewardBalance);
        if(pending > 0) {
            bool flag = black.transferFrom(communitywallet,msg.sender, pending);
            require(flag, "Withdraw unsuccessful, during reward transfer, hence aborting the transaction !");
        }
        bool flag =  pool.lpToken.transfer(msg.sender, _amount);
        require(flag, "Withdraw unsuccessful, during staking amount transfer, hence aborting the transaction !");
        emit Withdraw(msg.sender, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
		uint256 currentBalance = user.amount;
		require(currentBalance > 0,"Insufficient balance !");
		user.amount = 0;
        user.rewardDebt = 0;
        bool flag = pool.lpToken.transfer(address(msg.sender), currentBalance);
		require(flag, "Transfer unsuccessful !");
        emit EmergencyWithdraw(msg.sender, user.amount);
        
    }

   //---------------------locking-------------------------//
    //checks the account is locked(true) or unlocked(false)
    function lock(address account) public view returns(bool){
        return holderNextStakingAllowedTime[account] > block.timestamp;
    }
	
	 // if sender is in frozen state,then this function returns epoch value remaining for the address for it to get unfrozen.
    function secondsLeft(address account) public view returns(uint256){
        if(lock(account)){
            return  ( holderNextStakingAllowedTime[account] - block.timestamp );
        }
         else
            return 0;
    }
 
    function checkStakeLimit(uint256 _stakeAmount) internal{	  
        require(_stakeAmount <= maxStakeAmount,"Cannot stake  more than permissible limit");
        uint256 balance =  holdersRunningStakeBalance[msg.sender]  + _stakeAmount;
        if(balance == maxStakeAmount) {
            holdersRunningStakeBalance[msg.sender] = 0;        
		    holderNextStakingAllowedTime[msg.sender] = block.timestamp + stakingLockPeriod;        
        }
        else{
            require(balance < maxStakeAmount,"cannot stake more than permissible limit");
            holdersRunningStakeBalance[msg.sender] = balance;       
        }
    }
    
    //----------------------endlocking-----//
   //------------------claim reward----------------------------//
   
   function claimReward() external {
        require(rewardStartDate <= block.timestamp,"Rewards not yet Started !" );
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 CurrentRewardBalance= user.rewardDebt;
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(1e9);
        uint256 pending = user.amount.mul(pool.accBlackPerShare).div(1e9).sub(CurrentRewardBalance);
        require(pending >= minRewardBalanceToClaim,"reward Limit for claiming not reached"); 
        bool flag = black.transferFrom(communitywallet,msg.sender, pending);
        require(flag, "Claim reward unsuccessful, hence aborting the transaction !");
        emit Withdraw(msg.sender,pending);
   }
   
   
   //----------------reward end------------------------------------------------//

  //----------setter---------------------------------------------//

    function setBlackPerBlock(uint256 _blackPerBlock) public onlyOwner {
        blackPerBlock = _blackPerBlock;
    }
    
     function setTotalAllocationPoint(uint256 _totalAllocPoint) public onlyOwner {
        totalAllocPoint = _totalAllocPoint;
    }
    
     function setAllocationPoint(uint256 _allocPoint) public onlyOwner {
        poolInfo.allocPoint = _allocPoint;
    }
    
    function setRewardStartDate(uint256 _rewardStartdate) public onlyOwner {
       rewardStartDate = _rewardStartdate;
    }
    
    function setRewardAmount(uint256 _minRewardBalanceToClaim) public onlyOwner {
       minRewardBalanceToClaim = _minRewardBalanceToClaim;
    }
    
    function unLockWeeklyLock(address account) public onlyOwner{
        holderNextStakingAllowedTime[account] = block.timestamp;
    }
    
    function unLockStakeHolder(address account) public onlyOwner{
        holderUnstakeRemainingTime[account] = block.timestamp;
    }
    
    function setblackaddress(address  _black) public onlyOwner{
        black = IBEP20( _black);
        poolInfo.lpToken= black;
    }
    function setCommunityWallet(address _communitywallet) public onlyOwner{
        communitywallet = _communitywallet;
    }
}