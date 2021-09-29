/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

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

// File: contracts/libs/IBEP20.sol

pragma solidity ^0.6.12;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts/libs/SafeBEP20.sol



pragma solidity ^0.6.12;




/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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

// File: contracts/MasterChef.sol



// pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

contract AmiStaking is Ownable{
    
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    
    IBEP20 public amiToken;
    
    
    
    uint256 public ANNUAL_PLAN_APY = 2400;
    uint256 public HALF_YEAR_PLAN_APY = 1000;
    uint256 public MULTIPLIER = 10000;
    uint256 public firstLevelComission = 1000;
    uint256 public secondLevelComission = 500;

    uint256 private ONE_DAY = 1 days;
    uint256 private ONE_MONTH = ONE_DAY.mul(30);
    uint256 public halfYearDuration = uint256(6).mul(ONE_MONTH);
    uint256 public annualDuration = uint256(12).mul(ONE_MONTH);
    uint256 public totalDistributedInAnnual;
    uint256 public totalDistributedInHalfYear;

    
    uint256 public maxReward =  40000000*1e18;
    uint256 public rewardPaid;

	struct Deposit {
        bool isHalfYearly;
		uint256 amount;
		bool isFinshed;
		uint256 dividentWithdrawn;
		uint256 startDate;
	}

  
  
  	struct User {
		Deposit[] deposits;
		address firstLevelReferrer;
		address secondLevelReferrer;
		uint256 checkpoint;
	}


    event SetReferral(address user,address referrer,uint256 investmentAmount);
    event RefComissionPaid(address user,address paidTo,uint256 amount,bool isFirstLevelComission);
    event RewardPaid(address user,uint256 pendingReward,bool isAnnual);
    event Withdraw(address user,uint256 depositId,uint256 amount);

  	mapping (address => User) public users;

 
    mapping (address => uint256) public refEarnings;

  
    address public companyWallet;
        

    
    constructor(address _companyWallet,IBEP20 _amiToken) public {
        companyWallet = _companyWallet;
        amiToken = _amiToken;
    }
    
    
    function setCompanyWallet(address wallet) public onlyOwner{
        companyWallet = wallet;
    }
     
  
    function setMaxReward(uint256 amount) public onlyOwner{
        maxReward = amount;
    }
  
    function getDepositLength(address user) public view returns(uint256){
          return users[user].deposits.length;
    }
  
  function getDeposit(address user,uint256 index) public view returns( 
        bool isHalfYearly,
		uint256 amount,
		bool isFinshed,
		uint256 dividentWithdrawn,
		uint256 startDate){
		    
    Deposit storage deposit =  users[user].deposits[index];
    return(
          deposit.isHalfYearly,
          deposit.amount,
          deposit.isFinshed,
          deposit.dividentWithdrawn,
          deposit.startDate
    );
  }
    
    
    function withdraw() public{
        User storage user = users[msg.sender];
        uint256 withdrawAmount = 0;
        
        
        _claimReward(true,msg.sender);
        _claimReward(false,msg.sender);

        for(uint256 i = 0;i<user.deposits.length;i++){
            
           if(!user.deposits[i].isFinshed){
                if(user.deposits[i].isHalfYearly){
                    if(user.deposits[i].startDate.add(halfYearDuration) < block.timestamp){
                        withdrawAmount = withdrawAmount.add(user.deposits[i].amount);
                        user.deposits[i].isFinshed = true;
                        emit Withdraw(msg.sender,i ,user.deposits[i].amount);
                    }
                }else{
                       if(user.deposits[i].startDate.add(annualDuration) < block.timestamp){
                           
                            withdrawAmount = withdrawAmount.add(user.deposits[i].amount);
                            user.deposits[i].isFinshed = true;
                            emit Withdraw(msg.sender,i ,user.deposits[i].amount);
                    }
                }
           }

         
        }
        
       if(withdrawAmount>0){
            transferTokens(msg.sender,withdrawAmount);
            users[msg.sender].checkpoint = block.timestamp;
        }
        
        
        
        
        
        
    }
    
    
    
    
     
    
    function preInvest(address _user,
                        uint256 amount, bool isHalfYearly,
                        address refAddress,uint256 checkpoint) public onlyOwner{
        
        User storage user  = users[_user];
        setReferral(user,refAddress,amount);
        Deposit memory deposit =   Deposit(isHalfYearly, amount,false, 0, checkpoint);
        uint256 dividentWithdrawn = getPendingRewardByDeposit(deposit);
        deposit.dividentWithdrawn = dividentWithdrawn;
		user.deposits.push(deposit);
		
        user.checkpoint = checkpoint;
        

    }
    

    
    
    
    
    
    function invest(uint256 amount, bool isHalfYearly,address refAddress) public{
        amiToken.safeTransferFrom(msg.sender,address(this),amount);
        User storage user  = users[msg.sender];
        setReferral(user,refAddress,amount);
		user.deposits.push(Deposit(isHalfYearly, amount,false, 0, block.timestamp));
        payReferralCommission(msg.sender,user,amount);
        user.checkpoint = block.timestamp;
    }
    
    function claimReward(bool isAnnual) public{
         _claimReward(isAnnual,msg.sender);
    }
    
    
    
    function _claimReward(bool isAnnual ,address _user) internal {
        User storage user = users[_user];
        uint256 pendingAmount = 0;
        for(uint256 i = 0;i<user.deposits.length;i++){
            
            if(!user.deposits[i].isFinshed){
                  uint256 _amount = getPendingRewardByDeposit(user.deposits[i]);
                  if(isAnnual){
                        if(!user.deposits[i].isHalfYearly){
                            pendingAmount = pendingAmount.add(_amount);
                            user.deposits[i].dividentWithdrawn = user.deposits[i].dividentWithdrawn.add(_amount);
                            totalDistributedInAnnual = totalDistributedInAnnual.add(_amount);
                        }
                        
                        
                  }else{
                        if(user.deposits[i].isHalfYearly){
                            pendingAmount = pendingAmount.add(_amount);
                            user.deposits[i].dividentWithdrawn = user.deposits[i].dividentWithdrawn.add(_amount);
                            totalDistributedInHalfYear = totalDistributedInHalfYear.add(_amount);

                        }
                  }
            }
        
        }
        
        if(pendingAmount>0){
            require(rewardPaid.add(pendingAmount) < maxReward, "max reward reached");
            transferTokens(msg.sender,pendingAmount);
            emit RewardPaid(msg.sender,pendingAmount,isAnnual);
            
            users[msg.sender].checkpoint = block.timestamp;
            rewardPaid = rewardPaid.add(pendingAmount);
        }
   
    }
    
    function getPendingReward(address addr) public view returns(uint256,uint256){
        User memory user = users[addr];
        uint256 annualPlan = 0;
        uint256 halfYearPlan = 0;

        for(uint256 i = 0;i<user.deposits.length;i++){
            
            if(!user.deposits[i].isFinshed){
                if(user.deposits[i].isHalfYearly){
                    halfYearPlan = halfYearPlan.add(getPendingRewardByDeposit(user.deposits[i]));
                }else{
                    annualPlan = annualPlan.add(getPendingRewardByDeposit(user.deposits[i]));
                }
            }
            

        
        }
        
        return (halfYearPlan,annualPlan);
    }
    
    
    
    
    
    function getPendingRewardByDeposit(Deposit memory deposit) public view returns (uint256){
        uint256 rate= deposit.isHalfYearly?HALF_YEAR_PLAN_APY: ANNUAL_PLAN_APY;
        uint256 duration = deposit.isHalfYearly?halfYearDuration:annualDuration;
        uint256 originalReward  = deposit.amount.mul(rate).div(MULTIPLIER);
        uint256 timeSpent = block.timestamp.sub(deposit.startDate);
        if(timeSpent > duration){
            timeSpent = duration;
        }
        originalReward = originalReward.mul(timeSpent).div(duration);
        return originalReward.sub(deposit.dividentWithdrawn);
    }
    
    
    function getReferral(address user) public view returns (address){
        return users[user].firstLevelReferrer;
    }
    
    
    function payReferralCommission(address userAdd,User memory user,uint256 amount) internal{
        uint256 firstLComissionAmount = amount.mul(firstLevelComission).div(MULTIPLIER);
        uint256 secondLComissionAmount = amount.mul(secondLevelComission).div(MULTIPLIER);
        transferTokens(user.firstLevelReferrer,firstLComissionAmount);
        refEarnings[user.firstLevelReferrer] =refEarnings[user.firstLevelReferrer].add(firstLComissionAmount);
        refEarnings[user.secondLevelReferrer] =refEarnings[user.firstLevelReferrer].add(secondLComissionAmount);

        transferTokens(user.secondLevelReferrer,secondLComissionAmount);
        emit RefComissionPaid(userAdd,user.firstLevelReferrer,firstLComissionAmount,true);
        emit RefComissionPaid(userAdd,user.secondLevelReferrer,secondLComissionAmount,false);


    }

    function setReferral(User storage user,address refferal,uint256 amount) internal{
        address preRef = user.firstLevelReferrer;
        if(preRef == address(0)){
            if(refferal == address(0) || refferal == msg.sender){
                refferal = companyWallet;
            }
            user.firstLevelReferrer = refferal;
            emit SetReferral(msg.sender,refferal,amount);
            address secondLevel = getReferral(refferal);
            if(secondLevel == address(0)){
                secondLevel = companyWallet;
            }
            user.secondLevelReferrer = secondLevel;
        }
        
        
    }
    
    
    
    function transferTokens(address _user,uint256 amount) internal{
        uint256 balance = amiToken.balanceOf(address(this));
        if(balance < amount){
            amiToken.transfer(_user,balance);

        }else{
            amiToken.transfer(_user,amount);
        }
    }
    
    
    function safeGetAllTokens(address tokenAddress )public onlyOwner{
        uint256 bal = IBEP20(tokenAddress).balanceOf(address(this));
        IBEP20(tokenAddress).transfer(msg.sender,bal);
    }
    
}