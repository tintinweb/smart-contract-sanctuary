/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

/*
 * Crypto stamp 2 On-Chain Shop (Layer 2)
 * Ability to purchase pseudo-random digital-physical collectible postage stamps
 * and to redeem Crypto stamp 2 pre-sale vouchers in a similar manner,
 * all on a Layer 2 / side chain.
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

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

// File: contracts/MultiOracleRequestI.sol

/*
 * Interface for requests to the multi-rate oracle (for EUR/ETH and ERC20)
 * Copy this to projects that need to access the oracle.
 * This is a strict superset of OracleRequestI to ensure compatibility.
 * See rate-oracle project for implementation.
 */

interface MultiOracleRequestI {

    /**
     * @dev Number of wei per EUR
     */
    function EUR_WEI() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev Timestamp of when the last update for the ETH rate occurred
     */
    function lastUpdate() external view returns (uint256);

    /**
     * @dev Number of EUR per ETH (rounded down!)
     */
    function ETH_EUR() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev Number of EUR cent per ETH (rounded down!)
     */
    function ETH_EURCENT() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev True for ERC20 tokens that are supported by this oracle, false otherwise
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Number of token units per EUR
     */
    function eurRate(address tokenAddress) external view returns(uint256);

    /**
     * @dev Timestamp of when the last update for the specific ERC20 token rate occurred
     */
    function lastRateUpdate(address tokenAddress) external view returns (uint256);

    /**
     * @dev Emitted on rate update - using address(0) as tokenAddress for ETH updates
     */
    event RateUpdated(address indexed tokenAddress, uint256 indexed eurRate);

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

// File: contracts/ShippingManagerI.sol

/*
 * Interface for shipping manager.
 */

interface ShippingManagerI {

    enum ShippingStatus{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    /**
     * @dev Emitted when a token gets enabled (or disabled).
     */
    event TokenSupportSet(address indexed tokenAddress, bool enabled);

    /**
     * @dev Emitted when a shop authorization is set (or unset).
     */
    event ShopAuthorizationSet(address indexed tokenAddress, address indexed shopAddress, bool authorized);

    /**
     * @dev Emitted when the shipping status is set directly.
     */
    event ShippingStatusSet(address indexed tokenAddress, uint256 indexed tokenId, ShippingStatus shippingStatus);

    /**
     * @dev Emitted when the owner submits shipping data.
     */
    event ShippingSubmitted(address indexed owner, address[] tokenAddresses, uint256[][] tokenIds, string deliveryInfo);

    /**
     * @dev Emitted when the shipping service failed to ship the physical item and re-set the status.
     */
    event ShippingFailed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, string reason);

    /**
     * @dev Emitted when the shipping service confirms they can and will ship the physical item with the provided delivery information.
     */
    event ShippingConfirmed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);

    /**
     * @dev True for ERC-721 tokens that are supported by this shipping manager, false otherwise.
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Set the shipping status directly. Can only be called by an authorized on-chain shop.
     */
    function setTokenSupported(address tokenAddress, bool enabled) external;

    /**
     * @dev True if the given `_shopAddress` is authorized as a shop for the given `_tokenAddress`.
     */
    function authorizedShop(address tokenAddress, address shopAddress) external view returns(bool);

    /**
     * @dev Set the shipping status directly. Can only be called by an authorized on-chain shop.
     */
    function setShopAuthorized(address tokenAddress, address shopAddress, bool authorized) external;

    /**
     * @dev The current delivery status for the given asset.
     */
    function deliveryStatus(address tokenAddress, uint256 tokenId) external view returns(ShippingStatus);

    /**
     * @dev Set the shipping status directly. Can only be called by an authorized on-chain shop.
     */
    function setShippingStatus(address tokenAddress, uint256 tokenId, ShippingStatus newStatus) external;

    /**
     * @dev For token owner (after successful purchase): Request shipping.
     * _deliveryInfo is a postal address encrypted with a public key on the client side.
     */
    function shipToMe(address[] memory _tokenAddresses, string memory _deliveryInfo, uint256[][] memory _tokenIds) external;

    /**
     * @dev For shipping service: Mark shipping as completed/confirmed.
     */
    function confirmShipping(address[] memory _tokenAddresses, uint256[][] memory _tokenIds) external;

    /**
     * @dev For shipping service: Mark shipping as failed/rejected (due to invalid address).
     */
    function rejectShipping(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, string memory _reason) external;

}

// File: contracts/CS2PropertiesI.sol

/*
 * Interface for CS2 properties.
 */

interface CS2PropertiesI {

    enum AssetType {
        Honeybadger,
        Llama,
        Panda,
        Doge
    }

    enum Colors {
        Black,
        Green,
        Blue,
        Yellow,
        Red
    }

    function getType(uint256 tokenId) external view returns (AssetType);
    function getColor(uint256 tokenId) external view returns (Colors);

}

// File: contracts/CS2OnChainShopL2.sol

/*
 * Shop and presale redemption for CS2 on L2.
 */

contract CS2OnChainShopL2 is ERC165, IERC1155Receiver {
    using Address for address payable;

    BridgeDataI public bridgeData;

    IERC721Enumerable internal BridgedCS2;
    IERC1155 internal BridgedCS2Presale;
    ShippingManagerI internal shippingManager;

    uint256 public priceEurCent;

    uint256 public openTimestamp = 0;

    struct SoldInfo {
        address recipient;
        uint256 blocknumber;
        uint256 tokenId;
        bool presale;
        CS2PropertiesI.AssetType aType;
    }

    SoldInfo[] public soldSequence;
    uint256 public lastAssignedSequence;

    address[8] public tokenPools; // Pools for every AssetType as well as "normal" OCS and presale.
    uint256[8] public unassignedInPool;

    event BridgeDataChanged(address indexed previousBridgeData, address indexed newBridgeData);
    event PriceChanged(uint256 previousPriceEurCent, uint256 newPriceEurCent);
    event ShopOpened(uint256 openTimestamp);
    event ShopClosed();
    event AssetSold(address indexed buyer, address recipient, bool indexed presale, CS2PropertiesI.AssetType indexed aType, uint256 sequenceNumber, uint256 priceWei);
    event AssetAssigned(address indexed recipient, uint256 indexed tokenId, uint256 sequenceNumber);
    // ERC721 event - never emitted in this contract but helpful for running our tests.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // ERC1155 event - never emitted in this contract but helpful for running our tests.
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    constructor(address _bridgeDataAddress, address _shippingManagerAddress, address _bridgedCS2Address, address _bridgedCS2PresaleAddress, uint256 _priceEurCent, address[] memory _tokenPools)
    {
        bridgeData = BridgeDataI(_bridgeDataAddress);
        require(address(bridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        shippingManager = ShippingManagerI(_shippingManagerAddress);
        require(address(shippingManager) != address(0x0), "You need to provide an actual shipping manager contract.");
        BridgedCS2 = IERC721Enumerable(_bridgedCS2Address);
        require(address(BridgedCS2) != address(0x0), "You need to provide an actual bridged Cryptostamp 2 contract.");
        BridgedCS2Presale = IERC1155(_bridgedCS2PresaleAddress);
        require(address(BridgedCS2Presale) != address(0x0), "You need to provide an actual bridged Cryptostamp 2 Presale contract.");
        priceEurCent = _priceEurCent;
        require(priceEurCent > 0, "You need to provide a non-zero price.");
        uint256 poolnum = tokenPools.length;
        require(_tokenPools.length == poolnum, "Need correct amount of token pool addresses.");
        for (uint256 i = 0; i < poolnum; i++) {
            tokenPools[i] = _tokenPools[i];
        }
    }

    modifier onlyShopControl()
    {
        require(msg.sender == bridgeData.getAddress("shopControl"), "shopControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == bridgeData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier requireOpen() {
        require(isOpen() == true, "This call only works when the shop is open.");
        _;
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC165, IERC165)
    returns (bool)
    {
        return interfaceId == type(IERC1155Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /*** Enable adjusting variables after deployment ***/

    function setBridgeData(BridgeDataI _newBridgeData)
    external
    onlyShopControl
    {
        require(address(_newBridgeData) != address(0x0), "You need to provide an actual bridge data contract.");
        emit BridgeDataChanged(address(bridgeData), address(_newBridgeData));
        bridgeData = _newBridgeData;
    }

    /*** Manage price setting ***/

    function setPrice(uint256 _newPriceEurCent)
    public
    onlyShopControl
    {
        require(_newPriceEurCent > 0, "You need to provide a non-zero price.");
        emit PriceChanged(priceEurCent, _newPriceEurCent);
        priceEurCent = _newPriceEurCent;
    }

    // Calculate current asset price in "wei" (subunits of the native chain currency).
    // Note: Price in EUR cent is available from public var getter priceEurCent().
    function priceWei()
    public view
    returns (uint256)
    {
        return priceEurCent * MultiOracleRequestI(bridgeData.getAddress("Oracle")).eurRate(address(0)) / 100;
    }

    /*** Manage opening/closing shop ***/

    // Return true if shop is currently open for purchases.
    // This can have additional conditions to just the variable, e.g. actually having items to sell.
    function isOpen()
    public view
    returns (bool)
    {
        return openTimestamp > 0 && block.timestamp >= openTimestamp;
    }

    function openShop(uint256 _timestamp)
    public
    onlyShopControl
    {
        openTimestamp = _timestamp;
        emit ShopOpened(openTimestamp);
    }

    function closeShop()
    public
    onlyShopControl
    {
        openTimestamp = 0;
        emit ShopClosed();
    }

    /*** Actual shop functionality ***/

    // Get the index of the pool for presale or normal OCS assets of the given type.
    function getPoolIndex(bool _presale, CS2PropertiesI.AssetType _type)
    public pure
    returns (uint256)
    {
        return (_presale ? 4 : 0) + uint256(_type);
    }

    // Returns the amount of assets that are still available for sale.
    function getPool(bool _presale, CS2PropertiesI.AssetType _type)
    public view
    returns (address)
    {
        return tokenPools[getPoolIndex(_presale, _type)];
    }

    // Returns the amount of assets of that type still available for sale.
    function availableForSale(bool _presale, CS2PropertiesI.AssetType _type)
    public view
    returns (uint256)
    {
        return BridgedCS2.balanceOf(getPool(_presale, _type)) - unassignedInPool[getPoolIndex(_presale, _type)];
    }

    // Returns true if the asset of the given type is sold out.
    function isSoldOut(bool _presale, CS2PropertiesI.AssetType _type)
    public view
    returns (bool)
    {
        return availableForSale(_presale, _type) == 0;
    }

    // Buy assets. The number of assets is determined from the amount of ETH sent.
    function acceptAndBuy(CS2PropertiesI.AssetType _type, bool _acceptTermsCryptoPostAt, string calldata _acceptanceText)
    external payable
    requireOpen
    {
        buyFor(msg.sender, _type, _acceptTermsCryptoPostAt, _acceptanceText);
    }

    // Buy assets. The number of assets is determined from the amount of ETH sent.
    function buyFor(address _recipient, CS2PropertiesI.AssetType _type, bool _acceptTermsCryptoPostAt, string calldata _acceptanceText)
    public payable
    requireOpen
    {
        require(_acceptTermsCryptoPostAt, "You need to accept the terms.");
        require(bytes(_acceptanceText).length > 0, "You need to send the acceptance text.");
        bool isPresale = false;
        uint256 availAmount = availableForSale(isPresale, _type);
        require(availAmount > 0, "The requested asset is sold out.");
        uint256 curPriceWei = priceWei();
        require(msg.value >= curPriceWei, "Send enough currency to pay at least one item.");
        // Determine amount of assets to buy from payment value (algorithm rounds down).
        uint256 assetCount = msg.value / curPriceWei;
        // Don't allow buying more assets than available of this type.
        if (assetCount > availAmount) {
            assetCount = availAmount;
        }
        // Determine actual price of rounded-down count.
        uint256 payAmount = assetCount * curPriceWei;
        storeSequences(_recipient, _type, assetCount, isPresale, curPriceWei);
        // Assign a max of one asset/token more than we purchased.
        assignPurchasedAssets(assetCount + 1);
        // Transfer the actual payment amount to the beneficiary.
        // Our own account so no reentrancy here but put at end to be sure.
        payable(bridgeData.getAddress("beneficiary")).sendValue(payAmount);
        // Send back change money. Do this last. Also send to original sender, not to recipient.
        if (msg.value > payAmount) {
            payable(msg.sender).sendValue(msg.value - payAmount);
        }
    }

    // Redeem presale vouchers for assets.
    // The number of assets as well as the recipient are explicitly given.
    // This will fail when the full amount cannot be provided or the buyer has too few vouchers.
    // The recipient does not need to match the buyer, so the assets can be sent elsewhere (e.g. into a collection).
    function redeemVoucher(CS2PropertiesI.AssetType _type, uint256 _amount, address _recipient, bool _acceptTermsCryptoPostAt, string calldata _acceptanceText)
    public
    requireOpen
    {
        require(_acceptTermsCryptoPostAt, "You need to accept the terms.");
        require(bytes(_acceptanceText).length > 0, "You need to send the acceptance text.");
        bool isPresale = true;
        uint256 CS2PresaleId = uint256(_type);
        uint256 availAmount = availableForSale(isPresale, _type);
        require(_amount <= availAmount, "Not enough assets available to redeem that amount.");
        require(BridgedCS2Presale.balanceOf(msg.sender, CS2PresaleId) >= _amount, "You need to own enough presale vouchers to redeem the specified amount.");
        // Instead of actually redeeming, transfer the "vouchers" to this contract.
        BridgedCS2Presale.safeTransferFrom(msg.sender, address(this), CS2PresaleId, _amount, bytes(""));
        storeSequences(_recipient, _type, _amount, isPresale, 0);
        // Assign a max of one asset/token more than we redeemed.
        assignPurchasedAssets(_amount + 1);
    }

    function storeSequences(address _recipient, CS2PropertiesI.AssetType _type, uint256 _amount, bool _presale, uint256 _priceWei)
    internal
    {
        for (uint256 i = 0; i < _amount; i++) {
            // Assign a sequence number and store block and owner for it.
            soldSequence.push(SoldInfo(_recipient, block.number, 0, _presale, _type));
            emit AssetSold(msg.sender, _recipient, _presale, _type, soldSequence.length, _priceWei);
        }
        unassignedInPool[getPoolIndex(_presale, _type)] += _amount;
    }

    function onERC1155Received(address _operator, address /*_from*/, uint256 /*_id*/, uint256 /*_value*/, bytes calldata /*_data*/)
    external view override
    returns(bytes4)
    {
        require(_operator == address(this), "Can only receive tokens via redemption mechanism!");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address _operator, address /*_from*/, uint256[] calldata /*_ids*/, uint256[] calldata /*_values*/, bytes calldata /*_data*/)
    external view override
    returns(bytes4)
    {
        require(_operator == address(this), "Can only receive tokens via redemption mechanism!");
        return this.onERC1155BatchReceived.selector;
    }

    /*** Deal with assigning (and retrieving) assets for sequences ***/

    // Get total amount of not-yet-assigned assets
    function getUnassignedAssetCount()
    public view
    returns (uint256)
    {
        return soldSequence.length - lastAssignedSequence;
    }

    // Get total amount of sold assets
    function getSoldCount()
    public view
    returns (uint256)
    {
        return soldSequence.length;
    }

    // Get the token ID for any sold asset with the given sequence number.
    function getSoldTokenId(uint256 _sequenceNumber)
    public view
    returns (uint256)
    {
        require(_sequenceNumber <= lastAssignedSequence, "Token IDs are only assigned for sequences that have been assigned already.");
        uint256 seqIdx = _sequenceNumber - 1;
        return soldSequence[seqIdx].tokenId;
    }

    // Assign _maxCount asset (or less if less are unassigned)
    function assignPurchasedAssets(uint256 _maxCount)
    public
    {
        for (uint256 i = 0; i < _maxCount; i++) {
            if (lastAssignedSequence < soldSequence.length) {
                _assignNextPurchasedAsset(false);
            }
        }
    }

    function assignNextPurchasedAssset()
    public
    {
        _assignNextPurchasedAsset(true);
    }

    function _assignNextPurchasedAsset(bool revertForSameBlock)
    internal
    {
        uint256 nextSequenceNumber = lastAssignedSequence + 1;
        // Find the stamp to assign and transfer it.
        uint256 seqIdx = nextSequenceNumber - 1;
        if (soldSequence[seqIdx].blocknumber < block.number) {
            uint256 tokenId = _getNextUnassignedTokenId(seqIdx);
            soldSequence[seqIdx].tokenId = tokenId;
            emit AssetAssigned(soldSequence[seqIdx].recipient, tokenId, nextSequenceNumber);
            // If retrieval is caught up, do retrieval right away.
            uint256 poolIndex = getPoolIndex(soldSequence[seqIdx].presale, soldSequence[seqIdx].aType);
            // NOTE: We know BridgedCS2 is no contract that causes re-entrancy as it's our code.
            BridgedCS2.safeTransferFrom(tokenPools[poolIndex], soldSequence[seqIdx].recipient, tokenId);
            unassignedInPool[poolIndex] -= 1;
            // Set delivery status for newly sold asset, and update lastAssigned.
            shippingManager.setShippingStatus(address(BridgedCS2), tokenId, ShippingManagerI.ShippingStatus.Sold);
            lastAssignedSequence = nextSequenceNumber;
        }
        else {
            if (revertForSameBlock) {
                revert("Cannot assign assets in the same block.");
            }
        }
    }

    // Get the token ID for the next asset to assign, via a semi-random mechanism.
    function _getNextUnassignedTokenId(uint256 seqIdx)
    internal view
    returns (uint256)
    {
        require(seqIdx == lastAssignedSequence, "Mismatch of next sequence index to assign"); // last + 1 is next seqNo, seqIdx is seqNo - 1
        uint256 poolIndex = getPoolIndex(soldSequence[seqIdx].presale, soldSequence[seqIdx].aType);
        uint256 poolSize = BridgedCS2.balanceOf(tokenPools[poolIndex]);
        uint256 slotIndex = _getSemiRandomNumber(soldSequence[seqIdx].blocknumber, seqIdx, poolSize);
        uint256 tokenId = BridgedCS2.tokenOfOwnerByIndex(tokenPools[poolIndex], slotIndex);
        return tokenId;
    }

    // Get a semi-random number based on the block hash of the given block number, a salt and an exclusive max value.
    function _getSemiRandomNumber(uint256 _blockNumber, uint256 _salt, uint256 _maxValueExclusive)
    internal view
    returns (uint256)
    {
        // Get block hash. As this only works for the last 256 blocks, fall back to the empty keccak256 hash to keep getting stable results.
        bytes32 bhash;
        if (_blockNumber == block.number) {
          revert("Wait for next block please.");
        }
        else if (block.number < 256 || _blockNumber >= block.number - 256) {
          bhash = blockhash(_blockNumber);
        }
        else {
          bhash = keccak256("");
        }
        return uint256(keccak256(abi.encodePacked(_salt, bhash))) % _maxValueExclusive;
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
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}