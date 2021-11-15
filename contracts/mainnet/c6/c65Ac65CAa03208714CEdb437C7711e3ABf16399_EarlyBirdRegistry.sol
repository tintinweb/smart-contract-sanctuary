// SPDX-License-Identifier: MIT

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './IEarlyBirdRegistry.sol';

/// @title EarlyBirdRegistry
/// @author Simon Fremaux (@dievardump)
contract EarlyBirdRegistry is IEarlyBirdRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    event ProjectCreated(
        address indexed creator,
        uint256 indexed projectId,
        uint256 endRegistration, // when the registration ends
        uint256 maxRegistration, // how many people can register
        bool open // if the project accepts Open Registration
    );

    event Registration(uint256 indexed projectId, address[] list);

    struct Project {
        bool open;
        address creator;
        uint256 endRegistration;
        uint256 maxRegistration;
    }

    // this is a counter that increments automatically when registering an Early Bird Project
    uint256 lastProjectId;

    // list of all projects
    mapping(uint256 => Project) public projects;

    // list of registered address for a project
    mapping(uint256 => EnumerableSet.AddressSet) internal _registered;

    modifier onlyProject(uint256 projectId) {
        require(exists(projectId), 'Unknown project id.');
        _;
    }

    constructor() {}

    /// @notice allows anyone to register a new project that accepts Early Birds registrations
    /// @param open if the early bird registration is open or only creator can register addresses
    /// @param endRegistration unix epoch timestamp of registration closing
    /// @param maxRegistration the max registration count
    /// @return projectId the project Id (useful if called by a contract)
    function registerProject(
        bool open,
        uint256 endRegistration,
        uint256 maxRegistration
    ) external override returns (uint256 projectId) {
        projectId = lastProjectId + 1;
        lastProjectId = projectId;

        projects[projectId] = Project({
            open: open,
            creator: msg.sender,
            endRegistration: endRegistration,
            maxRegistration: maxRegistration
        });

        emit ProjectCreated(
            msg.sender,
            projectId,
            endRegistration,
            maxRegistration,
            open
        );
    }

    /// @notice tells if a project exists
    /// @param projectId project id to check
    /// @return true if the project exists
    function exists(uint256 projectId) public view override returns (bool) {
        return projectId > 0 && projectId <= lastProjectId;
    }

    /// @notice Helper to paginate all address registered for a project
    ///         Using pagination just in case it ever happens that there are much EarlyBirds
    /// @param projectId the project id
    /// @param offset index where to start
    /// @param limit how many to grab
    /// @return list of registered addresses
    function listRegistrations(
        uint256 projectId,
        uint256 offset,
        uint256 limit
    )
        external
        view
        override
        onlyProject(projectId)
        returns (address[] memory list)
    {
        EnumerableSet.AddressSet storage registered = _registered[projectId];

        uint256 count = registered.length();

        require(offset < count, 'Offset too high');

        if (count < offset + limit) {
            limit = count - offset;
        }

        list = new address[](limit);
        for (uint256 i; i < limit; i++) {
            list[i] = registered.at(offset + i);
        }
    }

    /// @notice Helper to know how many address registered to a project
    /// @param projectId the project id
    /// @return how many people registered
    function registeredCount(uint256 projectId)
        external
        view
        override
        onlyProject(projectId)
        returns (uint256)
    {
        return _registered[projectId].length();
    }

    /// @notice Small helpers that returns in how many seconds a project registration ends
    /// @param projectId to check
    /// @return the time in second before end; 0 if ended
    function registrationEndsIn(uint256 projectId)
        public
        view
        returns (uint256)
    {
        if (projects[projectId].endRegistration <= block.timestamp) {
            return 0;
        }

        return projects[projectId].endRegistration - block.timestamp;
    }

    /// @notice Helper to check if an address is registered for a project id
    /// @param check the address to check
    /// @param projectId the project id
    /// @return if the address was registered as an early bird
    function isRegistered(address check, uint256 projectId)
        external
        view
        override
        onlyProject(projectId)
        returns (bool)
    {
        return _registered[projectId].contains(check);
    }

    /// @notice Allows the creator of a project to change registration open state
    ///         this can be usefull to first register a specific list of addresses
    ///         before making the registration public
    /// @param projectId to modify
    /// @param open if the project is open to anyone or only creator can change
    function setRegistrationOpen(uint256 projectId, bool open) external {
        require(
            msg.sender == projects[projectId].creator,
            'Not project creator.'
        );
        projects[projectId].open = open;
    }

    /// @notice Allows a user to register for an EarlyBird spot on a project
    /// @dev the project needs to be "open" for people to register directly to it
    /// @param projectId the project id to register to
    function registerTo(uint256 projectId) external onlyProject(projectId) {
        Project memory project = projects[projectId];
        require(project.open == true, 'Project not open.');

        EnumerableSet.AddressSet storage registered = _registered[projectId];
        require(
            // before end registration time
            block.timestamp <= project.endRegistration &&
                // and there is still available spots
                registered.length() + 1 <= project.maxRegistration,
            'Registration closed.'
        );

        require(!registered.contains(msg.sender), 'Already registered');

        // add user to list
        registered.add(msg.sender);

        address[] memory list = new address[](1);
        list[0] = msg.sender;

        emit Registration(projectId, list);
    }

    /// @notice Allows a project creator to add early birds in Batch
    /// @dev msg.sender must be the projectId creator
    /// @param projectId to add to
    /// @param birds all addresses to add
    function registerBatchTo(uint256 projectId, address[] memory birds)
        external
        override
    {
        Project memory project = projects[projectId];

        require(msg.sender == project.creator, 'Not project creator.');

        uint256 count = birds.length;
        EnumerableSet.AddressSet storage registered = _registered[projectId];
        // before end registration time
        require(
            block.timestamp <= project.endRegistration,
            'Registration closed.'
        );

        // and there is still enough available spots
        require(
            registered.length() + count <= project.maxRegistration,
            'Not enough spots.'
        );

        for (uint256 i; i < count; i++) {
            registered.add(birds[i]);
        }

        emit Registration(projectId, birds);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEarlyBirdRegistry
/// @author Simon Fremaux (@dievardump)
interface IEarlyBirdRegistry {
    /// @notice allows anyone to register a new project that accepts Early Birds registrations
    /// @param open if the early bird registration is open or only creator can register addresses
    /// @param endRegistration unix epoch timestamp of registration closing
    /// @param maxRegistration the max registration count
    /// @return projectId the project Id (useful if called by a contract)
    function registerProject(
        bool open,
        uint256 endRegistration,
        uint256 maxRegistration
    ) external returns (uint256 projectId);

    /// @notice tells if a project exists
    /// @param projectId project id to check
    /// @return if the project exists
    function exists(uint256 projectId) external view returns (bool);

    /// @notice Helper to paginate all address registered for a project
    /// @param projectId the project id
    /// @param offset index where to start
    /// @param limit how many to grab
    /// @return list of registered addresses
    function listRegistrations(
        uint256 projectId,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory list);

    /// @notice Helper to know how many address registered to a project
    /// @param projectId the project id
    /// @return how many people registered
    function registeredCount(uint256 projectId) external view returns (uint256);

    /// @notice Helper to check if an address is registered for a project id
    /// @param check the address to check
    /// @param projectId the project id
    /// @return if the address was registered as an early bird
    function isRegistered(address check, uint256 projectId)
        external
        view
        returns (bool);

    /// @notice Allows a project creator to add early birds in Batch
    /// @dev msg.sender must be the projectId creator
    /// @param projectId to add to
    /// @param birds all addresses to add
    function registerBatchTo(uint256 projectId, address[] memory birds)
        external;
}

