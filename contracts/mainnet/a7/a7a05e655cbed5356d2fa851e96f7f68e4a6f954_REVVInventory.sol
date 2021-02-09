/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// Sources flattened with hardhat v2.0.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC721 Non-Fungible Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Note: The ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * Gets the approved address for a token ID, or zero if no address set
     * @dev Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return operator address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * Sets or unsets the approval of a given operator
     * @dev An operator is allowed to transfer all tokens of the sender on their behalf
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Note: The ERC-165 identifier for this interface is 0x5b5e139f.
 */
interface IERC721Metadata {
    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory);

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     * @return string URI of given token ID
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC721 Non-Fungible Token Standard, optional unsafe batchTransfer interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Note: The ERC-165 identifier for this interface is.
 */
interface IERC721BatchTransfer {
    /**
     * Unsafely transfers a batch of tokens.
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `tokenIds` is not owned by `from`.
     * @dev Resets the token approval for each of `tokenIds`.
     * @dev Emits an {IERC721-Transfer} event for each of `tokenIds`.
     * @param from Current tokens owner.
     * @param to Address of the new token owner.
     * @param tokenIds Identifiers of the tokens to transfer.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

pragma solidity 0.6.8;

/**
    @title ERC721 Non-Fungible Token Standard, token receiver
    @dev See https://eips.ethereum.org/EIPS/eip-721
    Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
    Note: The ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
        @notice Handle the receipt of an NFT
        @dev The ERC721 smart contract calls this function on the recipient
        after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
        otherwise the caller will revert the transaction. The selector to be
        returned can be obtained as `this.onERC721Received.selector`. This
        function MAY throw to revert and reject the transfer.
        Note: the ERC721 contract address is always the message sender.
        @param operator The address which called `safeTransferFrom` function
        @param from The address which previously owned the token
        @param tokenId The NFT identifier which is being transferred
        @param data Additional data with no specified format
        @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/GSN/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/introspection/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    /**
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits a `TransferSingle` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance for any of `ids`.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits a `TransferBatch` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return The balance of `id` owned by account `owner`.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * Retrieves the balances of `ids` owned by accounts `owners`. For each pair:
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The addresses of the token holders
     * @param ids The identifiers to retrieve the balance of.
     * @return The balances of `ids` owned by accounts `owners`.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * Enables or disables an operator's approval.
     * @dev Emits an `ApprovalForAll` event.
     * @param operator Address of the operator.
     * @param approved True to approve the operator, false to revoke an approval.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * Retrieves the approval status of an operator for a given owner.
     * @param owner Address of the authorisation giver.
     * @param operator Address of the operator.
     * @return True if the operator is approved, false if not.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, optional metadata URI extension
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Note: The ERC-165 identifier for this interface is 0x0e89341c.
 */
interface IERC1155MetadataURI {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * @dev The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @dev The uri function SHOULD be used to retrieve values if no event was emitted.
     * @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
     * @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
     *  an implementation to return a valid string even if the token does not exist.
     * @return URI string
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, optional Inventory extension
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * Interface for fungible/non-fungible tokens management on a 1155-compliant contract.
 *
 * This interface rationalizes the co-existence of fungible and non-fungible tokens
 * within the same contract. As several kinds of fungible tokens can be managed under
 * the Multi-Token standard, we consider that non-fungible tokens can be classified
 * under their own specific type. We introduce the concept of non-fungible collection
 * and consider the usage of 3 types of identifiers:
 * (a) Fungible Token identifiers, each representing a set of Fungible Tokens,
 * (b) Non-Fungible Collection identifiers, each representing a set of Non-Fungible Tokens (this is not a token),
 * (c) Non-Fungible Token identifiers. 

 * Identifiers nature
 * |       Type                | isFungible  | isCollection | isToken |
 * |  Fungible Token           |   true      |     true     |  true   |
 * |  Non-Fungible Collection  |   false     |     true     |  false  |
 * |  Non-Fungible Token       |   false     |     false    |  true   |
 *
 * Identifiers compatibilities
 * |       Type                |  transfer  |   balance    |   supply    |  owner  |
 * |  Fungible Token           |    OK      |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Collection  |    NOK     |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Token       |    OK      |   0 or 1     |   0 or 1    |   OK    |
 *
 * Note: The ERC-165 identifier for this interface is 0x469bd23f.
 */
interface IERC1155Inventory {
    /**
     * Optional event emitted when a collection (Fungible Token or Non-Fungible Collection) is created.
     *  This event can be used by a client application to determine which identifiers are meaningful
     *  to track through the functions `balanceOf`, `balanceOfBatch` and `totalSupply`.
     * @dev This event MUST NOT be emitted twice for the same `collectionId`.
     */
    event CollectionCreated(uint256 indexed collectionId, bool indexed fungible);

    /**
     * Retrieves the owner of a non-fungible token (ERC721-compatible).
     * @dev Reverts if `nftId` is owned by the zero address.
     * @param nftId Identifier of the token to query.
     * @return Address of the current owner of the token.
     */
    function ownerOf(uint256 nftId) external view returns (address);

    /**
     * Introspects whether or not `id` represents a fungible token.
     *  This function MUST return true even for a fungible token which is not-yet created.
     * @param id The identifier to query.
     * @return bool True if `id` represents afungible token, false otherwise.
     */
    function isFungible(uint256 id) external pure returns (bool);

    /**
     * Introspects the non-fungible collection to which `nftId` belongs.
     * @dev This function MUST return a value representing a non-fungible collection.
     * @dev This function MUST return a value for a non-existing token, and SHOULD NOT be used to check the existence of a non-fungible token.
     * @dev Reverts if `nftId` does not represent a non-fungible token.
     * @param nftId The token identifier to query the collection of.
     * @return The non-fungible collection identifier to which `nftId` belongs.
     */
    function collectionOf(uint256 nftId) external pure returns (uint256);

    /**
     * Retrieves the total supply of `id`.
     * @param id The identifier for which to retrieve the supply of.
     * @return
     *  If `id` represents a collection (fungible token or non-fungible collection), the total supply for this collection.
     *  If `id` represents a non-fungible token, 1 if the token exists, else 0.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice this documentation overrides {IERC1155-balanceOf(address,uint256)}.
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return
     *  If `id` represents a collection (fungible token or non-fungible collection), the balance for this collection.
     *  If `id` represents a non-fungible token, 1 if the token is owned by `owner`, else 0.
     */
    // function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * @notice this documentation overrides {IERC1155-balanceOfBatch(address[],uint256[])}.
     * Retrieves the balances of `ids` owned by accounts `owners`.
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The accounts to retrieve the balances of.
     * @param ids The identifiers to retrieve the balances of.
     * @return An array of elements such as for each pair `id`/`owner`:
     *  If `id` represents a collection (fungible token or non-fungible collection), the balance for this collection.
     *  If `id` represents a non-fungible token, 1 if the token is owned by `owner`, else 0.
     */
    // function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @notice this documentation overrides its {IERC1155-safeTransferFrom(address,address,uint256,uint256,bytes)}.
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token and is not owned by `from`.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     uint256 value,
    //     bytes calldata data
    // ) external;

    /**
     * @notice this documentation overrides its {IERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token and is not owned by `from`.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible token and `from` has an insufficient balance.
     * @dev Reverts if one of `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Current tokens owner.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    // function safeBatchTransferFrom(
    //     address from,
    //     address to,
    //     uint256[] calldata ids,
    //     uint256[] calldata values,
    //     bytes calldata data
    // ) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, token receiver
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61) to accept the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     *  (i.e. 0xbc197c81) if to accept the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;






/**
 * @title ERC1155InventoryIdentifiersLib, a library to introspect inventory identifiers.
 * @dev With N=32, representing the Non-Fungible Collection mask length, identifiers are represented as follow:
 * (a) a Fungible Token:
 *     - most significant bit == 0
 * (b) a Non-Fungible Collection:
 *     - most significant bit == 1
 *     - (256-N) least significant bits == 0
 * (c) a Non-Fungible Token:
 *     - most significant bit == 1
 *     - (256-N) least significant bits != 0
 */
library ERC1155InventoryIdentifiersLib {
    // Non-fungible bit. If an id has this bit set, it is a non-fungible (either collection or token)
    uint256 internal constant _NF_BIT = 1 << 255;

    // Mask for non-fungible collection (including the nf bit)
    uint256 internal constant _NF_COLLECTION_MASK = uint256(type(uint32).max) << 224;
    uint256 internal constant _NF_TOKEN_MASK = ~_NF_COLLECTION_MASK;

    function isFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT == 0;
    }

    function isNonFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT != 0 && id & _NF_TOKEN_MASK != 0;
    }

    function getNonFungibleCollection(uint256 nftId) internal pure returns (uint256) {
        return nftId & _NF_COLLECTION_MASK;
    }
}

abstract contract ERC1155InventoryBase is IERC1155, IERC1155MetadataURI, IERC1155Inventory, IERC165, Context {
    using ERC1155InventoryIdentifiersLib for uint256;

    bytes4 private constant _ERC165_INTERFACE_ID = type(IERC165).interfaceId;
    bytes4 private constant _ERC1155_INTERFACE_ID = type(IERC1155).interfaceId;
    bytes4 private constant _ERC1155_METADATA_URI_INTERFACE_ID = type(IERC1155MetadataURI).interfaceId;
    bytes4 private constant _ERC1155_INVENTORY_INTERFACE_ID = type(IERC1155Inventory).interfaceId;

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // Burnt non-fungible token owner's magic value
    uint256 internal constant _BURNT_NFT_OWNER = 0xdead000000000000000000000000000000000000000000000000000000000000;

    /* owner => operator => approved */
    mapping(address => mapping(address => bool)) internal _operators;

    /* collection ID => owner => balance */
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    /* collection ID => supply */
    mapping(uint256 => uint256) internal _supplies;

    /* NFT ID => owner */
    mapping(uint256 => uint256) internal _owners;

    /* collection ID => creator */
    mapping(uint256 => address) internal _creators;

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == _ERC165_INTERFACE_ID ||
            interfaceId == _ERC1155_INTERFACE_ID ||
            interfaceId == _ERC1155_METADATA_URI_INTERFACE_ID ||
            interfaceId == _ERC1155_INVENTORY_INTERFACE_ID;
    }

    //================================== ERC1155 =======================================/

    /// @dev See {IERC1155-balanceOf(address,uint256)}.
    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        require(owner != address(0), "Inventory: zero address");

        if (id.isNonFungibleToken()) {
            return address(_owners[id]) == owner ? 1 : 0;
        }

        return _balances[id][owner];
    }

    /// @dev See {IERC1155-balanceOfBatch(address[],uint256[])}.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory) {
        require(owners.length == ids.length, "Inventory: inconsistent arrays");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i != owners.length; ++i) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    /// @dev See {IERC1155-setApprovalForAll(address,bool)}.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = _msgSender();
        require(operator != sender, "Inventory: self-approval");
        _operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See {IERC1155-isApprovedForAll(address,address)}.
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return _operators[tokenOwner][operator];
    }

    //================================== ERC1155Inventory =======================================/

    /// @dev See {IERC1155Inventory-isFungible(uint256)}.
    function isFungible(uint256 id) external pure virtual override returns (bool) {
        return id.isFungibleToken();
    }

    /// @dev See {IERC1155Inventory-collectionOf(uint256)}.
    function collectionOf(uint256 nftId) external pure virtual override returns (uint256) {
        require(nftId.isNonFungibleToken(), "Inventory: not an NFT");
        return nftId.getNonFungibleCollection();
    }

    /// @dev See {IERC1155Inventory-ownerOf(uint256)}.
    function ownerOf(uint256 nftId) public view virtual override returns (address) {
        address owner = address(_owners[nftId]);
        require(owner != address(0), "Inventory: non-existing NFT");
        return owner;
    }

    /// @dev See {IERC1155Inventory-totalSupply(uint256)}.
    function totalSupply(uint256 id) external view virtual override returns (uint256) {
        if (id.isNonFungibleToken()) {
            return address(_owners[id]) == address(0) ? 0 : 1;
        } else {
            return _supplies[id];
        }
    }

    //================================== ABI-level Internal Functions =======================================/

    /**
     * Creates a collection (optional).
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function _createCollection(uint256 collectionId) internal virtual {
        require(!collectionId.isNonFungibleToken(), "Inventory: not a collection");
        require(_creators[collectionId] == address(0), "Inventory: existing collection");
        _creators[collectionId] = _msgSender();
        emit CollectionCreated(collectionId, collectionId.isFungibleToken());
    }

    /// @dev See {IERC1155InventoryCreator-creator(uint256)}.
    function _creator(uint256 collectionId) internal view virtual returns (address) {
        require(!collectionId.isNonFungibleToken(), "Inventory: not a collection");
        return _creators[collectionId];
    }

    //================================== Internal Helper Functions =======================================/

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view virtual returns (bool) {
        return (from == sender) || _operators[from][sender];
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param id Identifier of the token transferred.
     * @param value Amount of token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(IERC1155TokenReceiver(to).onERC1155Received(_msgSender(), from, id, value, data) == _ERC1155_RECEIVED, "Inventory: transfer refused");
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155batchReceived} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous tokens owner.
     * @param to New tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(_msgSender(), from, ids, values, data) == _ERC1155_BATCH_RECEIVED,
            "Inventory: transfer refused"
        );
    }
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155721/[email protected]

pragma solidity 0.6.8;






/**
 * @title ERC1155721Inventory, an ERC1155Inventory with additional support for ERC721.
 */
abstract contract ERC1155721Inventory is IERC721, IERC721Metadata, IERC721BatchTransfer, ERC1155InventoryBase {
    using Address for address;

    bytes4 private constant _ERC165_INTERFACE_ID = type(IERC165).interfaceId;
    bytes4 private constant _ERC1155_TOKEN_RECEIVER_INTERFACE_ID = type(IERC1155TokenReceiver).interfaceId;
    bytes4 private constant _ERC721_INTERFACE_ID = type(IERC721).interfaceId;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = type(IERC721Metadata).interfaceId;

    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;

    uint256 internal constant _APPROVAL_BIT_TOKEN_OWNER_ = 1 << 160;

    /* owner => NFT balance */
    mapping(address => uint256) internal _nftBalances;

    /* NFT ID => operator */
    mapping(uint256 => address) internal _nftApprovals;

    /// @dev See {IERC165-supportsInterface(bytes4)}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == _ERC721_INTERFACE_ID || interfaceId == _ERC721_METADATA_INTERFACE_ID;
    }

    //===================================== ERC721 ==========================================/

    /// @dev See {IERC721-balanceOf(address)}.
    function balanceOf(address tokenOwner) external view virtual override returns (uint256) {
        require(tokenOwner != address(0), "Inventory: zero address");
        return _nftBalances[tokenOwner];
    }

    /// @dev See {IERC721-ownerOf(uint256)} and {IERC1155Inventory-ownerOf(uint256)}.
    function ownerOf(uint256 nftId) public view virtual override(IERC721, ERC1155InventoryBase) returns (address) {
        return ERC1155InventoryBase.ownerOf(nftId);
    }

    /// @dev See {IERC721-approve(address,uint256)}.
    function approve(address to, uint256 nftId) external virtual override {
        address tokenOwner = ownerOf(nftId);
        require(to != tokenOwner, "Inventory: self-approval");
        require(_isOperatable(tokenOwner, _msgSender()), "Inventory: non-approved sender");
        _owners[nftId] = uint256(tokenOwner) | _APPROVAL_BIT_TOKEN_OWNER_;
        _nftApprovals[nftId] = to;
        emit Approval(tokenOwner, to, nftId);
    }

    /// @dev See {IERC721-getApproved(uint256)}.
    function getApproved(uint256 nftId) external view virtual override returns (address) {
        uint256 tokenOwner = _owners[nftId];
        require(address(tokenOwner) != address(0), "Inventory: non-existing NFT");
        if (tokenOwner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
            return _nftApprovals[nftId];
        } else {
            return address(0);
        }
    }

    /// @dev See {IERC721-isApprovedForAll(address,address)} and {IERC1155-isApprovedForAll(address,address)}
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override(IERC721, ERC1155InventoryBase) returns (bool) {
        return ERC1155InventoryBase.isApprovedForAll(tokenOwner, operator);
    }

    /// @dev See {IERC721-isApprovedForAll(address,address)} and {IERC1155-isApprovedForAll(address,address)}
    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721, ERC1155InventoryBase) {
        return ERC1155InventoryBase.setApprovalForAll(operator, approved);
    }

    /**
     * Unsafely transfers a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721Inventory-transferFrom(address,address,uint256)}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            "",
            /* safe */
            false
        );
    }

    /**
     * Safely transfers a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721Inventory-safeTransferFrom(address,address,uint256)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            "",
            /* safe */
            true
        );
    }

    /**
     * Safely transfers a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721Inventory-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            data,
            /* safe */
            true
        );
    }

    /**
     * Unsafely transfers a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721BatchTransfer-batchTransferFrom(address,address,uint256[])}.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds
    ) public virtual override {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            values[i] = 1;
            _transferNFT(from, to, nftId, 1, operatable, true);
            emit Transfer(from, to, nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection();
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        if (nfCollectionId != 0) {
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
            _transferNFTUpdateBalances(from, to, length);
        }

        emit TransferBatch(_msgSender(), from, to, nftIds, values);
        if (to.isContract() && _isERC1155TokenReceiver(to)) {
            _callOnERC1155BatchReceived(from, to, nftIds, values, "");
        }
    }

    /// @dev See {IERC721Metadata-tokenURI(uint256)}.
    function tokenURI(uint256 nftId) external view virtual override returns (string memory) {
        require(address(_owners[nftId]) != address(0), "Inventory: non-existing NFT");
        return uri(nftId);
    }

    //================================== ERC1155 =======================================/

    /**
     * Safely transfers some token (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeTransferFrom(address,address,uint256,uint256,bytes)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        address sender = _msgSender();
        require(to != address(0), "Inventory: transfer to zero");
        bool operatable = _isOperatable(from, sender);

        if (id.isFungibleToken()) {
            _transferFungible(from, to, id, value, operatable);
        } else if (id.isNonFungibleToken()) {
            _transferNFT(from, to, id, value, operatable, false);
            emit Transfer(from, to, id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, to, id, value);
        if (to.isContract()) {
            _callOnERC1155Received(from, to, id, value, data);
        }
    }

    /**
     * Safely transfers a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        // internal function to avoid stack too deep error
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256) public view virtual override returns (string memory);

    //================================== ABI-level Internal Functions =======================================/

    /**
     * Safely or unsafely transfers some token (ERC721-compatible).
     * @dev For `safe` transfer, see {IERC1155721Inventory-transferFrom(address,address,uint256)}.
     * @dev For un`safe` transfer, see {IERC1155721Inventory-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data,
        bool safe
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        _transferNFT(from, to, nftId, 1, operatable, false);

        emit Transfer(from, to, nftId);
        emit TransferSingle(sender, from, to, nftId, 1);
        if (to.isContract()) {
            if (_isERC1155TokenReceiver(to)) {
                _callOnERC1155Received(from, to, nftId, 1, data);
            } else if (safe) {
                _callOnERC721Received(from, to, nftId, data);
            }
        }
    }

    /**
     * Safely transfers a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            if (id.isFungibleToken()) {
                _transferFungible(from, to, id, values[i], operatable);
            } else if (id.isNonFungibleToken()) {
                _transferNFT(from, to, id, values[i], operatable, true);
                emit Transfer(from, to, id);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
            nftsCount += nfCollectionCount;
            _transferNFTUpdateBalances(from, to, nftsCount);
        }

        emit TransferBatch(_msgSender(), from, to, ids, values);
        if (to.isContract()) {
            _callOnERC1155BatchReceived(from, to, ids, values, data);
        }
    }

    /**
     * Safely or unsafely mints some token (ERC721-compatible).
     * @dev For `safe` mint, see {IERC1155721InventoryMintable-mint(address,uint256)}.
     * @dev For un`safe` mint, see {IERC1155721InventoryMintable-safeMint(address,uint256,bytes)}.
     */
    function _mint(
        address to,
        uint256 nftId,
        bytes memory data,
        bool safe
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        require(nftId.isNonFungibleToken(), "Inventory: not an NFT");

        _mintNFT(to, nftId, 1, false);

        emit Transfer(address(0), to, nftId);
        emit TransferSingle(_msgSender(), address(0), to, nftId, 1);
        if (to.isContract()) {
            if (_isERC1155TokenReceiver(to)) {
                _callOnERC1155Received(address(0), to, nftId, 1, data);
            } else if (safe) {
                _callOnERC721Received(address(0), to, nftId, data);
            }
        }
    }

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256[])}.
     */
    function _batchMint(address to, uint256[] memory nftIds) internal {
        require(to != address(0), "Inventory: transfer to zero");

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            require(nftId.isNonFungibleToken(), "Inventory: not an NFT");
            values[i] = 1;
            _mintNFT(to, nftId, 1, true);
            emit Transfer(address(0), to, nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection();
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _balances[nfCollectionId][to] += nfCollectionCount;
                    _supplies[nfCollectionId] += nfCollectionCount;
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        _balances[nfCollectionId][to] += nfCollectionCount;
        _supplies[nfCollectionId] += nfCollectionCount;
        _nftBalances[to] += length;

        emit TransferBatch(_msgSender(), address(0), to, nftIds, values);
        if (to.isContract() && _isERC1155TokenReceiver(to)) {
            _callOnERC1155BatchReceived(address(0), to, nftIds, values, "");
        }
    }

    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function _safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = _msgSender();
        if (id.isFungibleToken()) {
            _mintFungible(to, id, value);
        } else if (id.isNonFungibleToken()) {
            _mintNFT(to, id, value, false);
            emit Transfer(address(0), to, id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, address(0), to, id, value);
        if (to.isContract()) {
            _callOnERC1155Received(address(0), to, id, value, data);
        }
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function _safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _mintFungible(to, id, value);
            } else if (id.isNonFungibleToken()) {
                _mintNFT(to, id, value, true);
                emit Transfer(address(0), to, id);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _balances[nfCollectionId][to] += nfCollectionCount;
                        _supplies[nfCollectionId] += nfCollectionCount;
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _balances[nfCollectionId][to] += nfCollectionCount;
            _supplies[nfCollectionId] += nfCollectionCount;
            nftsCount += nfCollectionCount;
            _nftBalances[to] += nftsCount;
        }

        emit TransferBatch(_msgSender(), address(0), to, ids, values);
        if (to.isContract()) {
            _callOnERC1155BatchReceived(address(0), to, ids, values, data);
        }
    }

    //============================== Internal Helper Functions =======================================/

    function _mintFungible(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 supply = _supplies[id];
        uint256 newSupply = supply + value;
        require(newSupply > supply, "Inventory: supply overflow");
        _supplies[id] = newSupply;
        // cannot overflow as supply cannot overflow
        _balances[id][to] += value;
    }

    function _mintNFT(
        address to,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(_owners[id] == 0, "Inventory: existing/burnt NFT");

        _owners[id] = uint256(to);

        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection();
            // it is virtually impossible that a non-fungible collection supply
            // overflows due to the cost of minting individual tokens
            ++_supplies[collectionId];
            ++_balances[collectionId][to];
            ++_nftBalances[to];
        }
    }

    function _transferFungible(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bool operatable
    ) internal {
        require(operatable, "Inventory: non-approved sender");
        require(value != 0, "Inventory: zero value");
        uint256 balance = _balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        if (from != to) {
            _balances[id][from] = balance - value;
            // cannot overflow as supply cannot overflow
            _balances[id][to] += value;
        }
    }

    function _transferNFT(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bool operatable,
        bool isBatch
    ) internal virtual {
        require(value == 1, "Inventory: wrong NFT value");
        uint256 owner = _owners[id];
        require(from == address(owner), "Inventory: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && _msgSender() == _nftApprovals[id], "Inventory: non-approved sender");
        }
        _owners[id] = uint256(to);
        if (!isBatch) {
            _transferNFTUpdateBalances(from, to, 1);
            _transferNFTUpdateCollection(from, to, id.getNonFungibleCollection(), 1);
        }
    }

    function _transferNFTUpdateBalances(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            _nftBalances[from] -= amount;
            //  cannot overflow as supply cannot overflow
            _nftBalances[to] += amount;
        }
    }

    function _transferNFTUpdateCollection(
        address from,
        address to,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            _balances[collectionId][from] -= amount;
            // cannot overflow as supply cannot overflow
            _balances[collectionId][to] += amount;
        }
    }

    ///////////////////////////////////// Receiver Calls Internal /////////////////////////////////////

    /**
     * Queries whether a contract implements ERC1155TokenReceiver.
     * @param _contract address of the contract.
     * @return wheter the given contract implements ERC1155TokenReceiver.
     */
    function _isERC1155TokenReceiver(address _contract) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory staticCallData = abi.encodeWithSelector(_ERC165_INTERFACE_ID, _ERC1155_TOKEN_RECEIVER_INTERFACE_ID);
        assembly {
            let call_ptr := add(0x20, staticCallData)
            let call_size := mload(staticCallData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    /**
     * Calls {IERC721Receiver-onERC721Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param nftId Identifier of the token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC721Received(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) internal {
        require(IERC721Receiver(to).onERC721Received(_msgSender(), from, nftId, data) == _ERC721_RECEIVED, "Inventory: transfer refused");
    }
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155721/[email protected]

pragma solidity 0.6.8;

/**
 * @title IERC1155721InventoryBurnable interface.
 * The function {IERC721Burnable-burnFrom(address,uint256)} is not provided as
 *  {IERC1155Burnable-burnFrom(address,uint256,uint256)} can be used instead.
 */
interface IERC1155721InventoryBurnable {
    /**
     * Burns some token (ERC1155-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address if `id` represents a non-fungible token.
     * @dev Emits an {IERC1155-TransferSingle} event to the zero address.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external;

    /**
     * Burns multiple tokens (ERC1155-compatible).
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each burnt non-fungible token.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    /**
     * Burns a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Current token owner.
     * @param nftIds Identifiers of the tokens to transfer.
     */
    function batchBurnFrom(address from, uint256[] calldata nftIds) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155721/[email protected]

pragma solidity 0.6.8;


/**
 * @title ERC1155721InventoryBurnable, a burnable ERC1155721Inventory.
 */
abstract contract ERC1155721InventoryBurnable is IERC1155721InventoryBurnable, ERC1155721Inventory {
    //============================== ERC1155721InventoryBurnable =======================================/

    /**
     * Burns some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryBurnable-burnFrom(address,uint256,uint256)}.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        if (id.isFungibleToken()) {
            _burnFungible(from, id, value, operatable);
        } else if (id.isNonFungibleToken()) {
            _burnNFT(from, id, value, operatable, false);
            emit Transfer(from, address(0), id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, address(0), id, value);
    }

    /**
     * Burns a batch of token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryBurnable-batchBurnFrom(address,uint256[],uint256[])}.
     */
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            if (id.isFungibleToken()) {
                _burnFungible(from, id, values[i], operatable);
            } else if (id.isNonFungibleToken()) {
                _burnNFT(from, id, values[i], operatable, true);
                emit Transfer(from, address(0), id);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
            nftsCount += nfCollectionCount;
            // cannot underflow as balance is verified through ownership
            _nftBalances[from] -= nftsCount;
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /**
     * Burns a batch of token (ERC721-compatible).
     * @dev See {IERC1155721InventoryBurnable-batchBurnFrom(address,uint256[])}.
     */
    function batchBurnFrom(address from, uint256[] memory nftIds) public virtual override {
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            values[i] = 1;
            _burnNFT(from, nftId, values[i], operatable, true);
            emit Transfer(from, address(0), nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection();
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        if (nfCollectionId != 0) {
            _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
            _nftBalances[from] -= length;
        }

        emit TransferBatch(sender, from, address(0), nftIds, values);
    }

    //============================== Internal Helper Functions =======================================/

    function _burnFungible(
        address from,
        uint256 id,
        uint256 value,
        bool operatable
    ) internal {
        require(value != 0, "Inventory: zero value");
        require(operatable, "Inventory: non-approved sender");
        uint256 balance = _balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        _balances[id][from] = balance - value;
        // Cannot underflow
        _supplies[id] -= value;
    }

    function _burnNFT(
        address from,
        uint256 id,
        uint256 value,
        bool operatable,
        bool isBatch
    ) internal virtual {
        require(value == 1, "Inventory: wrong NFT value");
        uint256 owner = _owners[id];
        require(from == address(owner), "Inventory: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && _msgSender() == _nftApprovals[id], "Inventory: non-approved sender");
        }
        _owners[id] = _BURNT_NFT_OWNER;

        if (!isBatch) {
            _burnNFTUpdateCollection(from, id.getNonFungibleCollection(), 1);

            // cannot underflow as balance is verified through NFT ownership
            --_nftBalances[from];
        }
    }

    function _burnNFTUpdateCollection(
        address from,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        // cannot underflow as balance is verified through NFT ownership
        _balances[collectionId][from] -= amount;
        _supplies[collectionId] -= amount;
    }
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155721/[email protected]

pragma solidity 0.6.8;

/**
 * @title IERC1155721InventoryMintable interface.
 * The function {IERC721Mintable-safeMint(address,uint256,bytes)} is not provided as
 *  {IERC1155Mintable-safeMint(address,uint256,uint256,bytes)} can be used instead.
 */
interface IERC1155721InventoryMintable {
    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `id` is not a token.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which has already been minted.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and there is an overflow of supply.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails or is refused.
     * @dev Emits an {IERC721-Transfer} event from the zero address if `id` represents a non-fungible token.
     * @dev Emits an {IERC1155-TransferSingle} event from the zero address.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to mint.
     * @param value Amount of token to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `ids` is not a token.
     * @dev Reverts if one of `ids` represents a non-fungible token and its paired value is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which has already been minted.
     * @dev Reverts if one of `ids` represents a fungible token and its paired value is 0.
     * @dev Reverts if one of `ids` represents a fungible token and there is an overflow of supply.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC721-Transfer} event from the zero address for each non-fungible token minted.
     * @dev Emits an {IERC1155-TransferBatch} event from the zero address.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to mint.
     * @param values Amounts of tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * Unsafely mints a Non-Fungible Token (ERC721-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `nftId` does not represent a non-fungible token.
     * @dev Reverts if `nftId` has already been minted.
     * @dev Emits an {IERC721-Transfer} event from the zero address.
     * @dev Emits an {IERC1155-TransferSingle} event from the zero address.
     * @dev If `to` is a contract and supports ERC1155TokenReceiver, calls {IERC1155TokenReceiver-onERC1155Received} with empty data.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to mint.
     */
    function mint(address to, uint256 nftId) external;

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` has already been minted.
     * @dev Emits an {IERC721-Transfer} event from the zero address for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event from the zero address.
     * @dev If `to` is a contract and supports ERC1155TokenReceiver, calls {IERC1155TokenReceiver-onERC1155BatchReceived} with empty data.
     * @param to Address of the new token owner.
     * @param nftIds Identifiers of the tokens to mint.
     */
    function batchMint(address to, uint256[] calldata nftIds) external;

    /**
     * Safely mints a token (ERC721-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `tokenId` has already ben minted.
     * @dev Reverts if `to` is a contract which does not implement IERC721Receiver or IERC1155TokenReceiver.
     * @dev Reverts if `to` is an IERC1155TokenReceiver or IERC721TokenReceiver contract which refuses the transfer.
     * @dev Emits an {IERC721-Transfer} event from the zero address.
     * @dev Emits an {IERC1155-TransferSingle} event from the zero address.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to mint.
     * @param data Optional data to pass along to the receiver call.
     */
    function safeMint(
        address to,
        uint256 nftId,
        bytes calldata data
    ) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Inventory, additional creator interface
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 */
interface IERC1155InventoryCreator {
    /**
     * Returns the creator of a collection, or the zero address if the collection has not been created.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @param collectionId Identifier of the collection.
     * @return The creator of a collection, or the zero address if the collection has not been created.
     */
    function creator(uint256 collectionId) external view returns (address);
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}


// File @animoca/ethereum-contracts-core_library/contracts/utils/types/[email protected]

pragma solidity 0.6.8;

library UInt256ToDecimalString {
    function toDecimalString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's String.toString() implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8b10cb38d8fedf34f2d89b0ed604f2dceb76d6a9/contracts/utils/Strings.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/metadata/[email protected]

pragma solidity 0.6.8;


contract BaseMetadataURI is Ownable {
    using UInt256ToDecimalString for uint256;

    event BaseMetadataURISet(string baseMetadataURI);

    string public baseMetadataURI;

    function setBaseMetadataURI(string calldata baseMetadataURI_) external onlyOwner {
        baseMetadataURI = baseMetadataURI_;
        emit BaseMetadataURISet(baseMetadataURI_);
    }

    function _uri(uint256 id) internal view virtual returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, id.toDecimalString()));
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @animoca/ethereum-contracts-core_library/contracts/access/[email protected]

pragma solidity 0.6.8;

/**
 * Contract module which allows derived contracts access control over token
 * minting operations.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMinter`, which can be applied to the minting functions of your contract.
 * Those functions will only be accessible to accounts with the minter role
 * once the modifer is put in place.
 */
contract MinterRole is AccessControl {
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    /**
     * Modifier to make a function callable only by accounts with the minter role.
     */
    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: not a Minter");
        _;
    }

    /**
     * Constructor.
     */
    constructor() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit MinterAdded(_msgSender());
    }

    /**
     * Validates whether or not the given account has been granted the minter role.
     * @param account The account to validate.
     * @return True if the account has been granted the minter role, false otherwise.
     */
    function isMinter(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * Grants the minter role to a non-minter.
     * @param account The account to grant the minter role to.
     */
    function addMinter(address account) public onlyMinter {
        require(!isMinter(account), "MinterRole: already Minter");
        grantRole(DEFAULT_ADMIN_ROLE, account);
        emit MinterAdded(account);
    }

    /**
     * Renounces the granted minter role.
     */
    function renounceMinter() public onlyMinter {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit MinterRemoved(_msgSender());
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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


// File contracts/solc-0.6/token/ERC1155721/REVVInventory.sol

pragma solidity ^0.6.8;







contract REVVInventory is
    Ownable,
    Pausable,
    ERC1155721InventoryBurnable,
    IERC1155721InventoryMintable,
    IERC1155InventoryCreator,
    BaseMetadataURI,
    MinterRole
{
    // solhint-disable-next-line const-name-snakecase
    string public constant override name = "REVV Inventory";
    // solhint-disable-next-line const-name-snakecase
    string public constant override symbol = "REVV-I";

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256 id) public view virtual override returns (string memory) {
        return _uri(id);
    }

    //================================== ERC1155InventoryCreator =======================================/

    /// @dev See {IERC1155InventoryCreator-creator(uint256)}.
    function creator(uint256 collectionId) external view override returns (address) {
        return _creator(collectionId);
    }

    // ===================================================================================================
    //                               Admin Public Functions
    // ===================================================================================================

    //================================== Pausable =======================================/

    function pause() external virtual {
        require(owner() == _msgSender(), "Inventory: not the owner");
        _pause();
    }

    function unpause() external virtual {
        require(owner() == _msgSender(), "Inventory: not the owner");
        _unpause();
    }

    //================================== ERC1155Inventory =======================================/

    /**
     * Creates a collection.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function createCollection(uint256 collectionId) external onlyOwner {
        _createCollection(collectionId);
    }

    //================================== ERC1155721InventoryMintable =======================================/

    /**
     * Unsafely mints a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256)}.
     */
    function mint(address to, uint256 nftId) public virtual override {
        require(isMinter(_msgSender()), "Inventory: not a minter");
        _mint(to, nftId, "", false);
    }

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256[])}.
     */
    function batchMint(address to, uint256[] memory nftIds) public virtual override {
        require(isMinter(_msgSender()), "Inventory: not a minter");
        _batchMint(to, nftIds);
    }

    /**
     * Safely mints a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        require(isMinter(_msgSender()), "Inventory: not a minter");
        _mint(to, nftId, data, true);
    }

    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        require(isMinter(_msgSender()), "Inventory: not a minter");
        _safeMint(to, id, value, data);
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        require(isMinter(_msgSender()), "Inventory: not a minter");
        _safeBatchMint(to, ids, values, data);
    }

    //================================== ERC721 =======================================/

    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.transferFrom(from, to, nftId);
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.batchTransferFrom(from, to, nftIds);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.safeTransferFrom(from, to, nftId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.safeTransferFrom(from, to, nftId, data);
    }

    function batchBurnFrom(address from, uint256[] memory nftIds) public virtual override {
        require(!paused(), "Inventory: paused");
        super.batchBurnFrom(from, nftIds);
    }

    //================================== ERC1155 =======================================/

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.safeTransferFrom(from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.burnFrom(from, id, value);
    }

    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(!paused(), "Inventory: paused");
        super.batchBurnFrom(from, ids, values);
    }
}