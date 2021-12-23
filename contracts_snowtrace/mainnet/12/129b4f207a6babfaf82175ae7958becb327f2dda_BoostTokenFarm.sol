/**
 *Submitted for verification at snowtrace.io on 2021-12-23
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

// File: contracts/defrostBoostFarm/boostTokenFarmData.sol

pragma solidity ^0.5.16;

contract BoostTokenFarmData {
    
    address public rewardToken;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;

    uint256 public rewardPerduration; //reward token number per duration
    uint256 public duration;
    
    mapping(address => uint256) public rewards;   
        
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    uint256 public periodFinish;
    uint256 public startTime;

    address public boostFarm;
}

// File: contracts/modules/Admin.sol

pragma solidity ^0.5.16;



contract Admin is Ownable {
    mapping(address => bool) public mapAdmin;
    event AddAdmin(address admin);
    event RemoveAdmin(address admin);

    modifier onlyAdmin() {
        require(mapAdmin[msg.sender], "not admin");
        _;
    }

    function addAdmin(address admin)
        external
        onlyOwner
    {
        mapAdmin[admin] = true;
        emit AddAdmin(admin);
    }

    function removeAdmin(address admin)
        external
        onlyOwner
    {
        delete mapAdmin[admin];
        emit RemoveAdmin(admin);
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

// File: contracts/modules/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// File: contracts/defrostBoostFarm/boostTokenFarm.sol

pragma solidity ^0.5.16;












contract BoostTokenFarm is Halt, BoostTokenFarmData,proxyOwner{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event RewardPaid(address rewardToken,address indexed user, uint256 reward);

    modifier onlyBoostFarm() {
        require(boostFarm==msg.sender, "not admin");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;     
        }
        _;
    }

    constructor(address _multiSignature,
                address _origin0,
                address _origin1,
                address _boostFarm,
                address _rewardToken)
      proxyOwner(_multiSignature,_origin0,_origin1)
      public
    {
        boostFarm = _boostFarm;
        rewardToken = _rewardToken;
    }

    function setPoolToken(address _boostFarm,address _rewardToken) public onlyOrigin {
        boostFarm = _boostFarm;
        rewardToken = _rewardToken;
    }

    function setMineRate(uint256 _reward,uint256 _duration) public onlyOrigin updateReward(address(0)){
        require(_duration>0,"duration need to be over 0");
        rewardRate = _reward.div(_duration);
        rewardPerduration = _reward;
        duration = _duration;
    }

    //need set start time  as same as boostFarm
    function setPeriodFinish(uint256 _startime,uint256 _endtime) public onlyOrigin updateReward(address(0)) {
        require(_startime>now);
        require(_endtime>_startime);

        //set new finish time
        lastUpdateTime = _startime;
        periodFinish = _endtime;
        startTime = _startime;
    }  
    
    /**
     * @dev getting back the left mine token
     * @param reciever the reciever for getting back mine token
     */
    function getbackLeftMiningToken(address reciever)  public
        onlyOrigin
    {
        uint256 bal =  IERC20(rewardToken).balanceOf(boostFarm);
        IERC20(rewardToken).safeTransferFrom(boostFarm,reciever,bal);
    }

//////////////////////////public function/////////////////////////////////    

    function lastTimeRewardApplicable() public view returns(uint256) {

        //get max
         uint256 timestamp = block.timestamp>startTime?block.timestamp:startTime;

         //get min
         return (timestamp<periodFinish?timestamp:periodFinish);
     }

    function rewardPerToken() public view returns(uint256) {
        if (IERC20(boostFarm).totalSupply() == 0 || now < startTime) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(IERC20(boostFarm).totalSupply())
        );
    }

    function earned(address account)  public view returns(uint256) {
        return IERC20(boostFarm).balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getReward(address account) public updateReward(account) onlyBoostFarm {
        uint256 reward = earned(account);
        if (reward > 0) {
            rewards[account] = 0;
            IERC20(rewardToken).safeTransferFrom(boostFarm,account, reward);
            emit RewardPaid(rewardToken,account, reward);
        }
    }

    function getMineInfo() public view returns (uint256,uint256) {
        return (rewardPerduration,duration);
    }

//    function stake(address account) public updateReward(account) onlyBoostFarm {
//        require(startTime>0,"farm is not inited");
//    }
//
//    function unstake(address account) public updateReward(account) onlyBoostFarm {
//    }

}

// File: contracts/defrostBoostFarm/defrostBoostFarmStorage.sol

pragma solidity ^0.5.16;






contract deFrostFarmErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract defrostBoostFarmStorage is Halt, ReentrancyGuard{
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 extRewardDebt; 
    }

    struct ExtFarmInfo{
        address extFarmAddr;
        bool extEnableDeposit;
        uint256 extPid;
        uint256 extRewardPerShare;
        uint256 extTotalDebtReward;  //
        bool extEnableClaim;
    }

    struct PoolMineInfo {
        uint256 totalMineReward;
        uint256 duration;
    }

    uint256 RATIO_DENOM = 1000;
    struct whiteListRewardRatio {
        uint256 amount;
        uint256 incPercent;
    }

    struct teamRewardRatio {
        uint256 amount;
        uint256 percent;
    }


    // Info of each pool.
    struct PoolInfo {
        address  lpToken;          // Address of LP token contract. 0
        uint256 currentSupply;    //1
        uint256 bonusStartBlock;  //2
        uint256 newStartBlock;    //3
        uint256 bonusEndBlock;    // Block number when bonus phx period ends.4
        uint256 lastRewardBlock;  // Last block number that phxs distribution occurs.5
        uint256 accRewardPerShare;// Accumulated phx per share, times 1e12. See below.6
        uint256 rewardPerBlock;   // phx tokens created per block.7
        uint256 totalDebtReward;  //8
        uint256 bonusStartTime;

        ExtFarmInfo extFarmInfo;

    }


    uint256 teamRewardLevels;
    mapping (uint256 => teamRewardRatio) teamRewardInfo;

    uint256 whiteListRewardIncLevels;
    mapping (uint256 => whiteListRewardRatio)  public whiteListRewardIncInfo;

    mapping (address => bool) public whiteListLpUserInfo;

    address public rewardToken;
    address public oracle;
    address public h2o;
    uint256 public fixedTeamRatio = 10;
    uint256 public fixedWhitelistRatio = 100;
    uint256 public whiteListfloorLimit;

    address public teamRewardSc;
    address public releaseSc;

    mapping (uint256=>PoolMineInfo) public poolmineinfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;// Info of each user that stakes LP tokens.

    PoolInfo[] poolInfo;   // Info of each pool.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 public BaseBoostTokenAmount = 1000 ether;
    uint256 public BaseIncreaseRatio = 30; //3%

    uint256 public RatioIncreaseStep = 10;// 1%
    uint256 public BoostTokenAmountStepAmount = 1000 ether;

    address public smelt;
    uint256 internal totalsupply;
    mapping(address => uint256) internal balances;

    address public tokenFarm;

}

// File: contracts/defrostBoostFarm/defrostBoostFarm.sol

pragma solidity ^0.5.16;






interface ITeamRewardSC {
    function inputTeamReward(uint256 _amount) external;
}

interface IReleaseSC {
    function releaseToken(address account,uint256 amount) external;
    function getClaimAbleBalance(address account) external view returns (uint256);
    function dispatchTimes() external view returns (uint256);
    function lockedBalanceOf(address account) external view returns(uint256);
    function userFarmClaimedBalances(address account) external view returns (uint256);
}

interface ITokenFarmSC {
    function stake(address account) external;
    function unstake(address account) external;
    function getReward(address account) external;
    function earned(address account)  external view returns(uint256);
    function getMineInfo() external view returns (uint256,uint256);
}


interface IChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
   // function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function pendingTokens(uint256 _pid, address _user)  external view returns (uint256,address,string memory,uint256);

    function joe() external view returns (address);
    function joePerSec() external view returns (uint256);

    function poolInfo(uint256) external  view returns ( address lpToken, uint256 allocPoint, uint256 lastRewardTime, uint256 accJoePerShare);
    function poolLength() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);
    function withdraw(uint256 _pid, uint256 _amount) external;
}


contract DefrostFarm is defrostBoostFarmStorage,proxyOwner{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event QuitDefrostReward(address to, uint256 amount);
    event QuitExtReward(address extFarmAddr, address rewardToken, address to, uint256 amount);
    event UpdatePoolInfo(uint256 pid, uint256 bonusEndBlock, uint256 rewardPerBlock);
    event WithdrawDefrostReward(address to, uint256 amount);
    event DoubleFarmingEnable(uint256 pid, bool flag);
    event SetExtFarm(uint256 pid, address extFarmAddr, uint256 extPid );
    event EmergencyWithdraw(uint256 indexed pid);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event GetBackLeftRewardToken(address to, uint256 amount);

    event BoostDeposit(address indexed user,  uint256 amount);
    event BoostWithdraw(address indexed user, uint256 amount);

    constructor(address _multiSignature,address _origin0,address _origin1)
        proxyOwner(_multiSignature,_origin0,_origin1)
        public
    {

    }

    function getPoolInfo(uint256 _pid) external view returns (
        address lpToken,         // Address of LP token contract.
        uint256 currentSupply,    //
        uint256 bonusStartBlock,  //
        uint256 newStartBlock,    //
        uint256 bonusEndBlock,    // Block number when bonus defrost period ends.
        uint256 lastRewardBlock,  // Last block number that defrost distribution occurs.
        uint256 accRewardPerShare,// Accumulated defrost per share, times 1e12. See below.
        uint256 rewardPerBlock,   // defrost tokens created per block.
        uint256 totalDebtReward) {

        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        return (
            address(pool.lpToken),
            pool.currentSupply,
            pool.bonusStartBlock,
            pool.newStartBlock,
            pool.bonusEndBlock,
            pool.lastRewardBlock,
            pool.accRewardPerShare,
            pool.rewardPerBlock,
            pool.totalDebtReward
            );

    }
    
//    function getExtFarmInfo(uint256 _pid) external view returns (
//		address extFarmAddr,
//        bool extEnableDeposit,
//        uint256 extPid,
//        uint256 extRewardPerShare,
//        uint256 extTotalDebtReward,
//        bool extEnableClaim,
//        uint256 extAccPerShare){
//
//        require(_pid < poolInfo.length,"pid >= poolInfo.length");
//        PoolInfo storage pool = poolInfo[_pid];
//
//        return (
//            pool.extFarmInfo.extFarmAddr,
//            pool.extFarmInfo.extEnableDeposit,
//            pool.extFarmInfo.extPid,
//            pool.extFarmInfo.extRewardPerShare,
//            pool.extFarmInfo.extTotalDebtReward,
//            pool.extFarmInfo.extEnableClaim,
//            pool.extFarmInfo.extRewardPerShare);
//
//    }

//    function poolLength() external view returns (uint256) {
//        return poolInfo.length;
//    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(address _lpToken,
                 uint256 _bonusStartTime,
                 uint256 _bonusEndBlock,
                 uint256 _rewardPerBlock,
                 uint256 _totalMineReward,
                 uint256 _duration,
                 uint256 _secPerBlk
             ) public onlyOrigin {

        require(block.number < _bonusEndBlock, "block.number >= bonusEndBlock");
        //require(_bonusStartBlock < _bonusEndBlock, "_bonusStartBlock >= _bonusEndBlock");
        require(block.timestamp<_bonusStartTime,"start time is earlier than current time");
        //estimate entime
        uint256 endTime = block.timestamp.add((_bonusEndBlock.sub(block.number)).mul(_secPerBlk));
        require(_bonusStartTime<endTime,"estimate end time is early than start time");

        require(address(_lpToken) != address(0), "_lpToken == 0");

        //uint256 lastRewardBlock = block.number > _bonusStartBlock ? block.number : _bonusStartBlock;

        ExtFarmInfo memory extFarmInfo = ExtFarmInfo({
                extFarmAddr:address(0x0),
                extEnableDeposit:false,
                extPid: 0,
                extRewardPerShare: 0,
                extTotalDebtReward:0,
                extEnableClaim:false
                });


        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            currentSupply: 0,
            bonusStartBlock: 0,
            newStartBlock: 0,
            bonusEndBlock: _bonusEndBlock,
            lastRewardBlock: 0,
            accRewardPerShare: 0,
            rewardPerBlock: _rewardPerBlock,
            totalDebtReward: 0,
            bonusStartTime: _bonusStartTime,
            extFarmInfo:extFarmInfo
        }));


        PoolMineInfo memory pmi = PoolMineInfo({
            totalMineReward: _totalMineReward,
            duration:_duration
        });

        poolmineinfo[poolInfo.length-1] = pmi;
    }

    function updatePoolInfo(uint256 _pid,
                            uint256 _bonusEndBlock,
                            uint256 _rewardPerBlock,
                            uint256 _totalMineReward,
                            uint256 _duration)
            public
            onlyOrigin
    {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        require(_bonusEndBlock > block.number, "_bonusEndBlock <= block.number");
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.bonusEndBlock <= block.number){
            pool.newStartBlock = block.number;
        }

        pool.bonusEndBlock = _bonusEndBlock;
        pool.rewardPerBlock = _rewardPerBlock;
        //keep it to later show
        poolmineinfo[_pid].totalMineReward = _totalMineReward;
        poolmineinfo[_pid].duration=_duration;

        emit UpdatePoolInfo(_pid, _bonusEndBlock, _rewardPerBlock);
    }

    function getMultiplier(uint256 _pid) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if(block.number <= pool.bonusStartBlock){
            return 0;// no begin
        }

        if(pool.lastRewardBlock >= pool.bonusEndBlock){
            return 0;// ended
        }

        if(block.number >= pool.bonusEndBlock){
            // ended, but no update, lastRewardBlock < bonusEndBlock
            return pool.bonusEndBlock.sub(pool.lastRewardBlock);
        }

        return block.number.sub(pool.lastRewardBlock);
    }

    // View function to see pending defrost on frontend.
    function pendingDefrostReward(uint256 _pid, address _user) public view returns (uint256,uint256) {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (block.number > pool.lastRewardBlock && pool.currentSupply != 0) {
            uint256 multiplier = getMultiplier(_pid);
            uint256 reward = multiplier.mul(pool.rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(pool.currentSupply));
        }


        // return (user.amount, user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt));//orginal
       uint256 pendingReward = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);

       (pendingReward,) = getUserRewardAndTeamReward(_pid,_user,pendingReward);

       return (user.amount,pendingReward);

    }

    /////////////////////////////////////////////////////////////////////////////////////////
    function totalUnclaimedExtFarmReward(address extFarmAddr) public view returns(uint256){
        
        uint256 allTotalUnclaimed = 0;

        for (uint256 index = 0; index < poolInfo.length; index++) {
            PoolInfo storage pool = poolInfo[index];

            if(pool.extFarmInfo.extFarmAddr == address(0x0) || pool.extFarmInfo.extFarmAddr != extFarmAddr) continue;

            allTotalUnclaimed = pool.currentSupply.mul(pool.extFarmInfo.extRewardPerShare).div(1e12).sub(pool.extFarmInfo.extTotalDebtReward).add(allTotalUnclaimed);

        }

        return allTotalUnclaimed;
    }

    function distributeFinalExtReward(uint256 _pid, uint256 _amount) public onlyOrigin {

        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.extFarmInfo.extFarmAddr != address(0x0),"pool not supports double farming");

        uint256 allUnClaimedExtReward = totalUnclaimedExtFarmReward(pool.extFarmInfo.extFarmAddr);

        uint256 extRewardCurrentBalance = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this));

        uint256 maxDistribute = extRewardCurrentBalance.sub(allUnClaimedExtReward);

        require(_amount <= maxDistribute,"distibute too much external rewards");

        pool.extFarmInfo.extRewardPerShare = _amount.mul(1e12).div(pool.currentSupply).add(pool.extFarmInfo.extRewardPerShare);
    }

    function getExtFarmRewardRate(IChef chef,IERC20 lpToken, uint256 extPid) internal view returns(uint256 rate){
//        uint256 multiplier = chef.getMultiplier(block.number-1, block.number);

        uint256 extRewardPerBlock = chef.joePerSec();

        (,uint256 allocPoint,uint256 lastRewardTimestamp,) = chef.poolInfo(extPid);
        //changed according joe
        uint256 multiplier = block.timestamp.sub(lastRewardTimestamp);

        uint256 totalAllocPoint = chef.totalAllocPoint();
        uint256 totalSupply = lpToken.balanceOf(address(chef));

        rate = multiplier.mul(extRewardPerBlock).mul(allocPoint).mul(1e12).div(totalAllocPoint).div(totalSupply);
    }

    function extRewardPerBlock(uint256 _pid) public view returns(uint256) {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];

        if(!pool.extFarmInfo.extEnableDeposit) return 0;

        IChef chef = IChef(pool.extFarmInfo.extFarmAddr);
        uint256 rate = getExtFarmRewardRate(chef, IERC20(pool.lpToken),pool.extFarmInfo.extPid);
        (uint256 amount,) = chef.userInfo(_pid,address(this));
        uint256 extReward = rate.mul(amount).div(1e12);

        return extReward;
    }

    function allPendingReward(uint256 _pid,address _user) public view returns(uint256,uint256,uint256){
        uint256 depositAmount;
        uint256 deFrostReward;
        uint256 joeReward;
        
       (depositAmount, deFrostReward) = pendingDefrostReward(_pid,_user);
        joeReward = pendingExtReward(_pid,_user);
        
        return (depositAmount, deFrostReward, joeReward);
    }

    function enableDoubleFarming(uint256 _pid, bool enable) public onlyOrigin {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];

        require(pool.extFarmInfo.extFarmAddr != address(0x0),"pool not supports double farming yet");
        if(pool.extFarmInfo.extEnableDeposit != enable){

            uint256 oldJoeRewarad = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this));

            if(enable){
                IERC20(pool.lpToken).approve(pool.extFarmInfo.extFarmAddr,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                if(pool.currentSupply > 0) {
                    IChef(pool.extFarmInfo.extFarmAddr).deposit(pool.extFarmInfo.extPid,pool.currentSupply);
                }

                pool.extFarmInfo.extEnableClaim = true;

            }else{
                IERC20(pool.lpToken).approve(pool.extFarmInfo.extFarmAddr,0);
                (uint256 amount,) = IChef(pool.extFarmInfo.extFarmAddr).userInfo(pool.extFarmInfo.extPid,address(this));
                if(amount > 0){
                    IChef(pool.extFarmInfo.extFarmAddr).withdraw(pool.extFarmInfo.extPid,amount);
                }
            }

            if(pool.currentSupply > 0){
                uint256 deltaJoeReward = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this)).sub(oldJoeRewarad);

                pool.extFarmInfo.extRewardPerShare = deltaJoeReward.mul(1e12).div(pool.currentSupply).add(pool.extFarmInfo.extRewardPerShare);
            }

            pool.extFarmInfo.extEnableDeposit = enable;

            emit DoubleFarmingEnable(_pid,enable);
        }

    }

    function setDoubleFarming(uint256 _pid,address extFarmAddr,uint256 _extPid) public onlyOrigin {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        require(extFarmAddr != address(0x0),"extFarmAddr == 0x0");
        PoolInfo storage pool = poolInfo[_pid];

       // require(pool.extFarmInfo.extFarmAddr == address(0x0),"cannot set extFramAddr again");

        uint256 extPoolLength = IChef(extFarmAddr).poolLength();
        require(_extPid < extPoolLength,"bad _extPid");

        (address lpToken,,,) = IChef(extFarmAddr).poolInfo(_extPid);
        require(lpToken == address(pool.lpToken),"pool mismatch between deFrostFarm and extFarm");

        pool.extFarmInfo.extFarmAddr = extFarmAddr;
        pool.extFarmInfo.extPid = _extPid;

        emit SetExtFarm(_pid, extFarmAddr, _extPid);

    }

    function disableExtEnableClaim(uint256 _pid)public onlyOrigin {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];

        require(pool.extFarmInfo.extEnableDeposit == false, "can only disable extEnableClaim when extEnableDeposit is disabled");

        pool.extFarmInfo.extEnableClaim = false;
    }

    function pendingExtReward(uint256 _pid, address _user) public view returns(uint256){
        require(_pid < poolInfo.length,"pid >= poolInfo.length");

        PoolInfo storage pool = poolInfo[_pid];
        if(pool.extFarmInfo.extFarmAddr == address(0x0)){
            return 0;
        }

        if(pool.currentSupply <= 0) return 0;

        UserInfo storage user = userInfo[_pid][_user];
        if(user.amount <= 0) return 0;

        uint256 extRewardPerShare = pool.extFarmInfo.extRewardPerShare;

        if(pool.extFarmInfo.extEnableDeposit){
            (uint256 totalPendingJoe,,,) = IChef(pool.extFarmInfo.extFarmAddr).pendingTokens(pool.extFarmInfo.extPid,address(this));
            extRewardPerShare = totalPendingJoe.mul(1e12).div(pool.currentSupply).add(extRewardPerShare);
        }

        uint256 userPendingJoe = user.amount.mul(extRewardPerShare).div(1e12).sub(user.extRewardDebt);

        return userPendingJoe;
    }

    function depositLPToChef(uint256 _pid,uint256 _amount) internal {
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];

        if(pool.extFarmInfo.extFarmAddr == address(0x0)) return;

        UserInfo storage user =  userInfo[_pid][msg.sender];

        if(pool.extFarmInfo.extEnableDeposit){

            uint256 oldJoeRewarad = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this));
            uint256 oldTotalDeposit = pool.currentSupply.sub(_amount);

            IChef(pool.extFarmInfo.extFarmAddr).deposit(pool.extFarmInfo.extPid, _amount);

            uint256 deltaJoeReward = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this));
            deltaJoeReward = deltaJoeReward.sub(oldJoeRewarad);

            if(oldTotalDeposit > 0 && deltaJoeReward > 0){
                pool.extFarmInfo.extRewardPerShare = deltaJoeReward.mul(1e12).div(oldTotalDeposit).add(pool.extFarmInfo.extRewardPerShare);
            }

        }

        if(pool.extFarmInfo.extEnableClaim) {
            uint256 transferJoeAmount = user.amount.sub(_amount).mul(pool.extFarmInfo.extRewardPerShare).div(1e12).sub(user.extRewardDebt);

            if(transferJoeAmount > 0){
                address JoeToken = IChef(pool.extFarmInfo.extFarmAddr).joe();
                IERC20(JoeToken).safeTransfer(msg.sender,transferJoeAmount);
            }
        }

        pool.extFarmInfo.extTotalDebtReward = pool.extFarmInfo.extTotalDebtReward.sub(user.extRewardDebt);
        user.extRewardDebt = user.amount.mul(pool.extFarmInfo.extRewardPerShare).div(1e12);
        pool.extFarmInfo.extTotalDebtReward = pool.extFarmInfo.extTotalDebtReward.add(user.extRewardDebt);

    }

    function withDrawLPFromExt(uint256 _pid,uint256 _amount) internal{
        require(_pid < poolInfo.length,"pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user =  userInfo[_pid][msg.sender];

        if(pool.extFarmInfo.extFarmAddr == address(0x0)) return;

        if(pool.extFarmInfo.extEnableDeposit){

            require(user.amount >= _amount,"withdraw too much lpToken");

            uint256 oldJoeRewarad = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this));
            uint256 oldTotalDeposit = pool.currentSupply;

            IChef(pool.extFarmInfo.extFarmAddr).withdraw(pool.extFarmInfo.extPid, _amount);

            uint256 deltaJoeReward = IERC20(IChef(pool.extFarmInfo.extFarmAddr).joe()).balanceOf(address(this)).sub(oldJoeRewarad);
            if(oldTotalDeposit > 0 && deltaJoeReward > 0)
                pool.extFarmInfo.extRewardPerShare = deltaJoeReward.mul(1e12).div(oldTotalDeposit).add(pool.extFarmInfo.extRewardPerShare);

        }

        if(pool.extFarmInfo.extEnableClaim) {
            uint256 transferJoeAmount = user.amount.mul(pool.extFarmInfo.extRewardPerShare).div(1e12).sub(user.extRewardDebt);

            if(transferJoeAmount > 0){
                address JoeToken = IChef(pool.extFarmInfo.extFarmAddr).joe();
                IERC20(JoeToken).safeTransfer(msg.sender, transferJoeAmount);
            }
        }

        pool.extFarmInfo.extTotalDebtReward = pool.extFarmInfo.extTotalDebtReward.sub(user.extRewardDebt);
        user.extRewardDebt = user.amount.sub(_amount).mul(pool.extFarmInfo.extRewardPerShare).div(1e12);
        pool.extFarmInfo.extTotalDebtReward = pool.extFarmInfo.extTotalDebtReward.add(user.extRewardDebt);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.currentSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(_pid);
        uint256 reward = multiplier.mul(pool.rewardPerBlock);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(pool.currentSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for defrost reward allocation.
    function deposit(uint256 _pid, uint256 _amount) public  notHalted nonReentrant {
        require(_pid < poolInfo.length, "pid >= poolInfo.length");

        PoolInfo storage pool = poolInfo[_pid];
        //to set start block number at init start
        require(block.timestamp>pool.bonusStartTime,"not reach start time for farming");
        if(pool.bonusStartBlock==0
           &&pool.newStartBlock==0
           &&pool.lastRewardBlock==0) {
            pool.bonusStartBlock = block.number;
            pool.newStartBlock = block.number;
            pool.lastRewardBlock = block.number;
        }

        //move to here
        updatePool(_pid);

        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
               mintUserRewardAndTeamReward(_pid,msg.sender,pending);
            }
        }

        if(_amount > 0) {
            IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.currentSupply = pool.currentSupply.add(_amount);
        }


        // must excute after lpToken has beem transfered from user to this contract and the amount of user depoisted is updated.
        depositLPToChef(_pid,_amount);
            
        pool.totalDebtReward = pool.totalDebtReward.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.totalDebtReward = pool.totalDebtReward.add(user.rewardDebt);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public notHalted nonReentrant {
        require(_pid < poolInfo.length, "pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        withDrawLPFromExt(_pid,_amount);

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);

        if(pending > 0) {
            mintUserRewardAndTeamReward(_pid,msg.sender,pending);
        }

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.currentSupply = pool.currentSupply.sub(_amount);
            IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        }

        pool.totalDebtReward = pool.totalDebtReward.sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.totalDebtReward = pool.totalDebtReward.add(user.rewardDebt);

        emit Withdraw(msg.sender, _pid, _amount);
    }


    function emergencyWithdrawExtLp(uint256 _pid) public onlyOrigin {
        require(_pid < poolInfo.length, "pid >= poolInfo.length");
        PoolInfo storage pool = poolInfo[_pid];

        if(pool.extFarmInfo.extFarmAddr == address(0x0)) return;

        IChef(pool.extFarmInfo.extFarmAddr).emergencyWithdraw(pool.extFarmInfo.extPid);

        pool.extFarmInfo.extEnableDeposit = false;            

        emit EmergencyWithdraw(_pid);
    }

    // Safe defrost transfer function, just in case if rounding error causes pool to not have enough defrost reward.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
        if (_amount > rewardBal) {
            IERC20(rewardToken).safeTransfer(_to, rewardBal);
        } else {
            IERC20(rewardToken).safeTransfer(_to, _amount);
        }
    }

    function quitDefrostFarm(address _to) public onlyOrigin {
        require(_to != address(0), "_to == 0");
        uint256 rewardTokenBal = IERC20(rewardToken).balanceOf(address(this));
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(block.number > pool.bonusEndBlock, "quitPhx block.number <= pid.bonusEndBlock");
            updatePool(pid);
            uint256 reward = pool.currentSupply.mul(pool.accRewardPerShare).div(1e12).sub(pool.totalDebtReward);
            rewardTokenBal = rewardTokenBal.sub(reward);
        }
        safeRewardTransfer(_to, rewardTokenBal);
        emit QuitDefrostReward(_to, rewardTokenBal);
    }

    function quitExtFarm(address extFarmAddr, address _to) public onlyOrigin {

        IERC20 joeToken = IERC20(IChef(extFarmAddr).joe());

        uint256 joeBalance = joeToken.balanceOf(address(this));

        uint256 totalUnclaimedReward = totalUnclaimedExtFarmReward(extFarmAddr);

        require(totalUnclaimedReward <= joeBalance, "extreward shortage");

        uint256 quitBalance = joeBalance.sub(totalUnclaimedReward);

        joeToken.safeTransfer(_to, quitBalance);

        emit QuitExtReward(extFarmAddr,address(joeToken),_to, quitBalance);
    }

    function getBackLeftRewardToken(address _to) public onlyOrigin {
        uint256 rewardTokenBal = IERC20(rewardToken).balanceOf(address(this));
        safeRewardTransfer(_to, rewardTokenBal);
        emit GetBackLeftRewardToken(_to, rewardTokenBal);
    }

    function setDefrostAddress( address _rewardToken,
                                address _oracle,
                                address _h2o,
                                address _teamRewardSc,
                                address _releaseSc,
                                address _tokenFarm,
                                address _smelt)
        public onlyOrigin
    {
        require(_rewardToken!=address(0),"_rewardToken address is 0");
        require(_oracle!=address(0),"_rewardToken address is 0");
        require(_teamRewardSc!=address(0),"_rewardToken address is 0");
        require(_releaseSc!=address(0),"_rewardToken address is 0");

        require(_tokenFarm!=address(0),"_tokenFarm address is 0");
        require(_smelt!=address(0),"_smelt address is 0");

        rewardToken = _rewardToken;
        oracle = _oracle;
        h2o = _h2o;
        teamRewardSc = _teamRewardSc;
        releaseSc = _releaseSc;

        /////////////////////////////////////////////////////
        tokenFarm = _tokenFarm;
        smelt = _smelt;
        IERC20(h2o).approve(address(tokenFarm),uint256(-1));
    }

    function totalStaked(uint256 _pid) public view returns (uint256){
        require(_pid < poolInfo.length,"pid >= poolInfo.length");

        PoolInfo storage pool = poolInfo[_pid];
        return pool.currentSupply;
    }

    function getMineInfo(uint256 _pid) public view returns (uint256,uint256,uint256,uint256,uint256) {
        return (poolmineinfo[_pid].totalMineReward,poolmineinfo[_pid].duration,
           poolInfo[_pid].bonusStartBlock,poolInfo[_pid].rewardPerBlock,poolInfo[_pid].bonusStartTime);
    }

////////////////////////////////////////////////////////////////////////////////////////////////

    function setFixedTeamRatio(uint256 _ratio)
        public onlyOrigin
    {
        fixedTeamRatio = _ratio;
    }

    function setFixedWhitelistPara(uint256 _incRatio,uint256 _whiteListfloorLimit)
       public onlyOrigin
    {
        //_incRatio,0 whiteList increase will stop
        fixedWhitelistRatio = _incRatio;
        whiteListfloorLimit = _whiteListfloorLimit;
    }

    function setWhiteList(address[] memory _user)
        public onlyOrigin
    {
        require(_user.length>0,"array length is 0");
        for(uint256 i=0;i<_user.length;i++) {
            whiteListLpUserInfo[_user[i]] = true;
        }
    }

    function setWhiteListMemberStatus(address _user,bool _status)
        public onlyOrigin
    {
        whiteListLpUserInfo[_user] = _status;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////

    function getUserRewardAndTeamReward(uint256 _pid,address _user, uint256 _reward)
            public view returns(uint256,uint256)
    {
        uint256 userIncRatio = RATIO_DENOM;

        UserInfo storage user = userInfo[_pid][_user];
        //current stake must be over minimum require lp amount
        if (whiteListLpUserInfo[_user]&&user.amount >= whiteListfloorLimit) {
            userIncRatio = userIncRatio.add(fixedWhitelistRatio);
        }

        uint256 userRward = _reward.mul(userIncRatio).div(RATIO_DENOM);

        //boost user balance;
        uint256 userBoostFactor = getUserBoostFactor(balances[_user]);
        userRward = userRward.mul(userBoostFactor).div(RATIO_DENOM);

        //get team reward
        uint256 teamReward = userRward.mul(fixedTeamRatio).div(RATIO_DENOM);

        //get user reward
        userRward = userRward.sub(teamReward);

        return (userRward,teamReward);
    }

    function mintUserRewardAndTeamReward(uint256 _pid,address _user, uint256 _reward) internal {

        uint256 userRward = 0;
        uint256 teamReward = 0;

        (userRward,teamReward) = getUserRewardAndTeamReward(_pid,_user,_reward);

        if(teamReward>0) {
            IERC20(rewardToken).approve(teamRewardSc,teamReward);
            ITeamRewardSC(teamRewardSc).inputTeamReward(teamReward);
        }

        IERC20(rewardToken).approve(releaseSc,userRward);
        IReleaseSC(releaseSc).releaseToken(_user,userRward);
    }

    //function lockedBalanceOf(address account) external view returns(uint256);
   // function userFarmClaimedBalances(address account) external view returns (uint256);

    function getRewardInfo(uint256 _pid,address _user)  public view returns(uint256,uint256,uint256,uint256,uint256) {
        uint256 depositAmount;
        uint256 deFrostReward;
        uint256 joeReward;

        (depositAmount,deFrostReward,joeReward) = allPendingReward(_pid,_user);

        uint256 distimes = IReleaseSC(releaseSc).dispatchTimes();

        uint256 claimable = deFrostReward.div(distimes);
        uint256 locked = IReleaseSC(releaseSc).lockedBalanceOf(_user);
        locked = locked.add(deFrostReward.sub(claimable));

        claimable = claimable.add(IReleaseSC(releaseSc).getClaimAbleBalance(_user));

        uint256 claimed = IReleaseSC(releaseSc).userFarmClaimedBalances(_user);

        return (depositAmount,claimable,locked,claimed,joeReward);
    }
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setBoostFarmFactorPara(uint256 _BaseBoostTokenAmount,uint256 _BaseIncreaseRatio,uint256 _BoostTokenAmountStepAmount,uint256 _RatioIncreaseStep)
        external
        onlyOrigin
    {
        BaseBoostTokenAmount = _BaseBoostTokenAmount;
        BaseIncreaseRatio = _BaseIncreaseRatio; //3%

        RatioIncreaseStep = _RatioIncreaseStep;// 1%
        BoostTokenAmountStepAmount = _BoostTokenAmountStepAmount;
    }

    function boostDeposit(uint256 _pid,uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.timestamp>pool.bonusStartTime,"not reach start time for farming");

        withdraw(_pid,0);

        ITokenFarmSC(tokenFarm).getReward(msg.sender);

        IERC20(smelt).safeTransferFrom(msg.sender,address(this), _amount);

        totalsupply = totalsupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);   

        emit BoostDeposit(msg.sender,_amount);
    }

    function boostwithdraw(uint256 _pid,uint256 _amount) external{

        withdraw(_pid,0);

        ITokenFarmSC(tokenFarm).getReward(msg.sender);

        totalsupply = totalsupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        IERC20(smelt).safeTransfer(msg.sender, _amount);

        emit BoostWithdraw(msg.sender, _amount);

    }

    function getUserBoostFactor(uint256 _amount)
        public view returns(uint256)
    {

        if(_amount<BaseBoostTokenAmount) {
            return RATIO_DENOM;
        } else {
            uint256 ratio = (_amount.sub(BaseBoostTokenAmount).div(BoostTokenAmountStepAmount)).mul(RatioIncreaseStep);//no decimal,just integer multiple
            return RATIO_DENOM.add(BaseIncreaseRatio).add(ratio);
        }
    }

    function boostStakedFor(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function boostPendingReward(address _account) public view returns(uint256){
        return ITokenFarmSC(tokenFarm).earned(_account);
    }

    function boostTotalStaked() public view returns (uint256){
        return totalsupply;
    }

    function getBoostMineInfo() public view returns (uint256,uint256) {
        return ITokenFarmSC(tokenFarm).getMineInfo();
    }

    function balanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function totalSupply() external view returns (uint256){
        return totalsupply;
    }

}