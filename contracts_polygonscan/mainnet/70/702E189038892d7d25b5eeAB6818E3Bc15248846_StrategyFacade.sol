// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.6.0;

import "EnumerableSet.sol";

import "IStrategyFacade.sol";

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;
}

/// @title Facade contract for Gelato Resolver contract
/// @author Tesseract Finance, Chimera
contract StrategyFacade is IStrategyFacade {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal availableStrategies;
    uint256 public totalStrats;
    address public resolver;
    address public owner;
    uint256 public interval;
    uint256 public lastBlock;

    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);
    event ResolverContractUpdated(address resolver);
    event ErrorHandled(bytes indexed reason, address indexed strategy);

    modifier onlyResolver() {
        require(
            msg.sender == resolver,
            "StrategyFacade: Only Gelato Resolver can call"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "StrategyFacade: Only owner can call");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setResolver(address _resolver) public onlyOwner {
        resolver = _resolver;

        emit ResolverContractUpdated(_resolver);
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setInterval(uint256 _interval) public onlyOwner {
        interval = _interval;
    }

    function addStrategy(address _strategy) public onlyOwner {
        require(
            !availableStrategies.contains(_strategy),
            "StrategyFacade::addStrategy: Strategy already added"
        );

        availableStrategies.add(_strategy);
        lastBlock = block.timestamp;
        totalStrats++;

        emit StrategyAdded(_strategy);
    }

    function getStrategy(uint256 i) public view returns (address strat) {
        strat = availableStrategies.at(i);
    }

    function removeStrategy(address _strategy) public onlyOwner {
        require(
            availableStrategies.contains(_strategy),
            "StrategyFacade::removeStrategy: Strategy already removed"
        );

        availableStrategies.remove(_strategy);

        emit StrategyRemoved(_strategy);
    }

    function gelatoCanHarvestAny(uint256 _callCost)
        public
        view
        returns (bool canExec)
    {
        if (lastBlock + interval > block.timestamp) {
            canExec = false;
            return canExec; // enforce minimal interval
        }

        uint256 callable = 0;
        for (uint256 i; i < availableStrategies.length(); i++) {
            address currentStrategy = availableStrategies.at(i);
            if (StrategyAPI(currentStrategy).harvestTrigger(_callCost)) {
                callable++;
            }
        }

        if (callable > 0) {
            canExec = true;
        } else {
            canExec = false;
        }
        return canExec;
    }

    function checkHarvest(uint256 _callCost)
        public
        view
        override
        returns (bool canExec, address strategy)
    {
        for (uint256 i; i < availableStrategies.length(); i++) {
            address currentStrategy = availableStrategies.at(i);
            if (StrategyAPI(currentStrategy).harvestTrigger(_callCost)) {
                return (canExec = true, strategy = currentStrategy);
            }
        }

        return (canExec = false, strategy = address(0));
    }

    function harvest(address _strategy) public override onlyResolver {
        try StrategyAPI(_strategy).harvest() {} catch (bytes memory reason) {
            emit ErrorHandled(reason, _strategy);
        }
    }

    function harvestAll(uint256 _callCost) public override onlyResolver {
        for (uint256 i; i < availableStrategies.length(); i++) {
            address currentStrategy = availableStrategies.at(i);
            if (StrategyAPI(currentStrategy).harvestTrigger(_callCost)) {
                harvest(currentStrategy);
            }
        }
        lastBlock = block.timestamp;
    }

    function checkAll(uint256 _callCost)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = gelatoCanHarvestAny(_callCost);
        execPayload = abi.encodeWithSelector(
            IStrategyFacade.harvestAll.selector,
            _callCost
        );
    }

    function check(uint256 _callCost)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        (bool _canExec, address _strategy) = checkHarvest(_callCost);

        canExec = _canExec;

        execPayload = abi.encodeWithSelector(
            IStrategyFacade.harvest.selector,
            address(_strategy)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.6.0;

/// @title StrategyFacade Interface
/// @author Tesseract Finance
interface IStrategyFacade {
    /**
     * Checks if any of the strategies should be harvested
     * @dev :_callCost: must be priced in terms of wei (1e-18 ETH)
     *
     * @param _callCost - The Gelato bot's estimated gas cost to call harvest function (in wei)
     *
     * @return canExec - True if Gelato bot should harvest, false if it shouldn't
     * @return strategy - Address of the strategy contract that needs to be harvested
     */
    function checkHarvest(uint256 _callCost) external view returns (bool canExec, address strategy);

    /**
     * Call harvest function on a Strategy smart contract with the given address
     *
     * @param _strategy - Address of a Strategy smart contract which needs to be harvested
     *
     * No return, reverts on error
     */
    function harvest(address _strategy) external;
    function harvestAll(uint256 _callCost) external;
}