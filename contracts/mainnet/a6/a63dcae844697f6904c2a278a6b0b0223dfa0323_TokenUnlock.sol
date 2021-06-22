/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: contracts/Ownable.sol

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

// File: contracts/Halt.sol

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

// File: contracts/whiteList.sol

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
    /**
     * @dev Implementation of a whitelist which filters a eligible uint32.
     */
library whiteListUint32 {
    /**
     * @dev add uint32 into white list.
     * @param whiteList the storage whiteList.
     * @param temp input value
     */

    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    /**
     * @dev remove uint32 from whitelist.
     */
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible uint256.
     */
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible address.
     */
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}

// File: contracts/Operator.sol

pragma solidity =0.5.16;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    mapping(uint256=>address) private _operators;
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operators[index] = addAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}

// File: contracts/multiSignatureClient.sol

pragma solidity =0.5.16;
interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    bytes32 private constant multiSignaturePositon = keccak256("org.Finnexus.multiSignature.storage");
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

// File: contracts/TokenUnlockData.sol

pragma solidity =0.5.16;



contract TokenUnlockData is multiSignatureClient,Operator,Halt {
    //the locjed reward info

    struct lockedItem {
        uint256 startTime; //this tx startTime for locking
        uint256 endTime;   //record input amount in each lock tx
        uint256 amount;
    }

    struct lockedInfo {
        uint256 wholeAmount;
        uint256 pendingAmount;     //record input amount in each lock tx
        uint256 totalItem;
        bool    disable;
        mapping (uint256 => lockedItem) alloc;//the allocation table
    }

    address public phxAddress;  //fnx token address

    mapping (address => lockedInfo) public allLockedPhx;//converting tx record for each user

    event SetUserPhxAlloc(address indexed owner, uint256 indexed amount,uint256 indexed worth);

    event ClaimPhx(address indexed owner, uint256 indexed amount,uint256 indexed worth);

}

// File: contracts/SafeMath.sol

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

// File: contracts/IERC20.sol

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

// File: contracts/TokenUnlock.sol

pragma solidity =0.5.16;





/**
 * @title FPTCoin is finnexus collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract TokenUnlock is TokenUnlockData {
    using SafeMath for uint256;
    modifier inited (){
    	  require(phxAddress !=address(0));
    	  _;
    }

    constructor(address _phxAddress,address _multiSignature)
        multiSignatureClient(_multiSignature)
        public
    {
        phxAddress = _phxAddress;
    }



    function update() public onlyOperator(0) {
    }

    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftPhx(address reciever)  public onlyOperator(0) validCall {
        uint256 bal =  IERC20(phxAddress).balanceOf(address(this));
        IERC20(phxAddress).transfer(reciever,bal);
    }  

    function lockedBalanceOf(address user) public view returns (uint256) {
        lockedInfo storage lr = allLockedPhx[user];
        return lr.pendingAmount;
    }

    function getUserLockedItemInfo(address user,uint256 alloxidx) public view returns (uint256,uint256,uint256,bool) {
        lockedItem storage lralloc = allLockedPhx[user].alloc[alloxidx];
        return (lralloc.startTime,lralloc.endTime,lralloc.amount,allLockedPhx[user].disable);
    }

    function setMultiUsersPhxUnlockInfo( address[] memory users,
                                      uint256[] memory amounts,
                                      uint256[] memory startTimes,
                                      uint256[] memory timeIntervals,
                                      uint256[] memory allocTimes)
        public
        inited
        onlyOperator(0)
    {
        require(users.length==amounts.length);
        require(users.length==startTimes.length);
        require(users.length==timeIntervals.length);
        require(users.length==allocTimes.length);
        uint256 i=0;
        for(;i<users.length;i++){
            _setUserPhxUnlockInfo(users[i],amounts[i],startTimes[i],timeIntervals[i],allocTimes[i]);
        }
    }


    function setUserPhxUnlockInfo(address user,uint256 amount,uint256 startTime,uint256 timeInterval,uint256 allocTimes)
        public
        inited
        onlyOperator(0)
    {
        _setUserPhxUnlockInfo(user,amount,startTime,timeInterval,allocTimes);
    }

    function _setUserPhxUnlockInfo(address user,uint256 amount,uint256 startTime,uint256 timeInterval,uint256 allocTimes)
        internal
    {
        require(user!=address(0),"user address is 0");
        require(amount>0,"amount should be bigger than 0");
        require(timeInterval>0,"time interval is 0");
        require(allocTimes>0,"alloc times is 0");
        require(!allLockedPhx[user].disable,"user is diabled already");

        uint256 lastIndex = allLockedPhx[user].totalItem;
        if(lastIndex>0) {
            require(startTime>= allLockedPhx[user].alloc[lastIndex-1].endTime,"starttime is earlier than last set");
        }

        uint256 divAmount = amount.div(allocTimes);
        uint256 startIdx = allLockedPhx[user].totalItem;
        uint256 i;
        for (i=0;i<allocTimes;i++) {
            allLockedPhx[user].alloc[startIdx+i] = lockedItem( startTime.add(i*timeInterval),
                startTime.add((i+1)*timeInterval),
                divAmount);
        }

        allLockedPhx[user].wholeAmount = allLockedPhx[user].wholeAmount.add(amount);
        allLockedPhx[user].pendingAmount = allLockedPhx[user].pendingAmount.add(amount);
        allLockedPhx[user].totalItem = allLockedPhx[user].totalItem.add(allocTimes);

        emit SetUserPhxAlloc(user,amount,divAmount);
    }


    function resetUserPhxUnlockInfo(address user,uint256 roundidx,uint256 amount,uint256 startTime,uint256 endTime)
            public
            inited
            onlyOperator(0)
            
    {
        require(startTime<endTime,"startTime is later than endTime");
        require(now< allLockedPhx[user].alloc[roundidx].endTime,"this alloc is expired already");
        //reset do not need to check because, possible enabled after reset
       // require(!allLockedPhx[user].disable,"user is diabled already");

        allLockedPhx[user].alloc[roundidx].startTime = startTime;
        allLockedPhx[user].alloc[roundidx].startTime = endTime;

        //sub alloc amount
        allLockedPhx[user].pendingAmount =  allLockedPhx[user].pendingAmount.sub(allLockedPhx[user].alloc[roundidx].amount);
        allLockedPhx[user].wholeAmount =  allLockedPhx[user].wholeAmount.sub(allLockedPhx[user].alloc[roundidx].amount);

        allLockedPhx[user].alloc[roundidx].amount = amount;

        allLockedPhx[user].pendingAmount =  allLockedPhx[user].pendingAmount.add(amount);
        allLockedPhx[user].wholeAmount =  allLockedPhx[user].wholeAmount.add(amount);
    }

    function claimExpiredPhx() public inited notHalted {
        require(!allLockedPhx[msg.sender].disable,"user is diabled already");
        uint256 i = 0;
        uint256 endIdx = allLockedPhx[msg.sender].totalItem ;
        uint256 totalRet=0;
        for(;i<endIdx;i++) {
           //only count the rewards over at least one timeSpan
           if (now >= allLockedPhx[msg.sender].alloc[i].endTime) {
               if (allLockedPhx[msg.sender].alloc[i].amount > 0) {
                   totalRet = totalRet.add(allLockedPhx[msg.sender].alloc[i].amount);
                   allLockedPhx[msg.sender].alloc[i].amount = 0;
               }
           }
        }
        allLockedPhx[msg.sender].pendingAmount = allLockedPhx[msg.sender].pendingAmount.sub(totalRet);

        //transfer back to user
        uint256 balbefore = IERC20(phxAddress).balanceOf(msg.sender);
        IERC20(phxAddress).transfer(msg.sender,totalRet);
        uint256 balafter = IERC20(phxAddress).balanceOf(msg.sender);
        require((balafter-balbefore)==totalRet,"error transfer phx,balance check failed");
        
        emit ClaimPhx(msg.sender,totalRet, allLockedPhx[msg.sender].pendingAmount);
    }
    
    function getClaimAbleBalance(address user) public view returns (uint256) {
        uint256 i = 0;
        uint256 endIdx = allLockedPhx[user].totalItem ;
        uint256 totalRet=0;
        for(;i<endIdx;i++) {
            //only count the rewards over at least one timeSpan
            if (now >= allLockedPhx[user].alloc[i].endTime) {
                if (allLockedPhx[user].alloc[i].amount > 0) {
                    totalRet = totalRet.add(allLockedPhx[user].alloc[i].amount);
                }
            }
        }
        return totalRet;
    }

    function setUserStatus(address user,bool disable)
        public
        inited
        onlyOperator(0)
        validCall
    {
        require(user != address(0));
        allLockedPhx[user].disable = disable;
    }
    
}