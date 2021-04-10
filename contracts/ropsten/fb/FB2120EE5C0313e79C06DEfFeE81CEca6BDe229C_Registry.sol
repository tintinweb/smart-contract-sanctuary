//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./IRegistry.sol";

/**
 *  @title Registry contract storing information about all refunders deployed
 *  Used for querying and reverse querying available refunders for a given target+identifier transaction
 */
contract Registry is IRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice mapping of refunders and their version. Version starts from 1
    mapping(address => uint8) public refunderVersion;

    // Tuple of target address + identifier corresponding to set of refunders
    mapping(address => mapping(bytes4 => EnumerableSet.AddressSet)) aggregatedRefundables;

    EnumerableSet.AddressSet private refunders;

    /// @notice Register event emitted once new refunder is added to the registry
    event Register(address indexed refunder, uint8 version);

    /// @notice UpdateRefundable event emitted once a given refunder updates his supported refundable transactions
    event UpdateRefundable(
        address indexed refunder,
        address indexed targetAddress,
        bytes4 indexed identifier,
        bool supported
    );

    /// @notice Modifier checking that the msg sender is a registered refunder
    modifier onlyRefunder() {
        require(
            refunders.contains(msg.sender) && refunderVersion[msg.sender] > 0,
            "Registry: Not refunder"
        );
        _;
    }

    /// @notice Register function for adding new refunder in the registry
    /// @param refunder the address of the new refunder
    /// @param version the version of the refunder
    function register(address refunder, uint8 version) external override {
        require(version != 0, "Registry: Invalid version");
        require(
            !refunders.contains(refunder),
            "Registry: Refunder already registered"
        );

        refunders.add(refunder);
        refunderVersion[refunder] = version;

        emit Register(refunder, version);
    }

    /**
     * @notice Updates the tuple with the supported target + identifier transactions. Can be called only by refunder contract
     * @param target the target contract of the refundable transaction
     * @param identifier the function identifier of the refundable transaction
     * @param supported boolean property indicating whether the specified transaction is refundable or not
     */
    function updateRefundable(
        address target,
        bytes4 identifier,
        bool supported
    ) external override onlyRefunder {
        if (supported) {
            aggregatedRefundables[target][identifier].add(msg.sender);
        } else {
            aggregatedRefundables[target][identifier].remove(msg.sender);
        }

        emit UpdateRefundable(msg.sender, target, identifier, supported);
    }

    /**
     * @notice Get function returning the number of refunders for the specified target + identifier transaction
     * @param target the target contract of the refundable transaction
     * @param identifier the function identifier of the refundable transaction
     */
    function getRefunderCountFor(address target, bytes4 identifier)
        external
        view
        override
        returns (uint256)
    {
        return aggregatedRefundables[target][identifier].length();
    }

    /**
     * @notice Returns the refunder address for a given combination of target + identifier transaction at the specified index
     * @param target the target contract of the refundable transaction
     * @param identifier the function identifier of the refundable transaction
     * @param index the index of the refunder in the set of refunders
     */
    function getRefunderForAtIndex(
        address target,
        bytes4 identifier,
        uint256 index
    ) external view override returns (address) {
        require(
            index < aggregatedRefundables[target][identifier].length(),
            "Registry: Invalid index"
        );

        return aggregatedRefundables[target][identifier].at(index);
    }

    /**
     * @notice Returns the refunder address by index
     * @param index the index of the refunder in the set of refunders
     */
    function getRefunder(uint256 index)
        external
        view
        override
        returns (address)
    {
        require(index < refunders.length(), "Registry: Invalid index");

        return refunders.at(index);
    }

    /// @notice Returns the count of all unique refunders
    function getRefundersCount() external view override returns (uint256) {
        return refunders.length();
    }

    /**
     * @notice Returns all refunders that support refunding of target+identifier transactions
     * @param target the target contract of the refundable transaction
     * @param identifier the function identifier of the refundable transaction
     */
    function refundersFor(address target, bytes4 identifier)
        external
        view
        returns (address[] memory)
    {
        uint256 n = aggregatedRefundables[target][identifier].length();
        address[] memory result = new address[](n);

        for (uint256 i = 0; i < n; i++) {
            result[i] = aggregatedRefundables[target][identifier].at(i);
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IRegistry {
    function register(address refunder, uint8 version) external;

    function updateRefundable(
        address targetAddress,
        bytes4 identifier,
        bool supported
    ) external;

    function getRefundersCount() external view returns (uint256);

    function getRefunder(uint256 index) external returns (address);

    function getRefunderCountFor(address targetAddress, bytes4 identifier)
        external
        view
        returns (uint256);

    function getRefunderForAtIndex(
        address targetAddress,
        bytes4 identifier,
        uint256 index
    ) external view returns (address);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}