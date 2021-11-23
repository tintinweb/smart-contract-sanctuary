// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.6.6;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes memory) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

pragma solidity ^0.6.6;

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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.6;

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
abstract contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {}

    function init(address owner_) internal initializer {
        _setOwner(owner_);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.6;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

pragma solidity ^0.6.6;

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
        require(b <= a, errorMessage);
        return a - b;
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.6;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.6.6;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: @uniswap/v3-periphery/contracts/interfaces/IQuoter.sol

pragma solidity ^0.6.6;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes calldata path, uint256 amountIn)
        external
        returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes calldata path, uint256 amountOut)
        external
        returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol

pragma solidity ^0.6.6;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol

pragma solidity ^0.6.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// File: customAggV2.sol

pragma solidity ^0.6.6;

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function factory() external pure returns (address);
}

interface IUniswapV3Router is ISwapRouter {
    function refundETH() external payable;

    function factory() external pure returns (address);

    function WETH9() external pure returns (address);

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pair);
}

interface IUniswapV2Pair {
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external pure returns (address);

    function token1() external pure returns (address);
}

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 public constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalBalanceOf(IERC20 token, address who)
        public
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) public pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

// DAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
// WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

contract Swap is Ownable {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IUniswapV2Router public sushiswapRouter;

    IUniswapV2Router public uniswapRouterV2;

    IUniswapV3Router public uniswapRouterV3;

    IQuoter public quoterV3;

    uint24 public poolFee;

    function initialize(address _owner) public initializer {
        Ownable.init(_owner);

        sushiswapRouter = IUniswapV2Router(
            0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
        );
        uniswapRouterV2 = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapRouterV3 = IUniswapV3Router(
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        quoterV3 = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
        poolFee = 3000;
    }

    function getPairRateSushi(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256 _amountOut) {
        require(_tokenIn != _tokenOut, "Both tokens are same");

        if (UniversalERC20.isETH(_tokenIn)) {
            _tokenIn = IERC20(sushiswapRouter.WETH());
        } else if (UniversalERC20.isETH(_tokenOut)) {
            _tokenOut = IERC20(sushiswapRouter.WETH());
        }

        if (
            IUniswapV2Router(sushiswapRouter.factory()).getPair(
                address(_tokenIn),
                address(_tokenOut)
            ) != address(0)
        ) {
            address[] memory path = new address[](2);
            path[0] = address(_tokenIn);
            path[1] = address(_tokenOut);

            uint256[] memory amountsOut = sushiswapRouter.getAmountsOut(
                _amountIn,
                path
            );

            _amountOut = amountsOut[1];
        }
    }

    function getPairRateUniV2(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256 _amountOut) {
        require(_tokenIn != _tokenOut, "Both tokens are same");

        if (UniversalERC20.isETH(_tokenIn)) {
            _tokenIn = IERC20(uniswapRouterV2.WETH());
        } else if (UniversalERC20.isETH(_tokenOut)) {
            _tokenOut = IERC20(uniswapRouterV2.WETH());
        }

        if (
            IUniswapV2Router(uniswapRouterV2.factory()).getPair(
                address(_tokenIn),
                address(_tokenOut)
            ) != address(0)
        ) {
            address[] memory path = new address[](2);
            path[0] = address(_tokenIn);
            path[1] = address(_tokenOut);

            uint256[] memory amountsOut = uniswapRouterV2.getAmountsOut(
                _amountIn,
                path
            );

            _amountOut = amountsOut[1];
        }
    }

    function getPairRateUniV3(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256 _amountOut) {
        require(_tokenIn != _tokenOut, "Both tokens are same");

        if (UniversalERC20.isETH(_tokenIn)) {
            _tokenIn = IERC20(uniswapRouterV3.WETH9());
        } else if (UniversalERC20.isETH(_tokenOut)) {
            _tokenOut = IERC20(uniswapRouterV3.WETH9());
        }

        if (
            IUniswapV3Router(uniswapRouterV3.factory()).getPool(
                address(_tokenIn),
                address(_tokenOut),
                poolFee
            ) != address(0)
        ) {
            uint160 sqrtPriceLimitX96 = 0;

            _amountOut = quoterV3.quoteExactInputSingle(
                address(_tokenIn),
                address(_tokenOut),
                poolFee,
                _amountIn,
                sqrtPriceLimitX96
            );
        }
    }

    // important to receive ETH
    receive() external payable {}

    function getBestExchangeRate(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn
    ) external payable returns (uint256 amountOut, uint8 platform) {
        uint256[] memory returnAmounts = new uint256[](3);

        returnAmounts[0] = getPairRateSushi(_tokenIn, _tokenOut, _amountIn);
        returnAmounts[1] = getPairRateUniV2(_tokenIn, _tokenOut, _amountIn);
        returnAmounts[2] = getPairRateUniV3(_tokenIn, _tokenOut, _amountIn);

        uint256 amount = 0;
        uint8 index;

        for (uint8 i = 0; i < returnAmounts.length; i++) {
            if (amount < returnAmounts[i]) {
                amount = returnAmounts[i];
                index = i;
            }
        }

        require(amount > 0, "No liquidity added");

        amountOut = amount;
        platform = index;
    }

    function getPairV2(
        address factory,
        address token0,
        address token1
    ) internal view returns (address) {
        return IUniswapV2Router(factory).getPair(token0, token1);
    }

    function getPairV3(
        address factory,
        address token0,
        address token1
    ) internal view returns (address) {
        return IUniswapV3Router(factory).getPool(token0, token1, poolFee);
    }

    function getReserveV2(address pairAddress)
        internal
        view
        returns (
            address _tokenIn,
            uint256 _tokenInBal,
            uint256 _tokenoutBal
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 liq1, uint112 liq2, ) = pair.getReserves();
        _tokenIn = pair.token0();
        _tokenInBal = uint256(liq1).sub(pair.MINIMUM_LIQUIDITY());
        _tokenoutBal = uint256(liq2).sub(pair.MINIMUM_LIQUIDITY());
    }

    function getReserveV3(address pair, IERC20 token0)
        internal
        view
        returns (uint256 token0Bal)
    {
        token0Bal = token0.balanceOf(pair);
    }

    function sushiSwap(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal {
        require(_tokenIn != _tokenOut, "Both tokens are same");
        require(_amountIn > 0, "Amount too small to swap");
        require(
            getPairRateSushi(_tokenIn, _tokenOut, _amountIn) >=
                _amountOutMinimum,
            "Insufficient output amount"
        );

        address[] memory path = new address[](2);

        if (UniversalERC20.isETH(_tokenIn)) {
            path[0] = sushiswapRouter.WETH();
            path[1] = address(_tokenOut);
        } else if (UniversalERC20.isETH(_tokenOut)) {
            path[0] = address(_tokenIn);
            path[1] = sushiswapRouter.WETH();
        } else {
            path[0] = address(_tokenIn);
            path[1] = address(_tokenOut);
        }

        address pairAddress = getPairV2(
            sushiswapRouter.factory(),
            path[0],
            path[1]
        );

        require(pairAddress != address(0), "Pair doesn't exist");

        (
            address token0,
            uint256 _tokenInSwapAmount,
            uint256 _tokenOutSwapAmount
        ) = getReserveV2(pairAddress);

        uint256 maxSwapAmount;

        if (path[0] == token0) {
            maxSwapAmount = _tokenInSwapAmount;
        } else {
            maxSwapAmount = _tokenOutSwapAmount;
        }

        require(_amountIn <= maxSwapAmount, "Not enough liquidity");

        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            _amountIn
        );

        TransferHelper.safeApprove(
            path[0],
            address(sushiswapRouter),
            _amountIn
        );

        if (UniversalERC20.isETH(_tokenIn)) {
            sushiswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: msg.value
            }(_amountOutMinimum, path, msg.sender, block.timestamp);
        } else if (UniversalERC20.isETH(_tokenOut)) {
            sushiswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amountIn,
                _amountOutMinimum,
                path,
                msg.sender,
                block.timestamp
            );
        } else {
            sushiswapRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountIn,
                    _amountOutMinimum,
                    path,
                    msg.sender,
                    block.timestamp
                );
        }
    }

    function uniSwapV2(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal {
        require(_tokenIn != _tokenOut, "Both tokens are same");
        require(_amountIn > 0, "Amount too small to swap");
        require(
            getPairRateUniV2(_tokenIn, _tokenOut, _amountIn) >=
                _amountOutMinimum,
            "Insufficient output amount"
        );

        address[] memory path = new address[](2);

        if (UniversalERC20.isETH(_tokenIn)) {
            path[0] = uniswapRouterV2.WETH();
            path[1] = address(_tokenOut);
        } else if (UniversalERC20.isETH(_tokenOut)) {
            path[0] = address(_tokenIn);
            path[1] = uniswapRouterV2.WETH();
        } else {
            path[0] = address(_tokenIn);
            path[1] = address(_tokenOut);
        }

        address pairAddress = getPairV2(
            uniswapRouterV2.factory(),
            address(path[0]),
            address(path[1])
        );

        require(pairAddress != address(0), "Pair doesn't exist");

        (
            address token0,
            uint256 _tokenInSwapAmount,
            uint256 _tokenOutSwapAmount
        ) = getReserveV2(pairAddress);

        uint256 maxSwapAmount;

        if (path[0] == token0) {
            maxSwapAmount = _tokenInSwapAmount;
        } else {
            maxSwapAmount = _tokenOutSwapAmount;
        }

        require(_amountIn <= maxSwapAmount, "Not enough liquidity");
        if(!UniversalERC20.isETH(_tokenIn)){
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            _amountIn
        );

        TransferHelper.safeApprove(
            path[0],
            address(uniswapRouterV2),
            _amountIn
        );

        }

        if (UniversalERC20.isETH(_tokenIn)) {
            uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: msg.value
            }(_amountOutMinimum, path, msg.sender, block.timestamp);
        } else if (UniversalERC20.isETH(_tokenOut)) {
            uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amountIn,
                _amountOutMinimum,
                path,
                msg.sender,
                block.timestamp
            );
        } else {
            uniswapRouterV2
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountIn,
                    _amountOutMinimum,
                    path,
                    msg.sender,
                    block.timestamp
                );
        }
    }

    function uniSwapV3(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal {
        require(_tokenIn != _tokenOut, "Both tokens are same");
        require(_amountIn > 0, "Amount too small to swap");
        require(
            getPairRateUniV3(_tokenIn, _tokenOut, _amountIn) >=
                _amountOutMinimum,
            "Insufficient output amount"
        );

        if (UniversalERC20.isETH(_tokenIn)) {
            _tokenIn = IERC20(uniswapRouterV3.WETH9());
        } else if (UniversalERC20.isETH(_tokenOut)) {
            _tokenOut = IERC20(uniswapRouterV3.WETH9());
        }

        address pairAddress = getPairV3(
            uniswapRouterV3.factory(),
            address(_tokenIn),
            address(_tokenOut)
        );

        require(pairAddress != address(0), "Pair doesn't exist");

        uint256 _tokenInSwapAmount = getReserveV3(pairAddress, _tokenIn);

        require(_amountIn <= _tokenInSwapAmount, "Not enough liquidity");

        TransferHelper.safeTransferFrom(
            address(_tokenIn),
            msg.sender,
            address(this),
            _amountIn
        );

        TransferHelper.safeApprove(
            address(_tokenIn),
            address(uniswapRouterV3),
            _amountIn
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(_tokenIn),
                tokenOut: address(_tokenOut),
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        uniswapRouterV3.exactInputSingle(params);
    }

    function swapFromBestExchange(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24 _exchange
    ) external payable returns (uint256 returnAmount) {
        Balances memory beforeBalances = _getFirstAndLastBalances(
            _tokenIn,
            _tokenOut
        );

        if (_exchange == 0) {
            sushiSwap(_tokenIn, _tokenOut, _amountIn, _amountOutMinimum);
        } else if (_exchange == 1) {
            uniSwapV2(_tokenIn, _tokenOut, _amountIn, _amountOutMinimum);
        } else if (_exchange == 2) {
            uniSwapV3(_tokenIn, _tokenOut, _amountIn, _amountOutMinimum);
        } else {
            revert("No more swaps available");
        }

        Balances memory afterBalances = _getFirstAndLastBalances(
            _tokenIn,
            _tokenOut
        );

        returnAmount = afterBalances.ofDestToken.sub(
            beforeBalances.ofDestToken
        );
    }

    struct Balances {
        uint256 ofFromToken;
        uint256 ofDestToken;
    }

    function _getFirstAndLastBalances(IERC20 _tokenIn, IERC20 _tokenOut)
        internal
        view
        returns (Balances memory)
    {
        return
            Balances({
                ofFromToken: _tokenIn.universalBalanceOf(msg.sender),
                ofDestToken: _tokenOut.universalBalanceOf(msg.sender)
            });
    }
}