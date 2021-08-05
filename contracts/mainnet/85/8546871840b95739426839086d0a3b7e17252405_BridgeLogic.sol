/**
 *Submitted for verification at Etherscan.io on 2021-01-22
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
 * `SafeMath` reSPDX-License-Identifiers this intuition by reverting the transaction when an
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