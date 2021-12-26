/**
 *Submitted for verification at snowtrace.io on 2021-12-26
*/

// File: contracts/modules/Ownable.sol

pragma solidity ^0.5.16;

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

// File: contracts/modules/Halt.sol

pragma solidity ^0.5.16;


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

// File: contracts/farmRelease/tokenReleaseData.sol

pragma solidity ^0.5.16;


contract tokenReleaseData is Halt {
    uint256 constant internal currentVersion = 2;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
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

    address public meltAddress;  //token address
    uint256 public idxperiod = 24*3600;
    uint256 public timeSpan = 30*24*3600;//time interval span time ,default one month
    uint256 public dispatchTimes = 6;    //allocation times,default 6 times
    uint256 public txNum = 100; //100 times transfer tx 
    uint256 public lockPeriod = dispatchTimes*timeSpan;
    
    //the user's locked total balance
    mapping (address => uint256) public lockedBalances;//locked balance for each user
    
    mapping (address =>  mapping (uint256 => lockedReward)) public lockedAllRewards;//converting tx record for each user
    
    mapping (address => lockedIdx) public lockedIndexs;//the converting tx index info

    mapping (address => uint256[]) public userTxIdxs;//address idx number

    mapping (address => uint256) public userFarmClaimedBalances;//locked balance for each user

    event Input(address indexed sender,address indexed reciever, uint256 indexed amount,uint256 divAmount);

    event Claim(address indexed sender,uint256 indexed amount,uint256 indexed txcnt);

}

// File: contracts/modules/SafeMath.sol

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

// File: contracts/modules/IERC20.sol

pragma solidity ^0.5.16;
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

// File: contracts/modules/multiSignatureClient.sol

pragma solidity ^0.5.16;
interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    bytes32 private constant multiSignaturePositon = keccak256("org.Defrost.multiSignature.storage");
    constructor(address multiSignature) public {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(msgHash);
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > 0, "multiSignatureClient : This tx is not aprroved");
        saveValue(msgHash,newIndex);
    }
    function saveValue(bytes32 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(bytes32 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// File: contracts/modules/proxyOwner.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.16;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant proxyOwnerPosition  = keccak256("org.defrost.Owner.storage");
    bytes32 private constant proxyOriginPosition0  = keccak256("org.defrost.Origin.storage.0");
    bytes32 private constant proxyOriginPosition1  = keccak256("org.defrost.Origin.storage.1");
    uint256 private constant oncePosition  = uint256(keccak256("org.defrost.Once.storage"));
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature,address origin0,address origin1) multiSignatureClient(multiSignature) public {
        _setProxyOwner(msg.sender);
        _setProxyOrigin(address(0),origin0);
        _setProxyOrigin(address(0),origin1);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) public onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _oldOrigin,address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_oldOrigin,_newOrigin);
    }
    function _setProxyOrigin(address _oldOrigin,address _newOrigin) internal 
    {
        emit OriginTransferred(_oldOrigin,_newOrigin);
        (address _origin0,address _origin1) = txOrigin();
        if (_origin0 == _oldOrigin){
            bytes32 position = proxyOriginPosition0;
            assembly {
                sstore(position, _newOrigin)
            }
        }else if(_origin1 == _oldOrigin){
            bytes32 position = proxyOriginPosition1;
            assembly {
                sstore(position, _newOrigin)
            }            
        }else{
            require(false,"OriginTransferred : old origin is illegal address!");
        }
    }
    function txOrigin() public view returns (address _origin0,address _origin1) {
        bytes32 position0 = proxyOriginPosition0;
        bytes32 position1 = proxyOriginPosition1;
        assembly {
            _origin0 := sload(position0)
            _origin1 := sload(position1)
        }
    }
    modifier originOnce() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(bytes32(key))==0, "proxyOwner : This function must be invoked only once!");
        saveValue(bytes32(key),1);
        _;
    }
    function isOrigin() public view returns (bool){
        (address _origin0,address _origin1) = txOrigin();
        return  msg.sender == _origin0 || msg.sender == _origin1;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner();//&& isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
            //allow owner to set once
            uint256 key = oncePosition+uint32(msg.sig);
            require (getValue(bytes32(key))==0, "proxyOwner : This function must be invoked only once!");
            saveValue(bytes32(key),1);
        }else if(isOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/farmRelease/tokenRelease.sol

pragma solidity ^0.5.16;





/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract tokenRelease is tokenReleaseData,proxyOwner {
    using SafeMath for uint256;

    constructor (address multiSignature,address origin0,address origin1)
        proxyOwner(multiSignature,origin0,origin1)
        public
    {
    }

    modifier inited (){
    	  require(meltAddress !=address(0));
    	  _;
    }

    /**
     * @dev constructor function. set minePool contract address.
     */ 
    function setParameter(address _meltAddress,uint256 _timeSpan,uint256 _dispatchTimes,uint256 _txNum,uint256 _idxperiod) OwnerOrOrigin public{
        if (_meltAddress != address(0))
            meltAddress = _meltAddress;
            
        if (_timeSpan != 0) 
            timeSpan = _timeSpan;
            
        if (_dispatchTimes != 0) 
            dispatchTimes = _dispatchTimes;
        
        if (_txNum != 0) 
            txNum = _txNum;

        if(_idxperiod != 0) {
            idxperiod = _idxperiod;
        }

        lockPeriod = dispatchTimes*timeSpan;
    }
    
    /**
     * @dev getting back the left mine token
     */
    function emergencyGetbackLeft()  public isHalted {
        require(lockedBalances[msg.sender]>0,"locked balance is zero");
        uint256 amount = lockedBalances[msg.sender];

        lockedBalances[msg.sender] = 0;

        userFarmClaimedBalances[msg.sender] = userFarmClaimedBalances[msg.sender].add(lockedBalances[msg.sender]);

        IERC20(meltAddress).transfer(msg.sender,amount);
    }  

    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }

    function releaseToken(address account,uint256 amount) external inited {
       
 	    // if(amount==0) {//remove to fixed release problem
		//    return;
		//}
		
        //msg.sender should be the farm contract,here is msg.sender
        IERC20(meltAddress).transferFrom(msg.sender,address(this),amount);
        //according day to cal idx
        uint256 idx = now.div(idxperiod);

        uint256 latest = userTxIdxs[account].length;
        if(latest == 0 || userTxIdxs[account][latest-1]!=idx){
            userTxIdxs[account].push(idx);
        }

        uint256 divAmount = amount.div(dispatchTimes);

        if( lockedAllRewards[account][idx].total==0) {
            lockedAllRewards[account][idx] = lockedReward(now,amount);
        } else {
            lockedAllRewards[account][idx].startTime = now;
            lockedAllRewards[account][idx].total = lockedAllRewards[account][idx].total.add(amount);
        }
        
        //index 0 to save the left token num
        lockedAllRewards[account][idx].alloc[0] = lockedAllRewards[account][idx].alloc[0].add(amount.sub(divAmount));
        uint256 i=2;
        //idx = 1, the reward give user immediately
        for(;i<dispatchTimes;i++){
            lockedAllRewards[account][idx].alloc[i] = lockedAllRewards[account][idx].alloc[i].add(divAmount);
        }
        lockedAllRewards[account][idx].alloc[i] = lockedAllRewards[account][idx].alloc[i].add(amount.sub(divAmount.mul(dispatchTimes-1)));

        lockedBalances[account] = lockedBalances[account].add(amount.sub(divAmount));
        IERC20(meltAddress).transfer(account,divAmount);

        userFarmClaimedBalances[account] = userFarmClaimedBalances[account].add(divAmount);

        //get current claimable balance for account
        uint256 claimable = getClaimAbleBalance(account);
        if(claimable>0) {
            claimpExpired(account);
        }

        emit Input(msg.sender,account,amount,divAmount);
    }



      /**
     * @dev user user claim expired reward
     */ 
    function claimpExpired(address account) internal inited {
        require(meltAddress !=address(0),"token should be set");
        
        uint256 txcnt = 0;
        uint256 idx = lockedIndexs[account].beginIdx;
        uint256 endIdx = userTxIdxs[account].length;
        uint256 totalRet = 0;

        uint256 pretxid = 0;
        for(;idx<endIdx && txcnt<txNum;idx++) {
           //i used for the user input  tx idx,too much i used before,no changed now
           uint256 i = userTxIdxs[account][idx];
           if(i!=pretxid){
                pretxid = i;
            } else {
                continue;
           }

           if (now >= lockedAllRewards[account][i].startTime + timeSpan) {
               if (lockedAllRewards[account][i].alloc[0] > 0) {
                    if (now >= lockedAllRewards[account][i].startTime + lockPeriod) {
                        totalRet = totalRet.add(lockedAllRewards[account][i].alloc[0]);
                        lockedAllRewards[account][i].alloc[0] = 0;
                        //updated last expired idx
                        lockedIndexs[account].beginIdx = idx;
                    } else {
                      
                        uint256 timeIdx = (now - lockedAllRewards[account][i].startTime).div(timeSpan) + 1;
                        uint256 j = 2;
                        uint256 subtotal = 0;
                        for(;j<timeIdx+1;j++) {
                            subtotal = subtotal.add(lockedAllRewards[account][i].alloc[j]);
                            lockedAllRewards[account][i].alloc[j] = 0;
                        }
                        
                        //updated left locked balance,possible?
                        if(subtotal<=lockedAllRewards[account][i].alloc[0]){
                            lockedAllRewards[account][i].alloc[0] = lockedAllRewards[account][i].alloc[0].sub(subtotal);
                        } else {
                            subtotal = lockedAllRewards[account][i].alloc[0];
                            lockedAllRewards[account][i].alloc[0] = 0;
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
        
        lockedBalances[account] = lockedBalances[account].sub(totalRet);
        //transfer back to user
        IERC20(meltAddress).transfer(account,totalRet);

        userFarmClaimedBalances[account] = userFarmClaimedBalances[account].add(totalRet);

        emit Claim(account,totalRet,txcnt);
    }
    
      /**
     * @dev get user claimable balance
     */
    function getClaimAbleBalance(address account) public view returns (uint256) {
        require(meltAddress !=address(0),"melt token should be set");
        
        uint256 txcnt = 0;
        uint256 idx = lockedIndexs[account].beginIdx;
       //uint256 endIdx = lockedIndexs[_user].totalIdx;
        uint256 endIdx = userTxIdxs[account].length;
        uint256 totalRet = 0;
        uint256 pretxid = 0;

        for(;idx<endIdx && txcnt<txNum;idx++) {
            uint256 i = userTxIdxs[account][idx];
            if(i!=pretxid){
                pretxid = i;
            } else {
                continue;
            }
           //only count the rewards over at least one timeSpan
           if (now >= lockedAllRewards[account][i].startTime + timeSpan) {
               
               if (lockedAllRewards[account][i].alloc[0] > 0) {
                    if (now >= lockedAllRewards[account][i].startTime + lockPeriod) {
                        totalRet = totalRet.add(lockedAllRewards[account][i].alloc[0]);
                    } else {
                        uint256 timeIdx = (now - lockedAllRewards[account][i].startTime).div(timeSpan) + 1;
                        uint256 j = 2;
                        uint256 subtotal = 0;
                        for(;j<timeIdx+1;j++) {
                            subtotal = subtotal.add(lockedAllRewards[account][i].alloc[j]);
                        }
                        
                        //updated left locked balance,possible?
                        if(subtotal>lockedAllRewards[account][i].alloc[0]){
                            subtotal = lockedAllRewards[account][i].alloc[0];
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


    function getUserFarmClaimRecords(address account)
            public
            view
            returns
    (uint256,uint256[] memory,uint256[] memory) {
        uint256 idx = lockedIndexs[account].beginIdx;
        //uint256 endIdx = userTxIdxs[_user].length;
        uint256 len = (userTxIdxs[account].length - idx);
        uint256 retidx = 0;
        uint256 pretxid = 0;

        uint256[] memory retStArr = new uint256[]((dispatchTimes+1)*len);
        uint256[] memory retAllocArr = new uint256[]((dispatchTimes+1)*len);

        for(;idx<userTxIdxs[account].length;idx++) {
            uint256 i = userTxIdxs[account][idx];

            if(i!=pretxid){
                pretxid = i;
            } else {
                continue;
            }

            for(uint256 j=0;j<=dispatchTimes;j++) {
                retAllocArr[retidx*(dispatchTimes+1)+j] = lockedAllRewards[account][i].alloc[j];
                if(j==0) {
                    retStArr[retidx*(dispatchTimes+1)+j] = 0;
                } else {
                    retStArr[retidx*(dispatchTimes+1)+j] = lockedAllRewards[account][i].startTime.add(timeSpan*(j-1));
                }
            }
            retidx++;
        }

        return (dispatchTimes+1,retStArr,retAllocArr);
    }
    
}