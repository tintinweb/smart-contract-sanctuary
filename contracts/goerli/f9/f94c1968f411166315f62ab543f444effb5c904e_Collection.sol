/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/*
 * Crypto stamp Collection Code and Prototype (Layer 2)
 * Actual code to be used via EIP1167 proxy for Collections of ERC721 and ERC1155 assets,
 * for example digital-physical collectible postage stamps
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Österreichische Post AG <post.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://crypto.post.at/

 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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

// File: contracts/CollectionNotificationI.sol

/*
 * Interface for Collection notification contracts.
 */


interface CollectionNotificationI is IERC165 {
    /*
     *     Calculate the interface ID for ERC 165:
     *
     *     bytes4(keccak256('onContractAdded(bool)')) == 0xdaf96bfb
     *     bytes4(keccak256('onContractRemoved()')) == 0x4664c35c
     *     bytes4(keccak256('onAssetAdded(address,uint256,uint8)')) == 0x60dec1cc
     *     bytes4(keccak256('onAssetRemoved(address,uint256,uint8)')) == 0xb5ed6ea2
     *
     *     => 0xdaf96bfb ^ 0x4664c35c ^ 0x60dec1cc ^ 0xb5ed6ea2 == 0x49ae07c9
     */

    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Notify about being added as a notification contract on the Collection
     * @dev The Collection smart contract calls this function when adding this contract
     * as a notification contract. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onContractAdded.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param initial This is being called in the initial constructor of the Collection
     * @return bytes4 `bytes4(keccak256("onContractAdded(bool)"))`
     */
    function onContractAdded(bool initial)
    external returns (bytes4);

    /**
     * @notice Notify about being removed as a notification contract on the Collection
     * @dev The Collection smart contract calls this function when removing this contract
     * as a notification contract. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onContractRemoved.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @return bytes4 `bytes4(keccak256("onContractRemoved()"))`
     */
    function onContractRemoved()
    external returns (bytes4);

    /**
     * @notice Notify about adding an asset to the Collection
     * @dev The Collection smart contract calls this function when adding any asset to
     * its internal tracking of assets. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onAssetAdded.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param tokenAddress The address of the token contract
     * @param tokenId The token identifier which is being transferred
     * @param tokenType The type of token this asset represents (can be ERC721 or ERC1155)
     * @return bytes4 `bytes4(keccak256("onAssetAdded(address,uint256,uint8)"))`
     */
    function onAssetAdded(address tokenAddress, uint256 tokenId, TokenType tokenType)
    external returns (bytes4);

    /**
     * @notice Notify about removing an asset from the Collection
     * @dev The Collection smart contract calls this function when removing any asset from
     * its internal tracking of assets. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onAssetAdded.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the Collection contract address is always the message sender.
     * @param tokenAddress The address of the token contract
     * @param tokenId The token identifier which is being transferred
     * @param tokenType The type of token this asset represents (can be ERC721 or ERC1155)
     * @return bytes4 `bytes4(keccak256("onAssetRemoved(address,uint256,uint8)"))`
     */
    function onAssetRemoved(address tokenAddress, uint256 tokenId, TokenType tokenType)
    external returns (bytes4);
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

// File: contracts/ENSSimpleRegistrarI.sol

/*
 * Interface for simple ENS Registrar
 * Exposing a registerAddr() signature modeled after the sample at
 * https://docs.ens.domains/contract-developer-guide/writing-a-registrar
 * together with the setAddr() from the AddrResolver.
 */

interface ENSSimpleRegistrarI {
    function registerAddr(bytes32 label, address target) external;
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

// File: contracts/Collection.sol

/*
 * Single Collection, which is a very lightweight contract that can be the owner of ERC721 tokens.
 */











contract Collection is ERC165, CollectionI {
    using Address for address;
    using Address for address payable;

    struct AssetInfo {
        address tokenAddress;
        uint256 tokenId;
    }

    bool public override isPrototype;

    BridgeDataI public bridgeData;
    CollectionsI public override collections;
    address public override notificationContract;

    AssetInfo[] public ownedAssets;
    mapping(bytes32 => uint256) public ownedAssetIndex; // for looking up an asset

    event BridgeDataChanged(address indexed previousBridgeData, address indexed newBridgeData);
    // TestTracker events - never emitted in this contract but helpful for running our tests.
    event SeenContractAdded(bool initial);
    event SeenContractRemoved();
    event SeenAssetAdded(address tokenAddress, uint256 tokenId, CollectionNotificationI.TokenType tokenType);
    event SeenAssetRemoved(address tokenAddress, uint256 tokenId, CollectionNotificationI.TokenType tokenType);

    modifier onlyOwner {
        require(!isPrototype && msg.sender == ownerAddress(), "Only Collection owner allowed.");
        _;
    }

    modifier requireActive {
        require(!isPrototype, "Needs an active contract, not the prototype.");
        _;
    }

    modifier onlyProtoTokenAssignmentControl() {
        require(isPrototype && msg.sender == bridgeData.getAddress("tokenAssignmentControl"), "prototype and tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyOwnerOrProtoTAC() {
        if (isPrototype) {
            require(msg.sender == bridgeData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        }
        else {
            require(msg.sender == ownerAddress(), "Collection owner required for this function.");
        }
        _;
    }

    constructor(address _bridgeDataAddress)
    {
        bridgeData = BridgeDataI(_bridgeDataAddress);
        require(address(bridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        // The initially deployed contract is just a prototype and code holder.
        // Clones will proxy their commends to this one and actually work.
        isPrototype = true;
    }

    function initialRegister(address _notificationContract,
                             string calldata _ensName,
                             string calldata _ensSubdomainName,
                             address _ensSubdomainRegistrarAddress,
                             address _ensReverseRegistrarAddress)
    external override
    requireActive
    {
        // Make sure that this function has not been called on this contract yet.
        require(address(collections) == address(0), "Cannot be initialized twice.");
        // Make sure that caller is an ERC721 contract itself.
        collections = CollectionsI(msg.sender);
        require(collections.supportsInterface(type(IERC721).interfaceId), "Creator needs to be ERC721!");
        if (_notificationContract != address(0)) {
            _transferNotificationContract(_notificationContract, true);
        }
        // Register ENS name if we did get a registrar.
        if (_ensSubdomainRegistrarAddress != address(0)) {
            _registerENS(_ensName, _ensSubdomainRegistrarAddress);
        }
        // We also set a reverse record via https://docs.ens.domains/contract-api-reference/reverseregistrar#set-name which needs a full name.
        if (_ensReverseRegistrarAddress != address(0)) {
            _registerReverseENS(_ensReverseRegistrarAddress, string(abi.encodePacked(_ensName, ".", _ensSubdomainName)));
        }
    }

    function setBridgeData(BridgeDataI _newBridgeData)
    external
    onlyProtoTokenAssignmentControl
    {
        require(address(_newBridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        emit BridgeDataChanged(address(bridgeData), address(_newBridgeData));
        bridgeData = _newBridgeData;
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC165, IERC165)
    returns (bool)
    {
        return interfaceId == type(CollectionI).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /*** Enable adjusting variables after deployment ***/

    function transferNotificationContract(address _newNotificationContract)
    public override
    onlyOwner
    {
        _transferNotificationContract(_newNotificationContract, false);
    }

    function _transferNotificationContract(address _newNotificationContract, bool _initial)
    private
    {
        if (notificationContract != _newNotificationContract) {
            emit NotificationContractTransferred(notificationContract, _newNotificationContract);
            if (notificationContract != address(0)) {
                require(
                    CollectionNotificationI(notificationContract).onContractRemoved() ==
                        CollectionNotificationI(notificationContract).onContractRemoved.selector,
                    "onContractRemoved failure"
                );
            }
            notificationContract = _newNotificationContract;
            if (notificationContract != address(0)) {
                require(IERC165(notificationContract).supportsInterface(type(CollectionNotificationI).interfaceId),
                        "Need to implement the actual collection notification interface!");
                require(
                    CollectionNotificationI(notificationContract).onContractAdded(_initial) ==
                        CollectionNotificationI(notificationContract).onContractAdded.selector,
                    "onContractAdded failure"
                );
            }
        }
    }

    /*** Deal with ERC721 and ERC1155 tokens we receive ***/

    // Override ERC721Receiver to record receiving of ERC721 tokens.
    // Also, comment out all params that are in the interface but not actually used, to quiet compiler warnings.
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 _tokenId, bytes memory /*_data*/)
    public override
    requireActive
    returns (bytes4)
    {
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being an ERC721 contract.
        require(IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId), "onERC721Received caller needs to implement ERC721!");
        // If we think we own this asset already, we don't need to add it, but this is still weird and should not happen.
        if (!ownsAsset(_tokenAddress, _tokenId)) {
            _addtoAssets(_tokenAddress, _tokenId, CollectionNotificationI.TokenType.ERC721);
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address /*_operator*/, address /*_from*/, uint256 _id, uint256 /*_value*/, bytes calldata /*_data*/)
    external override
    requireActive
    returns(bytes4)
    {
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being an ERC1155 contract.
        require(IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId), "onERC1155Received caller needs to implement ERC1155!");
        // If we think we own this asset already, we don't need to add it. On ERC115 this can happen easily.
        if (!ownsAsset(_tokenAddress, _id)) {
            _addtoAssets(_tokenAddress, _id, CollectionNotificationI.TokenType.ERC1155);
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address /*_operator*/, address /*_from*/, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata /*_data*/)
    external override
    requireActive
    returns(bytes4)
    {
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being an ERC1155 contract.
        require(IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId), "onERC1155BatchReceived caller needs to implement ERC1155!");
        uint256 batchcount = _ids.length;
        require(batchcount == _values.length, "Both ids and values need to be the same length.");
        for (uint256 i = 0; i < batchcount; i++) {
          if (!ownsAsset(_tokenAddress, _ids[i])) {
              _addtoAssets(_tokenAddress, _ids[i], CollectionNotificationI.TokenType.ERC1155);
          }
        }
        return this.onERC1155BatchReceived.selector;
    }

    /*** Special Collection functionality ***/

    // Get collection owner from ERC 721 parent (Collections factory)
    function ownerAddress()
    public view override
    requireActive
    returns (address)
    {
        return collections.collectionOwner(address(this));
    }

    function ownsAsset(address _tokenAddress, uint256 _tokenId)
    public view override
    requireActive
    returns(bool)
    {
        // Check if we do have this in our owned asset data.
        uint256 probableIndex = lookupIndex(_tokenAddress, _tokenId);
        if (probableIndex >= ownedAssets.length ||
            ownedAssets[probableIndex].tokenAddress != _tokenAddress ||
            ownedAssets[probableIndex].tokenId != _tokenId) {
            return false;
        }
        return true;
    }

    function ownedAssetsCount()
    public view override
    requireActive
    returns (uint256) {
        return ownedAssets.length;
    }

    function syncAssetOwnership(address _tokenAddress, uint256 _tokenId)
    public override
    requireActive
    {
        // Check if we do have this in our owned asset data.
        CollectionNotificationI.TokenType tokenType;
        bool hasOwnership;
        if (IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId)) { // ERC721
            hasOwnership = (IERC721(_tokenAddress).ownerOf(_tokenId) == address(this));
            tokenType = CollectionNotificationI.TokenType.ERC721;
        }
        else if (IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId)) { // ERC1155
            hasOwnership = (IERC1155(_tokenAddress).balanceOf(address(this), _tokenId) > 0);
            tokenType = CollectionNotificationI.TokenType.ERC1155;
        }
        else {
            revert("Token address has to be either ERC721 or ERC1155!");
        }
        bool isOwned = ownsAsset(_tokenAddress, _tokenId);
        if (isOwned && !hasOwnership) {
            // We think we own the asset but it moved on the contract, remove it.
            _removeFromAssets(_tokenAddress, _tokenId, tokenType);
        }
        else if (!isOwned && hasOwnership) {
            // The contract says we own it but we think we don't, add it.
            _addtoAssets(_tokenAddress, _tokenId, tokenType);
        }
    }

    // Internal helper to add item to assets - make sure we have tested for !ownsAsset before.
    function _addtoAssets(address _tokenAddress, uint256 _tokenId, CollectionNotificationI.TokenType _tokenType)
    internal
    {
        ownedAssets.push(AssetInfo(_tokenAddress, _tokenId));
        uint256 newIndex = ownedAssets.length - 1;
        ownedAssetIndex[getLookupHash(ownedAssets[newIndex])] = newIndex;
        emit AssetAdded(_tokenAddress, _tokenId);

        if (notificationContract != address(0)) {
            require(
                CollectionNotificationI(notificationContract).onAssetAdded(_tokenAddress, _tokenId, _tokenType) ==
                    CollectionNotificationI(notificationContract).onAssetAdded.selector,
                "onAssetAdded failure"
            );
        }
    }

    // Internal helper to remove item from assets - make sure we have tested for ownsAsset before.
    function _removeFromAssets(address _tokenAddress, uint256 _tokenId, CollectionNotificationI.TokenType _tokenType)
    internal
    {
        bytes32 lookupHash = getLookupHash(_tokenAddress, _tokenId);
        uint256 currentIndex = ownedAssetIndex[lookupHash];
        uint256 lastIndex = ownedAssets.length - 1;
        // When the asset to delete is the last one, the swap operation is unnecessary
        if (currentIndex != lastIndex) {
            AssetInfo storage lastAsset = ownedAssets[lastIndex];
            ownedAssets[currentIndex] = lastAsset; // Move the last asset to the slot of the to-delete asset
            ownedAssetIndex[getLookupHash(lastAsset)] = currentIndex; // Update the moved asset's index
        }
        // Deletes the contents at the last position of the array and re-sets the index.
        ownedAssets.pop();
        ownedAssetIndex[lookupHash] = 0;
        emit AssetRemoved(_tokenAddress, _tokenId);

        if (notificationContract != address(0)) {
            require(
                CollectionNotificationI(notificationContract).onAssetRemoved(_tokenAddress, _tokenId, _tokenType) ==
                    CollectionNotificationI(notificationContract).onAssetRemoved.selector,
                "onAssetRemoved failure"
            );
        }
    }

    /*** Provide functions to transfer owned assets away ***/

    function safeTransferTo(address _tokenAddress, uint256 _tokenId, address _to)
    external override
    {
        // Called function checks if it's the owner or an allowed account calling this.
        safeTransferTo(_tokenAddress, _tokenId, _to, 1);
    }

    function safeTransferTo(address _tokenAddress, uint256 _tokenId, address _to, uint256 _value)
    public override
    {
        require(collections.isApprovedOrOwnerOnCollection(msg.sender, address(this)), "Only an approved address or Collection owner allowed.");
        // In theory, we could enforce a syncAssetOwnership() here but we'd still need the require.
        require(ownsAsset(_tokenAddress, _tokenId), "We do not own this asset.");
        if (IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId)) { // ERC721
            IERC721(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId);
            // _removeFromAssets calls onAssetRemoved() which will check we already do not own it any more.
            _removeFromAssets(_tokenAddress, _tokenId, CollectionNotificationI.TokenType.ERC721);
        }
        else if (IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId)) { // ERC1155
            IERC1155 tokenContract = IERC1155(_tokenAddress);
            tokenContract.safeTransferFrom(address(this), _to, _tokenId, _value, "");
            // Only remove from assets if we now do not own any of this token after the transaction.
            if (tokenContract.balanceOf(address(this), _tokenId) == 0) {
                // _removeFromAssets calls onAssetRemoved() which will check we already do not own it any more.
                _removeFromAssets(_tokenAddress, _tokenId, CollectionNotificationI.TokenType.ERC1155);
            }
        }
        else {
            // We pretty much never can get here as we'll never mark anything owned that isn't ERC721 or ERC1155.
            revert("Token address has to be either ERC721 or ERC1155!");
        }
    }

    /*** Internal helpers to calculate the hash to use for the lookup mapping. ***/

    function getLookupHash(address _tokenAddress, uint256 _tokenId)
    private pure
    returns(bytes32)
    {
        return keccak256(abi.encodePacked(_tokenAddress, _tokenId));
    }

    function getLookupHash(AssetInfo memory _assetInfo)
    private pure
    returns(bytes32)
    {
        return getLookupHash(_assetInfo.tokenAddress, _assetInfo.tokenId);
    }

    function lookupIndex(address _tokenAddress, uint256 _tokenId)
    public view
    returns(uint256)
    {
        return ownedAssetIndex[getLookupHash(_tokenAddress, _tokenId)];
    }

    /*** Destroy Collection ***/

    // Destroys and burns an empty Collection.
    function destroy()
    external override
    onlyOwner
    {
        require(ownedAssets.length == 0, "Only empty collections can be destroyed.");
        address payable collectionOwner = payable(ownerAddress());
        collections.burn(collections.tokenIdForCollection(address(this)));
        emit CollectionDestroyed(msg.sender);
        selfdestruct(collectionOwner);
    }

    /*** Forward calls to external contracts ***/

    // Given a contract address and an already-encoded payload (with a function call etc.),
    // we call that contract with this payload, e.g. to trigger actions in the name of the collection.
    function externalCall(address payable _remoteAddress, bytes calldata _callPayload)
    external override payable
    onlyOwner
    {
        // Using methods from OpenZeppelin's Address library to bubble up exceptions with their messages.
        if (_callPayload.length > 0) {
            _remoteAddress.functionCallWithValue(_callPayload, msg.value);
        }
        else {
            _remoteAddress.sendValue(msg.value);
        }
    }

    /*** ENS registration access ***/

    // There is no standard for how to register a name with an ENS registrar.
    // Examples are:
    // .eth permanent registrar controller: https://docs.ens.domains/contract-api-reference/.eth-permanent-registrar/controller#register-name
    // .test registrar: https://docs.ens.domains/contract-api-reference/testregistrar#register-a-domain
    // Sample custom registrar: https://docs.ens.domains/contract-developer-guide/writing-a-registrar
    // Either the plain name or the label has can be required to call the function for registration, see
    // https://docs.ens.domains/contract-api-reference/name-processing for the description on name processing.
    // The registrar usually ends up calling setSubnodeOwner(bytes32 node, bytes32 label, address owner),
    // see https://github.com/ensdomains/ens/blob/master/contracts/ENS.sol for the ENS interface.
    // Because of all this, the function *only* works with a registrar with the same register() signature as
    // the sample custom FIFS registrar. Any more complicated registrations need to be done via externalCall().
    function registerENS(string memory _name, address _registrarAddress)
    public override
    onlyOwner
    {
        _registerENS(_name, _registrarAddress);
    }

    function _registerENS(string memory _name, address _registrarAddress)
    private
    {
        require(_registrarAddress != address(0), "Need valid registrar.");
        bytes32 label = keccak256(bytes(_name));
        ENSSimpleRegistrarI(_registrarAddress).registerAddr(label, address(this));
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // See https://docs.ens.domains/ens-deployments for address of ENS deployments, e.g. Etherscan can be used to look up that owner on those.
    // namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
    // Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
    // Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
    function registerReverseENS(address _reverseRegistrarAddress, string memory _name)
    public override
    onlyOwnerOrProtoTAC
    {
        _registerReverseENS(_reverseRegistrarAddress, _name);
    }

    function _registerReverseENS(address _reverseRegistrarAddress, string memory _name)
    private
    {
        require(_reverseRegistrarAddress != address(0), "Need valid reverse registrar.");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(address _foreignToken, address _to)
    external
    onlyOwnerOrProtoTAC
    {
        IERC20 erc20Token = IERC20(_foreignToken);
        erc20Token.transfer(_to, erc20Token.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    // NOTE: This is only for the prototype, actual instances manage NFTs with their normal functions.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyProtoTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}