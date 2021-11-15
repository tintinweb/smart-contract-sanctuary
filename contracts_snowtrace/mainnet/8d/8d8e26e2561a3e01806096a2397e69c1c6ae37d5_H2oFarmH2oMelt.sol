/**
 *Submitted for verification at snowtrace.io on 2021-11-15
*/

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

// File: contracts/modules/whiteList.sol

pragma solidity ^0.5.16;
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

// File: contracts/modules/Operator.sol

pragma solidity ^0.5.16;


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

// File: contracts/modules/ReentrancyGuard.sol

pragma solidity ^0.5.16;
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

// File: contracts/defrostMeltFarmH2oMelt/LPTokenWrapper.sol

pragma solidity ^0.5.16;



contract LPTokenWrapper {

    uint256 internal totalsupply;
    mapping(address => uint256) internal balances;
    address public stakeToken;
    
    using SafeMath for uint256;

    function totalSupply() public view returns(uint256) {
        return totalsupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return balances[account];
    }

    function stake(uint256 amount) internal {

        require(amount > 0, "cannot stake 0");
        uint256 preBalance = IERC20(stakeToken).balanceOf(address(this));
        IERC20(stakeToken).transferFrom(msg.sender,address(this), amount);
        uint256 afterBalance = IERC20(stakeToken).balanceOf(address(this));
        require(afterBalance-preBalance==amount,"token stake transfer error!");

        totalsupply = totalsupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
    }

    function unstake (uint256 amount) internal {
        totalsupply = totalsupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        uint256 preBalance = IERC20(stakeToken).balanceOf(address(this));
        IERC20(stakeToken).transfer(msg.sender, amount);
        uint256 afterBalance = IERC20(stakeToken).balanceOf(address(this));
        require(preBalance - afterBalance==amount,"token unstake transfer error!");
    }

    
}

// File: contracts/defrostMeltFarmH2oMelt/TokenFarmData.sol

pragma solidity ^0.5.16;

contract TokenFarmData {
    
    address public rewardToken;
    address public manager;

   // address  public rewardDistribution;
    
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;

    uint256 public rewardPerduration; //reward token number per duration
    uint256 public duration;
    
    mapping(address => uint256) public rewards;   
        
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    uint256 public periodFinish;
    uint256 public startTime;
}

// File: contracts/modules/Admin.sol

pragma solidity ^0.5.16;



contract Admin is multiSignatureClient,Ownable {
    mapping(address => bool) public mapAdmin;
    event AddAdmin(address admin);
    event RemoveAdmin(address admin);

    modifier onlyAdmin() {
        require(mapAdmin[msg.sender], "not admin");
        _;
    }

    function addAdmin(address admin)
        external
        validCall
    {
        mapAdmin[admin] = true;
        emit AddAdmin(admin);
    }

    function removeAdmin(address admin)
        external
        validCall
    {
        delete mapAdmin[admin];
        emit RemoveAdmin(admin);
    }
}

// File: contracts/modules/Address.sol

pragma solidity ^0.5.16;

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
        (bool success, ) = recipient.call.value(amount)("");
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call.value(value )(data);
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: contracts/defrostMeltFarmH2oMelt/TokenFarm.sol

pragma solidity ^0.5.16;










contract TokenFarm is Halt,TokenFarmData {
    using SafeMath for uint256;

    event RewardPaid(address rewardToken,address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            require(now >= startTime,"not reach start time");
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;     
        }
        _;
    }

    constructor(address _manager,address _rewardToken)
      public
    {
        manager = _manager;
        rewardToken = _rewardToken;
    }

    function setMineRate(uint256 _reward,uint256 _duration) public onlyOwner updateReward(address(0)){
        rewardRate = _reward.div(_duration);
        rewardPerduration = _reward;
        duration = _duration;
    }   


    function setPeriodFinish(uint256 startime,uint256 endtime) public onlyOwner updateReward(address(0)) {
        //set new finish time
        lastUpdateTime = startime;
        periodFinish = endtime;
        startTime = startime;
    }  
    
    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftMiningToken(address reciever)  public
        onlyOwner
    {
        uint256 bal =  IERC20(rewardToken).balanceOf(manager);
        IERC20(rewardToken).transferFrom(manager,reciever,bal);
    }

//////////////////////////public function/////////////////////////////////    

    function lastTimeRewardApplicable() public view returns(uint256) {

        //get max
         uint256 timestamp = block.timestamp>startTime?block.timestamp:startTime;

         //get min
         return (timestamp<periodFinish?timestamp:periodFinish);
     }

    function rewardPerToken() public view returns(uint256) {
        if (IERC20(manager).totalSupply() == 0 || now < startTime) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(IERC20(manager).totalSupply())
        );
    }

    function earned(address account)  public view returns(uint256) {
        return IERC20(manager).balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
     }

    function getReward(address account) public updateReward(account) onlyOwner {
        uint256 reward = earned(account);
        if (reward > 0) {
            rewards[account] = 0;
            uint256 preBalance = IERC20(rewardToken).balanceOf(address(manager));

            IERC20(rewardToken).transferFrom(manager,account, reward);

            uint256 afterBalance = IERC20(rewardToken).balanceOf(address(manager));
            require(preBalance - afterBalance==reward,"phx award transfer error!");
            emit RewardPaid(rewardToken,account, reward);
        }
    }

    function stake(address account) public updateReward(account) onlyOwner {
         require(startTime>0,"farm is not inited");
         require(now>startTime,"farm time not arrive");
    }

    function unstake(address account) public updateReward(account) onlyOwner {
    }

    function exit(address account) public onlyOwner {
        getReward(account);
    }

    function getMineInfo() public view returns (uint256,uint256) {
        return (rewardPerduration,duration);
    }

}

// File: contracts/defrostMeltFarmH2oMelt/MeltFarmH2oMelt.sol

pragma solidity ^0.5.16;











contract H2oFarmH2oMelt  is LPTokenWrapper,proxyOwner,Halt,ReentrancyGuard{

    uint256 public REWARD_NUM = 2;

    address[] public rewardTokens;
    mapping(address=>TokenFarm) public tokenFarms;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _multiSignature,address origin0,address origin1,
                address _stakeToken,address[] memory _rewardTokens)
        proxyOwner(_multiSignature,origin0,origin1)
        public
    {
       // require(_rewardTokens.length==REWARD_NUM);

        require(_multiSignature != address(0));
        require(_stakeToken != address(0));

        if(REWARD_NUM != _rewardTokens.length) {
            REWARD_NUM = _rewardTokens.length;
        }

        stakeToken = _stakeToken;
        for(uint256 i=0;i<_rewardTokens.length;i++) {
            rewardTokens.push(_rewardTokens[i]);
            tokenFarms[_rewardTokens[i]] = new TokenFarm(address(this),_rewardTokens[i]);
            IERC20(_rewardTokens[i]).approve(address(tokenFarms[_rewardTokens[i]]),~uint256(0));
        }
    }

    function initMinePool(uint256[] memory _reward,uint256[] memory _duration,uint256[] memory _startime,uint256[] memory _endtime) public OwnerOrOrigin{

        require(_reward.length==REWARD_NUM,"rewards length is not equal reward token number");
        require(_reward.length==_duration.length,"reward array length is not equal");
        require(_startime.length==REWARD_NUM,"start time array length is not equal");
        require(_startime.length==_endtime.length,"end time array length is not equal");

        for(uint256 i=0;i<REWARD_NUM;i++) {
            require(_reward[i]>0);
            require(_duration[i]>0);
            tokenFarms[rewardTokens[i]].setMineRate(_reward[i],_duration[i]);

            require(_startime[i]>0);
            require(_endtime[i]>0);
            tokenFarms[rewardTokens[i]].setPeriodFinish(_startime[i],_endtime[i]);
        }
    }


    function setMineRate(uint256 _pid,uint256 _reward,uint256 _duration) public OwnerOrOrigin{
        require(_pid<REWARD_NUM);
        //allow set reward to 0,then stop this reward
        require(_duration>0);
        tokenFarms[rewardTokens[_pid]].setMineRate(_reward,_duration);
    }


    function setPeriodFinish(uint256 _pid,uint256 _startime,uint256 _endtime)public OwnerOrOrigin {
         require(_pid<REWARD_NUM);
         require(_startime>now);
         require(_endtime>_startime);

         tokenFarms[rewardTokens[_pid]].setPeriodFinish(_startime,_endtime);
    }

    function getbackLeftMiningToken(address reciever)  public
        onlyOrigin
    {
        for(uint256 i=0;i<rewardTokens.length;i++) {
            tokenFarms[rewardTokens[i]].getbackLeftMiningToken(reciever);
        }

    }


    function rewardPerToken(uint256 _pid) public view returns(uint256) {
        return tokenFarms[rewardTokens[_pid]].rewardPerToken();
    }


    function earned(uint256 _pid,address account) internal view returns(uint256) {
        return tokenFarms[rewardTokens[_pid]].earned(account);
    }


    function getMineInfo(uint256 _pid) public view returns (uint256,uint256) {
        return tokenFarms[rewardTokens[_pid]].getMineInfo();
    }

    function allPendingReward(uint256 _pid,address _user) public view returns(uint256){
        return earned(_pid,_user);
    }

    function totalStaked() public view returns (uint256){
        return super.totalSupply();
    }

    function exit() public notHalted nonReentrant {
        super.unstake(balanceOf(msg.sender));

        for(uint256 i=0;i<rewardTokens.length;i++) {
            tokenFarms[rewardTokens[i]].exit(msg.sender);
        }

    }

    function getReward() public notHalted nonReentrant {
        for(uint256 i=0;i<rewardTokens.length;i++) {
            tokenFarms[rewardTokens[i]].getReward(msg.sender);
        }
    }

//    /**
//     * @param addr The user to look up staking information for.
//     * @return The number of staking tokens deposited for addr.
//     */
    function totalStakedFor(address _account) public view returns (uint256) {
        return super.balanceOf(_account);
    }


//////////////////////////////compitable with previous interface for UI///////////////////////////////////////////////////////////
    function deposit(uint256 _amount)  public payable {
        stake(_amount);

        for(uint256 i=0;i<rewardTokens.length;i++) {
            tokenFarms[rewardTokens[i]].stake(msg.sender);
        }

        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public payable{
        if(_amount==0) {
            getReward();
        }else {
            unstake(_amount);
            for(uint256 i=0;i<rewardTokens.length;i++) {
                tokenFarms[rewardTokens[i]].unstake(msg.sender);
            }
            emit Withdrawn(msg.sender, _amount);
        }
    }


}