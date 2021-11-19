/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IBEP20;` statement to your contract,
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
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract Pausable {
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
    constructor() public {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
        emit Paused(msg.sender);
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
        emit Unpaused(msg.sender);
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Whitelist is Pausable {
    
    using SafeMath for uint256;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public userTier;
    
    string public clientSeed;
    string public serverSeed;
    uint public nonce;
    
    uint public currentWhitelisted = 0;

    uint public poolStartDate;
    
    address public poolCreator;


    event TransferOwnership(address _address);
    event AddedToWhitelist(address accounts,uint _tier,address poolAddress);
    event RandomAddedToWhitelist(address accounts,uint _tier,address poolAddress);
    event RemovedFromWhitelist(address _address,address poolAddress);
    

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender),"only whitelist address can call");
        _;
    }

    modifier onlyPoolCreator() {
        require(msg.sender == poolCreator,"only Pool Creator address can call");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
  
    constructor(address _address,uint256 _startDate,string memory _serverSeed) public {
        poolStartDate = _startDate;
        poolCreator = _address;
        serverSeed = _serverSeed;
    }
    
    modifier beforePoolStart(){
        require(block.timestamp <= poolStartDate);
        _;
    } 

    function changeClientSeed(string memory _clientSeed) public {
        clientSeed = _clientSeed;
    }

    function transferOwnership(address newOwner) public onlyPoolCreator() {
        require(newOwner != address(0), "new owner is the zero address");
        poolCreator = newOwner;
        emit TransferOwnership(newOwner);
    }
    // 1 = Tier1
    // 2 = Tier2
    // 3 = tier3
    // 4 = Tier4
    // 5 = Tier5 
    // 6 = Gamers
    // 7 = Ecopartners
    function addPublicRandom(address[] memory _addresses,uint256 _tier, uint _maximumWhitelisted,string memory _serverSeed) public onlyPoolCreator() beforePoolStart{
        require (_addresses.length > 0," _addresses length is zero");
        require (_tier > 0 && _tier <= 7,"not a valid _tier"); 
        uint totalWhitelisted;
        require(_addresses.length > _maximumWhitelisted,"less address");        
        uint arrlength = _addresses.length;        
        for (uint i = 0; i < (_maximumWhitelisted.div(32)).add(1); i++){
            nonce++;        
            bytes32 hash = (keccak256(abi.encode(_serverSeed,clientSeed,nonce)));        
            for (uint j = 0; j < 32; j++){    
                if(totalWhitelisted < _maximumWhitelisted){
                    uint256 val = uint(bytes32(hash[j])).mod(arrlength);
                    whitelist[_addresses[val]] = true;
                    userTier[_addresses[val]] = _tier;
                    _addresses[val] = _addresses[arrlength-1];
                    delete _addresses[arrlength-1];
                    arrlength = arrlength.sub(1);
                    totalWhitelisted = totalWhitelisted.add(1);
                    emit RandomAddedToWhitelist(_addresses[val],_tier,address(this));
                }
            }
        }
        currentWhitelisted = currentWhitelisted.add(totalWhitelisted);
    }

    /* Whitelist Private Users */
    
    function addPrivate(address[] memory _addresses,uint256[] memory _tier) external onlyPoolCreator() beforePoolStart{
        require (_addresses.length == _tier.length ,"_tier and _addresses length is not same");
        uint totalWhitelisted;
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0),"address must be valid");
            require(_tier[i] != 0, "tier must be valid ");
            if(whitelist[_addresses[i]] != true){
                whitelist[_addresses[i]] = true;
                userTier[_addresses[i]] = _tier[i];
                totalWhitelisted+=1;
                emit AddedToWhitelist(_addresses[i],_tier[i],address(this));
            }
        }
        currentWhitelisted = currentWhitelisted.add(totalWhitelisted);
    }

    function remove(address[] memory _addresses) external onlyPoolCreator() beforePoolStart {
        require(_addresses.length <= currentWhitelisted,"remove only whitelist address");
        uint totalWhitelisted;
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
            totalWhitelisted+=1;
            emit RemovedFromWhitelist(_addresses[i],address(this));
        }
        currentWhitelisted = currentWhitelisted.sub(totalWhitelisted);
    }
    
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function getUserTier(address _address) public view returns(uint256){
        if(isWhitelisted(_address)){
            return userTier[_address];
        }
        else {
            return 0;
        }
    }

    function pause() public onlyPoolCreator(){
        _pause();
    }
    
    function unpause() public onlyPoolCreator(){
        _unpause();
    }
 
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Pool is Whitelist,ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 increment = 0;

    mapping(uint256 => Purchase) public purchases; 
    
    uint256[] public purchaseIds; 
    mapping(address => uint256[]) public myPurchases; 
    
    struct Purchase {
        uint256 amount;
        address purchaser;
        uint256 bnbAmount;
        uint256 timestamp;
        bool wasFinalized ;
        bool reverted;
    }

    IBEP20 public ibep20;
    bool public isSaleFunded = false;
    uint public decimals = 0;
    bool public unsoldTokensReedemed = false;
    uint256 public tradeValue; 
    uint256 public startDate; 
    uint256 public endDate; 
    uint256 public individualMinimumAmount;  
    uint256 public individualMaximumAmount;  

    uint256 public minimumRaise;  
    
    uint256 public tokensAllocated = 0; 
    uint256 public tokensForSale = 0; 
    bool    public poolType; // for standard put false and instant put true
    uint public constant DENOMINATOR = 10000;

    address payable public fundAddress;
   
    address payable public FEE_ADDRESS; 
    uint256 public feePercentage;
    uint256 public feeAmount = 0 ;
    address public factoryContract;

    

    event PurchaseEvent(uint256 amount, address indexed purchaser, uint256 timestamp,address poolAddress);
    event AddFund(uint amount,address poolAddress);
    event WithdrawFunds(address indexed _owner,address poolAddress);
    event RedeemGivenMinimumGoalNotAchieved(uint _purchase_id,address poolAddress);
    event SetFundAddress(address _fundAddress);
    event SetFeePercentage(uint256 _feePercentage);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _tokenAddress, uint256 _tradeValue, uint256 _tokensForSale,uint256 _startDate, uint256 _endDate,
        bool _poolType, uint256 _minimumRaise,address _address,string memory _serverSeed,address _factoryContract
    ) public Whitelist(_address,_startDate,_serverSeed) {
        
        require(_tokenAddress != address(0) && _address != address(0),"invalid address");
        require(_tradeValue > 0,"tradeValue is low");
        require(block.timestamp < _endDate, "End Date should be further than current date");
        require(block.timestamp < _startDate, "_startDate Date should be further than current date");
        require(_startDate < _endDate, "End Date higher than Start Date");
        require(_tokensForSale > 0, "Tokens for Sale should be > 0");
        require(_minimumRaise <= DENOMINATOR, "Minimum Raise should be less than total tokens");
        
        tokensForSale = _tokensForSale;
        tradeValue = _tradeValue;
        startDate = _startDate; 
        endDate = _endDate; 
        poolType = _poolType;
        if(!_poolType   ){ /* If raise is not atomic swap */
            minimumRaise = _tokensForSale.mul(_minimumRaise).div(DENOMINATOR);
        }
        ibep20 = IBEP20(_tokenAddress);
        decimals = ibep20.decimals();
        factoryContract = _factoryContract;
        
    }

    /* One Time Call Function for Set User Limit */
    
    function setLimit(uint256 _individualMinimumAmount,uint256 _individualMaximumAmount) external beforePoolStart(){
        require(msg.sender == factoryContract || msg.sender == poolCreator ,"only valid address can call");
        require(_individualMaximumAmount >= _individualMinimumAmount, "Individual Maximim AMount should be > Individual Minimum Amount");
        require(tokensForSale >= _individualMinimumAmount, "Tokens for Sale should be > Individual Minimum Amount");
        require(tokensForSale >= _individualMaximumAmount, "Tokens for Sale should be > Individual maximum Amount");
        individualMinimumAmount = _individualMinimumAmount; 
        individualMaximumAmount = _individualMaximumAmount;
    }

    function setFundAddress(address payable _fundAddress) public onlyPoolCreator() {
        require (_fundAddress != address(0),"Set valid address");
        fundAddress = _fundAddress;
        emit SetFundAddress(_fundAddress); 
    }

    function setTreasurerAddress(address payable _treasurer) public onlyPoolCreator() beforePoolStart(){
        FEE_ADDRESS = _treasurer;
    }

    function setFeePercentage(uint256 _feePercentage) public onlyPoolCreator() beforePoolStart(){
        require(_feePercentage < DENOMINATOR && _feePercentage > 0,"set Valid fee percentage");
        feePercentage =  _feePercentage;
        emit SetFeePercentage(_feePercentage);
    }

    /**
    * Modifier to make a function callable only when the contract has Atomic Swaps not available.
    */

    modifier isNotInstant() {
        require(!poolType, "Has to be non instant swap");
        _;
    }

    /**
    * Modifier to make a function callable only when the contract has Atomic Swaps not available.
    */
    modifier isSaleFinalized() {
        require(hasFinalized(), "Has to be finalized");
        _;
    }

    /**
    * Modifier to make a function callable only when the swap time is open.
    */
    modifier isSaleOpen() {
        require(isOpen(), "Has to be open");
        _;
    }

    /**
    * Modifier to make a function callable only when the contract has Atomic Swaps not available.
    */

    modifier isSalePreStarted() {
        require(isPreStart(), "Has to be pre-started");
        _;
    }

    /**
    * Modifier to make a function callable only when the contract has Atomic Swaps not available.
    */

    modifier isFunded() {
        require(isSaleFunded, "Has to be funded");
        _;
    }

    /* ========== VIEWS ========== */

    function getStratDate() public view returns(uint){
        return startDate;
    }

    /* Get Functions */
    function totalRaiseCost() public view returns (uint256) {
        return (cost(tokensForSale));
    }

    function availableTokens() public view returns (uint256) {
        return ibep20.balanceOf(address(this));
    }

    function tokensLeft() public view returns (uint256) {
        return tokensForSale - tokensAllocated;
    }
    

    function hasMinimumRaise() public view returns (bool){
        return (minimumRaise != 0);
    }

    /* Verify if minimum raise was not achieved */
    function minimumRaiseNotAchieved() public view returns (bool){
        require(cost(tokensAllocated) < cost(minimumRaise), "TotalRaise is bigger than minimum raise amount");
        return true;
    }

    /* Verify if minimum raise was achieved */
    function minimumRaiseAchieved() public view returns (bool){
        if(hasMinimumRaise()){
            require(cost(tokensAllocated) >= cost(minimumRaise), "TotalRaise is less than minimum raise amount");
        }
        return true;
    }

    function hasFinalized() public view returns (bool){
        return block.timestamp > endDate;
    }

    function hasStarted() public view returns (bool){
        return block.timestamp >= startDate;
    }
    
    function isPreStart() public view returns (bool){
        return block.timestamp < startDate;
    }

    function isOpen() public view returns (bool){
        return hasStarted() && !hasFinalized();
    }

    function cost(uint256 _amount) public view returns (uint){
        return _amount.mul(tradeValue).div(10**decimals);
    }
    
    function costFee(uint _amount) public view returns(uint){
        uint fee = _amount.mul(tradeValue).div(10**decimals).mul(feePercentage).div(DENOMINATOR);
        return fee;
    }

    function getPurchase(uint256 _purchase_id) external view returns (uint256, address, uint256, uint256, bool, bool){
        Purchase memory purchase = purchases[_purchase_id];
        return (purchase.amount, purchase.purchaser, purchase.bnbAmount, purchase.timestamp, purchase.wasFinalized, purchase.reverted);
    }

    function getPurchaseIds() public view returns(uint256[] memory) {
        return purchaseIds;
    }

    
    function getMyPurchases(address _address) public view returns(uint256[] memory) {
        return myPurchases[_address];
    }

    /* Add Tokens for Sale */

    function addFund(uint256 _amount) public isSalePreStarted {
        require(ibep20.balanceOf(msg.sender) >= _amount,"token balance is low");
        require(availableTokens().add(_amount) <= tokensForSale, "Transfered tokens have to be equal or less than proposed");
        ibep20.safeTransferFrom(msg.sender, address(this), _amount);
        if(availableTokens() == tokensForSale){
            isSaleFunded = true;
        }
        emit AddFund(_amount,address(this));
    }

    /* For Token Exchange */
    
    function swap(uint256 _amount) payable external whenNotPaused isFunded isSaleOpen onlyWhitelisted() {

        require(_amount > 0, "Amount has to be positive");
        require(_amount <= tokensLeft(), "Amount is less than tokens available");
        require(msg.value == cost(_amount).add(costFee(_amount)), "User has to cover the cost of the swap in BNB, use the cost function to determine");
        //uint256 tier = getUserTier(msg.sender);
        //require(tier != 0,"only valid user swap this tokens");
        require(_amount >= individualMinimumAmount, "Amount is bigger than minimum amount");
        require(_amount <= individualMaximumAmount, "Amount is smaller than maximum amount"); 

        uint256[] memory _purchases = getMyPurchases(msg.sender);

        uint256 purchaserTotalAmountPurchased = 0;
        for (uint i = 0; i < _purchases.length; i++) {
            Purchase memory _purchase = purchases[_purchases[i]];
            purchaserTotalAmountPurchased = purchaserTotalAmountPurchased.add(_purchase.amount);
        }
        require(purchaserTotalAmountPurchased.add(_amount) <= individualMaximumAmount, "Address has already passed the max amount of swap");
        
        if(poolType){
            ibep20.safeTransfer(address(msg.sender), _amount);
        }
        feeAmount = feeAmount.add(costFee(_amount)); 

        uint256 purchase_id = increment;
        increment = increment.add(1);
        Purchase memory purchase = Purchase(_amount, msg.sender, msg.value, block.timestamp, poolType, false);
        purchases[purchase_id] = purchase;
        purchaseIds.push(purchase_id);
        myPurchases[msg.sender].push(purchase_id);
        tokensAllocated = tokensAllocated.add(_amount);
        emit PurchaseEvent(_amount, msg.sender, block.timestamp,address(this));
    }

    /* Redeem tokens when the sale was finalized */

    function redeemTokens(uint256 purchase_id) external isNotInstant isSaleFinalized isFunded whenNotPaused nonReentrant{
        
        require((purchases[purchase_id].amount != 0) && !purchases[purchase_id].wasFinalized, "Purchase is either 0 or finalized");
        //require(hasMinimumRaise(), "Minimum raise has to exist");
        require(minimumRaiseAchieved(),"minimun rasie  has not be reached");
        require(purchases[purchase_id].purchaser == msg.sender);
        
        purchases[purchase_id].wasFinalized = true;
        ibep20.safeTransfer(msg.sender, purchases[purchase_id].amount);
    }

    /* Retrieve Minumum Amount */

    function redeemGivenMinimumGoalNotAchieved(uint256 purchase_id) external isSaleFinalized isNotInstant nonReentrant {
        require(hasMinimumRaise(), "Minimum raise has to exist");
        require(minimumRaiseNotAchieved(), "Minimum raise has to be reached");
        /* Confirm it exists and was not finalized */
        require((purchases[purchase_id].amount != 0) && !purchases[purchase_id].wasFinalized, "Purchase is either 0 or finalized");
        
        require(purchases[purchase_id].purchaser == msg.sender);
        purchases[purchase_id].wasFinalized = true;
        purchases[purchase_id].reverted = true;
        msg.sender.transfer(purchases[purchase_id].bnbAmount);
        emit RedeemGivenMinimumGoalNotAchieved(purchase_id,address(this));
    }

    /* Admin Functions for Withdrow sale Funds */

    function withdrawFunds() external whenNotPaused onlyPoolCreator() isSaleFinalized {
        require(minimumRaiseAchieved(), "Minimum raise has to be reached");
        FEE_ADDRESS.transfer(feeAmount); /* Fee Address */
        fundAddress.transfer(address(this).balance);
        emit WithdrawFunds(msg.sender,address(this));
    }  

    /* Admin Functions for Withdrow Unsold Tokens  */
    
    function withdrawUnsoldTokens() external onlyPoolCreator() isSaleFinalized {
        require(!unsoldTokensReedemed);
        uint256 unsoldTokens;
        if(hasMinimumRaise() && 
            (cost(tokensAllocated) < cost(minimumRaise))){ 
                unsoldTokens = tokensForSale;
        }else{
            unsoldTokens = tokensForSale.sub(tokensAllocated);
        }
        if(unsoldTokens > 0){
            unsoldTokensReedemed = true;
            ibep20.safeTransfer(fundAddress, unsoldTokens);
        }
    }   

    function removeOtherBEP20Tokens(address _tokenAddress, address _to) external onlyPoolCreator() isSaleFinalized {
        require(_tokenAddress != address(ibep20), "Token Address has to be diff than the ibep20 subject to sale");
        IBEP20 ibep20Token = IBEP20(_tokenAddress);
        ibep20Token.safeTransfer(_to, ibep20Token.balanceOf(address(this)));
    } 

    /* Safe Pull function */

    function safePull() payable external onlyPoolCreator() whenPaused  {
        msg.sender.transfer(address(this).balance);
        ibep20.safeTransfer(msg.sender, ibep20.balanceOf(address(this)));
    }
    
}


abstract contract Ownable is Context {
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


contract Authorizable is Ownable {


    mapping(address => bool) public authorized;
    address[] public adminList;

    event AddAuthorized(address indexed _address);
    event RemoveAuthorized(address indexed _address, uint index);

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender,"Authorizable: caller is not the SuperAdmin or Admin");
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0),"Authorizable: _toAdd isn't vaild address");
        authorized[_toAdd] = true;
        adminList.push(_toAdd);
        emit AddAuthorized(_toAdd);
    }

    function removeAuthorized(address _toRemove,uint _index) onlyOwner public {
        require(_toRemove != address(0),"Authorizable: _toRemove isn't vaild address");
        require(adminList[_index] == _toRemove,"Authorizable: _index isn't valid index");
        authorized[_toRemove] = false;
        delete adminList[_index];
        emit RemoveAuthorized(_toRemove,_index);
    }

    function getAdminList() public view returns(address[] memory ){
        return adminList;
    }

}


contract PoolFactory is Authorizable{
    using SafeMath for uint256;
   
    mapping(address=>bool) private _isPool;
    
    address[] public poolAddress;

    uint256 public timeGap;
    uint256 public poolDuration;

    /* ========== EVENTS ========== */
    
    event PoolCreated(string _name,address poolAddress,address poolOwner,address indexed _tokenAddress, uint256 _tradeValue, uint256 _tokensForSale, bool _poolType, uint256 _minimumRaise,string _serverSeed,uint256[2] _date);
    event SetLimit(address poolAddress,uint256 userLimit1,uint256 userLimit2);
    
    /* ========== CONSTRUCTOR ========== */
    
    constructor() public {
        timeGap = 2 days;
        poolDuration = 2 days;
    }

    /* ========== CREATEION OF NEW POOL ========== */
    
    function newPool(string memory _name,address _tokenAddress, uint256 _tradeValue, uint256 _tokensForSale,uint[2] memory _date,uint[2] memory _userLimit,bool _poolType, 
        uint256 _minimumRaise,string memory _serverSeed) external onlyAuthorized()  {
        require(_date[0] >= timeGap.add(block.timestamp),"_startDate Date should be further than current date" );
        require(_date[1] >= _date[0].add(poolDuration),"End date must be grater than min duration time");   
        Pool pool = new Pool(_tokenAddress, _tradeValue, _tokensForSale,_date[0],_date[1],_poolType, _minimumRaise,msg.sender,_serverSeed,address(this));
        emit PoolCreated(_name,address(pool),msg.sender,_tokenAddress,_tradeValue,_tokensForSale,_poolType, _minimumRaise,_serverSeed,_date);
        pool.setLimit(_userLimit[0],_userLimit[1]);
        emit SetLimit(address(pool),_userLimit[0], _userLimit[1]);
        _isPool[address(pool)] = true;
        poolAddress.push(address(pool));
    }

    function changeTimeGap(uint256 _timeInSec) public onlyAuthorized(){
        timeGap = _timeInSec;
    } 

    function updateMinPoolDuration(uint256 _poolDuration) public onlyAuthorized(){
        poolDuration = _poolDuration;
    } 

    /* ========== VIEWS ========== */
    
    function isPool(address _address)public view returns(bool){
        return _isPool[_address];
    }

    function totalPool() public view returns(uint256){
        return poolAddress.length;
    } 

    function getAllPools() public view returns(address[] memory){
        return poolAddress;
    }
}