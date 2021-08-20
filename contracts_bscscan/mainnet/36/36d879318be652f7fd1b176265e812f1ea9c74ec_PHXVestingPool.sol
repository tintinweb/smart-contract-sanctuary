/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// File: contracts/PhoenixModules/multiSignature/multiSignatureClient.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.Phoenix.multiSignature.storage"));
    event DebugEvent(address indexed from,bytes32 msgHash,uint256 value,uint256 value1);
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
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// File: contracts/PhoenixModules/proxyModules/proxyOwner.sol

pragma solidity =0.5.16;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant ownerExpiredPosition = keccak256("org.Phoenix.ownerExpired.storage");
    bytes32 private constant versionPositon = keccak256("org.Phoenix.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Phoenix.Owner.storage");
    bytes32 private constant proxyOriginPosition  = keccak256("org.Phoenix.Origin.storage");
    uint256 private constant oncePosition  = uint256(keccak256("org.Phoenix.Once.storage"));
    uint256 private constant ownerExpired =  90 days;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature) multiSignatureClient(multiSignature) public{
        _setProxyOwner(msg.sender);
        _setProxyOrigin(tx.origin);
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
        position = ownerExpiredPosition;
        uint256 expired = now+ownerExpired;
        assembly {
            sstore(position, expired)
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
    function transferOrigin(address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_newOrigin);
    }
    function _setProxyOrigin(address _newOrigin) internal 
    {
        emit OriginTransferred(txOrigin(),_newOrigin);
        bytes32 position = proxyOriginPosition;
        assembly {
            sstore(position, _newOrigin)
        }
    }
    function txOrigin() public view returns (address _origin) {
        bytes32 position = proxyOriginPosition;
        assembly {
            _origin := sload(position)
        }
    }
    function ownerExpiredTime() public view returns (uint256 _expired) {
        bytes32 position = ownerExpiredPosition;
        assembly {
            _expired := sload(position)
        }
    }
    modifier originOnce() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(msg.sender == txOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    function _setVersion(uint256 version_) internal 
    {
        bytes32 position = versionPositon;
        assembly {
            sstore(position, version_)
        }
    }
    function version() public view returns(uint256 version_){
        bytes32 position = versionPositon;
        assembly {
            version_ := sload(position)
        }
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

// File: contracts/PhoenixModules/proxyModules/initializable.sol

pragma solidity =0.5.16;
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract initializable {

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

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;
        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        assembly { cs := extcodesize(address) }
        return cs == 0;
    }

}

// File: contracts/PhoenixModules/proxyModules/versionUpdater.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */


contract versionUpdater is proxyOwner,initializable {
    function implementationVersion() public pure returns (uint256);
    function initialize() public initializer versionUpdate {

    }
    modifier versionUpdate(){
        require(implementationVersion() > version() &&  ownerExpiredTime()>now,"New version implementation is already updated!");
        _;
    }
}

// File: contracts/PhoenixModules/proxyModules/timeLimitation.sol

pragma solidity =0.5.16;


contract timeLimitation is proxyOwner {
    
    /**
     * @dev PPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn PPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    struct addressInfo {
        uint128 time;
        bool bIgnoreFrom;
        bool bIgnoreTo;
    }
    mapping(address=>addressInfo) internal addressTimeMap;
    uint256 public limitation;
    /**
     * @dev set time limitation, only owner can invoke. 
     * @param _limitation new time limitation.
     */ 
    function setTimeLimitation(uint256 _limitation) public OwnerOrOrigin {
        limitation = _limitation;
    }
    function getAccountInfo(address account) public view returns(bool,bool){
        return (addressTimeMap[account].bIgnoreFrom,addressTimeMap[account].bIgnoreTo);
    }
    function setAccountInfo(address account,bool bIgnoreFrom,bool bIgnoreTo) public OwnerOrOrigin{
        addressTimeMap[account].bIgnoreFrom = bIgnoreFrom;
        addressTimeMap[account].bIgnoreTo = bIgnoreTo;
    }
    function setTransferTimeLimitation(address from,address to) internal{
        if (!addressTimeMap[from].bIgnoreFrom && !addressTimeMap[to].bIgnoreTo){
            addressTimeMap[to].time = uint128(now);
        }
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param account user's account.
     */ 
    function getTimeLimitation(address account) public view returns (uint256){
        return addressTimeMap[account].time+limitation;
    }
    modifier OutLimitation(address account) {
        require(addressTimeMap[account].time+limitation<now,"Time limitation is not expired!");
        _;
    }    
}

// File: contracts/PhoenixModules/proxyModules/Halt.sol

pragma solidity =0.5.16;


contract Halt is proxyOwner {
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
        onlyOrigin
    {
        halted = halt;
    }
}

// File: contracts/PhoenixModules/ERC20/IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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

// File: contracts/PhoenixModules/modules/SafeMath.sol

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
    uint256 constant internal calDecimal = 1e18; 
    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }
    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}

// File: contracts/PhoenixModules/modules/Address.sol

pragma solidity =0.5.16;

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

// File: contracts/PhoenixModules/ERC20/safeErc20.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/PhoenixModules/modules/safeTransfer.sol

pragma solidity =0.5.16;

contract safeTransfer{
    using SafeERC20 for IERC20;
    event Redeem(address indexed recieptor,address indexed token,uint256 amount);
    function getPayableAmount(address token,uint256 amount) internal returns (uint256) {
        if (token == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(token);
            oToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        return amount;
    }
    /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param token token address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address token,uint256 amount) internal{
        if (token == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 oToken = IERC20(token);
            oToken.safeTransfer(recieptor,amount);
        }
        emit Redeem(recieptor,token,amount);
    }
}

// File: contracts/PhoenixModules/modules/ReentrancyGuard.sol

pragma solidity =0.5.16;
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

// File: contracts/PhoenixModules/PHXVestingPool/PHXVestingPoolData.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */





contract PHXVestingPoolData is Halt,timeLimitation,ReentrancyGuard,versionUpdater,safeTransfer{
    uint256 constant internal currentVersion = 3;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 constant internal mineBoostingAmount = 500e18; 
    uint256 constant internal rateDecimals = 1e8;
    address[] public vestTokens;
    mapping(address=>uint256) public vestingTokenRate;
    struct userAcceleratorInfo {
        uint256 vestingTokenBalance;
        //Period ID start at 1. if a PeriodID equals zero, it means your PHX is flexible staked.
        //User's max locked period id;
        uint64 maxPeriodID;
        //User's max locked period timestamp. Flexible PHX is locked _flexibleExpired seconds;
        uint128 lockedExpired;
        mapping(address=>uint256) tokenBalance;
        mapping(address=>uint256) acceleratedBalance;
    }
    mapping(address=>userAcceleratorInfo) public userInfoMap;
    address[] minePoolList;
    uint256 public maxPeriodLimit;
    uint256 public period;
    uint256 public startTime;
    event Stake(address indexed sender,address indexed token,address indexed toMinePool,uint256 amount,uint256 maxPeriod);
    event Unstake(address indexed sender,address indexed token,uint256 amount);
    event ChangePeriod(address indexed sender,uint256 maxPeriod);
    event TransferStake(address indexed sender,address indexed fromMinePool,address indexed toMinePool,uint256 maxPeriod);
    event BoostingMinePool(address indexed sender,address indexed toMinePool,uint256 amount,uint256 maxPeriod);
    event WithdrawMinePool(address indexed sender,address indexed fromMinePool,uint256 amount,uint256 maxPeriod);
}

// File: contracts/PhoenixModules/acceleratedMinePool/IAcceleratedMinePool.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IAcceleratedMinePool {
    function setPHXVestingPool(address _accelerator) external;
    function changeAcceleratedInfo(address account,uint256[] calldata newRates,uint256 maxLockedPeriod) external;
    function transferPPTCoin(address account,address recieptor) external;
    function changePPTStake(address account) external;
}

// File: contracts/PhoenixModules/modules/whiteListAddress.sol

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */

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

// File: contracts/PhoenixModules/modules/SmallNumbers.sol

pragma solidity =0.5.16;
    /**
     * @dev Implementation of a Fraction number operation library.
     */
library SmallNumbers {
//    using Fraction for fractionNumber;
    int256 constant private sqrtNum = 1<<120;
    int256 constant private shl = 80;
    uint8 constant private PRECISION   = 32;  // fractional bits
    uint256 constant public FIXED_ONE = uint256(1) << PRECISION; // 0x100000000
    int256 constant public FIXED_64 = 1 << 64; // 0x100000000
    uint256 constant private FIXED_TWO = uint256(2) << PRECISION; // 0x200000000
    int256 constant private FIXED_SIX = int256(6) << PRECISION; // 0x200000000
    uint256 constant private MAX_VAL   = uint256(1) << (256 - PRECISION); // 0x0000000100000000000000000000000000000000000000000000000000000000

    /**
     * @dev Standard normal cumulative distribution function
     */
    function normsDist(int256 xNum) internal pure returns (int256) {
        bool _isNeg = xNum<0;
        if (_isNeg) {
            xNum = -xNum;
        }
        if (xNum > FIXED_SIX){
            return _isNeg ? 0 : int256(FIXED_ONE);
        } 
        // constant int256 b1 = 1371733226;
        // constant int256 b2 = -1531429783;
        // constant int256 b3 = 7651389478;
        // constant int256 b4 = -7822234863;
        // constant int256 b5 = 5713485167;
        //t = 1.0/(1.0 + p*x);
        int256 p = 994894385;
        int256 t = FIXED_64/(((p*xNum)>>PRECISION)+int256(FIXED_ONE));
        //double val = 1 - (1/(Math.sqrt(2*Math.PI))  * Math.exp(-1*Math.pow(a, 2)/2)) * (b1*t + b2 * Math.pow(t,2) + b3*Math.pow(t,3) + b4 * Math.pow(t,4) + b5 * Math.pow(t,5) );
        //1.0 - (-x * x / 2.0).exp()/ (2.0*pi()).sqrt() * t * (a1 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429)))) ;
        xNum=xNum*xNum/int256(FIXED_TWO);
        xNum = int256(7359186145390886912/fixedExp(uint256(xNum)));
        int256 tt = t;
        int256 All = 1371733226*tt;
        tt = (tt*t)>>PRECISION;
        All += -1531429783*tt;
        tt = (tt*t)>>PRECISION;
        All += 7651389478*tt;
        tt = (tt*t)>>PRECISION;
        All += -7822234863*tt;
        tt = (tt*t)>>PRECISION;
        All += 5713485167*tt;
        xNum = (xNum*All)>>64;
        if (!_isNeg) {
            xNum = uint64(FIXED_ONE) - xNum;
        }
        return xNum;
    }
    function pow(uint256 _x,uint256 _y) internal pure returns (uint256){
        _x = (ln(_x)*_y)>>PRECISION;
        return fixedExp(_x);
    }

    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        x = x << PRECISION;
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function ln(uint256 _x)  internal pure returns (uint256) {
        return fixedLoge(_x);
    }
        /**
        input range: 
            [0x100000000,uint256_max]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

    */
    function fixedLoge(uint256 _x) internal pure returns (uint256 logE) {
        /*
        Since `fixedLog2_min` output range is max `0xdfffffffff` 
        (40 bits, or 5 bytes), we can use a very large approximation
        for `ln(2)`. This one is used since it’s the max accuracy 
        of Python `ln(2)`

        0xb17217f7d1cf78 = ln(2) * (1 << 56)
        
        */
        //Cannot represent negative numbers (below 1)
        require(_x >= FIXED_ONE,"loge function input is too small");

        uint256 _log2 = fixedLog2(_x);
        logE = (_log2 * 0xb17217f7d1cf78) >> 56;
    }

    /**
        Returns log2(x >> 32) << 32 [1]
        So x is assumed to be already upshifted 32 bits, and 
        the result is also upshifted 32 bits. 
        
        [1] The function returns a number which is lower than the 
        actual value

        input-range : 
            [0x100000000,uint256_max]
        output-range: 
            [0,0xdfffffffff]

        This method asserts outside of bounds

    */
    function fixedLog2(uint256 _x) internal pure returns (uint256) {
        // Numbers below 1 are negative. 
        require( _x >= FIXED_ONE,"Log2 input is too small");

        uint256 hi = 0;
        while (_x >= FIXED_TWO) {
            _x >>= 1;
            hi += FIXED_ONE;
        }

        for (uint8 i = 0; i < PRECISION; ++i) {
            _x = (_x * _x) / FIXED_ONE;
            if (_x >= FIXED_TWO) {
                _x >>= 1;
                hi += uint256(1) << (PRECISION - 1 - i);
            }
        }

        return hi;
    }
    function exp(int256 _x)internal pure returns (uint256){
        bool _isNeg = _x<0;
        if (_isNeg) {
            _x = -_x;
        }
        uint256 value = fixedExp(uint256(_x));
        if (_isNeg){
            return uint256(FIXED_64) / value;
        }
        return value;
    }
    /**
        fixedExp is a ‘protected’ version of `fixedExpUnsafe`, which 
        asserts instead of overflows
    */
    function fixedExp(uint256 _x) internal pure returns (uint256) {
        require(_x <= 0x386bfdba29,"exp function input is overflow");
        return fixedExpUnsafe(_x);
    }
       /**
        fixedExp 
        Calculates e^x according to maclauren summation:

        e^x = 1+x+x^2/2!...+x^n/n!

        and returns e^(x>>32) << 32, that is, upshifted for accuracy

        Input range:
            - Function ok at    <= 242329958953 
            - Function fails at >= 242329958954

        This method is is visible for testcases, but not meant for direct use. 
 
        The values in this method been generated via the following python snippet: 

        def calculateFactorials():
            “”"Method to print out the factorials for fixedExp”“”

            ni = []
            ni.append( 295232799039604140847618609643520000000) # 34!
            ITERATIONS = 34
            for n in range( 1,  ITERATIONS,1 ) :
                ni.append(math.floor(ni[n - 1] / n))
            print( “\n        “.join([“xi = (xi * _x) >> PRECISION;\n        res += xi * %s;” % hex(int(x)) for x in ni]))

    */
    function fixedExpUnsafe(uint256 _x) internal pure returns (uint256) {
    
        uint256 xi = FIXED_ONE;
        uint256 res = 0xde1bc4d19efcac82445da75b00000000 * xi;

        xi = (xi * _x) >> PRECISION;
        res += xi * 0xde1bc4d19efcb0000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x6f0de268cf7e58000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x2504a0cd9a7f72000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9412833669fdc800000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1d9d4d714865f500000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x4ef8ce836bba8c0000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xb481d807d1aa68000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x16903b00fa354d000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x281cdaac677b3400000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x402e2aad725eb80000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x5d5a6c9f31fe24000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x7c7890d442a83000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9931ed540345280000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaf147cf24ce150000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d00000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xafc441338061b8000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9c3cabbc0056e000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x839168328705c80000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x694120286c04a0000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x50319e98b3d2c400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x3a52a1e36b82020;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x289286e0fce002;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x650139600;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x8c40;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x462;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }  
}

// File: contracts/PhoenixModules/PHXVestingPool/PHXVestingPool.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */





contract PHXVestingPool is PHXVestingPoolData{
    using SafeMath for uint256;
    using whiteListAddress for address[];
        /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function initMineLockedInfo(uint256 _startTime,uint256 _periodTime,uint256 _maxPeriodLimit) external originOnce {
        startTime = _startTime;
        period = _periodTime;
        maxPeriodLimit = _maxPeriodLimit;
    }
    function update() external versionUpdate {
    }
    //rate = rateThousandth / 1000;
    function setVestingRate(address token,uint256 rateThousandth) external OwnerOrOrigin {
        vestTokens.addWhiteListAddress(token);
        vestingTokenRate[token] = rateThousandth;
    }
    function removeVestingToken(address token) external OwnerOrOrigin {
        vestTokens.removeWhiteListAddress(token);
        vestingTokenRate[token] = 0;
    }
    function getVestingBalance(address account)external view returns(uint256,uint64){
         return (userInfoMap[account].vestingTokenBalance,userInfoMap[account].maxPeriodID);
    }
    function getVestingTokenBalance(address account,address token)external view returns(uint256){
         return userInfoMap[account].tokenBalance[token];
    }
    function getAcceleratedBalance(address account,address minePool)external view returns(uint256,uint64){
        return (userInfoMap[account].acceleratedBalance[minePool],userInfoMap[account].maxPeriodID);
    }
    function getAcceleratorPeriodInfo()external view returns (uint256,uint256){
        return (startTime,period);
    }
    function airdrop(address token,address[] calldata toAccounts,uint256[] calldata amounts,uint64[] calldata maxLockedPeriods,address toMinePool) 
        nonReentrant notHalted onlyOrigin external{
        require(toAccounts.length == amounts.length && toAccounts.length == maxLockedPeriods.length,"input argments list length is not equal!");
        for (uint256 i=0;i<toAccounts.length;i++){
            _stake(toAccounts[i],token,amounts[i],maxLockedPeriods[i],toMinePool);
        }
    }
    function stake(address token,uint256 amount,uint64 maxLockedPeriod,address toMinePool) nonReentrant notHalted public {
        _stake(msg.sender,token,amount,maxLockedPeriod,toMinePool);
    }
    function _stake(address account,address token,uint256 amount,uint64 maxLockedPeriod,address toMinePool)
         tokenPermission(token) validPeriod(maxLockedPeriod) internal {
        amount = getPayableAmount(token,amount);
        require(amount>0, "Stake amount is zero!");
        uint64 oldPeriod = userInfoMap[account].maxPeriodID;
        uint256 balance = amount.mul(vestingTokenRate[token])/1000;
        userInfoMap[account].vestingTokenBalance  =  userInfoMap[account].vestingTokenBalance.add(balance);
        userInfoMap[account].tokenBalance[token] = userInfoMap[account].tokenBalance[token].add(amount);
        setUserLockedPeriod(account,maxLockedPeriod);
        _accelerateMinePool(account,toMinePool,balance,oldPeriod);
        if (oldPeriod != userInfoMap[account].maxPeriodID){
            uint256 poolLen = minePoolList.length;
            for(uint256 i=0;i<poolLen;i++){
                if (minePoolList[i] != toMinePool){
                    changeAcceleratedInfo(account,minePoolList[i],userInfoMap[account].acceleratedBalance[minePoolList[i]],oldPeriod);
                }
            }
        }        
        emit Stake(account,token,toMinePool,amount,maxLockedPeriod);
    }
    /**
     * @dev Add PHX locked period.
     * @param maxLockedPeriod accelerated locked preiod number.
     */
    function changeStakePeriod(uint64 maxLockedPeriod)public validPeriod(maxLockedPeriod) notHalted{
        require(userInfoMap[msg.sender].vestingTokenBalance > 0, "stake balance is zero");
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        setUserLockedPeriod(msg.sender,maxLockedPeriod);
        if (oldPeriod != userInfoMap[msg.sender].maxPeriodID){
            uint256 poolLen = minePoolList.length;
            for(uint256 i=0;i<poolLen;i++){
                changeAcceleratedInfo(msg.sender,minePoolList[i],userInfoMap[msg.sender].acceleratedBalance[minePoolList[i]],oldPeriod);
            }
            emit ChangePeriod(msg.sender,maxLockedPeriod);
        }
    }
    function unstakeAll()external nonReentrant notHalted periodExpired(msg.sender){
        uint nlen = vestTokens.length;
        for (uint i=0;i<nlen;i++){
            address token = vestTokens[i];
            uint256 amount = userInfoMap[msg.sender].tokenBalance[token];
            if (amount>0){
                _redeem(msg.sender, token, amount);
                emit Unstake(msg.sender,token,amount);
                userInfoMap[msg.sender].tokenBalance[token] = 0;
            }
        }
        userInfoMap[msg.sender].vestingTokenBalance = 0;
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        userInfoMap[msg.sender].maxPeriodID = 0;
        uint256 poolLen = minePoolList.length;
        for(uint256 i=0;i<poolLen;i++){
            address toMinePool = minePoolList[i];
            uint256 amount = userInfoMap[msg.sender].acceleratedBalance[toMinePool];
            userInfoMap[msg.sender].acceleratedBalance[toMinePool] = 0;
            changeAcceleratedInfo(msg.sender,toMinePool,amount,oldPeriod);
        }
    }
    /**
     * @dev withdraw PHX coin.
     * @param amount PHX amount that withdraw from mine pool.
     */
    function unstake(address token,uint256 amount,address toMinePool)public tokenPermission(token) nonReentrant notHalted periodExpired(msg.sender){
        require(amount > 0, 'unstake amount is zero');
        uint256 tokenBalance = userInfoMap[msg.sender].tokenBalance[token];
        require(tokenBalance>= amount,'unstake amount is greater than total user stakes');
        uint64 oldPeriod = userInfoMap[msg.sender].maxPeriodID;
        uint256 balance = amount.mul(vestingTokenRate[token])/1000;
        uint256 oldBalance = userInfoMap[msg.sender].acceleratedBalance[toMinePool];
        require(oldBalance>=balance,'mine pool vesting balance is insufficient');
        userInfoMap[msg.sender].vestingTokenBalance = userInfoMap[msg.sender].vestingTokenBalance.sub(balance);
        userInfoMap[msg.sender].tokenBalance[token] = tokenBalance-amount;
        userInfoMap[msg.sender].acceleratedBalance[toMinePool] = oldBalance - balance;
        if(userInfoMap[msg.sender].vestingTokenBalance == 0){
           userInfoMap[msg.sender].maxPeriodID = 0;
        }
        _redeem(msg.sender, token, amount);
        emit Unstake(msg.sender,token,amount);
        changeAcceleratedInfo(msg.sender,toMinePool,oldBalance,oldPeriod);
    }
    function transferAcceleratedBalance(address fromMinePool,address toMinePool,uint256 amount) public{
        _removeFromMinoPool(msg.sender,fromMinePool,amount);
        _accelerateMinePool(msg.sender,toMinePool,amount,userInfoMap[msg.sender].maxPeriodID);
        emit TransferStake(msg.sender,fromMinePool,toMinePool,amount);
    }
    function changeAcceleratedInfo(address account,address minePool,uint256 oldStake,uint64 oldPeriod)internal {
        if (minePool != address(0)){
            uint64 curPeriod = getCurrentPeriodID();
            uint256[] memory oldRates = calculateAccelerateRates(oldStake,oldPeriod,curPeriod);
            uint256[] memory newRates = calculateAccelerateRates(userInfoMap[account].acceleratedBalance[minePool],
                userInfoMap[account].maxPeriodID,curPeriod);
            if (oldRates.length !=0 || newRates.length != 0){
                IAcceleratedMinePool(minePool).changeAcceleratedInfo(account,newRates,userInfoMap[account].maxPeriodID);
            }
        }
    }
    function _removeFromMinoPool(address account,address minePool,uint256 amount) internal{
        require(userInfoMap[account].acceleratedBalance[minePool]>=amount,"mine pool accelerated balance is unsufficient");
        uint256 oldBalance = userInfoMap[account].acceleratedBalance[minePool];
        userInfoMap[account].acceleratedBalance[minePool] = oldBalance-amount;
        changeAcceleratedInfo(account,minePool,oldBalance,userInfoMap[account].maxPeriodID);
        emit WithdrawMinePool(account,minePool,amount,userInfoMap[account].maxPeriodID);
    }
    function _accelerateMinePool(address account,address minePool,uint256 amount,uint64 oldPeriod) internal{
        uint256 oldBalance = userInfoMap[account].acceleratedBalance[minePool];
        userInfoMap[account].acceleratedBalance[minePool] = oldBalance.add(amount);
        changeAcceleratedInfo(account,minePool,oldBalance,oldPeriod); 
        emit BoostingMinePool(account,minePool,amount,userInfoMap[account].maxPeriodID);
    }
    /**
     * @dev getting user's maximium locked period ID.
     * @param account user's account
     */
    function getUserMaxPeriodId(address account)public view returns (uint64) {
        return userInfoMap[account].maxPeriodID;
    }
    /**
     * @dev getting user's locked expired time. After this time user can unstake PHX coins.
     * @param account user's account
     */
    function getUserExpired(address account)public view returns (uint256) {
        return userInfoMap[account].lockedExpired;
    }
    /**
     * @dev getting current mine period ID.
     */
    function getCurrentPeriodID()public view returns (uint64) {
        return getPeriodIndex(currentTime());
    }
    /**
     * @dev convert timestamp to period ID.
     * @param _time timestamp. 
     */ 
    function getPeriodIndex(uint256 _time) public view returns (uint64) {
        if (_time<startTime){
            return 0;
        }
        return uint64(_time.sub(startTime).div(period)+1);
    }
    function setUserLockedPeriod(address account,uint64 lockedPeriod) internal{
        uint64 curPeriod = getPeriodIndex(currentTime());
        uint64 userMaxPeriod = curPeriod+lockedPeriod-1;
        require(userMaxPeriod>=userInfoMap[account].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        userInfoMap[account].maxPeriodID = userMaxPeriod;
        userInfoMap[account].lockedExpired = uint128(getPeriodFinishTime(curPeriod+lockedPeriod-1));
    }
    /**
     * @dev convert period ID to period's finish timestamp.
     * @param periodID period ID. 
     */
    function getPeriodFinishTime(uint64 periodID)public view returns (uint256) {
        return period.mul(periodID).add(startTime);
    }
        /**
     * @dev Throws if input period number is greater than _maxPeriod.
     */
    modifier validPeriod(uint64 period){
        require(period > 0 && period <= maxPeriodLimit, 'locked period must be in valid range');
        _;
    }
    /**
     * @dev get now timestamp.
     */
    function currentTime() internal view returns (uint256){
        return now;
    }
    modifier tokenPermission(address token){
        require(vestingTokenRate[token]>0 && vestTokens.isEligibleAddress(token),'Token is not allowed to vest');

        _;
    }    
    /**
     * @dev Throws if user's locked expired timestamp is less than now.
     */
    modifier periodExpired(address account){
        require(userInfoMap[account].lockedExpired < currentTime(),'locked period is not expired');

        _;
    }
    function calculateAccelerateRates(uint256 stakeNum,uint64 maxPeriod,uint64 currentPreiod) public pure returns(uint256[] memory){
        if (maxPeriod<currentPreiod || stakeNum<mineBoostingAmount){
            uint256[] memory rates = new uint256[](0);
            return rates;
        }
        maxPeriod = maxPeriod - currentPreiod + 1;
        uint256[] memory rates = new uint256[](maxPeriod);
        require(stakeNum<1e40, "input stakeNum overflow");
        //t=(amount/500)^0.05
        //0.05<<32 = 214748365
        uint256 t = (SmallNumbers.pow((stakeNum<<32)/mineBoostingAmount,214748365)*rateDecimals)>>32;
        uint256 tt = t*t/rateDecimals;
        tt = tt*tt/rateDecimals;
        uint256 t5 = tt*t/rateDecimals;
        uint256 t6 = t5*t/rateDecimals;
        uint256 slope = (t6*400000 + t5*670000)/rateDecimals;
        for (uint256 i=0;i<maxPeriod;i++){
            rates[i] = slope*i+t;
        }
        return rates;
        //rate=(t^6*0.004+t^5*0.0067)*(Period-1)+t
        
    }
}