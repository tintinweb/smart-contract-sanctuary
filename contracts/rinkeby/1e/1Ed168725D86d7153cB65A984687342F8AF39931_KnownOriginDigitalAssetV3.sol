/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165Storage.sol



pragma solidity ^0.8.0;


/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

// File: contracts/access/IKOAccessControlsLookup.sol



pragma solidity 0.8.4;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(uint256 _index, address _account, bytes32[] calldata _merkleProof) external view returns (bool);

    function isVerifiedArtistProxy(address _artist, address _proxy) external view returns (bool);

    function hasLegacyMinterRole(address _address) external view returns (bool);

    function hasContractRole(address _address) external view returns (bool);

    function hasContractOrAdminRole(address _address) external view returns (bool);
}

// File: contracts/core/IERC2981.sol



pragma solidity 0.8.4;


/// @notice This is purely an extension for the KO platform
/// @notice Royalties on KO are defined at an edition level for all tokens from the same edition
interface IERC2981EditionExtension {

    /// @notice Does the edition have any royalties defined
    function hasRoyalties(uint256 _editionId) external view returns (bool);

    /// @notice Get the royalty receiver - all royalties should be sent to this account if not zero address
    function getRoyaltiesReceiver(uint256 _editionId) external view returns (address);
}

/**
 * ERC2981 standards interface for royalties
 */
interface IERC2981 is IERC165, IERC2981EditionExtension {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _value
    ) external view returns (
        address _receiver,
        uint256 _royaltyAmount
    );

}

// File: contracts/core/IKODAV3Minter.sol



pragma solidity 0.8.4;

interface IKODAV3Minter {

    function mintBatchEdition(uint16 _editionSize, address _to, string calldata _uri) external returns (uint256 _editionId);

    function mintBatchEditionAndComposeERC20s(uint16 _editionSize, address _to, string calldata _uri, address[] calldata _erc20s, uint256[] calldata _amounts) external returns (uint256 _editionId);

    function mintConsecutiveBatchEdition(uint16 _editionSize, address _to, string calldata _uri) external returns (uint256 _editionId);
}

// File: contracts/programmable/ITokenUriResolver.sol



pragma solidity 0.8.4;

interface ITokenUriResolver {

    /// @notice Return the edition or token level URI - token level trumps edition level if found
    function tokenURI(uint256 _editionId, uint256 _tokenId) external view returns (string memory);

    /// @notice Do we have an edition level or token level token URI resolver set
    function isDefined(uint256 _editionId, uint256 _tokenId) external view returns (bool);
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol



pragma solidity ^0.8.0;

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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

    constructor () {
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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/core/IERC2309.sol



pragma solidity 0.8.4;

/**
  @title ERC-2309: ERC-721 Batch Mint Extension
  @dev https://github.com/ethereum/EIPs/issues/2309
 */
interface IERC2309 {
    /**
      @notice This event is emitted when ownership of a batch of tokens changes by any mechanism.
      This includes minting, transferring, and burning.

      @dev The address executing the transaction MUST own all the tokens within the range of
      fromTokenId and toTokenId, or MUST be an approved operator to act on the owners behalf.
      The fromTokenId and toTokenId MUST be a sequential range of tokens IDs.
      When minting/creating tokens, the `fromAddress` argument MUST be set to `0x0` (i.e. zero address).
      When burning/destroying tokens, the `toAddress` argument MUST be set to `0x0` (i.e. zero address).

      @param fromTokenId The token ID that begins the batch of tokens being transferred
      @param toTokenId The token ID that ends the batch of tokens being transferred
      @param fromAddress The address transferring ownership of the specified range of tokens
      @param toAddress The address receiving ownership of the specified range of tokens.
    */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

// File: contracts/core/IHasSecondarySaleFees.sol



pragma solidity 0.8.4;


/// @title Royalties formats required for use on the Rarible platform
/// @dev https://docs.rarible.com/asset/royalties-schema
interface IHasSecondarySaleFees is IERC165 {

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    function getFeeRecipients(uint256 id) external returns (address payable[] memory);

    function getFeeBps(uint256 id) external returns (uint[] memory);
}

// File: contracts/core/IKODAV3.sol



pragma solidity 0.8.4;






/// @title Core KODA V3 functionality
interface IKODAV3 is
IERC165, // Contract introspection
IERC721, // Core NFTs
IERC2309, // Consecutive batch mint
IERC2981, // Royalties
IHasSecondarySaleFees // Rariable / Foundation royalties
{
    // edition utils

    function getCreatorOfEdition(uint256 _editionId) external view returns (address _originalCreator);

    function getCreatorOfToken(uint256 _tokenId) external view returns (address _originalCreator);

    function getSizeOfEdition(uint256 _editionId) external view returns (uint256 _size);

    function getEditionSizeOfToken(uint256 _tokenId) external view returns (uint256 _size);

    function editionExists(uint256 _editionId) external view returns (bool);

    // Has the edition been disabled / soft burnt
    function isEditionSalesDisabled(uint256 _editionId) external view returns (bool);

    // Has the edition been disabled / soft burnt OR sold out
    function isSalesDisabledOrSoldOut(uint256 _editionId) external view returns (bool);

    // Work out the max token ID for an edition ID
    function maxTokenIdOfEdition(uint256 _editionId) external view returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting low to high token IDs
    function getNextAvailablePrimarySaleToken(uint256 _editionId) external returns (uint256 _tokenId);

    // Helper method for getting the next primary sale token from an edition starting high to low token IDs
    function getReverseAvailablePrimarySaleToken(uint256 _editionId) external view returns (uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, low token ID to high
    function facilitateNextPrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Utility method to get all data needed for the next primary sale, high token ID to low
    function facilitateReversePrimarySale(uint256 _editionId) external returns (address _receiver, address _creator, uint256 _tokenId);

    // Expanded royalty method for the edition, not token
    function royaltyAndCreatorInfo(uint256 _editionId, uint256 _value) external returns (address _receiver, address _creator, uint256 _amount);

    // Allows the creator to correct mistakes until the first token from an edition is sold
    function updateURIIfNoSaleMade(uint256 _editionId, string calldata _newURI) external;

    // Has any primary transfer happened from an edition
    function hasMadePrimarySale(uint256 _editionId) external view returns (bool);

    // Has the edition sold out
    function isEditionSoldOut(uint256 _editionId) external view returns (bool);

    // Toggle on/off the edition from being able to make sales
    function toggleEditionSalesDisabled(uint256 _editionId) external;

    // token utils

    function exists(uint256 _tokenId) external view returns (bool);

    function getEditionIdOfToken(uint256 _tokenId) external pure returns (uint256 _editionId);

    function getEditionDetails(uint256 _tokenId) external view returns (address _originalCreator, address _owner, uint16 _size, uint256 _editionId, string memory _uri);

    function hadPrimarySaleOfToken(uint256 _tokenId) external view returns (bool);
}

// File: contracts/core/composable/TopDownERC20Composable.sol



pragma solidity 0.8.4;







interface ERC998ERC20TopDown {
    event ReceivedERC20(address indexed _from, uint256 indexed _tokenId, address indexed _erc20Contract, uint256 _value);
    event ReceivedERC20ForEdition(address indexed _from, uint256 indexed _editionId, address indexed _erc20Contract, uint256 _value);
    event TransferERC20(uint256 indexed _tokenId, address indexed _to, address indexed _erc20Contract, uint256 _value);

    function balanceOfERC20(uint256 _tokenId, address _erc20Contract) external view returns (uint256);

    function transferERC20(uint256 _tokenId, address _to, address _erc20Contract, uint256 _value) external;

    function getERC20(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) external;
}

interface ERC998ERC20TopDownEnumerable {
    function totalERC20Contracts(uint256 _tokenId) external view returns (uint256);

    function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address);
}

/// @notice ERC998 ERC721 > ERC20 Top Down implementation
abstract contract TopDownERC20Composable is ERC998ERC20TopDown, ERC998ERC20TopDownEnumerable, ReentrancyGuard, Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Edition ID -> ERC20 contract -> Balance of ERC20 for every token in Edition
    mapping(uint256 => mapping(address => uint256)) public editionTokenERC20Balances;

    // Edition ID -> ERC20 contract -> Token ID -> Balance Transferred out of token
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public editionTokenERC20TransferAmounts;

    // Edition ID -> Linked ERC20 contract addresses
    mapping(uint256 => EnumerableSet.AddressSet) ERC20sEmbeddedInEdition;

    // Token ID -> Linked ERC20 contract addresses
    mapping(uint256 => EnumerableSet.AddressSet) ERC20sEmbeddedInNft;

    // Token ID -> ERC20 contract -> balance of ERC20 owned by token
    mapping(uint256 => mapping(address => uint256)) public ERC20Balances;

    /// @notice the ERC20 balance of a NFT token given an ERC20 token address
    function balanceOfERC20(uint256 _tokenId, address _erc20Contract) public override view returns (uint256) {
        IKODAV3 koda = IKODAV3(address(this));
        uint256 editionId = koda.getEditionIdOfToken(_tokenId);

        uint256 editionBalance = editionTokenERC20Balances[editionId][_erc20Contract];
        uint256 tokenEditionBalance = editionBalance / koda.getSizeOfEdition(editionId);
        uint256 spentTokens = editionTokenERC20TransferAmounts[editionId][_erc20Contract][_tokenId];
        tokenEditionBalance = tokenEditionBalance - spentTokens;

        return tokenEditionBalance + ERC20Balances[_tokenId][_erc20Contract];
    }

    /// @notice Transfer out an ERC20 from an NFT
    function transferERC20(uint256 _tokenId, address _to, address _erc20Contract, uint256 _value) external override nonReentrant {
        _prepareERC20LikeTransfer(_tokenId, _to, _erc20Contract, _value);

        IERC20(_erc20Contract).transfer(_to, _value);

        emit TransferERC20(_tokenId, _to, _erc20Contract, _value);
    }

    /// @notice An NFT token owner (or approved) can compose multiple ERC20s in their NFT
    function getERC20s(address _from, uint256[] calldata _tokenIds, address _erc20Contract, uint256 _totalValue) external {
        uint256 totalTokens = _tokenIds.length;
        require(totalTokens > 0 && _totalValue > 0, "Empty values provided");

        uint256 valuePerToken = _totalValue / totalTokens;
        for (uint i = 0; i < totalTokens; i++) {
            getERC20(_from, _tokenIds[i], _erc20Contract, valuePerToken);
        }
    }

    /// @notice A NFT token owner (or approved address) can compose any ERC20 in their NFT
    function getERC20(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) public override nonReentrant {
        require(_value > 0, "Value cannot be zero");

        address spender = _msgSender();
        IERC721 self = IERC721(address(this));

        address owner = self.ownerOf(_tokenId);
        require(
            owner == spender || self.isApprovedForAll(owner, spender) || self.getApproved(_tokenId) == spender,
            "Only token owner"
        );
        require(_from == _msgSender(), "Must be token owner");

        IKODAV3 koda = IKODAV3(address(this));
        uint256 editionId = koda.getEditionIdOfToken(_tokenId);
        bool editionAlreadyContainsERC20 = ERC20sEmbeddedInEdition[editionId].contains(_erc20Contract);
        bool nftAlreadyContainsERC20 = ERC20sEmbeddedInNft[_tokenId].contains(_erc20Contract);

        // does not already contain _erc20Contract
        if (!editionAlreadyContainsERC20 && !nftAlreadyContainsERC20) {
            ERC20sEmbeddedInNft[_tokenId].add(_erc20Contract);
        }

        ERC20Balances[_tokenId][_erc20Contract] = ERC20Balances[_tokenId][_erc20Contract] + _value;

        IERC20 token = IERC20(_erc20Contract);
        require(token.allowance(_from, address(this)) >= _value, "Amount exceeds allowance");

        token.transferFrom(_from, address(this), _value);

        emit ReceivedERC20(_from, _tokenId, _erc20Contract, _value);
    }

    function _composeERC20IntoEdition(address _from, uint256 _editionId, address _erc20Contract, uint256 _value) internal nonReentrant {
        require(_value > 0, "Value cannot be zero");

        bool editionAlreadyContainsERC20 = ERC20sEmbeddedInEdition[_editionId].contains(_erc20Contract);
        require(!editionAlreadyContainsERC20, "Edition already contains ERC20");

        ERC20sEmbeddedInEdition[_editionId].add(_erc20Contract);
        editionTokenERC20Balances[_editionId][_erc20Contract] = editionTokenERC20Balances[_editionId][_erc20Contract] + _value;

        IERC20(_erc20Contract).transferFrom(_from, address(this), _value);

        emit ReceivedERC20ForEdition(_from, _editionId, _erc20Contract, _value);
    }

    function totalERC20Contracts(uint256 _tokenId) override public view returns (uint256) {
        IKODAV3 koda = IKODAV3(address(this));
        uint256 editionId = koda.getEditionIdOfToken(_tokenId);
        return ERC20sEmbeddedInNft[_tokenId].length() + ERC20sEmbeddedInEdition[editionId].length();
    }

    function erc20ContractByIndex(uint256 _tokenId, uint256 _index) override external view returns (address) {
        uint256 numOfERC20sInNFT = ERC20sEmbeddedInNft[_tokenId].length();
        if (_index >= numOfERC20sInNFT) {
            IKODAV3 koda = IKODAV3(address(this));
            uint256 editionId = koda.getEditionIdOfToken(_tokenId);
            return ERC20sEmbeddedInEdition[editionId].at(_index - numOfERC20sInNFT);
        }

        return ERC20sEmbeddedInNft[_tokenId].at(_index);
    }

    /// --- Internal ----

    function _prepareERC20LikeTransfer(uint256 _tokenId, address _to, address _erc20Contract, uint256 _value) private {
        // To avoid stack too deep, do input checks within this scope
        {
            require(_value > 0, "Value cannot be zero");
            require(_to != address(0), "To cannot be zero address");

            IERC721 self = IERC721(address(this));

            address owner = self.ownerOf(_tokenId);
            require(
                owner == _msgSender() || self.isApprovedForAll(owner, _msgSender()) || self.getApproved(_tokenId) == _msgSender(),
                "Not owner"
            );
        }

        // Check that the NFT contains the ERC20
        bool nftContainsERC20 = ERC20sEmbeddedInNft[_tokenId].contains(_erc20Contract);

        IKODAV3 koda = IKODAV3(address(this));
        uint256 editionId = koda.getEditionIdOfToken(_tokenId);
        bool editionContainsERC20 = ERC20sEmbeddedInEdition[editionId].contains(_erc20Contract);
        require(nftContainsERC20 || editionContainsERC20, "No such ERC20 wrapped in token");

        // Check there is enough balance to transfer out
        require(balanceOfERC20(_tokenId, _erc20Contract) >= _value, "Transfer amount exceeds balance");

        uint256 editionSize = koda.getSizeOfEdition(editionId);
        uint256 tokenInitialBalance = editionTokenERC20Balances[editionId][_erc20Contract] / editionSize;
        uint256 spentTokens = editionTokenERC20TransferAmounts[editionId][_erc20Contract][_tokenId];
        uint256 editionTokenBalance = tokenInitialBalance - spentTokens;

        // Check whether the value can be fully transferred from the edition balance, token balance or both balances
        if (editionTokenBalance >= _value) {
            editionTokenERC20TransferAmounts[editionId][_erc20Contract][_tokenId] = spentTokens + _value;
        } else if (ERC20Balances[_tokenId][_erc20Contract] >= _value) {
            ERC20Balances[_tokenId][_erc20Contract] = ERC20Balances[_tokenId][_erc20Contract] - _value;
        } else {
            // take from both balances
            editionTokenERC20TransferAmounts[editionId][_erc20Contract][_tokenId] = spentTokens + editionTokenBalance;
            uint256 amountOfTokensToSpendFromTokenBalance = _value - editionTokenBalance;
            ERC20Balances[_tokenId][_erc20Contract] = ERC20Balances[_tokenId][_erc20Contract] - amountOfTokensToSpendFromTokenBalance;
        }

        // The ERC20 is no longer composed within the token if the balance falls to zero
        if (nftContainsERC20 && ERC20Balances[_tokenId][_erc20Contract] == 0) {
            ERC20sEmbeddedInNft[_tokenId].remove(_erc20Contract);
        }

        // If all tokens in an edition have spent their ERC20 balance, then we can remove the link
        if (editionContainsERC20) {
            uint256 allTokensInEditionERC20Balance;
            for (uint i = 0; i < editionSize; i++) {
                uint256 tokenBal = tokenInitialBalance - editionTokenERC20TransferAmounts[editionId][_erc20Contract][editionId + i];
                allTokensInEditionERC20Balance = allTokensInEditionERC20Balance + tokenBal;
            }

            if (allTokensInEditionERC20Balance == 0) {
                ERC20sEmbeddedInEdition[editionId].remove(_erc20Contract);
            }
        }
    }
}

// File: contracts/core/composable/TopDownSimpleERC721Composable.sol



pragma solidity 0.8.4;



abstract contract TopDownSimpleERC721Composable is Context {
    struct ComposedNFT {
        address nft;
        uint256 tokenId;
    }

    // KODA Token ID -> composed nft
    mapping(uint256 => ComposedNFT) public kodaTokenComposedNFT;

    // External NFT address -> External Token ID -> KODA token ID
    mapping(address => mapping(uint256 => uint256)) public composedNFTsToKodaToken;

    event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
    event TransferChild(uint256 indexed _tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);

    /// @notice compose a child ERC721 into a KODA token
    /// @notice Caller must own both KODA and child NFT tokens
    function composeNFTIntoKodaToken(uint256 _kodaTokenId, address _nft, uint256 _nftTokenId) external {
        require(kodaTokenComposedNFT[_kodaTokenId].nft == address(0), "Max 1 NFT");

        IERC721 nftContract = IERC721(_nft);
        require(
            IERC721(address(this)).ownerOf(_kodaTokenId) == nftContract.ownerOf(_nftTokenId),
            "Need to own both tokens"
        );

        kodaTokenComposedNFT[_kodaTokenId] = ComposedNFT(_nft, _nftTokenId);
        composedNFTsToKodaToken[_nft][_nftTokenId] = _kodaTokenId;

        nftContract.transferFrom(_msgSender(), address(this), _nftTokenId);
        emit ReceivedChild(_msgSender(), _kodaTokenId, _nft, _nftTokenId);
    }

    /// @notice Transfer a child 721 wrapped within a KODA token to a given recipient
    /// @notice only KODA token owner can call this
    function transferChild(uint256 _kodaTokenId, address _recipient) external {
        require(
            IERC721(address(this)).ownerOf(_kodaTokenId) == _msgSender(),
            "Only KODA owner"
        );

        address nft = kodaTokenComposedNFT[_kodaTokenId].nft;
        uint256 nftId = kodaTokenComposedNFT[_kodaTokenId].tokenId;

        delete kodaTokenComposedNFT[_kodaTokenId];
        delete composedNFTsToKodaToken[nft][nftId];

        IERC721(nft).transferFrom(address(this), _recipient, nftId);

        emit TransferChild(_kodaTokenId, _recipient, nft, nftId);
    }
}

// File: contracts/core/Konstants.sol



pragma solidity 0.8.4;

contract Konstants {

    // Every edition always goes up in batches of 1000
    uint16 public constant MAX_EDITION_SIZE = 1000;

    // magic method that defines the maximum range for an edition - this is fixed forever - tokens are minted in range
    function _editionFromTokenId(uint256 _tokenId) internal pure returns (uint256) {
        return (_tokenId / MAX_EDITION_SIZE) * MAX_EDITION_SIZE;
    }
}

// File: contracts/core/BaseKoda.sol



pragma solidity 0.8.4;






abstract contract BaseKoda is Konstants, Context, IKODAV3 {

    bytes4 constant internal ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    event AdminUpdateSecondaryRoyalty(uint256 _secondarySaleRoyalty);
    event AdminUpdateBasisPointsModulo(uint256 _basisPointsModulo);
    event AdminUpdateModulo(uint256 _modulo);
    event AdminEditionReported(uint256 indexed _editionId, bool indexed _reported);
    event AdminArtistAccountReported(address indexed _account, bool indexed _reported);
    event AdminUpdateAccessControls(IKOAccessControlsLookup indexed _oldAddress, IKOAccessControlsLookup indexed _newAddress);

    modifier onlyContract(){
        _onlyContract();
        _;
    }

    function _onlyContract() private view {
        require(accessControls.hasContractRole(_msgSender()), "Caller must have contract role");
    }

    modifier onlyAdmin(){
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() private view {
        require(accessControls.hasAdminRole(_msgSender()), "Caller must have admin role");
    }

    IKOAccessControlsLookup public accessControls;

    // A onchain reference to editions which have been reported for some infringement purposes to KO
    mapping(uint256 => bool) public reportedEditionIds;

    // A onchain reference to accounts which have been lost/hacked etc
    mapping(address => bool) public reportedArtistAccounts;

    // Secondary sale commission
    uint256 public secondarySaleRoyalty = 12_50000; // 12.5% by default

    /// @notice precision 100.00000%
    uint256 public modulo = 100_00000;

    /// @notice Basis points conversion modulo
    /// @notice This is used by the IHasSecondarySaleFees implementation which is different than EIP-2981 specs
    uint256 public basisPointsModulo = 1000;

    constructor(IKOAccessControlsLookup _accessControls) {
        accessControls = _accessControls;
    }

    function reportEditionId(uint256 _editionId, bool _reported) onlyAdmin public {
        reportedEditionIds[_editionId] = _reported;
        emit AdminEditionReported(_editionId, _reported);
    }

    function reportArtistAccount(address _account, bool _reported) onlyAdmin public {
        reportedArtistAccounts[_account] = _reported;
        emit AdminArtistAccountReported(_account, _reported);
    }

    function updateBasisPointsModulo(uint256 _basisPointsModulo) onlyAdmin public {
        require(_basisPointsModulo > 0, "Basis point cannot be zero");
        basisPointsModulo = _basisPointsModulo;
        emit AdminUpdateBasisPointsModulo(_basisPointsModulo);
    }

    function updateModulo(uint256 _modulo) onlyAdmin public {
        require(_modulo > 0, "Modulo point cannot be zero");
        modulo = _modulo;
        emit AdminUpdateModulo(_modulo);
    }

    function updateSecondaryRoyalty(uint256 _secondarySaleRoyalty) onlyAdmin public {
        secondarySaleRoyalty = _secondarySaleRoyalty;
        emit AdminUpdateSecondaryRoyalty(_secondarySaleRoyalty);
    }

    function updateAccessControls(IKOAccessControlsLookup _accessControls) public onlyAdmin {
        require(_accessControls.hasAdminRole(_msgSender()), "Sender must have admin role in new contract");
        emit AdminUpdateAccessControls(accessControls, _accessControls);
        accessControls = _accessControls;
    }

    /// @dev Allows for the ability to extract stuck ERC20 tokens
    /// @dev Only callable from admin
    function withdrawStuckTokens(address _tokenAddress, uint256 _amount, address _withdrawalAccount) onlyAdmin public {
        IERC20(_tokenAddress).transfer(_withdrawalAccount, _amount);
    }
}

// File: contracts/core/KnownOriginDigitalAssetV3.sol



pragma solidity 0.8.4;











/// @title A ERC-721 compliant contract which has a focus on being GAS efficient along with being able to support
/// both unique tokens and multi-editions sharing common traits but of limited supply
///
/// @author KnownOrigin Labs - https://knownorigin.io/
///
/// @notice The NFT supports a range of standards such as:
/// @notice EIP-2981 Royalties Standard
/// @notice EIP-2309 Consecutive batch mint
/// @notice ERC-998 Top-down ERC-20 composable
contract KnownOriginDigitalAssetV3 is
    TopDownERC20Composable,
    TopDownSimpleERC721Composable,
    BaseKoda,
    ERC165Storage,
    IKODAV3Minter {

    event EditionURIUpdated(uint256 indexed _editionId);
    event EditionSalesDisabledToggled(uint256 indexed _editionId, bool _oldValue, bool _newValue);
    event SealedEditionMetaDataSet(uint256 indexed _editionId);
    event SealedTokenMetaDataSet(uint256 indexed _tokenId);
    event AdditionalEditionUnlockableSet(uint256 indexed _editionId);
    event AdminRoyaltiesRegistryProxySet(address indexed _royaltiesRegistryProxy);
    event AdminTokenUriResolverSet(address indexed _tokenUriResolver);

    modifier validateEdition(uint256 _editionId) {
        _validateEdition(_editionId);
        _;
    }

    function _validateEdition(uint256 _editionId) private view {
        require(_editionExists(_editionId), "Edition does not exist");
    }

    /// @notice Token name
    string public constant name = "KnownOriginDigitalAsset";

    /// @notice Token symbol
    string public constant symbol = "KODA";

    /// @notice KODA version
    string public constant version = "3";

    /// @notice Royalties registry
    IERC2981 public royaltiesRegistryProxy;

    /// @notice Token URI resolver
    ITokenUriResolver public tokenUriResolver;

    /// @notice Edition number pointer
    uint256 public editionPointer;

    struct EditionDetails {
        address creator; // primary edition/token creator
        uint16 editionSize; // onchain edition size
        string uri; // the referenced metadata
    }

    /// @dev tokens are minted in batches - the first token ID used is representative of the edition ID
    mapping(uint256 => EditionDetails) internal editionDetails;

    /// @dev Mapping of tokenId => owner - only set on first transfer (after mint) such as a primary sale and/or gift
    mapping(uint256 => address) internal owners;

    /// @dev Mapping of owner => number of tokens owned
    mapping(address => uint256) internal balances;

    /// @dev Mapping of tokenId => approved address
    mapping(uint256 => address) internal approvals;

    /// @dev Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    /// @notice Optional one time use storage slot for additional edition metadata
    mapping(uint256 => string) public sealedEditionMetaData;

    /// @notice Optional one time use storage slot for additional token metadata such ass peramweb metadata
    mapping(uint256 => string) public sealedTokenMetaData;

    /// @notice Optional storage slot for additional unlockable content
    mapping(uint256 => string) public additionalEditionUnlockableSlot;

    /// @notice Allows a creator to disable sales of their edition
    mapping(uint256 => bool) public editionSalesDisabled;

    constructor(
        IKOAccessControlsLookup _accessControls,
        IERC2981 _royaltiesRegistryProxy,
        uint256 _editionPointer
    ) BaseKoda(_accessControls) {

        editionPointer = _editionPointer;

        // optional registry address - can be constructed as zero address
        royaltiesRegistryProxy = _royaltiesRegistryProxy;

        // INTERFACE_ID_ERC721
        _registerInterface(0x80ac58cd);

        // INTERFACE_ID_ERC721_METADATA
        _registerInterface(0x5b5e139f);

        // _INTERFACE_ID_ERC2981
        _registerInterface(0x2a55205a);

        // _INTERFACE_ID_FEES
        _registerInterface(0xb7799584);
    }

    /// @notice Mints batches of tokens emitting multiple Transfer events
    function mintBatchEdition(uint16 _editionSize, address _to, string calldata _uri)
    public
    override
    onlyContract
    returns (uint256 _editionId) {
        return _mintBatchEdition(_editionSize, _to, _uri);
    }

    /// @notice Mints an edition token batch and composes ERC20s for every token in the edition
    /// @dev there is a limit on the number of ERC20s that can be embedded in an edition
    function mintBatchEditionAndComposeERC20s(
        uint16 _editionSize,
        address _to,
        string calldata _uri,
        address[] calldata _erc20s,
        uint256[] calldata _amounts
    ) external
    override
    onlyContract
    returns (uint256 _editionId) {
        uint256 totalErc20s = _erc20s.length;
        require(totalErc20s > 0 && totalErc20s == _amounts.length, "Tokens invalid");

        _editionId = _mintBatchEdition(_editionSize, _to, _uri);

        for (uint i = 0; i < totalErc20s; i++) {
            _composeERC20IntoEdition(_to, _editionId, _erc20s[i], _amounts[i]);
        }
    }

    function _mintBatchEdition(uint16 _editionSize, address _to, string calldata _uri) internal returns (uint256) {
        require(_editionSize > 0 && _editionSize <= MAX_EDITION_SIZE, "Invalid edition size");

        uint256 start = generateNextEditionNumber();

        // N.B: Dont store owner, see ownerOf method to special case checking to avoid storage costs on creation

        // assign balance
        balances[_to] = balances[_to] + _editionSize;

        // edition of x
        editionDetails[start] = EditionDetails(_to, _editionSize, _uri);

        // Loop emit all transfer events
        uint256 end = start + _editionSize;
        for (uint i = start; i < end; i++) {
            emit Transfer(address(0), _to, i);
        }
        return start;
    }

    /// @notice Mints batches of tokens but emits a single ConsecutiveTransfer event EIP-2309
    function mintConsecutiveBatchEdition(uint16 _editionSize, address _to, string calldata _uri)
    public
    override
    onlyContract
    returns (uint256 _editionId) {
        require(_editionSize > 0 && _editionSize <= MAX_EDITION_SIZE, "Invalid edition size");

        uint256 start = generateNextEditionNumber();

        // N.B: Dont store owner, see ownerOf method to special case checking to avoid storage costs on creation

        // assign balance
        balances[_to] = balances[_to] + _editionSize;

        // Start ID always equals edition ID
        editionDetails[start] = EditionDetails(_to, _editionSize, _uri);

        // emit EIP-2309 consecutive transfer event
        emit ConsecutiveTransfer(start, start + _editionSize, address(0), _to);

        return start;
    }

    /// @notice Allows the creator of an edition to update the token URI provided that no primary sales have been made
    function updateURIIfNoSaleMade(uint256 _editionId, string calldata _newURI) external override {
        require(_msgSender() == editionDetails[_editionId].creator, "Not creator");
        require(
            !hasMadePrimarySale(_editionId) && (!tokenUriResolverActive() || !tokenUriResolver.isDefined(_editionId, 0)),
            "Invalid Edition state"
        );

        editionDetails[_editionId].uri = _newURI;

        emit EditionURIUpdated(_editionId);
    }

    /// @notice Increases the edition pointer and then returns this pointer for minting methods
    function generateNextEditionNumber() internal returns (uint256) {
        editionPointer = editionPointer + MAX_EDITION_SIZE;
        return editionPointer;
    }

    /// @notice URI for an edition. Individual tokens in an edition will have this URI when tokenURI() is called
    function editionURI(uint256 _editionId) validateEdition(_editionId) public view returns (string memory) {

        // Here we are checking only that the edition has a edition level resolver - there may be a overridden token level resolver
        if (tokenUriResolverActive() && tokenUriResolver.isDefined(_editionId, 0)) {
            return tokenUriResolver.tokenURI(_editionId, 0);
        }

        return editionDetails[_editionId].uri;
    }

    /// @notice Returns the URI based on the edition associated with a token
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        uint256 editionId = _editionFromTokenId(_tokenId);

        if (tokenUriResolverActive() && tokenUriResolver.isDefined(editionId, _tokenId)) {
            return tokenUriResolver.tokenURI(editionId, _tokenId);
        }

        return editionDetails[editionId].uri;
    }

    /// @notice Allows the caller to check if external URI resolver is active
    function tokenUriResolverActive() public view returns (bool) {
        return address(tokenUriResolver) != address(0);
    }

    /// @notice Additional metadata string for an edition
    function editionAdditionalMetaData(uint256 _editionId) public view returns (string memory) {
        return sealedEditionMetaData[_editionId];
    }

    /// @notice Additional metadata string for a token
    function tokenAdditionalMetaData(uint256 _tokenId) public view returns (string memory) {
        return sealedTokenMetaData[_tokenId];
    }

    /// @notice Additional metadata string for an edition given a token ID
    function editionAdditionalMetaDataForToken(uint256 _tokenId) public view returns (string memory) {
        uint256 editionId = _editionFromTokenId(_tokenId);
        return sealedEditionMetaData[editionId];
    }

    function getEditionDetails(uint256 _tokenId)
    public
    override
    view
    returns (address _originalCreator, address _owner, uint16 _size, uint256 _editionId, string memory _uri) {
        uint256 editionId = _editionFromTokenId(_tokenId);
        EditionDetails storage edition = editionDetails[editionId];
        return (
        edition.creator,
        _ownerOf(_tokenId, editionId),
        edition.editionSize,
        editionId,
        tokenURI(_tokenId)
        );
    }

    /// @notice If primary sales for an edition are disabled
    function isEditionSalesDisabled(uint256 _editionId) external view override returns (bool) {
        return editionSalesDisabled[_editionId];
    }

    /// @notice If primary sales for an edition are disabled or if the edition is sold out
    function isSalesDisabledOrSoldOut(uint256 _editionId) external view override returns (bool) {
        return editionSalesDisabled[_editionId] || isEditionSoldOut(_editionId);
    }

    /// @notice Toggle for disabling primary sales for an edition
    function toggleEditionSalesDisabled(uint256 _editionId) validateEdition(_editionId) external override {
        address creator = editionDetails[_editionId].creator;

        require(
            creator == _msgSender() || accessControls.hasAdminRole(_msgSender()),
            "Only creator or platform admin"
        );

        emit EditionSalesDisabledToggled(_editionId, editionSalesDisabled[_editionId], !editionSalesDisabled[_editionId]);

        editionSalesDisabled[_editionId] = !editionSalesDisabled[_editionId];
    }

    ///////////////////
    // Creator query //
    ///////////////////

    function getCreatorOfEdition(uint256 _editionId) public override view returns (address _originalCreator) {
        return _getCreatorOfEdition(_editionId);
    }

    function getCreatorOfToken(uint256 _tokenId) public override view returns (address _originalCreator) {
        return _getCreatorOfEdition(_editionFromTokenId(_tokenId));
    }

    function _getCreatorOfEdition(uint256 _editionId) internal view returns (address _originalCreator) {
        return editionDetails[_editionId].creator;
    }

    ////////////////
    // Size query //
    ////////////////

    function getSizeOfEdition(uint256 _editionId) public override view returns (uint256 _size) {
        return editionDetails[_editionId].editionSize;
    }

    function getEditionSizeOfToken(uint256 _tokenId) public override view returns (uint256 _size) {
        return editionDetails[_editionFromTokenId(_tokenId)].editionSize;
    }

    /////////////////////
    // Existence query //
    /////////////////////

    function editionExists(uint256 _editionId) public override view returns (bool) {
        return _editionExists(_editionId);
    }

    function _editionExists(uint256 _editionId) internal view returns (bool) {
        return editionDetails[_editionId].editionSize > 0;
    }

    function exists(uint256 _tokenId) public override view returns (bool) {
        return _exists(_tokenId);
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf(_tokenId, _editionFromTokenId(_tokenId)) != address(0);
    }

    /// @notice Returns the last token ID of an edition based on the edition's size
    function maxTokenIdOfEdition(uint256 _editionId) public override view returns (uint256 _tokenId) {
        return _maxTokenIdOfEdition(_editionId);
    }

    function _maxTokenIdOfEdition(uint256 _editionId) internal view returns (uint256 _tokenId) {
        return editionDetails[_editionId].editionSize + _editionId;
    }

    ////////////////
    // Edition ID //
    ////////////////

    function getEditionIdOfToken(uint256 _tokenId) public override pure returns (uint256 _editionId) {
        return _editionFromTokenId(_tokenId);
    }

    function _royaltyInfo(uint256 _tokenId, uint256 _value) internal view returns (address _receiver, uint256 _royaltyAmount) {
        uint256 editionId = _editionFromTokenId(_tokenId);
        // If we have a registry and its defined, use it
        if (royaltyRegistryActive() && royaltiesRegistryProxy.hasRoyalties(editionId)) {
            // Note: any registry must be edition aware so to only store one entry for all within the edition
            (_receiver, _royaltyAmount) = royaltiesRegistryProxy.royaltyInfo(editionId, _value);
        } else {
            // Fall back to KO defaults
            _receiver = _getCreatorOfEdition(editionId);
            _royaltyAmount = (_value / modulo) * secondarySaleRoyalty;
        }
    }

    //////////////
    // ERC-2981 //
    //////////////

    // Abstract away token royalty registry, proxy through to the implementation
    function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    override
    view
    returns (address _receiver, uint256 _royaltyAmount) {
        return _royaltyInfo(_tokenId, _value);
    }

    // Expanded method at edition level and expanding on the funds receiver and the creator
    function royaltyAndCreatorInfo(uint256 _tokenId, uint256 _value)
    external
    view
    override
    returns (address receiver, address creator, uint256 royaltyAmount) {
        address originalCreator = _getCreatorOfEdition(_editionFromTokenId(_tokenId));
        (address _receiver, uint256 _royaltyAmount) = _royaltyInfo(_tokenId, _value);
        return (_receiver, originalCreator, _royaltyAmount);
    }

    function hasRoyalties(uint256 _editionId) validateEdition(_editionId) external override view returns (bool) {
        return royaltyRegistryActive() && royaltiesRegistryProxy.hasRoyalties(_editionId)
        || secondarySaleRoyalty > 0;
    }

    function getRoyaltiesReceiver(uint256 _tokenId) public override view returns (address) {
        uint256 editionId = _editionFromTokenId(_tokenId);
        if (royaltyRegistryActive() && royaltiesRegistryProxy.hasRoyalties(editionId)) {
            return royaltiesRegistryProxy.getRoyaltiesReceiver(editionId);
        }
        return _getCreatorOfEdition(editionId);
    }

    function royaltyRegistryActive() public view returns (bool) {
        return address(royaltiesRegistryProxy) != address(0);
    }

    //////////////////////////////
    // Has Secondary Sale Fees //
    ////////////////////////////

    function getFeeRecipients(uint256 _tokenId) external view override returns (address payable[] memory) {
        address payable[] memory feeRecipients = new address payable[](1);
        feeRecipients[0] = payable(getRoyaltiesReceiver(_tokenId));
        return feeRecipients;
    }

    function getFeeBps(uint256 _tokenId) external view override returns (uint[] memory) {
        uint[] memory feeBps = new uint[](1);
        feeBps[0] = uint(secondarySaleRoyalty) / basisPointsModulo;
        // convert to basis points
        return feeBps;
    }

    ////////////////////////////////////
    // Primary Sale Utilities methods //
    ////////////////////////////////////

    /// @notice List of token IDs that are still with the original creator
    function getAllUnsoldTokenIdsForEdition(uint256 _editionId) validateEdition(_editionId) public view returns (uint256[] memory) {
        uint256 maxTokenId = _maxTokenIdOfEdition(_editionId);

        // work out number of unsold tokens in order to allocate memory to an array later
        uint256 numOfUnsoldTokens;
        for (uint256 i = _editionId; i < maxTokenId; i++) {
            // if no owner set - assume primary if not moved
            if (owners[i] == address(0)) {
                numOfUnsoldTokens += 1;
            }
        }

        uint256[] memory unsoldTokens = new uint256[](numOfUnsoldTokens);

        // record token IDs of unsold tokens
        uint256 nextIndex;
        for (uint256 tokenId = _editionId; tokenId < maxTokenId; tokenId++) {
            // if no owner set - assume primary if not moved
            if (owners[tokenId] == address(0)) {
                unsoldTokens[nextIndex] = tokenId;
                nextIndex += 1;
            }
        }

        return unsoldTokens;
    }

    /// @notice For a given edition, returns the next token and associated royalty information
    function facilitateNextPrimarySale(uint256 _editionId)
    public
    view
    override
    returns (address receiver, address creator, uint256 tokenId) {
        require(!editionSalesDisabled[_editionId], "Edition sales disabled");

        uint256 _tokenId = getNextAvailablePrimarySaleToken(_editionId);
        address _creator = _getCreatorOfEdition(_editionId);

        if (royaltyRegistryActive() && royaltiesRegistryProxy.hasRoyalties(_editionId)) {
            address _receiver = royaltiesRegistryProxy.getRoyaltiesReceiver(_editionId);
            return (_receiver, _creator, _tokenId);
        }

        return (_creator, _creator, _tokenId);
    }

    /// @notice Return the next unsold token ID for a given edition unless all tokens have been sold
    function getNextAvailablePrimarySaleToken(uint256 _editionId) public override view returns (uint256 _tokenId) {
        uint256 maxTokenId = _maxTokenIdOfEdition(_editionId);

        // low to high
        for (uint256 tokenId = _editionId; tokenId < maxTokenId; tokenId++) {
            // if no owner set - assume primary if not moved
            if (owners[tokenId] == address(0)) {
                return tokenId;
            }
        }
        revert("No tokens left on the primary market");
    }

    /// @notice Starting from the last token in an edition and going down the first, returns the next unsold token (if any)
    function getReverseAvailablePrimarySaleToken(uint256 _editionId) public override view returns (uint256 _tokenId) {
        uint256 highestTokenId = _maxTokenIdOfEdition(_editionId) - 1;

        // high to low
        while (highestTokenId >= _editionId) {
            // if no owner set - assume primary if not moved
            if (owners[highestTokenId] == address(0)) {
                return highestTokenId;
            }
            highestTokenId--;
        }
        revert("No tokens left on the primary market");
    }

    /// @notice Using the reverse token ID logic of an edition, returns next token ID and associated royalty information
    function facilitateReversePrimarySale(uint256 _editionId)
    public
    view
    override
    returns (address receiver, address creator, uint256 tokenId) {
        require(!editionSalesDisabled[_editionId], "Edition sales disabled");

        uint256 _tokenId = getReverseAvailablePrimarySaleToken(_editionId);
        address _creator = _getCreatorOfEdition(_editionId);

        if (royaltyRegistryActive() && royaltiesRegistryProxy.hasRoyalties(_editionId)) {
            address _receiver = royaltiesRegistryProxy.getRoyaltiesReceiver(_editionId);
            return (_receiver, _creator, _tokenId);
        }

        return (_creator, _creator, _tokenId);
    }

    /// @notice If the token specified by token ID has been sold on the primary market
    function hadPrimarySaleOfToken(uint256 _tokenId) public override view returns (bool) {
        return owners[_tokenId] != address(0);
    }

    /// @notice If any token in the edition has been sold
    function hasMadePrimarySale(uint256 _editionId) validateEdition(_editionId) public override view returns (bool) {
        uint256 maxTokenId = _maxTokenIdOfEdition(_editionId);

        // low to high
        for (uint256 tokenId = _editionId; tokenId < maxTokenId; tokenId++) {
            // if no owner set - assume primary if not moved
            if (owners[tokenId] != address(0)) {
                return true;
            }
        }

        return false;
    }

    /// @notice If all tokens in the edition have been sold
    function isEditionSoldOut(uint256 _editionId) validateEdition(_editionId) public override view returns (bool) {
        uint256 maxTokenId = _maxTokenIdOfEdition(_editionId);

        // low to high
        for (uint256 tokenId = _editionId; tokenId < maxTokenId; tokenId++) {
            // if no owner set - assume primary if not moved
            if (owners[tokenId] == address(0)) {
                return false;
            }
        }

        return true;
    }

    //////////////
    // Defaults //
    //////////////

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///      checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///      `onERC721Received` on `_to` and throws if the return value is not
    ///      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) override external {
        _safeTransferFrom(_from, _to, _tokenId, _data);

        // move the token
        emit Transfer(_from, _to, _tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///      except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external {
        _safeTransferFrom(_from, _to, _tokenId, bytes(""));

        // move the token
        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        _transferFrom(_from, _to, _tokenId);

        uint256 receiverCodeSize;
        assembly {
            receiverCodeSize := extcodesize(_to)
        }
        if (receiverCodeSize > 0) {
            bytes4 selector = IERC721Receiver(_to).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                _data
            );
            require(
                selector == ERC721_RECEIVED,
                "ERC721_INVALID_SELECTOR"
            );
        }
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///         TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///         THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `_msgSender()` is the current owner, an authorized
    ///      operator, or the approved address for this NFT. Throws if `_from` is
    ///      not the current owner. Throws if `_to` is the zero address. Throws if
    ///      `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) override external {
        _transferFrom(_from, _to, _tokenId);

        // move the token
        emit Transfer(_from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) private {
        // enforce not being able to send to zero as we have explicit rules what a minted but unbound owner is
        require(_to != address(0), "ERC721_ZERO_TO_ADDRESS");

        // Ensure the owner is the sender
        address owner = _ownerOf(_tokenId, _editionFromTokenId(_tokenId));
        require(owner != address(0), "ERC721_ZERO_OWNER");
        require(_from == owner, "ERC721_OWNER_MISMATCH");

        address spender = _msgSender();
        address approvedAddress = getApproved(_tokenId);
        require(
            spender == owner // sending to myself
            || isApprovedForAll(owner, spender)  // is approved to send any behalf of owner
            || approvedAddress == spender, // is approved to move this token ID
            "ERC721_INVALID_SPENDER"
        );

        // Ensure approval for token ID is cleared
        if (approvedAddress != address(0)) {
            approvals[_tokenId] = address(0);
        }

        // set new owner - this will now override any specific other mappings for the base edition config
        owners[_tokenId] = _to;

        // Modify balances
        balances[_from] = balances[_from] - 1;
        balances[_to] = balances[_to] + 1;
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) override public view returns (address) {
        uint256 editionId = _editionFromTokenId(_tokenId);
        address owner = _ownerOf(_tokenId, editionId);
        require(owner != address(0), "ERC721_ZERO_OWNER");
        return owner;
    }

    /// @dev Newly created editions and its tokens minted to a creator don't have the owner set until the token is sold on the primary market
    /// @dev Therefore, if internally an edition exists and owner of token is zero address, then creator still owns the token
    /// @dev Otherwise, the token owner is returned or the zero address if the token does not exist
    function _ownerOf(uint256 _tokenId, uint256 _editionId) internal view returns (address) {

        // If an owner assigned
        address owner = owners[_tokenId];
        if (owner != address(0)) {
            return owner;
        }

        // fall back to edition creator
        address possibleCreator = _getCreatorOfEdition(_editionId);
        if (possibleCreator != address(0) && (_maxTokenIdOfEdition(_editionId) - 1) >= _tokenId) {
            return possibleCreator;
        }

        return address(0);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///      operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) override external {
        address owner = ownerOf(_tokenId);
        require(_approved != owner, "ERC721_APPROVED_IS_OWNER");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721_INVALID_SENDER");
        approvals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`"s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///      multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) override external {
        operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(
            _msgSender(),
            _operator,
            _approved
        );
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///      function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) override external view returns (uint256) {
        require(_owner != address(0), "ERC721_ZERO_OWNER");
        return balances[_owner];
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) override public view returns (address){
        return approvals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) override public view returns (bool){
        return operatorApprovals[_owner][_operator];
    }

    /// @notice An extension to the default ERC721 behaviour, derived from ERC-875.
    /// @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _safeTransferFrom(_from, _to, _tokenIds[i], bytes(""));
            emit Transfer(_from, _to, _tokenIds[i]);
        }
    }

    /// @notice An extension to the default ERC721 behaviour, derived from ERC-875 but using the ConsecutiveTransfer event
    /// @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
    function consecutiveBatchTransferFrom(address _from, address _to, uint256 _fromTokenId, uint256 _toTokenId) public {
        for (uint256 i = _fromTokenId; i <= _toTokenId; i++) {
            _safeTransferFrom(_from, _to, i, bytes(""));
        }
        emit ConsecutiveTransfer(_fromTokenId, _toTokenId, _from, _to);
    }

    /////////////////////
    // Admin functions //
    /////////////////////

    function setRoyaltiesRegistryProxy(IERC2981 _royaltiesRegistryProxy) onlyAdmin public {
        royaltiesRegistryProxy = _royaltiesRegistryProxy;
        emit AdminRoyaltiesRegistryProxySet(address(_royaltiesRegistryProxy));
    }

    function setTokenUriResolver(ITokenUriResolver _tokenUriResolver) onlyAdmin public {
        tokenUriResolver = _tokenUriResolver;
        emit AdminTokenUriResolverSet(address(_tokenUriResolver));
    }

    ///////////////////////
    // Creator functions //
    ///////////////////////

    /// @notice Optional metadata storage slot which allows the creator to set an additional metadata blob on the edition
    function lockInAdditionalMetaData(uint256 _editionId, string calldata _metadata) external {
        address creator = getCreatorOfEdition(_editionId);
        require(
            _msgSender() == creator || accessControls.isVerifiedArtistProxy(creator, _msgSender()),
            "Unable to set when not creator"
        );

        require(bytes(sealedEditionMetaData[_editionId]).length == 0, "can only be set once");
        sealedEditionMetaData[_editionId] = _metadata;
        emit SealedEditionMetaDataSet(_editionId);
    }

    /// @notice Optional storage slot which allows the creator to set an additional unlockable blob on the edition
    function lockInUnlockableContent(uint256 _editionId, string calldata _content) external {
        address creator = getCreatorOfEdition(_editionId);
        require(
            _msgSender() == creator || accessControls.isVerifiedArtistProxy(creator, _msgSender()),
            "Unable to set when not creator"
        );

        additionalEditionUnlockableSlot[_editionId] = _content;
        emit AdditionalEditionUnlockableSet(_editionId);
    }

    /// @notice Optional metadata storage slot which allows a token owner to set an additional metadata blob on the token
    function lockInAdditionalTokenMetaData(uint256 _tokenId, string calldata _metadata) external {
        require(
            _msgSender() == ownerOf(_tokenId) || accessControls.hasContractRole(_msgSender()),
            "Unable to set when not owner or contract"
        );
        require(bytes(sealedTokenMetaData[_tokenId]).length == 0, "can only be set once");
        sealedTokenMetaData[_tokenId] = _metadata;
        emit SealedTokenMetaDataSet(_tokenId);
    }
}