/**
 *Submitted for verification at polygonscan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IFarmingPool {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdrawAll(uint256 _pid) external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

interface IStrategy {
    function want() external view returns (address);

    function farmingToken() external view returns (address);

    function targetProfitToken() external view returns (address);

    function inFarmBalance() external view returns (uint256);

    function totalBalance() external view returns (uint256);

    function deposit(address _account, uint256 _amount) external;

    function withdraw(address _account, uint256 _amount) external;

    function withdrawAll() external;
}

interface IPolyDexRouterV2 {
    event Exchange(address pair, uint256 amountOut, address output);
    event ChangeGovernance(address indexed governance);
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }

    function factory() external view returns (address);

    function formula() external view returns (address);

    function swapFeeReward() external view returns (address);

    function WETH() external view returns (address);

    function setGovernance(address) external;

    function addLiquidity(
        address pair,
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
        address pair,
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

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address tokenOut,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline
    ) external payable returns (uint256 totalAmountOut);

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline
    ) external payable returns (uint256 totalAmountIn);

    function createPair(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address to
    ) external returns (uint256 liquidity);

    function createPairETH(
        address token,
        uint256 amountToken,
        address to
    ) external payable returns (uint256 liquidity);

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address pair,
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
        address pair,
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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
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
}

/*
    Bancor Formula interface
*/
interface IPolyDexFormula {
    function getReserveAndWeights(address pair, address tokenA)
        external
        view
        returns (
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint32 tokenWeightA,
            uint32 tokenWeightB,
            uint32 swapFee
        );

    function getFactoryReserveAndWeights(
        address factory,
        address pair,
        address tokenA
    )
        external
        view
        returns (
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint32 tokenWeightA,
            uint32 tokenWeightB,
            uint32 swapFee
        );

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountIn);

    function getPairAmountIn(
        address pair,
        address tokenIn,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountOut);

    function getPairAmountOut(
        address pair,
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function ensureConstantValue(
        uint256 reserve0,
        uint256 reserve1,
        uint256 balance0Adjusted,
        uint256 balance1Adjusted,
        uint32 tokenWeight0
    ) external view returns (bool);

    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function mintLiquidityFee(
        uint256 totalLiquidity,
        uint112 reserve0,
        uint112 reserve1,
        uint112 collectedFee0,
        uint112 collectedFee1
    ) external view returns (uint256 amount);
}

abstract contract StrategyBase is Ownable, ReentrancyGuard, Pausable, IStrategy {
    using SafeERC20 for IERC20;

    address public controller;
    address public operator;
    address public strategist;

    address public override want;
    address public override farmingToken;
    address public override targetProfitToken;

    address public farmingPool;
    uint256 public farmingPoolId;

    address public profitReceiver = address(0x2C7b3425fC0cc552a0965a2671daA2C693bE46dE); // OperationFund

    address public polydexRouter = address(0xC60aE14F2568b102F8Ca6266e8799112846DD088);
    address public polydexFormula = address(0x992f8B188439da78705b6d1E67571EF888693754);
    mapping(address => mapping(address => address[])) public polydexPaths;

    address public constant weth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address public constant wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public constant usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    uint256 private constant USDC_MISSING_DECIMALS_MULTIPLER = 10**12;

    address public timelock = address(0xd2fbBA7FcE609b6cfA0fdE4fA7ae27D3AfC77446); // 6h timelock
    bool public notPublic = false; // allow public to call earn() function

    uint256 public lastEarnTime = 0;

    uint256 public operatorFee = 500;
    uint256 public constant operatorFeeMax = 10000; // 100 = 1%
    uint256 public constant operatorFeeUL = 1000;

    uint256 public autoEarnLimit = 100 ether; // $100
    uint256 public autoEarnDelaySeconds = 6 hours;

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Farm(uint256 amount);
    event Earned(address earnedAddress, uint256 earnedAmt);
    event DistributeFee(address earnedAddress, uint256 fee, address receiver);
    event InCaseTokensGetStuck(address tokenAddress, uint256 tokenAmt, address receiver);
    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    constructor(
        address _controller,
        address _want,
        address _farmingToken,
        address _farmingPool,
        uint256 _farmingPoolId,
        address _targetProfitToken,
        address[] memory _farmingToken2UsdcPath,
        address[] memory _farmingToken2TargetProfitTokenPath
    ) {
        controller = _controller;

        want = _want;
        farmingToken = _farmingToken;
        farmingPool = _farmingPool;
        targetProfitToken = _targetProfitToken;
        farmingPool = _farmingPool;
        farmingPoolId = _farmingPoolId;

        polydexPaths[_farmingToken][usdc] = _farmingToken2UsdcPath;
        polydexPaths[_farmingToken][targetProfitToken] = _farmingToken2TargetProfitTokenPath;

        strategist = msg.sender; // to call earn if public not allowed
        operator = msg.sender;
    }

    modifier onlyStrategist() {
        require(strategist == msg.sender || operator == msg.sender, "caller is not the strategist");
        _;
    }

    modifier onlyController() {
        require(controller == msg.sender, "caller is not the controller");
        _;
    }

    modifier onlyTimelock() {
        require(timelock == msg.sender, "caller is not timelock");
        _;
    }

    function getName() public pure virtual returns (string memory);

    function _farm() internal virtual;

    function _withdrawSome(uint256 _amount) internal virtual;

    function _exit() internal virtual;

    function inFarmBalance() public view virtual override returns (uint256);

    function _harvest() internal virtual;

    function pendingHarvest() public view virtual returns (uint256);

    function isAuthorised(address _account) public view returns (bool) {
        return (_account == operator) || (_account == controller) || (_account == strategist) || (_account == timelock);
    }

    function _checkAutoEarn() internal {
        if (!paused() && !notPublic) {
            uint256 _pendingHarvestDollarValue = pendingHarvestDollarValue();
            if (_pendingHarvestDollarValue >= autoEarnLimit || ((_pendingHarvestDollarValue > 0) && (block.timestamp - lastEarnTime >= autoEarnDelaySeconds))) {
                earn();
            }
        }
    }

    function deposit(address, uint256 _wantAmt) public override onlyController whenNotPaused {
        require(_wantAmt > 0, "deposit: not good");
        _checkAutoEarn();
        IERC20(want).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _farm();
        emit Deposit(_wantAmt);
    }

    function farm() public nonReentrant {
        _farm();
    }

    function withdraw(address, uint256 _wantAmt) public override onlyController whenNotPaused nonReentrant {
        require(_wantAmt > 0, "withdraw: not good");
        _checkAutoEarn();
        _withdrawSome(_wantAmt);
        IERC20(want).safeTransfer(address(msg.sender), _wantAmt);
        emit Withdraw(_wantAmt);
    }

    function totalBalance() external view override returns (uint256) {
        if (farmingToken == want) return inFarmBalance();
        else return IERC20(want).balanceOf(address(this)) + inFarmBalance();
    }

    function withdrawAll() external override onlyController {
        _checkAutoEarn();
        _exit();
        uint256 _wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(address(msg.sender), _wantBal);
        emit Withdraw(_wantBal);
    }

    function earn() public whenNotPaused {
        require(!notPublic || isAuthorised(msg.sender), "!authorised");

        _harvest();

        // Converts farm tokens into want tokens
        address _farmingToken = farmingToken;
        uint256 _earnedAmt = IERC20(_farmingToken).balanceOf(address(this));
        if (_earnedAmt > 0) {
            uint256 _distributeFee = _distributeFees(_earnedAmt);
            _earnedAmt -= _distributeFee;

            emit Earned(_farmingToken, _earnedAmt);

            _swapToken(_farmingToken, targetProfitToken, _earnedAmt, profitReceiver);
        }

        lastEarnTime = block.timestamp;
    }

    function _distributeFees(uint256 _earnedAmt) internal returns (uint256 _fee) {
        if (_earnedAmt > 0) {
            // Performance fee
            if (operatorFee > 0) {
                _fee = (_earnedAmt * operatorFee) / operatorFeeMax;
                address _farmingToken = farmingToken;
                address _operator = operator;
                IERC20(_farmingToken).safeTransfer(_operator, _fee);
                emit DistributeFee(_farmingToken, _fee, _operator);
            }
        }
    }

    function exchangeRate(
        address _inputToken,
        address _outputToken,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        try IPolyDexFormula(polydexFormula).getAmountsOut(_inputToken, _outputToken, _tokenAmount, polydexPaths[_inputToken][_outputToken]) returns (uint256[] memory amounts) {
            return amounts[amounts.length - 1];
        } catch {
            return 0;
        }
    }

    function pendingHarvestDollarValue() public view returns (uint256) {
        address _farmingToken = farmingToken;
        uint256 _pending = pendingHarvest();
        uint256 _earnedAmt = IERC20(_farmingToken).balanceOf(address(this));
        return (_pending == 0 && _earnedAmt == 0) ? 0 : exchangeRate(_farmingToken, usdc, _pending + _earnedAmt) * USDC_MISSING_DECIMALS_MULTIPLER;
    }

    /* ========== GOVERNANCE ========== */

    function setStrategist(address _strategist) external onlyOwner {
        require(_strategist != address(0), "invalidAddress");
        strategist = _strategist;
    }

    function setOperator(address _operator) external onlyOwner {
        require(operator != address(0), "invalidAddress");
        operator = _operator;
    }

    function setOperatorFee(uint256 _operatorFee) external onlyOwner {
        require(_operatorFee <= operatorFeeUL, "too high");
        operatorFee = _operatorFee;
    }

    function setProfitReceiver(address _profitReceiver) external onlyOwner {
        require(_profitReceiver != address(0), "invalidAddress");
        profitReceiver = _profitReceiver;
    }

    function setNotPublic(bool _notPublic) external onlyOwner {
        notPublic = _notPublic;
    }

    function setAutoEarnLimit(uint256 _autoEarnLimit) external onlyOwner {
        autoEarnLimit = _autoEarnLimit;
    }

    function setAutoEarnDelaySeconds(uint256 _autoEarnDelaySeconds) external onlyOwner {
        autoEarnDelaySeconds = _autoEarnDelaySeconds;
    }

    function setQuickRouter(address _polydexRouter) external onlyOwner {
        polydexRouter = _polydexRouter;
    }

    function setMainPaths(address[] memory _farmingToken2UsdcPath, address[] memory _farmingToken2TargetProfitTokenPath) external onlyOwner {
        address _farmingToken = farmingToken;
        polydexPaths[_farmingToken][usdc] = _farmingToken2UsdcPath;
        polydexPaths[_farmingToken][targetProfitToken] = _farmingToken2TargetProfitTokenPath;
    }

    function setPath(
        address _inputToken,
        address _outputToken,
        address[] memory _path
    ) external onlyOwner {
        polydexPaths[_inputToken][_outputToken] = _path;
    }

    function _swapToken(
        address _inputToken,
        address _outputToken,
        uint256 _amount,
        address _to
    ) internal {
        IERC20(_inputToken).safeIncreaseAllowance(address(polydexRouter), _amount);
        IPolyDexRouterV2(polydexRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(_inputToken, _outputToken, _amount, 1, polydexPaths[_inputToken][_outputToken], _to, block.timestamp + 60);
    }

    /* ========== EMERGENCY ========== */

    function pause() external onlyOwner whenNotPaused {
        super._pause();
    }

    function unpause() external onlyOwner whenPaused {
        super._unpause();
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != want, "want");
        require(_token != farmingToken, "farmingToken");
        uint256 _amount = IERC20(_token).balanceOf(_token);
        if (_amount > 0) {
            address _profitReceiver = profitReceiver;
            IERC20(_token).safeTransfer(_profitReceiver, _amount);
            emit InCaseTokensGetStuck(_token, _amount, _profitReceiver);
        }
    }

    function setController(address _controller) external {
        require(_controller != address(0), "invalidAddress");
        require(controller == msg.sender || timelock == msg.sender, "caller is not the controller nor timelock");
        controller = _controller;
    }

    function setTimelock(address _timelock) external onlyTimelock {
        timelock = _timelock;
    }

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
        require(success, "StrategyBase::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}

contract StrategyStakeMeeb is StrategyBase {
    using SafeERC20 for IERC20;

    // _controller = TokenPlayChef
    // _want = MEEB
    // _farmingToken = MEEB
    // _farmingPool = MeebFarmingBank (earns MEEB)
    // _farmingPoolId = 0 // Stake pool
    // _targetProfitToken = TOP
    // _farmingToken2UsdcPath = [pair(MEEB/USDC)]
    // _farmingToken2TargetProfitTokenPath = [pair(MEEB/USDC), pair(USDC/TOP)]
    constructor(
        address _controller,
        address _want,
        address _farmingToken,
        address _farmingPool,
        uint256 _farmingPoolId,
        address _targetProfitToken,
        address[] memory _farmingToken2UsdcPath,
        address[] memory _farmingToken2TargetProfitTokenPath
    ) StrategyBase(_controller, _want, _farmingToken, _farmingPool, _farmingPoolId, _targetProfitToken, _farmingToken2UsdcPath, _farmingToken2TargetProfitTokenPath) {}

    function getName() public pure override returns (string memory) {
        return "MeebMaster.com:StrategyStakePlx";
    }

    function _farm() internal override {
        address _want = want;
        uint256 _wantBal = IERC20(_want).balanceOf(address(this));
        IERC20(want).safeIncreaseAllowance(address(farmingPool), _wantBal);
        IFarmingPool(farmingPool).deposit(farmingPoolId, _wantBal);
    }

    function _withdrawSome(uint256 _amount) internal override {
        IFarmingPool(farmingPool).withdraw(farmingPoolId, _amount);
    }

    function _exit() internal override {
        IFarmingPool(farmingPool).withdrawAll(farmingPoolId);
    }

    function inFarmBalance() public view override returns (uint256 amount) {
        (amount, ) = IFarmingPool(farmingPool).userInfo(farmingPoolId, address(this));
    }

    function _harvest() internal override {
        return IFarmingPool(farmingPool).withdraw(farmingPoolId, 0);
    }

    function pendingHarvest() public view override returns (uint256) {
        return IFarmingPool(farmingPool).pendingReward(farmingPoolId, address(this));
    }
}