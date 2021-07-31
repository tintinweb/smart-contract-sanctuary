/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

    constructor() {
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
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

interface IStrategy {
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    function wantAddress() external view returns (address);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    function earnedAddress() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);

    function migrateFrom(
        address _oldStrategy,
        uint256 _oldWantLockedTotal,
        uint256 _oldSharesTotal
    ) external;

    function inCaseTokensGetStuck(address _token, uint256 _amount) external;

    function inFarmBalance() external view returns (uint256);

    function totalBalance() external view returns (uint256);
}

interface IRewarder {
    function onPviReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 pviAmount,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 pviAmount
    ) external view returns (address[] memory, uint256[] memory);
}

interface ICappedMintableBurnableERC20 {
    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function minter(address) external view returns (bool);

    function mint(address, uint256) external;

    function burn(uint256) external;

    function burnFrom(address, uint256) external;
}

interface ITokenLocker {
    function startReleaseTime() external view returns (uint256);

    function endReleaseTime() external view returns (uint256);

    function totalLock() external view returns (uint256);

    function totalReleased() external view returns (uint256);

    function lockOf(address _account) external view returns (uint256);

    function released(address _account) external view returns (uint256);

    function canUnlockAmount(address _account) external view returns (uint256);

    function lock(address _account, uint256 _amount) external;

    function unlock(uint256 _amount) external;

    function unlockAll() external;

    function claimUnlocked() external;
}

contract PolyVaultsBank is OwnableUpgradeable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        // We do some fancy math here. Basically, any point in time, the amount of BDO
        // entitled to a user but is pending to be distributed is:
        //
        //   amount = user.shares / sharesTotal * wantLockedTotal
        //   pending reward = (amount * pool.accRewardToken1PerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardToken1PerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

        uint256 lastStakeTime;
        uint256 lastHarvestTime;
        uint256 totalDeposit;
        uint256 totalWithdraw;
    }

    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. BDO to distribute per block.
        uint256 lastRewardTime; // Last block number that reward distribution occurs.
        uint256 accPviPerShare; // Accumulated PVIs per share, times 1e18. See below.
        address strategy; // Strategy address that will auto compound want tokens
        uint256 earlyWithdrawFee; // 10000
        uint256 earlyWithdrawTime; // 10000
        bool isStarted; // if lastRewardTime has passed
        uint256 startTime;
    }

    address public pvi = address(0x7A5dc8A09c831251026302C93A778748dd48b4DF);
    uint256 public totalRewardPerSecond;
    uint256 public rewardPerSecond;

    uint256 public startTime;

    uint256 public week;
    uint256 public nextHalvingTime;
    uint256 public rewardHalvingRate;

    //   TOTAL:                     800,000,000 PVI
    //   =============================================
    //   > LP Incentive (to Farm):  520,000,000 (65.0%)
    //   > Dev + MKT:               180,000,000 (22.5%)
    //   > Reserve Fund:             80,000,000 (10.0%)
    //   > Insurance Fund:           20,000,000 ( 2.5%)

    uint256 public devRate;
    uint256 public reserveRate;
    uint256 public insuranceRate;

    address public devFund;
    address public reserveFund;
    address public insuranceFund;

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => IRewarder) public rewarder;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.

    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.

    address public timelock;

    address public locker;
    uint256 public lockPercent;

    mapping(address => bool) public whitelisted;
    mapping(uint256 => bool) public pausePool;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    // ...

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed want, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTime, uint256 sharesTotal, uint256 accPviPerShare);
    event LogRewardPerSecond(uint256 rewardPerSecond);

    modifier onlyTimelock() {
        require(timelock == msg.sender, "PolyVaultsBank: caller is not timelock");
        _;
    }

    modifier notContract() {
        if (!whitelisted[msg.sender]) {
            uint256 size;
            address addr = msg.sender;
            assembly {
                size := extcodesize(addr)
            }
            require(size == 0, "contract not allowed");
            require(tx.origin == msg.sender, "contract not allowed");
        }
        _;
    }

    modifier checkHalving() {
        if (rewardHalvingRate < 10000) {
            if (block.timestamp >= nextHalvingTime) {
                massUpdatePools();
                uint256 _totalRewardPerSecond = (totalRewardPerSecond * rewardHalvingRate) / 10000;
                totalRewardPerSecond = _totalRewardPerSecond;
                _updateRewardPerSecond();
                nextHalvingTime = nextHalvingTime + 7 days;
                ++week;
            }
        }
        _;
    }

    function initialize(
        address _pvi,
        address _locker,
        address _devFund,
        address _reserveFund,
        address _insuranceFund,
        uint256 _totalRewardPerSecond,
        uint256 _startTime
    ) public initializer {
        require(block.timestamp < _startTime, "late");
        OwnableUpgradeable.__Ownable_init();

        pvi = _pvi;
        locker = _locker;
        lockPercent = 6000; // 60%

        devRate = 2250; // 22.5% (Dev + MKT)
        reserveRate = 1000; // 10%
        insuranceRate = 250; // 2.5%

        devFund = _devFund;
        reserveFund = _reserveFund;
        insuranceFund = _insuranceFund;

        totalRewardPerSecond = _totalRewardPerSecond; // 0.021372 PVI/seconds
        _updateRewardPerSecond();

        week = 0;
        startTime = _startTime;
        nextHalvingTime = _startTime + 7 days;

        rewardHalvingRate = 9900; // 99% - 1% halving weekly
    }

    function resetStartTime(uint256 _startTime) external onlyOwner {
        require(startTime > block.timestamp && _startTime > block.timestamp, "late");
        startTime = _startTime;
        nextHalvingTime = _startTime + 7 days;
    }

    function _updateRewardPerSecond() internal {
        uint256 _totalRewardPerSecond = totalRewardPerSecond;
        uint256 _totalRate = devRate + reserveRate + insuranceRate;
        rewardPerSecond = _totalRewardPerSecond - ((_totalRewardPerSecond * _totalRate) / 10000);
        emit LogRewardPerSecond(rewardPerSecond);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function startReleaseTime() public view returns (uint256) {
        return (lockPercent == 0 || locker == address(0)) ? 0 : ITokenLocker(locker).startReleaseTime();
    }

    function endReleaseTime() external view returns (uint256) {
        return (lockPercent == 0 || locker == address(0)) ? 0 : ITokenLocker(locker).endReleaseTime();
    }

    //    function checkPoolDuplicate(IERC20 _want) internal view {
    //        uint256 length = poolInfo.length;
    //        for (uint256 pid = 0; pid < length; ++pid) {
    //            require(poolInfo[pid].want != _want, "PolyVaultsBank: existing pool?");
    //        }
    //    }

    function addPool(
        uint256 _allocPoint,
        IERC20 _want,
        address _strategy,
        uint256 _lastRewardTime,
        uint256 _earlyWithdrawFee,
        uint256 _earlyWithdrawTime,
        IRewarder _rewarder
    ) public onlyOwner {
        // checkPoolDuplicate(_want);
        massUpdatePools();
        if (block.timestamp < startTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = startTime;
            } else {
                if (_lastRewardTime < startTime) {
                    _lastRewardTime = startTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (_lastRewardTime <= startTime) || (_lastRewardTime <= block.timestamp);
        rewarder[poolInfo.length] = _rewarder;
        poolInfo.push(
            PoolInfo({
                want: _want,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accPviPerShare: 0,
                strategy: _strategy,
                earlyWithdrawFee: _earlyWithdrawFee,
                earlyWithdrawTime: _earlyWithdrawTime,
                isStarted: _isStarted,
                startTime: _lastRewardTime
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
        emit LogPoolAddition(poolInfo.length.sub(1), _allocPoint, _want, _rewarder);
    }

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _earlyWithdrawFee,
        uint256 _earlyWithdrawTime,
        IRewarder _rewarder
    ) public onlyOwner {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        pool.allocPoint = _allocPoint;
        pool.earlyWithdrawFee = _earlyWithdrawFee;
        pool.earlyWithdrawTime = _earlyWithdrawTime;
        if (address(_rewarder) != address(0)) {
            rewarder[_pid] = _rewarder;
        }
        emit LogSetPool(_pid, _allocPoint, _rewarder);
    }

    function resetStrategy(uint256 _pid, address _strategy) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(IERC20(pool.want).balanceOf(pool.strategy) == 0 || pool.accPviPerShare == 0, "strategy not empty");
        pool.strategy = _strategy;
    }

    //    function migrateStrategy(uint256 _pid, address _newStrategy) public onlyOwner {
    //        require(IStrategy(_newStrategy).wantLockedTotal() == 0 && IStrategy(_newStrategy).sharesTotal() == 0, "new strategy not empty");
    //        PoolInfo storage pool = poolInfo[_pid];
    //        address _oldStrategy = pool.strategy;
    //        uint256 _oldSharesTotal = IStrategy(_oldStrategy).sharesTotal();
    //        uint256 _oldWantAmt = IStrategy(_oldStrategy).wantLockedTotal();
    //        IStrategy(_oldStrategy).withdraw(address(this), _oldWantAmt);
    //        pool.want.transfer(_newStrategy, _oldWantAmt);
    //        IStrategy(_newStrategy).migrateFrom(_oldStrategy, _oldWantAmt, _oldSharesTotal);
    //        pool.strategy = _newStrategy;
    //    }

    function setLockPercent(uint256 _lockPercent) external onlyOwner {
        require(_lockPercent <= 10000, "exceed 100%");
        massUpdatePools();
        lockPercent = _lockPercent;
    }

    function setRewardHalvingRate(uint256 _rewardHalvingRate) external onlyOwner {
        require(_rewardHalvingRate >= 9000, "below 90%");
        massUpdatePools();
        rewardHalvingRate = _rewardHalvingRate;
    }

    function setTotalRewardPerSecond(uint256 _totalRewardPerSecond) external onlyOwner {
        require(_totalRewardPerSecond <= 1 ether, "insane high rate");
        massUpdatePools();
        totalRewardPerSecond = _totalRewardPerSecond;
        _updateRewardPerSecond();
    }

    function setRates(
        uint256 _devRate,
        uint256 _reserveRate,
        uint256 _insuranceRate
    ) external onlyOwner {
        require(_devRate <= 4500, "too high"); // <= 45%
        require(_reserveRate <= 3500, "too high"); // <= 35%
        require(_insuranceRate <= 1000, "too high"); // <= 10%
        massUpdatePools();
        devRate = _devRate;
        reserveRate = _reserveRate;
        insuranceRate = _insuranceRate;
        _updateRewardPerSecond();
    }

    function setFunds(
        address _devFund,
        address _reserveFund,
        address _insuranceFund
    ) external onlyOwner {
        if (_devFund != address(0)) devFund = _devFund;
        if (_reserveFund != address(0)) reserveFund = _reserveFund;
        if (_insuranceFund != address(0)) insuranceFund = _insuranceFund;
    }

    // View function to see pending reward on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 _accPviPerShare = pool.accPviPerShare;
        uint256 sharesTotal = IStrategy(pool.strategy).sharesTotal();
        if (block.timestamp > pool.lastRewardTime && sharesTotal != 0) {
            uint256 _seconds = block.timestamp - pool.lastRewardTime;
            if (totalAllocPoint > 0) {
                uint256 _reward = (_seconds * rewardPerSecond * pool.allocPoint) / totalAllocPoint;
                _accPviPerShare += (_reward * 1e18) / sharesTotal;
            }
        }
        return user.shares.mul(_accPviPerShare).div(1e18).sub(user.rewardDebt);
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256) {
        address _strategy = poolInfo[_pid].strategy;
        uint256 _sharesTotal = IStrategy(_strategy).sharesTotal();
        uint256 _wantLockedTotal = IStrategy(_strategy).wantLockedTotal();
        if (_sharesTotal == 0) {
            return 0;
        }
        return userInfo[_pid][_user].shares.mul(_wantLockedTotal).div(_sharesTotal);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.want) == address(0)) {
            return;
        }
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 sharesTotal = IStrategy(pool.strategy).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _seconds = block.timestamp - pool.lastRewardTime;
            uint256 _reward = (_seconds * rewardPerSecond * pool.allocPoint) / totalAllocPoint;
            pool.accPviPerShare += (_reward * 1e18) / sharesTotal;
        }
        pool.lastRewardTime = block.timestamp;
        emit LogUpdatePool(_pid, pool.lastRewardTime, sharesTotal, pool.accPviPerShare);
    }

    function _harvestReward(uint256 _pid, address _account) internal {
        UserInfo storage user = userInfo[_pid][_account];
        uint256 _amount = user.shares;
        uint256 _claimableAmount = 0;
        if (_amount > 0) {
            PoolInfo memory pool = poolInfo[_pid];
            uint256 _totalReward = (_amount * pool.accPviPerShare) / 1e18;
            if (_totalReward < user.rewardDebt) {
                user.rewardDebt = _totalReward;
            } else {
                _claimableAmount = _totalReward - user.rewardDebt;
            }
            if (_claimableAmount > 0) {
                require(_claimableAmount * 200 <= IERC20(pvi).totalSupply(), "Suspicious big reward amount!!"); // <= 0.5% total supply
                emit RewardPaid(_account, _claimableAmount);

                _topupFunds(_claimableAmount);
                _safePviMint(address(this), _claimableAmount);

                address _locker = locker;

                if (lockPercent > 0 && _locker != address(0)) {
                    uint256 _startReleaseTime = startReleaseTime();
                    uint256 _userLastHarvestTime = user.lastHarvestTime;
                    if (block.timestamp <= _startReleaseTime) {
                        uint256 _lockAmount = _claimableAmount.mul(lockPercent).div(10000);
                        _claimableAmount = _claimableAmount.sub(_lockAmount);
                        IERC20(pvi).safeIncreaseAllowance(_locker, _lockAmount);
                        ITokenLocker(_locker).lock(_account, _lockAmount);
                    } else if (_userLastHarvestTime < _startReleaseTime) {
                        uint256 _beforeReleaseSeconds = (_userLastHarvestTime == 0) ? _startReleaseTime.sub(startTime) : _startReleaseTime.sub(_userLastHarvestTime);
                        // uint256 _afterReleaseSeconds = block.timestamp.sub(_startReleaseTime);
                        uint256 _lockAmount = _claimableAmount.mul(_beforeReleaseSeconds).div(_beforeReleaseSeconds.add(block.timestamp.sub(_startReleaseTime))).mul(lockPercent).div(10000);
                        _claimableAmount = _claimableAmount.sub(_lockAmount);
                        IERC20(pvi).safeIncreaseAllowance(_locker, _lockAmount);
                        ITokenLocker(_locker).lock(_account, _lockAmount);
                    }
                }

                _safePviTransfer(_account, _claimableAmount);
                user.lastHarvestTime = block.timestamp;
            }
        }
        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPviReward(_pid, msg.sender, _account, _claimableAmount, _amount);
        }
    }

    function _checkStrategyBalanceAfterDeposit(
        address _strategy,
        uint256 _depositAmount,
        uint256 _oldInFarmBalance,
        uint256 _oldTotalBalance
    ) internal view {
        require(_oldInFarmBalance + _depositAmount <= IStrategy(_strategy).inFarmBalance(), "Short of strategy infarm balance: need audit!");
        require(_oldTotalBalance + _depositAmount <= IStrategy(_strategy).totalBalance(), "Short of strategy total balance: need audit!");
    }

    function _checkStrategyBalanceAfterWithdraw(
        address _strategy,
        uint256 _withdrawAmount,
        uint256 _oldInFarmBalance,
        uint256 _oldTotalBalance
    ) internal view {
        require(_oldInFarmBalance <= _withdrawAmount + IStrategy(_strategy).inFarmBalance(), "Short of strategy infarm balance: need audit!");
        require(_oldTotalBalance <= _withdrawAmount + IStrategy(_strategy).totalBalance(), "Short of strategy total balance: need audit!");
    }

    function deposit(uint256 _pid, uint256 _wantAmt) external nonReentrant notContract checkHalving {
        require(!pausePool[_pid], "paused");
        require(_wantAmt == 0 || _wantAmt > 1, "bad deposit");
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.shares > 0) {
            _harvestReward(_pid, msg.sender);
        }
        if (_wantAmt > 0) {
            IERC20 _want = pool.want;
            address _strategy = pool.strategy;
            uint256 _before = _want.balanceOf(address(this));
            _want.safeTransferFrom(address(msg.sender), address(this), _wantAmt);
            uint256 _after = _want.balanceOf(address(this));
            _wantAmt = _after - _before; // fix issue of deflation token
            _want.safeIncreaseAllowance(_strategy, _wantAmt);
            uint256 sharesAdded;
            {
                uint256 _oldInFarmBalance = IStrategy(_strategy).inFarmBalance();
                uint256 _oldTotalBalance = IStrategy(_strategy).totalBalance();
                sharesAdded = IStrategy(_strategy).deposit(msg.sender, _wantAmt);
                _checkStrategyBalanceAfterDeposit(_strategy, _wantAmt, _oldInFarmBalance, _oldTotalBalance);
            }
            user.shares = user.shares.add(sharesAdded);
            user.totalDeposit = user.totalDeposit.add(_wantAmt);
            user.lastStakeTime = block.timestamp;
        }
        user.rewardDebt = (user.shares * pool.accPviPerShare) / 1e18;
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    function earlyWithdrawTimeEnd(uint256 _pid, address _account) public view returns (uint256) {
        return (whitelisted[_account]) ? userInfo[_pid][_account].lastStakeTime : userInfo[_pid][_account].lastStakeTime + poolInfo[_pid].earlyWithdrawTime;
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _wantAmt) public nonReentrant notContract checkHalving {
        require(!pausePool[_pid], "paused");
        require(_wantAmt == 0 || _wantAmt > 1, "bad withdraw");
        updatePool(_pid);

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        address _strategy = pool.strategy;
        uint256 _wantLockedTotal = IStrategy(_strategy).wantLockedTotal();
        uint256 _sharesTotal = IStrategy(_strategy).sharesTotal();

        require(user.shares > 0, "PolyVaultsBank: user.shares is 0");
        require(_sharesTotal > 0, "PolyVaultsBank: sharesTotal is 0");

        _harvestReward(_pid, msg.sender);

        // Withdraw want tokens
        uint256 amount = user.shares.mul(_wantLockedTotal).div(_sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved;
            {
                uint256 _oldInFarmBalance = IStrategy(_strategy).inFarmBalance();
                uint256 _oldTotalBalance = IStrategy(_strategy).totalBalance();
                sharesRemoved = IStrategy(_strategy).withdraw(msg.sender, _wantAmt);
                _checkStrategyBalanceAfterWithdraw(_strategy, _wantAmt, _oldInFarmBalance, _oldTotalBalance);
            }

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            IERC20 _want = pool.want;
            uint256 wantBal = _want.balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }

            if (_wantAmt > 0) {
                if (block.timestamp >= earlyWithdrawTimeEnd(_pid, msg.sender)) {
                    _want.safeTransfer(address(msg.sender), _wantAmt);
                } else {
                    uint256 fee = _wantAmt.mul(pool.earlyWithdrawFee).div(10000);
                    uint256 userReceivedAmount = _wantAmt.sub(fee);
                    _want.safeTransfer(owner(), fee);
                    _want.safeTransfer(address(msg.sender), userReceivedAmount);
                }
                user.totalWithdraw = user.totalWithdraw.add(_wantAmt);
            }
        }
        user.rewardDebt = (user.shares * pool.accPviPerShare) / 1e18;
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) external notContract {
        withdraw(_pid, 0);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external notContract nonReentrant {
        require(!pausePool[_pid], "paused");

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        address _strategy = pool.strategy;
        uint256 _wantLockedTotal = IStrategy(_strategy).wantLockedTotal();
        uint256 _sharesTotal = IStrategy(_strategy).sharesTotal();
        uint256 amount = user.shares.mul(_wantLockedTotal).div(_sharesTotal);

        user.shares = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onPviReward(_pid, msg.sender, msg.sender, 0, 0);
        }

        IStrategy(_strategy).withdraw(msg.sender, amount);
        if (amount > 0) {
            IERC20 _want = pool.want;
            if (block.timestamp >= earlyWithdrawTimeEnd(_pid, msg.sender)) {
                _want.safeTransfer(address(msg.sender), amount);
            } else {
                uint256 fee = amount.mul(pool.earlyWithdrawFee).div(10000);
                uint256 userReceivedAmount = amount.sub(fee);
                _want.safeTransfer(owner(), fee);
                _want.safeTransfer(address(msg.sender), userReceivedAmount);
            }
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function _safePviMint(address _to, uint256 _amount) internal {
        address _pvi = pvi;
        if (ICappedMintableBurnableERC20(_pvi).minter(address(this)) && _to != address(0)) {
            uint256 _totalSupply = IERC20(_pvi).totalSupply();
            uint256 _cap = ICappedMintableBurnableERC20(_pvi).cap();
            uint256 _mintAmount = (_totalSupply + _amount <= _cap) ? _amount : (_cap - _totalSupply);
            if (_mintAmount > 0) {
                ICappedMintableBurnableERC20(_pvi).mint(_to, _mintAmount);
            }
        }
    }

    function _safePviTransfer(address _to, uint256 _amount) internal {
        address _pvi = pvi;
        uint256 _pviBal = IERC20(_pvi).balanceOf(address(this));
        if (_pviBal > 0) {
            if (_amount > _pviBal) {
                IERC20(_pvi).safeTransfer(_to, _pviBal);
            } else {
                IERC20(_pvi).safeTransfer(_to, _amount);
            }
        }
    }

    function _topupFunds(uint256 _claimableAmount) internal {
        address _pvi = pvi;
        uint256 _totalAmount = (_claimableAmount * totalRewardPerSecond) / rewardPerSecond;
        uint256 _devAmount = (_totalAmount * devRate) / 10000;
        uint256 _reserveAmount = (_totalAmount * reserveRate) / 10000;
        uint256 _insuranceAmount = (_totalAmount * insuranceRate) / 10000;
        uint256 _totalMintAmount = _devAmount + _reserveAmount + _insuranceAmount;
        if (ICappedMintableBurnableERC20(_pvi).minter(address(this)) && IERC20(_pvi).totalSupply() + _totalMintAmount <= ICappedMintableBurnableERC20(_pvi).cap()) {
            ICappedMintableBurnableERC20(_pvi).mint(devFund, _devAmount);
            ICappedMintableBurnableERC20(_pvi).mint(reserveFund, _reserveAmount);
            ICappedMintableBurnableERC20(_pvi).mint(insuranceFund, _insuranceAmount);
        }
    }

    function setWhitelisted(address _account, bool _whitelisted) external nonReentrant onlyOwner {
        whitelisted[_account] = _whitelisted;
    }

    function setPausePool(uint256 _pid, bool _pausePool) external nonReentrant onlyOwner {
        pausePool[_pid] = _pausePool;
    }

    /* ========== EMERGENCY ========== */

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock || (timelock == address(0) && msg.sender == owner()), "PolyVaultsBank: !authorised");
        timelock = _timelock;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyTimelock {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    /**
     * @dev This is from Timelock contract.
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) external onlyTimelock returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "PolyVaultsBank::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}