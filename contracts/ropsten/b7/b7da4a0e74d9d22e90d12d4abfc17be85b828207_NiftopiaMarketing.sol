/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/Niftopia/Marketing.sol


pragma solidity =0.8.6;











interface IMarketing is IERC721Receiver, IERC1155Receiver {
    /**
     * owner events
    **/

    event CreatMarketing(
        address indexed collectionAddress,
        uint256[] indexed tokenIds,
        uint8 typeId,
        uint8[] optionIds,
        bool isExclusive,
        uint256 dailyPrice,
        uint256 penaltyValue,
        uint256 depositValue,
        uint32 startDate,
        uint32 endDate,
        bool isCollection,
        address indexed sellerAddress,
        uint256 marketingId,
        uint32 createdTime
    );

    event AddItemInMarketing(
        uint256 indexed marketingId,
        address indexed collectionAddress,
        uint256[] indexed tokenIds,
        uint32 updatedTime
    );

    event WithdrawItemFromMarketing(
        uint256 indexed marketingId,
        address indexed collectionAddress,
        uint256[] indexed tokenIds,
        uint32 updatedTime
    );

    event UpdatePeriodOfMarketing(
        uint256 indexed marketingId,
        uint32 startDate,
        uint32 endDate,
        uint32 updatedTime
    );



    /**
     * @dev Emitted on claimMarketingFees()
     * @param marketingId your marketing ID
     * @param amount Amount of fees from the marketing
     * @param claimedTime claimedTime
     **/
    event ClaimMarketingFees(
        uint256 indexed marketingId,
        address indexed tokenOwnerAddress,
        uint256 amount,
        uint32 claimedTime
    );

    /**
     * buyer events
    **/

    /**
     * @dev Emitted on purchaseMarketing()
     * @param marketingId your marketing ID
     * @param purchaseId your purchase ID
     * @param buyerAddress Address of purchase creator
     * @param duration Duration of puchase
     * @param purchasedTime purchasedTime
     **/
    event PurchaseMarketing(
        uint256 indexed marketingId,
        uint256 indexed purchaseId,
        address indexed buyerAddress,
        uint8 duration,
        uint32 purchasedTime
    );

    /**
     * @dev Emitted on updateDurationOfPurchase()
     * @param marketingId your marketing ID
     * @param purchaseId your purchase ID
     * @param duration Duration of purchase
     * @param updatedTime updatedTime
     **/
    event UpdateDurationOfPurchase(
        uint256 indexed marketingId,
        uint256 indexed purchaseId,
        uint8 duration,
        uint32 updatedTime
    );

    /**
     * @dev Emitted on cancelPurchase()
     * @param marketingId your marketing ID
     * @param purchaseId your purchase ID
     * @param canceledTime canceledTime
     **/
    event CancelPurchase(
        uint256 indexed marketingId,
        uint256 indexed purchaseId,
        uint32 canceledTime
    );

    /**
     * @dev Emitted on withdrawCollateral()
     * @param marketingId your marketing ID
     * @param purchaseId your purchase ID
     * @param amount Amount of remind collateral in the purchase
     * @param withdrewTime withdrewTime
     **/
    event WithdrawCollateral(
        uint256 indexed marketingId,
        uint256 indexed purchaseId,
        uint256 amount,
        uint32 withdrewTime
    );

    /**
     * @dev Emitted on depositCollateral()
     * @param marketingId your marketing ID
     * @param purchaseId your purchase ID
     * @param amount Amount for additional deposit in the purchase
     * @param depositedTime depositedTime
     **/
    event DepositCollateral(
        uint256 indexed marketingId,
        uint256 indexed purchaseId,
        uint256 amount,
        uint32 depositedTime
    );

    /**
     * @dev create your marketing and deposit your NFT to Marketing contract, which acts as an escrow between the owner and the buyer
     * @param _collectionAddress Address of collection contract including nfts to deposit
     * @param _tokenIds tokenIDs of nfts to deposit
     * @param _typeId The type id of nfts (e.g. image: 0, music: 1, video: 2 and ...)
     * @param _optionId The id of option (e.g. No porn: 0, Music Videos: 1 and ...)
     * @param _isExclusive one of Exclusive and Non-exclusive (Exclusive: true, Non-Exclusive: false)
     * @param _dailyPrice daily Price
     * @param _penaltyValue penalty value
     * @param _depositValue deposit value
     * @param _startDate marketing start date (timestamp)
     * @param _endDate marketing end date (timestamp)
     * @param _isCollection individual marketing or collection marketing (Collection: true, Non-collection: false)
     */

    function createMarketing(
        address _collectionAddress,
        uint256[] memory _tokenIds,
        uint8 _typeId,
        uint8[] memory _optionId,
        bool _isExclusive,
        uint256 _dailyPrice,
        uint256 _penaltyValue,
        uint256 _depositValue,
        uint32 _startDate,
        uint32 _endDate,
        bool _isCollection
    ) external;

    /**
     * @dev add your NFT to your Marketing
     * @param _marketingId your marketing ID
     * @param _collectionAddress Address of collection contract including nfts to deposit
     * @param _tokenIds tokenIDs of nfts to deposit
     */

    function addItemInMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) external;

    /**
     * @dev send your NFT from the marketing to your wallet
     * @param _marketingId your marketing ID
     * @param _collectionAddress Address of collection contract including nfts to deposit
     * @param _tokenIds tokenIDs of nfts to withdraw
     */

    function withdrawItemFromMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) external;


    /**
     * @dev update marketing period
     * @param _marketingId your marketing ID
     * @param _startDate marketing start date (timestamp)
     * @param _endDate marketing end date (timestamp)
     */

    function updatePeriodOfMarketing(
        uint256 _marketingId,
        uint32 _startDate,
        uint32 _endDate
    ) external;


    /**
     * @dev send your profit for the marketing to your wallet.
     * @param _marketingId your marketing ID
     */
    function claimMarketingFees(
        uint256 _marketingId
    ) external;

    /**
     * Buyer actions
    */

    /**
     * @dev register your address in marketing.
     * @param _marketingId your marketing ID
     * @param _duration usable duration
     *
     * msg.value = marketing fees + deposit value
     */
    function purchaseMarketing(
        uint256 _marketingId,
        uint8 _duration
    ) external payable;
}

contract NiftopiaMarketing is IMarketing, ERC721Holder, ERC1155Receiver, ERC1155Holder {
    using SafeERC20 for ERC20;

//    IResolver private resolver;
    address private admin;
    address payable private beneficiary;
    uint256 private marketingId = 1;
    bool public paused = false;
    uint256 private totalBalance = 0;

    uint8 marketingTypeNumber = 1;
    uint8 marketingOptionNumber = 1;
    mapping(uint8 => string) marketingTypes;
    mapping(uint8 => string) marketingOptions;

    uint256 public marketingFee = 0;

    uint256 private constant SECONDS_IN_DAY = 86400;

    struct Marketing {
        address payable creator;
        address collection;
        uint8 typeId;
        uint8[] optionIds;
        bool isExclusive;
        uint256 dailyPrice;
        uint256 penaltyValue;
        uint256 depositValue;
        uint32 startDate;
        uint32 endDate;
        bool isCollection;
        bool isActive;
        uint32 currentPurchaseId;
        uint256[] tokenIds;
        uint256 balance;
    }

    struct TokenOwner {
        uint256 tokenCount;
        uint256 withdrewAmount;
    }

    mapping(uint256 => Marketing) marketings;
    mapping(uint256 => mapping(address => TokenOwner)) marketingOwnerBalance;
    mapping(uint256 => mapping(uint256 => address)) marketingTokenIdOwner;
    mapping(uint256 => mapping(uint256 => uint256)) marketingTokenIdIndex;

    struct Purchase {
        address payable creator;
        uint8 duration;
        uint256 collateral;
        uint32 purchasedTime;
        uint32 endTime;
    }

    mapping(uint256 => mapping(uint256 => Purchase)) marketingPurchases;

    modifier onlyAdmin {
        require(msg.sender == admin, "Niftopia::not admin");
        _;
    }

    modifier onlyMarketingCreator (uint256 _marketingId) {
        require(_marketingId < marketingId, "markeing ID is not existing");
        require(msg.sender == marketings[_marketingId].creator, "You must be creator of this marketing");
        _;
    }

    modifier onlyPurchaseCreator (uint256 _marketingId, uint256 _purchaseId) {
        require(_marketingId < marketingId, "markeing ID is not existing");
        require(_purchaseId > 0 && _purchaseId <= marketings[_marketingId].currentPurchaseId, "purchase id error");
        require(msg.sender == marketingPurchases[_marketingId][_purchaseId].creator, "You must be creator of this purchase");
        _;
    }

    constructor(
    ) {
        admin = msg.sender;
    }

    function setMarketingTypes(string memory marketingType) external onlyAdmin {
        require(keccak256(abi.encodePacked(marketingType)) != keccak256(abi.encodePacked("")), "");
        marketingTypes[marketingTypeNumber] = marketingType;
        marketingTypeNumber ++;
    }

    function setMarketingOptions(string memory marketingOption) external onlyAdmin {
        require(keccak256(abi.encodePacked(marketingOption)) != keccak256(abi.encodePacked("")), "");
        marketingOptions[marketingOptionNumber] = marketingOption;
        marketingOptionNumber ++;
    }

    function getMarketingTypes(uint8 num) public view returns (string memory) {
        require(num < marketingTypeNumber, "");
        return marketingTypes[num];
    }

    function getMarketingOptions(uint8 num) public view returns (string memory) {
        require(num < marketingOptionNumber, "");
        return marketingOptions[num];
    }

    function createMarketing(
        address _collectionAddress,
        uint256[] memory _tokenIds,
        uint8 _typeId,
        uint8[] memory _optionIds,
        bool _isExclusive,
        uint256 _dailyPrice,
        uint256 _penaltyValue,
        uint256 _depositValue,
        uint32 _startDate,
        uint32 _endDate,
        bool _isCollection
    ) external override {
        ensureIsNotZeroAddr(_collectionAddress);
        require(_dailyPrice > 0, "");
        require(_typeId > 0 && _typeId < marketingTypeNumber, "");
        require(_startDate > uint32(block.timestamp), "start date error");
        require(_endDate > _startDate, "end date error");

        for (uint32 i = 0; i < _optionIds.length; i++) {
            require(_optionIds[i] > 0 && _optionIds[i] < marketingOptionNumber, "");
        }

        require(is721(_collectionAddress), "NiftopiaMarketing::Collection must be ERC721 token.");

        Marketing memory marketing = Marketing({
            creator: payable(msg.sender),
            collection: _collectionAddress,
            typeId: _typeId,
            optionIds: _optionIds,
            isExclusive: _isExclusive,
            dailyPrice: _dailyPrice,
            penaltyValue: _penaltyValue,
            depositValue: _depositValue,
            startDate: _startDate,
            endDate: _endDate,
            isCollection: _isCollection,
            isActive: true,
            currentPurchaseId: 0,
            tokenIds: new uint256[](0),
            balance: 0
        });

        marketings[marketingId] = marketing;

        uint256 _marketingId = marketingId;

        marketingId++;

        if (!_isCollection) {
            require(_tokenIds.length > 0, "token Id is required");
            _addItemInMarketing(_marketingId, _collectionAddress, _tokenIds);
        }

        emit CreatMarketing(
            _collectionAddress,
            _tokenIds,
            _typeId,
            _optionIds,
            _isExclusive,
            _dailyPrice,
            _penaltyValue,
            _depositValue,
            _startDate,
            _endDate,
            _isCollection,
            msg.sender,
            marketingId,
            uint32(block.timestamp)
        );


    }

    function _addItemInMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) private {
        Marketing storage marketing = marketings[_marketingId];
        uint256 tokenCount = marketing.tokenIds.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            marketing.tokenIds.push(_tokenIds[i]);
            tokenCount++;
            if (marketingOwnerBalance[_marketingId][msg.sender].tokenCount == 0) {
                marketingOwnerBalance[_marketingId][msg.sender] = TokenOwner({
                    tokenCount: 1,
                    withdrewAmount: 0
                }) ;
            } else {
                marketingOwnerBalance[_marketingId][msg.sender].tokenCount ++;
            }
            marketingTokenIdOwner[_marketingId][_tokenIds[i]] = msg.sender;
            marketingTokenIdIndex[_marketingId][_tokenIds[i]] = tokenCount;
            if (is721(_collectionAddress)) {
                IERC721(_collectionAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenIds[i]
                );
            }
        }
    }

    function addItemInMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) external override {
        ensureIsMarketingAssets(_marketingId, _collectionAddress, _tokenIds);
        Marketing memory marketing = marketings[_marketingId];
        require(_marketingId > 0 && _marketingId < marketingId, "range out of marketings");
        require(marketing.currentPurchaseId == 0, "you can't add items because marketing is running.");
        _addItemInMarketing(marketingId, _collectionAddress, _tokenIds);

        emit AddItemInMarketing(
            _marketingId,
            _collectionAddress,
            _tokenIds,
            uint32(block.timestamp)
        );
    }

    function withdrawItemFromMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) external override {
        ensureIsMarketingAssets(_marketingId, _collectionAddress, _tokenIds);
        require(marketings[_marketingId].currentPurchaseId == 0, "can't withdraw items");
        _withdrawItemFromMarketing(_marketingId, _collectionAddress, _tokenIds);

        emit WithdrawItemFromMarketing(
            _marketingId,
            _collectionAddress,
            _tokenIds,
            uint32(block.timestamp)
        );
    }

    function _withdrawItemFromMarketing(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) private {
        uint256 tokenIndex = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ensureTokenInMarketing(_marketingId, _tokenIds[i], msg.sender);
            tokenIndex = marketingTokenIdIndex[_marketingId][_tokenIds[i]];
            delete marketings[_marketingId].tokenIds[tokenIndex];
            if (marketingOwnerBalance[marketingId][msg.sender].tokenCount > 0) {
                marketingOwnerBalance[marketingId][msg.sender].tokenCount--;
            }
            marketingTokenIdOwner[marketingId][_tokenIds[i]] = address(0x0);
            marketingTokenIdIndex[marketingId][_tokenIds[i]] = 0;
            if (is721(_collectionAddress)) {
                IERC721(_collectionAddress).transferFrom(
                    address(this),
                    msg.sender,
                    _tokenIds[i]
                );
            }
        }
    }

    function claimMarketingFees(
        uint256 _marketingId
    ) external override {
        require(_marketingId > 0 && _marketingId  < marketingId, "range out of marketings");
        Marketing memory marketing = marketings[_marketingId];
        TokenOwner storage tokenOwner = marketingOwnerBalance[_marketingId][msg.sender];
        uint256 withdrawableFees = _withdrawableMarketingFees(marketing, tokenOwner);
        bool isSent = payable(msg.sender).send(withdrawableFees);
        require(isSent, "Failed to send Ether");
        tokenOwner.withdrewAmount += withdrawableFees;
        emit ClaimMarketingFees(_marketingId, msg.sender, withdrawableFees, uint32(block.timestamp));
    }

    function withdrawableMarketingFees(
        uint256 _marketingId
    ) public view returns (uint256) {
        require(_marketingId > 0 && _marketingId  < marketingId, "range out of marketings");
        Marketing memory marketing = marketings[_marketingId];
        TokenOwner memory tokenOwner = marketingOwnerBalance[_marketingId][msg.sender];
        return _withdrawableMarketingFees(marketing, tokenOwner);
    }

    function _withdrawableMarketingFees(
        Marketing memory marketing,
        TokenOwner memory tokenOwner
    ) public pure returns (uint256) {
        uint256 userFees = marketing.balance;
        userFees = userFees * tokenOwner.tokenCount / marketing.tokenIds.length;
        return userFees - tokenOwner.withdrewAmount;
    }

    function updatePeriodOfMarketing(
        uint256 _marketingId,
        uint32 _startDate,
        uint32 _endDate
    ) external onlyMarketingCreator(_marketingId) override {
        require(_startDate > uint32(block.timestamp), "start date error");
        require(_endDate > _startDate, "end date error");
        Marketing storage marketing = marketings[_marketingId];
        marketing.startDate = _startDate;
        marketing.endDate = _endDate;

        emit UpdatePeriodOfMarketing(
            _marketingId,
            _startDate,
            _endDate,
            uint32(block.timestamp)
        );
    }

    function _pauseMarketing(uint256 _marketingId) private {
        Marketing storage marketing = marketings[_marketingId];
        marketing.isActive = false;
    }

    function _openMarketing(uint256 _marketingId) private {
        Marketing storage marketing = marketings[_marketingId];
        marketing.isActive = true;
    }

    // Purchase functions

    function purchaseMarketing(
        uint256 _marketingId,
        uint8 _duration
    ) external payable override {

        require(_marketingId < marketingId, "markeing ID is not existing");
        require(_duration > 0, "duration > 0");
        Marketing storage marketing = marketings[_marketingId];
        require(marketing.isActive, "this marketing is disabled");
        uint32 cTime = uint32(block.timestamp);
        uint32 endTime = cTime;
        if (cTime < marketing.startDate) {
            endTime = marketing.startDate + 86400 * _duration;
        } else {
            endTime = cTime + 86400 * _duration;
        }
        require(endTime <= marketing.endDate, "date range out");

        uint256 amount = msg.value;

        require(amount == marketing.dailyPrice * _duration + marketing.depositValue, "you have to deposit enough money");
        uint256 _collateral = marketing.depositValue;
        if (!marketing.isExclusive) {
            require(marketing.currentPurchaseId == 0, "this marketing is exclusive and already was bought.");
        }
        uint32 purchasedTime = uint32(block.timestamp);
        Purchase memory purchase = Purchase({
            creator: payable(msg.sender),
            duration: _duration,
            collateral: _collateral,
            purchasedTime: purchasedTime,
            endTime: endTime
        });
        marketing.currentPurchaseId++;
        marketingPurchases[_marketingId][marketing.currentPurchaseId] = purchase;
        marketing.balance = marketing.balance + ((marketing.dailyPrice * _duration) * 95) / 100;

        totalBalance += amount;

        emit PurchaseMarketing(
            _marketingId,
            marketing.currentPurchaseId,
            msg.sender,
            _duration,
            uint32(block.timestamp)
        );
    }

    function ensureTokenInMarketing(
        uint256 _marketingId,
        uint256 _tokenId,
        address owner
    ) private view {
        require(marketingTokenIdOwner[_marketingId][_tokenId] == owner, "you don't owner of the token");
    }


    function ensureIsMarketingAssets(
        uint256 _marketingId,
        address _collectionAddress,
        uint256[] memory _tokenIds
    ) private view {
        require(_marketingId < marketingId, "markeing ID is not existing");
        require(marketings[_marketingId].isCollection, "can't add items in personal marketing");
        ensureIsNotZeroAddr(_collectionAddress);
        require(_collectionAddress == marketings[_marketingId].collection, "collection address must be same to marketing collection address.");
        require(_tokenIds.length > 0, "");
    }

    // confirm functions

    function is721(address _nft) private view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC721).interfaceId);
    }

    function is1155(address _nft) private view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC1155).interfaceId);
    }

    function ensureIsNotZeroAddr(address _addr) private pure {
        require(_addr != address(0), "NiftopiaMarketing::zero address");
    }

    function ensureIsZeroAddr(address _addr) private pure {
        require(_addr == address(0), "NiftopiaMarketing::not a zero address");
    }

    // view functions

    function getLastMarketingId() public view returns (uint256) {
        return marketingId - 1;
    }

    function getMarketingDetail(uint256 _marketingId) public view returns (Marketing memory) {
        require(_marketingId != 0 && _marketingId < marketingId, "markeing ID is not existing" );
        Marketing memory marketing = marketings[_marketingId];
        return marketing;
    }

    function getMarketingPurchaseDetail(uint256 _marketingId, uint256 _purchaseId) public view returns (Purchase memory) {
        require(_marketingId != 0 && _marketingId < marketingId, "markeing ID is not existing" );
        require(_purchaseId > 0 && _purchaseId <= marketings[_marketingId].currentPurchaseId, "purchase id error");
        Purchase memory purchase = marketingPurchases[_marketingId][_purchaseId];
        return purchase;
    }

    function getBlockTime() public view returns (uint32) {
        return uint32(block.timestamp);
    }
}