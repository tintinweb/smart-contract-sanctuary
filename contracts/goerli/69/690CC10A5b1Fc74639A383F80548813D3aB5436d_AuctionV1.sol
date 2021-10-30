/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

/*
 * Auction V1 Prototype for cryptoWine project
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Cryptoagri GmbH <cryptowine.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://cryptowine.at/
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: contracts/AgriDataI.sol

/*
 * Interface for data storage of the cryptoAgri system.
 */

interface AgriDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
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

// File: contracts/ERC721SignedTransferI.sol

/*
 * Interface for ERC721 Signed Transfers.
 */

/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface ERC721SignedTransferI is IERC721 {

    /**
     * @dev Emitted when a signed transfer is being executed.
     */
    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedTransfer(uint256 tokenId, address to, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedTransferWithOperator(uint256 tokenId, address to, bytes memory signature) external;

}

// File: contracts/ERC721ExistsI.sol

/*
 * Interface for an ERC721 compliant contract with an exists() function.
 */

/**
 * @dev ERC721 compliant contract with an exists() function.
 */
interface ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) external view returns (bool);

}

// File: contracts/CryptoWineTokenI.sol

/*
 * Interface for functions of the cryptoWine token that need to be accessed by
 * other contracts.
 */

interface CryptoWineTokenI is IERC721Enumerable, ERC721ExistsI, ERC721SignedTransferI {

    /**
     * @dev The base URI of the token.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev The storage fee per year in EUR cent.
     */
    function storageFeeYearlyEurCent() external view returns (uint256);

    /**
     * @dev The wine ID for a specific asset / token ID.
     */
    function wineID(uint256 tokenId) external view returns (uint256);

    /**
     * @dev The deposit in EUR cent that is available for storage, shipping, etc.
     */
    function depositEurCent(uint256 tokenId) external view returns (uint256);

    /**
     * @dev The start timestamp (unix format, seconds) for storage.
     */
    function storageStart(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Start storage for a specific asset / token ID, with an initial deposit.
     */
    function startStorage(uint256 tokenId, uint256 depositEurCent) external;

    /**
     * @dev The timestamp (unix format, seconds) until which that storage is paid with the deposit.
     */
    function storageValidUntil(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Prolong storage for specific assets / token IDs by depositing more funds via native currency.
     */
    function depositStorageFunds(uint256[] memory _tokenIds, uint256[] memory _amounts) external payable;

    /**
     * @dev Prolong storage for specific assets / token IDs by depositing more funds via an ERC20 token.
     */
    function depositStorageFundTokens(address _payTokenAddress, uint256[] memory _tokenIds, uint256[] memory _payTokenAmounts) external;

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
     * @dev Emitted when an authorizer is set (or unset).
     */
    event AuthorizerSet(address indexed tokenAddress, address indexed authorizerAddress, bool enabled);

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
    event ShippingSubmitted(address indexed owner, address[] tokenAddresses, uint256[][] tokenIds, uint256 shippingId, uint256 shippingPaymentWei);

    /**
     * @dev Emitted when the shipping service failed to ship the physical item and re-set the status.
     */
    event ShippingFailed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, string reason);

    /**
     * @dev Emitted when the shipping service confirms they can and will ship the physical item with the provided delivery information.
     */
    event ShippingConfirmed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);

    /**
     * @dev True if the given `authorizerAddress` can authorize shops for the given `tokenAddress`.
     */
    function isAuthorizer(address tokenAddress, address authorizerAddress) external view returns(bool);

    /**
     * @dev Set an address as being able to authorize shops for the given token.
     */
    function setAuthorizer(address tokenAddress, address authorizerAddress, bool enabled) external;

    /**
     * @dev True for ERC-721 tokens that are supported by this shipping manager, false otherwise.
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Set a token as (un)supported.
     */
    function setTokenSupported(address tokenAddress, bool enabled) external;

    /**
     * @dev True if the given `shopAddress` is authorized as a shop for the given `tokenAddress`.
     */
    function authorizedShop(address tokenAddress, address shopAddress) external view returns(bool);

    /**
     * @dev Set a shop as (un)authorized for a specific token. When enabling, also sets token as supported if it is not yet.
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
     * To make sure the correct amount of currency is being paid here (or has already been paid via other means),
     * a signature from shippingControl is required.
     */
    function shipToMe(address[] memory tokenAddresses, uint256[][] memory tokenIds, uint256 shippingId, bytes memory signature) external payable;

    /**
     * @dev For shipping service: Mark shipping as completed/confirmed.
     */
    function confirmShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds) external;

    /**
     * @dev For shipping service: Mark shipping as failed/rejected (due to invalid address).
     */
    function rejectShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds, string memory reason) external;

}

// File: contracts/TaxRegionsI.sol

/*
 * Interface for tax regions list.
 */

interface TaxRegionsI {

    /**
     * @dev Return the VAT permil rate for a given tax region.
     */
    function vatPermilForRegionId(string memory taxRegionIdentifier) external view returns(uint256);

    /**
     * @dev Return the VAT permil rate for a given tax region.
     */
    function vatPermilForRegionHash(bytes32 taxRegionHash) external view returns(uint256);

    /**
     * @dev Get Region Hash for a region identifier string.
     */
    function getRegionHash(string memory taxRegionIdentifier) external view returns(bytes32);

}

// File: contracts/AuctionV1FactoryI.sol

/*
 * Interface for cryptoWine auctions V1 Factory.
 */

interface AuctionV1FactoryI {

    /**
     * @dev Emitted when a new auction is created.
     */
    event NewAuction(address auctionAddress);

    /**
     * @dev The agri data contract used with the tokens.
     */
    function agriData() external view returns (AgriDataI);

}

// File: contracts/AuctionV1DeployI.sol

/*
 * cryptoWine Auction V1 deployment interface
 */

interface AuctionV1DeployI {

    function initialRegister() external;

}

// File: contracts/AuctionV1.sol

/*
 * cryptoWine Auction V1 contract, can own currency and wine NFTs.
 *
 * Preparation steps:
 *   1. Create new auction via the factory.
 *   2. Transfer NFTs to auction
 *   3. start auction (no NFTs accepted after this!)
 */

contract AuctionV1 is ERC165, AuctionV1DeployI, ReentrancyGuard {
    using Address for address payable;
    using Address for address;

    bool public isPrototype;

    AgriDataI public agriData;

    uint256 internal _eurRate;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public minBidEurCent;

    uint256 public bidCount;
    address public constant eolGuard = address(1);
    address public highestBidder;
    address public lastTokenDistributionBidder;
    address public lastFundsDistributionBidder;

    mapping(address => address) public nextLowerBidder;
    mapping(address => uint256) public bidAssetAmount;
    mapping(address => uint256) public bidNetWeiPerAsset;
    mapping(address => uint256) public bidVATPermil;
    mapping(address => uint256) public bidTimestamp;
    mapping(address => uint256) public bidTotalWei;
    mapping(address => uint256) public bidDistributedAmount;
    mapping(address => bool) public bidDistributedFunds;

    event AuctionStartSet(uint256 startTimestamp, uint256 endTimestamp, uint256 minBidEurCent);
    event AuctionEndSet(uint256 endTimestamp);
    event MinBidSet(uint256 minBidEurCent);
    event NewBid(address indexed bidder, uint256 amount, uint256 netWeiPerAsset, uint256 totalBidWei, string taxRegionIdentifier);
    event BidChanged(address indexed bidder, uint256 newTotalAmount, uint256 netWeiPerAsset, uint256 totalBidWei);
    event AssetSold(address indexed buyer, uint256 indexed tokenId);
    event DistributionFailed(address indexed buyer, uint256 indexed tokenId);
    event PaymentForwarded(address indexed recipient, uint256 paymentAmount, uint256 amountAssets, uint256 netWeiPerAsset, uint256 vatPermil);
    event PaymentRefunded(address indexed recipient, uint256 refundAmount);

    modifier requireActive {
        require(!isPrototype, "Needs an active contract, not the prototype.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == agriData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == agriData.getAddress("auctionCreateControl"), "Admin key required for this function.");
        _;
    }

    modifier requireStarted() {
        require(startTimestamp > 0 && startTimestamp <= block.timestamp, "Auction has to be started.");
       _;
    }

    modifier requireNotFinished() {
        require(endTimestamp > block.timestamp, "Auction cannot be finished.");
       _;
    }

    modifier requireFinished() {
        require(endTimestamp > 0 && endTimestamp <= block.timestamp, "Auction has to be finished.");
       _;
    }

    constructor(address _agriDataAddress)
    {
        agriData = AgriDataI(_agriDataAddress);
        require(address(agriData) != address(0x0), "You need to provide an actual agri data contract.");
        // The initially deployed contract is just a prototype and code holder.
        // Clones will proxy their commends to this one and actually work.
        isPrototype = true;
    }

    function initialRegister()
    external
    requireActive
    {
        // Make sure that this function has not been called on this contract yet.
        require(address(agriData) == address(0), "Cannot be initialized twice.");
        agriData = AuctionV1FactoryI(msg.sender).agriData();
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override
    returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /*** Get contracts with their ABI ***/

    function oracle()
    public view
    returns (MultiOracleRequestI)
    {
        return MultiOracleRequestI(agriData.getAddress("Oracle"));
    }

    function shippingManager()
    public view
    returns (ShippingManagerI)
    {
        return ShippingManagerI(agriData.getAddress("ShippingManager"));
    }

    function taxRegions()
    public view
    returns (TaxRegionsI)
    {
        return TaxRegionsI(agriData.getAddress("TaxRegions"));
    }

    function assetToken()
    public view
    returns (CryptoWineTokenI)
    {
        return CryptoWineTokenI(agriData.getAddress("CryptoWineToken"));
    }

    /*** Deal with ERC721 tokens we receive ***/

    // Override ERC721Receiver to record receiving of ERC721 tokens.
    // Also, comment out all params that are in the interface but not actually used, to quiet compiler warnings.
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 /*_tokenId*/, bytes memory /*_data*/)
    public view
    requireActive
    returns (bytes4)
    {
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being from the contract we need.
        require(_tokenAddress == address(assetToken()), "Actually needs to be a correct token!");
        require(startTimestamp == 0 || startTimestamp > block.timestamp, "Auction cannot have started yet.");
        return this.onERC721Received.selector;
    }

    /*** Auction-realted properties / view functions ***/

    // Get EUR rate in wei - dynamic until first bid comes in, fixed after that point.
    function eurRate()
    public view
    requireActive
    returns (uint256)
    {
        if (_eurRate > 0) {
            return _eurRate;
        }
        return oracle().eurRate(address(0));
    }

    // Calculate current minimal bid in "wei" (subunits of the native chain currency).
    function minBidWei()
    public view
    requireActive
    returns (uint256)
    {
        return minBidEurCent * eurRate() / 100;
    }

    // The price that asset have been sold for, is only determined once all tokens have been distributed.
    function netSalePriceWei()
    public view
    requireFinished
    returns (uint256)
    {
        require(assetToken().balanceOf(address(this)) == 0, "Price is only known once tokens have been distributed");
        if (lastTokenDistributionBidder == eolGuard) {
            // Distribution ran into the end of the bids before all tokens were used up.
            // In this case, the minimum bid price is the one paid for all tokens.
            return minBidWei();
        }
        return bidNetWeiPerAsset[lastTokenDistributionBidder];
    }

    // The price that asset have been sold for, is only determined once all tokens have been distributed.
    function netSalePriceEurCent()
    public view
    requireFinished
    returns (uint256)
    {
        return netSalePriceWei() * 100 / eurRate();
    }

    // The total payment price for all assets in a bid (for all distributed assets, including tax).
    function bidTotalSalePriceWei(address bidder)
    public view
    requireFinished
    returns (uint256)
    {
        return netSalePriceWei() * bidDistributedAmount[bidder] * (1000 + bidVATPermil[bidder]) / 1000;
    }

    // Returns true if the existing bidder has a higher bid than a new bid incoming in the current block.
    function hasHigherBid(address _existingBidder, uint256 _newBidNetWeiPerAsset)
    public view
    requireActive
    returns (bool)
    {
        // NOTE: If an existing bid with the same net wei per asset exists, it's considered HIGHER than a new one!
        return bidNetWeiPerAsset[_existingBidder] >= _newBidNetWeiPerAsset;
    }

    // Returns true if all semi-automatic distribution is finished.
    function distributionDone()
    public view
    requireActive
    returns (bool)
    {
        return lastFundsDistributionBidder == eolGuard;
    }

    /*** Actual auction functionality ***/

    // Start the auction. At this point, NFTs already need to be owned by this auction.
    function startAuction(uint256 _startTimestamp, uint256 _endTimestamp, uint256 _minBidEurCent)
    public
    requireActive
    onlyAdmin
    {
        require(assetToken().balanceOf(address(this)) > 0, "The auction needs to own tokens to be started.");
        require(_startTimestamp >= block.timestamp, "Start needs to be in the future.");
        require(_endTimestamp > _startTimestamp, "End needs to be after the start.");
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        minBidEurCent = _minBidEurCent;
        emit AuctionStartSet(startTimestamp, endTimestamp, minBidEurCent);
    }

    // Adjust the end of the auction, potentially while it's already running.
    function setAuctionEnd(uint256 _endTimestamp)
    public
    requireActive
    requireNotFinished
    onlyAdmin
    {
        require(_endTimestamp > block.timestamp, "End needs to be in the future.");
        require(_endTimestamp > startTimestamp, "End needs to be after the start.");
        endTimestamp = _endTimestamp;
        emit AuctionEndSet(endTimestamp);
    }

    // Adjust the minimum bid of the auction, potentially while it's already running.
    function setMinBid(uint256 _minBidEurCent)
    public
    requireActive
    requireNotFinished
    onlyAdmin
    {
        minBidEurCent = _minBidEurCent;
        emit MinBidSet(minBidEurCent);
    }

    // Bid on a certain number/amount of NFTs. `candidateHigherBidder` ideally is just the exactly next higher bidder.
    function bid(uint256 _amount, string memory _taxRegionIdentifier, address _candidateHigherBidder, bool _acceptTerms, string memory _acceptanceText)
    public payable
    requireActive
    requireStarted
    requireNotFinished
    {
        require(_acceptTerms, "You need to accept the terms.");
        require(bytes(_acceptanceText).length > 0, "You need to send the acceptance text.");
        require(bidAssetAmount[msg.sender] == 0, "You con only make one bid.");
        require(_amount > 0, "You need to bid on at least one asset.");
        require(_amount <= assetToken().balanceOf(address(this)), "You cannot bid on more assets than this auction sells.");
        if (_eurRate == 0) {
            // Rate gets fixed when the first bid is received.
            _eurRate = oracle().eurRate(address(0));
        }
        uint256 vatPermil = taxRegions().vatPermilForRegionId(_taxRegionIdentifier);
        require(vatPermil > 0, "The region is not supported.");
        uint256 netWeiPerAsset = msg.value * 1000 / (1000 + vatPermil) / _amount;
        require(netWeiPerAsset >= minBidWei(), "You need to bid more than the minimum bid plus VAT.");
        if (_candidateHigherBidder == address(0)) {
            // Compare to highest bidder.
            if (highestBidder != address(0) && hasHigherBid(highestBidder, netWeiPerAsset)) {
                _candidateHigherBidder = highestBidder;
            }
        }
        else {
            require(hasHigherBid(_candidateHigherBidder, netWeiPerAsset), "Candidate needs to actually have a higher bid.");
        }
        // Put bid into the linked list.
        if (_candidateHigherBidder == address(0)) {
            // Due to check above, this means we are the new highest bidder.
            if (highestBidder == address(0)) {
                nextLowerBidder[msg.sender] = eolGuard;
            }
            else {
                nextLowerBidder[msg.sender] = highestBidder;
            }
            highestBidder = msg.sender;
        }
        else {
            // Starting with the candidate, run a search for the next lower bidder.
            while (hasHigherBid(nextLowerBidder[_candidateHigherBidder], netWeiPerAsset)) {
                _candidateHigherBidder = nextLowerBidder[_candidateHigherBidder];
            }
            // Now, _candidateHigherBidder is actually the next higher one to the new bid,
            // so insert the new one in the linked list between this and the next lower.
            nextLowerBidder[msg.sender] = nextLowerBidder[_candidateHigherBidder];
            nextLowerBidder[_candidateHigherBidder] = msg.sender;
        }
        // Store properties of the bid.
        bidCount += 1;
        bidAssetAmount[msg.sender] = _amount;
        bidNetWeiPerAsset[msg.sender] = netWeiPerAsset;
        bidVATPermil[msg.sender] = vatPermil;
        bidTimestamp[msg.sender] = block.timestamp;
        bidTotalWei[msg.sender] = msg.value;
        emit NewBid(msg.sender, _amount, netWeiPerAsset, msg.value, _taxRegionIdentifier);
    }

    // Adjust your bid to higher price and/or amount of NFTs. `_candidateHigherBidder` ideally is just the exactly next higher bidder.
    // `_previousNextHigherBidder` needs to be the one exactly above this current bid previously, use the zero address if it's the highest bidder.
    function adjustBid(uint256 _newTotalAmount, address _candidateHigherBidder, address _previousNextHigherBidder)
    public payable
    requireActive
    requireStarted
    requireNotFinished
    {
        require(bidAssetAmount[msg.sender] > 0, "You need to have an active bid.");
        require(msg.sender == highestBidder || nextLowerBidder[_previousNextHigherBidder] == msg.sender, "Previous next higher bidder does not match.");
        require(_newTotalAmount < assetToken().balanceOf(address(this)), "You cannot bid on more assets than this auction sells.");
        require(_newTotalAmount >= bidAssetAmount[msg.sender], "You cannot reduce the amount of assets.");
        uint256 netWeiPerAsset = (bidTotalWei[msg.sender] + msg.value) * 1000 / (1000 + bidVATPermil[msg.sender]) / _newTotalAmount;
        require(netWeiPerAsset >= bidNetWeiPerAsset[msg.sender], "You cannot reduce the bid per asset.");  // Because of that, we're always over the min bid here.
        if (msg.sender == highestBidder) {
            // Already highest bidder, no need to adjust the linked list.
            require(_candidateHigherBidder == address(0) && _previousNextHigherBidder == address(0), "Already highest bidder, all candidate need to be zero.");
        }
        else {
            // Not highest bidder yet, adjust the linked list.
            if (_candidateHigherBidder == address(0)) {
                // Compare to highest bidder.
                if (hasHigherBid(highestBidder, netWeiPerAsset)) {
                    _candidateHigherBidder = highestBidder;
                }
            }
            else {
                require(hasHigherBid(_candidateHigherBidder, netWeiPerAsset), "Candidate needs to actually have a higher bid.");
            }
            // Take previous bid out of the linked list.
            nextLowerBidder[_previousNextHigherBidder] = nextLowerBidder[msg.sender];
            // Put new bid into the linked list.
            if (_candidateHigherBidder == address(0)) {
                // Due to check above, this means we are the new highest bidder.
                nextLowerBidder[msg.sender] = highestBidder;
                highestBidder = msg.sender;
            }
            else {
                // Starting with the candidate, run a search for the next lower bidder.
                while (hasHigherBid(nextLowerBidder[_candidateHigherBidder], netWeiPerAsset)) {
                    _candidateHigherBidder = nextLowerBidder[_candidateHigherBidder];
                }
                // Now, _candidateHigherBidder is actually the next higher one to the new bid,
                // so insert the new one in the linked list between this and the next lower.
                nextLowerBidder[msg.sender] = nextLowerBidder[_candidateHigherBidder];
                nextLowerBidder[_candidateHigherBidder] = msg.sender;
            }
        }
        bidAssetAmount[msg.sender] = _newTotalAmount;
        bidNetWeiPerAsset[msg.sender] = netWeiPerAsset;
        bidTimestamp[msg.sender] = block.timestamp;
        bidTotalWei[msg.sender] += msg.value;
        emit BidChanged(msg.sender, _newTotalAmount, netWeiPerAsset, bidTotalWei[msg.sender]);
    }

    // Distribute tokens and funds, will need a larger number of steps to get through it all.
    function distribute(uint256 _maxSteps)
    public
    requireActive
    requireFinished
    nonReentrant
    {
        for (uint256 i = 0; i < _maxSteps; i++) {
            if (lastFundsDistributionBidder != eolGuard) {
                _distributeOneStep();
            }
        }
    }

    // Run distribution for a single step.
    function _distributeOneStep()
    internal
    {
        if (assetToken().balanceOf(address(this)) > 0) {
            // Distribution Phase 1: Deliver all tokens to the winners.
            if (lastTokenDistributionBidder == address(0)) {
                // We haven't distributed anything yet, start with the highest bidder.
                lastTokenDistributionBidder = highestBidder;
            }
            else if (lastTokenDistributionBidder != eolGuard &&
                     bidDistributedAmount[lastTokenDistributionBidder] >= bidAssetAmount[lastTokenDistributionBidder]) {
                // This one did get all its tokens, move to the next bid.
                lastTokenDistributionBidder = nextLowerBidder[lastTokenDistributionBidder];
            }
            uint256 tokenId = assetToken().tokenOfOwnerByIndex(address(this), 0);
            if (lastTokenDistributionBidder == eolGuard) {
                // We had bids for fewer tokens than we had available!
                emit DistributionFailed(address(0), tokenId);
                // If a receiver fails on onReceivedERC721, the NFT is sent to leftovers address for manual distribution.
                assetToken().safeTransferFrom(address(this), agriData.getAddress("leftovers"), tokenId);
            }
            else {
                bidDistributedAmount[lastTokenDistributionBidder]++;
                shippingManager().setShippingStatus(address(assetToken()), tokenId, ShippingManagerI.ShippingStatus.Sold);
                assetToken().startStorage(tokenId, assetToken().storageFeeYearlyEurCent()); // One year of storage is included.
                emit AssetSold(lastTokenDistributionBidder, tokenId);
                // At last, actually (try to) distribute the asset token.
                try assetToken().safeTransferFrom(address(this), lastTokenDistributionBidder, tokenId) {}
                catch Error(string memory /*reason*/) {
                    emit DistributionFailed(lastTokenDistributionBidder, tokenId);
                    // If a receiver fails on onReceivedERC721, the NFT is sent to leftovers address for manual distribution.
                    assetToken().safeTransferFrom(address(this), agriData.getAddress("leftovers"), tokenId);
                }
            }
        }
        else {
            // Distribution Phase 2: Move actual payment funds to benbeficiary, return overpayments and failed bid funds.
            if (lastFundsDistributionBidder == address(0)) {
                // We haven't distributed funds yet but are done with tokens, start again with the highest bidder.
                lastFundsDistributionBidder = highestBidder;
            }
            else {
                // Move to the next bid(der).
                lastFundsDistributionBidder = nextLowerBidder[lastFundsDistributionBidder];
            }
            if (lastFundsDistributionBidder != eolGuard) {
                uint256 payAmountWei = bidTotalSalePriceWei(lastFundsDistributionBidder);
                if (payAmountWei > 0) {
                    emit PaymentForwarded(agriData.getAddress("beneficiary"), payAmountWei, bidDistributedAmount[lastFundsDistributionBidder], netSalePriceWei(), bidVATPermil[lastFundsDistributionBidder]);
                    // Transfer the actual payment amount to the beneficiary.
                    // Our own account so no reentrancy here.
                    payable(agriData.getAddress("beneficiary")).sendValue(payAmountWei);
                }
                if (!lastFundsDistributionBidder.isContract()) {
                    bidDistributedFunds[lastFundsDistributionBidder] = true;
                    uint256 refundAmount = bidTotalWei[lastFundsDistributionBidder] - payAmountWei;
                    emit PaymentRefunded(lastFundsDistributionBidder, refundAmount);
                    // EOAs get their funds back directly, contract need to withdraw themselves.
                    payable(lastFundsDistributionBidder).sendValue(refundAmount);
                }
            }
        }
    }

    // Contracts can withdraw their overpayments (or funds for lost bids) when distribute() is fully done.
    function withdrawFunds()
    public
    requireActive
    requireFinished
    {
        require(distributionDone(), "Semi-automatic distribution of funds needs to be finished.");
        require(bidAssetAmount[msg.sender] > 0, "You need to have a bid on this auction.");
        require(bidDistributedFunds[msg.sender] == false, "Funds cannot be paid back twice!");
        uint256 refundAmount = bidTotalWei[msg.sender] - bidTotalSalePriceWei(msg.sender);
        bidDistributedFunds[msg.sender] = true;
        emit PaymentRefunded(msg.sender, refundAmount);
        // Transfer the overpayment (for a winner, otherwise the whole amount) back to the bidder.
        // Last thing to do to prevent reentrancy.
        payable(msg.sender).sendValue(refundAmount);
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // See https://docs.ens.domains/ens-deployments for address of ENS deployments, e.g. Etherscan can be used to look up that owner on those.
    // namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
    // Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
    // Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
    function registerReverseENS(address _reverseRegistrarAddress, string memory _name)
    public
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "Need valid reverse registrar.");
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