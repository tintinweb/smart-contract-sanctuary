/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

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

// File: BBTest/EnumerableSet.sol



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

// File: BBTest/IBabyBananaNFT.sol



pragma solidity ^0.8.0;

interface IBabyBananaNFT {
    function consume(uint256 tokenId, address sender) external;
    function stake(uint256 tokenId, address sender) external;
    function priceOf(uint256 tokenId) external view returns (uint256);
    function stakingRewardShareOf(uint256 tokenId, address account) external view returns (uint256);
    function featureValueOf(uint8 feature, address account) external view returns (uint256);
    function lotteryTicketsOf(address account) external view returns (uint256);
    function rewardTokenFor(address account) external view returns (address);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// File: BBTest/IERC165.sol



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
// File: BBTest/IERC1155Receiver.sol



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
// File: BBTest/IERC1155.sol



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
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

// File: BBTest/IERC1155MetadataURI.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}
// File: BBTest/BabyBananaNFT.sol



pragma solidity ^0.8.0;






contract BabyBananaNFT is IERC1155MetadataURI, IERC165, IBabyBananaNFT {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;

    struct Metadata {
        bool isStackable;
        bool isConsumable;
        bool isStakeable;
        bool isUnique;
        uint256 price;
        uint256 stakingRewardShare;
        address rewardToken;
    }
    
    // Initial features
    uint8 constant BUYBACK = 0;
    uint8 constant CHESS_GAME = 1;
    uint8 constant SPACE_CENTER = 2;
    uint8 constant TAX_DISCOUNT = 3;
    uint8 constant REWARD_BOOST = 4;
    uint8 constant REWARD_TOKEN = 5;
    uint8 constant LOTTERY_TICKET = 6;
    
    address constant BANANA = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant MULTI_SIG_TEAM_WALLET = 0x48e065F5a65C3Ba5470f75B65a386A2ad6d5ba6b;

    address public maintenanceWallet = 0xda83D3257E8880e44Cfe8e8690b9d6c283d397c6;
    address public museum = 0xD5E81e25bB36A94d64Eb844b905546Ff8f29DB8D;
    address public token;
    
    string _uri;
    EnumerableSet.UintSet _tokenIds;
    
    mapping(uint256 => mapping(uint8 => uint256)) public tokenFeatureValue;
    mapping(uint256 => Metadata) public  tokenMetadata;
    mapping(uint256 => uint256) public minted;
    mapping(uint256 => bool) public isFrozen;
    
    mapping(address => bool) _isLimitExempt; // Excluded addresses from holding limitations
    mapping(address => bool) _isHolderExempt; // Excluded addresses from perks (ignored from holders)
    mapping(uint256 => uint8[]) _tokenFeatureIds; // Helper to iterate token feature values
    mapping(uint256 => EnumerableSet.AddressSet) _holders; // Addresses that hold token
    mapping(address => EnumerableSet.UintSet) _usersTokens; // Token ids that user is holding (used to determine features and their values)
    
    mapping(uint256 => mapping(address => uint256)) _balances;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    modifier onlyMaintenance() {
        require(msg.sender == maintenanceWallet);
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == MULTI_SIG_TEAM_WALLET);
        _;
    }

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    modifier onlyMuseum() {
        require(msg.sender == museum);
        _;
    }

    constructor() {
        _setURI("https://babybanana.finance/nft/api/{id}");
        
        _isHolderExempt[ZERO] = true;
        _isLimitExempt[ZERO] = true;
        _isHolderExempt[DEAD] = true;
        _isLimitExempt[DEAD] = true;

        _isHolderExempt[maintenanceWallet] = true;
        _isLimitExempt[maintenanceWallet] = true;
    }
    
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address account, uint256 id) public view virtual override(IBabyBananaNFT, IERC1155) returns (uint256) {
        require(account != ZERO, "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(IBabyBananaNFT, IERC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(msg.sender, from, to, id, amount, data);
    }

    function _safeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != ZERO, "ERC1155: transfer to the zero address");
        
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        
        emit TransferSingle(operator, from, to, id, amount);

        if (!_isLimitExempt[to]) { _doTransferCheck(to, id); }
        _handleHolderCount(from, to, id);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(msg.sender, from, to, ids, amounts, data);
    }
    
    function _safeBatchTransferFrom(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != ZERO, "ERC1155: transfer to the zero address");
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
            
            if (!_isLimitExempt[to]) { _doTransferCheck(to, id); }
            _handleHolderCount(from, to, id);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    
    // Private helpers
    
    function _setURI(string memory newuri) private {
        _uri = newuri;
    }
    
    function _doTransferCheck(address recipient, uint256 tokenId) private view {
        if (!tokenMetadata[tokenId].isStackable) { _checkNonStackables(recipient); }
        if (tokenMetadata[tokenId].rewardToken != address(0)) { _checkRewardNFT(recipient); }
    }
    
    function _checkRewardNFT(address recipient) private view {
        for (uint256 i; i < _usersTokens[recipient].length(); i++) {
            uint256 tokenId = _usersTokens[recipient].at(i);
            require(tokenMetadata[tokenId].rewardToken == address(0), "Recipient has active reward NFT");
        }
    }
    
    function _checkNonStackables(address recipient) private view {
        for (uint256 i; i < _usersTokens[recipient].length(); i++) {
            uint256 tokenId = _usersTokens[recipient].at(i);
            require(tokenMetadata[tokenId].isStackable, "Recipient has non-stackable NFT");
        }
    }
    
    function _handleHolderCount(address sender, address recipient, uint256 tokenId) private {
        bool isEmptyWallet = _balances[tokenId][sender] == 0;
        if (isEmptyWallet) { _holders[tokenId].remove(sender); _usersTokens[sender].remove(tokenId); }
        
        bool hasToken = _balances[tokenId][recipient] > 0;
        if (!_isHolderExempt[recipient] && hasToken) { _holders[tokenId].add(recipient); _usersTokens[recipient].add(tokenId); }
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    
    // Custom interface

    function consume(uint256 tokenId, address sender) external override onlyToken {
        require(tokenMetadata[tokenId].isConsumable, "Token is not consumable");
        
        _safeTransferFrom(sender, sender, DEAD, tokenId, 1, "");
    }

    function stake(uint256 tokenId, address sender) external override onlyMuseum {
        require(tokenMetadata[tokenId].isStakeable, "Token is not stakeable");

        _safeTransferFrom(sender, sender, museum, tokenId, 1, "");
    }

    function priceOf(uint256 tokenId) external view override returns (uint256) {
        return tokenMetadata[tokenId].price;
    }

    function stakingRewardShareOf(uint256 tokenId, address account) external view override returns (uint256) {
        if (_isHolderExempt[account]) { return 0; }

        for (uint256 i; i < _usersTokens[account].length(); i++) {
            uint256 id = _usersTokens[account].at(i);
            if (tokenId == id) { return tokenMetadata[tokenId].stakingRewardShare; }
        }

        return 0;
    }
    
    function featureValueOf(uint8 featureId, address account) public view override returns (uint256) {
        if (_isHolderExempt[account]) { return 0; }

        uint256 largestFeatureValue;
        for (uint256 i; i < _usersTokens[account].length(); i++) {
            uint256 tokenId = _usersTokens[account].at(i);

            for (uint256 j; j < _tokenFeatureIds[tokenId].length; j++) {
                uint8 feature = _tokenFeatureIds[tokenId][j];
                uint256 featureValue = tokenFeatureValue[tokenId][feature];
                if (feature == featureId && featureValue > largestFeatureValue) {
                    largestFeatureValue = featureValue; 
                }
            }
        }
        
        return largestFeatureValue;
    }

    function lotteryTicketsOf(address account) external view override returns (uint256) {
        if (_isHolderExempt[account]) { return 0; }

        uint256 lotteryTickets;
        for (uint256 i; i < _usersTokens[account].length(); i++) {
            uint256 tokenId = _usersTokens[account].at(i);

            for (uint256 j; j < _tokenFeatureIds[tokenId].length; j++) {
                uint8 feature = _tokenFeatureIds[tokenId][j];
                if (feature == LOTTERY_TICKET) { lotteryTickets += tokenFeatureValue[tokenId][feature]; }
            }
        }
        
        return lotteryTickets;
    }

    function rewardTokenFor(address account) external view override returns (address) {
        if (_isHolderExempt[account]) { return BANANA; }

        for (uint256 i; i < _usersTokens[account].length(); i++) {
            uint256 tokenId = _usersTokens[account].at(i);
            address rewardToken = tokenMetadata[tokenId].rewardToken;
            if (rewardToken != address(0)) { return rewardToken; }
        }

        return BANANA;
    }
    
    function createdTokensAmount() external view returns (uint256) {
        return _tokenIds.length();
    }

    // Helpers to iterate token holders
    
    function tokenHoldersAmount(uint256 tokenId) external view returns (uint256) {
        return _holders[tokenId].length();
    }
    
    function tokenHolder(uint256 tokenId, uint256 index) external view returns (address) {
        return _holders[tokenId].at(index);
    }

    // Helpers to iterate token feature ids

    function tokenFeatureIdsAmount(uint256 tokenId) external view returns (uint256) {
        return _tokenFeatureIds[tokenId].length;
    }

    function tokenFeatureId(uint256 tokenId, uint256 index) external view returns (uint8) {
        return _tokenFeatureIds[tokenId][index];
    }

    // Helpers to iterate tokens that user hold

    function userTokensAmount(address account) external view returns (uint256) {
        return _usersTokens[account].length();
    }

    function userToken(address account, uint256 index) external view returns (uint256) {
        return _usersTokens[account].at(index);
    }
    
    // Team

    function setURI(string memory newUri) external onlyTeam {
        _uri = newUri;
    }

    function updateMaintenanceWallet(address newAddress) external onlyTeam {
        _isHolderExempt[maintenanceWallet] = false;
        _isLimitExempt[maintenanceWallet] = false;
        _isHolderExempt[newAddress] = true;
        _isLimitExempt[newAddress] = true;
        maintenanceWallet = newAddress;
    }

    function updateMuseum(address newMuseum) external onlyTeam {
        museum = newMuseum;
    }

    function updateToken(address newToken) external onlyTeam {
        token = newToken;
    }

    function setLimitExempt(address account, bool exempt) external onlyTeam {
        require(account != maintenanceWallet && account != ZERO && account != DEAD, "Unauthorized parameter address");
        
        _isLimitExempt[account] = exempt;
    }
    
    /**
     * @notice Use with caution because account is not automatically added back to holder with perks.
    */
    function setHolderExempt(address account, bool exempt) external onlyTeam {
        require(account != maintenanceWallet && account != ZERO && account != DEAD, "Unauthorized parameter address");
        
        if (exempt) {
            for (uint256 i; i < _tokenIds.length(); i++) {
                _holders[_tokenIds.at(i)].remove(account);
                _usersTokens[account].remove(_tokenIds.at(i));
            }
        }
        
        _isHolderExempt[account] = exempt;
    }

    // Maintenance

    function updateFeatureValue(uint256 tokenId, uint8 featureId, uint256 newValue) external onlyMaintenance {
        require(_tokenIds.contains(tokenId), "Token id doesn't exist");
        
        bool hasFeatureId;
        for (uint256 i; i < _tokenFeatureIds[tokenId].length; i++) {
            uint8 feature = _tokenFeatureIds[tokenId][i];
            if (feature == featureId) { hasFeatureId = true; }
        }
        require(hasFeatureId, "Token doesn't have feature");
        
        tokenFeatureValue[tokenId][featureId] = newValue;
    }

    function updateStakingRewardShare(uint256 tokenId, uint256 newShare) external onlyMaintenance {
        require(_tokenIds.contains(tokenId), "Token id doesn't exist");

        tokenMetadata[tokenId].stakingRewardShare = newShare;
    }

    function setTokenPrice(uint256 tokenId, uint256 newPrice) external onlyMaintenance {
        require(_tokenIds.contains(tokenId), "Token id doesn't exist");

        tokenMetadata[tokenId].price = newPrice;
    }

    function freezeMinting(uint256 tokenId) external onlyMaintenance {
        isFrozen[tokenId] = true;
    }

    // Creation

    /**
     * @notice Create new token for this collection.
     * @notice Marketing still need to mint tokens separately.
     * @notice Calling of this function is limited to maintenance wallet.
     * @param tokenId Token id to be added in the collection.
     * @param metadata Token metadata.
     * @param featureIds List of feature ids to be added as a token features.
     * @param featureValues List of feature values.
    */
    function addToken(
        uint256 tokenId,
        Metadata calldata metadata,
        uint8[] calldata featureIds,
        uint256[] calldata featureValues
    ) public onlyMaintenance {
        require(minted[tokenId] == 0, "Can't modify minted tokens");
        require(!_tokenIds.contains(tokenId), "Token id is already created");
        require(featureIds.length == featureValues.length, "Parameter length mismatch");
        
        _tokenIds.add(tokenId);
        tokenMetadata[tokenId] = metadata;
        if (metadata.isConsumable) { require(featureIds.length == 1, "Consumable can't have many perks"); }
        
        for (uint256 i; i < featureIds.length; i++) {
            uint8 featureId = featureIds[i];
            _tokenFeatureIds[tokenId].push(featureId);
            tokenFeatureValue[tokenId][featureId] = featureValues[i];
        }
    }

    /**
     * @notice Same as addToken, but add multiple token configs at once.
     * @notice Marketing still need to mint tokens separately.
     * @notice Calling of this function is limited to maintenance wallet.
     * @param tokenIds List of token ids to be added in the collection.
     * @param metadatas List of token metadatas.
     * @param arrayOffeatureIds Multidimensional array of feature ids.
     * @param arrayOfFeatureValues Multidimensional array of feature values.
    */
    function addTokenBatch(
        uint256[] calldata tokenIds,
        Metadata[] calldata metadatas,
        uint8[][] calldata arrayOffeatureIds,
        uint256[][] calldata arrayOfFeatureValues
    ) external onlyMaintenance {
        bool validParametersLengths = tokenIds.length == metadatas.length && 
            metadatas.length == arrayOffeatureIds.length &&
            arrayOffeatureIds.length == arrayOfFeatureValues.length;
        require(validParametersLengths, "Parameter length mismatch");

        for (uint256 i; i < tokenIds.length; i++) {
            addToken(tokenIds[i], metadatas[i], arrayOffeatureIds[i], arrayOfFeatureValues[i]);
        }
    }
    
    /**
     * @notice Remove token from this collection.
     * @notice Token to be removed must have been created before removal.
     * @notice Minted tokens cannot be removed.
     * @notice Calling of this function is limited to maintenance wallet.
     * @param tokenId Id of the token to be removed.
    */
    function removeToken(uint256 tokenId) external onlyMaintenance {
        require(_tokenIds.contains(tokenId), "Token id doesn't exist");
        require(minted[tokenId] == 0, "Can't modify minted tokens");
        
        _tokenIds.remove(tokenId);
        
        for (uint256 i; i < _tokenFeatureIds[tokenId].length; i++) {
            uint8 featureId = _tokenFeatureIds[tokenId][i];
            delete tokenFeatureValue[tokenId][featureId];
        }
        
        delete _tokenFeatureIds[tokenId];
        delete tokenMetadata[tokenId];
    }

    /**
     * @notice Mint new NFTs. Passed id must be created by calling addToken before minting.
     * @notice Minter doesn't gain any perks of the NFTs.
     * @notice Calling of this function is limited to maintenance wallet.
     * @param id Id of the token to be minted.
     * @param amount Amount of tokens to be minted.
    */
    function mint(uint256 id, uint256 amount) external onlyMaintenance {
        require(_tokenIds.contains(id), "Token id doesn't exist");
        require(!isFrozen[id], "Token id is frozen from minting");
        
        if (tokenMetadata[id].isUnique) { require(minted[id] == 0 && amount == 1, "Can't mint more than 1 NFT"); }
        minted[id] += amount;

        _balances[id][msg.sender] += amount;
        emit TransferSingle(msg.sender, ZERO, msg.sender, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, ZERO, msg.sender, id, amount, "");
    }

    /**
     * @notice Same as mint function, but mint multiple NFTs at once.
     * @notice Minter doesn't gain any perks of the NFTs.
     * @notice Both parameters MUST have same length.
     * @notice Calling of this function is limited to maintenance wallet.
     * @param ids List of ids of tokens to be minted.
     * @param amounts List of amounts of tokens to be minted.
    */
    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyMaintenance {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            require(_tokenIds.contains(id), "Token id doesn't exist");
            require(!isFrozen[id], "Token id is frozen from minting");
            
            if (tokenMetadata[id].isUnique) { require(minted[id] == 0 && amount == 1, "Can't mint more than 1 NFT"); }
            minted[id] += amount;
            _balances[id][msg.sender] += amount;
        }

        emit TransferBatch(msg.sender, ZERO, msg.sender, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, ZERO, msg.sender, ids, amounts, "");
    }
}