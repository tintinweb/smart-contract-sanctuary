/**
 *Submitted for verification at hooscan.com on 2022-01-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-03-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-28
*/

// Sources flattened with hardhat v2.0.7 https://hardhat.org

// File @openzeppelin/contracts/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/GSN/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/Container.sol


pragma solidity ^0.7.0;

contract Container {

    struct Item{
        uint256 itemType;
        uint256 status;
        address[] addresses;
    }

    uint256 MaxItemAdressNum = 255;
    mapping (bytes32 => Item) private container;
    // bool private _nativePaused = false;


    function itemAddressExists(bytes32 _id, address _oneAddress) internal view returns(bool){
        for(uint256 i = 0; i < container[_id].addresses.length; i++){
            if(container[_id].addresses[i] == _oneAddress)
                return true;
        }
        return false;
    }
    function getItemAddresses(bytes32 _id) internal view returns(address[] memory){
        return container[_id].addresses;
    }

    function getItemInfo(bytes32 _id) internal view returns(uint256, uint256, uint256){
        return (container[_id].itemType, container[_id].status, container[_id].addresses.length);
    }

    function getItemAddressCount(bytes32 _id) internal view returns(uint256){
        return container[_id].addresses.length;
    }

    function setItemInfo(bytes32 _id, uint256 _itemType, uint256 _status) internal{
        container[_id].itemType = _itemType;
        container[_id].status = _status;
    }

    function addItemAddress(bytes32 _id, address _oneAddress) internal{
        require(!itemAddressExists(_id, _oneAddress), "dup address added");
        require(container[_id].addresses.length < MaxItemAdressNum, "too many addresses");
        container[_id].addresses.push(_oneAddress);
    }
    function removeItemAddresses(bytes32 _id) internal {
        delete container[_id].addresses;
    }

    function removeOneItemAddress(bytes32 _id, address _oneAddress) internal {
        for(uint256 i = 0; i < container[_id].addresses.length; i++){
            if(container[_id].addresses[i] == _oneAddress){
                container[_id].addresses[i] = container[_id].addresses[container[_id].addresses.length - 1];
                container[_id].addresses.pop();
                return;
            }
        }
    }

    function removeItem(bytes32 _id) internal{
        delete container[_id];
    }

    function replaceItemAddress(bytes32 _id, address _oneAddress, address _anotherAddress) internal {
        for(uint256 i = 0; i < container[_id].addresses.length; i++){
            if(container[_id].addresses[i] == _oneAddress){
                container[_id].addresses[i] = _anotherAddress;
                return;
            }
        }
    }
}


// File contracts/BridgeStorage.sol


pragma solidity ^0.7.0;

contract BridgeStorage is Container {
    string public constant name = "BridgeStorage";

    address private caller;

    constructor(address aCaller) {
        caller = aCaller;
    }

    modifier onlyCaller() {
        require(msg.sender == caller, "only use main contract to call");
        _;
    }

    function supporterExists(bytes32 taskHash, address user) public view returns(bool) {
          return itemAddressExists(taskHash, user);
    }

    function setTaskInfo(bytes32 taskHash, uint256 taskType, uint256 status) external onlyCaller {
        setItemInfo(taskHash, taskType, status);
    }

    function getTaskInfo(bytes32 taskHash) public view returns(uint256, uint256, uint256){
        return getItemInfo(taskHash);
    }

    function addSupporter(bytes32 taskHash, address oneAddress) external onlyCaller{
        addItemAddress(taskHash, oneAddress);
    }

    function removeAllSupporter(bytes32 taskHash) external onlyCaller {
        removeItemAddresses(taskHash);
    }
    function removeTask(bytes32 taskHash)external onlyCaller{
        removeItem(taskHash);
    }
}


// File contracts/BridgeAdmin.sol


pragma solidity ^0.7.0;

contract BridgeAdmin is Container {
    bytes32 internal constant OWNERHASH = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    bytes32 internal constant OPERATORHASH = 0x46a52cf33029de9f84853745a87af28464c80bf0346df1b32e205fc73319f622;
    bytes32 internal constant PAUSERHASH = 0x0cc58340b26c619cd4edc70f833d3f4d9d26f3ae7d5ef2965f81fe5495049a4f;
    bytes32 internal constant STOREHASH = 0xe41d88711b08bdcd7556c5d2d24e0da6fa1f614cf2055f4d7e10206017cd1680;
    bytes32 internal constant LOGICHASH = 0x397bc5b97f629151e68146caedba62f10b47e426b38db589771a288c0861f182;
    uint256 internal constant MAXUSERNUM = 255;
    bytes32[] private classHashArray;

    uint256 internal ownerRequireNum;
    uint256 internal operatorRequireNum;

    event AdminChanged(string TaskType, string class, address oldAddress, address newAddress);
    event AdminRequiredNumChanged(string TaskType, string class, uint256 previousNum, uint256 requiredNum);
    event AdminTaskDropped(bytes32 taskHash);

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MaxItemAdressNum
        && _required <= ownerCount
        && _required > 0
            && ownerCount > 0);
        _;
    }

    modifier onlyOwner() {
        require(itemAddressExists(OWNERHASH, msg.sender), "only use owner to call");
        _;
    }

    function initAdmin(address[] memory _owners, uint _ownerRequired) internal validRequirement(_owners.length, _ownerRequired) {
        for (uint i = 0; i < _owners.length; i++) {
            addItemAddress(OWNERHASH, _owners[i]);
        }
        addItemAddress(PAUSERHASH,_owners[0]);// we need an init pauser
        addItemAddress(LOGICHASH, address(0x0));
        addItemAddress(STOREHASH, address(0x1));

        classHashArray.push(OWNERHASH);
        classHashArray.push(OPERATORHASH);
        classHashArray.push(PAUSERHASH);
        classHashArray.push(STOREHASH);
        classHashArray.push(LOGICHASH);
        ownerRequireNum = _ownerRequired;
        operatorRequireNum = 2;
    }

    function classHashExist(bytes32 aHash) private view returns (bool) {
        for (uint256 i = 0; i < classHashArray.length; i++)
            if (classHashArray[i] == aHash) return true;
        return false;
    }

    function getAdminAddresses(string memory class) public view returns (address[] memory) {
        bytes32 classHash = getClassHash(class);
        return getItemAddresses(classHash);
    }

    function getOwnerRequireNum() public view returns (uint256){
        return ownerRequireNum;
    }

    function getOperatorRequireNum() public view returns (uint256){
        return operatorRequireNum;
    }

    function resetRequiredNum(string memory class, uint256 requiredNum) public onlyOwner returns (bool){
        bytes32 classHash = getClassHash(class);
        require((classHash == OPERATORHASH) || (classHash == OWNERHASH), "wrong class");

        bytes32 taskHash = keccak256(abi.encodePacked("resetRequiredNum", class, requiredNum));
        addItemAddress(taskHash, msg.sender);

        if (getItemAddressCount(taskHash) >= ownerRequireNum) {
            removeItem(taskHash);
            uint256 previousNum = 0;
            if (classHash == OWNERHASH) {
                previousNum = ownerRequireNum;
                ownerRequireNum = requiredNum;
            }
            else if (classHash == OPERATORHASH) {
                previousNum = operatorRequireNum;
                operatorRequireNum = requiredNum;
            } else {
                revert("wrong class");
            }
            emit AdminRequiredNumChanged("resetRequiredNum", class, previousNum, requiredNum);
        }
        return true;
    }

    function modifyAddress(string memory class, address oldAddress, address newAddress) internal onlyOwner returns (bool){
        bytes32 classHash = getClassHash(class);
        bytes32 taskHash = keccak256(abi.encodePacked("modifyAddress", class, oldAddress, newAddress));
        addItemAddress(taskHash, msg.sender);
        if (getItemAddressCount(taskHash) >= ownerRequireNum) {
            replaceItemAddress(classHash, oldAddress, newAddress);
            emit AdminChanged("modifyAddress", class, oldAddress, newAddress);
            removeItem(taskHash);
            return true;
        }
        return false;
    }

    function getClassHash(string memory class) private view returns (bytes32){
        bytes32 classHash = keccak256(abi.encodePacked(class));
        require(classHashExist(classHash), "invalid class");
        return classHash;
    }

    function dropAddress(string memory class, address oneAddress) public onlyOwner returns (bool){
        bytes32 classHash = getClassHash(class);
        require(classHash != STOREHASH && classHash != LOGICHASH, "wrong class");
        require(itemAddressExists(classHash, oneAddress), "no such address exist");

        if (classHash == OWNERHASH)
            require(getItemAddressCount(classHash) > ownerRequireNum, "insuffience addresses");

        bytes32 taskHash = keccak256(abi.encodePacked("dropAddress", class, oneAddress));
        addItemAddress(taskHash, msg.sender);
        if (getItemAddressCount(taskHash) >= ownerRequireNum) {
            removeOneItemAddress(classHash, oneAddress);
            emit AdminChanged("dropAddress", class, oneAddress, oneAddress);
            removeItem(taskHash);
            return true;
        }
        return false;
    }

    function addAddress(string memory class, address oneAddress) public onlyOwner returns (bool){
        bytes32 classHash = getClassHash(class);
        require(classHash != STOREHASH && classHash != LOGICHASH, "wrong class");

        bytes32 taskHash = keccak256(abi.encodePacked("addAddress", class, oneAddress));
        addItemAddress(taskHash, msg.sender);
        if (getItemAddressCount(taskHash) >= ownerRequireNum) {
            addItemAddress(classHash, oneAddress);
            emit AdminChanged("addAddress", class, oneAddress, oneAddress);
            removeItem(taskHash);
            return true;
        }
        return false;
    }

    function dropTask(bytes32 taskHash) public onlyOwner returns (bool){
        removeItem(taskHash);
        emit AdminTaskDropped(taskHash);
        return true;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/BridgeLogic.sol


pragma solidity ^0.7.0;




contract BridgeLogic {
    using SafeMath for uint256;

    string public constant name = "BridgeLogic";

    bytes32 internal constant OPERATORHASH = 0x46a52cf33029de9f84853745a87af28464c80bf0346df1b32e205fc73319f622;
    uint256 public constant TASKINIT = 0;
    uint256 public constant TASKPROCESSING = 1;
    uint256 public constant TASKCANCELLED = 2;
    uint256 public constant TASKDONE = 3;
    uint256 public constant WITHDRAWTASK = 1;

    address private caller;
    BridgeStorage private store;

    constructor(address aCaller) {
        caller = aCaller;
    }

    modifier onlyCaller(){
        require(msg.sender == caller, "only main contract can call");
        _;
    }

    modifier operatorExists(address operator) {
        require(store.supporterExists(OPERATORHASH, operator), "wrong operator");
        _;
    }

    function resetStoreLogic(address storeAddress) external onlyCaller {
        store = BridgeStorage(storeAddress);
    }

    function getStoreAddress() public view returns(address) {
        return address(store);
    }

    function supportTask(uint256 taskType, bytes32 taskHash, address oneAddress, uint256 requireNum) external onlyCaller returns(uint256){
        require(!store.supporterExists(taskHash, oneAddress), "supporter already exists");
        (uint256 theTaskType,uint256 theTaskStatus,uint256 theSupporterNum) = store.getTaskInfo(taskHash);
        require(theTaskStatus < TASKDONE, "wrong status");

        if (theTaskStatus != TASKINIT)
            require(theTaskType == taskType, "task type not match");
        store.addSupporter(taskHash, oneAddress);
        theSupporterNum++;
        if(theSupporterNum >= requireNum)
            theTaskStatus = TASKDONE;
        else
            theTaskStatus = TASKPROCESSING;
        store.setTaskInfo(taskHash, taskType, theTaskStatus);
        return theTaskStatus;
    }

    function cancelTask(bytes32 taskHash)  external onlyCaller returns(uint256) {
        (uint256 theTaskType,uint256 theTaskStatus,uint256 theSupporterNum) = store.getTaskInfo(taskHash);
        require(theTaskStatus == TASKPROCESSING, "wrong status");
        if(theSupporterNum > 0) store.removeAllSupporter(taskHash);
        theTaskStatus = TASKCANCELLED;
        store.setTaskInfo(taskHash, theTaskType, theTaskStatus);
        return theTaskStatus;
    }
    function removeTask(bytes32 taskHash)  external onlyCaller {
        store.removeTask(taskHash);

    }


}


// File contracts/ERC20Sample.sol

pragma solidity ^0.7.0;


abstract contract ERC20Template is IERC20 {

    function mint(address account, uint256 amount) public{
    }
    function burn(address account , uint256 amount) public{
    }
    function redeem(address account, uint256 amount)public {
    }
    function issue(address account, uint256 amount) public {
    }
}


// File contracts/Bridge.sol


pragma solidity ^0.7.0;

contract Bridge is BridgeAdmin, Pausable {

    using SafeMath for uint256;

    string public constant name = "Bridge";

    BridgeLogic private logic;

    uint256 public defaultNativeSendInWithdrawToken = 1e17;
    mapping (string=>uint256) public fee;
    mapping (string=>mapping(address=>uint256)) public minDeposit;
    address native = address(0x0000000000000000000000000000000000000000);

    event Deposit(address indexed sender, uint value);
    event DepositNative(address indexed from, uint256 nativeValue, uint256 value, string targetAddress, string chain, bool buyNative);
    event DepositToken(address indexed from, uint256 value, address indexed token, string targetAddress, string chain, uint256 nativeValue, bool buyNative);
    event WithdrawingNative(address indexed to, uint256 value, string proof);
    event WithdrawingToken(address indexed to, address indexed token, uint256 value, string proof);
    event WithdrawDoneNative(address indexed to, uint256 value, string proof);
    event WithdrawDoneToken(address indexed to, address indexed token, uint256 value, string proof);
    event NativeSentInWithdrawToken(address indexed to, address indexed token, uint256 value, string proof, uint256 nativeValue);

    modifier onlyOperator() {
        require(itemAddressExists(OPERATORHASH, msg.sender), "wrong operator");
        _;
    }

    modifier onlyPauser() {
        require(itemAddressExists(PAUSERHASH, msg.sender), "wrong pauser");
        _;
    }

    modifier positiveValue(uint _value) {
        require(_value > 0, "value need > 0");
        _;
    }

    constructor(address[] memory _owners, uint _ownerRequired) {
        initAdmin(_owners, _ownerRequired);
    }

    receive() external payable {
        if (msg.value > 0)
           emit Deposit(msg.sender, msg.value);
    }

    function depositNative(string memory _targetAddress, string memory chain, uint value, bool buyNative) public payable whenNotPaused{
        require(msg.value >= value.add(fee[chain]), "invalid value");
        if (buyNative){
            require(value >= minDeposit[chain][native], "invalid deposit amount with buyNative enabled");
        }
        emit DepositNative(msg.sender, msg.value, value, _targetAddress, chain, buyNative);
    }

    function depositToken(address _token, uint value, string memory _targetAddress, string memory chain, bool buyNative) public payable whenNotPaused returns (bool){
        require(msg.value >= fee[chain], "invalid value");
        if (buyNative){
            require(value >= minDeposit[chain][_token], "invalid deposit amount with buyNative enabled");
        }
        bool res = depositTokenLogic(_token,  msg.sender, value);
        emit DepositToken(msg.sender, value, _token, _targetAddress, chain, msg.value, buyNative);
        return res;
    }

    function withdrawNative(address payable to, uint value, string memory proof, bytes32 taskHash) public
    onlyOperator
    whenNotPaused
    positiveValue(value)
    returns(bool)
    {
        require(address(this).balance >= value, "not enough native token");
        require(taskHash == keccak256((abi.encodePacked(to,value,proof))),"taskHash is wrong");
        uint256 status = logic.supportTask(logic.WITHDRAWTASK(), taskHash, msg.sender, operatorRequireNum);

        if (status == logic.TASKPROCESSING()){
            emit WithdrawingNative(to, value, proof);
        }else if (status == logic.TASKDONE()) {
            emit WithdrawingNative(to, value, proof);
            emit WithdrawDoneNative(to, value, proof);
            to.transfer(value);
            logic.removeTask(taskHash);
        }
        return true;
    }

    function withdrawToken(address _token, address to, uint value, string memory proof, bytes32 taskHash, bool sendNative) public
    onlyOperator
    whenNotPaused
    positiveValue(value)
    returns (bool)
    {
        require(taskHash == keccak256((abi.encodePacked(to,value,proof))),"taskHash is wrong");
        uint256 status = logic.supportTask(logic.WITHDRAWTASK(), taskHash, msg.sender, operatorRequireNum);

        if (status == logic.TASKPROCESSING()){
            emit WithdrawingToken(to, _token, value, proof);
        }else if (status == logic.TASKDONE()) {
            bool res = withdrawTokenLogic( _token, to, value);
            if (sendNative){
                require(address(this).balance >= defaultNativeSendInWithdrawToken, "bridge insufficient native balance");
                payable(to).transfer(defaultNativeSendInWithdrawToken);
                emit NativeSentInWithdrawToken(to, _token, value, proof, defaultNativeSendInWithdrawToken);
            }
            emit WithdrawingToken(to, _token, value, proof);
            emit WithdrawDoneToken(to, _token, value, proof);
            logic.removeTask(taskHash);
            return res;
        }
        return true;
    }

    function modifyAdminAddress(string memory class, address oldAddress, address newAddress) public whenPaused {
        require(newAddress != address(0x0), "wrong address");
        bool flag = modifyAddress(class, oldAddress, newAddress);
        if(flag){
            bytes32 classHash = keccak256(abi.encodePacked(class));
            if(classHash == LOGICHASH){
                logic = BridgeLogic(newAddress);
            }else if(classHash == STOREHASH){
                logic.resetStoreLogic(newAddress);
            }
        }
    }

    function getLogicAddress() public view returns(address){
        return address(logic);
    }

    function getStoreAddress() public view returns(address){
        return logic.getStoreAddress();
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function transferNative(uint256 value,  address to) 
    whenPaused onlyOwner external
    {
        require(address(this).balance >= value, "value to large");
        require(to != address(0x0), "wrong receiving address");
        payable(to).transfer(value);
    }

    function transferToken(address token, address to, uint256 value) 
    whenPaused onlyOwner external
    {
        IERC20 atoken = IERC20(token);
        bool success = atoken.transfer(to,value);
    }

    function setFee(string memory targetChain, uint256 _amount) 
    whenPaused onlyPauser external
    {
        fee[targetChain] = _amount;
    }

    function setMinDeposit(string memory targetChain, address token, uint256 _amount) 
    whenPaused onlyPauser external
    {
        minDeposit[targetChain][token] = _amount;
    }

    function setDefaultNativeSendInWithdrawToken(uint256 _amount) 
    whenPaused onlyPauser external
    {
        defaultNativeSendInWithdrawToken = _amount;
    }

    function setDepositSelector(address token, string memory method, bool _isValueFirst) onlyOperator external{
        depositSelector[token] = assetSelector(method,_isValueFirst);
    }

    function setWithdrawSelector(address token, string memory method, bool _isValueFirst) onlyOperator external{
        withdrawSelector[token] = assetSelector(method,_isValueFirst);
    }

    struct assetSelector{
        string selector;
        bool isValueFirst;
    }

    mapping (address=>assetSelector)  public depositSelector;
    mapping (address=> assetSelector) public withdrawSelector;

    function depositTokenLogic(address token, address _from, uint256 _value) internal returns(bool){
        bool status = false;
        bytes memory returnedData;
        if (bytes(depositSelector[token].selector).length == 0){
            (status,returnedData)= token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",_from,this,_value));
        }
        else{
            assetSelector memory aselector = depositSelector[token];
            if (aselector.isValueFirst){
                // burn user asset
                (status, returnedData) = token.call(abi.encodeWithSignature(aselector.selector,_value,_from));
            }
            else {
                (status,returnedData)= token.call(abi.encodeWithSignature(aselector.selector,_from,_value));
            }
        }
        require(
            status && (returnedData.length == 0 || abi.decode(returnedData, (bool))),
            ' transfer failed');
        return true;
    }

    function withdrawTokenLogic(address token, address _to, uint256 _value) internal returns(bool){
        bool status = false;
        bytes memory returnedData;
        if (bytes(withdrawSelector[token].selector).length==0){
            (status,returnedData)= token.call(abi.encodeWithSignature("transfer(address,uint256)",_to,_value));
        }
        else{
            assetSelector memory aselector = withdrawSelector[token];
            if (aselector.isValueFirst){
                (status,returnedData) = token.call(abi.encodeWithSignature( aselector.selector,_value,_to));
            }
            else {
                (status,returnedData)= token.call(abi.encodeWithSignature(aselector.selector,_to,_value));
            }
        }

        require(status && (returnedData.length == 0 || abi.decode(returnedData, (bool))),'withdraw failed');
        return true;
    }
}