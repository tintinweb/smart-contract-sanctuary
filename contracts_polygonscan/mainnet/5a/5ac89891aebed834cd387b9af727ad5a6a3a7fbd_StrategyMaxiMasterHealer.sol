/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

// File: vaults-v1/contracts/libs/IUniRouter01.sol





pragma solidity >=0.6.12;



interface IUniRouter01 {

    function factory() external pure returns (address);



    function WETH() external pure returns (address);



    function addLiquidity(

        address tokenA,

        address tokenB,

        uint256 amountADesired,

        uint256 amountBDesired,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline

    )

        external

        returns (

            uint256 amountA,

            uint256 amountB,

            uint256 liquidity

        );



    function addLiquidityETH(

        address token,

        uint256 amountTokenDesired,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    )

        external

        payable

        returns (

            uint256 amountToken,

            uint256 amountETH,

            uint256 liquidity

        );



    function removeLiquidity(

        address tokenA,

        address tokenB,

        uint256 liquidity,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountA, uint256 amountB);



    function removeLiquidityETH(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountToken, uint256 amountETH);



    function removeLiquidityWithPermit(

        address tokenA,

        address tokenB,

        uint256 liquidity,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountA, uint256 amountB);



    function removeLiquidityETHWithPermit(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountToken, uint256 amountETH);



    function swapExactTokensForTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapTokensForExactTokens(

        uint256 amountOut,

        uint256 amountInMax,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapExactETHForTokens(

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable returns (uint256[] memory amounts);



    function swapTokensForExactETH(

        uint256 amountOut,

        uint256 amountInMax,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapExactTokensForETH(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapETHForExactTokens(

        uint256 amountOut,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable returns (uint256[] memory amounts);



    function quote(

        uint256 amountA,

        uint256 reserveA,

        uint256 reserveB

    ) external pure returns (uint256 amountB);



    function getAmountOut(

        uint256 amountIn,

        uint256 reserveIn,

        uint256 reserveOut

    ) external pure returns (uint256 amountOut);



    function getAmountIn(

        uint256 amountOut,

        uint256 reserveIn,

        uint256 reserveOut

    ) external pure returns (uint256 amountIn);



    function getAmountsOut(uint256 amountIn, address[] calldata path)

        external

        view

        returns (uint256[] memory amounts);



    function getAmountsIn(uint256 amountOut, address[] calldata path)

        external

        view

        returns (uint256[] memory amounts);

}
// File: vaults-v1/contracts/libs/IUniRouter02.sol





pragma solidity >=0.6.12;




interface IUniRouter02 is IUniRouter01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountETH);



    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountETH);



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

}
// File: vaults-v1/contracts/libs/IStrategyFish.sol





pragma solidity >=0.6.12;



interface IStrategyFish {

    function depositReward(uint256 _depositAmt) external returns (bool);

}
// File: @openzeppelin/contracts/proxy/utils/Initializable.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/Math.sol



pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


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
    constructor() {
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
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: vaults-v1/contracts/BaseStrategy.sol





pragma solidity ^0.8.4;












enum StratType { BASIC, MASTER_HEALER, MAXIMIZER_CORE, MAXIMIZER }



abstract contract BaseStrategy is Ownable, ReentrancyGuard, Pausable, Initializable {

    using Math for uint256;

    using SafeERC20 for IERC20;



    address public wantAddress;

    address public earnedAddress;

    address public uniRouterAddress;

    address public vaultChefAddress;

    address public govAddress;

    address public masterchefAddress;

    address public maxiAddress; // zero and unused except for maximizer vaults. This is the maximized want token

    StratType public stratType;

    

    uint256 public pid;

    uint256 public lastEarnBlock;

    uint256 public sharesTotal;

    uint256 public controllerFee;

    uint256 public rewardRate;

    uint256 public buyBackRate;

    uint256 public withdrawFeeFactor; 

    uint256 public slippageFactor;



    // Frontend variables

    uint256 public tolerance;

    uint256 public burnedAmount;

    

    StrategyPaths internal paths;

    

    address public constant wmaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address public constant usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public constant crystlAddress = 0x76bF0C28e604CC3fE9967c83b3C3F31c213cfE64; 

    address public constant rewardAddress = 0x917FB15E8aAA12264DCBdC15AFef7cD3cE76BA39; 

    address public constant withdrawFeeAddress = 0x5386881b46C37CdD30A748f7771CF95D7B213637; 

    address public constant feeAddress = 0x5386881b46C37CdD30A748f7771CF95D7B213637; 

    

    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant feeMaxTotal = 1000;

    uint256 public constant feeMax = 10000; // 100 = 1%

    uint256 public constant withdrawFeeFactorMax = 10000;

    uint256 public constant withdrawFeeFactorLL = 9900; 

    uint256 public constant slippageFactorUL = 995;



    event SetSettings(

        uint256 _controllerFee,

        uint256 _rewardRate,

        uint256 _buyBackRate,

        uint256 _withdrawFeeFactor,

        uint256 _slippageFactor,

        uint256 _tolerance,

        address _uniRouterAddress

    );

    

    modifier onlyGov() {

        require(msg.sender == govAddress, "!gov");

        _;

    }



    function _baseInit() internal initializer {

        lastEarnBlock = block.number;

        controllerFee = 50;

        buyBackRate = 450;

        withdrawFeeFactor = 9990; // 0.1% withdraw fee

        slippageFactor = 950; // 5% default slippage tolerance

    }



    function _vaultDeposit(uint256 _amount) internal virtual;

    function _vaultWithdraw(uint256 _amount) internal virtual;

    function earn() external virtual;

    function vaultSharesTotal() public virtual view returns (uint256);

    function wantLockedTotal() public virtual view returns (uint256);

    function _resetAllowances() internal virtual;

    function _emergencyVaultWithdraw() internal virtual;

    

    function deposit(address /*_userAddress*/, uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {

        // Call must happen before transfer

        uint256 wantLockedBefore = wantLockedTotal();



        IERC20(wantAddress).safeTransferFrom(

            address(msg.sender),

            address(this),

            _wantAmt

        );



        // Proper deposit amount for tokens with fees, or vaults with deposit fees

        uint256 sharesAdded = _farm();

        if (sharesTotal > 0) {

            sharesAdded = sharesAdded * sharesTotal / wantLockedBefore;

        }

        sharesTotal += sharesAdded;



        return sharesAdded;

    }



    function _farm() internal returns (uint256) {

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));

        if (wantAmt == 0) return 0;

        

        uint256 sharesBefore = vaultSharesTotal();

        _vaultDeposit(wantAmt);

        uint256 sharesAfter = vaultSharesTotal();

        

        return sharesAfter - sharesBefore;

    }



    function withdraw(address /*_userAddress*/, uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256) {

        require(_wantAmt > 0, "_wantAmt is 0");

        

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));

        

        // Check if strategy has tokens from panic

        if (_wantAmt > wantAmt) {

            _vaultWithdraw(_wantAmt - wantAmt);

            wantAmt = IERC20(wantAddress).balanceOf(address(this));

        }



        if (_wantAmt > wantAmt) {

            _wantAmt = wantAmt;

        }



        if (_wantAmt > wantLockedTotal()) {

            _wantAmt = wantLockedTotal();

        }



        uint256 sharesRemoved = (_wantAmt * sharesTotal).ceilDiv(wantLockedTotal());

        if (sharesRemoved > sharesTotal) {

            sharesRemoved = sharesTotal;

        }

        sharesTotal -= sharesRemoved;

        

        // Withdraw fee

        uint256 withdrawFee = _wantAmt * (withdrawFeeFactorMax - withdrawFeeFactor) / withdrawFeeFactorMax;

        if (withdrawFee > 0) {

            IERC20(wantAddress).safeTransfer(withdrawFeeAddress, withdrawFee);

        }

        

        _wantAmt -= withdrawFee;



        IERC20(wantAddress).safeTransfer(vaultChefAddress, _wantAmt);



        return sharesRemoved;

    }



    // To pay for earn function

    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {

        if (controllerFee > 0) {

            uint256 fee = _earnedAmt * controllerFee / feeMax;

    

            _safeSwapWmatic(

                fee,

                paths.earnedToWmatic,

                feeAddress

            );

            

            _earnedAmt -= fee;

        }



        return _earnedAmt;

    }



    function distributeRewards(uint256 _earnedAmt) internal returns (uint256) {

        if (rewardRate > 0) {

            uint256 fee = _earnedAmt * rewardRate / feeMax;

    

            uint256 usdcBefore = IERC20(usdcAddress).balanceOf(address(this));

            

            _safeSwap(

                fee,

                paths.earnedToUsdc,

                address(this)

            );

            

            uint256 usdcAfter = IERC20(usdcAddress).balanceOf(address(this)) - usdcBefore;

            

            IStrategyFish(rewardAddress).depositReward(usdcAfter);

            

            _earnedAmt -= fee;

        }



        return _earnedAmt;

    }



    function buyBack(uint256 _earnedAmt) internal virtual returns (uint256) {

        if (buyBackRate > 0) {

            uint256 buyBackAmt = _earnedAmt * buyBackRate / feeMax;

    

            _safeSwap(

                buyBackAmt,

                paths.earnedToCrystl,

                buyBackAddress

            );



            _earnedAmt -= buyBackAmt;

        }

        

        return _earnedAmt;

    }



    function resetAllowances() external onlyGov {

        _resetAllowances();

    }



    function pause() external onlyGov {

        _pause();

    }



    function unpause() external onlyGov {

        _unpause();

        _resetAllowances();

    }



    function panic() external onlyGov {

        _pause();

        _emergencyVaultWithdraw();

    }



    function unpanic() external onlyGov {

        _unpause();

        _farm();

    }



    function setGov(address _govAddress) external onlyGov {

        govAddress = _govAddress;

    }

    

    function setSettings(

        uint256 _controllerFee,

        uint256 _rewardRate,

        uint256 _buyBackRate,

        uint256 _withdrawFeeFactor,

        uint256 _slippageFactor,

        uint256 _tolerance,

        address _uniRouterAddress

    ) external onlyGov {

        require(_controllerFee + _rewardRate + _buyBackRate <= feeMaxTotal, "Max fee of 10%");

        require(_withdrawFeeFactor >= withdrawFeeFactorLL, "_withdrawFeeFactor too low");

        require(_withdrawFeeFactor <= withdrawFeeFactorMax, "_withdrawFeeFactor too high");

        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");

        controllerFee = _controllerFee;

        rewardRate = _rewardRate;

        buyBackRate = _buyBackRate;

        withdrawFeeFactor = _withdrawFeeFactor;

        slippageFactor = _slippageFactor;

        tolerance = _tolerance;

        uniRouterAddress = _uniRouterAddress;



        emit SetSettings(

            _controllerFee,

            _rewardRate,

            _buyBackRate,

            _withdrawFeeFactor,

            _slippageFactor,

            _tolerance,

            _uniRouterAddress

        );

    }

    

    function _safeSwap(

        uint256 _amountIn,

        address[] memory _path,

        address _to

    ) internal {

        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);

        uint256 amountOut = amounts[amounts.length - 1];

        

        if (_path[_path.length - 1] == crystlAddress && _to == buyBackAddress) {

            burnedAmount += amountOut;

        }



        IUniRouter02(uniRouterAddress).swapExactTokensForTokens(

            _amountIn,

            amountOut * slippageFactor / 1000,

            _path,

            _to,

            block.timestamp + 600

        );

    }

    

    function _safeSwapWmatic(

        uint256 _amountIn,

        address[] memory _path,

        address _to

    ) internal {

        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);

        uint256 amountOut = amounts[amounts.length - 1];



        IUniRouter02(uniRouterAddress).swapExactTokensForETH(

            _amountIn,

            amountOut * slippageFactor / 1000,

            _path,

            _to,

            block.timestamp + 600

        );

    }

}
// File: vaults-v1/contracts/BaseStrategyMaxiSingle.sol





pragma solidity ^0.8.4;





abstract contract BaseStrategyMaxiSingle is BaseStrategy {



    function _vaultHarvest() internal virtual;



    function earn() external override nonReentrant whenNotPaused onlyOwner {

        // Harvest farm tokens

        _vaultHarvest();



        // Converts farm tokens into want tokens

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));



        if (earnedAmt > 0) {

            earnedAmt = distributeFees(earnedAmt);

            earnedAmt = distributeRewards(earnedAmt);

            earnedAmt = buyBack(earnedAmt);

    

            if (earnedAddress != maxiAddress) {

                // Swap all earned to maximized token

                _safeSwap(

                    earnedAmt,

                    paths.earnedToMaxi,

                    address(this)

                );

            }

    

            lastEarnBlock = block.number;

    

            IVaultHealer(vaultChefAddress).maximizerDeposit(IERC20(maxiAddress).balanceOf(address(this)));

            _farm();

        }

    }



}
// File: vaults-v1/contracts/libs/StrategySwapPaths.sol



pragma solidity ^0.8.4;

struct StrategyPaths {
    address[] earnedToWmatic;
    address[] earnedToUsdc;
    address[] earnedToCrystl;
    address[] earnedToToken0;
    address[] earnedToToken1;
    address[] token0ToEarned;
    address[] token1ToEarned;
    address[] earnedToMaxi;
}

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

library StrategySwapPaths {
    
    address internal constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    function buildAllPaths(StrategyPaths storage paths, address earnedAddress, address middleStep, address crystl, address want, address maxi) public {
            
        makeEarnedToWmaticPath(paths.earnedToWmatic, earnedAddress, middleStep);
        makeEarnedToXPath(paths.earnedToUsdc, paths.earnedToWmatic, USDC);
        makeEarnedToXPath(paths.earnedToCrystl, paths.earnedToWmatic, crystl);
        
        if (maxi != address(0))  makeEarnedToXPath(paths.earnedToMaxi, paths.earnedToWmatic, maxi);
        try IUniPair(want).token0() returns (address _token0) {
            address _token1 = IUniPair(want).token1();
            makeEarnedToXPath(paths.earnedToToken0, paths.earnedToWmatic, _token0);
            makeEarnedToXPath(paths.earnedToToken1, paths.earnedToWmatic, _token1);
            reverseArray(paths.token0ToEarned, paths.earnedToToken0);
            reverseArray(paths.token1ToEarned, paths.earnedToToken1);
        } catch {}

    }
    
    function makeEarnedToWmaticPath(address[] storage _path, address earnedAddress, address middleStep) public {

         _path.push(earnedAddress);
        
        if (earnedAddress == WMATIC) {
        } else if (middleStep == address(0)) {
            _path.push(WMATIC);
        } else {
            _path.push(middleStep);
            _path.push(WMATIC);
        }
    }
    function makeEarnedToXPath(address[] storage _path, address[] memory earnedToWmaticPath, address xToken) public {
        
        if (earnedToWmaticPath[0] == xToken) {
        } else if (earnedToWmaticPath[1] == xToken) {
            _path.push(earnedToWmaticPath[0]);
        } else {
            for (uint i; i < earnedToWmaticPath.length; i++) {
                _path.push(earnedToWmaticPath[i]);
            }
        }
        _path.push(xToken);
    }
    
    function reverseArray(address[] storage _reverse, address[] storage _array) internal {
        for (uint i; i < _array.length; i++) {
            _reverse.push(_array[_array.length - 1 - i]);
        }
    }
    
}
// File: vaults-v1/contracts/libs/IVaultHealer.sol



pragma solidity >=0.6.12;

interface IVaultHealer {

    function poolInfo(uint _pid) external view returns (address want, address strat);
    
    function maximizerDeposit(uint _amount) external;
}
// File: vaults-v1/contracts/libs/IMasterchef.sol





pragma solidity >=0.6.12;



interface IMasterchef {

    function deposit(uint256 _pid, uint256 _amount) external;



    function withdraw(uint256 _pid, uint256 _amount) external;



    function emergencyWithdraw(uint256 _pid) external;

    

    function userInfo(uint256 _pid, address _address) external view returns (uint256, uint256);

    

    function harvest(uint256 _pid, address _to) external;

    

}
// File: vaults-v1/contracts/StrategyMaxiMasterHealer.sol





pragma solidity ^0.8.4;







//Can be used for both single-stake and LP want tokens

contract StrategyMaxiMasterHealer is BaseStrategyMaxiSingle {

    using SafeERC20 for IERC20;



    function initialize(

        uint256 _pid,

        uint256 _tolerance,

        address _govAddress,

        address _masterChef,

        address _uniRouter,

        address _wantAddress, 

        address _earnedAddress,

        address _earnedToWmaticStep //address(0) if swapping earned->wmatic directly, or the address of an intermediate trade token such as weth

    ) external {

        

        _baseInit();



        govAddress = _govAddress;



        vaultChefAddress = msg.sender;

        masterchefAddress = _masterChef;

        uniRouterAddress = _uniRouter;

        wantAddress = _wantAddress;

        earnedAddress = _earnedAddress;

        (maxiAddress,) = IVaultHealer(vaultChefAddress).poolInfo(0);

        

        pid = _pid;

        tolerance = _tolerance;

        

        StrategySwapPaths.buildAllPaths(paths, _wantAddress, _earnedToWmaticStep, crystlAddress, _wantAddress, maxiAddress);

        

        transferOwnership(vaultChefAddress);

        

        stratType = StratType.MAXIMIZER;

        _resetAllowances();

    }



    function _vaultDeposit(uint256 _amount) internal override {

        IMasterchef(masterchefAddress).deposit(pid, _amount);

    }

    

    function _vaultWithdraw(uint256 _amount) internal override {

        IMasterchef(masterchefAddress).withdraw(pid, _amount);

    }

    

    function _vaultHarvest() internal override {

        IMasterchef(masterchefAddress).withdraw(pid, 0);

    }

    

    function vaultSharesTotal() public override view returns (uint256) {

        (uint256 amount,) = IMasterchef(masterchefAddress).userInfo(pid, address(this));

        return amount;

    }

    

    function wantLockedTotal() public override view returns (uint256) {

        return IERC20(wantAddress).balanceOf(address(this)) + vaultSharesTotal();

    }



    function _resetAllowances() internal override {

        IERC20(wantAddress).safeApprove(masterchefAddress, type(uint256).max);

        IERC20(earnedAddress).safeApprove(uniRouterAddress, type(uint256).max);

        IERC20(usdcAddress).safeApprove(rewardAddress, type(uint256).max);

    }

    

    function _emergencyVaultWithdraw() internal override {

        IMasterchef(masterchefAddress).emergencyWithdraw(pid);

    }

}