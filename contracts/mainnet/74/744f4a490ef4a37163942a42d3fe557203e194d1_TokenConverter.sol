/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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

// File: contracts\modules\Managerable.sol

pragma solidity =0.5.16;

contract Managerable is Ownable {

    address private _managerAddress;
    /**
     * @dev modifier, Only manager can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyManager() {
        require(_managerAddress == msg.sender,"Managerable: caller is not the Manager");
        _;
    }
    /**
     * @dev set manager by owner. 
     *
     */
    function setManager(address managerAddress)
    public
    onlyOwner
    {
        _managerAddress = managerAddress;
    }
    /**
     * @dev get manager address. 
     *
     */
    function getManager()public view returns (address) {
        return _managerAddress;
    }
}

// File: contracts\modules\Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts\TokenConverter\TokenConverterData.sol

pragma solidity =0.5.16;



contract TokenConverterData is Managerable,Halt {
    //the locjed reward info
    struct lockedReward {
        uint256 startTime; //this tx startTime for locking
        uint256 total;     //record input amount in each lock tx    
        mapping (uint256 => uint256) alloc;//the allocation table
    }
    
    struct lockedIdx {
        uint256 beginIdx;//the first index for user converting input claimable tx index 
        uint256 totalIdx;//the total number for converting tx
    }
    
    address public cfnxAddress; //cfnx token address
    address public fnxAddress;  //fnx token address
    uint256 public timeSpan = 30*24*3600;//time interval span time ,default one month
    uint256 public dispatchTimes = 6;    //allocation times,default 6 times
    uint256 public txNum = 100; //100 times transfer tx 
    uint256 public lockPeriod = dispatchTimes*timeSpan;
    
    //the user's locked total balance
    mapping (address => uint256) public lockedBalances;//locked balance for each user
    
    mapping (address =>  mapping (uint256 => lockedReward)) public lockedAllRewards;//converting tx record for each user
    
    mapping (address => lockedIdx) public lockedIndexs;//the converting tx index info
    
    
    /**
     * @dev Emitted when `owner` locked  `amount` FPT, which net worth is  `worth` in USD. 
     */
    event InputCfnx(address indexed owner, uint256 indexed amount,uint256 indexed worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` FPT, which net worth is  `worth` in USD.
     */
    event ClaimFnx(address indexed owner, uint256 indexed amount,uint256 indexed worth);

}

// File: contracts\modules\SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts\TokenConverter\TokenConverter.sol

pragma solidity =0.5.16;





/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract TokenConverter is TokenConverterData {
    using SafeMath for uint256;
    modifier inited (){
    	  require(cfnxAddress!=address(0));
    	  require(fnxAddress!=address(0));
    	  _;
    } 

    function initialize() onlyOwner public {
        
    }
    
    function update() onlyOwner public{
    }
    
    /**
     * @dev constructor function. set FNX minePool contract address. 
     */ 
    function setParameter(address _cfnxAddress,address _fnxAddress,uint256 _timeSpan,uint256 _dispatchTimes,uint256 _txNum) onlyOwner public{
        if (_cfnxAddress != address(0))
            cfnxAddress = _cfnxAddress;
            
        if (_fnxAddress != address(0))
            fnxAddress = _fnxAddress;
            
        if (_timeSpan != 0) 
            timeSpan = _timeSpan;
            
        if (_dispatchTimes != 0) 
            dispatchTimes = _dispatchTimes;
        
        if (_txNum != 0) 
            txNum = _txNum;   
        
    }
    
    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftFnx(address reciever)  public onlyOwner {
        uint256 bal =  IERC20(fnxAddress).balanceOf(address(this));
        IERC20(fnxAddress).transfer(reciever,bal);
    }  

    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }


    /**
     * @dev user input cnfx to get fnx
     * @param amount fnx amount
     */ 
    function inputCfnxForInstallmentPay(uint256 amount) external inited {
        require(amount>0,"amount should be bigger than 0");
        
        IERC20(cfnxAddress).transferFrom(msg.sender,address(this),amount);
        uint256 idx = lockedIndexs[msg.sender].totalIdx;
        uint256 divAmount = amount.div(dispatchTimes);

        lockedAllRewards[msg.sender][idx] = lockedReward(now,amount);
        
        //index 0 to save the left token num
        lockedAllRewards[msg.sender][idx].alloc[0] = amount.sub(divAmount);
        uint256 i=2;
        //idx = 1, the reward give user immediately
        for(;i<dispatchTimes;i++){
            lockedAllRewards[msg.sender][idx].alloc[i] = divAmount;
        }
        lockedAllRewards[msg.sender][idx].alloc[i] = amount.sub(divAmount.mul(dispatchTimes-1));
        
        
        lockedBalances[msg.sender] = lockedBalances[msg.sender].add(amount.sub(divAmount));
        
        //should can not be overflow
        lockedIndexs[msg.sender].totalIdx =  lockedIndexs[msg.sender].totalIdx + 1;
        
        IERC20(fnxAddress).transfer(msg.sender,divAmount);

        emit InputCfnx(msg.sender,amount,divAmount);
    }
    
      /**
     * @dev user user claim expired reward
     */ 
    function claimFnxExpiredReward() external inited {
        require(fnxAddress!=address(0),"fnx token should be set");
        
        uint256 txcnt = 0;
        uint256 i = lockedIndexs[msg.sender].beginIdx;
        uint256 endIdx = lockedIndexs[msg.sender].totalIdx;
        uint256 totalRet = 0;
        
        for(;i<endIdx && txcnt<txNum;i++) {
           //only count the rewards over at least one timeSpan
           if (now >= lockedAllRewards[msg.sender][i].startTime + timeSpan) {
               
               if (lockedAllRewards[msg.sender][i].alloc[0] > 0) {
                    if (now >= lockedAllRewards[msg.sender][i].startTime + lockPeriod) {
                        totalRet = totalRet.add(lockedAllRewards[msg.sender][i].alloc[0]);
                        lockedAllRewards[msg.sender][i].alloc[0] = 0;
                        
                        //updated last expired idx
                        lockedIndexs[msg.sender].beginIdx = i;
                    } else {
                      
                        uint256 timeIdx = (now - lockedAllRewards[msg.sender][i].startTime).div(timeSpan) + 1;
                        uint256 j = 2;
                        uint256 subtotal = 0;
                        for(;j<timeIdx+1;j++) {
                            subtotal = subtotal.add(lockedAllRewards[msg.sender][i].alloc[j]);
                            lockedAllRewards[msg.sender][i].alloc[j] = 0;
                        }
                        
                        //updated left locked balance,possible?
                        if(subtotal<=lockedAllRewards[msg.sender][i].alloc[0]){
                            lockedAllRewards[msg.sender][i].alloc[0] = lockedAllRewards[msg.sender][i].alloc[0].sub(subtotal);
                        } else {
                            subtotal = lockedAllRewards[msg.sender][i].alloc[0];
                            lockedAllRewards[msg.sender][i].alloc[0] = 0;
                        }
                        
                        totalRet = totalRet.add(subtotal);
                    }
                    
                    txcnt = txcnt + 1;
               }
                
           } else {
               //the item after this one is pushed behind this,not needed to caculate
               break;
           }
        }
        
        lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(totalRet);
        //transfer back to user
        IERC20(fnxAddress).transfer(msg.sender,totalRet);
        
        emit ClaimFnx(msg.sender,totalRet,txcnt);
    }
    
      /**
     * @dev get user claimable balance
     * @param _user the user address
     */ 
    function getClaimAbleBalance(address _user) public view returns (uint256) {
        require(fnxAddress!=address(0),"fnx token should be set");
        
        uint256 txcnt = 0;
        uint256 i = lockedIndexs[_user].beginIdx;
        uint256 endIdx = lockedIndexs[_user].totalIdx;
        uint256 totalRet = 0;
        
        for(;i<endIdx && txcnt<txNum;i++) {
           //only count the rewards over at least one timeSpan
           if (now >= lockedAllRewards[_user][i].startTime + timeSpan) {
               
               if (lockedAllRewards[_user][i].alloc[0] > 0) {
                    if (now >= lockedAllRewards[_user][i].startTime + lockPeriod) {
                        totalRet = totalRet.add(lockedAllRewards[_user][i].alloc[0]);
                    } else {
                        uint256 timeIdx = (now - lockedAllRewards[_user][i].startTime).div(timeSpan) + 1;
                        uint256 j = 2;
                        uint256 subtotal = 0;
                        for(;j<timeIdx+1;j++) {
                            subtotal = subtotal.add(lockedAllRewards[_user][i].alloc[j]);
                        }
                        
                        //updated left locked balance,possible?
                        if(subtotal>lockedAllRewards[_user][i].alloc[0]){
                            subtotal = lockedAllRewards[_user][i].alloc[0];
                        }
                        
                        totalRet = totalRet.add(subtotal);
                    }
                    
                    txcnt = txcnt + 1;
               }
                
           } else {
               //the item after this one is pushed behind this,not needed to caculate
               break;
           }
        }
        
        return totalRet;
    }
    
  
    
}