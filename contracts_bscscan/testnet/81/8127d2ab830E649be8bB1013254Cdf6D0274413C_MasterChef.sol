// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MasterChef is ContextUpgradeable,OwnableUpgradeable{
    using SafeMathUpgradeable for uint256;
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
        IERC20Upgradeable lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BLACKs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BLACKs distribution occurs.
        uint256 accBlackPerShare; // Accumulated BLACKs per share, times 1e18. See below.
    }

    // The BLACK TOKEN!
    IERC20Upgradeable public black;
   
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
    uint256 public  maxStakeAmount;
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

    uint256  private  decimalMultiplier; 
    
    // latest Staking time +  withdrawLockPeriod,  to find when can I unstake
    mapping(address => uint256) public holderUnstakeRemainingTime;
    
    // once staking amount reaches maxStakeAmount, then it stores (current block time + stakingLockPeriod)
    mapping (address => uint256) private holderNextStakingAllowedTime;
    
    // Holds the running staking balance for each holder for staking lock, here balance of a user can reach to 
    // a maximum of maxStakeAmount
    mapping(address => uint256) private holdersRunningStakeBalance;

     bool private  feesAppliableStaking;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user,  uint256 amount);
    
    function initialize ()  public initializer{
        OwnableUpgradeable.__Ownable_init();
        startBlock = block.number;
        startTime = block.timestamp;
        //TODO change rewardStartdate
        rewardStartDate = block.timestamp + 2 minutes;
        poolInfo.allocPoint=1000;
        poolInfo.lastRewardBlock= startBlock;
        poolInfo.accBlackPerShare= 0;
        totalAllocPoint = 1000;    
        minRewardBalanceToClaim = 100 * decimalMultiplier ;
        maxStakeAmount = 1000000 * decimalMultiplier;   
        decimalMultiplier = 1e18;
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
                accBlackPerShare = accBlackPerShare.add(blackReward.mul(decimalMultiplier).div(totalStakedTokens));
            }
            return user.amount.mul(accBlackPerShare).div(decimalMultiplier).sub(user.rewardDebt);
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
        pool.accBlackPerShare = pool.accBlackPerShare.add(blackReward.mul(decimalMultiplier).div(lpSupply));
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
		uint256 stakedAmount = _amount; 
        if(feesAppliableStaking)
          stakedAmount = _amount * 90 / 100;
        user.amount = user.amount.add(stakedAmount);
        holderUnstakeRemainingTime[msg.sender]= block.timestamp + withdrawLockPeriod;
        bool flag = pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        require(flag, "Deposit unsuccessful, hence aborting the transaction !");
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier);
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
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier);
        uint256 pending = currentUserBalance.mul(pool.accBlackPerShare).div(decimalMultiplier).sub(CurrentRewardBalance);
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
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier);
        uint256 pending = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier).sub(CurrentRewardBalance);
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
    // type of toke that will be accepted for staking
    function setStakingTokenAddress(address  _token) public onlyOwner{       
        poolInfo.lpToken=IERC20Upgradeable(_token);
    }
	// this is token is the reward token
    function setBlackAddress(address  _black) public onlyOwner{
        black = IERC20Upgradeable( _black);
    }

    function setCommunityWallet(address  _communitywallet) public onlyOwner{
        communitywallet = _communitywallet;    
    }
    function setFeesAppliableStaking(bool  _feesAppliableStaking) public onlyOwner{
        feesAppliableStaking = _feesAppliableStaking;
        if(_feesAppliableStaking){
             decimalMultiplier = 1e9; 
             minRewardBalanceToClaim = 100 * decimalMultiplier ;
             maxStakeAmount = 1000000 * decimalMultiplier;
        }
                   
    }
 
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

