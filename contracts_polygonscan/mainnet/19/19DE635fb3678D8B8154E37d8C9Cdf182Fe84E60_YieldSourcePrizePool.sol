// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICompLike is IERC20 {
    function getCurrentVotes(address account) external view returns (uint96);

    function delegate(address delegate) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title IControlledToken
  * @author PoolTogether Inc Team
  * @notice ERC20 Tokens with a controller for minting & burning.
*/
interface IControlledToken is IERC20 {

    /** 
        @notice Interface to the contract responsible for controlling mint/burn
    */
    function controller() external view returns (address);

    /** 
      * @notice Allows the controller to mint tokens for a user account
      * @dev May be overridden to provide more granular control over minting
      * @param user Address of the receiver of the minted tokens
      * @param amount Amount of tokens to mint
    */
    function controllerMint(address user, uint256 amount) external;

    /** 
      * @notice Allows the controller to burn tokens from a user account
      * @dev May be overridden to provide more granular control over burning
      * @param user Address of the holder account to burn tokens from
      * @param amount Amount of tokens to burn
    */
    function controllerBurn(address user, uint256 amount) external;

    /** 
      * @notice Allows an operator via the controller to burn tokens on behalf of a user account
      * @dev May be overridden to provide more granular control over operator-burning
      * @param operator Address of the operator performing the burn action via the controller contract
      * @param user Address of the holder account to burn tokens from
      * @param amount Amount of tokens to burn
    */
    function controllerBurnFrom(
        address operator,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../external/compound/ICompLike.sol";
import "../interfaces/ITicket.sol";

interface IPrizePool {
    /// @dev Event emitted when controlled token is added
    event ControlledTokenAdded(ITicket indexed token);

    event AwardCaptured(uint256 amount);

    /// @dev Event emitted when assets are deposited
    event Deposited(
        address indexed operator,
        address indexed to,
        ITicket indexed token,
        uint256 amount
    );

    /// @dev Event emitted when interest is awarded to a winner
    event Awarded(address indexed winner, ITicket indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are awarded to a winner
    event AwardedExternalERC20(address indexed winner, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are transferred out
    event TransferredExternalERC20(address indexed to, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC721s are awarded to a winner
    event AwardedExternalERC721(address indexed winner, address indexed token, uint256[] tokenIds);

    /// @dev Event emitted when assets are withdrawn
    event Withdrawal(
        address indexed operator,
        address indexed from,
        ITicket indexed token,
        uint256 amount,
        uint256 redeemed
    );

    /// @dev Event emitted when the Balance Cap is set
    event BalanceCapSet(uint256 balanceCap);

    /// @dev Event emitted when the Liquidity Cap is set
    event LiquidityCapSet(uint256 liquidityCap);

    /// @dev Event emitted when the Prize Strategy is set
    event PrizeStrategySet(address indexed prizeStrategy);

    /// @dev Event emitted when the Ticket is set
    event TicketSet(ITicket indexed ticket);

    /// @dev Emitted when there was an error thrown awarding an External ERC721
    event ErrorAwardingExternalERC721(bytes error);

    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    function depositTo(address to, uint256 amount) external;

    /// @notice Deposit assets into the Prize Pool in exchange for tokens,
    /// then sets the delegate on behalf of the caller.
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    /// @param delegate The address to delegate to for the caller
    function depositToAndDelegate(address to, uint256 amount, address delegate) external;

    /// @notice Withdraw assets from the Prize Pool instantly.  A fairness fee may be charged for an early exit.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @return The actual amount withdrawn
    function withdrawFrom(address from, uint256 amount) external returns (uint256);

    /// @notice Called by the prize strategy to award prizes.
    /// @dev The amount awarded must be less than the awardBalance()
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of assets to be awarded
    function award(address to, uint256 amount) external;

    /// @notice Returns the balance that is available to award.
    /// @dev captureAwardBalance() should be called first
    /// @return The total amount of assets to be awarded for the current prize
    function awardBalance() external view returns (uint256);

    /// @notice Captures any available interest as award balance.
    /// @dev This function also captures the reserve fees.
    /// @return The total amount of assets to be awarded for the current prize
    function captureAwardBalance() external returns (uint256);

    /// @dev Checks with the Prize Pool if a specific token type may be awarded as an external prize
    /// @param externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function canAwardExternal(address externalToken) external view returns (bool);

    // @dev Returns the total underlying balance of all assets. This includes both principal and interest.
    /// @return The underlying balance of assets
    function balance() external returns (uint256);

    /**
     * @notice Read internal Ticket accounted balance.
     * @return uint256 accountBalance
     */
    function getAccountedBalance() external view returns (uint256);

    /**
     * @notice Read internal balanceCap variable
     */
    function getBalanceCap() external view returns (uint256);

    /**
     * @notice Read internal liquidityCap variable
     */
    function getLiquidityCap() external view returns (uint256);

    /**
     * @notice Read ticket variable
     */
    function getTicket() external view returns (ITicket);

    /**
     * @notice Read token variable
     */
    function getToken() external view returns (address);

    /**
     * @notice Read prizeStrategy variable
     */
    function getPrizeStrategy() external view returns (address);

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function isControlled(ITicket controlledToken) external view returns (bool);

    /// @notice Called by the Prize-Strategy to transfer out external ERC20 tokens
    /// @dev Used to transfer out tokens held by the Prize Pool.  Could be liquidated, or anything.
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external asset token being awarded
    /// @param amount The amount of external assets to be awarded
    function transferExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the Prize-Strategy to award external ERC20 prizes
    /// @dev Used to award any arbitrary tokens held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of external assets to be awarded
    /// @param externalToken The address of the external asset token being awarded
    function awardExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the prize strategy to award external ERC721 prizes
    /// @dev Used to award any arbitrary NFTs held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external NFT token being awarded
    /// @param tokenIds An array of NFT Token IDs to be transferred
    function awardExternalERC721(
        address to,
        address externalToken,
        uint256[] calldata tokenIds
    ) external;

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @dev If a user wins, his balance can go over the cap. He will be able to withdraw the excess but not deposit.
    /// @dev Needs to be called after deploying a prize pool to be able to deposit into it.
    /// @param balanceCap New balance cap.
    /// @return True if new balance cap has been successfully set.
    function setBalanceCap(uint256 balanceCap) external returns (bool);

    /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
    /// @param liquidityCap The new liquidity cap for the prize pool
    function setLiquidityCap(uint256 liquidityCap) external;

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy.
    function setPrizeStrategy(address _prizeStrategy) external;

    /// @notice Set prize pool ticket.
    /// @param ticket Address of the ticket to set.
    /// @return True if ticket has been successfully set.
    function setTicket(ITicket ticket) external returns (bool);

    /// @notice Delegate the votes for a Compound COMP-like token held by the prize pool
    /// @param compLike The COMP-like token held by the prize pool that should be delegated
    /// @param to The address to delegate to
    function compLikeDelegate(ICompLike compLike, address to) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../libraries/TwabLib.sol";
import "./IControlledToken.sol";

interface ITicket is IControlledToken {
    /**
     * @notice A struct containing details for an Account.
     * @param balance The current balance for an Account.
     * @param nextTwabIndex The next available index to store a new twab.
     * @param cardinality The number of recorded twabs (plus one!).
     */
    struct AccountDetails {
        uint224 balance;
        uint16 nextTwabIndex;
        uint16 cardinality;
    }

    /**
     * @notice Combines account details with their twab history.
     * @param details The account details.
     * @param twabs The history of twabs for this account.
     */
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[65535] twabs;
    }

    /**
     * @notice Emitted when TWAB balance has been delegated to another user.
     * @param delegator Address of the delegator.
     * @param delegate Address of the delegate.
     */
    event Delegated(address indexed delegator, address indexed delegate);

    /**
     * @notice Emitted when ticket is initialized.
     * @param name Ticket name (eg: PoolTogether Dai Ticket (Compound)).
     * @param symbol Ticket symbol (eg: PcDAI).
     * @param decimals Ticket decimals.
     * @param controller Token controller address.
     */
    event TicketInitialized(string name, string symbol, uint8 decimals, address indexed controller);

    /**
     * @notice Emitted when a new TWAB has been recorded.
     * @param delegate The recipient of the ticket power (may be the same as the user).
     * @param newTwab Updated TWAB of a ticket holder after a successful TWAB recording.
     */
    event NewUserTwab(
        address indexed delegate,
        ObservationLib.Observation newTwab
    );

    /**
     * @notice Emitted when a new total supply TWAB has been recorded.
     * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a successful total supply TWAB recording.
     */
    event NewTotalSupplyTwab(ObservationLib.Observation newTotalSupplyTwab);

    /**
     * @notice Retrieves the address of the delegate to whom `user` has delegated their tickets.
     * @dev Address of the delegate will be the zero address if `user` has not delegated their tickets.
     * @param user Address of the delegator.
     * @return Address of the delegate.
     */
    function delegateOf(address user) external view returns (address);

    /**
    * @notice Delegate time-weighted average balances to an alternative address.
    * @dev    Transfers (including mints) trigger the storage of a TWAB in delegate(s) account, instead of the
              targetted sender and/or recipient address(s).
    * @dev    To reset the delegate, pass the zero address (0x000.000) as `to` parameter.
    * @dev Current delegate address should be different from the new delegate address `to`.
    * @param  to Recipient of delegated TWAB.
    */
    function delegate(address to) external;

    /**
     * @notice Allows the controller to delegate on a users behalf.
     * @param user The user for whom to delegate
     * @param delegate The new delegate
     */
    function controllerDelegateFor(address user, address delegate) external;

    /**
     * @notice Allows a user to delegate via signature
     * @param user The user who is delegating
     * @param delegate The new delegate
     * @param deadline The timestamp by which this must be submitted
     * @param v The v portion of the ECDSA sig
     * @param r The r portion of the ECDSA sig
     * @param s The s portion of the ECDSA sig
     */
    function delegateWithSignature(
        address user,
        address delegate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Gets a users twab context.  This is a struct with their balance, next twab index, and cardinality.
     * @param user The user for whom to fetch the TWAB context.
     * @return The TWAB context, which includes { balance, nextTwabIndex, cardinality }
     */
    function getAccountDetails(address user) external view returns (TwabLib.AccountDetails memory);

    /**
     * @notice Gets the TWAB at a specific index for a user.
     * @param user The user for whom to fetch the TWAB.
     * @param index The index of the TWAB to fetch.
     * @return The TWAB, which includes the twab amount and the timestamp.
     */
    function getTwab(address user, uint16 index)
        external
        view
        returns (ObservationLib.Observation memory);

    /**
     * @notice Retrieves `user` TWAB balance.
     * @param user Address of the user whose TWAB is being fetched.
     * @param timestamp Timestamp at which we want to retrieve the TWAB balance.
     * @return The TWAB balance at the given timestamp.
     */
    function getBalanceAt(address user, uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves `user` TWAB balances.
     * @param user Address of the user whose TWABs are being fetched.
     * @param timestamps Timestamps range at which we want to retrieve the TWAB balances.
     * @return `user` TWAB balances.
     */
    function getBalancesAt(address user, uint64[] calldata timestamps)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Retrieves the average balance held by a user for a given time frame.
     * @param user The user whose balance is checked.
     * @param startTime The start time of the time frame.
     * @param endTime The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalanceBetween(
        address user,
        uint64 startTime,
        uint64 endTime
    ) external view returns (uint256);

    /**
     * @notice Retrieves the average balances held by a user for a given time frame.
     * @param user The user whose balance is checked.
     * @param startTimes The start time of the time frame.
     * @param endTimes The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalancesBetween(
        address user,
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the total supply TWAB balance at the given timestamp.
     * @param timestamp Timestamp at which we want to retrieve the total supply TWAB balance.
     * @return The total supply TWAB balance at the given timestamp.
     */
    function getTotalSupplyAt(uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves the total supply TWAB balance between the given timestamps range.
     * @param timestamps Timestamps range at which we want to retrieve the total supply TWAB balance.
     * @return Total supply TWAB balances.
     */
    function getTotalSuppliesAt(uint64[] calldata timestamps)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Retrieves the average total supply balance for a set of given time frames.
     * @param startTimes Array of start times.
     * @param endTimes Array of end times.
     * @return The average total supplies held during the time frame.
     */
    function getAverageTotalSuppliesBetween(
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library ExtendedSafeCastLib {
    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 _value) internal pure returns (uint208) {
        require(_value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(_value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 _value) internal pure returns (uint224) {
        require(_value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(_value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";

/**
* @title Observation Library
* @notice This library allows one to store an array of timestamped values and efficiently binary search them.
* @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
* @author PoolTogether Inc.
*/
library ObservationLib {
    using OverflowSafeComparatorLib for uint32;
    using SafeCast for uint256;

    /// @notice The maximum number of observations
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /**
    * @notice Observation, which includes an amount and timestamp.
    * @param amount `amount` at `timestamp`.
    * @param timestamp Recorded `timestamp`.
    */
    struct Observation {
        uint224 amount;
        uint32 timestamp;
    }

    /**
    * @notice Fetches Observations `beforeOrAt` and `atOrAfter` a `_target`, eg: where [`beforeOrAt`, `atOrAfter`] is satisfied.
    * The result may be the same Observation, or adjacent Observations.
    * @dev The answer must be contained in the array used when the target is located within the stored Observation.
    * boundaries: older than the most recent Observation and younger, or the same age as, the oldest Observation.
    * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
    *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
    * @param _observations List of Observations to search through.
    * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
    * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
    * @param _target Timestamp at which we are searching the Observation.
    * @param _cardinality Cardinality of the circular buffer we are searching through.
    * @param _time Timestamp at which we perform the binary search.
    * @return beforeOrAt Observation recorded before, or at, the target.
    * @return atOrAfter Observation recorded at, or after, the target.
    */
    function binarySearch(
        Observation[MAX_CARDINALITY] storage _observations,
        uint24 _newestObservationIndex,
        uint24 _oldestObservationIndex,
        uint32 _target,
        uint24 _cardinality,
        uint32 _time
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 leftSide = _oldestObservationIndex;
        uint256 rightSide = _newestObservationIndex < leftSide
            ? leftSide + _cardinality - 1
            : _newestObservationIndex;
        uint256 currentIndex;

        while (true) {
            // We start our search in the middle of the `leftSide` and `rightSide`.
            // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
            currentIndex = (leftSide + rightSide) / 2;

            beforeOrAt = _observations[uint24(RingBufferLib.wrap(currentIndex, _cardinality))];
            uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

            // We've landed on an uninitialized timestamp, keep searching higher (more recently).
            if (beforeOrAtTimestamp == 0) {
                leftSide = currentIndex + 1;
                continue;
            }

            atOrAfter = _observations[uint24(RingBufferLib.nextIndex(currentIndex, _cardinality))];

            bool targetAtOrAfter = beforeOrAtTimestamp.lte(_target, _time);

            // Check if we've found the corresponding Observation.
            if (targetAtOrAfter && _target.lte(atOrAfter.timestamp, _time)) {
                break;
            }

            // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
            if (!targetAtOrAfter) {
                rightSide = currentIndex - 1;
            } else {
                // Otherwise, we keep searching higher. To the left of the current index.
                leftSide = currentIndex + 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/// @title OverflowSafeComparatorLib library to share comparator functions between contracts
/// @dev Code taken from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/3e88af408132fc957e3e406f65a0ce2b1ca06c3d/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library OverflowSafeComparatorLib {
    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically < `_b`.
    function lt(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a < _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted < bAdjusted;
    }

    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically <= `_b`.
    function lte(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {

        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a <= _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice 32-bit timestamp subtractor
    /// @dev safe for 0 or 1 overflows, where `_a` and `_b` must be chronologically before or equal to time
    /// @param _a The subtraction left operand
    /// @param _b The subtraction right operand
    /// @param _timestamp The current time.  Expected to be chronologically after both.
    /// @return The difference between a and b, adjusted for overflow
    function checkedSub(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (uint32) {
        // No need to adjust if there hasn't been an overflow

        if (_a <= _timestamp && _b <= _timestamp) return _a - _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return uint32(aAdjusted - bAdjusted);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library RingBufferLib {
    /**
    * @notice Returns wrapped TWAB index.
    * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
    * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
    *       it will return 0 and will point to the first element of the array.
    * @param _index Index used to navigate through the TWAB circular buffer.
    * @param _cardinality TWAB buffer cardinality.
    * @return TWAB index.
    */
    function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
    * @notice Computes the negative offset from the given index, wrapped by the cardinality.
    * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
    * @param _index The index from which to offset
    * @param _amount The number of indices to offset.  This is subtracted from the given index.
    * @param _cardinality The number of elements in the ring buffer
    * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        return wrap(_index + _cardinality - _amount, _cardinality);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _cardinality The cardinality of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(uint256 _nextIndex, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        if (_cardinality == 0) {
            return 0;
        }

        return wrap(_nextIndex + _cardinality - 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(uint256 _index, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return wrap(_index + 1, _cardinality);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./ExtendedSafeCastLib.sol";
import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";
import "./ObservationLib.sol";

/**
  * @title  PoolTogether V4 TwabLib (Library)
  * @author PoolTogether Inc Team
  * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
  * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
            Each user is mapped to an Account struct containing the TWAB history (ring bufffer) and
            ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new TWAB
            checkpoint is stored in the circular ring buffer, as either a new checkpoint or rewriting
            a previous checkpoint with new parameters. The TwabLib (using existing blocktimes 1block/15sec)
            guarantees minimum 7.4 years of search history.
 */
library TwabLib {
    using OverflowSafeComparatorLib for uint32;
    using ExtendedSafeCastLib for uint256;

    /**
      * @notice Sets max ring buffer length in the Account.twabs Observation list.
                As users transfer/mint/burn tickets new Observation checkpoints are
                recorded. The current max cardinality guarantees a six month minimum,
                of historical accurate lookups with current estimates of 1 new block
                every 15 seconds - the of course contain a transfer to trigger an
                observation write to storage.
      * @dev    The user Account.AccountDetails.cardinality parameter can NOT exceed
                the max cardinality variable. Preventing "corrupted" ring buffer lookup
                pointers and new observation checkpoints.

                The MAX_CARDINALITY in fact guarantees at least 7.4 years of records:
                If 14 = block time in seconds
                (2**24) * 14 = 234881024 seconds of history
                234881024 / (365 * 24 * 60 * 60) ~= 7.44 years
    */
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /** @notice Struct ring buffer parameters for single user Account
      * @param balance       Current balance for an Account
      * @param nextTwabIndex Next uninitialized or updatable ring buffer checkpoint storage slot
      * @param cardinality   Current total "initialized" ring buffer checkpoints for single user AccountDetails.
                             Used to set initial boundary conditions for an efficient binary search.
    */
    struct AccountDetails {
        uint208 balance;
        uint24 nextTwabIndex;
        uint24 cardinality;
    }

    /// @notice Combines account details with their twab history
    /// @param details The account details
    /// @param twabs The history of twabs for this account
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[MAX_CARDINALITY] twabs;
    }

    /// @notice Increases an account's balance and records a new twab.
    /// @param _account The account whose balance will be increased
    /// @param _amount The amount to increase the balance by
    /// @param _currentTime The current time
    /// @return accountDetails The new AccountDetails
    /// @return twab The user's latest TWAB
    /// @return isNew Whether the TWAB is new
    function increaseBalance(
        Account storage _account,
        uint208 _amount,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;
        (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
        accountDetails.balance = _accountDetails.balance + _amount;
    }

    /** @notice Calculates the next TWAB checkpoint for an account with a decreasing balance.
     * @dev    With Account struct and amount decreasing calculates the next TWAB observable checkpoint.
     * @param _account        Account whose balance will be decreased
     * @param _amount         Amount to decrease the balance by
     * @param _revertMessage  Revert message for insufficient balance
     * @return accountDetails Updated Account.details struct
     * @return twab           TWAB observation (with decreasing average)
     * @return isNew          Whether TWAB is new or calling twice in the same block
     */
    function decreaseBalance(
        Account storage _account,
        uint208 _amount,
        string memory _revertMessage,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;

        require(_accountDetails.balance >= _amount, _revertMessage);

        (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
        unchecked {
            accountDetails.balance -= _amount;
        }
    }

    /** @notice Calculates the average balance held by a user for a given time frame.
      * @dev    Finds the average balance between start and end timestamp epochs.
                Validates the supplied end time is within the range of elapsed time i.e. less then timestamp of now.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _startTime      Start of timestamp range as an epoch
      * @param _endTime        End of timestamp range as an epoch
      * @param _currentTime    Block.timestamp
      * @return Average balance of user held between epoch timestamps start and end
    */
    function getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 endTime = _endTime > _currentTime ? _currentTime : _endTime;

        return
            _getAverageBalanceBetween(_twabs, _accountDetails, _startTime, endTime, _currentTime);
    }

    /// @notice Retrieves the oldest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the oldest TWAB in the twabs array
    /// @return twab The oldest TWAB
    function oldestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
        index = _accountDetails.nextTwabIndex;
        twab = _twabs[index];

        // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
        if (twab.timestamp == 0) {
            index = 0;
            twab = _twabs[0];
        }
    }

    /// @notice Retrieves the newest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the newest TWAB in the twabs array
    /// @return twab The newest TWAB
    function newestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
        index = uint24(RingBufferLib.newestIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
        twab = _twabs[index];
    }

    /// @notice Retrieves amount at `_targetTime` timestamp
    /// @param _twabs List of TWABs to search through.
    /// @param _accountDetails Accounts details
    /// @param _targetTime Timestamp at which the reserved TWAB should be for.
    /// @return uint256 TWAB amount at `_targetTime`.
    function getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 timeToTarget = _targetTime > _currentTime ? _currentTime : _targetTime;
        return _getBalanceAt(_twabs, _accountDetails, timeToTarget, _currentTime);
    }

    /// @notice Calculates the average balance held by a user for a given time frame.
    /// @param _startTime The start time of the time frame.
    /// @param _endTime The end time of the time frame.
    /// @return The average balance that the user held during the time frame.
    function _getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        (uint24 oldestTwabIndex, ObservationLib.Observation memory oldTwab) = oldestTwab(
            _twabs,
            _accountDetails
        );

        (uint24 newestTwabIndex, ObservationLib.Observation memory newTwab) = newestTwab(
            _twabs,
            _accountDetails
        );

        ObservationLib.Observation memory startTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _startTime,
            _currentTime
        );

        ObservationLib.Observation memory endTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _endTime,
            _currentTime
        );

        // Difference in amount / time
        return (endTwab.amount - startTwab.amount) / OverflowSafeComparatorLib.checkedSub(endTwab.timestamp, startTwab.timestamp, _currentTime);
    }

    /** @notice Searches TWAB history and calculate the difference between amount(s)/timestamp(s) to return average balance
                between the Observations closes to the supplied targetTime.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _targetTime     Target timestamp to filter Observations in the ring buffer binary search
      * @param _currentTime    Block.timestamp
      * @return uint256 Time-weighted average amount between two closest observations.
    */
    function _getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        uint24 newestTwabIndex;
        ObservationLib.Observation memory afterOrAt;
        ObservationLib.Observation memory beforeOrAt;
        (newestTwabIndex, beforeOrAt) = newestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically after the newest TWAB, we can simply return the current balance
        if (beforeOrAt.timestamp.lte(_targetTime, _currentTime)) {
            return _accountDetails.balance;
        }

        uint24 oldestTwabIndex;
        // Now, set before to the oldest TWAB
        (oldestTwabIndex, beforeOrAt) = oldestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically before the oldest TWAB, we can early return
        if (_targetTime.lt(beforeOrAt.timestamp, _currentTime)) {
            return 0;
        }

        // Otherwise, we perform the `binarySearch`
        (beforeOrAt, afterOrAt) = ObservationLib.binarySearch(
            _twabs,
            newestTwabIndex,
            oldestTwabIndex,
            _targetTime,
            _accountDetails.cardinality,
            _currentTime
        );

        // Sum the difference in amounts and divide by the difference in timestamps.
        // The time-weighted average balance uses time measured between two epoch timestamps as
        // a constaint on the measurement when calculating the time weighted average balance.
        return
            (afterOrAt.amount - beforeOrAt.amount) / OverflowSafeComparatorLib.checkedSub(afterOrAt.timestamp, beforeOrAt.timestamp, _currentTime);
    }

    /** @notice Calculates a user TWAB for a target timestamp using the historical TWAB records.
                The balance is linearly interpolated: amount differences / timestamp differences
                using the simple (after.amount - before.amount / end.timestamp - start.timestamp) formula.
    /** @dev    Binary search in _calculateTwab fails when searching out of bounds. Thus, before
                searching we exclude target timestamps out of range of newest/oldest TWAB(s).
                IF a search is before or after the range we "extrapolate" a Observation from the expected state.
      * @param _twabs           Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails  User AccountDetails struct loaded in memory
      * @param _newestTwab      Newest TWAB in history (end of ring buffer)
      * @param _oldestTwab      Olderst TWAB in history (end of ring buffer)
      * @param _newestTwabIndex Pointer in ring buffer to newest TWAB
      * @param _oldestTwabIndex Pointer in ring buffer to oldest TWAB
      * @param _targetTimestamp Epoch timestamp to calculate for time (T) in the TWAB
      * @param _time            Block.timestamp
      * @return accountDetails Updated Account.details struct
    */
    function _calculateTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        ObservationLib.Observation memory _newestTwab,
        ObservationLib.Observation memory _oldestTwab,
        uint24 _newestTwabIndex,
        uint24 _oldestTwabIndex,
        uint32 _targetTimestamp,
        uint32 _time
    ) private view returns (ObservationLib.Observation memory) {
        // If `_targetTimestamp` is chronologically after the newest TWAB, we extrapolate a new one
        if (_newestTwab.timestamp.lt(_targetTimestamp, _time)) {
            return _computeNextTwab(_newestTwab, _accountDetails.balance, _targetTimestamp);
        }

        if (_newestTwab.timestamp == _targetTimestamp) {
            return _newestTwab;
        }

        if (_oldestTwab.timestamp == _targetTimestamp) {
            return _oldestTwab;
        }

        // If `_targetTimestamp` is chronologically before the oldest TWAB, we create a zero twab
        if (_targetTimestamp.lt(_oldestTwab.timestamp, _time)) {
            return ObservationLib.Observation({ amount: 0, timestamp: _targetTimestamp });
        }

        // Otherwise, both timestamps must be surrounded by twabs.
        (
            ObservationLib.Observation memory beforeOrAtStart,
            ObservationLib.Observation memory afterOrAtStart
        ) = ObservationLib.binarySearch(
                _twabs,
                _newestTwabIndex,
                _oldestTwabIndex,
                _targetTimestamp,
                _accountDetails.cardinality,
                _time
            );

        uint224 heldBalance = (afterOrAtStart.amount - beforeOrAtStart.amount) /
            OverflowSafeComparatorLib.checkedSub(afterOrAtStart.timestamp, beforeOrAtStart.timestamp, _time);

        return _computeNextTwab(beforeOrAtStart, heldBalance, _targetTimestamp);
    }

    /**
     * @notice Calculates the next TWAB using the newestTwab and updated balance.
     * @dev    Storage of the TWAB obersation is managed by the calling function and not _computeNextTwab.
     * @param _currentTwab    Newest Observation in the Account.twabs list
     * @param _currentBalance User balance at time of most recent (newest) checkpoint write
     * @param _time           Current block.timestamp
     * @return TWAB Observation
     */
    function _computeNextTwab(
        ObservationLib.Observation memory _currentTwab,
        uint224 _currentBalance,
        uint32 _time
    ) private pure returns (ObservationLib.Observation memory) {
        // New twab amount = last twab amount (or zero) + (current amount * elapsed seconds)
        return
            ObservationLib.Observation({
                amount: _currentTwab.amount +
                    _currentBalance *
                    (_time.checkedSub(_currentTwab.timestamp, _time)),
                timestamp: _time
            });
    }

    /// @notice Sets a new TWAB Observation at the next available index and returns the new account details.
    /// @dev Note that if _currentTime is before the last observation timestamp, it appears as an overflow
    /// @param _twabs The twabs array to insert into
    /// @param _accountDetails The current account details
    /// @param _currentTime The current time
    /// @return accountDetails The new account details
    /// @return twab The newest twab (may or may not be brand-new)
    /// @return isNew Whether the newest twab was created by this call
    function _nextTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _currentTime
    )
        private
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        (, ObservationLib.Observation memory _newestTwab) = newestTwab(_twabs, _accountDetails);

        // if we're in the same block, return
        if (_newestTwab.timestamp == _currentTime) {
            return (_accountDetails, _newestTwab, false);
        }

        ObservationLib.Observation memory newTwab = _computeNextTwab(
            _newestTwab,
            _accountDetails.balance,
            _currentTime
        );

        _twabs[_accountDetails.nextTwabIndex] = newTwab;

        AccountDetails memory nextAccountDetails = push(_accountDetails);

        return (nextAccountDetails, newTwab, true);
    }

    /// @notice "Pushes" a new element on the AccountDetails ring buffer, and returns the new AccountDetails
    /// @param _accountDetails The account details from which to pull the cardinality and next index
    /// @return The new AccountDetails
    function push(AccountDetails memory _accountDetails)
        internal
        pure
        returns (AccountDetails memory)
    {
        _accountDetails.nextTwabIndex = uint24(
            RingBufferLib.nextIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY)
        );

        // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
        // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
        // exceeds the max cardinality, new observations would be incorrectly set or the
        // observation would be out of "bounds" of the ring buffer. Once reached the
        // AccountDetails.cardinality will continue to be equal to max cardinality.
        if (_accountDetails.cardinality < MAX_CARDINALITY) {
            _accountDetails.cardinality += 1;
        }

        return _accountDetails;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "../external/compound/ICompLike.sol";
import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";

/**
  * @title  PoolTogether V4 PrizePool
  * @author PoolTogether Inc Team
  * @notice Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.
            Users deposit and withdraw from this contract to participate in Prize Pool.
            Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
            Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
*/
abstract contract PrizePool is IPrizePool, Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// @notice Semver Version
    string public constant VERSION = "4.0.0";

    /// @notice Prize Pool ticket. Can only be set once by calling `setTicket()`.
    ITicket internal ticket;

    /// @notice The Prize Strategy that this Prize Pool is bound to.
    address internal prizeStrategy;

    /// @notice The total amount of tickets a user can hold.
    uint256 internal balanceCap;

    /// @notice The total amount of funds that the prize pool can hold.
    uint256 internal liquidityCap;

    /// @notice the The awardable balance
    uint256 internal _currentAwardBalance;

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure caller is the prize-strategy
    modifier onlyPrizeStrategy() {
        require(msg.sender == prizeStrategy, "PrizePool/only-prizeStrategy");
        _;
    }

    /// @dev Function modifier to ensure the deposit amount does not exceed the liquidity cap (if set)
    modifier canAddLiquidity(uint256 _amount) {
        require(_canAddLiquidity(_amount), "PrizePool/exceeds-liquidity-cap");
        _;
    }

    /* ============ Constructor ============ */

    /// @notice Deploy the Prize Pool
    /// @param _owner Address of the Prize Pool owner
    constructor(address _owner) Ownable(_owner) ReentrancyGuard() {
        _setLiquidityCap(type(uint256).max);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizePool
    function balance() external override returns (uint256) {
        return _balance();
    }

    /// @inheritdoc IPrizePool
    function awardBalance() external view override returns (uint256) {
        return _currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function canAwardExternal(address _externalToken) external view override returns (bool) {
        return _canAwardExternal(_externalToken);
    }

    /// @inheritdoc IPrizePool
    function isControlled(ITicket _controlledToken) external view override returns (bool) {
        return _isControlled(_controlledToken);
    }

    /// @inheritdoc IPrizePool
    function getAccountedBalance() external view override returns (uint256) {
        return _ticketTotalSupply();
    }

    /// @inheritdoc IPrizePool
    function getBalanceCap() external view override returns (uint256) {
        return balanceCap;
    }

    /// @inheritdoc IPrizePool
    function getLiquidityCap() external view override returns (uint256) {
        return liquidityCap;
    }

    /// @inheritdoc IPrizePool
    function getTicket() external view override returns (ITicket) {
        return ticket;
    }

    /// @inheritdoc IPrizePool
    function getPrizeStrategy() external view override returns (address) {
        return prizeStrategy;
    }

    /// @inheritdoc IPrizePool
    function getToken() external view override returns (address) {
        return address(_token());
    }

    /// @inheritdoc IPrizePool
    function captureAwardBalance() external override nonReentrant returns (uint256) {
        uint256 ticketTotalSupply = _ticketTotalSupply();
        uint256 currentAwardBalance = _currentAwardBalance;

        // it's possible for the balance to be slightly less due to rounding errors in the underlying yield source
        uint256 currentBalance = _balance();
        uint256 totalInterest = (currentBalance > ticketTotalSupply)
            ? currentBalance - ticketTotalSupply
            : 0;

        uint256 unaccountedPrizeBalance = (totalInterest > currentAwardBalance)
            ? totalInterest - currentAwardBalance
            : 0;

        if (unaccountedPrizeBalance > 0) {
            currentAwardBalance = totalInterest;
            _currentAwardBalance = currentAwardBalance;

            emit AwardCaptured(unaccountedPrizeBalance);
        }

        return currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function depositTo(address _to, uint256 _amount)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
    }

    /// @inheritdoc IPrizePool
    function depositToAndDelegate(address _to, uint256 _amount, address _delegate)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
        ticket.controllerDelegateFor(msg.sender, _delegate);
    }

    /// @notice Transfers tokens in from one user and mints tickets to another
    /// @notice _operator The user to transfer tokens from
    /// @notice _to The user to mint tickets to
    /// @notice _amount The amount to transfer and mint
    function _depositTo(address _operator, address _to, uint256 _amount) internal
    {
        require(_canDeposit(_to, _amount), "PrizePool/exceeds-balance-cap");

        ITicket _ticket = ticket;

        _token().safeTransferFrom(_operator, address(this), _amount);

        _mint(_to, _amount, _ticket);
        _supply(_amount);

        emit Deposited(_operator, _to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function withdrawFrom(address _from, uint256 _amount)
        external
        override
        nonReentrant
        returns (uint256)
    {
        ITicket _ticket = ticket;

        // burn the tickets
        _ticket.controllerBurnFrom(msg.sender, _from, _amount);

        // redeem the tickets
        uint256 _redeemed = _redeem(_amount);

        _token().safeTransfer(_from, _redeemed);

        emit Withdrawal(msg.sender, _from, _ticket, _amount, _redeemed);

        return _redeemed;
    }

    /// @inheritdoc IPrizePool
    function award(address _to, uint256 _amount) external override onlyPrizeStrategy {
        if (_amount == 0) {
            return;
        }

        uint256 currentAwardBalance = _currentAwardBalance;

        require(_amount <= currentAwardBalance, "PrizePool/award-exceeds-avail");

        unchecked {
            _currentAwardBalance = currentAwardBalance - _amount;
        }

        ITicket _ticket = ticket;

        _mint(_to, _amount, _ticket);

        emit Awarded(_to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function transferExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeStrategy {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit TransferredExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeStrategy {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit AwardedExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC721(
        address _to,
        address _externalToken,
        uint256[] calldata _tokenIds
    ) external override onlyPrizeStrategy {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_tokenIds.length == 0) {
            return;
        }

        uint256[] memory _awardedTokenIds = new uint256[](_tokenIds.length); 
        bool hasAwardedTokenIds;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            try IERC721(_externalToken).safeTransferFrom(address(this), _to, _tokenIds[i]) {
                hasAwardedTokenIds = true;
                _awardedTokenIds[i] = _tokenIds[i];
            } catch (
                bytes memory error
            ) {
                emit ErrorAwardingExternalERC721(error);
            }
        }
        if (hasAwardedTokenIds) { 
            emit AwardedExternalERC721(_to, _externalToken, _awardedTokenIds);
        }
    }

    /// @inheritdoc IPrizePool
    function setBalanceCap(uint256 _balanceCap) external override onlyOwner returns (bool) {
        _setBalanceCap(_balanceCap);
        return true;
    }

    /// @inheritdoc IPrizePool
    function setLiquidityCap(uint256 _liquidityCap) external override onlyOwner {
        _setLiquidityCap(_liquidityCap);
    }

    /// @inheritdoc IPrizePool
    function setTicket(ITicket _ticket) external override onlyOwner returns (bool) {
        require(address(_ticket) != address(0), "PrizePool/ticket-not-zero-address");
        require(address(ticket) == address(0), "PrizePool/ticket-already-set");

        ticket = _ticket;

        emit TicketSet(_ticket);

        _setBalanceCap(type(uint256).max);

        return true;
    }

    /// @inheritdoc IPrizePool
    function setPrizeStrategy(address _prizeStrategy) external override onlyOwner {
        _setPrizeStrategy(_prizeStrategy);
    }

    /// @inheritdoc IPrizePool
    function compLikeDelegate(ICompLike _compLike, address _to) external override onlyOwner {
        if (_compLike.balanceOf(address(this)) > 0) {
            _compLike.delegate(_to);
        }
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* ============ Internal Functions ============ */

    /// @notice Transfer out `amount` of `externalToken` to recipient `to`
    /// @dev Only awardable `externalToken` can be transferred out
    /// @param _to Recipient address
    /// @param _externalToken Address of the external asset token being transferred
    /// @param _amount Amount of external assets to be transferred
    /// @return True if transfer is successful
    function _transferOut(
        address _to,
        address _externalToken,
        uint256 _amount
    ) internal returns (bool) {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_amount == 0) {
            return false;
        }

        IERC20(_externalToken).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice Called to mint controlled tokens.  Ensures that token listener callbacks are fired.
    /// @param _to The user who is receiving the tokens
    /// @param _amount The amount of tokens they are receiving
    /// @param _controlledToken The token that is going to be minted
    function _mint(
        address _to,
        uint256 _amount,
        ITicket _controlledToken
    ) internal {
        _controlledToken.controllerMint(_to, _amount);
    }

    /// @dev Checks if `user` can deposit in the Prize Pool based on the current balance cap.
    /// @param _user Address of the user depositing.
    /// @param _amount The amount of tokens to be deposited into the Prize Pool.
    /// @return True if the Prize Pool can receive the specified `amount` of tokens.
    function _canDeposit(address _user, uint256 _amount) internal view returns (bool) {
        uint256 _balanceCap = balanceCap;

        if (_balanceCap == type(uint256).max) return true;

        return (ticket.balanceOf(_user) + _amount <= _balanceCap);
    }

    /// @dev Checks if the Prize Pool can receive liquidity based on the current cap
    /// @param _amount The amount of liquidity to be added to the Prize Pool
    /// @return True if the Prize Pool can receive the specified amount of liquidity
    function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
        uint256 _liquidityCap = liquidityCap;
        if (_liquidityCap == type(uint256).max) return true;
        return (_ticketTotalSupply() + _amount <= _liquidityCap);
    }

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param _controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function _isControlled(ITicket _controlledToken) internal view returns (bool) {
        return (ticket == _controlledToken);
    }

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @param _balanceCap New balance cap.
    function _setBalanceCap(uint256 _balanceCap) internal {
        balanceCap = _balanceCap;
        emit BalanceCapSet(_balanceCap);
    }

    /// @notice Allows the owner to set a liquidity cap for the pool
    /// @param _liquidityCap New liquidity cap
    function _setLiquidityCap(uint256 _liquidityCap) internal {
        liquidityCap = _liquidityCap;
        emit LiquidityCapSet(_liquidityCap);
    }

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy
    function _setPrizeStrategy(address _prizeStrategy) internal {
        require(_prizeStrategy != address(0), "PrizePool/prizeStrategy-not-zero");

        prizeStrategy = _prizeStrategy;

        emit PrizeStrategySet(_prizeStrategy);
    }

    /// @notice The current total of tickets.
    /// @return Ticket total supply.
    function _ticketTotalSupply() internal view returns (uint256) {
        return ticket.totalSupply();
    }

    /// @dev Gets the current time as represented by the current block
    /// @return The timestamp of the current block
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ============ Abstract Contract Implementatiton ============ */

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view virtual returns (bool);

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token
    function _token() internal view virtual returns (IERC20);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal virtual returns (uint256);

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal virtual;

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@pooltogether/yield-source-interface/contracts/IYieldSource.sol";

import "./PrizePool.sol";

/**
 * @title  PoolTogether V4 YieldSourcePrizePool
 * @author PoolTogether Inc Team
 * @notice The Yield Source Prize Pool uses a yield source contract to generate prizes.
 *         Funds that are deposited into the prize pool are then deposited into a yield source. (i.e. Aave, Compound, etc...)
 */
contract YieldSourcePrizePool is PrizePool {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Address of the yield source.
    IYieldSource public immutable yieldSource;

    /// @dev Emitted when yield source prize pool is deployed.
    /// @param yieldSource Address of the yield source.
    event Deployed(address indexed yieldSource);

    /// @notice Emitted when stray deposit token balance in this contract is swept
    /// @param amount The amount that was swept
    event Swept(uint256 amount);

    /// @notice Deploy the Prize Pool and Yield Service with the required contract connections
    /// @param _owner Address of the Yield Source Prize Pool owner
    /// @param _yieldSource Address of the yield source
    constructor(address _owner, IYieldSource _yieldSource) PrizePool(_owner) {
        require(
            address(_yieldSource) != address(0),
            "YieldSourcePrizePool/yield-source-not-zero-address"
        );

        yieldSource = _yieldSource;

        // A hack to determine whether it's an actual yield source
        (bool succeeded, bytes memory data) = address(_yieldSource).staticcall(
            abi.encodePacked(_yieldSource.depositToken.selector)
        );
        address resultingAddress;
        if (data.length > 0) {
            resultingAddress = abi.decode(data, (address));
        }
        require(succeeded && resultingAddress != address(0), "YieldSourcePrizePool/invalid-yield-source");

        emit Deployed(address(_yieldSource));
    }

    /// @notice Sweeps any stray balance of deposit tokens into the yield source.
    /// @dev This becomes prize money
    function sweep() external nonReentrant onlyOwner {
        uint256 balance = _token().balanceOf(address(this));
        _supply(balance);

        emit Swept(balance);
    }

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        IYieldSource _yieldSource = yieldSource;
        return (
            _externalToken != address(_yieldSource) &&
            _externalToken != _yieldSource.depositToken()
        );
    }

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal override returns (uint256) {
        return yieldSource.balanceOfToken(address(this));
    }

    /// @notice Returns the address of the ERC20 asset token used for deposits.
    /// @return Address of the ERC20 asset token.
    function _token() internal view override returns (IERC20) {
        return IERC20(yieldSource.depositToken());
    }

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal override {
        _token().safeIncreaseAllowance(address(yieldSource), _mintAmount);
        yieldSource.supplyTokenTo(_mintAmount, address(this));
    }

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal override returns (uint256) {
        return yieldSource.redeemToken(_redeemAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

/// @title Defines the functions used to interact with a yield source.  The Prize Pool inherits this contract.
/// @notice Prize Pools subclasses need to implement this interface so that yield can be generated.
interface IYieldSource {
    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token address.
    function depositToken() external view returns (address);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens.
    function balanceOfToken(address addr) external returns (uint256);

    /// @notice Supplies tokens to the yield source.  Allows assets to be supplied on other user's behalf using the `to` param.
    /// @param amount The amount of asset tokens to be supplied.  Denominated in `depositToken()` as above.
    /// @param to The user whose balance will receive the tokens
    function supplyTokenTo(uint256 amount, address to) external;

    /// @notice Redeems tokens from the yield source.
    /// @param amount The amount of asset tokens to withdraw.  Denominated in `depositToken()` as above.
    /// @return The actual amount of interst bearing tokens that were redeemed.
    function redeemToken(uint256 amount) external returns (uint256);
}