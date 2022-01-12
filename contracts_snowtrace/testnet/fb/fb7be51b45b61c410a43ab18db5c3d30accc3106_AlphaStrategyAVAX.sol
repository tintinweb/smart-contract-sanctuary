/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-12
*/

pragma solidity 0.7.3;


/**
 * @dev Collection of functions related to the address type
 */
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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
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



/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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


interface IJoeBar {
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
    function balanceOf(address account) external returns (uint256);
}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
    function add(uint256, address, bool) external;
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
}

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    function stakeOnsenFarm() external;
    function stakeSushiBar() external;
    function stakeOnxFarm() external;
    function stakeOnx() external;

    function withdrawPendingTeamFund() external;
    function withdrawPendingTreasuryFund() external;
}

contract AlphaStrategyAVAX is OwnableUpgradeable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public treasury;
    //address public rewardManager;
    address public multisigWallet;

    mapping(address => uint256) public userXJoeDebt;

    uint256 public accXJoePerShare;
    uint256 public lastPendingXJoe;
    uint256 public curPendingXJoe;

    mapping(address => uint256) public userRewardDebt;
    /*
    uint256 public accRewardPerShare;
    uint256 public lastPendingReward;
    uint256 public curPendingReward;
    */
    uint256 keepFee;
    uint256 keepFeeMax;
    /*
    uint256 keepReward;
    uint256 keepRewardMax;
    */
    address public vault;
    address public underlying;
    address public masterChef;
    address public Joe;
    address public xJoe;

    address public xJoeStakingMasterchef;
    uint256 public xJoeStakingPoolId;

    bool public sell;
    uint256 public sellFloor;

    uint256 public poolId;

    constructor() public {
    }

    function initializeAlphaStrategy(
        address _multisigWallet,
        //address _rewardManager,
        address _underlying,
        address _vault,
        address _masterChef,
        uint256 _poolId,
        address _Joe,
        address _xJoe,
        address _xJoeStakingMasterchef,
        uint _xJoeStakingPoolId
    ) public initializer {
        underlying = _underlying;
        vault = _vault;
        masterChef = _masterChef;
        sell = true;
        poolId = _poolId;
        xJoeStakingMasterchef = _xJoeStakingMasterchef;
        xJoeStakingPoolId = _xJoeStakingPoolId;

        //rewardManager = _rewardManager;

        __Ownable_init();

        address _lpt;
        (_lpt,,,) = IMasterChef(_masterChef).poolInfo(poolId);
        require(_lpt == underlying, "Pool Info does not match underlying");

        Joe = _Joe;
        xJoe = _xJoe;
        //EDIT THIS
        treasury = address(0xFF7122ea8Ef2FA9Be9464C29087cf6BADDF28c2F);
        //treasury
        keepFee = 3;
        keepFeeMax = 100;
        /*
        //fee sharing 
        keepReward = 15;
        keepRewardMax = 100;
        */

        multisigWallet = _multisigWallet;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
        require(_feeMax > 0, "Treasury feeMax should be bigger than zero");
        require(_fee < _feeMax, "Treasury fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }
    /*
    // keep reward functions
    function setKeepReward(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
        require(_feeMax > 0, "Reward feeMax should be bigger than zero");
        require(_fee < _feeMax, "Reward fee can't be bigger than feeMax");
        keepReward = _fee;
        keepRewardMax = _feeMax;
    }
    */
    // Salvage functions
    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == Joe || token == underlying);
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) public onlyMultisigOrOwner {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }


    modifier onlyVault() {
        require(msg.sender == vault, "Not a vault");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisigWallet , "The sender has to be the multisig wallet");
        _;
    }

    modifier onlyMultisigOrOwner() {
        require(msg.sender == multisigWallet || msg.sender == owner() , "The sender has to be the multisig wallet or owner");
        _;
    }

    function setMultisig(address _wallet) public onlyMultisig {
        multisigWallet = _wallet;
    }

    function updateAccPerShare(address user) public onlyVault {
        updateAccXJoePerShare(user);
        //updateAccRewardPerShare(user);
    }
    /*
    function updateAccRewardPerShare(address user) internal {
        curPendingReward = pendingReward();

        if (lastPendingReward > 0 && curPendingReward < lastPendingReward) {
            curPendingReward = 0;
            lastPendingReward = 0;
            accRewardPerShare = 0;
            userRewardDebt[user] = 0;
            return;
        }

        uint256 totalSupply = IERC20(vault).totalSupply();

        if (totalSupply == 0) {
            accRewardPerShare = 0;
            return;
        }

        uint256 addedReward = curPendingReward.sub(lastPendingReward);
        accRewardPerShare = accRewardPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );
    }
    */
    function updateAccXJoePerShare(address user) internal {
        curPendingXJoe = pendingXJoe();

        if (lastPendingXJoe > 0 && curPendingXJoe < lastPendingXJoe) {
            curPendingXJoe = 0;
            lastPendingXJoe = 0;
            accXJoePerShare = 0;
            userXJoeDebt[user] = 0;
            return;
        }

        uint256 totalSupply = IERC20(vault).totalSupply();

        if (totalSupply == 0) {
            accXJoePerShare = 0;
            return;
        }

        uint256 addedReward = curPendingXJoe.sub(lastPendingXJoe);
        accXJoePerShare = accXJoePerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );
    }

    function updateUserRewardDebts(address user) public onlyVault {
        userXJoeDebt[user] = IERC20(vault).balanceOf(user)
            .mul(accXJoePerShare)
            .div(1e36);
        /*
        userRewardDebt[user] = IERC20(vault).balanceOf(user)
            .mul(accRewardPerShare)
            .div(1e36);
        */
    }

    function pendingXJoe() public view returns (uint256) {
        uint256 xJoeBalance = IERC20(xJoe).balanceOf(address(this));
        return xJoeMasterChefBalance().add(xJoeBalance);
    }
    /*
    function pendingReward() public view returns (uint256) {
        address rewardToken = getSecondRewardsToken();
        return IERC20(rewardToken).balanceOf(address(this));
    }
    */
    function pendingRewardOfUser(address user) external view returns (uint256) { //uint256) {
        return (pendingXJoeOfUser(user));  //, pendingRewardTokenOfUser(user));
    }
    /*
    function pendingRewardTokenOfUser(address user) public view returns (uint256) {
        uint256 totalSupply = IERC20(vault).totalSupply();
        uint256 userBalance = IERC20(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        // pending RewardToken
        uint256 allPendingReward = pendingReward();
        if (allPendingReward < lastPendingReward) return 0;

        uint256 addedReward = allPendingReward.sub(lastPendingReward);

        uint256 newAccRewardPerShare = accRewardPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );

        uint256 _pendingReward = userBalance.mul(newAccRewardPerShare).div(1e36).sub(
            userRewardDebt[user]
        );

        return _pendingReward;
    }
    */
    function pendingXJoeOfUser(address user) public view returns (uint256) {
        uint256 totalSupply = IERC20(vault).totalSupply();
        uint256 userBalance = IERC20(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        // pending xJoe
        uint256 allPendingXJoe = pendingXJoe();

        if (allPendingXJoe < lastPendingXJoe) return 0;

        uint256 addedReward = allPendingXJoe.sub(lastPendingXJoe);

        uint256 newAccXJoePerShare = accXJoePerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );

        uint256 _pendingXJoe = userBalance.mul(newAccXJoePerShare).div(1e36).sub(
            userXJoeDebt[user]
        );

        return _pendingXJoe;
    }

    function getPendingShare(address user, uint256 perShare, uint256 debt) internal returns (uint256 share) {
        uint256 current = IERC20(vault).balanceOf(user)
            .mul(perShare)
            .div(1e36);

        if(current < debt){
            return 0;
        }

        return current
            .sub(debt);
    }

    function withdrawReward(address user) public onlyVault {
        // withdraw pending xJoe
        uint256 _pendingXJoe = getPendingShare(user, accXJoePerShare, userXJoeDebt[user]);

        uint256 _xJoeBalance = IERC20(xJoe).balanceOf(address(this));

        if(_xJoeBalance < _pendingXJoe){
            uint256 needToWithdraw = _pendingXJoe.sub(_xJoeBalance);
            uint256 toWithdraw = Math.min(xJoeMasterChefBalance(), needToWithdraw);
            IMasterChef(xJoeStakingMasterchef).withdraw(xJoeStakingPoolId, toWithdraw);

            _xJoeBalance = IERC20(xJoe).balanceOf(address(this));
        }

        if (_xJoeBalance < _pendingXJoe) {
            _pendingXJoe = _xJoeBalance;
        }

        if(_pendingXJoe > 0 && curPendingXJoe > _pendingXJoe){
            // send reward to user
            IERC20(xJoe).safeTransfer(user, _pendingXJoe);
            lastPendingXJoe = curPendingXJoe.sub(_pendingXJoe);
        }
        /*
        // withdraw pending rewards token
        uint256 _pending = getPendingShare(user, accRewardPerShare, userRewardDebt[user]);

        address RewardToken = getSecondRewardsToken();

        uint256 _balance = IERC20(RewardToken).balanceOf(address(this));

        if (_balance < _pending) {
            _pending = _balance;
        }

        if(_pending > 0 && curPendingReward > _pending){
            // send reward to user
            IERC20(RewardToken).safeTransfer(user, _pending);
            lastPendingReward = curPendingReward.sub(_pending);
        }
        */
    }
    /*
    function getSecondRewardsToken() public view returns (address token) {
        address RewardToken;
        (RewardToken,,,) = IMasterChef(xJoeStakingMasterchef).poolInfo(xJoeStakingPoolId);
        return RewardToken;
    }
    */
    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawAllToVault() public onlyMultisigOrOwner {
        if (address(masterChef) != address(0)) {
            exitJoeRewardPool();
        }
        IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawToVault(uint256 amount) public onlyVault {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IERC20(underlying).balanceOf(address(this));

        if(amount > entireBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(masterChefBalance(), needToWithdraw);
            IMasterChef(masterChef).withdraw(poolId, toWithdraw);
        }

        IERC20(underlying).safeTransfer(vault, amount);
    }

    /*
    *   Note that we currently do not have a mechanism here to include the
    *   amount of reward that is accrued.
    */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (masterChef == address(0)) {
            return IERC20(underlying).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return masterChefBalance().add(IERC20(underlying).balanceOf(address(this)));
    }

    // OnsenFarm functions - Sushiswap slp reward pool functions

    function masterChefBalance() internal view returns (uint256 bal) {
        (bal,) = IMasterChef(masterChef).userInfo(poolId, address(this));
    }

    function exitJoeRewardPool() internal {
        uint256 bal = masterChefBalance();
        if (bal != 0) {
            IMasterChef(masterChef).withdraw(poolId, bal);
        }
    }
    //edited to add claiming from xjoe farm
    function claimJoeRewardPool() internal {
        uint256 bal = masterChefBalance();
        if (bal != 0) {
            IMasterChef(masterChef).withdraw(poolId, 0);
        }
        uint256 balxJoe = xJoeMasterChefBalance();
        if (balxJoe != 0) {
            IMasterChef(xJoeStakingMasterchef).withdraw(xJoeStakingPoolId, 0);
        }
    }

    function xJoeMasterChefBalance() internal view returns (uint256 bal) {
        (bal,) = IMasterChef(xJoeStakingMasterchef).userInfo(xJoeStakingPoolId, address(this));
    }

    function exitRewardsForXJoe() internal {
        uint256 bal = xJoeMasterChefBalance();
    
        if (bal != 0) {
            IMasterChef(xJoeStakingMasterchef).withdraw(xJoeStakingPoolId, bal);
        }
    }

    function enterJoeRewardPool() internal {
        uint256 entireBalance = IERC20(underlying).balanceOf(address(this));
        if (entireBalance != 0) {
            IERC20(underlying).safeApprove(masterChef, 0);
            IERC20(underlying).safeApprove(masterChef, entireBalance);
            IMasterChef(masterChef).deposit(poolId, entireBalance);
        }
    }

    function enterXJoeRewardPool() internal {
        uint256 entireBalance = IERC20(xJoe).balanceOf(address(this));

        if (entireBalance != 0) {
            IERC20(xJoe).safeApprove(xJoeStakingMasterchef, 0);
            IERC20(xJoe).safeApprove(xJoeStakingMasterchef, entireBalance);

            IMasterChef(xJoeStakingMasterchef).deposit(xJoeStakingPoolId, entireBalance);
        }
    }

    function stakeJoeFarm() external {
        enterJoeRewardPool();
    }

    function stakeXJoe() external {
        claimJoeRewardPool();

        uint256 JoeRewardBalance = IERC20(Joe).balanceOf(address(this));
        if (!sell || JoeRewardBalance < sellFloor) {
            // Profits can be disabled for possible simplified and rapid exit
            // emit ProfitsNotCollected(sell, JoeRewardBalance < sellFloor);
            return;
        }

        if (JoeRewardBalance == 0) {
            return;
        }

        IERC20(Joe).safeApprove(xJoe, 0);
        IERC20(Joe).safeApprove(xJoe, JoeRewardBalance);

        uint256 balanceBefore = IERC20(xJoe).balanceOf(address(this));

        IJoeBar(xJoe).enter(JoeRewardBalance);

        uint256 balanceAfter = IERC20(xJoe).balanceOf(address(this));
        uint256 added = balanceAfter.sub(balanceBefore);

        if (added > 0) {
            uint256 fee = added.mul(keepFee).div(keepFeeMax);
            IERC20(xJoe).safeTransfer(treasury, fee);
            /*
            uint256 feeReward = added.mul(keepReward).div(keepRewardMax);
            IERC20(xJoe).safeTransfer(rewardManager, feeReward);
            */
        }
    }

    function stakeExternalRewards() external {
        enterXJoeRewardPool();
    }

    function setXJoeStakingPoolId(uint256 _poolId) public onlyMultisig {
        exitRewardsForXJoe();

        xJoeStakingPoolId = _poolId;

        enterXJoeRewardPool();
    }

    function setOnxTreasuryFundAddress(address _address) public onlyMultisigOrOwner {
        treasury = _address;
    }
    /*
    function setRewardManagerAddress(address _address) public onlyMultisigOrOwner {
        rewardManager = _address;
    }
    */
}