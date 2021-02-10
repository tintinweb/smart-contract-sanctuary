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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {IExecutorRegistry} from "../../interfaces/gelato/IExecutorRegistry.sol";
import {IBouncer} from "../../interfaces/gelato/IBouncer.sol";

/// @title ServiceRegistry
/// @notice Global Registry for all use cases that customers want to get executed
/// @notice Each Service must be accepted by at least one executor
/// @notice Executors will guarantee to execute a service
/// @notice Gov can incentivize certain Services with tokens and blacklist them
/// @notice This contract acts as the defacto subjective binding agreement between executors
/// and Service Sumbmittors, enforced by governance
/// @notice We can later add e.g. merkle proofs to facilated slashing if agreement was not upheld
/// @dev ToDo: Implement credit system
contract ServiceRegistry is IBouncer {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;
    IExecutorRegistry public executorRegistry;

    // Called by Customer
    mapping(address => bool) public useCaseRequested;

    // Called by Executors
    mapping(address => bool) public useCaseAccepted;
    mapping(address => EnumerableSet.AddressSet) internal executorsPerUseCase;

    // Called by gov
    mapping(address => bool) public useCaseIncentivized;
    mapping(address => bool) public useCaseBlacklisted;

    address[] public useCaseList;

    constructor(IExecutorRegistry _execModule) public {
        governance = msg.sender;
        executorRegistry = _execModule;
    }

    // ################ Callable by Users ################
    /// @dev Everyone can call this method and request a service to be executed
    function request(address _newService) external {
        require(
            !useCaseAccepted[_newService],
            "ServiceRegistry: Service already accepted"
        );
        require(
            !useCaseRequested[_newService],
            "ServiceRegistry: Service already requested"
        );
        useCaseRequested[_newService] = true;
    }

    // ################ Callable by Executors ################
    function accept(address _service) external {
        require(
            executorRegistry.isExecutor(msg.sender),
            "ServiceRegistry: acccept: !whitelisted executor"
        );
        require(
            useCaseRequested[_service],
            "ServiceRegistry: accept: service requested"
        );
        require(
            !useCaseBlacklisted[_service],
            "ServiceRegistry: accept: service blacklisted"
        );
        require(
            !useCaseAccepted[_service],
            "ServiceRegistry: accept: service already accepted"
        );

        if (executorsPerUseCase[_service].length() == 0) {
            useCaseAccepted[_service] = true;
        }
        executorsPerUseCase[_service].add(msg.sender);
    }

    // Individual Executor stops to serve a requested Service
    function stop(address _service) external {
        require(
            executorRegistry.isExecutor(msg.sender),
            "ServiceRegistry:stop: !whitelisted executor"
        );
        require(
            useCaseAccepted[_service],
            "ServiceRegistry:stop: service not accepted"
        );
        executorsPerUseCase[_service].remove(msg.sender);
        if (executorsPerUseCase[_service].length() == 0) {
            useCaseAccepted[_service] = false;
        }
    }

    // ################ Callable by Gov ################
    function startIncentives(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            !useCaseIncentivized[_service],
            "ServiceRegistry: Use Case already incentivized"
        );
        useCaseIncentivized[_service] = true;
    }

    function stopIncentives(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            useCaseIncentivized[_service],
            "ServiceRegistry: Use Case not incentivized"
        );
        useCaseIncentivized[_service] = false;
    }

    function blacklist(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            !useCaseBlacklisted[_service],
            "ServiceRegistry: Use Case already blacklisted"
        );
        useCaseBlacklisted[_service] = true;
    }

    function deblacklist(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            useCaseBlacklisted[_service],
            "ServiceRegistry: Use Case not blacklisted"
        );
        useCaseBlacklisted[_service] = false;
    }

    /**
     * @notice Allows governance to change executor module (for future upgradability)
     * @param _execModule new governance address to set
     */
    function setExexModule(IExecutorRegistry _execModule) external {
        require(msg.sender == governance, "setGovernance: Only gov");
        executorRegistry = _execModule;
    }

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: Only gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(
            msg.sender == pendingGovernance,
            "acceptGovernance: Only pendingGov"
        );
        governance = pendingGovernance;
    }

    // ### VIEW FUNCTIONS ###
    function useCases() external view returns (address[] memory) {
        return useCaseList;
    }

    /// @notice returns true of executor accepted to serve a certain service
    /// @dev Overrides IBouncer Contract
    function preExec(
        address _service,
        bytes calldata,
        address _executor
    ) external override {
        require(
            canExecutorExec(_service, _executor),
            "Service Registry: preExec: Failure"
        );
    }

    /// @notice returns true of executor accepted to serve a certain service
    /// @dev Overrides IBouncer Contract
    function postExec(
        address _service,
        bytes calldata,
        address _executor
    ) external override {}

    function canExecutorExec(address _service, address _executor)
        public
        view
        returns (bool)
    {
        return
            executorsPerUseCase[_service].contains(_executor) &&
            !useCaseBlacklisted[_service] &&
            executorRegistry.isExecutor(_executor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IBouncer {
    function preExec(
        address _to,
        bytes calldata _data,
        address _executor
    ) external;

    function postExec(
        address _to,
        bytes calldata _data,
        address _executor
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IExecutorRegistry {
    function isExecutor(address _executor) external view returns (bool);
}