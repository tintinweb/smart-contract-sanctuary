/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library AddressUpgradeable {
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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


abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


interface IERC20Upgradeable {
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

library SafeMathUpgradeable {
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



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

interface IERC20Detailed { 
    function decimals() external view returns (uint8);
}

contract DeHiveTokensale is OwnableUpgradeable, PausableUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * EVENTS
     **/
    event DHVPurchased(address indexed user, address indexed purchaseToken, uint256 dhvAmount);
    event TokensClaimed(address indexed user, uint256 dhvAmount);

    /**
     * CONSTANTS
     **/

    // *** TOKENSALE PARAMETERS START ***
    uint256 public constant PRECISION = 1000000; //Up to 0.000001
    uint256 public constant PRE_SALE_START =    1616594400; //Mar 24 2021 14:00:00 GMT
    uint256 public constant PRE_SALE_END =      1616803140; //Mar 26 2021 23:59:00 GMT

    uint256 public constant PUBLIC_SALE_START = 1618408800; //Apr 14 2021 14:00:00 GMT
    uint256 public constant PUBLIC_SALE_END =   1618790340; //Apr 18 2021 23:59:00 GMT

    uint256 public constant PRE_SALE_DHV_POOL =     450000 * 10 ** 18; // 5% DHV in total in presale pool
    uint256 public constant PRE_SALE_DHV_NUX_POOL =  50000 * 10 ** 18; // 
    uint256 public constant PUBLIC_SALE_DHV_POOL = 1100000 * 10 ** 18; // 11% DHV in public sale pool
    uint256 private constant WITHDRAWAL_PERIOD = 365 * 24 * 60 * 60; //1 year
    // *** TOKENSALE PARAMETERS END ***


    /***
     * STORAGE
     ***/

    uint256 public maxTokensAmount;
    uint256 public maxGasPrice;

    // *** VESTING PARAMETERS START ***

    uint256 public vestingStart;
    uint256 public vestingDuration; /*= 305 * 24 * 60 * 60*/ //305 days - until Apr 30 2021 00:00:00 GMT
    
    // *** VESTING PARAMETERS END ***
    address public DHVToken;
    address internal USDTToken; /*= 0xdAC17F958D2ee523a2206206994597C13D831ec7 */
    address internal DAIToken; /*= 0x6B175474E89094C44Da98b954EedeAC495271d0F*/
    address internal NUXToken; /*= 0x89bD2E7e388fAB44AE88BEf4e1AD12b4F1E0911c*/

    mapping (address => uint256) public purchased;
    mapping (address => uint256) internal _claimed;

    uint256 public purchasedWithNUX;
    uint256 public purchasedPreSale;
    uint256 public purchasedPublicSale;
    uint256 public ETHRate;
    mapping (address => uint256) public rates;

    address private _treasury;
    
    /***
     * MODIFIERS
     ***/

    /**
     * @dev Throws if called with not supported token.
     */
    modifier supportedCoin(address _token) {
        require(_token == USDTToken || _token == DAIToken, "Token not supported");
        _;
    }

    /**
    * @dev Throws if called when no ongoing pre-sale or public sale.
    */
    modifier onlySale() {
        require(_isPreSale() || _isPublicSale(), "Sale stages are over or not started");
        _;
    }

    /**
    * @dev Throws if called when no ongoing pre-sale or public sale.
    */
    modifier onlyPreSale() {
        require(_isPreSale(), "Presale stages are over or not started");
        _;
    }

    /**
    * @dev Throws if sale stage is ongoing.
    */
    modifier notOnSale() {
        require(!_isPreSale(), "Presale is not over");
        require(!_isPublicSale(), "Sale is not over");
        _;
    }

    /**
    * @dev Throws if gas price exceeds gas limit.
    */
    modifier correctGas() {
        require(maxGasPrice == 0 || tx.gasprice <= maxGasPrice, "Gas price exceeds limit");
        _;
    }

    /***
     * INITIALIZER AND SETTINGS
     ***/

    /**
     * @notice Initializes the contract with correct addresses settings
     * @param treasury Address of the DeHive protocol's treasury where funds from sale go to
     * @param dhv DHVToken mainnet address
     */
    function initialize(address treasury, address dhv) public initializer {
        require(treasury != address(0), "Zero address");
        require(dhv != address(0), "Zero address");

        __Ownable_init();
        __Pausable_init();

        _treasury = treasury;
        DHVToken = dhv;

        DAIToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        USDTToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        NUXToken = 0x89bD2E7e388fAB44AE88BEf4e1AD12b4F1E0911c;
        vestingStart = 0;
        vestingDuration = 305 * 24 * 60 * 60;
        maxTokensAmount = 49600 * (10 ** 18); // around 50 ETH 
    }

    /**
     * @notice Updates current vesting start time. Can be used once
     * @param _vestingStart New vesting start time
     */
    function adminSetVestingStart(uint256 _vestingStart) virtual external onlyOwner{
        require(vestingStart == 0, "Vesting start is already set");
        require(_vestingStart > PUBLIC_SALE_END && block.timestamp < _vestingStart, "Incorrect time provided");
        vestingStart = _vestingStart;
    }

    /**
     * @notice Sets the rate for the chosen token based on the contracts precision
     * @param _token ERC20 token address or zero address for ETH
     * @param _rate Exchange rate based on precision (e.g. _rate = PRECISION corresponds to 1:1)
     */
    function adminSetRates(address _token, uint256 _rate) external onlyOwner {
        if (_token == address(0))
            ETHRate = _rate;
        else
            rates[_token] = _rate;
    }

    /**
    * @notice Allows owner to change the treasury address. Treasury is the address where all funds from sale go to
    * @param treasury New treasury address
    */
    function adminSetTreasury(address treasury) external onlyOwner notOnSale {
        _treasury = treasury;
    }

    /**
    * @notice Allows owner to change max allowed DHV token per address.
    * @param _maxDHV New max DHV amount
    */
    function adminSetMaxDHV(uint256 _maxDHV) external onlyOwner {
        maxTokensAmount = _maxDHV;
    }

    /**
    * @notice Allows owner to change the max allowed gas price. Prevents gas wars
    * @param _maxGasPrice New max gas price
    */
    function adminSetMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
    }

    /**
    * @notice Stops purchase functions. Owner only
    */
    function adminPause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Unpauses purchase functions. Owner only
    */
    function adminUnpause() external onlyOwner {
        _unpause();
    }

    /***
     * PURCHASE FUNCTIONS
     ***/

    /**
     * @notice For purchase with ETH
     */
    receive() external virtual payable onlySale whenNotPaused {
        _purchaseDHVwithETH();
    }

    /**
     * @notice For purchase with allowed stablecoin (USDT and DAI)
     * @param ERC20token Address of the token to be paid in
     * @param ERC20amount Amount of the token to be paid in
     */
    function purchaseDHVwithERC20(address ERC20token, uint256 ERC20amount) external onlySale supportedCoin(ERC20token) whenNotPaused correctGas {
        require(ERC20amount > 0, "Zero amount");
        uint256 purchaseAmount = _calcPurchaseAmount(ERC20token, ERC20amount);
        require(maxTokensAmount == 0 || 
                purchaseAmount.add(purchased[msg.sender]) <= maxTokensAmount, "Maximum allowed exceeded");

        
        if (_isPreSale()) {
            require(purchasedPreSale.add(purchaseAmount) <= PRE_SALE_DHV_POOL, "Not enough DHV in presale pool");
            purchasedPreSale = purchasedPreSale.add(purchaseAmount);
        } else {
            require(purchaseAmount <= publicSaleAvailableDHV(), "Not enough DHV in sale pool");
            purchasedPublicSale = purchasedPublicSale.add(purchaseAmount);
        }
            
        IERC20Upgradeable(ERC20token).safeTransferFrom(_msgSender(), _treasury, ERC20amount); // send ERC20 to Treasury
        purchased[_msgSender()] = purchased[_msgSender()].add(purchaseAmount);

        emit DHVPurchased(_msgSender(), ERC20token, purchaseAmount);
    }

    /**
     * @notice For purchase with NUX token only. Available only for tokensale
     * @param nuxAmount Amount of the NUX token
     */
    function purchaseDHVwithNUX(uint256 nuxAmount) external onlyPreSale whenNotPaused correctGas {
        require(nuxAmount > 0, "Zero amount");
        uint256 purchaseAmount = _calcPurchaseAmount(NUXToken, nuxAmount);
        require(maxTokensAmount == 0 || 
                purchaseAmount.add(purchased[msg.sender]) <= maxTokensAmount, "Maximum allowed exceeded");


        require(purchasedWithNUX.add(purchaseAmount) <= PRE_SALE_DHV_NUX_POOL, "Not enough DHV in NUX pool");
        purchasedWithNUX = purchasedWithNUX.add(purchaseAmount);

        IERC20Upgradeable(NUXToken).safeTransferFrom(_msgSender(), _treasury, nuxAmount);
        purchased[_msgSender()] = purchased[_msgSender()].add(purchaseAmount);

        emit DHVPurchased(_msgSender(), NUXToken, purchaseAmount);
    }

    /**
     * @notice For purchase with ETH. ETH is left on the contract until withdrawn to treasury
     */
    function purchaseDHVwithETH() external payable onlySale whenNotPaused {
        require(msg.value > 0, "No ETH sent");
        _purchaseDHVwithETH();
    }

    function _purchaseDHVwithETH() correctGas private {
        uint256 purchaseAmount = _calcEthPurchaseAmount(msg.value);
        require(maxTokensAmount == 0 || 
                purchaseAmount.add(purchased[msg.sender]) <= maxTokensAmount, "Maximum allowed exceeded");


        if (_isPreSale()) {
            require(purchasedPreSale.add(purchaseAmount) <= PRE_SALE_DHV_POOL, "Not enough DHV in presale pool");
            purchasedPreSale = purchasedPreSale.add(purchaseAmount);
        } else {
            require(purchaseAmount <= publicSaleAvailableDHV(), "Not enough DHV in sale pool");
            purchasedPublicSale = purchasedPublicSale.add(purchaseAmount);
        }

        purchased[_msgSender()] = purchased[_msgSender()].add(purchaseAmount);

        payable(_treasury).transfer(msg.value);

        emit DHVPurchased(_msgSender(), address(0), purchaseAmount);
    }

    /**
     * @notice Function to get available on public sale amount of DHV
     * @notice Unsold NUX pool and pre-sale pool go to public sale
     * @return The amount of the token released.
     */
    function publicSaleAvailableDHV() public view returns(uint256) {
        return PUBLIC_SALE_DHV_POOL.sub(purchasedPublicSale) +
               PRE_SALE_DHV_POOL.sub(purchasedPreSale) +
               PRE_SALE_DHV_NUX_POOL.sub(purchasedWithNUX);
    }


    /**
     * @notice Function for the administrator to withdraw token (except DHV)
     * @notice Withdrawals allowed only if there is no sale pending stage
     * @param ERC20token Address of ERC20 token to withdraw from the contract
     */
    function adminWithdrawERC20(address ERC20token) external onlyOwner notOnSale {
        require(ERC20token != DHVToken || _canWithdrawDHV(), "DHV withdrawal is forbidden");

        uint256 tokenBalance = IERC20Upgradeable(ERC20token).balanceOf(address(this));
        IERC20Upgradeable(ERC20token).safeTransfer(_treasury, tokenBalance);
    }

    /**
     * @notice Function for the administrator to withdraw ETH for refunds
     * @notice Withdrawals allowed only if there is no sale pending stage
     */
    function adminWithdraw() external onlyOwner notOnSale {
        require(address(this).balance > 0, "Nothing to withdraw");

        (bool success, ) = _treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Returns DHV amount for 1 external token
     * @param _token External toke (DAI, USDT, NUX, 0 address for ETH)
     */
    function rateForToken(address _token) external view returns(uint256) {
        if (_token == address(0)) {
            return _calcEthPurchaseAmount(10**18);
        }
        else {
            return _calcPurchaseAmount(_token, 10**( uint256(IERC20Detailed(_token).decimals()) ));
        }
    }

    /***
     * VESTING INTERFACE
     ***/

    /**
     * @notice Transfers available for claim vested tokens to the user.
     */
    function claim() external {
        require(vestingStart!=0, "Vesting start is not set");
        require(_isPublicSaleOver(), "Not allowed to claim now");
        uint256 unclaimed = claimable(_msgSender());
        require(unclaimed > 0, "TokenVesting: no tokens are due");

        _claimed[_msgSender()] = _claimed[_msgSender()].add(unclaimed);
        IERC20Upgradeable(DHVToken).safeTransfer(_msgSender(), unclaimed);
        emit TokensClaimed(_msgSender(), unclaimed);
    }

    /**
     * @notice Gets the amount of tokens the user has already claimed
     * @param _user Address of the user who purchased tokens
     * @return The amount of the token claimed.
     */
    function claimed(address _user) external view returns (uint256) {
        return _claimed[_user];
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been claimed yet.
     * @param _user Address of the user who purchased tokens
     * @return The amount of the token vested and unclaimed.
     */
    function claimable(address _user) public view returns (uint256) {
        return _vestedAmount(_user).sub(_claimed[_user]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _user Address of the user who purchased tokens
     * @return Amount of DHV already vested
     */
    function _vestedAmount(address _user) private view returns (uint256) {
        if (block.timestamp >= vestingStart.add(vestingDuration)) {
            return purchased[_user];
        } else {
            return purchased[_user].mul(block.timestamp.sub(vestingStart)).div(vestingDuration);
        }
    }

    /***
     * INTERNAL HELPERS
     ***/


    /**
     * @dev Checks if presale stage is on-going.
     * @return True is presale is active
     */
    function _isPreSale() virtual internal view returns (bool) {
        return (block.timestamp >= PRE_SALE_START && block.timestamp < PRE_SALE_END);
    }

    /**
     * @dev Checks if public sale stage is on-going.
     * @return True is public sale is active
     */
    function _isPublicSale() virtual internal view returns (bool) {
        return (block.timestamp >= PUBLIC_SALE_START && block.timestamp < PUBLIC_SALE_END);
    }

    /**
     * @dev Checks if public sale stage is over.
     * @return True is public sale is over
     */
    function _isPublicSaleOver() virtual internal view returns (bool) {
        return (block.timestamp >= PUBLIC_SALE_END);
    }

    /**
     * @dev Checks if public sale stage is over.
     * @return True is public sale is over
     */
    function _canWithdrawDHV() virtual internal view returns (bool) {
        return (block.timestamp >= vestingStart.add(WITHDRAWAL_PERIOD) );
    }

    /**
     * @dev Calculates DHV amount based on rate and token.
     * @param _token Supported ERC20 token
     * @param _amount Token amount to convert to DHV
     * @return DHV amount
     */
    function _calcPurchaseAmount(address _token, uint256 _amount) private view returns (uint256) {
        uint256 purchaseAmount = _amount.mul(rates[_token]).div(PRECISION);
        require(purchaseAmount > 0, "Rates not set");

        uint8 _decimals = IERC20Detailed(_token).decimals();
        if (_decimals < 18) {
            purchaseAmount = purchaseAmount.mul(10 ** (18 - uint256(_decimals)));
        }
        return purchaseAmount;
    }

    /**
     * @dev Calculates DHV amount based on rate and ETH amount.
     * @param _amount ETH amount to convert to DHV
     * @return DHV amount
     */
    function _calcEthPurchaseAmount(uint256 _amount) private view returns (uint256) {
        uint256 purchaseAmount = _amount.mul(ETHRate).div(PRECISION);
        require(purchaseAmount > 0, "Rates not set");
        return purchaseAmount;
    }


}

contract DeHiveTokensaleMock is DeHiveTokensale {

    uint256 public preSaleStart;
    uint256 public preSaleEnd;
    uint256 public publicSaleStart;
    uint256 public publicSaleEnd;


    function initialize(address _DAIToken,
        address _USDTToken,
        address _NUXToken,
        address treasury,
        address dhv) public initializer
    {
        DeHiveTokensale.initialize(treasury, dhv);
        USDTToken = _USDTToken;
        DAIToken = _DAIToken;
        NUXToken = _NUXToken;


        preSaleStart =    1616594400; //Mar 24 2021 14:00:00 GMT
        preSaleEnd =      1616803140; //Mar 26 2021 23:59:00 GMT

        publicSaleStart = 1618408800; //Apr 14 2021 14:00:00 GMT
        publicSaleEnd =   1618790340; //Apr 18 2021 23:59:00 GMT

    }
    function getUSDTToken() public view returns(address){
        return USDTToken;
    }
    function getDAIToken() public view returns(address){
        return DAIToken;
    }
    function getNUXToken() public view returns(address){
        return NUXToken;
    }

    function setPreSale(uint256 start, uint256 end) public {
        preSaleStart = start;
        preSaleEnd = end;
    }

    function setPublicSale(uint256 start, uint256 end) public {
        publicSaleStart = start;
        publicSaleEnd = end;
    }

    function adminSetVestingDuration(uint256 _duration) public {
        vestingDuration = _duration;
    }

    function adminSetVestingStart(uint256 _vestingStart) override external {
        vestingStart = _vestingStart;
    }

    function _isPreSale() override internal view returns (bool) {
        return (block.timestamp >= preSaleStart && block.timestamp < preSaleEnd);
    }

    function _isPublicSale() override internal view returns (bool) {
        return (block.timestamp >= publicSaleStart && block.timestamp < publicSaleEnd);
    }

    function _isPublicSaleOver() override internal view returns (bool) {
        return (block.timestamp >= publicSaleEnd);
    }


}