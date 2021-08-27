/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// import "./ERC1155/IERC1155.sol";


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
    function transferFrom(address sender, address recipient, uint256 amount) payable external  returns (bool);

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
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Holder.sol

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
abstract contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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
}



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

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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




/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableMap.sol
 */
library EnumerableMapper {
    struct MapEntry {
        uint256 _key;
        uint256 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        uint256 key,
        uint256 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, uint256 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, uint256 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (uint256, uint256) {
        require(map._entries.length > index, 'EnumerableMap: index out of bounds');

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, uint256 key) private view returns (uint256) {
        return _get(map, key, 'EnumerableMap: nonexistent key');
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        uint256 key,
        string memory errorMessage
    ) private view returns (uint256) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToUintMap

    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return _get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return _get(map._inner, key, errorMessage);
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
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


interface IERC721_TM is IERC721 {
  
    function _tokenUris(uint256 _typeId) external  returns (uint256);
    function safeMint(uint256 _id, address _to, uint256 _uriTemplateId) external;
    function safeBatchMint(uint256[] calldata _id, address[] calldata _to, uint256 _uriTemplateId) external;
    function safeMultipleBatchMint(uint256[] calldata _id, address[] calldata _to, uint256[] calldata _uriTemplateId) external;
}

interface IERC721_Config is IERC721_TM {
    function setSingleProperty(bytes32 _property, uint256 _id, uint256 _value) external;
    function setMultipleProperty(bytes32 _property, uint256[] calldata _id, uint256[] calldata _value) external;
    function setBatchProperty(bytes32[] calldata _property, uint256[] calldata _id, uint256[] calldata _value) external;
    function getSingleProperty(bytes32 _property, uint256 _id) external view returns (uint256 _value);
    function getMultipleProperty(bytes32 _property, uint256[] calldata _id) external view returns (uint256[] memory _value);
    // function getPower(uint256 tokenId) external view returns (uint256 power);
}


contract EsportsStaking is Ownable, ERC721Holder, Pausable {
    using SafeMath for uint256;
    using EnumerableMapper for EnumerableMapper.UintToUintMap;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    
    IERC721_Config public nft;  
    IERC20 public quoteErc20;
    address public vault;
    
    // This is a packed array of booleans. 
    mapping(uint256 => uint256) private claimedBitMap;
    event Stake(address indexed user, uint256 indexed nftId, uint256 indexed optionId);
    
    // index就是 tokenId, 查询某个nftid是否已经领取
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
    
    // index就是 tokenId, 批量查询某些nftid 是否已经领取
    function batchIsClaimed(uint256[] calldata index) public view returns (bool[] memory) {
        bool[] memory isClaimedResult = new bool[](index.length);
        
        for(uint256 n=0; n < index.length; ++n){
            isClaimedResult[n] = isClaimed(index[n]);
        }
        return isClaimedResult;
    }
    
    function _changeClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] ^ (1 << claimedBitIndex);
    }
    
    // function _batchChangeClaimed(uint256[] calldata index) private {
    //     for(uint256 n=0; n < index.length; ++n){
    //         _changeClaimed(index[n]);
    //     }
    // }
    
    // function _setClaimed(uint256 index) private {
    //     uint256 claimedWordIndex = index / 256;
    //     uint256 claimedBitIndex = index % 256;
    //     claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    // }
    
    // function _batchSetClaimed(uint256[] calldata index) private {
    //     for(uint256 n=0; n < index.length; ++n){
    //         _setClaimed(index[n]);
    //     }
    // }
    
    //比赛配置 模板
    struct raceSetting {
        uint256 prize; //奖池的金额总数
        uint256 startTime;  //比赛截止时间timestamp
        bool status; //是否已经有赛果
        uint256 startOption; //该赛事的选项起始id
        uint256 endOption; //该赛事的选项结尾id(不包含)
        uint256 winOption; //胜利的选项
    }
    
    uint256 public _optionId; //（最大）选项id，做成自增逻辑
    uint256 public _raceId; //（最大）比赛id，做成自增逻辑
    
    EnumerableSet.UintSet private settledRace;  // 记录 已有赛果的 比赛id
    mapping(uint256 => raceSetting) private _races;  // 比赛id=>比赛配置
    mapping(uint256 => uint256) public optionTotalWeight; //选项id => 该选项下 的总权重 投数
    // mapping(uint256 => uint256) public raceTotalWeight; //比赛id => 该比赛下 的总权重 投数
    
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) private optionNFTOwner; //用户地址 => 用户在该选项id下 所押 的 NFT序号
    mapping(address => mapping(uint256 => uint256)) private optionNFTOwnerWeight; //用户地址 => 用户在该选项id下 所押 的 用户 总权重 投数
    
    mapping(uint256 => EnumerableSet.AddressSet) private raceNFTOwnerClaim; //race id => 未领取过奖励的用户
    // mapping(address => mapping(uint256 => bool)) private raceNFTOwnerClaim; //用户地址 => 用户在该race id下 是否已经领取过奖励
    
    constructor(
        address _nftAddress,
        address _quoteErc20Address,
        address _masterAccount
    ) {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));
        nft = IERC721_Config(_nftAddress);
        quoteErc20 = IERC20(_quoteErc20Address);
        vault = _masterAccount;
        _optionId = 1;
        _raceId = 1;
    }
    
    function _holdRace(uint256 prize, uint256 startTime, uint256 optionNumber) private {
        _races[_raceId].prize = prize;
        _races[_raceId].startTime = startTime;
        _races[_raceId].status = false;
        
        // for(uint256 n=0; n < optionNumber; ++n){
        //     _races[_raceId].option.add(_optionId+n);
        // }
        
        _races[_raceId].startOption = _optionId;
        _races[_raceId].endOption = _optionId + optionNumber;
    }
    
    //生成 单场比赛
    function holdRace(uint256 prize, uint256 startTime, uint256 optionNumber) public onlyOwner {
        _holdRace(prize, startTime, optionNumber);
        
        _optionId = _optionId + optionNumber;
        _raceId += 1;
        
    }
    
    //批量生成比赛；临时，可优化费用
    function batchHoldRace(uint256[] calldata prizes, uint256[] calldata startTimes, uint256[] calldata optionNumbers) public onlyOwner {
        for(uint256 n=0; n < optionNumbers.length; ++n){
            holdRace(prizes[n], startTimes[n], optionNumbers[n]);
        }
    }
    
    //获得一场比赛下 起始以及结尾选项id，结尾选项不包含
    function getRaceOption(uint256 raceId) public view returns(uint256, uint256) {
        return (_races[raceId].startOption, _races[raceId].endOption);
    }
    
    //获得多场比赛下 起始以及结尾选项id, 结尾选项不包含
    function batchGetRaceOption(uint256[] calldata raceIds) public view returns(uint256[] memory, uint256[] memory) {
        uint256[] memory startOptions = new uint256[](raceIds.length);
        uint256[] memory endOptions = new uint256[](raceIds.length);
        
        for (uint256 n=0; n < raceIds.length; ++n) {
            startOptions[n] = _races[raceIds[n]].startOption;
            endOptions[n] = _races[raceIds[n]].endOption;
        } 
        return (startOptions, endOptions);
    }
    
    // 用户 投注 多个nftid 致 同一个 race下的option中
    function stake(uint256[] calldata nftIds, uint256 optionId, uint256 raceId) public {
        uint256 weight = 0;
        require(_races[raceId].startTime > block.timestamp, "race started");
        require((_races[raceId].startOption<=optionId) && (optionId <_races[raceId].endOption), "Option Race Mismatch");
        for (uint256 n=0; n < nftIds.length; ++n) {
            require(nft.ownerOf(nftIds[n])==_msgSender(), "You do not own the nft");
            
            require(!isClaimed(nftIds[n]), "nft staked already");
            _changeClaimed(nftIds[n]);
            
            weight += nft.getSingleProperty(bytes32(bytes6(0x776569676874)), nftIds[n]);
            
            optionNFTOwner[_msgSender()][optionId].add(nftIds[n]);
            
	    emit Stake(_msgSender(), nftIds[n], optionId);
        }
        
        optionTotalWeight[optionId] += weight;
        
        // raceTotalWeight[raceId] += weight;
        raceNFTOwnerClaim[raceId].add(_msgSender());
        
        optionNFTOwnerWeight[_msgSender()][optionId] += weight;
         
    }
    
     //查询比赛配置信息
     
      function raceInfo( uint256 raceId ) public view returns(uint256,uint256,uint256) {
        
        return ( _races[raceId].startTime,_races[raceId].prize, block.timestamp);
    }
     
    function batchRaceInfo( uint256[] calldata raceIds ) public view returns(uint256[] memory,uint256[] memory,uint256) {
        uint256[] memory startTimeList = new uint256[](raceIds.length);
        uint256[] memory prizeList = new uint256[](raceIds.length);
        for (uint256 m=0; m < raceIds.length; ++m) {
            startTimeList[m] = _races[raceIds[m]].startTime;
            prizeList[m] = _races[raceIds[m]].prize;
        }
        return (startTimeList,prizeList,block.timestamp);
    }
    
    
    // 查询 当前 用户某 比赛选项optionId 预估收益
    function estimateReward(address user, uint256 raceId, uint256 optionId) public view returns(uint256) {
        //require((_races[raceId].startOption<=optionId) && (optionId <_races[raceId].endOption), "Option Race Mismatch");
        if(optionNFTOwnerWeight[user][optionId] == 0){
            return 0;
        }else{
            return _races[raceId].prize.mul(optionNFTOwnerWeight[user][optionId]).div(optionTotalWeight[optionId]);
        }
        
    }
    
    // 批量查询 用户某些 比赛选项optionId 预估收益
    function batchEstimateReward(address[] calldata users, uint256[] calldata raceIds, uint256[] calldata optionIds) public view returns(uint256[] memory) {
        uint256[] memory rewards = new uint256[](users.length);
        for (uint256 n=0; n < users.length; ++n) {
            rewards[n] = estimateReward(users[n], raceIds[n], optionIds[n]);
        }
        return rewards;
    }
    
    // 查询 用户 某个选项optionId下的 投注的nft ID
    function userOptionStakeNFTids(address user, uint256 optionId) public view returns(uint256[] memory) {
        uint256[] memory nftIds = new uint256[](optionNFTOwner[user][optionId].length());
        for (uint256 n=0; n < optionNFTOwner[user][optionId].length(); ++n) {
            nftIds[n] = optionNFTOwner[user][optionId].at(n);
        }
        return nftIds;
    }
    
    // 查询 用户 某个比赛raceId下的 投注的nft ID
    function userRaceStakeNFTids(address user, uint256 raceId) public view returns(uint256[] memory){
        uint256 length = 0;
        for (uint256 n=_races[raceId].startOption; n < _races[raceId].endOption; ++n) {
            length += optionNFTOwner[user][n].length();
        }
        
        uint256[] memory nftIds = new uint256[](length);
        uint256 index = 0;
        for (uint256 n=_races[raceId].startOption; n < _races[raceId].endOption; ++n) {
            for (uint256 m=0; m < optionNFTOwner[user][n].length(); ++m) {
                nftIds[index] = optionNFTOwner[user][n].at(m);
                index += 1;
            }
            
        }
        
        return nftIds;
    }
    
    // （内部函数） 清除 记录选项投注数据 以节省空间; 无领取行为！
    function _claimRewardOptionFinalize(address user, uint256 raceId, uint256 optionId) private {
        require(raceNFTOwnerClaim[raceId].contains(user), "claimed");
        
        for (uint256 m=optionNFTOwner[user][optionId].length(); m > 0; m--) {
            
            _changeClaimed(optionNFTOwner[user][optionId].at(m-1));
            
            optionNFTOwner[user][optionId].remove(optionNFTOwner[user][optionId].at(m-1));
        }
    }
    
    //  领取 某用户 某场比赛raceId 对应的奖励 
    function _claimRewardRace(address user, uint256 raceId) private {
        quoteErc20.transferFrom(vault, user, estimateReward(user, raceId, _races[raceId].winOption));
        
        for (uint256 n=_races[raceId].startOption; n < _races[raceId].endOption; ++n) {
             _claimRewardOptionFinalize(user, raceId, n);
        }
        
        raceNFTOwnerClaim[raceId].remove(user);
        
    }
    
    //  批量 领取 用户s 比赛s 对应的奖励 ; 任何人都可以发起
    function batchClaimRewardRace(address[] calldata users, uint256 raceId) public {
        require(_races[raceId].status==true, "Race not settled yet");
        for (uint256 n=0; n < users.length; ++n) {
            _claimRewardRace(users[n], raceId);
        }
        
    }
    
    //  某场比赛 未领取的用户们
    function raceUnClaimedUser(uint256 raceId) public view returns(address[] memory){
        address[] memory users = new address[](raceNFTOwnerClaim[raceId].length());
        for (uint256 n=0; n < raceNFTOwnerClaim[raceId].length(); ++n) {
           users[n] = raceNFTOwnerClaim[raceId].at(n);
        }
        return users;
    }
    
    // 某个用户 还有哪些比赛未领取
    function userUnClaimedRace(address user) public view returns(uint256[] memory){
        uint256[] memory raceIds = new uint256[](_raceId);
        for (uint256 n=1; n < _raceId; ++n) {
           if (raceNFTOwnerClaim[n].contains(user)) {
               raceIds[n]=n;
           }
        }
        return raceIds;
    }
    
        
    // 系统外部 输入 race结果
    function settleRace(uint256 raceId, uint256 winOption) public onlyOwner {
        require((_races[raceId].startOption<=winOption) && (winOption <_races[raceId].endOption), "Option Race Mismatch");
        settledRace.add(raceId);
        _races[raceId].status = true;
        _races[raceId].winOption = winOption;
    }
    
    // 系统外部 批量输入 race结果
    function batchSettleRace(uint256[] calldata raceIds, uint256[] calldata winOptions) public onlyOwner {
        for (uint256 n=0; n < raceIds.length; ++n) {
           settleRace(raceIds[n], winOptions[n]);
        }
    }
    
    // 输入无效optionId 0 作为正确选项
    function unvalidRace(uint256 raceId) public onlyOwner {
        settledRace.add(raceId);
        _races[raceId].status = true;
        _races[raceId].winOption = 0;
    }

}