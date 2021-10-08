// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/ITroveLinkAccessController.sol";
import "./interfaces/ITroveLinkController.sol";
import "./AddressUtils.sol";

contract TroveLinkController is ITroveLinkController {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable accessController;

    EnumerableSet.AddressSet private _services;
    mapping(address => bytes32) private _serviceToRoleLink;
    address private _voting;

    function voting() public view returns (address) {
        return _voting;
    }

    function serviceCount() external view override(ITroveLinkController) returns (uint256) {
        return _services.length();
    }

    function isService(address service_) external view override(ITroveLinkController) returns (bool) {
        return _services.contains(service_);
    }

    function service(uint256 index_) external view override(ITroveLinkController) returns (address) {
        return _services.at(index_);
    }

    function serviceLinkedRole(address service_) external view override(ITroveLinkController) returns (bytes32) {
        return _serviceToRoleLink[service_];
    }

    constructor(
        address accessController_,
        address voting_
        // Service[] memory services_
    ) public {
        require(accessController_ != address(0), "AccessController is zero address");
        accessController = accessController_;
        emit AccessControllerUpdated(accessController_);
        _updateVoting(voting_);
        // for (uint256 i = 0; i < services_.length; i++) {
        //     Service memory service_ = services_[i];
        //     _addService(service_.service, service_.role);
        // }
    }

    function addService(address service_, bytes32 role_) external override(ITroveLinkController) returns (bool) {
        require(msg.sender == address(this), "Invalid sender");
        require(!_services.contains(service_), "Service already added");
        _addService(service_, role_);
        return true;
    }

    function execute(
        address destination_,
        bytes memory data_,
        string memory description_
    ) external payable override(ITroveLinkController) returns (bytes memory result) {
        require(msg.sender == _voting, "Invalid sender");
        uint256 value = msg.value;
        result = destination_.functionCallWithValue(
            data_,
            value,
            "Execution error"
        );
        emit Executed(
            destination_,
            data_,
            description_,
            value
        );
    }

    function removeService(address service_) external override(ITroveLinkController) returns (bool) {
        require(msg.sender == address(this), "Invalid sender");
        require(_services.contains(service_), "Service is not added");
        bytes32 role_ = _serviceToRoleLink[service_];
        uint256 membersCount = ITroveLinkAccessController(accessController).roleMemberCount(role_);
        require(membersCount == 0, "Connected role has members");
        _services.remove(service_);
        _serviceToRoleLink[service_] = bytes32(0);
        emit ServiceRemoved(service_, role_);
        return true;
    }

    function updateVoting(address voting_) external override(ITroveLinkController) returns (bool) {
        require(msg.sender == address(this), "Invalid sender");
        _updateVoting(voting_);
        return true;
    }

    function _addService(address service_, bytes32 role_) private {
        require(service_ != address(0), "Service is zero address");
        if (_services.add(service_)) {
            _serviceToRoleLink[service_] = role_;
            emit ServiceAdded(service_, role_);
        }
    }

    function _updateVoting(address voting_) private {
        require(voting_ != address(0), "Voting is zero address");
        _voting = voting_;
        emit VotingUpdated(voting_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITroveLinkController {
    // Structs
    struct Service {
        address service;
        bytes32 role;
    }

    // External view functions
    function serviceCount() external view returns (uint256);
    function isService(address service_) external view returns (bool);
    function service(uint256 index_) external view returns (address);
    function serviceLinkedRole(address service_) external view returns (bytes32);

    // Events
    event AccessControllerUpdated(address accessController_);
    event Executed(address destination_, bytes data_, string description_, uint256 value_);
    event ServiceAdded(address service_, bytes32 role_);
    event ServiceRemoved(address service_, bytes32 role_);
    event VotingUpdated(address voting_);

    // External functions
    function addService(address service_, bytes32 role_) external returns (bool);
    function execute(
        address destination_,
        bytes memory data_,
        string memory description_
    ) external payable returns (bytes memory result);
    function removeService(address service_) external returns (bool);
    function updateVoting(address voting_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITroveLinkAccessController {
    // External view functions
    function roleCount() external view returns (uint256);
    function hasRole(bytes32 role_, address account_) external view returns (bool);
    function role(uint256 index_) external view returns (bytes32);
    function roleMember(bytes32 role_, uint256 index_) external view returns (address);
    function roleMemberCount(bytes32 role_) external view returns (uint256);

    // Events
    event Initialized(address controller_, bytes32[] roles_);
    event RoleAdded(bytes32 role_);
    event RoleGranted(bytes32 indexed role_, address account_);
    event RoleRemoved(bytes32 role_);
    event RoleRevoked(bytes32 indexed role_, address account_);

    // External functions
    function addRole(bytes32 role_) external returns (bool);
    function grantRole(bytes32 role_, address account_) external returns (bool);
    function removeRole(bytes32 role_) external returns (bool);
    function revokeRole(bytes32 role_, address account_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library AddressUtils {
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "AddressUtils: insufficient value");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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