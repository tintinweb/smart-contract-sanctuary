/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.6;



// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/EnumerableMap

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
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
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
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
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
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
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
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
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// Part: OpenZeppelin/[email protected]/EnumerableSet

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC721Receiver

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

// Part: OpenZeppelin/[email protected]/SafeMath

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Part: OpenZeppelin/[email protected]/Strings

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// Part: smartcontractkit/[email protected]/LinkTokenInterface

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/SafeMathChainlink

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// Part: smartcontractkit/[email protected]/VRFRequestIDBase

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// Part: OpenZeppelin/[email protected]/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
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

// Part: OpenZeppelin/[email protected]/IERC721

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

// Part: OpenZeppelin/[email protected]/Ownable

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// Part: smartcontractkit/[email protected]/VRFConsumerBase

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// Part: OpenZeppelin/[email protected]/IERC721Enumerable

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

// Part: OpenZeppelin/[email protected]/IERC721Metadata

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Part: PokemonBaseStatData

contract PokemonBaseStatData is Ownable {

    mapping(string => PokemonBaseStats) public pokemonNameToPokemonBaseStats;
    string[] public listOfPokemonNames;

    struct PokemonBaseStats {
        uint256 hp;
        uint256 atk;
        uint256 def;
        uint256 spa;
        uint256 spd;
        uint256 spe;
        string type1;
        string type2;
        uint256 number; 
        string pokemonName;
    }

    constructor()
    public 
    {
        createBaseStatPokemon(1,"Bulbasaur","Grass","Poison",318,45,49,49,65,65,45);
        createBaseStatPokemon(2,"Ivysaur","Grass","Poison",405,60,62,63,80,80,60);
        createBaseStatPokemon(3,"Venusaur","Grass","Poison",525,80,82,83,100,100,80);
        // createBaseStatPokemon(3,"Mega Venusaur","Grass","Poison",625,80,100,123,122,120,80);
        // createBaseStatPokemon(3,"Gigantamax Venusaur","Grass","Poison",525,80,82,83,100,100,80);
        // createBaseStatPokemon(4,"Charmander","Fire","None",309,39,52,43,60,50,65);
        // createBaseStatPokemon(5,"Charmeleon","Fire","None",405,58,64,58,80,65,80);
        // createBaseStatPokemon(6,"Charizard","Fire","Flying",534,78,84,78,109,85,100);
        // createBaseStatPokemon(6,"Mega Charizard x","Fire","Dragon",634,78,130,111,130,85,100);
        // createBaseStatPokemon(6,"Mega Charizard y","Fire","Flying",634,78,104,78,159,115,100);
        // createBaseStatPokemon(6,"Gigantamax Charizard","Fire","Flying",534,78,84,78,109,85,100);
        // createBaseStatPokemon(7,"Squirtle","Water","None",314,44,48,65,50,64,43);
        // createBaseStatPokemon(8,"Wartortle","Water","None",405,59,63,80,65,80,58);
        // createBaseStatPokemon(9,"Blastoise","Water","None",530,79,83,100,85,105,78);
        // createBaseStatPokemon(9,"Mega Blastoise","Water","None",630,79,103,120,135,115,78);
        // createBaseStatPokemon(9,"Gigantamax Blasoise","Blastoise","Water",530,79,83,100,85,105,78);
        // createBaseStatPokemon(10,"Caterpie","Bug","None",195,45,30,35,20,20,45);
        // createBaseStatPokemon(11,"Metapod","Bug","None",205,50,20,55,25,25,30);
        // createBaseStatPokemon(12,"Butterfree","Bug","Flying",395,60,45,50,90,80,70);
        // createBaseStatPokemon(12,"Gigantamax Butterfree","Bug","Flying",395,60,45,50,90,80,70);
        // createBaseStatPokemon(13,"Weedle","Bug","Poison",195,40,35,30,20,20,50);
        // createBaseStatPokemon(14,"Kakuna","Bug","Poison",205,45,25,50,25,25,35);
        // createBaseStatPokemon(15,"Beedrill","Bug","Poison",395,65,90,40,45,80,75);
        // createBaseStatPokemon(15,"Mega Beedrill","Bug","Poison",495,65,150,40,15,80,145);
        // createBaseStatPokemon(16,"Pidgey","Normal","Flying",251,40,45,40,35,35,56);
        // createBaseStatPokemon(17,"Pidgeotto","Normal","Flying",349,63,60,55,50,50,71);
        // createBaseStatPokemon(18,"Pidgeot","Normal","Flying",479,83,80,75,70,70,101);
        // createBaseStatPokemon(18,"Mega Pidgeot","Normal","Flying",579,83,80,80,135,80,121);
        // createBaseStatPokemon(19,"Rattata","Normal","None",253,30,56,35,25,35,72);
        // createBaseStatPokemon(19,"Alolan Rattata","Dark","Normal",253,30,56,35,25,35,72);
        // createBaseStatPokemon(20,"Raticate","Normal","None",413,55,81,60,50,70,97);
        // createBaseStatPokemon(20,"Alolan Raticate","Dark","Normal",413,75,71,70,40,80,77);
        // createBaseStatPokemon(21,"Spearow","Normal","Flying",262,40,60,30,31,31,70);
        // createBaseStatPokemon(22,"Fearow","Normal","Flying",442,65,90,65,61,61,100);
        // createBaseStatPokemon(23,"Ekans","Poison","None",288,35,60,44,40,54,55);
        // createBaseStatPokemon(24,"Arbok","Poison","None",438,60,85,69,65,79,80);
        // createBaseStatPokemon(25,"Pikachu","Electric","None",320,35,55,40,50,50,90);
        // createBaseStatPokemon(25,"Gigantamax Pikachu","Electric","None",320,35,55,40,50,50,90);
        // createBaseStatPokemon(26,"Raichu","Electric","None",485,60,90,55,90,80,110);
        // createBaseStatPokemon(26,"Alolan Raichu","Electric","Psychic",485,60,85,50,95,85,110);
        // createBaseStatPokemon(27,"Sandshrew","Ground","None",300,50,75,85,20,30,40);
        // createBaseStatPokemon(27,"Alolan Sandshrew","Ice","Steel",300,50,75,90,10,35,40);
        // createBaseStatPokemon(28,"Sandslash","Ground","None",450,75,100,110,45,55,65);
        // createBaseStatPokemon(28,"Alolan Sandslash","Ice","Steel",450,75,100,120,25,65,65);
        // createBaseStatPokemon(29,"Nidoran♀","Poison","None",275,55,47,52,40,40,41);
        // createBaseStatPokemon(30,"Nidorina","Poison","None",365,70,62,67,55,55,56);
        // createBaseStatPokemon(31,"Nidoqueen","Poison","Ground",505,90,92,87,75,85,76);
        // createBaseStatPokemon(32,"Nidoran♂","Poison","None",273,46,57,40,40,40,50);
        // createBaseStatPokemon(33,"Nidorino","Poison","None",365,61,72,57,55,55,65);
        // createBaseStatPokemon(34,"Nidoking","Poison","Ground",505,81,102,77,85,75,85);
        // createBaseStatPokemon(35,"Clefairy","Fairy","None",323,70,45,48,60,65,35);
        // createBaseStatPokemon(36,"Clefable","Fairy","None",483,95,70,73,95,90,60);
        // createBaseStatPokemon(37,"Vulpix","Fire","None",299,38,41,40,50,65,65);
        // createBaseStatPokemon(37,"Alolan Vulpix","Ice","None",299,38,41,40,50,65,65);
        // createBaseStatPokemon(38,"Ninetales","Fire","None",505,73,76,75,81,100,100);
        // createBaseStatPokemon(38,"Alolan Ninetales","Ice","Fairy",505,73,67,75,81,100,109);
        // createBaseStatPokemon(39,"Jigglypuff","Normal","Fairy",270,115,45,20,45,25,20);
        // createBaseStatPokemon(40,"Wigglytuff","Normal","Fairy",435,140,70,45,85,50,45);
        // createBaseStatPokemon(41,"Zubat","Poison","Flying",245,40,45,35,30,40,55);
        // createBaseStatPokemon(42,"Golbat","Poison","Flying",455,75,80,70,65,75,90);
        // createBaseStatPokemon(43,"Oddish","Grass","Poison",320,45,50,55,75,65,30);
        // createBaseStatPokemon(44,"Gloom","Grass","Poison",395,60,65,70,85,75,40);
        // createBaseStatPokemon(45,"Vileplume","Grass","Poison",490,75,80,85,110,90,50);
        // createBaseStatPokemon(46,"Paras","Bug","Grass",285,35,70,55,45,55,25);
        // createBaseStatPokemon(47,"Parasect","Bug","Grass",405,60,95,80,60,80,30);
        // createBaseStatPokemon(48,"Venonat","Bug","Poison",305,60,55,50,40,55,45);
        // createBaseStatPokemon(49,"Venomoth","Bug","Poison",450,70,65,60,90,75,90);
        // createBaseStatPokemon(50,"Diglett","Ground","None",265,10,55,25,35,45,95);
        // createBaseStatPokemon(50,"Alolan Diglett","Ground","Steel",265,10,55,30,35,45,90);
        // createBaseStatPokemon(51,"Dugtrio","Ground","None",405,35,80,50,50,70,120);
        // createBaseStatPokemon(51,"Alolan Dugtrio","Ground","Steel",425,35,100,60,50,70,110);
        // createBaseStatPokemon(52,"Meowth","Normal","None",290,40,45,35,40,40,90);
        // createBaseStatPokemon(53,"Gigantamax Meowth","Normal","None",290,40,45,35,40,40,90);
        // createBaseStatPokemon(52,"Alolan Meowth","Dark","None",290,40,35,35,50,40,90);
        // createBaseStatPokemon(52,"Galarian Meowth","Steel","None",290,50,65,55,40,40,40);
        // createBaseStatPokemon(53,"Persian","Normal","None",440,65,70,60,65,65,115);
        // createBaseStatPokemon(53,"Alolan Persian","Dark","None",440,65,60,60,75,65,115);
        // createBaseStatPokemon(54,"Psyduck","Water","None",320,50,52,48,65,50,55);
        // createBaseStatPokemon(55,"Golduck","Water","None",500,80,82,78,95,80,85);
        // createBaseStatPokemon(56,"Mankey","Fighting","None",305,40,80,35,35,45,70);
        // createBaseStatPokemon(57,"Primeape","Fighting","None",455,65,105,60,60,70,95);
        // createBaseStatPokemon(58,"Growlithe","Fire","None",350,55,70,45,70,50,60);
        // createBaseStatPokemon(59,"Arcanine","Fire","None",555,90,110,80,100,80,95);
        // createBaseStatPokemon(60,"Poliwag","Water","None",300,40,50,40,40,40,90);
        // createBaseStatPokemon(61,"Poliwhirl","Water","None",385,65,65,65,50,50,90);
        // createBaseStatPokemon(62,"Poliwrath","Water","Fighting",510,90,95,95,70,90,70);
        // createBaseStatPokemon(63,"Abra","Psychic","None",310,25,20,15,105,55,90);
        // createBaseStatPokemon(64,"Kadabra","Psychic","None",400,40,35,30,120,70,105);
        // createBaseStatPokemon(65,"Alakazam","Psychic","None",500,55,50,45,135,95,120);
        // createBaseStatPokemon(65,"Mega Alakazam","Psychic","None",590,55,50,65,175,95,150);
        // createBaseStatPokemon(66,"Machop","Fighting","None",305,70,80,50,35,35,35);
        // createBaseStatPokemon(67,"Machoke","Fighting","None",405,80,100,70,50,60,45);
        // createBaseStatPokemon(68,"Machamp","Fighting","None",505,90,130,80,65,85,55);
        // createBaseStatPokemon(68,"Gigantamax Machamp","Fighting","None",505,90,130,80,65,85,55);
        // createBaseStatPokemon(69,"Bellsprout","Grass","Poison",300,50,75,35,70,30,40);
        // createBaseStatPokemon(70,"Weepinbell","Grass","Poison",390,65,90,50,85,45,55);
        // createBaseStatPokemon(71,"Victreebel","Grass","Poison",490,80,105,65,100,70,70);
        // createBaseStatPokemon(72,"Tentacool","Water","Poison",335,40,40,35,50,100,70);
        // createBaseStatPokemon(73,"Tentacruel","Water","Poison",515,80,70,65,80,120,100);
        // createBaseStatPokemon(74,"Geodude","Rock","Ground",300,40,80,100,30,30,20);
        // createBaseStatPokemon(74,"Alolan Geodude","Rock","Electric",300,40,80,100,30,30,20);
        // createBaseStatPokemon(75,"Graveler","Rock","Ground",390,55,95,115,45,45,35);
        // createBaseStatPokemon(75,"Alolan Graveler","Rock","Electric",390,55,95,115,45,45,35);
        // createBaseStatPokemon(76,"Golem","Rock","Ground",495,80,120,130,55,65,45);
        // createBaseStatPokemon(76,"Alolan Golem","Rock","Electric",495,80,120,130,55,65,45);
        // createBaseStatPokemon(77,"Ponyta","Fire","None",410,50,85,55,65,65,90);
        // createBaseStatPokemon(77,"Galarian Ponyta","Psychic","Fairy",410,50,85,55,65,65,90);
        // createBaseStatPokemon(78,"Rapidash","Fire","None",500,65,100,70,80,80,105);
        // createBaseStatPokemon(78,"Galarian Rapidash","Psychic","Fairy",500,65,100,70,80,80,105);
        // createBaseStatPokemon(79,"Slowpoke","Water","Psychic",315,90,65,65,40,40,15);
        // createBaseStatPokemon(79,"Galarian Slowpoke","Psychic","None",315,90,65,65,40,40,15);
        // createBaseStatPokemon(80,"Slowbro","Water","Psychic",490,95,75,110,100,80,30);
        // createBaseStatPokemon(80,"Galarian Slowbro","Poison","Psychic",490,95,100,95,100,70,30);
        // createBaseStatPokemon(80,"Mega Slowbro","Water","Psychic",590,95,75,180,130,80,30);
        // createBaseStatPokemon(81,"Magnemite","Electric","Steel",325,25,35,70,95,55,45);
        // createBaseStatPokemon(82,"Magneton","Electric","Steel",465,50,60,95,120,70,70);
        // createBaseStatPokemon(83,"Farfetch'd","Normal","Flying",352,52,90,55,58,62,60);
        // createBaseStatPokemon(83,"Galarian Farfetched","Fighting","None",377,52,95,55,58,62,55);
        // createBaseStatPokemon(84,"Doduo","Normal","Flying",310,35,85,45,35,35,75);
        // createBaseStatPokemon(85,"Dodrio","Normal","Flying",460,60,110,70,60,60,100);
        // createBaseStatPokemon(86,"Seel","Water","None",325,65,45,55,45,70,45);
        // createBaseStatPokemon(87,"Dewgong","Water","Ice",475,90,70,80,70,95,70);
        // createBaseStatPokemon(88,"Grimer","Poison","None",325,80,80,50,40,50,25);
        // createBaseStatPokemon(88,"Alolan Grimer","Poison","Dark",325,80,80,50,40,50,25);
        // createBaseStatPokemon(89,"Muk","Poison","None",500,105,105,75,65,100,50);
        // createBaseStatPokemon(89,"Alolan Muk","Poison","Dark",500,105,105,75,65,100,50);
        // createBaseStatPokemon(90,"Shellder","Water","None",305,30,65,100,45,25,40);
        // createBaseStatPokemon(91,"Cloyster","Water","Ice",525,50,95,180,85,45,70);
        // createBaseStatPokemon(92,"Gastly","Ghost","Poison",310,30,35,30,100,35,80);
        // createBaseStatPokemon(93,"Haunter","Ghost","Poison",405,45,50,45,115,55,95);
        // createBaseStatPokemon(94,"Gengar","Ghost","Poison",500,60,65,60,130,75,110);
        // createBaseStatPokemon(94,"Mega Gengar","Ghost","Poison",600,60,65,80,170,95,130);
        // createBaseStatPokemon(94,"Gigantamax Gengar","Ghost","Poison",500,60,65,60,130,75,110);
        // createBaseStatPokemon(95,"Onix","Rock","Ground",385,35,45,160,30,45,70);
        // createBaseStatPokemon(96,"Drowzee","Psychic","None",328,60,48,45,43,90,42);
        // createBaseStatPokemon(97,"Hypno","Psychic","None",483,85,73,70,73,115,67);
        // createBaseStatPokemon(98,"Krabby","Water","None",325,30,105,90,25,25,50);
        // createBaseStatPokemon(99,"Kingler","Water","None",475,55,130,115,50,50,75);
        // createBaseStatPokemon(99,"Gigantamax Kingler","Water","None",475,55,130,115,50,50,75);
        // createBaseStatPokemon(100,"Voltorb","Electric","None",330,40,30,50,55,55,100);
        // createBaseStatPokemon(101,"Electrode","Electric","None",480,60,50,70,80,80,140);
        // createBaseStatPokemon(102,"Exeggcute","Grass","Psychic",325,60,40,80,60,45,40);
        // createBaseStatPokemon(103,"Exeggutor","Grass","Psychic",520,95,95,85,125,65,55);
        // createBaseStatPokemon(103,"Alolan Exeggutor","Grass","Dragon",530,95,105,85,125,75,45);
        // createBaseStatPokemon(104,"Cubone","Ground","None",320,50,50,95,40,50,35);
        // createBaseStatPokemon(105,"Marowak","Ground","None",425,60,80,110,50,80,45);
        // createBaseStatPokemon(105,"Alolan Marowak","Fire","Ghost",425,60,80,110,50,80,45);
        // createBaseStatPokemon(106,"Hitmonlee","Fighting","None",455,50,120,53,35,110,87);
        // createBaseStatPokemon(107,"Hitmonchan","Fighting","None",455,50,105,79,35,110,76);
        // createBaseStatPokemon(108,"Lickitung","Normal","None",385,90,55,75,60,75,30);
        // createBaseStatPokemon(109,"Koffing","Poison","None",340,40,65,95,60,45,35);
        // createBaseStatPokemon(110,"Weezing","Poison","None",490,65,90,120,85,70,60);
        // createBaseStatPokemon(110,"Galarian Weezing","Poison","Fairy",490,65,90,120,85,70,60);
        // createBaseStatPokemon(111,"Rhyhorn","Ground","Rock",345,80,85,95,30,30,25);
        // createBaseStatPokemon(112,"Rhydon","Ground","Rock",485,105,130,120,45,45,40);
        // createBaseStatPokemon(113,"Chansey","Normal","None",450,250,5,5,35,105,50);
        // createBaseStatPokemon(114,"Tangela","Grass","None",435,65,55,115,100,40,60);
        // createBaseStatPokemon(115,"Kangaskhan","Normal","None",490,105,95,80,40,80,90);
        // createBaseStatPokemon(115,"Mega Kangaskhan","Normal","None",590,105,125,100,60,100,100);
        // createBaseStatPokemon(116,"Horsea","Water","None",295,30,40,70,70,25,60);
        // createBaseStatPokemon(117,"Seadra","Water","None",440,55,65,95,95,45,85);
        // createBaseStatPokemon(118,"Goldeen","Water","None",320,45,67,60,35,50,63);
        // createBaseStatPokemon(119,"Seaking","Water","None",450,80,92,65,65,80,68);
        // createBaseStatPokemon(120,"Staryu","Water","None",340,30,45,55,70,55,85);
        // createBaseStatPokemon(121,"Starmie","Water","Psychic",520,60,75,85,100,85,115);
        // createBaseStatPokemon(122,"Mr. Mime","Psychic","Fairy",460,40,45,65,100,120,90);
        // createBaseStatPokemon(122,"Galarian Mr. Mime","Ice","Psychic",460,50,65,65,90,90,100);
        // createBaseStatPokemon(123,"Scyther","Bug","Flying",500,70,110,80,55,80,105);
        // createBaseStatPokemon(124,"Jynx","Ice","Psychic",455,65,50,35,115,95,95);
        // createBaseStatPokemon(125,"Electabuzz","Electric","None",490,65,83,57,95,85,105);
        // createBaseStatPokemon(126,"Magmar","Fire","None",495,65,95,57,100,85,93);
        // createBaseStatPokemon(127,"Pinsir","Bug","None",500,65,125,100,55,70,85);
        // createBaseStatPokemon(127,"Mega Pinsir","Bug","Flying",600,65,155,120,65,90,105);
        // createBaseStatPokemon(128,"Tauros","Normal","None",490,75,100,95,40,70,110);
        // createBaseStatPokemon(129,"Magikarp","Water","None",200,20,10,55,15,20,80);
        // createBaseStatPokemon(130,"Gyarados","Water","Flying",540,95,125,79,60,100,81);
        // createBaseStatPokemon(130,"Mega Gyarados","Water","Dark",640,95,155,109,70,130,81);
        // createBaseStatPokemon(131,"Lapras","Water","Ice",535,130,85,80,85,95,60);
        // createBaseStatPokemon(131,"Gigantamax Lapras","Water","Ice",535,130,85,80,85,95,60);
        // createBaseStatPokemon(132,"Ditto","Normal","None",288,48,48,48,48,48,48);
        // createBaseStatPokemon(133,"Eevee","Normal","None",325,55,55,50,45,65,55);
        // createBaseStatPokemon(133,"Gigantamax Eevee","Normal","None",325,55,55,50,45,65,55);
        // createBaseStatPokemon(134,"Vaporeon","Water","None",525,130,65,60,110,95,65);
        // createBaseStatPokemon(135,"Jolteon","Electric","None",525,65,65,60,110,95,130);
        // createBaseStatPokemon(136,"Flareon","Fire","None",525,65,130,60,95,110,65);
        // createBaseStatPokemon(137,"Porygon","Normal","None",395,65,60,70,85,75,40);
        // createBaseStatPokemon(138,"Omanyte","Rock","Water",355,35,40,100,90,55,35);
        // createBaseStatPokemon(139,"Omastar","Rock","Water",495,70,60,125,115,70,55);
        // createBaseStatPokemon(140,"Kabuto","Rock","Water",355,30,80,90,55,45,55);
        // createBaseStatPokemon(141,"Kabutops","Rock","Water",495,60,115,105,65,70,80);
        // createBaseStatPokemon(142,"Aerodactyl","Rock","Flying",515,80,105,65,60,75,130);
        // createBaseStatPokemon(142,"Mega Aerodactyl","Rock","Flying",615,80,135,85,70,95,150);
        // createBaseStatPokemon(143,"Snorlax","Normal","None",540,160,110,65,65,110,30);
        // createBaseStatPokemon(143,"Gigantamax Snorlax","Normal","None",540,160,110,65,65,110,30);
        // createBaseStatPokemon(144,"Articuno","Ice","Flying",580,90,85,100,95,125,85);
        // createBaseStatPokemon(144,"Galarian Articuno","Psychic","Flying",580,90,85,85,125,100,95);
        // createBaseStatPokemon(145,"Zapdos","Electric","Flying",580,90,90,85,125,90,100);
        // createBaseStatPokemon(145,"Galarian Zapdos","Fighting","Flying",580,90,125,90,85,90,100);
        // createBaseStatPokemon(146,"Moltres","Fire","Flying",580,90,100,90,125,85,90);
        // createBaseStatPokemon(146,"Galarian Moltres","Dark","Flying",580,90,85,90,100,125,90);
        // createBaseStatPokemon(147,"Dratini","Dragon","None",300,41,64,45,50,50,50);
        // createBaseStatPokemon(148,"Dragonair","Dragon","None",420,61,84,65,70,70,70);
        // createBaseStatPokemon(149,"Dragonite","Dragon","Flying",600,91,134,95,100,100,80);
        // createBaseStatPokemon(150,"Mewtwo","Psychic","None",680,106,110,90,154,90,130);
        // createBaseStatPokemon(150,"Mega Mewtwo x","Psychic","Fighting",780,106,190,100,154,100,130);
        // createBaseStatPokemon(150,"Mega Mewtwo y","Psychic","None",780,106,150,70,194,120,140);
        // createBaseStatPokemon(151,"Mew","Psychic","None",600,100,100,100,100,100,100);





        // createBaseStatPokemon(152,"Chikorita","Grass","None",318,45,49,65,49,65,45);
        // createBaseStatPokemon(153,"Bayleef","Grass","None",405,60,62,80,63,80,60);
        // createBaseStatPokemon(154,"Meganium","Grass","None",525,80,82,100,83,100,80);
        // createBaseStatPokemon(155,"Cyndaquil","Fire","None",309,39,52,43,60,50,65);
        // createBaseStatPokemon(156,"Quilava","Fire","None",405,58,64,58,80,65,80);
        // createBaseStatPokemon(157,"Typhlosion","Fire","None",534,78,84,78,109,85,100);
        // createBaseStatPokemon(158,"Totodile","Water","None",314,50,65,64,44,48,43);
        // createBaseStatPokemon(159,"Croconaw","Water","None",405,65,80,80,59,63,58);
        // createBaseStatPokemon(160,"Feraligatr","Water","None",530,85,105,100,79,83,78);
        // createBaseStatPokemon(161,"Sentret","Normal","None",215,35,46,34,35,45,20);
        // createBaseStatPokemon(162,"Furret","Normal","None",415,85,76,64,45,55,90);
        // createBaseStatPokemon(163,"Hoothoot","Normal","Flying",262,60,30,30,36,56,50);
        // createBaseStatPokemon(164,"Noctowl","Normal","Flying",442,100,50,50,76,96,70);
        // createBaseStatPokemon(165,"Ledyba","Bug","Flying",265,40,20,30,40,80,55);
        // createBaseStatPokemon(166,"Ledian","Bug","Flying",390,55,35,50,55,110,85);
        // createBaseStatPokemon(167,"Spinarak","Bug","Poison",250,40,60,40,40,40,30);
        // createBaseStatPokemon(168,"Ariados","Bug","Poison",390,70,90,70,60,60,40);
        // createBaseStatPokemon(169,"Crobat","Poison","Flying",535,85,90,80,70,80,130);
        // createBaseStatPokemon(170,"Chinchou","Water","Electric",330,75,38,38,56,56,67);
        // createBaseStatPokemon(171,"Lanturn","Water","Electric",460,125,58,58,76,76,67);
        // createBaseStatPokemon(172,"Pichu","Electric","None",205,20,40,15,35,35,60);
        // createBaseStatPokemon(173,"Cleffa","Fairy","None",218,50,25,28,45,55,15);
        // createBaseStatPokemon(174,"Igglybuff","Normal","Fairy",210,90,30,15,40,20,15);
        // createBaseStatPokemon(175,"Togepi","Fairy","None",245,35,20,65,40,65,20);
        // createBaseStatPokemon(176,"Togetic","Fairy","Flying",405,55,40,85,80,105,40);
        // createBaseStatPokemon(177,"Natu","Psychic","Flying",320,40,50,45,70,45,70);
        // createBaseStatPokemon(178,"Xatu","Psychic","Flying",470,65,75,70,95,70,95);
        // createBaseStatPokemon(179,"Mareep","Electric","None",280,55,40,40,65,45,35);
        // createBaseStatPokemon(180,"Flaaffy","Electric","None",365,70,55,55,80,60,45);
        // createBaseStatPokemon(181,"Ampharos","Electric","None",510,90,75,85,115,90,55);
        // createBaseStatPokemon(181,"Mega Ampharos","Electric","Dragon",610,90,95,105,165,110,45);
        // createBaseStatPokemon(182,"Bellossom","Grass","None",490,75,80,95,90,100,50);
        // createBaseStatPokemon(183,"Marill","Water","Fairy",250,70,20,50,20,50,40);
        // createBaseStatPokemon(184,"Azumarill","Water","Fairy",420,100,50,80,60,80,50);
        // createBaseStatPokemon(185,"Sudowoodo","Rock","None",410,70,100,115,30,65,30);
        // createBaseStatPokemon(186,"Politoed","Water","None",500,90,75,75,90,100,70);
        // createBaseStatPokemon(187,"Hoppip","Grass","Flying",250,35,35,40,35,55,50);
        // createBaseStatPokemon(188,"Skiploom","Grass","Flying",340,55,45,50,45,65,80);
        // createBaseStatPokemon(189,"Jumpluff","Grass","Flying",460,75,55,70,55,95,110);
        // createBaseStatPokemon(190,"Aipom","Normal","None",360,55,70,55,40,55,85);
        // createBaseStatPokemon(191,"Sunkern","Grass","None",180,30,30,30,30,30,30);
        // createBaseStatPokemon(192,"Sunflora","Grass","None",425,75,75,55,105,85,30);
        // createBaseStatPokemon(193,"Yanma","Bug","Flying",390,65,65,45,75,45,95);
        // createBaseStatPokemon(194,"Wooper","Water","Ground",210,55,45,45,25,25,15);
        // createBaseStatPokemon(195,"Quagsire","Water","Ground",430,95,85,85,65,65,35);
        // createBaseStatPokemon(196,"Espeon","Psychic","None",525,65,65,60,130,95,110);
        // createBaseStatPokemon(197,"Umbreon","Dark","None",525,95,65,110,60,130,65);
        // createBaseStatPokemon(198,"Murkrow","Dark","Flying",405,60,85,42,85,42,91);
        // createBaseStatPokemon(199,"Slowking","Water","Psychic",490,95,75,80,100,110,30);
        // createBaseStatPokemon(199,"Galarian Slowking","Poison","Psychic",490,95,65,80,110,110,30);
        // createBaseStatPokemon(200,"Misdreavus","Ghost","None",435,60,60,60,85,85,85);
        // createBaseStatPokemon(201,"Unown","Psychic","None",336,48,72,48,72,48,48);
        // createBaseStatPokemon(202,"Wobbuffet","Psychic","None",405,190,33,58,33,58,33);
        // createBaseStatPokemon(203,"Girafarig","Normal","Psychic",455,70,80,65,90,65,85);
        // createBaseStatPokemon(204,"Pineco","Bug","None",290,50,65,90,35,35,15);
        // createBaseStatPokemon(205,"Forretress","Bug","Steel",465,75,90,140,60,60,40);
        // createBaseStatPokemon(206,"Dunsparce","Normal","None",415,100,70,70,65,65,45);
        // createBaseStatPokemon(207,"Gligar","Ground","Flying",430,65,75,105,35,65,85);
        // createBaseStatPokemon(208,"Steelix","Steel","Ground",510,75,85,200,55,65,30);
        // createBaseStatPokemon(208,"Mega Steelix","Steel","Ground",610,75,125,230,55,95,30);
        // createBaseStatPokemon(209,"Snubbull","Fairy","None",300,60,80,50,40,40,30);
        // createBaseStatPokemon(210,"Granbull","Fairy","None",450,90,120,75,60,60,45);
        // createBaseStatPokemon(211,"Qwilfish","Water","Poison",430,65,95,75,55,55,85);
        // createBaseStatPokemon(212,"Scizor","Bug","Steel",500,70,130,100,55,80,65);
        // createBaseStatPokemon(212,"Mega Scizor","Bug","Steel",600,70,150,140,65,100,75);
        // createBaseStatPokemon(213,"Shuckle","Bug","Rock",505,20,10,230,10,230,5);
        // createBaseStatPokemon(214,"Heracross","Bug","Fighting",500,80,125,75,40,95,85);
        // createBaseStatPokemon(214,"Mega Heracross","Bug","Fighting",600,80,185,115,40,105,75);
        // createBaseStatPokemon(215,"Sneasel","Dark","Ice",430,55,95,55,35,75,115);
        // createBaseStatPokemon(216,"Teddiursa","Normal","None",330,60,80,50,50,50,40);
        // createBaseStatPokemon(217,"Ursaring","Normal","None",500,90,130,75,75,75,55);
        // createBaseStatPokemon(218,"Slugma","Fire","None",250,40,40,40,70,40,20);
        // createBaseStatPokemon(219,"Magcargo","Fire","Rock",410,50,50,120,80,80,30);
        // createBaseStatPokemon(220,"Swinub","Ice","Ground",250,50,50,40,30,30,50);
        // createBaseStatPokemon(221,"Piloswine","Ice","Ground",450,100,100,80,60,60,50);
        // createBaseStatPokemon(222,"Corsola","Water","Rock",380,55,55,85,65,85,35);
        // createBaseStatPokemon(222,"Galarian Corsola","Ghost","None",380,60,55,100,65,100,30);
        // createBaseStatPokemon(223,"Remoraid","Water","None",300,35,65,35,65,35,65);
        // createBaseStatPokemon(224,"Octillery","Water","None",480,75,105,75,105,75,45);
        // createBaseStatPokemon(225,"Delibird","Ice","Flying",330,45,55,45,65,45,75);
        // createBaseStatPokemon(226,"Mantine","Water","Flying",465,65,40,70,80,140,70);
        // createBaseStatPokemon(227,"Skarmory","Steel","Flying",465,65,80,140,40,70,70);
        // createBaseStatPokemon(228,"Houndour","Dark","Fire",330,45,60,30,80,50,65);
        // createBaseStatPokemon(229,"Houndoom","Dark","Fire",500,75,90,50,110,80,95);
        // createBaseStatPokemon(229,"Mega Houndoom","Dark","Fire",600,75,90,90,140,90,115);
        // createBaseStatPokemon(230,"Kingdra","Water","Dragon",540,75,95,95,95,95,85);
        // createBaseStatPokemon(231,"Phanpy","Ground","None",330,90,60,60,40,40,40);
        // createBaseStatPokemon(232,"Donphan","Ground","None",500,90,120,120,60,60,50);
        // createBaseStatPokemon(233,"Porygon2","Normal","None",515,85,80,90,105,95,60);
        // createBaseStatPokemon(234,"Stantler","Normal","None",465,73,95,62,85,65,85);
        // createBaseStatPokemon(235,"Smeargle","Normal","None",250,55,20,35,20,45,75);
        // createBaseStatPokemon(236,"Tyrogue","Fighting","None",210,35,35,35,35,35,35);
        // createBaseStatPokemon(237,"Hitmontop","Fighting","None",455,50,95,95,35,110,70);
        // createBaseStatPokemon(238,"Smoochum","Ice","Psychic",305,45,30,15,85,65,65);
        // createBaseStatPokemon(239,"Elekid","Electric","None",360,45,63,37,65,55,95);
        // createBaseStatPokemon(240,"Magby","Fire","None",365,45,75,37,70,55,83);
        // createBaseStatPokemon(241,"Miltank","Normal","None",490,95,80,105,40,70,100);
        // createBaseStatPokemon(242,"Blissey","Normal","None",540,255,10,10,75,135,55);
        // createBaseStatPokemon(243,"Raikou","Electric","None",580,90,85,75,115,100,115);
        // createBaseStatPokemon(244,"Entei","Fire","None",580,115,115,85,90,75,100);
        // createBaseStatPokemon(245,"Suicune","Water","None",580,100,75,115,90,115,85);
        // createBaseStatPokemon(246,"Larvitar","Rock","Ground",300,50,64,50,45,50,41);
        // createBaseStatPokemon(247,"Pupitar","Rock","Ground",410,70,84,70,65,70,51);
        // createBaseStatPokemon(248,"Tyranitar","Rock","Dark",600,100,134,110,95,100,61);
        // createBaseStatPokemon(248,"Mega Tyranitar","Rock","Dark",700,100,164,150,95,120,71);
        // createBaseStatPokemon(249,"Lugia","Psychic","Flying",680,106,90,130,90,154,110);
        // createBaseStatPokemon(250,"Ho-oh","Fire","Flying",680,106,130,90,110,154,90);
        // createBaseStatPokemon(251,"Celebi","Psychic","Grass",600,100,100,100,100,100,100);
        // createBaseStatPokemon(252,"Treecko","Grass","None",310,40,45,35,65,55,70);
        // createBaseStatPokemon(253,"Grovyle","Grass","None",405,50,65,45,85,65,95);
        // createBaseStatPokemon(254,"Sceptile","Grass","None",530,70,85,65,105,85,120);
        // createBaseStatPokemon(254,"Mega Sceptile","Grass","Dragon",630,70,110,75,145,85,145);
        // createBaseStatPokemon(255,"Torchic","Fire","None",310,45,60,40,70,50,45);
        // createBaseStatPokemon(256,"Combusken","Fire","Fighting",405,60,85,60,85,60,55);
        // createBaseStatPokemon(257,"Blaziken","Fire","Fighting",530,80,120,70,110,70,80);
        // createBaseStatPokemon(257,"Mega Blaziken","Fire","Fighting",630,80,160,80,130,80,100);
        // createBaseStatPokemon(258,"Mudkip","Water","None",310,50,70,50,50,50,40);
        // createBaseStatPokemon(259,"Marshtomp","Water","Ground",405,70,85,70,60,70,50);
        // createBaseStatPokemon(260,"Swampert","Water","Ground",535,100,110,90,85,90,60);
        // createBaseStatPokemon(260,"Mega Swampert","Water","Ground",635,100,150,110,95,110,70);
        // createBaseStatPokemon(261,"Poochyena","Dark","None",220,35,55,35,30,30,35);
        // createBaseStatPokemon(262,"Mightyena","Dark","None",420,70,90,70,60,60,70);
        // createBaseStatPokemon(263,"Zigzagoon","Normal","None",240,38,30,41,30,41,60);
        // createBaseStatPokemon(263,"Galarian Zigzagoon","Dark","Normal",240,38,30,41,30,41,60);
        // createBaseStatPokemon(264,"Linoone","Normal","None",420,78,70,61,50,61,100);
        // createBaseStatPokemon(264,"Galarian Linoone","Dark","Normal",420,78,70,61,50,61,100);
        // createBaseStatPokemon(265,"Wurmple","Bug","None",195,45,45,35,20,30,20);
        // createBaseStatPokemon(266,"Silcoon","Bug","None",205,50,35,55,25,25,15);
        // createBaseStatPokemon(267,"Beautifly","Bug","Flying",395,60,70,50,100,50,65);
        // createBaseStatPokemon(268,"Cascoon","Bug","None",205,50,35,55,25,25,15);
        // createBaseStatPokemon(269,"Dustox","Bug","Poison",385,60,50,70,50,90,65);
        // createBaseStatPokemon(270,"Lotad","Water","Grass",220,40,30,30,40,50,30);
        // createBaseStatPokemon(271,"Lombre","Water","Grass",340,60,50,50,60,70,50);
        // createBaseStatPokemon(272,"Ludicolo","Water","Grass",480,80,70,70,90,100,70);
        // createBaseStatPokemon(273,"Seedot","Grass","None",220,40,40,50,30,30,30);
        // createBaseStatPokemon(274,"Nuzleaf","Grass","Dark",340,70,70,40,60,40,60);
        // createBaseStatPokemon(275,"Shiftry","Grass","Dark",480,90,100,60,90,60,80);
        // createBaseStatPokemon(276,"Taillow","Normal","Flying",270,40,55,30,30,30,85);
        // createBaseStatPokemon(277,"Swellow","Normal","Flying",430,60,85,60,50,50,125);
        // createBaseStatPokemon(278,"Wingull","Water","Flying",270,40,30,30,55,30,85);
        // createBaseStatPokemon(279,"Pelipper","Water","Flying",430,60,50,100,85,70,65);
        // createBaseStatPokemon(280,"Ralts","Psychic","Fairy",198,28,25,25,45,35,40);
        // createBaseStatPokemon(281,"Kirlia","Psychic","Fairy",278,38,35,35,65,55,50);
        // createBaseStatPokemon(282,"Gardevoir","Psychic","Fairy",518,68,65,65,125,115,80);
        // createBaseStatPokemon(282,"Mega Gardevoir","Psychic","Fairy",618,68,85,65,165,135,100);
        // createBaseStatPokemon(283,"Surskit","Bug","Water",269,40,30,32,50,52,65);
        // createBaseStatPokemon(284,"Masquerain","Bug","Flying",414,70,60,62,80,82,60);
        // createBaseStatPokemon(285,"Shroomish","Grass","None",295,60,40,60,40,60,35);
        // createBaseStatPokemon(286,"Breloom","Grass","Fighting",460,60,130,80,60,60,70);
        // createBaseStatPokemon(287,"Slakoth","Normal","None",280,60,60,60,35,35,30);
        // createBaseStatPokemon(288,"Vigoroth","Normal","None",440,80,80,80,55,55,90);
        // createBaseStatPokemon(289,"Slaking","Normal","None",670,150,160,100,95,65,100);
        // createBaseStatPokemon(290,"Nincada","Bug","Ground",266,31,45,90,30,30,40);
        // createBaseStatPokemon(291,"Ninjask","Bug","Flying",456,61,90,45,50,50,160);
        // createBaseStatPokemon(292,"Shedinja","Bug","Ghost",236,1,90,45,30,30,40);
        // createBaseStatPokemon(293,"Whismur","Normal","None",240,64,51,23,51,23,28);
        // createBaseStatPokemon(294,"Loudred","Normal","None",360,84,71,43,71,43,48);
        // createBaseStatPokemon(295,"Exploud","Normal","None",490,104,91,63,91,73,68);
        // createBaseStatPokemon(296,"Makuhita","Fighting","None",237,72,60,30,20,30,25);
        // createBaseStatPokemon(297,"Hariyama","Fighting","None",474,144,120,60,40,60,50);
        // createBaseStatPokemon(298,"Azurill","Normal","Fairy",190,50,20,40,20,40,20);
        // createBaseStatPokemon(299,"Nosepass","Rock","None",375,30,45,135,45,90,30);
        // createBaseStatPokemon(300,"Skitty","Normal","None",260,50,45,45,35,35,50);
        // createBaseStatPokemon(301,"Delcatty","Normal","None",380,70,65,65,55,55,70);
        // createBaseStatPokemon(302,"Sableye","Dark","Ghost",380,50,75,75,65,65,50);
        // createBaseStatPokemon(302,"Mega Sableye","Dark","Ghost",480,50,85,125,85,115,20);
        // createBaseStatPokemon(303,"Mawile","Steel","Fairy",380,50,85,85,55,55,50);
        // createBaseStatPokemon(303,"Mega Mawile","Steel","Fairy",480,50,105,125,55,95,50);
        // createBaseStatPokemon(304,"Aron","Steel","Rock",330,50,70,100,40,40,30);
        // createBaseStatPokemon(305,"Lairon","Steel","Rock",430,60,90,140,50,50,40);
        // createBaseStatPokemon(306,"Aggron","Steel","Rock",530,70,110,180,60,60,50);
        // createBaseStatPokemon(306,"Mega Aggron","Steel","None",630,70,140,230,60,80,50);
        // createBaseStatPokemon(307,"Meditite","Fighting","Psychic",280,30,40,55,40,55,60);
        // createBaseStatPokemon(308,"Medicham","Fighting","Psychic",410,60,60,75,60,75,80);
        // createBaseStatPokemon(308,"Mega Medicham","Fighting","Psychic",510,60,100,85,80,85,100);
        // createBaseStatPokemon(309,"Electrike","Electric","None",295,40,45,40,65,40,65);
        // createBaseStatPokemon(310,"Manectric","Electric","None",475,70,75,60,105,60,105);
        // createBaseStatPokemon(310,"Mega Manectric","Electric","None",575,70,75,80,135,80,135);
        // createBaseStatPokemon(311,"Plusle","Electric","None",405,60,50,40,85,75,95);
        // createBaseStatPokemon(312,"Minun","Electric","None",405,60,40,50,75,85,95);
        // createBaseStatPokemon(313,"Volbeat","Bug","None",400,65,73,55,47,75,85);
        // createBaseStatPokemon(314,"Illumise","Bug","None",400,65,47,55,73,75,85);
        // createBaseStatPokemon(315,"Roselia","Grass","Poison",400,50,60,45,100,80,65);
        // createBaseStatPokemon(316,"Gulpin","Poison","None",302,70,43,53,43,53,40);
        // createBaseStatPokemon(317,"Swalot","Poison","None",467,100,73,83,73,83,55);
        // createBaseStatPokemon(318,"Carvanha","Water","Dark",305,45,90,20,65,20,65);
        // createBaseStatPokemon(319,"Sharpedo","Water","Dark",460,70,120,40,95,40,95);
        // createBaseStatPokemon(319,"Mega Sharpedo","Water","Dark",560,70,140,70,110,65,105);
        // createBaseStatPokemon(320,"Wailmer","Water","None",400,130,70,35,70,35,60);
        // createBaseStatPokemon(321,"Wailord","Water","None",500,170,90,45,90,45,60);
        // createBaseStatPokemon(322,"Numel","Fire","Ground",305,60,60,40,65,45,35);
        // createBaseStatPokemon(323,"Camerupt","Fire","Ground",460,70,100,70,105,75,40);
        // createBaseStatPokemon(323,"Mega Camerupt","Fire","Ground",560,70,120,100,145,105,20);
        // createBaseStatPokemon(324,"Torkoal","Fire","None",470,70,85,140,85,70,20);
        // createBaseStatPokemon(325,"Spoink","Psychic","None",330,60,25,35,70,80,60);
        // createBaseStatPokemon(326,"Grumpig","Psychic","None",470,80,45,65,90,110,80);
        // createBaseStatPokemon(327,"Spinda","Normal","None",360,60,60,60,60,60,60);
        // createBaseStatPokemon(328,"Trapinch","Ground","None",290,45,100,45,45,45,10);
        // createBaseStatPokemon(329,"Vibrava","Ground","Dragon",340,50,70,50,50,50,70);
        // createBaseStatPokemon(330,"Flygon","Ground","Dragon",520,80,100,80,80,80,100);
        // createBaseStatPokemon(331,"Cacnea","Grass","None",335,50,85,40,85,40,35);
        // createBaseStatPokemon(332,"Cacturne","Grass","Dark",475,70,115,60,115,60,55);
        // createBaseStatPokemon(333,"Swablu","Normal","Flying",310,45,40,60,40,75,50);
        // createBaseStatPokemon(334,"Altaria","Dragon","Flying",490,75,70,90,70,105,80);
        // createBaseStatPokemon(334,"Mega Altaria","Dragon","Fairy",590,75,110,110,110,105,80);
        // createBaseStatPokemon(335,"Zangoose","Normal","None",458,73,115,60,60,60,90);
        // createBaseStatPokemon(336,"Seviper","Poison","None",458,73,100,60,100,60,65);
        // createBaseStatPokemon(337,"Lunatone","Rock","Psychic",440,70,55,65,95,85,70);
        // createBaseStatPokemon(338,"Solrock","Rock","Psychic",440,70,95,85,55,65,70);
        // createBaseStatPokemon(339,"Barboach","Water","Ground",288,50,48,43,46,41,60);
        // createBaseStatPokemon(340,"Whiscash","Water","Ground",468,110,78,73,76,71,60);
        // createBaseStatPokemon(341,"Corphish","Water","None",308,43,80,65,50,35,35);
        // createBaseStatPokemon(342,"Crawdaunt","Water","Dark",468,63,120,85,90,55,55);
        // createBaseStatPokemon(343,"Baltoy","Ground","Psychic",300,40,40,55,40,70,55);
        // createBaseStatPokemon(344,"Claydol","Ground","Psychic",500,60,70,105,70,120,75);
        // createBaseStatPokemon(345,"Lileep","Rock","Grass",355,66,41,77,61,87,23);
        // createBaseStatPokemon(346,"Cradily","Rock","Grass",495,86,81,97,81,107,43);
        // createBaseStatPokemon(347,"Anorith","Rock","Bug",355,45,95,50,40,50,75);
        // createBaseStatPokemon(348,"Armaldo","Rock","Bug",495,75,125,100,70,80,45);
        // createBaseStatPokemon(349,"Feebas","Water","None",200,20,15,20,10,55,80);
        // createBaseStatPokemon(350,"Milotic","Water","None",540,95,60,79,100,125,81);
        // createBaseStatPokemon(351,"Castform","Normal","None",420,70,70,70,70,70,70);
        // createBaseStatPokemon(352,"Kecleon","Normal","None",440,60,90,70,60,120,40);
        // createBaseStatPokemon(353,"Shuppet","Ghost","None",295,44,75,35,63,33,45);
        // createBaseStatPokemon(354,"Banette","Ghost","None",455,64,115,65,83,63,65);
        // createBaseStatPokemon(354,"Mega Banette","Ghost","None",555,64,165,75,93,83,75);
        // createBaseStatPokemon(355,"Duskull","Ghost","None",295,20,40,90,30,90,25);
        // createBaseStatPokemon(356,"Dusclops","Ghost","None",455,40,70,130,60,130,25);
        // createBaseStatPokemon(357,"Tropius","Grass","Flying",460,99,68,83,72,87,51);
        // createBaseStatPokemon(358,"Chimecho","Psychic","None",425,65,50,70,95,80,65);
        // createBaseStatPokemon(359,"Absol","Dark","None",465,65,130,60,75,60,75);
        // createBaseStatPokemon(359,"Mega Absol","Dark","None",565,65,150,60,115,60,115);
        // createBaseStatPokemon(360,"Wynaut","Psychic","None",260,95,23,48,23,48,23);
        // createBaseStatPokemon(361,"Snorunt","Ice","None",300,50,50,50,50,50,50);
        // createBaseStatPokemon(362,"Glalie","Ice","None",480,80,80,80,80,80,80);
        // createBaseStatPokemon(362,"Mega Glalie","Ice","None",580,80,120,80,120,80,100);
        // createBaseStatPokemon(363,"Spheal","Ice","Water",290,70,40,50,55,50,25);
        // createBaseStatPokemon(364,"Sealeo","Ice","Water",410,90,60,70,75,70,45);
        // createBaseStatPokemon(365,"Walrein","Ice","Water",530,110,80,90,95,90,65);
        // createBaseStatPokemon(366,"Clamperl","Water","None",345,35,64,85,74,55,32);
        // createBaseStatPokemon(367,"Huntail","Water","None",485,55,104,105,94,75,52);
        // createBaseStatPokemon(368,"Gorebyss","Water","None",485,55,84,105,114,75,52);
        // createBaseStatPokemon(369,"Relicanth","Water","Rock",485,100,90,130,45,65,55);
        // createBaseStatPokemon(370,"Luvdisc","Water","None",330,43,30,55,40,65,97);
        // createBaseStatPokemon(371,"Bagon","Dragon","None",300,45,75,60,40,30,50);
        // createBaseStatPokemon(372,"Shelgon","Dragon","None",420,65,95,100,60,50,50);
        // createBaseStatPokemon(373,"Salamence","Dragon","Flying",600,95,135,80,110,80,100);
        // createBaseStatPokemon(373,"Mega Salamence","Dragon","Flying",700,95,145,130,120,90,120);
        // createBaseStatPokemon(374,"Beldum","Steel","Psychic",300,40,55,80,35,60,30);
        // createBaseStatPokemon(375,"Metang","Steel","Psychic",420,60,75,100,55,80,50);
        // createBaseStatPokemon(376,"Metagross","Steel","Psychic",600,80,135,130,95,90,70);
        // createBaseStatPokemon(376,"Mega Metagross","Steel","Psychic",700,80,145,150,105,110,110);
        // createBaseStatPokemon(377,"Regirock","Rock","None",580,80,100,200,50,100,50);
        // createBaseStatPokemon(378,"Regice","Ice","None",580,80,50,100,100,200,50);
        // createBaseStatPokemon(379,"Registeel","Steel","None",580,80,75,150,75,150,50);
        // createBaseStatPokemon(380,"Latias","Dragon","Psychic",600,80,80,90,110,130,110);
        // createBaseStatPokemon(380,"Mega Latias","Dragon","Psychic",700,80,100,120,140,150,110);
        // createBaseStatPokemon(381,"Latios","Dragon","Psychic",600,80,90,80,130,110,110);
        // createBaseStatPokemon(381,"Mega Latios","Dragon","Psychic",700,80,130,100,160,120,110);
        // createBaseStatPokemon(382,"Kyogre","Water","None",670,100,100,90,150,140,90);
        // createBaseStatPokemon(382,"Primal Kyogre","Water","None",770,100,150,90,180,160,90);
        // createBaseStatPokemon(383,"Groudon","Ground","None",670,100,150,140,100,90,90);
        // createBaseStatPokemon(383,"Primal Groudon","Ground","Fire",770,100,180,160,150,90,90);
        // createBaseStatPokemon(384,"Rayquaza","Dragon","Flying",680,105,150,90,150,90,95);
        // createBaseStatPokemon(384,"Mega Rayquaza","Dragon","Flying",780,105,180,100,180,100,115);
        // createBaseStatPokemon(385,"Jirachi","Steel","Psychic",600,100,100,100,100,100,100);
        // createBaseStatPokemon(386,"Deoxys Normal Forme","Psychic","None",600,50,150,50,150,50,150);
        // createBaseStatPokemon(386,"Deoxys Attack Forme","Psychic","None",600,50,180,20,180,20,150);
        // createBaseStatPokemon(386,"Deoxys Defense Forme","Psychic","None",600,50,70,160,70,160,90);
        // createBaseStatPokemon(386,"Deoxys Speed Forme","Psychic","None",600,50,95,90,95,90,180);
        // createBaseStatPokemon(387,"Turtwig","Grass","None",318,55,68,64,45,55,31);
        // createBaseStatPokemon(388,"Grotle","Grass","None",405,75,89,85,55,65,36);
        // createBaseStatPokemon(389,"Torterra","Grass","Ground",525,95,109,105,75,85,56);
        // createBaseStatPokemon(390,"Chimchar","Fire","None",309,44,58,44,58,44,61);
        // createBaseStatPokemon(391,"Monferno","Fire","Fighting",405,64,78,52,78,52,81);
        // createBaseStatPokemon(392,"Infernape","Fire","Fighting",534,76,104,71,104,71,108);
        // createBaseStatPokemon(393,"Piplup","Water","None",314,53,51,53,61,56,40);
        // createBaseStatPokemon(394,"Prinplup","Water","None",405,64,66,68,81,76,50);
        // createBaseStatPokemon(395,"Empoleon","Water","Steel",530,84,86,88,111,101,60);
        // createBaseStatPokemon(396,"Starly","Normal","Flying",245,40,55,30,30,30,60);
        // createBaseStatPokemon(397,"Staravia","Normal","Flying",340,55,75,50,40,40,80);
        // createBaseStatPokemon(398,"Staraptor","Normal","Flying",485,85,120,70,50,60,100);
        // createBaseStatPokemon(399,"Bidoof","Normal","None",250,59,45,40,35,40,31);
        // createBaseStatPokemon(400,"Bibarel","Normal","Water",410,79,85,60,55,60,71);
        // createBaseStatPokemon(401,"Kricketot","Bug","None",194,37,25,41,25,41,25);
        // createBaseStatPokemon(402,"Kricketune","Bug","None",384,77,85,51,55,51,65);
        // createBaseStatPokemon(403,"Shinx","Electric","None",263,45,65,34,40,34,45);
        // createBaseStatPokemon(404,"Luxio","Electric","None",363,60,85,49,60,49,60);
        // createBaseStatPokemon(405,"Luxray","Electric","None",523,80,120,79,95,79,70);
        // createBaseStatPokemon(406,"Budew","Grass","Poison",280,40,30,35,50,70,55);
        // createBaseStatPokemon(407,"Roserade","Grass","Poison",515,60,70,65,125,105,90);
        // createBaseStatPokemon(408,"Cranidos","Rock","None",350,67,125,40,30,30,58);
        // createBaseStatPokemon(409,"Rampardos","Rock","None",495,97,165,60,65,50,58);
        // createBaseStatPokemon(410,"Shieldon","Rock","Steel",350,30,42,118,42,88,30);
        // createBaseStatPokemon(411,"Bastiodon","Rock","Steel",495,60,52,168,47,138,30);
        // createBaseStatPokemon(412,"Burmy","Bug","None",224,40,29,45,29,45,36);
        // createBaseStatPokemon(413,"Wormadam Plant Cloak","Bug","Grass",424,60,59,85,79,105,36);
        // createBaseStatPokemon(413,"Wormadam Sandy Cloak","Bug","Ground",424,60,79,105,59,85,36);
        // createBaseStatPokemon(413,"Wormadam Trash Cloak","Bug","Steel",424,60,69,95,69,95,36);
        // createBaseStatPokemon(414,"Mothim","Bug","Flying",424,70,94,50,94,50,66);
        // createBaseStatPokemon(415,"Combee","Bug","Flying",244,30,30,42,30,42,70);
        // createBaseStatPokemon(416,"Vespiquen","Bug","Flying",474,70,80,102,80,102,40);
        // createBaseStatPokemon(417,"Pachirisu","Electric","None",405,60,45,70,45,90,95);
        // createBaseStatPokemon(418,"Buizel","Water","None",330,55,65,35,60,30,85);
        // createBaseStatPokemon(419,"Floatzel","Water","None",495,85,105,55,85,50,115);
        // createBaseStatPokemon(420,"Cherubi","Grass","None",275,45,35,45,62,53,35);
        // createBaseStatPokemon(421,"Cherrim","Grass","None",450,70,60,70,87,78,85);
        // createBaseStatPokemon(422,"Shellos","Water","None",325,76,48,48,57,62,34);
        // createBaseStatPokemon(423,"Gastrodon","Water","Ground",475,111,83,68,92,82,39);
        // createBaseStatPokemon(424,"Ambipom","Normal","None",482,75,100,66,60,66,115);
        // createBaseStatPokemon(425,"Drifloon","Ghost","Flying",348,90,50,34,60,44,70);
        // createBaseStatPokemon(426,"Drifblim","Ghost","Flying",498,150,80,44,90,54,80);
        // createBaseStatPokemon(427,"Buneary","Normal","None",350,55,66,44,44,56,85);
        // createBaseStatPokemon(428,"Lopunny","Normal","None",480,65,76,84,54,96,105);
        // createBaseStatPokemon(428,"Mega Lopunny","Normal","Fighting",580,65,136,94,54,96,135);
        // createBaseStatPokemon(429,"Mismagius","Ghost","None",495,60,60,60,105,105,105);
        // createBaseStatPokemon(430,"Honchkrow","Dark","Flying",505,100,125,52,105,52,71);
        // createBaseStatPokemon(431,"Glameow","Normal","None",310,49,55,42,42,37,85);
        // createBaseStatPokemon(432,"Purugly","Normal","None",452,71,82,64,64,59,112);
        // createBaseStatPokemon(433,"Chingling","Psychic","None",285,45,30,50,65,50,45);
        // createBaseStatPokemon(434,"Stunky","Poison","Dark",329,63,63,47,41,41,74);
        // createBaseStatPokemon(435,"Skuntank","Poison","Dark",479,103,93,67,71,61,84);
        // createBaseStatPokemon(436,"Bronzor","Steel","Psychic",300,57,24,86,24,86,23);
        // createBaseStatPokemon(437,"Bronzong","Steel","Psychic",500,67,89,116,79,116,33);
        // createBaseStatPokemon(438,"Bonsly","Rock","None",290,50,80,95,10,45,10);
        // createBaseStatPokemon(439,"Mime Jr.","Psychic","Fairy",310,20,25,45,70,90,60);
        // createBaseStatPokemon(440,"Happiny","Normal","None",220,100,5,5,15,65,30);
        // createBaseStatPokemon(441,"Chatot","Normal","Flying",411,76,65,45,92,42,91);
        // createBaseStatPokemon(442,"Spiritomb","Ghost","Dark",485,50,92,108,92,108,35);
        // createBaseStatPokemon(443,"Gible","Dragon","Ground",300,58,70,45,40,45,42);
        // createBaseStatPokemon(444,"Gabite","Dragon","Ground",410,68,90,65,50,55,82);
        // createBaseStatPokemon(445,"Garchomp","Dragon","Ground",600,108,130,95,80,85,102);
        // createBaseStatPokemon(445,"Mega Garchomp","Dragon","Ground",700,108,170,115,120,95,92);
        // createBaseStatPokemon(446,"Munchlax","Normal","None",390,135,85,40,40,85,5);
        // createBaseStatPokemon(447,"Riolu","Fighting","None",285,40,70,40,35,40,60);
        // createBaseStatPokemon(448,"Lucario","Fighting","Steel",525,70,110,70,115,70,90);
        // createBaseStatPokemon(448,"Mega Lucario","Fighting","Steel",625,70,145,88,140,70,112);
        // createBaseStatPokemon(449,"Hippopotas","Ground","None",330,68,72,78,38,42,32);
        // createBaseStatPokemon(450,"Hippowdon","Ground","None",525,108,112,118,68,72,47);
        // createBaseStatPokemon(451,"Skorupi","Poison","Bug",330,40,50,90,30,55,65);
        // createBaseStatPokemon(452,"Drapion","Poison","Dark",500,70,90,110,60,75,95);
        // createBaseStatPokemon(453,"Croagunk","Poison","Fighting",300,48,61,40,61,40,50);
        // createBaseStatPokemon(454,"Toxicroak","Poison","Fighting",490,83,106,65,86,65,85);
        // createBaseStatPokemon(455,"Carnivine","Grass","None",454,74,100,72,90,72,46);
        // createBaseStatPokemon(456,"Finneon","Water","None",330,49,49,56,49,61,66);
        // createBaseStatPokemon(457,"Lumineon","Water","None",460,69,69,76,69,86,91);
        // createBaseStatPokemon(458,"Mantyke","Water","Flying",345,45,20,50,60,120,50);
        // createBaseStatPokemon(459,"Snover","Grass","Ice",334,60,62,50,62,60,40);
        // createBaseStatPokemon(460,"Abomasnow","Grass","Ice",494,90,92,75,92,85,60);
        // createBaseStatPokemon(460,"Mega Abomasnow","Grass","Ice",594,90,132,105,132,105,30);
        // createBaseStatPokemon(461,"Weavile","Dark","Ice",510,70,120,65,45,85,125);
        // createBaseStatPokemon(462,"Magnezone","Electric","Steel",535,70,70,115,130,90,60);
        // createBaseStatPokemon(463,"Lickilicky","Normal","None",515,110,85,95,80,95,50);
        // createBaseStatPokemon(464,"Rhyperior","Ground","Rock",535,115,140,130,55,55,40);
        // createBaseStatPokemon(465,"Tangrowth","Grass","None",535,100,100,125,110,50,50);
        // createBaseStatPokemon(466,"Electivire","Electric","None",540,75,123,67,95,85,95);
        // createBaseStatPokemon(467,"Magmortar","Fire","None",540,75,95,67,125,95,83);
        // createBaseStatPokemon(468,"Togekiss","Fairy","Flying",545,85,50,95,120,115,80);
        // createBaseStatPokemon(469,"Yanmega","Bug","Flying",515,86,76,86,116,56,95);
        // createBaseStatPokemon(470,"Leafeon","Grass","None",525,65,110,130,60,65,95);
        // createBaseStatPokemon(471,"Glaceon","Ice","None",525,65,60,110,130,95,65);
        // createBaseStatPokemon(472,"Gliscor","Ground","Flying",510,75,95,125,45,75,95);
        // createBaseStatPokemon(473,"Mamoswine","Ice","Ground",530,110,130,80,70,60,80);
        // createBaseStatPokemon(474,"Porygon-z","Normal","None",535,85,80,70,135,75,90);
        // createBaseStatPokemon(475,"Gallade","Psychic","Fighting",518,68,125,65,65,115,80);
        // createBaseStatPokemon(475,"Mega Gallade","Psychic","Fighting",618,68,165,95,65,115,110);
        // createBaseStatPokemon(476,"Probopass","Rock","Steel",525,60,55,145,75,150,40);
        // createBaseStatPokemon(477,"Dusknoir","Ghost","None",525,45,100,135,65,135,45);
        // createBaseStatPokemon(478,"Froslass","Ice","Ghost",480,70,80,70,80,70,110);
        // createBaseStatPokemon(479,"Rotom","Electric","Ghost",440,50,50,77,95,77,91);
        // createBaseStatPokemon(479,"Heat Rotom","Electric","Fire",520,50,65,107,105,107,86);
        // createBaseStatPokemon(479,"Wash Rotom","Electric","Water",520,50,65,107,105,107,86);
        // createBaseStatPokemon(479,"Frost Rotom","Electric","Ice",520,50,65,107,105,107,86);
        // createBaseStatPokemon(479,"Fan Rotom","Electric","Flying",520,50,65,107,105,107,86);
        // createBaseStatPokemon(479,"Mow Rotom","Electric","Grass",520,50,65,107,105,107,86);
        // createBaseStatPokemon(480,"Uxie","Psychic","None",580,75,75,130,75,130,95);
        // createBaseStatPokemon(481,"Mesprit","Psychic","None",580,80,105,105,105,105,80);
        // createBaseStatPokemon(482,"Azelf","Psychic","None",580,75,125,70,125,70,115);
        // createBaseStatPokemon(483,"Dialga","Steel","Dragon",680,100,120,120,150,100,90);
        // createBaseStatPokemon(484,"Palkia","Water","Dragon",680,90,120,100,150,120,100);
        // createBaseStatPokemon(485,"Heatran","Fire","Steel",600,91,90,106,130,106,77);
        // createBaseStatPokemon(486,"Regigigas","Normal","None",670,110,160,110,80,110,100);
        // createBaseStatPokemon(487,"Giratina Altered Forme","Ghost","Dragon",680,150,100,120,100,120,90);
        // createBaseStatPokemon(487,"Giratina Origin Forme","Ghost","Dragon",680,150,120,100,120,100,90);
        // createBaseStatPokemon(488,"Cresselia","Psychic","None",600,120,70,120,75,130,85);
        // createBaseStatPokemon(489,"Phione","Water","None",480,80,80,80,80,80,80);
        // createBaseStatPokemon(490,"Manaphy","Water","None",600,100,100,100,100,100,100);
        // createBaseStatPokemon(491,"Darkrai","Dark","None",600,70,90,90,135,90,125);
        // createBaseStatPokemon(492,"Shaymin Land Forme","Grass","None",600,100,100,100,100,100,100);
        // createBaseStatPokemon(492,"Shaymin Sky Forme","Grass","Flying",600,100,103,75,120,75,127);
        // createBaseStatPokemon(493,"Arceus","Normal","None",720,120,120,120,120,120,120);
        // createBaseStatPokemon(494,"Victini","Psychic","Fire",600,100,100,100,100,100,100);
        // createBaseStatPokemon(495,"Snivy","Grass","None",308,45,45,55,45,55,63);
        // createBaseStatPokemon(496,"Servine","Grass","None",413,60,60,75,60,75,83);
        // createBaseStatPokemon(497,"Serperior","Grass","None",528,75,75,95,75,95,113);
        // createBaseStatPokemon(498,"Tepig","Fire","None",308,65,63,45,45,45,45);
        // createBaseStatPokemon(499,"Pignite","Fire","Fighting",418,90,93,55,70,55,55);
        // createBaseStatPokemon(500,"Emboar","Fire","Fighting",528,110,123,65,100,65,65);
        // createBaseStatPokemon(501,"Oshawott","Water","None",308,55,55,45,63,45,45);
        // createBaseStatPokemon(502,"Dewott","Water","None",413,75,75,60,83,60,60);
        // createBaseStatPokemon(503,"Samurott","Water","None",528,95,100,85,108,70,70);
        // createBaseStatPokemon(504,"Patrat","Normal","None",255,45,55,39,35,39,42);
        // createBaseStatPokemon(505,"Watchog","Normal","None",420,60,85,69,60,69,77);
        // createBaseStatPokemon(506,"Lillipup","Normal","None",275,45,60,45,25,45,55);
        // createBaseStatPokemon(507,"Herdier","Normal","None",370,65,80,65,35,65,60);
        // createBaseStatPokemon(508,"Stoutland","Normal","None",500,85,110,90,45,90,80);
        // createBaseStatPokemon(509,"Purrloin","Dark","None",281,41,50,37,50,37,66);
        // createBaseStatPokemon(510,"Liepard","Dark","None",446,64,88,50,88,50,106);
        // createBaseStatPokemon(511,"Pansage","Grass","None",316,50,53,48,53,48,64);
        // createBaseStatPokemon(512,"Simisage","Grass","None",498,75,98,63,98,63,101);
        // createBaseStatPokemon(513,"Pansear","Fire","None",316,50,53,48,53,48,64);
        // createBaseStatPokemon(514,"Simisear","Fire","None",498,75,98,63,98,63,101);
        // createBaseStatPokemon(515,"Panpour","Water","None",316,50,53,48,53,48,64);
        // createBaseStatPokemon(516,"Simipour","Water","None",498,75,98,63,98,63,101);
        // createBaseStatPokemon(517,"Munna","Psychic","None",292,76,25,45,67,55,24);
        // createBaseStatPokemon(518,"Musharna","Psychic","None",487,116,55,85,107,95,29);
        // createBaseStatPokemon(519,"Pidove","Normal","Flying",264,50,55,50,36,30,43);
        // createBaseStatPokemon(520,"Tranquill","Normal","Flying",358,62,77,62,50,42,65);
        // createBaseStatPokemon(521,"Unfezant","Normal","Flying",488,80,115,80,65,55,93);
        // createBaseStatPokemon(522,"Blitzle","Electric","None",295,45,60,32,50,32,76);
        // createBaseStatPokemon(523,"Zebstrika","Electric","None",497,75,100,63,80,63,116);
        // createBaseStatPokemon(524,"Roggenrola","Rock","None",280,55,75,85,25,25,15);
        // createBaseStatPokemon(525,"Boldore","Rock","None",390,70,105,105,50,40,20);
        // createBaseStatPokemon(526,"Gigalith","Rock","None",515,85,135,130,60,80,25);
        // createBaseStatPokemon(527,"Woobat","Psychic","Flying",313,55,45,43,55,43,72);
        // createBaseStatPokemon(528,"Swoobat","Psychic","Flying",425,67,57,55,77,55,114);
        // createBaseStatPokemon(529,"Drilbur","Ground","None",328,60,85,40,30,45,68);
        // createBaseStatPokemon(530,"Excadrill","Ground","Steel",508,110,135,60,50,65,88);
        // createBaseStatPokemon(531,"Audino","Normal","None",445,103,60,86,60,86,50);
        // createBaseStatPokemon(531,"Mega Audino","Normal","Fairy",545,103,60,126,80,126,50);
        // createBaseStatPokemon(532,"Timburr","Fighting","None",305,75,80,55,25,35,35);
        // createBaseStatPokemon(533,"Gurdurr","Fighting","None",405,85,105,85,40,50,40);
        // createBaseStatPokemon(534,"Conkeldurr","Fighting","None",505,105,140,95,55,65,45);
        // createBaseStatPokemon(535,"Tympole","Water","None",294,50,50,40,50,40,64);
        // createBaseStatPokemon(536,"Palpitoad","Water","Ground",384,75,65,55,65,55,69);
        // createBaseStatPokemon(537,"Seismitoad","Water","Ground",509,105,95,75,85,75,74);
        // createBaseStatPokemon(538,"Throh","Fighting","None",465,120,100,85,30,85,45);
        // createBaseStatPokemon(539,"Sawk","Fighting","None",465,75,125,75,30,75,85);
        // createBaseStatPokemon(540,"Sewaddle","Bug","Grass",310,45,53,70,40,60,42);
        // createBaseStatPokemon(541,"Swadloon","Bug","Grass",380,55,63,90,50,80,42);
        // createBaseStatPokemon(542,"Leavanny","Bug","Grass",500,75,103,80,70,80,92);
        // createBaseStatPokemon(543,"Venipede","Bug","Poison",260,30,45,59,30,39,57);
        // createBaseStatPokemon(544,"Whirlipede","Bug","Poison",360,40,55,99,40,79,47);
        // createBaseStatPokemon(545,"Scolipede","Bug","Poison",485,60,100,89,55,69,112);
        // createBaseStatPokemon(546,"Cottonee","Grass","Fairy",280,40,27,60,37,50,66);
        // createBaseStatPokemon(547,"Whimsicott","Grass","Fairy",480,60,67,85,77,75,116);
        // createBaseStatPokemon(548,"Petilil","Grass","None",280,45,35,50,70,50,30);
        // createBaseStatPokemon(549,"Lilligant","Grass","None",480,70,60,75,110,75,90);
        // createBaseStatPokemon(550,"Basculin","Water","None",460,70,92,65,80,55,98);
        // createBaseStatPokemon(551,"Sandile","Ground","Dark",292,50,72,35,35,35,65);
        // createBaseStatPokemon(552,"Krokorok","Ground","Dark",351,60,82,45,45,45,74);
        // createBaseStatPokemon(553,"Krookodile","Ground","Dark",519,95,117,80,65,70,92);
        // createBaseStatPokemon(554,"Darumaka","Fire","None",315,70,90,45,15,45,50);
        // createBaseStatPokemon(554,"Galarian Darumaka","Ice","None",315,70,90,45,15,45,50);
        // createBaseStatPokemon(555,"Darmanitan Standard Mode","Fire","None",480,105,140,55,30,55,95);
        // createBaseStatPokemon(555,"Galarian Darmanitan Standard Mode","Ice","None",480,105,140,55,30,55,95);
        // createBaseStatPokemon(555,"Darmanitan Zen Mode","Fire","Psychic",540,105,30,105,140,105,55);
        // createBaseStatPokemon(555,"Galarian Darmanitan Zen Mode","Ice","Fire",540,105,160,55,30,55,135);
        // createBaseStatPokemon(556,"Maractus","Grass","None",461,75,86,67,106,67,60);
        // createBaseStatPokemon(557,"Dwebble","Bug","Rock",325,50,65,85,35,35,55);
        // createBaseStatPokemon(558,"Crustle","Bug","Rock",475,70,95,125,65,75,45);
        // createBaseStatPokemon(559,"Scraggy","Dark","Fighting",348,50,75,70,35,70,48);
        // createBaseStatPokemon(560,"Scrafty","Dark","Fighting",488,65,90,115,45,115,58);
        // createBaseStatPokemon(561,"Sigilyph","Psychic","Flying",490,72,58,80,103,80,97);
        // createBaseStatPokemon(562,"Yamask","Ghost","None",303,38,30,85,55,65,30);
        // createBaseStatPokemon(562,"Galarian Yamask","Ground","Ghost",303,38,55,85,30,65,30);
        // createBaseStatPokemon(563,"Cofagrigus","Ghost","None",483,58,50,145,95,105,30);
        // createBaseStatPokemon(564,"Tirtouga","Water","Rock",355,54,78,103,53,45,22);
        // createBaseStatPokemon(565,"Carracosta","Water","Rock",495,74,108,133,83,65,32);
        // createBaseStatPokemon(566,"Archen","Rock","Flying",401,55,112,45,74,45,70);
        // createBaseStatPokemon(567,"Archeops","Rock","Flying",567,75,140,65,112,65,110);
        // createBaseStatPokemon(568,"Trubbish","Poison","None",329,50,50,62,40,62,65);
        // createBaseStatPokemon(569,"Garbodor","Poison","None",474,80,95,82,60,82,75);
        // createBaseStatPokemon(569,"Gigantamax Garbodor","Poison","None",474,80,95,82,60,82,75);
        // createBaseStatPokemon(570,"Zorua","Dark","None",330,40,65,40,80,40,65);
        // createBaseStatPokemon(571,"Zoroark","Dark","None",510,60,105,60,120,60,105);
        // createBaseStatPokemon(572,"Minccino","Normal","None",300,55,50,40,40,40,75);
        // createBaseStatPokemon(573,"Cinccino","Normal","None",470,75,95,60,65,60,115);
        // createBaseStatPokemon(574,"Gothita","Psychic","None",290,45,30,50,55,65,45);
        // createBaseStatPokemon(575,"Gothorita","Psychic","None",390,60,45,70,75,85,55);
        // createBaseStatPokemon(576,"Gothitelle","Psychic","None",490,70,55,95,95,110,65);
        // createBaseStatPokemon(577,"Solosis","Psychic","None",290,45,30,40,105,50,20);
        // createBaseStatPokemon(578,"Duosion","Psychic","None",370,65,40,50,125,60,30);
        // createBaseStatPokemon(579,"Reuniclus","Psychic","None",490,110,65,75,125,85,30);
        // createBaseStatPokemon(580,"Ducklett","Water","Flying",305,62,44,50,44,50,55);
        // createBaseStatPokemon(581,"Swanna","Water","Flying",473,75,87,63,87,63,98);
        // createBaseStatPokemon(582,"Vanillite","Ice","None",305,36,50,50,65,60,44);
        // createBaseStatPokemon(583,"Vanillish","Ice","None",395,51,65,65,80,75,59);
        // createBaseStatPokemon(584,"Vanilluxe","Ice","None",535,71,95,85,110,95,79);
        // createBaseStatPokemon(585,"Deerling","Normal","Grass",335,60,60,50,40,50,75);
        // createBaseStatPokemon(586,"Sawsbuck","Normal","Grass",475,80,100,70,60,70,95);
        // createBaseStatPokemon(587,"Emolga","Electric","Flying",428,55,75,60,75,60,103);
        // createBaseStatPokemon(588,"Karrablast","Bug","None",315,50,75,45,40,45,60);
        // createBaseStatPokemon(589,"Escavalier","Bug","Steel",495,70,135,105,60,105,20);
        // createBaseStatPokemon(590,"Foongus","Grass","Poison",294,69,55,45,55,55,15);
        // createBaseStatPokemon(591,"Amoonguss","Grass","Poison",464,114,85,70,85,80,30);
        // createBaseStatPokemon(592,"Frillish","Water","Ghost",335,55,40,50,65,85,40);
        // createBaseStatPokemon(593,"Jellicent","Water","Ghost",480,100,60,70,85,105,60);
        // createBaseStatPokemon(594,"Alomomola","Water","None",470,165,75,80,40,45,65);
        // createBaseStatPokemon(595,"Joltik","Bug","Electric",319,50,47,50,57,50,65);
        // createBaseStatPokemon(596,"Galvantula","Bug","Electric",472,70,77,60,97,60,108);
        // createBaseStatPokemon(597,"Ferroseed","Grass","Steel",305,44,50,91,24,86,10);
        // createBaseStatPokemon(598,"Ferrothorn","Grass","Steel",489,74,94,131,54,116,20);
        // createBaseStatPokemon(599,"Klink","Steel","None",300,40,55,70,45,60,30);
        // createBaseStatPokemon(600,"Klang","Steel","None",440,60,80,95,70,85,50);
        // createBaseStatPokemon(601,"Klinklang","Steel","None",520,60,100,115,70,85,90);
        // createBaseStatPokemon(602,"Tynamo","Electric","None",275,35,55,40,45,40,60);
        // createBaseStatPokemon(603,"Eelektrik","Electric","None",405,65,85,70,75,70,40);
        // createBaseStatPokemon(604,"Eelektross","Electric","None",515,85,115,80,105,80,50);
        // createBaseStatPokemon(605,"Elgyem","Psychic","None",335,55,55,55,85,55,30);
        // createBaseStatPokemon(606,"Beheeyem","Psychic","None",485,75,75,75,125,95,40);
        // createBaseStatPokemon(607,"Litwick","Ghost","Fire",275,50,30,55,65,55,20);
        // createBaseStatPokemon(608,"Lampent","Ghost","Fire",370,60,40,60,95,60,55);
        // createBaseStatPokemon(609,"Chandelure","Ghost","Fire",520,60,55,90,145,90,80);
        // createBaseStatPokemon(610,"Axew","Dragon","None",320,46,87,60,30,40,57);
        // createBaseStatPokemon(611,"Fraxure","Dragon","None",410,66,117,70,40,50,67);
        // createBaseStatPokemon(612,"Haxorus","Dragon","None",540,76,147,90,60,70,97);
        // createBaseStatPokemon(613,"Cubchoo","Ice","None",305,55,70,40,60,40,40);
        // createBaseStatPokemon(614,"Beartic","Ice","None",485,95,110,80,70,80,50);
        // createBaseStatPokemon(615,"Cryogonal","Ice","None",485,70,50,30,95,135,105);
        // createBaseStatPokemon(616,"Shelmet","Bug","None",305,50,40,85,40,65,25);
        // createBaseStatPokemon(617,"Accelgor","Bug","None",495,80,70,40,100,60,145);
        // createBaseStatPokemon(618,"Stunfisk","Ground","Electric",471,109,66,84,81,99,32);
        // createBaseStatPokemon(618,"Galarian Stunfisk","Ground","Steel",471,109,81,99,66,84,32);
        // createBaseStatPokemon(619,"Mienfoo","Fighting","None",350,45,85,50,55,50,65);
        // createBaseStatPokemon(620,"Mienshao","Fighting","None",510,65,125,60,95,60,105);
        // createBaseStatPokemon(621,"Druddigon","Dragon","None",485,77,120,90,60,90,48);
        // createBaseStatPokemon(622,"Golett","Ground","Ghost",303,59,74,50,35,50,35);
        // createBaseStatPokemon(623,"Golurk","Ground","Ghost",483,89,124,80,55,80,55);
        // createBaseStatPokemon(624,"Pawniard","Dark","Steel",340,45,85,70,40,40,60);
        // createBaseStatPokemon(625,"Bisharp","Dark","Steel",490,65,125,100,60,70,70);
        // createBaseStatPokemon(626,"Bouffalant","Normal","None",490,95,110,95,40,95,55);
        // createBaseStatPokemon(627,"Rufflet","Normal","Flying",350,70,83,50,37,50,60);
        // createBaseStatPokemon(628,"Braviary","Normal","Flying",510,100,123,75,57,75,80);
        // createBaseStatPokemon(629,"Vullaby","Dark","Flying",370,70,55,75,45,65,60);
        // createBaseStatPokemon(630,"Mandibuzz","Dark","Flying",510,110,65,105,55,95,80);
        // createBaseStatPokemon(631,"Heatmor","Fire","None",484,85,97,66,105,66,65);
        // createBaseStatPokemon(632,"Durant","Bug","Steel",484,58,109,112,48,48,109);
        // createBaseStatPokemon(633,"Deino","Dark","Dragon",300,52,65,50,45,50,38);
        // createBaseStatPokemon(634,"Zweilous","Dark","Dragon",420,72,85,70,65,70,58);
        // createBaseStatPokemon(635,"Hydreigon","Dark","Dragon",600,92,105,90,125,90,98);
        // createBaseStatPokemon(636,"Larvesta","Bug","Fire",360,55,85,55,50,55,60);
        // createBaseStatPokemon(637,"Volcarona","Bug","Fire",550,85,60,65,135,105,100);
        // createBaseStatPokemon(638,"Cobalion","Steel","Fighting",580,91,90,129,90,72,108);
        // createBaseStatPokemon(639,"Terrakion","Rock","Fighting",580,91,129,90,72,90,108);
        // createBaseStatPokemon(640,"Virizion","Grass","Fighting",580,91,90,72,90,129,108);
        // createBaseStatPokemon(641,"Tornadus Incarnate Forme","Flying","None",580,79,115,70,125,80,111);
        // createBaseStatPokemon(641,"Tornadus Therian Forme","Flying","None",580,79,100,80,110,90,121);
        // createBaseStatPokemon(642,"Thundurus Incarnate Forme","Electric","Flying",580,79,115,70,125,80,111);
        // createBaseStatPokemon(642,"Thundurus Therian Forme","Electric","Flying",580,79,105,70,145,80,101);
        // createBaseStatPokemon(643,"Reshiram","Dragon","Fire",680,100,120,100,150,120,90);
        // createBaseStatPokemon(644,"Zekrom","Dragon","Electric",680,100,150,120,120,100,90);
        // createBaseStatPokemon(645,"Landorus Incarnate Forme","Ground","Flying",600,89,125,90,115,80,101);
        // createBaseStatPokemon(645,"Landorus Therian Forme","Ground","Flying",600,89,145,90,105,80,91);
        // createBaseStatPokemon(646,"Kyurem","Dragon","Ice",660,125,130,90,130,90,95);
        // createBaseStatPokemon(646,"Black Kyurem","Dragon","Ice",700,125,170,100,120,90,95);
        // createBaseStatPokemon(646,"White Kyurem","Dragon","Ice",700,125,120,90,170,100,95);
        // createBaseStatPokemon(647,"Keldeo Ordinary Forme","Water","Fighting",580,91,72,90,129,90,108);
        // createBaseStatPokemon(647,"Keldeo Resolute Forme","Water","Fighting",580,91,72,90,129,90,108);
        // createBaseStatPokemon(648,"Meloetta Aria Forme","Normal","Psychic",600,100,77,77,128,128,90);
        // createBaseStatPokemon(648,"Meloetta Pirouette Forme","Normal","Fighting",600,100,128,90,77,77,128);
        // createBaseStatPokemon(649,"Genesect","Bug","Steel",600,71,120,95,120,95,99);
        // createBaseStatPokemon(650,"Chespin","Grass","None",313,56,61,65,48,45,38);
        // createBaseStatPokemon(651,"Quilladin","Grass","None",405,61,78,95,56,58,57);
        // createBaseStatPokemon(652,"Chesnaught","Grass","Fighting",530,88,107,122,74,75,64);
        // createBaseStatPokemon(653,"Fennekin","Fire","None",307,40,45,40,62,60,60);
        // createBaseStatPokemon(654,"Braixen","Fire","None",409,59,59,58,90,70,73);
        // createBaseStatPokemon(655,"Delphox","Fire","Psychic",534,75,69,72,114,100,104);
        // createBaseStatPokemon(656,"Froakie","Water","None",314,41,56,40,62,44,71);
        // createBaseStatPokemon(657,"Frogadier","Water","None",405,54,63,52,83,56,97);
        // createBaseStatPokemon(658,"Greninja","Water","Dark",530,72,95,67,103,71,122);
        // createBaseStatPokemon(658,"Ash-Greninja","Water","Dark",640,72,145,67,153,71,132);
        // createBaseStatPokemon(659,"Bunnelby","Normal","None",237,38,36,38,32,36,57);
        // createBaseStatPokemon(660,"Diggersby","Normal","Ground",423,85,56,77,50,77,78);
        // createBaseStatPokemon(661,"Fletchling","Normal","Flying",278,45,50,43,40,38,62);
        // createBaseStatPokemon(662,"Fletchinder","Fire","Flying",382,62,73,55,56,52,84);
        // createBaseStatPokemon(663,"Talonflame","Fire","Flying",499,78,81,71,74,69,126);
        // createBaseStatPokemon(664,"Scatterbug","Bug","None",200,38,35,40,27,25,35);
        // createBaseStatPokemon(665,"Spewpa","Bug","None",213,45,22,60,27,30,29);
        // createBaseStatPokemon(666,"Vivillon","Bug","Flying",411,80,52,50,90,50,89);
        // createBaseStatPokemon(667,"Litleo","Fire","Normal",369,62,50,58,73,54,72);
        // createBaseStatPokemon(668,"Pyroar","Fire","Normal",507,86,68,72,109,66,106);
        // createBaseStatPokemon(669,"Flabébé","Fairy","None",303,44,38,39,61,79,42);
        // createBaseStatPokemon(670,"Floette","Fairy","None",371,54,45,47,75,98,52);
        // createBaseStatPokemon(671,"Florges","Fairy","None",552,78,65,68,112,154,75);
        // createBaseStatPokemon(672,"Skiddo","Grass","None",350,66,65,48,62,57,52);
        // createBaseStatPokemon(673,"Gogoat","Grass","None",531,123,100,62,97,81,68);
        // createBaseStatPokemon(674,"Pancham","Fighting","None",348,67,82,62,46,48,43);
        // createBaseStatPokemon(675,"Pangoro","Fighting","Dark",495,95,124,78,69,71,58);
        // createBaseStatPokemon(676,"Furfrou","Normal","None",472,75,80,60,65,90,102);
        // createBaseStatPokemon(677,"Espurr","Psychic","None",355,62,48,54,63,60,68);
        // createBaseStatPokemon(678,"Meowstic Male","Psychic","None",466,74,48,76,83,81,104);
        // createBaseStatPokemon(678,"Meowstic Female","Psychic","None",466,74,48,76,83,81,104);
        // createBaseStatPokemon(679,"Honedge","Steel","Ghost",325,45,80,100,35,37,28);
        // createBaseStatPokemon(680,"Doublade","Steel","Ghost",448,59,110,150,45,49,35);
        // createBaseStatPokemon(681,"Aegislash Blade Forme","Steel","Ghost",520,60,150,50,150,50,60);
        // createBaseStatPokemon(681,"Aegislash Shield Forme","Steel","Ghost",520,60,50,150,50,150,60);
        // createBaseStatPokemon(682,"Spritzee","Fairy","None",341,78,52,60,63,65,23);
        // createBaseStatPokemon(683,"Aromatisse","Fairy","None",462,101,72,72,99,89,29);
        // createBaseStatPokemon(684,"Swirlix","Fairy","None",341,62,48,66,59,57,49);
        // createBaseStatPokemon(685,"Slurpuff","Fairy","None",480,82,80,86,85,75,72);
        // createBaseStatPokemon(686,"Inkay","Dark","Psychic",288,53,54,53,37,46,45);
        // createBaseStatPokemon(687,"Malamar","Dark","Psychic",482,86,92,88,68,75,73);
        // createBaseStatPokemon(688,"Binacle","Rock","Water",306,42,52,67,39,56,50);
        // createBaseStatPokemon(689,"Barbaracle","Rock","Water",500,72,105,115,54,86,68);
        // createBaseStatPokemon(690,"Skrelp","Poison","Water",320,50,60,60,60,60,30);
        // createBaseStatPokemon(691,"Dragalge","Poison","Dragon",494,65,75,90,97,123,44);
        // createBaseStatPokemon(692,"Clauncher","Water","None",330,50,53,62,58,63,44);
        // createBaseStatPokemon(693,"Clawitzer","Water","None",500,71,73,88,120,89,59);
        // createBaseStatPokemon(694,"Helioptile","Electric","Normal",289,44,38,33,61,43,70);
        // createBaseStatPokemon(695,"Heliolisk","Electric","Normal",481,62,55,52,109,94,109);
        // createBaseStatPokemon(696,"Tyrunt","Rock","Dragon",362,58,89,77,45,45,48);
        // createBaseStatPokemon(697,"Tyrantrum","Rock","Dragon",521,82,121,119,69,59,71);
        // createBaseStatPokemon(698,"Amaura","Rock","Ice",362,77,59,50,67,63,46);
        // createBaseStatPokemon(699,"Aurorus","Rock","Ice",521,123,77,72,99,92,58);
        // createBaseStatPokemon(700,"Sylveon","Fairy","None",525,95,65,65,110,130,60);
        // createBaseStatPokemon(701,"Hawlucha","Fighting","Flying",500,78,92,75,74,63,118);
        // createBaseStatPokemon(702,"Dedenne","Electric","Fairy",431,67,58,57,81,67,101);
        // createBaseStatPokemon(703,"Carbink","Rock","Fairy",500,50,50,150,50,150,50);
        // createBaseStatPokemon(704,"Goomy","Dragon","None",300,45,50,35,55,75,40);
        // createBaseStatPokemon(705,"Sliggoo","Dragon","None",452,68,75,53,83,113,60);
        // createBaseStatPokemon(706,"Goodra","Dragon","None",600,90,100,70,110,150,80);
        // createBaseStatPokemon(707,"Klefki","Steel","Fairy",470,57,80,91,80,87,75);
        // createBaseStatPokemon(708,"Phantump","Ghost","Grass",309,43,70,48,50,60,38);
        // createBaseStatPokemon(709,"Trevenant","Ghost","Grass",474,85,110,76,65,82,56);
        // createBaseStatPokemon(710,"Pumpkaboo Average Size","Ghost","Grass",335,49,66,70,44,55,51);
        // createBaseStatPokemon(710,"Pumpkaboo Small Size","Ghost","Grass",335,44,66,70,44,55,56);
        // createBaseStatPokemon(710,"Pumpkaboo Large Size","Ghost","Grass",335,54,66,70,44,55,46);
        // createBaseStatPokemon(710,"Pumpkaboo Super Size","Ghost","Grass",335,59,66,70,44,55,41);
        // createBaseStatPokemon(711,"Gourgeist Average Size","Ghost","Grass",494,65,90,122,58,75,84);
        // createBaseStatPokemon(711,"Gourgeist Small Size","Ghost","Grass",494,55,85,122,58,75,99);
        // createBaseStatPokemon(711,"Gourgeist Large Size","Ghost","Grass",494,75,95,122,58,75,69);
        // createBaseStatPokemon(711,"Gourgeist Super Size","Ghost","Grass",494,85,100,122,58,75,54);
        // createBaseStatPokemon(712,"Bergmite","Ice","None",304,55,69,85,32,35,28);
        // createBaseStatPokemon(713,"Avalugg","Ice","None",514,95,117,184,44,46,28);
        // createBaseStatPokemon(714,"Noibat","Flying","Dragon",245,40,30,35,45,40,55);
        // createBaseStatPokemon(715,"Noivern","Flying","Dragon",535,85,70,80,97,80,123);
        // createBaseStatPokemon(716,"Xerneas","Fairy","None",680,126,131,95,131,98,99);
        // createBaseStatPokemon(717,"Yveltal","Dark","Flying",680,126,131,95,131,98,99);
        // createBaseStatPokemon(718,"Zygarde 10% Forme","Dragon","Ground",486,54,100,71,61,85,115);
        // createBaseStatPokemon(718,"Zygarde 50% Forme","Dragon","Ground",600,108,100,121,81,95,95);
        // createBaseStatPokemon(718,"Zygarde Complete Forme","Dragon","Ground",708,216,100,121,91,95,85);
        // createBaseStatPokemon(719,"Diancie","Rock","Fairy",600,50,100,150,100,150,50);
        // createBaseStatPokemon(719,"Mega Diancie","Rock","Fairy",700,50,160,110,160,110,110);
        // createBaseStatPokemon(720,"Hoopa Confined","Psychic","Ghost",600,80,110,60,150,130,70);
        // createBaseStatPokemon(720,"Hoopa Unbound","Psychic","Dark",680,80,160,60,170,130,80);
        // createBaseStatPokemon(721,"Volcanion","Fire","Water",600,80,110,120,130,90,70);
        // createBaseStatPokemon(722,"Rowlet","Grass","Flying",320,68,55,55,50,50,42);
        // createBaseStatPokemon(723,"Dartrix","Grass","Flying",420,78,75,75,70,70,52);
        // createBaseStatPokemon(724,"Decidueye","Grass","Ghost",530,78,107,75,100,100,70);
        // createBaseStatPokemon(725,"Litten","Fire","None",320,45,65,40,60,40,70);
        // createBaseStatPokemon(726,"Torracat","Fire","None",420,65,85,50,80,50,90);
        // createBaseStatPokemon(727,"Incineroar","Fire","Dark",530,95,115,90,80,90,60);
        // createBaseStatPokemon(728,"Popplio","Water","None",320,50,54,54,66,56,40);
        // createBaseStatPokemon(729,"Brionne","Water","None",420,60,69,69,91,81,50);
        // createBaseStatPokemon(730,"Primarina","Water","Fairy",530,80,74,74,126,116,60);
        // createBaseStatPokemon(731,"Pikipek","Normal","Flying",265,35,75,30,30,30,65);
        // createBaseStatPokemon(732,"Trumbeak","Normal","Flying",355,55,85,50,40,50,75);
        // createBaseStatPokemon(733,"Toucannon","Normal","Flying",485,80,120,75,75,75,60);
        // createBaseStatPokemon(734,"Yungoos","Normal","None",253,48,70,30,30,30,45);
        // createBaseStatPokemon(735,"Gumshoos","Normal","None",418,88,110,60,55,60,45);
        // createBaseStatPokemon(736,"Grubbin","Bug","None",300,47,62,45,55,45,46);
        // createBaseStatPokemon(737,"Charjabug","Bug","Electric",400,57,82,95,55,75,36);
        // createBaseStatPokemon(738,"Vikavolt","Bug","Electric",500,77,70,90,145,75,43);
        // createBaseStatPokemon(739,"Crabrawler","Fighting","None",338,47,82,57,42,47,63);
        // createBaseStatPokemon(740,"Crabominable","Fighting","Ice",478,97,132,77,62,67,43);
        // createBaseStatPokemon(741,"Oricorio Baile Style","Fire","Flying",476,75,70,70,98,70,93);
        // createBaseStatPokemon(741,"Oricorio Pom-Pom Style","Electric","Flying",476,75,70,70,98,70,93);
        // createBaseStatPokemon(741,"Oricorio P'au Style","Psychic","Flying",476,75,70,70,98,70,93);
        // createBaseStatPokemon(741,"Oricorio Sensu Style","Ghost","Flying",476,75,70,70,98,70,93);
        // createBaseStatPokemon(742,"Cutiefly","Bug","Fairy",304,40,45,40,55,40,84);
        // createBaseStatPokemon(743,"Ribombee","Bug","Fairy",464,60,55,60,95,70,124);
        // createBaseStatPokemon(744,"Rockruff","Rock","None",280,45,65,40,30,40,60);
        // createBaseStatPokemon(745,"Lycanroc Midday Forme","Rock","None",487,75,115,65,55,65,112);
        // createBaseStatPokemon(745,"Lycanroc Midnight Forme","Rock","None",487,85,115,75,55,75,82);
        // createBaseStatPokemon(745,"Lycanroc Dusk Forme","Rock","None",487,75,117,65,55,65,110);
        // createBaseStatPokemon(746,"Wishiwashi Solo Forme","Water","None",175,45,20,20,25,25,40);
        // createBaseStatPokemon(746,"Wishiwashi School Forme","Water","None",620,45,140,130,140,135,30);
        // createBaseStatPokemon(747,"Mareanie","Poison","Water",305,50,53,62,43,52,45);
        // createBaseStatPokemon(748,"Toxapex","Poison","Water",495,50,63,152,53,142,35);
        // createBaseStatPokemon(749,"Mudbray","Ground","None",385,70,100,70,45,55,45);
        // createBaseStatPokemon(750,"Mudsdale","Ground","None",500,100,125,100,55,85,35);
        // createBaseStatPokemon(751,"Dewpider","Water","Bug",269,38,40,52,40,72,27);
        // createBaseStatPokemon(752,"Araquanid","Water","Bug",454,68,70,92,50,132,42);
        // createBaseStatPokemon(753,"Fomantis","Grass","None",250,40,55,35,50,35,35);
        // createBaseStatPokemon(754,"Lurantis","Grass","None",480,70,105,90,80,90,45);
        // createBaseStatPokemon(755,"Morelull","Grass","Fairy",285,40,35,55,65,75,15);
        // createBaseStatPokemon(756,"Shiinotic","Grass","Fairy",405,60,45,80,90,100,30);
        // createBaseStatPokemon(757,"Salandit","Poison","Fire",320,48,44,40,71,40,77);
        // createBaseStatPokemon(758,"Salazzle","Poison","Fire",480,68,64,60,111,60,117);
        // createBaseStatPokemon(759,"Stufful","Normal","Fighting",340,70,75,50,45,50,50);
        // createBaseStatPokemon(760,"Bewear","Normal","Fighting",500,120,125,80,55,60,60);
        // createBaseStatPokemon(761,"Bounsweet","Grass","None",210,42,30,38,30,38,32);
        // createBaseStatPokemon(762,"Steenee","Grass","None",290,52,40,48,40,48,62);
        // createBaseStatPokemon(763,"Tsareena","Grass","None",510,72,120,98,50,98,72);
        // createBaseStatPokemon(764,"Comfey","Fairy","None",485,51,52,90,82,110,100);
        // createBaseStatPokemon(765,"Oranguru","Normal","Psychic",490,90,60,80,90,110,60);
        // createBaseStatPokemon(766,"Passimian","Fighting","None",490,100,120,90,40,60,80);
        // createBaseStatPokemon(767,"Wimpod","Bug","Water",230,25,35,40,20,30,80);
        // createBaseStatPokemon(768,"Golisopod","Bug","Water",530,75,125,140,60,90,40);
        // createBaseStatPokemon(769,"Sandygast","Ghost","Ground",320,55,55,80,70,45,15);
        // createBaseStatPokemon(770,"Palossand","Ghost","Ground",480,85,75,110,100,75,35);
        // createBaseStatPokemon(771,"Pyukumuku","Water","None",410,55,60,130,30,130,5);
        // createBaseStatPokemon(772,"Type: Null","Normal","None",534,95,95,95,95,95,59);
        // createBaseStatPokemon(773,"Silvally","Normal","None",570,95,95,95,95,95,95);
        // createBaseStatPokemon(774,"Minior Meteor Forme","Rock","Flying",440,60,60,100,60,100,60);
        // createBaseStatPokemon(774,"Minior Core Forme","Rock","Flying",500,60,100,60,100,60,120);
        // createBaseStatPokemon(775,"Komala","Normal","None",480,65,115,65,75,95,65);
        // createBaseStatPokemon(776,"Turtonator","Fire","Dragon",485,60,78,135,91,85,36);
        // createBaseStatPokemon(777,"Togedemaru","Electric","Steel",435,65,98,63,40,73,96);
        // createBaseStatPokemon(778,"Mimikyu","Ghost","Fairy",476,55,90,80,50,105,96);
        // createBaseStatPokemon(779,"Bruxish","Water","Psychic",475,68,105,70,70,70,92);
        // createBaseStatPokemon(780,"Drampa","Normal","Dragon",485,78,60,85,135,91,36);
        // createBaseStatPokemon(781,"Dhelmise","Ghost","Grass",517,70,131,100,86,90,40);
        // createBaseStatPokemon(782,"Jangmo-o","Dragon","None",300,45,55,65,45,45,45);
        // createBaseStatPokemon(783,"Hakamo-o","Dragon","Fighting",420,55,75,90,65,70,65);
        // createBaseStatPokemon(784,"Kommo-o","Dragon","Fighting",600,75,110,125,100,105,85);
        // createBaseStatPokemon(785,"Tapu Koko","Electric","Fairy",570,70,115,85,95,75,130);
        // createBaseStatPokemon(786,"Tapu Lele","Psychic","Fairy",570,70,85,75,130,115,95);
        // createBaseStatPokemon(787,"Tapu Bulu","Grass","Fairy",570,70,130,115,85,95,75);
        // createBaseStatPokemon(788,"Tapu Fini","Water","Fairy",570,70,75,115,95,130,85);
        // createBaseStatPokemon(789,"Cosmog","Psychic","None",200,43,29,31,29,31,37);
        // createBaseStatPokemon(790,"Cosmoem","Psychic","None",400,43,29,131,29,131,37);
        // createBaseStatPokemon(791,"Solgaleo","Psychic","Steel",680,137,137,107,113,89,97);
        // createBaseStatPokemon(792,"Lunala","Psychic","Ghost",680,137,113,89,137,107,97);
        // createBaseStatPokemon(793,"Nihilego","Rock","Poison",570,109,53,47,127,131,103);
        // createBaseStatPokemon(794,"Buzzwole","Bug","Fighting",570,107,139,139,53,53,79);
        // createBaseStatPokemon(795,"Pheromosa","Bug","Fighting",570,71,137,37,137,37,151);
        // createBaseStatPokemon(796,"Xurkitree","Electric","None",570,83,89,71,173,71,83);
        // createBaseStatPokemon(797,"Celesteela","Steel","Flying",570,97,101,103,107,101,61);
        // createBaseStatPokemon(798,"Kartana","Grass","Steel",570,59,181,131,59,31,109);
        // createBaseStatPokemon(799,"Guzzlord","Dark","Dragon",570,223,101,53,97,53,43);
        // createBaseStatPokemon(800,"Necrozma","Psychic","None",600,97,107,101,127,89,79);
        // createBaseStatPokemon(800,"Dusk Mane Necrozma","Psychic","Steel",680,97,157,127,113,109,77);
        // createBaseStatPokemon(800,"Dawn Wings Necrozma","Psychic","Ghost",680,97,113,109,157,127,77);
        // createBaseStatPokemon(800,"Ultra Necrozma","Psychic","Dragon",754,97,167,97,167,97,129);
        // createBaseStatPokemon(801,"Magearna","Steel","Fairy",600,80,95,115,130,115,65);
        // createBaseStatPokemon(802,"Marshadow","Fighting","Ghost",600,90,125,80,90,90,125);
        // createBaseStatPokemon(803,"Poipole","Poison","None",420,67,73,67,73,67,73);
        // createBaseStatPokemon(804,"Naganadel","Poison","Dragon",540,73,73,73,127,73,121);
        // createBaseStatPokemon(805,"Stakataka","Rock","Steel",570,61,131,211,53,101,13);
        // createBaseStatPokemon(806,"Blacephalon","Fire","Ghost",570,53,127,53,151,79,107);
        // createBaseStatPokemon(807,"Zeraora","Electric","None",600,88,112,75,102,80,143);
        // createBaseStatPokemon(808,"Meltan","Steel","None",300,46,65,65,55,35,34);
        // createBaseStatPokemon(809,"Melmetal","Steel","None",600,135,143,143,80,65,34);
        // createBaseStatPokemon(809,"Gigantamax Melmetal","Steel","None",600,135,143,143,80,65,34);
        // createBaseStatPokemon(810,"Grookey","Grass","None",310,50,65,50,40,40,65);
        // createBaseStatPokemon(811,"Thwackey","Grass","None",420,70,85,70,55,60,80);
        // createBaseStatPokemon(812,"Rillaboom","Grass","None",530,100,125,90,60,70,85);
        // createBaseStatPokemon(812,"Gigantamax Rillaboom","Grass","None",530,100,125,90,60,70,85);
        // createBaseStatPokemon(813,"Scorbunny","Fire","None",310,50,71,40,40,40,69);
        // createBaseStatPokemon(814,"Raboot","Fire","None",420,65,86,60,55,60,94);
        // createBaseStatPokemon(815,"Cinderace","Fire","None",530,80,116,75,65,75,119);
        // createBaseStatPokemon(815,"Gigantamax Cinderace","Fire","None",530,80,116,75,65,75,119);
        // createBaseStatPokemon(816,"Sobble","Water","None",310,50,40,40,70,40,70);
        // createBaseStatPokemon(817,"Drizzile","Water","None",420,65,60,55,95,55,90);
        // createBaseStatPokemon(818,"Inteleon","Water","None",530,70,85,65,125,65,120);
        // createBaseStatPokemon(818,"Gigantamax Inteleon","Water","None",530,70,85,65,125,65,120);
        // createBaseStatPokemon(819,"Skwovet","Normal","None",275,70,55,55,35,35,25);
        // createBaseStatPokemon(820,"Greedent","Normal","None",460,120,95,95,55,75,20);
        // createBaseStatPokemon(821,"Rookidee","Flying","None",245,38,47,35,33,35,57);
        // createBaseStatPokemon(822,"Corvisquire","Flying","None",365,68,67,55,43,55,77);
        // createBaseStatPokemon(823,"Corviknight","Flying","Steel",495,98,87,105,53,85,67);
        // createBaseStatPokemon(823,"Gigantamax Corviknight","Flying","Steel",495,98,87,105,53,85,67);
        // createBaseStatPokemon(824,"Blipbug","Bug","None",180,25,20,20,25,45,45);
        // createBaseStatPokemon(825,"Dottler","Bug","Psychic",335,50,35,80,50,90,30);
        // createBaseStatPokemon(826,"Orbeetle","Bug","Psychic",505,60,45,110,80,120,90);
        // createBaseStatPokemon(826,"Gigantamax Orbeetle","Bug","Psychic",505,60,45,110,80,120,90);
        // createBaseStatPokemon(827,"Nickit","Dark","None",245,40,28,28,47,52,50);
        // createBaseStatPokemon(828,"Thievul","Dark","None",455,70,58,58,87,92,90);
        // createBaseStatPokemon(829,"Gossifleur","Grass","None",250,40,40,60,40,60,10);
        // createBaseStatPokemon(830,"Eldegoss","Graass","None",460,60,50,90,80,120,60);
        // createBaseStatPokemon(831,"Wooloo","Normal","None",270,42,40,55,40,45,48);
        // createBaseStatPokemon(832,"Dubwool","Normal","None",490,72,80,100,60,90,88);
        // createBaseStatPokemon(833,"Chewtle","Water","None",284,50,64,50,38,38,44);
        // createBaseStatPokemon(834,"Drednaw","Water","Rock",485,90,115,90,48,68,74);
        // createBaseStatPokemon(834,"Gigantamax Drednaw","Water","Rock",485,90,115,90,48,68,74);
        // createBaseStatPokemon(835,"Yamper","Electric","None",270,59,45,50,40,50,26);
        // createBaseStatPokemon(836,"Boltund","Electric","None",490,69,90,60,90,60,121);
        // createBaseStatPokemon(837,"Rolycoly","Rock","None",240,30,40,50,40,50,30);
        // createBaseStatPokemon(838,"Carkol","Rock","Fire",410,80,60,90,60,70,50);
        // createBaseStatPokemon(839,"Coalossal","Rock","Fire",510,110,80,120,80,90,30);
        // createBaseStatPokemon(839,"Gigantamax Coalossal","Rock","Fire",510,110,80,120,80,90,30);
        // createBaseStatPokemon(840,"Applin","Grass","Dragon",260,40,40,80,40,40,20);
        // createBaseStatPokemon(841,"Flapple","Grass","Dragon",485,70,110,80,95,60,70);
        // createBaseStatPokemon(841,"Gigantamax Flapple","Grass","Dragon",485,70,110,80,95,60,70);
        // createBaseStatPokemon(842,"Appletun","Grass","Dragon",485,110,85,80,100,80,30);
        // createBaseStatPokemon(842,"Gigantamax Appletun","Grass","Dragon",485,110,85,80,100,80,30);
        // createBaseStatPokemon(843,"Silicobra","Ground","None",315,52,57,75,35,50,46);
        // createBaseStatPokemon(844,"Sandaconda","Ground","None",510,72,107,125,65,70,71);
        // createBaseStatPokemon(844,"Gigantamax Sandaconda","Ground","None",510,72,107,125,65,70,71);
        // createBaseStatPokemon(845,"Cramorant","Flying","Water",475,70,85,55,85,95,85);
        // createBaseStatPokemon(846,"Arrokuda","Water","None",280,41,63,40,40,30,66);
        // createBaseStatPokemon(847,"Barraskewda","Water","None",490,61,123,60,60,50,136);
        // createBaseStatPokemon(848,"Toxel","Electric","Poison",242,40,38,35,54,35,40);
        // createBaseStatPokemon(849,"Toxtricity Amped Forme","Electric","Poison",502,75,98,70,114,70,75);
        // createBaseStatPokemon(849,"Toxitricity Low Key Forme","Electric","Poison",502,75,98,70,114,70,75);
        // createBaseStatPokemon(849,"Gigantamax Toxitricity","Electric","Poison",502,75,98,70,114,70,75);
        // createBaseStatPokemon(850,"Sizzlipede","Fire","Bug",305,50,65,45,50,50,45);
        // createBaseStatPokemon(851,"Centiskorch","Fire","Bug",525,100,115,65,90,90,65);
        // createBaseStatPokemon(851,"Gigantamax Centiskorch","Fire","Bug",525,100,115,65,90,90,65);
        // createBaseStatPokemon(852,"Clobbopus","Fighting","None",310,50,68,60,50,50,32);
        // createBaseStatPokemon(853,"Grapploct","Fighting","None",480,80,118,90,70,80,42);
        // createBaseStatPokemon(854,"Sinistea","Ghost","None",308,40,45,45,74,54,50);
        // createBaseStatPokemon(855,"Polteageist","Ghost","None",508,60,65,65,134,114,70);
        // createBaseStatPokemon(856,"Hatenna","Psychic","None",265,42,30,45,56,53,39);
        // createBaseStatPokemon(857,"Hattrem","Psychic","None",370,57,40,65,86,73,49);
        // createBaseStatPokemon(858,"Hatterene","Psychic","Fairy",510,57,90,95,136,103,29);
        // createBaseStatPokemon(858,"Gigantamax Hatterene","Psychic","Fairy",510,57,90,95,136,103,29);
        // createBaseStatPokemon(859,"Impidimp","Dark","Fairy",265,45,45,30,55,40,50);
        // createBaseStatPokemon(860,"Morgrem","Dark","Fairy",370,65,60,45,75,55,70);
        // createBaseStatPokemon(861,"Grimmsnarl","Dark","Fairy",510,95,120,65,95,75,60);
        // createBaseStatPokemon(861,"Gigantamax Grimmsnarl","Dark","Fairy",510,95,120,65,95,75,60);
        // createBaseStatPokemon(862,"Obstagoon","Dark","Normal",520,93,90,101,60,81,95);
        // createBaseStatPokemon(863,"Perrserker","Steel","None",440,70,110,100,50,60,50);
        // createBaseStatPokemon(864,"Cursola","Ghost","None",510,60,95,50,145,130,30);
        // createBaseStatPokemon(865,"Sirfetch'd","Fighting","None",507,62,135,95,68,82,65);
        // createBaseStatPokemon(866,"Mr. Rime","Ice","Psychic",520,80,85,75,110,100,70);
        // createBaseStatPokemon(867,"Runerigus","Ground","Ghost",483,58,95,145,50,105,30);
        // createBaseStatPokemon(868,"Milcery","Fairy","None",270,45,40,40,50,61,34);
        // createBaseStatPokemon(869,"Alcremie","Fairy","None",495,65,60,75,110,121,64);
        // createBaseStatPokemon(869,"Gigantamax Alcremie","Fairy","None",495,65,60,75,110,121,64);
        // createBaseStatPokemon(870,"Falinks","Fighting","None",470,65,100,100,70,60,75);
        // createBaseStatPokemon(871,"Pincurchin","Electric","None",435,48,101,95,91,85,15);
        // createBaseStatPokemon(872,"Snom","Ice","Bug",185,30,25,35,45,30,20);
        // createBaseStatPokemon(873,"Frosmoth","Ice","Bug",475,70,65,60,125,90,65);
        // createBaseStatPokemon(874,"Stonjourner","Rock","None",470,100,125,135,20,20,70);
        // createBaseStatPokemon(875,"Eiscue Ice Face","Ice","None",470,75,80,110,65,90,50);
        // createBaseStatPokemon(875,"Eiscue Noice Face","Ice","None",470,75,80,70,65,50,130);
        // createBaseStatPokemon(876,"Indeedee Male","Psychic","Normal",475,60,65,55,105,95,95);
        // createBaseStatPokemon(876,"Indeedee Female","Psychic","Normal",475,70,55,65,95,105,85);
        // createBaseStatPokemon(877,"Morpeko Full Belly Mode","Electric","Dark",436,58,95,58,70,58,97);
        // createBaseStatPokemon(877,"Morpeko Hangry Mode","Electric","Dark",436,58,95,58,70,58,97);
        // createBaseStatPokemon(878,"Cufant","Steel","None",330,72,80,49,40,49,40);
        // createBaseStatPokemon(879,"Copperajah","Steel","None",500,122,130,69,80,69,30);
        // createBaseStatPokemon(879,"Gigantamax Copperajah","Steel","None",500,122,130,69,80,69,30);
        // createBaseStatPokemon(880,"Dracozolt","Electric","Dragon",505,90,100,90,80,70,75);
        // createBaseStatPokemon(881,"Arctozolt","Electric","Ice",505,90,100,90,90,80,55);
        // createBaseStatPokemon(882,"Dracovish","Water","Dragon",505,90,90,100,70,80,75);
        // createBaseStatPokemon(883,"Arctovish","Water","Ice",505,90,90,100,80,90,55);
        // createBaseStatPokemon(884,"Duraludon","Steel","Dragon",535,70,95,115,120,50,85);
        // createBaseStatPokemon(884,"Gigantamax Duraludon","Steel","Dragon",535,70,95,115,120,50,85);
        // createBaseStatPokemon(885,"Dreepy","Dragon","Ghost",270,28,60,30,40,30,82);
        // createBaseStatPokemon(886,"Drakloak","Dragon","Ghost",410,68,80,50,60,50,102);
        // createBaseStatPokemon(887,"Dragapult","Dragon","Ghost",600,88,120,75,100,75,142);
        // createBaseStatPokemon(888,"Zacian Hero of Many Battles","Fairy","None",670,92,130,115,80,115,138);
        // createBaseStatPokemon(888,"Zacian Crowned Sword Forme","Fairy","Steel",720,92,170,115,80,115,148);
        // createBaseStatPokemon(889,"Zamazenta Hero of Many Battles","Fighting","None",670,92,130,115,80,115,138);
        // createBaseStatPokemon(889,"Zamazenta Crowned Sheild Forme","Fighting","Steel",720,92,130,145,80,145,128);
        // createBaseStatPokemon(890,"Eternatus","Poison","Dragon",690,140,85,95,145,95,130);
        // createBaseStatPokemon(890,"Eternamax Eternatus","Poison","Dragon",1125,255,115,250,125,250,130);
        // createBaseStatPokemon(891,"Kubfu","Fighting","None",385,60,90,60,53,50,72);
        // createBaseStatPokemon(892,"Urshifu Single Strike Style","Fighting","Dark",550,100,130,100,63,60,97);
        // createBaseStatPokemon(892,"Gigantamax Urshifu Single Strike Style","Fighting","Dark",550,100,130,100,63,60,97);
        // createBaseStatPokemon(892,"Urshifu Rapid Strike Style","Fighting","Water",550,100,130,100,63,60,97);
        // createBaseStatPokemon(892,"Gigantamax Urshifu Rapid Strike Style","Fighting","Water",550,100,130,100,63,60,97);
        // createBaseStatPokemon(893,"Zarude","Dark","Grass",600,105,120,105,70,95,105);
        // createBaseStatPokemon(893,"Dada Zarude","Dark","Grass",600,105,120,105,70,95,105);
        // createBaseStatPokemon(894,"Regieleki","Electric","None",580,80,100,50,100,50,200);
        // createBaseStatPokemon(895,"Regidrago","Dragon","None",580,200,100,50,100,50,80);
        // createBaseStatPokemon(896,"Glastrier","Ice","None",580,100,145,130,65,110,30);
        // createBaseStatPokemon(897,"Spectrier","Ghost","None",580,100,65,60,145,80,130);
        // createBaseStatPokemon(898,"Calyrex","Psychic","Grass",500,100,80,80,80,80,80);
        // createBaseStatPokemon(898,"Ice Rider Calyrex","Psychic","Ice",680,100,165,150,85,130,50);
        // createBaseStatPokemon(898,"Shadow Rider Calyrex","Psychic","Ghost",680,100,85,80,165,100,150);
    }

    function createBaseStatPokemon(uint256 number, string memory pokemonName, string memory type1, string memory type2, uint256 _, uint256 hp, uint256 atk, uint256 def, uint256 spa, uint256 spd, uint256 spe) public onlyOwner {
        // require(notAdded(pokemonName), "Pokemon has already been added))
        PokemonBaseStats storage baseStats = pokemonNameToPokemonBaseStats[pokemonName];
        baseStats.pokemonName = pokemonName;
        baseStats.type1 = type1;
        baseStats.type2 = type2;
        baseStats.number = number;
        baseStats.hp = hp; 
        baseStats.def = def;
        baseStats.atk = atk;
        baseStats.spa = spa;
        baseStats.spd = spd;
        baseStats.spe = spe;
        listOfPokemonNames.push(pokemonName);
    }
}

// Part: OpenZeppelin/[email protected]/ERC721

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: Pokemon.sol

contract Pokemon is ERC721, VRFConsumerBase, Ownable, PokemonBaseStatData {
    using SafeMathChainlink for uint256;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    event requestedPokemon(bytes32 indexed requestId); 
    event PokemonCreated(uint256 indexed tokenId); 
    bytes32 internal keyHash;
    uint256 internal link_fee;
    uint256 public tokenCounter;

    mapping(uint256 => PokemonBaseStats) public tokenIdToBattleStats;
    mapping(uint256 => PokemonBaseStats) public tokenIdToEvs;
    mapping(uint256 => PokemonBaseStats) public tokenIdToIvs;
    UniquePokemon[] public uniquePokemon;
    string[] public natures;
    mapping(string => string) public pokemonNameToImageURI;
    mapping(uint256 => moves) public tokenIdToMoves;
    mapping(uint256 => uint256[]) public tokenIdToRNGNumbers;

    struct moves {
        string move1;
        string move2;
        string move3;
        string move4;
    }

    struct UniquePokemon {
        string nickname;
        // eh, solidity gonna get better at this
        string item;
        bool shiny;
        string ability;
        string nature;
        uint256 level; 
    }
    
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash, uint256 _link_fee)
    public 
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("Pokémon", "PKMON")
    {
        tokenCounter = 0;
        keyHash = _keyhash;
        link_fee = _link_fee;
        natures = ["Hardy", "Lonely", "Brave", "Adamant", "Naughty", "Bold", "Docile", "Relaxed", "Impish", "Lax", "Timid", "Hasty", "Serious", "Jolly", "Naive", "Modest", "Mild", "Quiet", "Bashful", "Rash", "Calm", "Gentle", "Sassy", "Careful", "Quirky"];
    }

    function createRandomPokemon(uint256 userProvidedSeed) 
        public returns (bytes32){
            bytes32 requestId = requestRandomness(keyHash, link_fee, userProvidedSeed);
            requestIdToSender[requestId] = msg.sender;
            emit requestedPokemon(requestId);
    }

    function setIvs(uint256[] memory RNGNumbers, string memory pokemonName, uint256 tokenId) internal {
        (string memory type1, string memory type2) = getTypeFromName(pokemonName);
        PokemonBaseStats memory baseStats = pokemonNameToPokemonBaseStats[pokemonName];
        uint256 hpIv = (RNGNumbers[1] % 31) + 1;
        uint256 atkIv = (RNGNumbers[2] % 31) + 1;
        uint256 defIv = (RNGNumbers[3] % 31) + 1;
        uint256 spaIv = (RNGNumbers[4] % 31) + 1;
        uint256 spdIv = (RNGNumbers[5] % 31) + 1;
        uint256 speIv = (RNGNumbers[6] % 31) + 1;
        PokemonBaseStats memory ivs = PokemonBaseStats({hp: hpIv, def: defIv, atk: atkIv, spa: spaIv, spd: spdIv, spe: speIv, type1: type1, type2: type2, number: baseStats.number, pokemonName: pokemonName});
        PokemonBaseStats memory evs = PokemonBaseStats({hp: 0, def: 0, atk: 0, spa: 0, spd: 0, spe: 0, type1: type1, type2: type2, number: baseStats.number, pokemonName: pokemonName});

        tokenIdToIvs[tokenId] = ivs;
        tokenIdToEvs[tokenId] = evs;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address owner = requestIdToSender[requestId];
        // string memory tokenURI = pokemonToTokenURI[requestId];
        uint256 newUniquePokemonID = tokenCounter;
        requestIdToTokenId[requestId] = newUniquePokemonID;
        _safeMint(owner, newUniquePokemonID);
        uint256[] memory RNGNumbers = getManyRandomNumbers(randomNumber, 11);
        tokenIdToRNGNumbers[newUniquePokemonID] =  RNGNumbers;
        tokenCounter = tokenCounter + 1;
    }

    function updateCreatedPokemon(uint256 tokenId) public {
        uint256[] memory RNGNumbers = tokenIdToRNGNumbers[tokenId];
        uint256 pokemonNameIndex = (RNGNumbers[7] % listOfPokemonNames.length);
        string memory pokemonName = listOfPokemonNames[pokemonNameIndex];
        (string memory type1, string memory type2) = getTypeFromName(pokemonName);
        string memory nature = natures[(RNGNumbers[8] % natures.length)];
        bool shiny = false;
        uint256 shinyRNG = (RNGNumbers[9] % 4096);
        if (shinyRNG == 0){
            shiny = true;
        } else {
            shiny = false;
        }
        uint256 level = (RNGNumbers[10] % 100) + 1;
        uniquePokemon.push(
            UniquePokemon(
                {
                    nickname: pokemonName,
                    item: "None",
                    shiny: shiny,
                    ability: "None",
                    nature: nature,
                    level: level
                }
            )
        );
        setIvs(RNGNumbers, pokemonName, tokenId);
        setBattleStats(pokemonName, tokenId);
        emit PokemonCreated(tokenCounter);
    }

    function getTypeFromName(string memory pokemonName) public view returns (string memory, string memory ){
        PokemonBaseStats memory baseStats = pokemonNameToPokemonBaseStats[pokemonName];
        return (baseStats.type1, baseStats.type2);
    }

    function setBattleStats(string memory pokemonName, uint256 tokenId) public {
        // HP = floor(0.01 x (2 x Base + IV + floor(0.25 x EV)) x Level) + Level + 10
        // we bump everything up by 100, then divide by 100 at the end
        // Other Stats = floor(0.01 x (2 x Base + IV + floor(0.25 x EV)) x Level) + 5) x Nature
        PokemonBaseStats storage battleStats = tokenIdToBattleStats[tokenId];
        PokemonBaseStats storage baseStats = pokemonNameToPokemonBaseStats[pokemonName];
        PokemonBaseStats storage ivs = tokenIdToIvs[tokenId];
        PokemonBaseStats storage evs = tokenIdToEvs[tokenId];
        UniquePokemon storage pokemon = uniquePokemon[tokenId];

        battleStats.hp = ((2 * baseStats.hp + ivs.hp + (evs.hp  / 4) * pokemon.level) / 100) + pokemon.level + 10;
        battleStats.atk = ((2 * baseStats.atk + ivs.atk + (evs.atk  / 4)/ 100) * pokemon.level) + 5; // We don't add the nature modifier!!!
        battleStats.def = ( (2 * baseStats.def + ivs.def + (evs.def  / 4)/ 100) * pokemon.level) + 5; // We don't add the nature modifier!!!
        battleStats.spa = ((2 * baseStats.spa + ivs.spa + (evs.spa / 4)/ 100) * pokemon.level) + 5; // We don't add the nature modifier!!!
        battleStats.spd = ((2 * baseStats.spd + ivs.spd + (evs.spd  / 4)/ 100) * pokemon.level) + 5; // We don't add the nature modifier!!!
        battleStats.spe = ((2 * baseStats.spe + ivs.spe + (evs.spe  / 4)/ 100) * pokemon.level) + 5; // We don't add the nature modifier!!!
    }

    // Could turn this into a chainlink API Call if we wanted 
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }


    function getManyRandomNumbers(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }   

    

    // function setMoves(string memory move1, string memory move2,string memory move3,string memory move4, uint256 tokenId) public onlyOwner {
    //     uniquePokemon[tokenId].move1 = move1;
    //     uniquePokemon[tokenId].move2 = move1;
    //     uniquePokemon[tokenId].move3 = move1;
    //     uniquePokemon[tokenId].move4 = move1;
    // }
}