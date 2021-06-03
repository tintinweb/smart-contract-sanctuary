/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

/*
 * Crypto stamp Bridge: Token Holder
 * ERC-721 and ERC-1155 tokens deposited to the bridge are owned by this
 * contract while they are active on the other side of the bridge. The bridge
 * can exit them from here again if needed via the bridge head. Users can push
 * tokens to the bridge via safeTresferFrom() to this token holder, or run
 * pull-based deposits via the bridge head.
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Österreichische Post AG <post.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://crypto.post.at/
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/utils/Address.sol


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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string calldata name) external returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// File: contracts/BridgeDataI.sol

/*
 * Interface for data storage of the bridge.
 */

interface BridgeDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);
    event ConnectedChainChanged(string previousConnectedChainName, string newConnectedChainName);
    event TokenURIBaseChanged(string previousTokenURIBase, string newTokenURIBase);
    event TokenSunsetAnnounced(uint256 indexed timestamp);

    /**
     * @dev The name of the chain connected to / on the other side of this bridge head.
     */
    function connectedChainName() external view returns (string memory);

    /**
     * @dev The name of our own chain, used in token URIs handed to deployed tokens.
     */
    function ownChainName() external view returns (string memory);

    /**
     * @dev The base of ALL token URIs, e.g. https://example.com/
     */
    function tokenURIBase() external view returns (string memory);

    /**
     * @dev The sunset timestamp for all deployed tokens.
     * If 0, no sunset is in place. Otherwise, if older than block timestamp,
     * all transfers of the tokens are frozen.
     */
    function tokenSunsetTimestamp() external view returns (uint256);

    /**
     * @dev Set a token sunset timestamp.
     */
    function setTokenSunsetTimestamp(uint256 _timestamp) external;

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/BridgeHeadI.sol

/*
 * Interface for a Bridge Head.
 */


interface BridgeHeadI {

    /**
     * @dev Emitted when an ERC721 token is deposited to the bridge.
     */
    event TokenDepositedERC721(address indexed tokenAddress, uint256 indexed tokenId, address indexed otherChainRecipient);

    /**
     * @dev Emitted when one or more ERC1155 tokens are deposited to the bridge.
     */
    event TokenDepositedERC1155Batch(address indexed tokenAddress, uint256[] tokenIds, uint256[] amounts, address indexed otherChainRecipient);

    /**
     * @dev Emitted when an ERC721 token is exited from the bridge.
     */
    event TokenExitedERC721(address indexed tokenAddress, uint256 indexed tokenId, address indexed recipient);

    /**
     * @dev Emitted when one or more ERC1155 tokens are exited from the bridge.
     */
    event TokenExitedERC1155Batch(address indexed tokenAddress, uint256[] tokenIds, uint256[] amounts, address indexed recipient);

    /**
     * @dev Emitted when a new bridged token is deployed.
     */
    event BridgedTokenDeployed(address indexed ownAddress, address indexed foreignAddress);

    /**
     * @dev The address of the bridge data contract storing all addresses and chain info for this bridge
     */
    function bridgeData() external view returns (BridgeDataI);

    /**
     * @dev The bridge controller address
     */
    function bridgeControl() external view returns (address);

    /**
     * @dev The token holder contract connected to this bridge head
     */
    function tokenHolder() external view returns (TokenHolderI);

    /**
     * @dev The name of the chain connected to / on the other side of this bridge head.
     */
    function connectedChainName() external view returns (string memory);

    /**
     * @dev The name of our own chain, used in token URIs handed to deployed tokens.
     */
    function ownChainName() external view returns (string memory);

    /**
     * @dev The minimum amount of (valid) signatures that need to be present in `processExitData()`.
     */
    function minSignatures() external view returns (uint256);

    /**
     * @dev True if deposits are possible at this time.
     */
    function depositEnabled() external view returns (bool);

    /**
     * @dev True if exits are possible at this time.
     */
    function exitEnabled() external view returns (bool);

    /**
     * @dev Called by token holder when a ERC721 token has been deposited and
     * needs to be moved to the other side of the bridge.
     */
    function tokenDepositedERC721(address tokenAddress, uint256 tokenId, address otherChainRecipient) external;

    /**
     * @dev Called by token holder when a ERC1155 token has been deposited and
     * needs to be moved to the other side of the bridge. If it was no batch
     * deposit, still this function is called with with only the one items in
     * the batch.
     */
    function tokenDepositedERC1155Batch(address tokenAddress, uint256[] calldata tokenIds, uint256[] calldata amounts, address otherChainRecipient) external;

    /**
     * @dev Called by people/contracts who want to move an ERC721 token to the
     * other side of the bridge. Needs to be called by the current token owner.
     */
    function depositERC721(address tokenAddress, uint256 tokenId, address otherChainRecipient) external;

    /**
     * @dev Called by people/contracts who want to move an ERC1155 token to the
     * other side of the bridge. When only a single token ID is desposited,
     * called with only one entry in the arrays. Needs to be called by the
     * current token owner.
     */
    function depositERC1155Batch(address tokenAddress, uint256[] calldata tokenIds, uint256[] calldata amounts, address otherChainRecipient) external;

    /**
     * @dev Process an exit message. Can be called by anyone, but requires data
     * with valid signatures from a minimum of `minSignatures()` of allowed
     * signer addresses and an exit nonce for the respective signer that has
     * not been used yet. Also, all signers need to be ordered with ascending
     * addresses for the call to succeed.
     * The ABI-encoded payload is for a call on the bridge head contract.
     * The signature is over the contract address, the chain ID, the exit
     * nonce, and the payload.
     */
    function processExitData(bytes memory _payload, uint256 _expirationTimestamp, bytes[] memory _signatures, uint256[] memory _exitNonces) external;

    /**
     * @dev Return a predicted token address given the prototype name as listed
     * in bridge data ("ERC721Prototype" or "ERC1155Prototype") and foreign
     * token address.
     */
    function predictTokenAddress(string memory _prototypeName, address _foreignAddress) external view returns (address);

    /**
     * @dev Exit an ERC721 token from the bridge to a recipient. Can be owned
     * by either the token holder or an address that is treated as an
     * equivalent holder for the bride. If not existing, can be minted if
     * allowed, or even a token deployed based in a given foreign address and
     * symbol. If properties data is set, will send that to the token contract
     * to set properties for the token.
     */
    function exitERC721(address _tokenAddress, uint256 _tokenId, address _recipient, address _foreignAddress, bool _allowMinting, string calldata _symbol, bytes calldata _propertiesData) external;

    /**
     * @dev Exit an already existing ERC721 token from the bridge to a
     * recipient, owned currently by the bridge in some form.
     */
    function exitERC721Existing(address _tokenAddress, uint256 _tokenId, address _recipient) external;

    /**
     * @dev Exit ERC1155 token(s) from the bridge to a recipient. The token
     * source can be the token holder, an equivalent, or a Collection. Only
     * tokens owned by one source can be existed in one transaction. If the
     * source is the zero address, tokens will be minted.
     */
    function exitERC1155Batch(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _recipient, address _foreignAddress, address _tokenSource) external;

    /**
     * @dev Exit an already existing ERC1155 token from the bridge to a
     * recipient, owned currently by the token holder.
     */
    function exitERC1155BatchFromHolder(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _recipient) external;

    /**
     * @dev Forward calls to external contracts. Can only be called by owner.
     * Given a contract address and an already-encoded payload (with a function call etc.),
     * we call that contract with this payload, e.g. to trigger actions in the name of the token holder.
     */
    function callAsHolder(address payable _remoteAddress, bytes calldata _callPayload) external payable;

}

// File: contracts/TokenHolderI.sol

/*
 * Interface for a Token Holder.
 */






interface TokenHolderI is IERC165, IERC721Receiver, IERC1155Receiver {

    /**
     * @dev The address of the bridge data contract storing all addresses and chain info for this bridge
     */
    function bridgeData() external view returns (BridgeDataI);

    /**
     * @dev The bridge head contract connected to this token holder
     */
    function bridgeHead() external view returns (BridgeHeadI);

    /**
     * @dev Forward calls to external contracts. Can only be called by owner.
     * Given a contract address and an already-encoded payload (with a function call etc.),
     * we call that contract with this payload, e.g. to trigger actions in the name of the bridge.
     */
    function externalCall(address payable _remoteAddress, bytes calldata _callPayload) external payable;

    /**
     * @dev Transfer ERC721 tokens out of the holder contract.
     */
    function safeTransferERC721(address _tokenAddress, uint256 _tokenId, address _to) external;

    /**
     * @dev Transfer ERC1155 tokens out of the holder contract.
     */
    function safeTransferERC1155Batch(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _to) external;

}

// File: contracts/CollectionsI.sol

/*
 * Interface for the Collections factory.
 */


/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface CollectionsI is IERC721 {

    /**
     * @dev Emitted when a new collection is created.
     */
    event NewCollection(address indexed owner, address collectionAddress);

    /**
     * @dev Emitted when a collection is destroyed.
     */
    event KilledCollection(address indexed owner, address collectionAddress);

    /**
     * @dev Creates a new Collection. For calling from other contracts,
     * returns the address of the new Collection.
     */
    function create(address _notificationContract,
                    string calldata _ensName,
                    string calldata _ensSubdomainName,
                    address _ensSubdomainRegistrarAddress,
                    address _ensReverseRegistrarAddress)
    external payable
    returns (address);

    /**
     * @dev Create a collection for a different owner. Only callable by a
     * create controller role. For calling from other contracts, returns the
     * address of the new Collection.
     */
    function createFor(address payable _newOwner,
                       address _notificationContract,
                       string calldata _ensName,
                       string calldata _ensSubdomainName,
                       address _ensSubdomainRegistrarAddress,
                       address _ensReverseRegistrarAddress)
    external payable
    returns (address);

    /**
     * @dev Removes (burns) an empty Collection. Only the Collection contract itself can call this.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Returns if a Collection NFT exists for the specified `tokenId`.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns whether the given spender can transfer a given `collectionAddr`.
     */
    function isApprovedOrOwnerOnCollection(address spender, address collectionAddr) external view returns (bool);

    /**
     * @dev Returns the Collection address for a token ID.
     */
    function collectionAddress(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the token ID for a Collection address.
     */
    function tokenIdForCollection(address collectionAddr) external view returns (uint256);

    /**
     * @dev Returns true if a Collection exists at this address, false if not.
     */
    function collectionExists(address collectionAddr) external view returns (bool);

    /**
     * @dev Returns the owner of the Collection with the given address.
     */
    function collectionOwner(address collectionAddr) external view returns (address);

    /**
     * @dev Returns a Collection address owned by `owner` at a given `index` of
     * its Collections list. Mirrors `tokenOfOwnerByIndex` in ERC721Enumerable.
     */
    function collectionOfOwnerByIndex(address owner, uint256 index) external view returns (address);

}

// File: contracts/CollectionI.sol

/*
 * Interface for a single Collection, which is a very lightweight contract that can be the owner of ERC721 tokens.
 */





interface CollectionI is IERC165, IERC721Receiver, IERC1155Receiver  {

    /**
     * @dev Emitted when the notification conmtract is changed.
     */
    event NotificationContractTransferred(address indexed previousNotificationContract, address indexed newNotificationContract);

    /**
     * @dev Emitted when an asset is added to the collection.
     */
    event AssetAdded(address tokenAddress, uint256 tokenId);

    /**
     * @dev Emitted when an asset is removed to the collection.
     */
    event AssetRemoved(address tokenAddress, uint256 tokenId);

    /**
     * @dev Emitted when the Collection is destroyed.
     */
    event CollectionDestroyed(address operator);

    /**
     * @dev True is this is the prototype, false if this is an active
     * (clone/proxy) collection contract.
     */
    function isPrototype() external view returns (bool);

    /**
     * @dev The linked Collections factory (the ERC721 contract).
     */
    function collections() external view returns (CollectionsI);

    /**
     * @dev The linked notification contract (e.g. achievements).
     */
    function notificationContract() external view returns (address);

    /**
     * @dev Initializes a new Collection. Needs to be called by the Collections
     * factory.
     */
    function initialRegister(address _notificationContract,
                             string calldata _ensName,
                             string calldata _ensSubdomainName,
                             address _ensSubdomainRegistrarAddress,
                             address _ensReverseRegistrarAddress)
    external;

    /**
     * @dev Switch the notification contract to a different address. Set to the
     * zero address to disable notifications. Can only be called by owner.
     */
    function transferNotificationContract(address _newNotificationContract) external;

    /**
     * @dev Get collection owner from ERC 721 parent (Collections factory).
     */
    function ownerAddress() external view returns (address);

    /**
     * @dev Determine if the Collection owns a specific asset.
     */
    function ownsAsset(address _tokenAddress, uint256 _tokenId) external view returns(bool);

    /**
     * @dev Get count of owned assets.
     */
    function ownedAssetsCount() external view returns (uint256);

    /**
     * @dev Make sure ownership of a certain asset is recorded correctly (added
     * if the collection owns it or removed if it doesn't).
     */
    function syncAssetOwnership(address _tokenAddress, uint256 _tokenId) external;

    /**
     * @dev Transfer an owned asset to a new owner (for ERC1155, a single item
     * of that asset).
     */
    function safeTransferTo(address _tokenAddress, uint256 _tokenId, address _to) external;

    /**
     * @dev Transfer a certain amount of an owned asset to a new owner (for
     * ERC721, _value is ignored).
     */
    function safeTransferTo(address _tokenAddress, uint256 _tokenId, address _to, uint256 _value) external;

    /**
     * @dev Destroy and burn an empty Collection. Can only be called by owner
     * and only on empty collections.
     */
    function destroy() external;

    /**
     * @dev Forward calls to external contracts. Can only be called by owner.
     * Given a contract address and an already-encoded payload (with a function
     * call etc.), we call that contract with this payload, e.g. to trigger
     * actions in the name of the collection.
     */
    function externalCall(address payable _remoteAddress, bytes calldata _callPayload) external payable;

    /**
     * @dev Register ENS name. Can only be called by owner.
     */
    function registerENS(string calldata _name, address _registrarAddress) external;

    /**
     * @dev Register Reverse ENS name. Can only be called by owner.
     */
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name) external;
}

// File: contracts/TokenHolder.sol

/*
 * Token Holder for the Crypto stamp bridge.
 * This contract holds all tokens on its own layer/chain that have been
 * deposited into the other layer/chain. Deposit interactions happen directly
 * with depositing users, all other interactions (such as exits) come via the
 * Bridge Head.
 */









contract TokenHolder is ERC165, TokenHolderI {
    using Address for address;
    using Address for address payable;

    BridgeDataI public override bridgeData;

    event BridgeDataChanged(address indexed previousBridgeData, address indexed newBridgeData);

    constructor(address _bridgeDataAddress)
    {
        bridgeData = BridgeDataI(_bridgeDataAddress);
    }

    modifier onlyBridgeControl()
    {
        require(msg.sender == bridgeData.getAddress("bridgeControl"), "bridgeControl key required for this function.");
        _;
    }

    modifier onlyBridge()
    {
        require(msg.sender == bridgeData.getAddress("bridgeControl") || msg.sender == bridgeData.getAddress("bridgeHead"), "bridgeControl key or bridge head required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == bridgeData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC165, IERC165)
    returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /*** Enable adjusting variables after deployment ***/

    function setBridgeData(BridgeDataI _newBridgeData)
    external
    onlyBridgeControl
    {
        require(address(_newBridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        emit BridgeDataChanged(address(bridgeData), address(_newBridgeData));
        bridgeData = _newBridgeData;
    }

    function bridgeHead()
    public view override
    returns (BridgeHeadI) {
        return BridgeHeadI(bridgeData.getAddress("bridgeHead"));
    }

    /*** Deal with ERC721 and ERC1155 tokens we receive ***/

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data)
    external override
    returns (bytes4)
    {
        address otherChainRecipient = getRecipient(_operator, _from, _data);
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being an ERC721 contract.
        require(IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId), "onERC721Received caller needs to implement ERC721!");
        // If it's a Collection, make sure notification contract is set to zero.
        if (_tokenAddress == bridgeData.getAddress("Collections")) {
            CollectionI coll = CollectionI(CollectionsI(_tokenAddress).collectionAddress(_tokenId));
            if (coll.notificationContract() != address(0)) {
                coll.transferNotificationContract(address(0));
            }
        }
        // Now, tell the bridge head of the deposit, it will care about forwarding this token over the bridge.
        bridgeHead().tokenDepositedERC721(_tokenAddress, _tokenId, otherChainRecipient);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data)
    external override
    returns(bytes4)
    {
        address otherChainRecipient = getRecipient(_operator, _from, _data);
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being an ERC1155 contract.
        require(IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId), "onERC1155Received caller needs to implement ERC1155!");
        // Now, tell the bridge head of the deposit, it will care about forwarding this token over the bridge.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _id;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _value;
        bridgeHead().tokenDepositedERC1155Batch(_tokenAddress, tokenIds, amounts, otherChainRecipient);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data)
    external override
    returns(bytes4)
    {
        address otherChainRecipient = getRecipient(_operator, _from, _data);
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being an ERC1155 contract.
        require(IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId), "onERC1155BatchReceived caller needs to implement ERC1155!");
        // Now, tell the bridge head of the deposit, it will care about forwarding this token over the bridge.
        bridgeHead().tokenDepositedERC1155Batch(_tokenAddress, _ids, _values, otherChainRecipient);
        return this.onERC1155BatchReceived.selector;
    }

    function getRecipient(address _operator, address _from, bytes memory _data)
    internal view
    returns(address)
    {
        if (_operator == bridgeData.getAddress("bridgeHead") && _data.length > 0) {
            // This is a pull-based deposit called via the bridge head, take recipient from _data.
            return abi.decode(_data, (address));
        }
        if (_from.isContract()) {
            // We do not want tokens to end up in un-reachable addresses on the other side, so revert.
            revert("Deposit contract-owned token via bridge head!");
        }
        if (_from == address(0)) {
            // We do not want tokens to end up in un-reachable addresses on the other side, so revert.
            revert("Can't mint into bridge directly!");
        }
        // This is an EOA, so we give it to that address on the other side as well.
        return _from;
    }

    /*** Forward calls to external contracts ***/

    // Given a contract address and an already-encoded payload (with a function call etc.),
    // we call that contract with this payload, e.g. to trigger actions in the name of the token holder.
    function externalCall(address payable _remoteAddress, bytes calldata _callPayload)
    external override payable
    onlyBridge
    {
        require(_remoteAddress != address(this) && _remoteAddress != bridgeData.getAddress("bridgeHead"), "No calls to bridge via this mechanism!");
        // Using methods from OpenZeppelin's Address library to bubble up exceptions with their messages.
        if (_callPayload.length > 0) {
            _remoteAddress.functionCallWithValue(_callPayload, msg.value);
        }
        else {
            _remoteAddress.sendValue(msg.value);
        }
    }

    /*** Transfer assets out of the holder ***/

    function safeTransferERC721(address _tokenAddress, uint256 _tokenId, address _to)
    public override
    onlyBridge
    {
        IERC721(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId);
    }

    function safeTransferERC1155Batch(address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _amounts, address _to)
    public override
    onlyBridge
    {
        IERC1155(_tokenAddress).safeBatchTransferFrom(address(this), _to, _tokenIds, _amounts, "");
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respective network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // For Mainnet, the address needed is 0x9062c0a6dbd6108336bcbe4593a3d1ce05512069
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(address _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        IERC20 erc20Token = IERC20(_foreignToken);
        erc20Token.transfer(_to, erc20Token.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}