/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
 * @dev Abstract contract that implements a modified version of  Openzeppelin {Ownable.sol} contract.
 * It creates a two step process for the transfer of ownership.
 */
abstract contract Claimable is Context {

  address private _owner;

  address public pendingOwner;

  // Claimable Events

  /**
   * @dev Emits when step two in ownership transfer is completed.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev Emits when step one in ownership transfer is initiated.
   */
  event NewPendingOwner(address indexed owner);

  /**
  * @dev Initializes the contract setting the deployer as the initial owner.
  */
  constructor() {
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
    require(_msgSender() == owner(), "Ownable: caller is not the owner");
    _;
  }

  /**
  * @dev Throws if called by any account other than the pendingOwner.
  */
  modifier onlyPendingOwner() {
    require(_msgSender() == pendingOwner);
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
    emit OwnershipTransferred(owner(), address(0));
    _owner = address(0);
  }

  /**
   * @dev Step one of ownership transfer.
   * Initiates transfer of ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   *
   * NOTE:`newOwner` requires to claim ownership in order to be able to call
   * {onlyOwner} modified functions.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(
      newOwner != address(0),
      'Cannot pass zero address!'
    );
    require(pendingOwner == address(0), "There is a pending owner!");
    pendingOwner = newOwner;
    emit NewPendingOwner(newOwner);
  }

  /**
   * @dev Cancels the transfer of ownership of the contract.
   * Can only be called by the current owner.
   */
  function cancelTransferOwnership() public onlyOwner {
    require(pendingOwner != address(0));
    delete pendingOwner;
    emit NewPendingOwner(address(0));
  }

  /**
   * @dev Step two of ownership transfer.
   * 'pendingOwner' claims ownership of the contract.
   * Can only be called by the pending owner.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner(), pendingOwner);
    _owner = pendingOwner;
    delete pendingOwner;
  }
}


interface IVault {

  // Vault Events

  /**
  * @dev Log a deposit transaction done by a user
  */
  event Deposit(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a withdraw transaction done by a user
  */
  event Withdraw(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a borrow transaction done by a user
  */
  event Borrow(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a payback transaction done by a user
  */
  event Payback(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a switch from provider to new provider in vault
  */
  event Switch(
    address fromProviderAddrs,
    address toProviderAddr,
    uint256 debtamount,
    uint256 collattamount
  );
  /**
  * @dev Log a change in active provider
  */
  event SetActiveProvider(address newActiveProviderAddress);
  /**
  * @dev Log a change in the array of provider addresses
  */
  event ProvidersChanged(address[] newProviderArray);
  /**
  * @dev Log a change in F1155 address
  */
  event F1155Changed(address newF1155Address);
  /**
  * @dev Log a change in fuji admin address
  */
  event FujiAdminChanged(address newFujiAdmin);
  /**
  * @dev Log a change in the factor values
  */
  event FactorChanged(
    FactorType factorType,
    uint64 newFactorA,
    uint64 newFactorB
  );
  /**
  * @dev Log a change in the oracle address
  */
  event OracleChanged(address newOracle);

  enum FactorType {
    Safety,
    Collateralization,
    ProtocolFee,
    BonusLiquidation
  }

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Core Vault Functions

  function deposit(uint256 _collateralAmount) external payable;

  function withdraw(int256 _withdrawAmount) external;

  function withdrawLiq(int256 _withdrawAmount) external;

  function borrow(uint256 _borrowAmount) external;

  function payback(int256 _repayAmount) external payable;

  function paybackLiq(address[] memory _users, uint256 _repayAmount) external payable;

  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanDebt,
    uint256 _fee
  ) external payable;

  //Getter Functions

  function activeProvider() external view returns (address);

  function borrowBalance(address _provider) external view returns (uint256);

  function depositBalance(address _provider) external view returns (uint256);

  function userDebtBalance(address _user) external view returns (uint256);

  function userProtocolFee(address _user) external view returns (uint256);

  function userDepositBalance(address _user) external view returns (uint256);

  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    external
    view
    returns (uint256);

  function getLiquidationBonusFor(uint256 _amount) external view returns (uint256);

  function getProviders() external view returns (address[] memory);

  function fujiERC1155() external view returns (address);

  //Setter Functions

  function setActiveProvider(address _provider) external;

  function updateF1155Balances() external;

  function protocolFee() external view returns (uint64, uint64);
}


interface IVaultControl {
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns (VaultAssets memory);
}


interface IFujiAdmin {

  // FujiAdmin Events

  /**
  * @dev Log change of flasher address
  */
  event FlasherChanged(address newFlasher);
  /**
  * @dev Log change of fliquidator address
  */
  event FliquidatorChanged(address newFliquidator);
  /**
  * @dev Log change of treasury address
  */
  event TreasuryChanged(address newTreasury);
  /**
  * @dev Log change of controller address
  */
  event ControllerChanged(address newController);
  /**
  * @dev Log change of vault harvester address
  */
  event VaultHarvesterChanged(address newHarvester);
  /**
  * @dev Log change of swapper address
  */
  event SwapperChanged(address newSwapper);
  /**
  * @dev Log change of vault address permission
  */
  event VaultPermitChanged(address vaultAddress, bool newPermit);


  function validVault(address _vaultAddr) external view returns (bool);

  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getVaultHarvester() external view returns (address);

  function getSwapper() external view returns (address);
}


interface IFujiOracle {

  // FujiOracle Events

  /**
  * @dev Log a change in price feed address for asset address
  */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  ) external view returns (uint256);
}


interface IFujiERC1155 {
  //Asset Types
  enum AssetType {
    //uint8 = 0
    collateralToken,
    //uint8 = 1
    debtToken
  }

  //General Getter Functions

  function getAssetID(AssetType _type, address _assetAddr) external view returns (uint256);

  function qtyOfManagedAssets() external view returns (uint64);

  function balanceOf(address _account, uint256 _id) external view returns (uint256);

  // function splitBalanceOf(address account,uint256 _AssetID) external view  returns (uint256,uint256);

  // function balanceOfBatchType(address account, AssetType _Type) external view returns (uint256);

  //Permit Controlled  Functions
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function updateState(uint256 _assetID, uint256 _newBalance) external;

  function addInitializeAsset(AssetType _type, address _addr) external returns (uint64);
}


interface IERC20Extended {
  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}


library Account {
  enum Status {
    Normal,
    Liquid,
    Vapor
  }
  struct Info {
    address owner; // The address that owns the account
    uint256 number; // A nonce that allows a single address to control many accounts
  }
}

library Actions {
  enum ActionType {
    Deposit, // supply tokens
    Withdraw, // borrow tokens
    Transfer, // transfer balance between accounts
    Buy, // buy an amount of some token (publicly)
    Sell, // sell an amount of some token (publicly)
    Trade, // trade tokens against another account
    Liquidate, // liquidate an undercollateralized or expiring account
    Vaporize, // use excess tokens to zero-out a completely negative account
    Call // send arbitrary data to an address
  }

  struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    Types.AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
  }
}

library Types {
  enum AssetDenomination {
    Wei, // the amount is denominated in wei
    Par // the amount is denominated in par
  }

  enum AssetReference {
    Delta, // the amount is given as a delta from the current value
    Target // the amount is given as an exact number to end up at
  }

  struct AssetAmount {
    bool sign; // true if positive
    AssetDenomination denomination;
    AssetReference ref;
    uint256 value;
  }
}

library FlashLoan {
  /**
   * @dev Used to determine which vault's function to call post-flashloan:
   * - Switch for executeSwitch(...)
   * - Close for executeFlashClose(...)
   * - Liquidate for executeFlashLiquidation(...)
   * - BatchLiquidate for executeFlashBatchLiquidation(...)
   */
  enum CallType {
    Switch,
    Close,
    BatchLiquidate
  }

  /**
   * @dev Struct of params to be passed between functions executing flashloan logic
   * @param asset: Address of asset to be borrowed with flashloan
   * @param amount: Amount of asset to be borrowed with flashloan
   * @param vault: Vault's address on which the flashloan logic to be executed
   * @param newProvider: New provider's address. Used when callType is Switch
   * @param userAddrs: User's address array Used when callType is BatchLiquidate
   * @param userBals:  Array of user's balances, Used when callType is BatchLiquidate
   * @param userliquidator: The user's address who is  performing liquidation. Used when callType is Liquidate
   * @param fliquidator: Fujis Liquidator's address.
   */
  struct Info {
    CallType callType;
    address asset;
    uint256 amount;
    address vault;
    address newProvider;
    address[] userAddrs;
    uint256[] userBalances;
    address userliquidator;
    address fliquidator;
  }
}


interface IFlasher {

  /**
  * @dev Logs a change in FujiAdmin address.
  */
  event FujiAdminChanged(address newFujiAdmin);
  
  function initiateFlashloan(FlashLoan.Info calldata info, uint8 amount) external;
}


library LibUniversalERC20AVAX {
  using SafeERC20 for IERC20;

  IERC20 private constant _AVAX_ADDRESS = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

  function isAVAX(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _AVAX_ADDRESS);
  }

  function univBalanceOf(IERC20 token, address account) internal view returns (uint256) {
    if (isAVAX(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function univTransfer(
    IERC20 token,
    address payable to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (isAVAX(token)) {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send AVAX");
      } else {
        token.safeTransfer(to, amount);
      }
    }
  }

  function univApprove(
    IERC20 token,
    address to,
    uint256 amount
  ) internal {
    require(!isAVAX(token), "Approve called on AVAX");

    if (amount == 0) {
      token.safeApprove(to, 0);
    } else {
      uint256 allowance = token.allowance(address(this), to);
      if (allowance < amount) {
        if (allowance > 0) {
          token.safeApprove(to, 0);
        }
        token.safeApprove(to, amount);
      }
    }
  }
}


/**
 * @title Errors library
 * @author Fuji
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = Validation Logic 100 series
 *  - MATH = Math libraries 200 series
 *  - RF = Refinancing 300 series
 *  - VLT = vault 400 series
 *  - SP = Special 900 series
 */
library Errors {
  //Errors
  string public constant VL_INDEX_OVERFLOW = "100"; // index overflows uint128
  string public constant VL_INVALID_MINT_AMOUNT = "101"; //invalid amount to mint
  string public constant VL_INVALID_BURN_AMOUNT = "102"; //invalid amount to burn
  string public constant VL_AMOUNT_ERROR = "103"; //Input value >0, and for ETH msg.value and amount shall match
  string public constant VL_INVALID_WITHDRAW_AMOUNT = "104"; //Withdraw amount exceeds provided collateral, or falls undercollaterized
  string public constant VL_INVALID_BORROW_AMOUNT = "105"; //Borrow amount does not meet collaterization
  string public constant VL_NO_DEBT_TO_PAYBACK = "106"; //Msg sender has no debt amount to be payback
  string public constant VL_MISSING_ERC20_ALLOWANCE = "107"; //Msg sender has not approved ERC20 full amount to transfer
  string public constant VL_USER_NOT_LIQUIDATABLE = "108"; //User debt position is not liquidatable
  string public constant VL_DEBT_LESS_THAN_AMOUNT = "109"; //User debt is less than amount to partial close
  string public constant VL_PROVIDER_ALREADY_ADDED = "110"; // Provider is already added in Provider Array
  string public constant VL_NOT_AUTHORIZED = "111"; //Not authorized
  string public constant VL_INVALID_COLLATERAL = "112"; //There is no Collateral, or Collateral is not in active in vault
  string public constant VL_NO_ERC20_BALANCE = "113"; //User does not have ERC20 balance
  string public constant VL_INPUT_ERROR = "114"; //Check inputs. For ERC1155 batch functions, array sizes should match.
  string public constant VL_ASSET_EXISTS = "115"; //Asset intended to be added already exists in FujiERC1155
  string public constant VL_ZERO_ADDR_1155 = "116"; //ERC1155: balance/transfer for zero address
  string public constant VL_NOT_A_CONTRACT = "117"; //Address is not a contract.
  string public constant VL_INVALID_ASSETID_1155 = "118"; //ERC1155 Asset ID is invalid.
  string public constant VL_NO_ERC1155_BALANCE = "119"; //ERC1155: insufficient balance for transfer.
  string public constant VL_MISSING_ERC1155_APPROVAL = "120"; //ERC1155: transfer caller is not owner nor approved.
  string public constant VL_RECEIVER_REJECT_1155 = "121"; //ERC1155Receiver rejected tokens
  string public constant VL_RECEIVER_CONTRACT_NON_1155 = "122"; //ERC1155: transfer to non ERC1155Receiver implementer
  string public constant VL_OPTIMIZER_FEE_SMALL = "123"; //Fuji OptimizerFee has to be > 1 RAY (1e27)
  string public constant VL_UNDERCOLLATERIZED_ERROR = "124"; // Flashloan-Flashclose cannot be used when User's collateral is worth less than intended debt position to close.
  string public constant VL_MINIMUM_PAYBACK_ERROR = "125"; // Minimum Amount payback should be at least Fuji Optimizerfee accrued interest.
  string public constant VL_HARVESTING_FAILED = "126"; // Harvesting Function failed, check provided _farmProtocolNum or no claimable balance.
  string public constant VL_FLASHLOAN_FAILED = "127"; // Flashloan failed
  string public constant VL_ERC1155_NOT_TRANSFERABLE = "128"; // ERC1155: Not Transferable
  string public constant VL_SWAP_SLIPPAGE_LIMIT_EXCEED = "129"; // ERC1155: Not Transferable
  string public constant VL_ZERO_ADDR = "130"; // Zero Address
  string public constant VL_INVALID_FLASH_NUMBER = "131"; // invalid flashloan number
  string public constant VL_INVALID_HARVEST_PROTOCOL_NUMBER = "132"; // invalid flashloan number
  string public constant VL_INVALID_HARVEST_TYPE = "133"; // invalid flashloan number
  string public constant VL_INVALID_FACTOR = "134"; // invalid factor
  string public constant VL_INVALID_NEW_PROVIDER ="135"; // invalid newProvider in executeSwitch

  string public constant MATH_DIVISION_BY_ZERO = "201";
  string public constant MATH_ADDITION_OVERFLOW = "202";
  string public constant MATH_MULTIPLICATION_OVERFLOW = "203";

  string public constant RF_INVALID_RATIO_VALUES = "301"; // Ratio Value provided is invalid, _ratioA/_ratioB <= 1, and > 0, or activeProvider borrowBalance = 0
  string public constant RF_INVALID_NEW_ACTIVEPROVIDER = "302"; //Input '_newProvider' and vault's 'activeProvider' must be different

  string public constant VLT_CALLER_MUST_BE_VAULT = "401"; // The caller of this function must be a vault

  string public constant ORACLE_INVALID_LENGTH = "501"; // The assets length and price feeds length doesn't match
  string public constant ORACLE_NONE_PRICE_FEED = "502"; // The price feed is not found
}


/**
 * @dev Contract to execute liquidations and flash close.
 */
contract FliquidatorAVAX is Claimable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using LibUniversalERC20AVAX for IERC20;

  address public constant AVAX = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

  // slippage limit to 2%
  uint256 public constant SLIPPAGE_LIMIT_NUMERATOR = 100;
  uint256 public constant SLIPPAGE_LIMIT_DENOMINATOR = 100;

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Flash Close Fee Factor
  Factor public flashCloseF;

  IFujiAdmin private _fujiAdmin;
  IFujiOracle private _oracle;
  IPangolinRouter public swapper;

  /**
  * @dev Log when a user is liquidated
  */
  event Liquidate(
    address indexed userAddr,
    address indexed vault,
    uint256 amount,
    address liquidator
  );
  /**
  * @dev Log when a user FlashClose its position
  */
  event FlashClose(address indexed userAddr, address indexed vault, uint256 amount);
  /**
  * @dev Log a change in fuji admin address
  */
  event FujiAdminChanged(address newFujiAdmin);
  /**
  * @dev Log a change in the factor values
  */
  event FactorChanged(
    bytes32 typehash,
    uint64 newFactorA,
    uint64 newFactorB
  );

  /**
  * @dev Log a change in the oracle address
  */
  event OracleChanged(address newOracle);
  /**
  * @dev Log change of swapper address
  */
  event SwapperChanged(address newSwapper);

  /**
  * @dev Throws if caller is not 'owner'.
  */
  modifier isAuthorized() {
    require(msg.sender == owner(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  /**
  * @dev Throws if caller is not '_flasher' address in {FujiAdmin}.
  */
  modifier onlyFlash() {
    require(msg.sender == _fujiAdmin.getFlasher(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  /**
  * @dev Throws if address passed is not a recognized vault.
  */
  modifier isValidVault(address _vaultAddr) {
    require(_fujiAdmin.validVault(_vaultAddr), "Invalid vault!");
    _;
  }

  /**
  * @dev Sets the flash close fee factor.
  */
  constructor() {
    // 0.01
    flashCloseF.a = 1;
    flashCloseF.b = 100;
  }

  receive() external payable {}

  // FLiquidator Core Functions

  /**
   * @dev Liquidates undercollaterized debt positions and get bonus (bonusL in Vault)
   * @param _addrs: Address array of users whose position is liquidatable
   * @param _vault: Address of the vault in where liquidation will occur
   * Emits a {Liquidate} event for each liquidated user.
   */
  function batchLiquidate(address[] calldata _addrs, address _vault)
    external
    payable
    nonReentrant
    isValidVault(_vault)
  {
    IVaultControl.VaultAssets memory vAssets = IVaultControl(_vault).vAssets();
    address f1155 = IVault(_vault).fujiERC1155();

    IVault(_vault).updateF1155Balances();

    (address[] memory addrs, uint256[] memory borrowBals, uint256 debtTotal) = _constructParams(
      _addrs,
      vAssets,
      _vault,
      f1155
    );

    // Check there is at least one user liquidatable
    require(debtTotal > 0, Errors.VL_USER_NOT_LIQUIDATABLE);

    if (vAssets.borrowAsset == AVAX) {
      require(msg.value >= debtTotal, Errors.VL_AMOUNT_ERROR);
    } else {
      // Check Liquidator Allowance
      require(
        IERC20(vAssets.borrowAsset).allowance(msg.sender, address(this)) >= debtTotal,
        Errors.VL_MISSING_ERC20_ALLOWANCE
      );

      // Transfer borrowAsset funds from the Liquidator to Vault
      IERC20(vAssets.borrowAsset).safeTransferFrom(msg.sender, _vault, debtTotal);
    }

    // Repay BaseProtocol debt
    uint256 _value = vAssets.borrowAsset == AVAX ? debtTotal : 0;
    IVault(_vault).paybackLiq{ value: _value }(addrs, debtTotal);

    // Compute liquidator's bonus: bonusL
    uint256 bonus = IVault(_vault).getLiquidationBonusFor(debtTotal);
    // Compute how much collateral needs to be swapt
    uint256 collateralInPlay = _getCollateralInPlay(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      debtTotal + bonus
    );

    // Burn f1155
    _burnMulti(addrs, borrowBals, vAssets, _vault, f1155);

    // Withdraw collateral
    IVault(_vault).withdrawLiq(int256(collateralInPlay));

    // Swap Collateral
    _swap(vAssets.collateralAsset, vAssets.borrowAsset, debtTotal + bonus, collateralInPlay, true);

    // Transfer to Liquidator the debtBalance + bonus
    IERC20(vAssets.borrowAsset).univTransfer(payable(msg.sender), debtTotal + bonus);

    // Emit liquidation event for each liquidated user
    for (uint256 i = 0; i < addrs.length; i += 1) {
      if (addrs[i] != address(0)) {
        emit Liquidate(addrs[i], _vault, borrowBals[i], msg.sender);
      }
    }
  }

  /**
   * @dev Initiates a flashloan to liquidate array of undercollaterized debt positions,
   * gets bonus (bonusFlashL in Vault)
   * @param _addrs: Array of Address whose position is liquidatable
   * @param _vault: The vault address where the debt position exist.
   * @param _flashnum: integer identifier of flashloan provider
   */
  function flashBatchLiquidate(
    address[] calldata _addrs,
    address _vault,
    uint8 _flashnum
  ) external isValidVault(_vault) nonReentrant {
    IVaultControl.VaultAssets memory vAssets = IVaultControl(_vault).vAssets();
    address f1155 = IVault(_vault).fujiERC1155();

    IVault(_vault).updateF1155Balances();

    (address[] memory addrs, uint256[] memory borrowBals, uint256 debtTotal) = _constructParams(
      _addrs,
      vAssets,
      _vault,
      f1155
    );

    // Check there is at least one user liquidatable
    require(debtTotal > 0, Errors.VL_USER_NOT_LIQUIDATABLE);

    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.BatchLiquidate,
      asset: vAssets.borrowAsset,
      amount: debtTotal,
      vault: _vault,
      newProvider: address(0),
      userAddrs: addrs,
      userBalances: borrowBals,
      userliquidator: msg.sender,
      fliquidator: address(this)
    });

    IFlasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashnum);
  }

  /**
   * @dev Liquidate a debt position by using a flashloan
   * @param _addrs: array **See addrs construction in 'function flashBatchLiquidate'
   * @param _borrowBals: array **See construction in 'function flashBatchLiquidate'
   * @param _liquidator: liquidator address
   * @param _vault: Vault address
   * @param _amount: amount of debt to be repaid
   * @param _flashloanFee: amount extra charged by flashloan provider
   * Emits a {Liquidate} event for each liquidated user.
   */
  function executeFlashBatchLiquidation(
    address[] calldata _addrs,
    uint256[] calldata _borrowBals,
    address _liquidator,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external payable onlyFlash {
    address f1155 = IVault(_vault).fujiERC1155();
    IVaultControl.VaultAssets memory vAssets = IVaultControl(_vault).vAssets();

    // Repay BaseProtocol debt to release collateral
    uint256 _value = vAssets.borrowAsset == AVAX ? _amount : 0;
    IVault(_vault).paybackLiq{ value: _value }(_addrs, _amount);

    // Compute liquidator's bonus
    uint256 bonus = IVault(_vault).getLiquidationBonusFor(_amount);

    // Compute how much collateral needs to be swapt for all liquidated users
    uint256 collateralInPlay = _getCollateralInPlay(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      _amount + _flashloanFee + bonus
    );

    // Burn f1155
    _burnMulti(_addrs, _borrowBals, vAssets, _vault, f1155);

    // Withdraw collateral
    IVault(_vault).withdrawLiq(int256(collateralInPlay));

    _swap(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      _amount + _flashloanFee + bonus,
      collateralInPlay,
      true
    );

    // Send flasher the underlying to repay Flashloan
    IERC20(vAssets.borrowAsset).univTransfer(
      payable(_fujiAdmin.getFlasher()),
      _amount + _flashloanFee
    );

    // Liquidator's bonus gets reduced by 20% as a protocol fee
    uint256 fujiFee = bonus / 5;

    // Transfer liquidator's bonus, minus fujiFee
    IERC20(vAssets.borrowAsset).univTransfer(payable(_liquidator), bonus - fujiFee);

    // Transfer fee to Fuji Treasury
    IERC20(vAssets.borrowAsset).univTransfer(_fujiAdmin.getTreasury(), fujiFee);

    // Emit liquidation event for each liquidated user
    for (uint256 i = 0; i < _addrs.length; i += 1) {
      if (_addrs[i] != address(0)) {
        emit Liquidate(_addrs[i], _vault, _borrowBals[i], _liquidator);
      }
    }
  }

  /**
   * @dev Initiates a flashloan used to repay partially or fully the debt position of msg.sender
   * @param _amount: Pass -1 to fully close debt position, otherwise Amount to be repaid with a flashloan
   * @param _vault: The vault address where the debt position exist.
   * @param _flashnum: integer identifier of flashloan provider
   */
  function flashClose(
    int256 _amount,
    address _vault,
    uint8 _flashnum
  ) external nonReentrant isValidVault(_vault) {
    // Update Balances at FujiERC1155
    IVault(_vault).updateF1155Balances();

    // Create Instance of FujiERC1155
    IFujiERC1155 f1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in f1155
    IVaultControl.VaultAssets memory vAssets = IVaultControl(_vault).vAssets();

    // Get user  Balances
    uint256 userCollateral = f1155.balanceOf(msg.sender, vAssets.collateralID);
    uint256 debtTotal = IVault(_vault).userDebtBalance(msg.sender);

    require(debtTotal > 0, Errors.VL_NO_DEBT_TO_PAYBACK);

    uint256 amount = _amount < 0 ? debtTotal : uint256(_amount);

    uint256 neededCollateral = IVault(_vault).getNeededCollateralFor(amount, false);
    require(userCollateral >= neededCollateral, Errors.VL_UNDERCOLLATERIZED_ERROR);

    address[] memory userAddressArray = new address[](1);
    userAddressArray[0] = msg.sender;

    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Close,
      asset: vAssets.borrowAsset,
      amount: amount,
      vault: _vault,
      newProvider: address(0),
      userAddrs: userAddressArray,
      userBalances: new uint256[](0),
      userliquidator: address(0),
      fliquidator: address(this)
    });

    IFlasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashnum);
  }

  /**
   * @dev Close user's debt position by using a flashloan
   * @param _userAddr: user addr to be liquidated
   * @param _vault: Vault address
   * @param _amount: amount received by Flashloan
   * @param _flashloanFee: amount extra charged by flashloan provider
   * Emits a {FlashClose} event.
   * Requirements:
   * - Should only be called by '_flasher' contract address stored in {FujiAdmin}
   */
  function executeFlashClose(
    address payable _userAddr,
    address _vault,
    uint256 _amount,
    uint256 _flashloanFee
  ) external payable onlyFlash {
    // Create Instance of FujiERC1155
    IFujiERC1155 f1155 = IFujiERC1155(IVault(_vault).fujiERC1155());

    // Struct Instance to get Vault Asset IDs in f1155
    IVaultControl.VaultAssets memory vAssets = IVaultControl(_vault).vAssets();
    uint256 flashCloseFee = (_amount * flashCloseF.a) / flashCloseF.b;

    uint256 protocolFee = IVault(_vault).userProtocolFee(_userAddr);
    uint256 totalDebt = f1155.balanceOf(_userAddr, vAssets.borrowID) + protocolFee;

    uint256 collateralInPlay = _getCollateralInPlay(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      _amount + _flashloanFee + flashCloseFee
    );

    // Repay BaseProtocol debt
    uint256 _value = vAssets.borrowAsset == AVAX ? _amount : 0;
    address[] memory _addrs = new address[](1);
    _addrs[0] = _userAddr;
    IVault(_vault).paybackLiq{ value: _value }(_addrs, _amount);

    // Full close
    if (_amount == totalDebt) {
      uint256 userCollateral = f1155.balanceOf(_userAddr, vAssets.collateralID);

      f1155.burn(_userAddr, vAssets.collateralID, userCollateral);

      // Withdraw full collateral
      IVault(_vault).withdrawLiq(int256(userCollateral));

      // Send remaining collateral to user
      IERC20(vAssets.collateralAsset).univTransfer(_userAddr, userCollateral - collateralInPlay);
    } else {
      f1155.burn(_userAddr, vAssets.collateralID, collateralInPlay);

      // Withdraw collateral in play only
      IVault(_vault).withdrawLiq(int256(collateralInPlay));
    }

    // Swap collateral for underlying to repay flashloan
    _swap(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      _amount + _flashloanFee + flashCloseFee,
      collateralInPlay,
      false
    );

    // Send flashClose fee to Fuji Treasury
    IERC20(vAssets.borrowAsset).univTransfer(_fujiAdmin.getTreasury(), flashCloseFee);

    // Send flasher the underlying to repay flashloan
    IERC20(vAssets.borrowAsset).univTransfer(
      payable(_fujiAdmin.getFlasher()),
      _amount + _flashloanFee
    );

    // Burn Debt f1155 tokens
    f1155.burn(_userAddr, vAssets.borrowID, _amount - protocolFee);

    emit FlashClose(_userAddr, _vault, _amount);
  }

  /**
   * @dev Swap an amount of underlying
   * @param _collateralAsset: Address of vault collateralAsset
   * @param _borrowAsset: Address of vault borrowAsset
   * @param _amountToReceive: amount of underlying to receive
   * @param _collateralAmount: collateral Amount sent for swap
   */
  function _swap(
    address _collateralAsset,
    address _borrowAsset,
    uint256 _amountToReceive,
    uint256 _collateralAmount,
    bool _checkSlippage
  ) internal returns (uint256) {
    if (_checkSlippage) {
      uint8 _collateralAssetDecimals;
      uint8 _borrowAssetDecimals;
      if (_collateralAsset == AVAX) {
        _collateralAssetDecimals = 18;
      } else {
        _collateralAssetDecimals = IERC20Extended(_collateralAsset).decimals();
      }
      if (_borrowAsset == AVAX) {
        _borrowAssetDecimals = 18;
      } else {
        _borrowAssetDecimals = IERC20Extended(_borrowAsset).decimals();
      }

      uint256 priceFromSwapper = (_collateralAmount * (10**uint256(_borrowAssetDecimals))) /
        _amountToReceive;
      uint256 priceFromOracle = _oracle.getPriceOf(
        _collateralAsset,
        _borrowAsset,
        _collateralAssetDecimals
      );
      uint256 priceDelta = priceFromSwapper > priceFromOracle
        ? priceFromSwapper - priceFromOracle
        : priceFromOracle - priceFromSwapper;

      require(
        (priceDelta * SLIPPAGE_LIMIT_DENOMINATOR) / priceFromOracle < SLIPPAGE_LIMIT_NUMERATOR,
        Errors.VL_SWAP_SLIPPAGE_LIMIT_EXCEED
      );
    }

    // Swap Collateral Asset to Borrow Asset
    address weth = swapper.WAVAX();
    address[] memory path;
    uint256[] memory swapperAmounts;

    if (_collateralAsset == AVAX) {
      path = new address[](2);
      path[0] = weth;
      path[1] = _borrowAsset;

      swapperAmounts = swapper.swapAVAXForExactTokens{ value: _collateralAmount }(
        _amountToReceive,
        path,
        address(this),
        // solhint-disable-next-line
        block.timestamp
      );
    } else if (_borrowAsset == AVAX) {
      path = new address[](2);
      path[0] = _collateralAsset;
      path[1] = weth;

      IERC20(_collateralAsset).univApprove(address(swapper), _collateralAmount);
      swapperAmounts = swapper.swapTokensForExactAVAX(
        _amountToReceive,
        _collateralAmount,
        path,
        address(this),
        // solhint-disable-next-line
        block.timestamp
      );
    } else {
      if (_collateralAsset == weth || _borrowAsset == weth) {
        path = new address[](2);
        path[0] = _collateralAsset;
        path[1] = _borrowAsset;
      } else {
        path = new address[](3);
        path[0] = _collateralAsset;
        path[1] = weth;
        path[2] = _borrowAsset;
      }

      IERC20(_collateralAsset).univApprove(address(swapper), _collateralAmount);
      swapperAmounts = swapper.swapTokensForExactTokens(
        _amountToReceive,
        _collateralAmount,
        path,
        address(this),
        // solhint-disable-next-line
        block.timestamp
      );
    }

    return _collateralAmount - swapperAmounts[0];
  }

  /**
   * @dev Get exact amount of collateral to be swapt
   * @param _collateralAsset: Address of vault collateralAsset
   * @param _borrowAsset: Address of vault borrowAsset
   * @param _amountToReceive: amount of underlying to receive
   */
  function _getCollateralInPlay(
    address _collateralAsset,
    address _borrowAsset,
    uint256 _amountToReceive
  ) internal view returns (uint256) {
    address weth = swapper.WAVAX();
    address[] memory path;
    if (_collateralAsset == AVAX || _collateralAsset == weth) {
      path = new address[](2);
      path[0] = weth;
      path[1] = _borrowAsset;
    } else if (_borrowAsset == AVAX || _borrowAsset == weth) {
      path = new address[](2);
      path[0] = _collateralAsset;
      path[1] = weth;
    } else {
      path = new address[](3);
      path[0] = _collateralAsset;
      path[1] = weth;
      path[2] = _borrowAsset;
    }

    uint256[] memory amounts = swapper.getAmountsIn(_amountToReceive, path);

    return amounts[0];
  }

  function _constructParams(
    address[] memory _userAddrs,
    IVaultControl.VaultAssets memory _vAssets,
    address _vault,
    address _f1155
  )
    internal
    view
    returns (
      address[] memory addrs,
      uint256[] memory borrowBals,
      uint256 debtTotal
    )
  {
    addrs = new address[](_userAddrs.length);

    uint256[] memory borrowIds = new uint256[](_userAddrs.length);
    uint256[] memory collateralIds = new uint256[](_userAddrs.length);

    // Build the required Arrays to query balanceOfBatch from f1155
    for (uint256 i = 0; i < _userAddrs.length; i += 1) {
      collateralIds[i] = _vAssets.collateralID;
      borrowIds[i] = _vAssets.borrowID;
    }

    // Get user collateral and debt balances
    borrowBals = IERC1155(_f1155).balanceOfBatch(_userAddrs, borrowIds);
    uint256[] memory collateralBals = IERC1155(_f1155).balanceOfBatch(_userAddrs, collateralIds);

    uint256 neededCollateral;

    for (uint256 i = 0; i < _userAddrs.length; i += 1) {
      // Compute amount of min collateral required including factors
      neededCollateral = IVault(_vault).getNeededCollateralFor(borrowBals[i], true);

      // Check if User is liquidatable
      if (collateralBals[i] < neededCollateral) {
        // If true, add User debt balance to the total balance to be liquidated
        addrs[i] = _userAddrs[i];
        debtTotal += borrowBals[i] + IVault(_vault).userProtocolFee(addrs[i]);
      } else {
        // set user that is not liquidatable to Zero Address
        addrs[i] = address(0);
      }
    }
  }

  /**
   * @dev Perform multi-batch burn of collateral
   * checking bonus paid to liquidator by each
   */
  function _burnMulti(
    address[] memory _addrs,
    uint256[] memory _borrowBals,
    IVaultControl.VaultAssets memory _vAssets,
    address _vault,
    address _f1155
  ) internal {
    uint256 bonusPerUser;
    uint256 collateralInPlayPerUser;

    for (uint256 i = 0; i < _addrs.length; i += 1) {
      if (_addrs[i] != address(0)) {
        bonusPerUser = IVault(_vault).getLiquidationBonusFor(_borrowBals[i]);

        collateralInPlayPerUser = _getCollateralInPlay(
          _vAssets.collateralAsset,
          _vAssets.borrowAsset,
          _borrowBals[i] + bonusPerUser
        );

        IFujiERC1155(_f1155).burn(_addrs[i], _vAssets.borrowID, _borrowBals[i]);
        IFujiERC1155(_f1155).burn(_addrs[i], _vAssets.collateralID, collateralInPlayPerUser);
      }
    }
  }

  // Administrative functions

  /**
   * @dev Set Factors "a" and "b" for a Struct Factor flashcloseF
   * @param _newFactorA: Nominator
   * @param _newFactorB: Denominator
   * Emits a {FactorChanged} event.
   */
  function setFlashCloseFee(uint64 _newFactorA, uint64 _newFactorB) external isAuthorized {
    flashCloseF.a = _newFactorA;
    flashCloseF.b = _newFactorB;
    emit FactorChanged(
      keccak256(abi.encode("flashCloseF")),
      _newFactorA,
      _newFactorB
    );
  }

  /**
   * @dev Sets the fujiAdmin Address
   * @param _newFujiAdmin: FujiAdmin Contract Address
   * Emits a {FujiAdminChanged} event.
   */
  function setFujiAdmin(address _newFujiAdmin) external isAuthorized {
    require(_newFujiAdmin != address(0), Errors.VL_ZERO_ADDR);
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
    emit FujiAdminChanged(_newFujiAdmin);
  }

  /**
   * @dev Changes the Swapper contract address
   * @param _newSwapper: address of new swapper contract
   * Emits {SwapperChanged} event.
   */
  function setSwapper(address _newSwapper) external isAuthorized {
    require(_newSwapper != address(0), Errors.VL_ZERO_ADDR);
    swapper = IPangolinRouter(_newSwapper);
    emit SwapperChanged(_newSwapper);
  }

  /**
   * @dev Changes the Oracle contract address
   * @param _newFujiOracle: address of new oracle contract
   * Emits {OracleChanged} event.
   */
  function setFujiOracle(address _newFujiOracle) external isAuthorized {
    require(_newFujiOracle != address(0), Errors.VL_ZERO_ADDR);
    _oracle = IFujiOracle(_newFujiOracle);
    emit OracleChanged(_newFujiOracle);
  }
}