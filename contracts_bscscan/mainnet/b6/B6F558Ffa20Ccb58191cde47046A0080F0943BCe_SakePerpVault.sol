/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

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
library SafeMathUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol






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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol


// solhint-disable-next-line compiler-version


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: @openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol




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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol




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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol




/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// File: contracts/utils/DecimalMath.sol



/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMathUpgradeable for uint256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// File: contracts/utils/Decimal.sol




library Decimal {
    using DecimalMath for uint256;
    using SafeMathUpgradeable for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// File: @openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol



/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: contracts/utils/SignedDecimalMath.sol



/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    using SignedSafeMathUpgradeable for int256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// File: contracts/utils/SignedDecimal.sol





library SignedDecimal {
    using SignedDecimalMath for int256;
    using SignedSafeMathUpgradeable for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// File: contracts/types/ISakePerpVaultTypes.sol

pragma experimental ABIEncoderV2;

interface ISakePerpVaultTypes {
    /**
     * @notice pool types
     * @param HIGH high risk pool
     * @param LOW low risk pool
     */
    enum Risk {HIGH, LOW}
}

// File: contracts/types/IExchangeTypes.sol




interface IExchangeTypes {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {ADD_TO_AMM, REMOVE_FROM_AMM}

    struct LiquidityChangedSnapshot {
        SignedDecimal.signedDecimal cumulativeNotional;
        // the base/quote reserve of amm right before liquidity changed
        Decimal.decimal quoteAssetReserve;
        Decimal.decimal baseAssetReserve;
        // total position size owned by amm after last snapshot taken
        // `totalPositionSize` = currentBaseAssetReserve - lastLiquidityChangedHistoryItem.baseAssetReserve + prevTotalPositionSize
        SignedDecimal.signedDecimal totalPositionSize;
    }
}

// File: contracts/interface/IExchange.sol







interface IExchange is IExchangeTypes {
    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit,
        bool _skipFluctuationCheck
    ) external returns (Decimal.decimal memory);

    function migrateLiquidity(Decimal.decimal calldata _liquidityMultiplier, Decimal.decimal calldata _priceLimitRatio)
        external;

    function shutdown() external;

    function settleFunding() external returns (SignedDecimal.signedDecimal memory);

    function calcFee(Decimal.decimal calldata _quoteAssetAmount) external view returns (Decimal.decimal memory);

    function calcBaseAssetAfterLiquidityMigration(
        SignedDecimal.signedDecimal memory _baseAssetAmount,
        Decimal.decimal memory _fromQuoteReserve,
        Decimal.decimal memory _fromBaseReserve
    ) external view returns (SignedDecimal.signedDecimal memory);

    function getInputTwap(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputTwap(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPrice(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputPrice(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getSpotPrice() external view returns (Decimal.decimal memory);

    function getLiquidityHistoryLength() external view returns (uint256);

    // overridden by state variable
    function quoteAsset() external view returns (IERC20Upgradeable);

    function open() external view returns (bool);

    // can not be overridden by state variable due to type `Deciaml.decimal`
    function getSettlementPrice() external view returns (Decimal.decimal memory);

    function getCumulativeNotional() external view returns (SignedDecimal.signedDecimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getLiquidityChangedSnapshots(uint256 i) external view returns (LiquidityChangedSnapshot memory);

    function mint(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function burn(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function getMMUnrealizedPNL(Decimal.decimal memory _baseAssetReserve, Decimal.decimal memory _quoteAssetReserve)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function moveAMMPriceToOracle(uint256 _oraclePrice, bytes32 _priceFeedKey) external;

    function setPriceFeed(address _priceFeed) external;

    function getReserve() external view returns (Decimal.decimal memory, Decimal.decimal memory);

    function initMarginRatio() external view returns (Decimal.decimal memory);

    function maintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function liquidationFeeRatio() external view returns (Decimal.decimal memory);

    function maxLiquidationFee() external view returns (Decimal.decimal memory);

    function spreadRatio() external view returns (Decimal.decimal memory);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function priceAdjustRatio() external view returns (uint256);

    function fluctuationLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function adjustTotalPosition(
        SignedDecimal.signedDecimal memory adjustedPosition,
        SignedDecimal.signedDecimal memory oldAdjustedPosition
    ) external;

    function getTotalPositionSize() external view returns (SignedDecimal.signedDecimal memory);

    function getExchangeState() external view returns (address);

    function getUnderlyingPrice() external view returns (Decimal.decimal memory);

    function isOverSpreadLimit() external view returns (bool);
}

// File: contracts/interface/ISakePerpVault.sol






interface ISakePerpVault is ISakePerpVaultTypes {
    function withdraw(
        IExchange _exchange,
        address _receiver,
        Decimal.decimal memory _amount
    ) external;

    function realizeBadDebt(IExchange _exchange, Decimal.decimal memory _badDebt) external;

    function modifyLiquidity() external;

    function getMMLiquidity(address _exchange, Risk _risk) external view returns (SignedDecimal.signedDecimal memory);

    function getAllMMLiquidity(address _exchange)
        external
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory);

    function getTotalMMLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getTotalMMAvailableLiquidity(address _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function getTotalLpUnrealizedPNL(IExchange _exchange) external view returns (SignedDecimal.signedDecimal memory);

    function addCachedLiquidity(address _exchange, Decimal.decimal memory _DeltalpLiquidity) external;

    function requireMMNotBankrupt(address _exchange) external;

    function getMMCachedLiquidity(address _exchange, Risk _risk) external view returns (Decimal.decimal memory);

    function getTotalMMCachedLiquidity(address _exchange) external view returns (Decimal.decimal memory);

    function setRiskLiquidityWeight(address _exchange, uint256 _highWeight, uint256 _lowWeight) external;

    function setMaxLoss(
        address _exchange,
        Risk _risk,
        uint256 _max
    ) external;
}

// File: contracts/interface/IInsuranceFund.sol




interface IInsuranceFund {
    function withdraw(Decimal.decimal calldata _amount) external returns (Decimal.decimal memory badDebt);

    function setExchange(IExchange _exchange) external;

    function setBeneficiary(address _beneficiary) external;
}

// File: contracts/interface/ISystemSettings.sol





interface ISystemSettings {
    function insuranceFundFeeRatio() external view returns (Decimal.decimal memory);

    function lpWithdrawFeeRatio() external view returns (Decimal.decimal memory);

    function overnightFeeRatio() external view returns (Decimal.decimal memory);

    function overnightFeeLpShareRatio() external view returns (Decimal.decimal memory);

    function fundingFeeLpShareRatio() external view returns (Decimal.decimal memory);

    function overnightFeePeriod() external view returns (uint256);

    function isExistedExchange(IExchange _exchange) external view returns (bool);

    function getAllExchanges() external view returns (IExchange[] memory);

    function getInsuranceFund(IExchange _exchange) external view returns (IInsuranceFund);

    function setNextOvernightFeeTime(IExchange _exchange) external;

    function nextOvernightFeeTime(address _exchange) external view returns (uint256);

    function checkTransfer(address _from, address _to) external view returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol







/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// File: contracts/MMLPToken.sol





contract MMLPToken is ERC20Upgradeable, OwnableUpgradeable {
    ISystemSettings public systemSettings;

    constructor(
        string memory _name,
        string memory _symbol,
        address _systemSettings
    ) public {
        systemSettings = ISystemSettings(_systemSettings);
        __ERC20_init(_name, _symbol);
        __Ownable_init();
    }

    function mint(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOwner {
        _burn(_account, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        amount;
        require(systemSettings.checkTransfer(from, to), "illegal transfer");
    }
}

// File: contracts/interface/IExchangeState.sol







interface IExchangeState {
    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function initMarginRatio() external view returns (Decimal.decimal memory);

    function maintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function liquidationFeeRatio() external view returns (Decimal.decimal memory);

    function maxLiquidationFee() external view returns (Decimal.decimal memory);

    function spreadRatio() external view returns (Decimal.decimal memory);

    function maxOracleSpreadRatio() external view returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        IExchangeTypes.Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        IExchangeTypes.Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function calcFee(Decimal.decimal calldata _quoteAssetAmount) external view returns (Decimal.decimal memory);

    function mint(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function burn(
        ISakePerpVaultTypes.Risk _level,
        address account,
        uint256 amount
    ) external;

    function getLPToken(ISakePerpVaultTypes.Risk _level) external view returns (MMLPToken);
}

// File: contracts/interface/ISakeMaster.sol


interface ISakeMaster {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 pengdingSake; // record sake amount when user withdraw lp.
        uint256 sakeRewardDebt; // Reward debt. See explanation below.
        uint256 cakeRewardDebt; // Reward debt. See explanation below.
        uint256 lastWithdrawBlock; // user last withdraw time;
    }

    function userInfo(uint256 poolId, address mm) external view returns (UserInfo memory);
}

// File: contracts/utils/MixedDecimal.sol





/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;
    using SignedSafeMathUpgradeable for int256;

    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE = "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(Decimal.decimal memory x)
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(SignedDecimal.signedDecimal memory x) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d.add(int256(y.d));
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d.sub(int256(y.d));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// File: contracts/SakePerpVault.sol

















contract SakePerpVault is ISakePerpVault, OwnableUpgradeable {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    //
    // EVENTS
    //
    event LiquidityAdd(
        address indexed exchange,
        address indexed account,
        uint256 risk,
        uint256 lpfund,
        uint256 tokenamount
    );
    event LiquidityRemove(
        address indexed exchange,
        address indexed account,
        uint256 risk,
        uint256 lpfund,
        uint256 tokenamount
    );
    //changeType shows the liquidity changed by what
    event LiquidityModify(address indexed exchange, uint256 lpfundHigh, uint256 lpfundLow);
    event BadDebtResolved(
        address indexed exchange,
        uint256 badDebt,
        uint256 insuranceFundResolveBadDebt,
        uint256 mmHighResolveBadDebt,
        uint256 mmLowResolveBadDebt
    );

    struct PoolInfo {
        SignedDecimal.signedDecimal totalLiquidity; // total liquidity of high/low risk pool
        Decimal.decimal totalFund; // fund of MM, not include the fee and pnl
        mapping(address => Decimal.decimal) fund;
        mapping(address => uint256) nextWithdrawTime;
        uint256 maxLoss;
    }

    struct ExchangeInfo {
        mapping(uint256 => PoolInfo) poolInfo; // pool info of high/low risk pool
        Decimal.decimal cachedLiquidity;
        uint256 highRiskLiquidityWeight;
        uint256 lowRiskLiquidityWeight;
    }

    uint256 private constant UINT100 = 100;
    ISystemSettings public systemSettings;
    address public sakePerp;
    uint256 public lpLockTime;

    // exchange info
    mapping(address => ExchangeInfo) public exchangeInfo;

    //**********************************************************//
    //    Can not change the order of above state variables     //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    ISakeMaster public sakeMaster;
    mapping(address => uint256) public poolIdMap;

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // MODIFIERS
    //
    modifier onlySakePerp() {
        require(_msgSender() == sakePerp, "only sakePerp");
        _;
    }

    //
    // PUBLIC
    //
    function initialize(
        address _sakePerp,
        address _systemSettings,
        uint256 _lockTime
    ) public initializer {
        sakePerp = _sakePerp;
        systemSettings = ISystemSettings(_systemSettings);
        lpLockTime = _lockTime;
        __Ownable_init();
    }

    /**
     * @notice set SakePerp dependency
     * @dev only owner can call
     * @param _sakePerp address
     */
    function setSakePerp(address _sakePerp) external onlyOwner {
        require(_sakePerp != address(0), "empty address");
        sakePerp = _sakePerp;
    }

    /**
     * @notice set systemSettings dependency
     * @dev only owner can call
     * @param _systemSettings address
     */
    function setSystemSettings(address _systemSettings) external onlyOwner {
        require(_systemSettings != address(0), "empty address");
        systemSettings = ISystemSettings(_systemSettings);
    }

    /**
     * @notice set high risk liquidity provider token weight
     * @dev only owner can call
     * @param _exchange address
     * @param _highWeight high risk pool lp token weight
     * @param _lowWeight low risk pool lp token weight
     */
    function setRiskLiquidityWeight(
        address _exchange,
        uint256 _highWeight,
        uint256 _lowWeight
    ) public override {
        require(_msgSender() == owner() || _msgSender() == _exchange, "invalid caller");
        require(_highWeight.add(_lowWeight) > 0, "invalid weight");
        exchangeInfo[_exchange].highRiskLiquidityWeight = _highWeight;
        exchangeInfo[_exchange].lowRiskLiquidityWeight = _lowWeight;
    }

    /**
     * @notice set pool max loss
     * @dev only owner can call
     * @param _exchange exchange address
     * @param _risk pool type
     * @param _max max loss
     */
    function setMaxLoss(
        address _exchange,
        Risk _risk,
        uint256 _max
    ) public override {
        require(_msgSender() == owner() || _msgSender() == _exchange, "invalid caller");
        require(_max > 0 && _max <= UINT100, "invalid max loss value");
        PoolInfo storage poolInfo = exchangeInfo[_exchange].poolInfo[uint256(_risk)];
        SignedDecimal.signedDecimal memory lpUnrealizedPNL = getLpUnrealizedPNL(_exchange, _risk);
        Decimal.decimal memory lockedLiquidity = poolInfo.totalFund.mulScalar(UINT100 - _max).divScalar(UINT100);
        require(!poolInfo.totalLiquidity.subD(lockedLiquidity).addD(lpUnrealizedPNL).isNegative(), "fund not enough");
        poolInfo.maxLoss = _max;
    }

    /**
     * @notice set lp liquidity lock time
     * @dev only owner can call
     * @param _lockTime new lock time
     */
    function setLpLockTime(uint256 _lockTime) external onlyOwner {
        lpLockTime = _lockTime;
    }

    /**
     * @notice set sakeMaster address
     * @dev only owner can call
     * @param _sakeMaster sakeMaster address
     */
    function setSakeMaster(address _sakeMaster) external onlyOwner {
        sakeMaster = ISakeMaster(_sakeMaster);
    }

    /**
     * @notice set pool id of exchange on sakeMaster
     * @dev only owner can call
     * @param _exchange exchange address
     * @param _id pool id on sakeMaster
     */
    function setPoolId(address _exchange, uint256 _id) external onlyOwner {
        poolIdMap[_exchange] = _id;
    }

    function setMMFund(address _exchange, address _mm, Decimal.decimal memory _fund) external onlyOwner {
        PoolInfo storage poolInfo = exchangeInfo[_exchange].poolInfo[0];
        poolInfo.totalFund = poolInfo.totalFund.addD(_fund);
        poolInfo.fund[_mm] = poolInfo.fund[_mm].addD(_fund);
    }

    /**
     * @notice withdraw token to trader/liquidator
     * @dev only SakePerp can call
     * @param _exchange exchange address
     * @param _receiver receiver, could be trader or liquidator
     * @param _amount token amount
     */
    function withdraw(
        IExchange _exchange,
        address _receiver,
        Decimal.decimal memory _amount
    ) public override onlySakePerp {
        _withdraw(_exchange, _receiver, _amount);
    }

    function _withdraw(
        IExchange _exchange,
        address _receiver,
        Decimal.decimal memory _amount
    ) internal {
        IERC20Upgradeable _token = _exchange.quoteAsset();
        Decimal.decimal memory totalTokenBalance = Decimal.decimal(_token.balanceOf(address(this)));
        if (totalTokenBalance.toUint() < _amount.toUint()) {
            Decimal.decimal memory balanceShortage = _amount.subD(totalTokenBalance);
            IInsuranceFund insuranceFund = systemSettings.getInsuranceFund(_exchange);
            Decimal.decimal memory totalInsurceFund = Decimal.decimal(_token.balanceOf(address(insuranceFund)));
            require(totalInsurceFund.toUint() >= balanceShortage.toUint(), "Fund not enough");
            insuranceFund.withdraw(balanceShortage);
        }

        _token.safeTransfer(_receiver, _amount.toUint());
    }

    function _realizeMMBadDebt(address _exchange, Decimal.decimal memory _badDebt)
        internal
        returns (Decimal.decimal memory, Decimal.decimal memory)
    {
        Decimal.decimal memory mmHighResolveBadDebt = Decimal.zero();
        Decimal.decimal memory mmLowResolveBadDebt = Decimal.zero();

        (SignedDecimal.signedDecimal memory highAvailable, SignedDecimal.signedDecimal memory lowAvailable) =
            getAllMMAvailableLiquidityWithPNL(_exchange);
        require(highAvailable.addD(lowAvailable).subD(_badDebt).toInt() >= 0, "MM Bankrupt");

        (Decimal.decimal memory highFactor, Decimal.decimal memory lowFactor) = _getMMFactor(_exchange);
        mmHighResolveBadDebt = _badDebt.mulD(highFactor).divD(highFactor.addD(lowFactor));
        mmLowResolveBadDebt = _badDebt.subD(mmHighResolveBadDebt);

        SignedDecimal.signedDecimal memory highRemainLiquidity = highAvailable.subD(mmHighResolveBadDebt);
        SignedDecimal.signedDecimal memory lowRemainLiquidity = lowAvailable.subD(mmLowResolveBadDebt);
        if (highRemainLiquidity.isNegative()) {
            mmHighResolveBadDebt = highAvailable.abs();
            mmLowResolveBadDebt = _badDebt.subD(mmHighResolveBadDebt);
        } else if (lowRemainLiquidity.isNegative()) {
            mmLowResolveBadDebt = lowAvailable.abs();
            mmHighResolveBadDebt = _badDebt.subD(mmLowResolveBadDebt);
        }

        PoolInfo storage highPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.HIGH)];
        PoolInfo storage lowPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.LOW)];
        highPool.totalLiquidity = highPool.totalLiquidity.subD(mmHighResolveBadDebt);
        lowPool.totalLiquidity = lowPool.totalLiquidity.subD(mmLowResolveBadDebt);

        return (mmHighResolveBadDebt, mmLowResolveBadDebt);
    }

    /**
     * @notice realize bad debt. insurance fund will pay first, lp fund will pay the rest
     * @dev only SakePerp can call
     * @param _exchange IExchange address
     * @param _badDebt amount of the bad debt
     */
    function realizeBadDebt(IExchange _exchange, Decimal.decimal memory _badDebt) external override onlySakePerp {
        // in order to realize all the bad debt vault need extra tokens from insuranceFund
        IInsuranceFund insuranceFund = systemSettings.getInsuranceFund(_exchange);
        Decimal.decimal memory totalInsuranceFund =
            Decimal.decimal(_exchange.quoteAsset().balanceOf(address(insuranceFund)));
        Decimal.decimal memory mmResolveBadDebt = Decimal.zero();
        Decimal.decimal memory insuranceFundResolveBadDebt = Decimal.zero();
        Decimal.decimal memory mmHighResolveBadDebt = Decimal.zero();
        Decimal.decimal memory mmLowResolveBadDebt = Decimal.zero();

        if (totalInsuranceFund.toUint() >= _badDebt.toUint()) {
            insuranceFund.withdraw(_badDebt);
            insuranceFundResolveBadDebt = _badDebt;
            mmResolveBadDebt = Decimal.zero();
        } else {
            insuranceFund.withdraw(totalInsuranceFund);
            insuranceFundResolveBadDebt = totalInsuranceFund;
            mmResolveBadDebt = _badDebt.subD(totalInsuranceFund);
        }

        if (mmResolveBadDebt.toUint() > 0) {
            (mmHighResolveBadDebt, mmLowResolveBadDebt) = _realizeMMBadDebt(address(_exchange), mmResolveBadDebt);
        }

        emit BadDebtResolved(
            address(_exchange),
            _badDebt.toUint(),
            insuranceFundResolveBadDebt.toUint(),
            mmHighResolveBadDebt.toUint(),
            mmLowResolveBadDebt.toUint()
        );
    }

    /**
     * @notice add cached liquidity to mm's total liquidity
     */
    function modifyLiquidity() external override {
        address _exchange = _msgSender();
        require(systemSettings.isExistedExchange(IExchange(_exchange)), "exchange not found");
        (Decimal.decimal memory highFactor, Decimal.decimal memory lowFactor) = _getMMFactor(_exchange);
        ExchangeInfo storage _exchangeInfo = exchangeInfo[_exchange];
        PoolInfo storage highPool = _exchangeInfo.poolInfo[uint256(Risk.HIGH)];
        PoolInfo storage lowPool = _exchangeInfo.poolInfo[uint256(Risk.LOW)];
        Decimal.decimal memory cachedLiquidity = _exchangeInfo.cachedLiquidity;
        Decimal.decimal memory cachedForHigh = cachedLiquidity.mulD(highFactor).divD(highFactor.addD(lowFactor));
        Decimal.decimal memory cachedForLow = cachedLiquidity.subD(cachedForHigh);
        highPool.totalLiquidity = highPool.totalLiquidity.addD(cachedForHigh);
        lowPool.totalLiquidity = lowPool.totalLiquidity.addD(cachedForLow);
        _exchangeInfo.cachedLiquidity = Decimal.zero();
        emit LiquidityModify(_exchange, cachedForHigh.toUint(), cachedForLow.toUint());
    }

    /**
     * @notice addCachedLiquidity (trader fee, overnight fee, trading spread)
     * @param _exchange exchange address
     * @param _DeltaLpLiquidity liquidity amount to be added
     */
    function addCachedLiquidity(address _exchange, Decimal.decimal memory _DeltaLpLiquidity)
        public
        override
        onlySakePerp
    {
        ExchangeInfo storage _exchangeInfo = exchangeInfo[_exchange];
        _exchangeInfo.cachedLiquidity = _exchangeInfo.cachedLiquidity.addD(_DeltaLpLiquidity);
    }

    /**
     * @notice addLiquidity to Exchange
     * @param _exchange IExchange address
     * @param _risk pool type
     * @param _quoteAssetAmount quote asset amount in 18 digits. Can Not be 0
     */
    function addLiquidity(
        IExchange _exchange,
        Risk _risk,
        Decimal.decimal memory _quoteAssetAmount
    ) external {
        requireExchange(_exchange, true);
        requireNonZeroInput(_quoteAssetAmount);

        address sender = _msgSender();
        _exchange.quoteAsset().safeTransferFrom(sender, address(this), _quoteAssetAmount.toUint());

        PoolInfo storage poolInfo = exchangeInfo[address(_exchange)].poolInfo[uint256(_risk)];
        SignedDecimal.signedDecimal memory lpUnrealizedPNL = getLpUnrealizedPNL(address(_exchange), _risk);

        Decimal.decimal memory totalLpTokenAmount =
            Decimal.decimal(IExchangeState(_exchange.getExchangeState()).getLPToken(_risk).totalSupply());
        if (totalLpTokenAmount.toUint() > 0) {
            _requireMMNotBankrupt(address(_exchange), _risk);
        }

        SignedDecimal.signedDecimal memory returnLpAmount = SignedDecimal.zero();
        if (totalLpTokenAmount.toUint() == 0) {
            returnLpAmount = MixedDecimal.fromDecimal(_quoteAssetAmount);
        } else {
            returnLpAmount = MixedDecimal.fromDecimal(_quoteAssetAmount).mulD(totalLpTokenAmount).divD(
                poolInfo.totalLiquidity.addD(lpUnrealizedPNL)
            );
        }

        if (poolInfo.fund[sender].toUint() == 0) {
            poolInfo.nextWithdrawTime[sender] = block.timestamp.add(lpLockTime);
        }

        poolInfo.totalLiquidity = poolInfo.totalLiquidity.addD(_quoteAssetAmount);
        poolInfo.totalFund = poolInfo.totalFund.addD(_quoteAssetAmount);
        poolInfo.fund[sender] = poolInfo.fund[sender].addD(_quoteAssetAmount);
        _exchange.mint(_risk, sender, returnLpAmount.toUint());

        emit LiquidityAdd(
            address(_exchange),
            sender,
            uint256(_risk),
            _quoteAssetAmount.toUint(),
            returnLpAmount.toUint()
        );
    }

    /**
     * @notice remove Liquidity from Exchange
     * @param _exchange IExchange address
     * @param _risk pool type
     * @param _lpTokenAmount lp token asset amount in 18 digits. Can Not be 0
     */
    function removeLiquidity(
        IExchange _exchange,
        Risk _risk,
        Decimal.decimal memory _lpTokenAmount
    ) external {
        PoolInfo storage poolInfo = exchangeInfo[address(_exchange)].poolInfo[uint256(_risk)];

        address sender = _msgSender();
        require(block.timestamp >= poolInfo.nextWithdrawTime[sender], "liquidity locked");
        requireExchange(_exchange, true);
        requireNonZeroInput(_lpTokenAmount);
        _requireMMNotBankrupt(address(_exchange), _risk);

        MMLPToken lpToken = IExchangeState(_exchange.getExchangeState()).getLPToken(_risk);
        SignedDecimal.signedDecimal memory lpUnrealizedPNL = getLpUnrealizedPNL(address(_exchange), _risk);
        Decimal.decimal memory totalLpTokenAmount = Decimal.decimal(lpToken.totalSupply());
        Decimal.decimal memory traderLpTokenAmount = Decimal.decimal(lpToken.balanceOf(sender).add(getDepositAmount(_exchange, sender)));
        Decimal.decimal memory removeFund = poolInfo.fund[sender].mulD(_lpTokenAmount).divD(traderLpTokenAmount);
        SignedDecimal.signedDecimal memory returnAmount =
            poolInfo.totalLiquidity.addD(lpUnrealizedPNL).mulD(_lpTokenAmount).divD(totalLpTokenAmount).mulD(
                Decimal.one().subD(systemSettings.lpWithdrawFeeRatio())
            );

        poolInfo.totalLiquidity = poolInfo.totalLiquidity.subD(returnAmount);
        poolInfo.totalFund = poolInfo.totalFund.subD(removeFund);
        poolInfo.fund[sender] = poolInfo.fund[sender].subD(removeFund);

        poolInfo.nextWithdrawTime[sender] = block.timestamp.add(lpLockTime);
        _exchange.burn(_risk, sender, _lpTokenAmount.toUint());
        _withdraw(_exchange, sender, returnAmount.abs());

        emit LiquidityRemove(
            address(_exchange),
            sender,
            uint256(_risk),
            returnAmount.toUint(),
            _lpTokenAmount.toUint()
        );
    }

    /**
     * @notice remove Liquidity from Exchange when shutdown
     * @param _exchange IExchange address
     * @param _risk pool type
     */
    function removeLiquidityWhenShutdown(IExchange _exchange, Risk _risk) external {
        address sender = _msgSender();
        requireExchange(_exchange, false);

        PoolInfo storage poolInfo = exchangeInfo[address(_exchange)].poolInfo[uint256(_risk)];
        SignedDecimal.signedDecimal memory lpUnrealizedPNL = getLpUnrealizedPNL(address(_exchange), _risk);
        SignedDecimal.signedDecimal memory remainAmount = poolInfo.totalLiquidity.addD(lpUnrealizedPNL);
        if (remainAmount.toInt() > 0) {
            MMLPToken lpToken = IExchangeState(_exchange.getExchangeState()).getLPToken(_risk);
            Decimal.decimal memory _lpTokenAmount = Decimal.decimal(lpToken.balanceOf(sender));
            Decimal.decimal memory totalLpTokenAmount = Decimal.decimal(lpToken.totalSupply());
            Decimal.decimal memory traderLpTokenAmount = Decimal.decimal(lpToken.balanceOf(sender).add(getDepositAmount(_exchange, sender)));
            Decimal.decimal memory removeFund = poolInfo.fund[sender].mulD(_lpTokenAmount).divD(traderLpTokenAmount);
            SignedDecimal.signedDecimal memory returnAmount =
                remainAmount.mulD(_lpTokenAmount).divD(totalLpTokenAmount);

            poolInfo.totalLiquidity = poolInfo.totalLiquidity.subD(returnAmount);
            poolInfo.totalFund = poolInfo.totalFund.subD(removeFund);
            poolInfo.fund[sender] = Decimal.zero();

            _exchange.burn(_risk, sender, _lpTokenAmount.toUint());
            _withdraw(_exchange, sender, returnAmount.abs());

            emit LiquidityRemove(
                address(_exchange),
                sender,
                uint256(_risk),
                returnAmount.toUint(),
                _lpTokenAmount.toUint()
            );
        }
    }

    //
    // VIEW FUNCTIONS
    //
    function getDepositAmount(IExchange _exchange, address _user) public view returns (uint256) {
        uint256 poolId = poolIdMap[address(_exchange)];
        if (poolId > 0) {
            ISakeMaster.UserInfo memory info = sakeMaster.userInfo(poolId, _user);
            return info.amount;
        }
        return 0;
    }
    
    function getTotalLpUnrealizedPNL(IExchange _exchange)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        (Decimal.decimal memory _quoteAssetReserve, Decimal.decimal memory _baseAssetReserve) = _exchange.getReserve();
        return _exchange.getMMUnrealizedPNL(_baseAssetReserve, _quoteAssetReserve);
    }

    function getAllLpUnrealizedPNL(address _exchange)
        public
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory totalLpUnrealizedPNL = getTotalLpUnrealizedPNL(IExchange(_exchange));
        (Decimal.decimal memory highFactor, Decimal.decimal memory lowFactor) = _getMMFactor(_exchange);
        if (totalLpUnrealizedPNL.toInt() == 0) {
            return (SignedDecimal.zero(), SignedDecimal.zero());
        }

        SignedDecimal.signedDecimal memory highUnrealizedPNL =
            totalLpUnrealizedPNL.mulD(highFactor).divD(highFactor.addD(lowFactor));
        SignedDecimal.signedDecimal memory lowUnrealizedPNL = totalLpUnrealizedPNL.subD(highUnrealizedPNL);

        {
            (SignedDecimal.signedDecimal memory highAvailable, SignedDecimal.signedDecimal memory lowAvailable) =
                getAllMMAvailableLiquidity(_exchange);
            SignedDecimal.signedDecimal memory highTotalLiquidity = highAvailable.addD(highUnrealizedPNL);
            SignedDecimal.signedDecimal memory lowTotalLiquidity = lowAvailable.addD(lowUnrealizedPNL);
            if (highTotalLiquidity.isNegative()) {
                highUnrealizedPNL = highAvailable.mulScalar(-1);
                lowUnrealizedPNL = totalLpUnrealizedPNL.subD(highUnrealizedPNL);
            } else if (lowTotalLiquidity.isNegative()) {
                lowUnrealizedPNL = lowAvailable.mulScalar(-1);
                highUnrealizedPNL = totalLpUnrealizedPNL.subD(lowUnrealizedPNL);
            }
        }

        return (highUnrealizedPNL, lowUnrealizedPNL);
    }

    function getLpUnrealizedPNL(address _exchange, Risk _risk)
        public
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        (SignedDecimal.signedDecimal memory high, SignedDecimal.signedDecimal memory low) =
            getAllLpUnrealizedPNL(_exchange);
        return _risk == Risk.HIGH ? high : low;
    }

    function getLpLiquidityAndUnrealizedPNL(address _exchange, Risk _risk)
        public
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory)
    {
        (SignedDecimal.signedDecimal memory highLiquidity, SignedDecimal.signedDecimal memory lowLiquidity) =
            getAllMMLiquidity(_exchange);
        (SignedDecimal.signedDecimal memory highUnrealizedPNL, SignedDecimal.signedDecimal memory lowUnrealizedPNL) =
            getAllLpUnrealizedPNL(_exchange);

        if (Risk.HIGH == _risk) {
            return (highLiquidity, highUnrealizedPNL);
        } else {
            return (lowLiquidity, lowUnrealizedPNL);
        }
    }

    function getLpTokenPrice(IExchange _exchange, Risk _risk)
        public
        view
        returns (int256 tokenPrice, int256 tokenPriceWithFee)
    {
        (SignedDecimal.signedDecimal memory lpLiquidity, SignedDecimal.signedDecimal memory lpUnrealizedPNL) =
            getLpLiquidityAndUnrealizedPNL(address(_exchange), _risk);

        Decimal.decimal memory totalLpTokenAmount =
            Decimal.decimal(IExchangeState(_exchange.getExchangeState()).getLPToken(_risk).totalSupply());
        if (totalLpTokenAmount.toUint() == 0) {
            tokenPriceWithFee = int256(Decimal.one().toUint());
            tokenPrice = int256(Decimal.one().toUint());
        } else {
            SignedDecimal.signedDecimal memory lpLiquidityWithFee =
                lpLiquidity.addD(getMMCachedLiquidity(address(_exchange), _risk));
            tokenPriceWithFee = lpUnrealizedPNL.addD(lpLiquidityWithFee).divD(totalLpTokenAmount).toInt();
            tokenPrice = lpUnrealizedPNL.addD(lpLiquidity).divD(totalLpTokenAmount).toInt();
        }
    }

    function getMMLiquidity(address _exchange, Risk _risk)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        return exchangeInfo[_exchange].poolInfo[uint256(_risk)].totalLiquidity;
    }

    function getAllMMLiquidity(address _exchange)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory)
    {
        PoolInfo memory highPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.HIGH)];
        PoolInfo memory lowPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.LOW)];
        return (highPool.totalLiquidity, lowPool.totalLiquidity);
    }

    function getAllMMAvailableLiquidity(address _exchange)
        public
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory)
    {
        PoolInfo memory highPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.HIGH)];
        PoolInfo memory lowPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.LOW)];
        Decimal.decimal memory highLockedLiquidity =
            highPool.totalFund.mulScalar(UINT100 - highPool.maxLoss).divScalar(UINT100);
        Decimal.decimal memory lowLockedLiquidity =
            lowPool.totalFund.mulScalar(UINT100 - lowPool.maxLoss).divScalar(UINT100);
        SignedDecimal.signedDecimal memory highAvailable = highPool.totalLiquidity.subD(highLockedLiquidity);
        SignedDecimal.signedDecimal memory lowAvailable = lowPool.totalLiquidity.subD(lowLockedLiquidity);
        return (highAvailable, lowAvailable);
    }

    function getAllMMAvailableLiquidityWithPNL(address _exchange)
        public
        view
        returns (SignedDecimal.signedDecimal memory, SignedDecimal.signedDecimal memory)
    {
        (SignedDecimal.signedDecimal memory highAvailable, SignedDecimal.signedDecimal memory lowAvailable) =
            getAllMMAvailableLiquidity(_exchange);
        (SignedDecimal.signedDecimal memory highUnrealizedPNL, SignedDecimal.signedDecimal memory lowUnrealizedPNL) =
            getAllLpUnrealizedPNL(_exchange);
        return (highAvailable.addD(highUnrealizedPNL), lowAvailable.addD(lowUnrealizedPNL));
    }

    function getTotalMMLiquidity(address _exchange) public view override returns (SignedDecimal.signedDecimal memory) {
        PoolInfo memory highPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.HIGH)];
        PoolInfo memory lowPool = exchangeInfo[_exchange].poolInfo[uint256(Risk.LOW)];
        return highPool.totalLiquidity.addD(lowPool.totalLiquidity);
    }

    function getTotalMMAvailableLiquidity(address _exchange)
        public
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        (SignedDecimal.signedDecimal memory high, SignedDecimal.signedDecimal memory low) =
            getAllMMAvailableLiquidity(_exchange);
        return high.addD(low);
    }

    function getMMCachedLiquidity(address _exchange, Risk _risk) public view override returns (Decimal.decimal memory) {
        Decimal.decimal memory cachedLiquidity = exchangeInfo[_exchange].cachedLiquidity;
        (Decimal.decimal memory highFactor, Decimal.decimal memory lowFactor) = _getMMFactor(_exchange);
        Decimal.decimal memory cachedForHigh = cachedLiquidity.mulD(highFactor).divD(highFactor.addD(lowFactor));
        Decimal.decimal memory cachedForLow = cachedLiquidity.subD(cachedForHigh);
        return Risk.HIGH == _risk ? cachedForHigh : cachedForLow;
    }

    function getTotalMMCachedLiquidity(address _exchange) public view override returns (Decimal.decimal memory) {
        return exchangeInfo[_exchange].cachedLiquidity;
    }

    function _getMMFactor(address _exchange) internal view returns (Decimal.decimal memory, Decimal.decimal memory) {
        ExchangeInfo memory _exchangeInfo = exchangeInfo[_exchange];
        return (
            Decimal.decimal(_exchangeInfo.highRiskLiquidityWeight),
            Decimal.decimal(_exchangeInfo.lowRiskLiquidityWeight)
        );
    }

    function getMaxLoss(address _exchange) public view returns (uint256, uint256) {
        return (
            exchangeInfo[_exchange].poolInfo[uint256(Risk.HIGH)].maxLoss,
            exchangeInfo[_exchange].poolInfo[uint256(Risk.LOW)].maxLoss
        );
    }

    function getPoolWeight(address _exchange) public view returns (uint256, uint256) {
        return (exchangeInfo[_exchange].highRiskLiquidityWeight, exchangeInfo[_exchange].lowRiskLiquidityWeight);
    }

    function getLockedLiquidity(
        address _exchange,
        Risk _risk,
        address _mm
    ) public view returns (Decimal.decimal memory) {
        PoolInfo storage poolInfo = exchangeInfo[_exchange].poolInfo[uint256(_risk)];
        return poolInfo.fund[_mm].mulScalar(UINT100 - poolInfo.maxLoss).divScalar(UINT100);
    }

    function getTotalFund(address _exchange, Risk _risk) public view returns (Decimal.decimal memory) {
        return exchangeInfo[_exchange].poolInfo[uint256(_risk)].totalFund;
    }

    function getFund(
        address _exchange,
        Risk _risk,
        address _mm
    ) public view returns (Decimal.decimal memory) {
        return exchangeInfo[_exchange].poolInfo[uint256(_risk)].fund[_mm];
    }

    function getNextWidhdrawTime(
        address _exchange,
        Risk _risk,
        address _mm
    ) public view returns (uint256) {
        return exchangeInfo[_exchange].poolInfo[uint256(_risk)].nextWithdrawTime[_mm];
    }

    //
    // REQUIRE FUNCTIONS
    //
    function requireMMNotBankrupt(address _exchange) public override {
        SignedDecimal.signedDecimal memory totalLpUnrealizedPNL = getTotalLpUnrealizedPNL(IExchange(_exchange));
        (SignedDecimal.signedDecimal memory highLiquidity, SignedDecimal.signedDecimal memory lowLiquidity) =
            getAllMMLiquidity(_exchange);
        require(totalLpUnrealizedPNL.addD(highLiquidity).addD(lowLiquidity).toInt() > 0, "MM Bankrupt");
    }

    function _requireMMNotBankrupt(address _exchange, Risk _risk) internal view {
        (SignedDecimal.signedDecimal memory lpLiquidity, SignedDecimal.signedDecimal memory lpUnrealizedPNL) =
            getLpLiquidityAndUnrealizedPNL(_exchange, _risk);
        require(lpUnrealizedPNL.addD(lpLiquidity).toInt() >= 0, "MM Bankrupt");
    }

    function requireNonZeroInput(Decimal.decimal memory _decimal) private pure {
        require(_decimal.toUint() != 0, "input is 0");
    }

    function requireExchange(IExchange _exchange, bool _open) private view {
        require(systemSettings.isExistedExchange(_exchange), "exchange not found");
        require(_open == _exchange.open(), _open ? "exchange was closed" : "exchange is open");
    }
}