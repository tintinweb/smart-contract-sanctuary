/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/utils/structs/[email protected]



pragma solidity 0.8.0;

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


// File contracts/interface/IRegistry.sol


pragma solidity 0.8.0;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts in the Solaverse.
 */
interface IRegistry {

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    /// Protocol contract address getters
    function master() external returns (address);
    function vault() external returns (address);
    function treasury() external returns (address);
    function solace() external returns (address);
    function locker() external returns (address);
    function claimsAdjustor() external returns (address);
    function claimsEscrow() external returns (address);

    // events
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);
    // Emitted when Solace Token is set
    event SolaceSet(address _solace);
    // Emitted when Master is set
    event MasterSet(address _master);
    // Emitted when Vault is set
    event VaultSet(address _vault);
    // Emitted when Treasury is set
    event TreasurySet(address _treasury);
    // Emitted when Locker is set
    event LockerSet(address _locker);
    // Emitted when ClaimsAdjustor is set
    event ClaimsAdjustorSet(address _claimsAdjustor);
    // Emitted when ClaimsEscrow is set
    event ClaimsEscrowSet(address _claimsEscrow);
    // Emitted when a Product is added
    event ProductAdded(address _product);
    // Emitted when a Product is removed
    event ProductRemoved(address _product);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Sets the solace token contract.
     * Can only be called by the current governor.
     * @param _solace The solace token address.
     */
    function setSolace(address _solace) external;

    /**
     * @notice Sets the master contract.
     * Can only be called by the current governor.
     * @param _master The master contract address.
     */
    function setMaster(address _master) external;

    /**
     * @notice Sets the vault contract.
     * Can only be called by the current governor.
     * @param _vault The vault contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets the treasury contract.
     * Can only be called by the current governor.
     * @param _treasury The treasury contract address.
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Sets the locker contract.
     * Can only be called by the current governor.
     * @param _locker The locker address.
     */
    function setLocker(address _locker) external;

        /**
     * @notice Sets the Claims Adjustor contract.
     * Can only be called by the current governor.
     * @param _claimsAdjustor The Claims Adjustor address.
     */
    function setClaimsAdjustor(address _claimsAdjustor) external;

    /**
     * @notice Sets the Claims Escrow contract.
     * Can only be called by the current governor.
     * @param _claimsEscrow The sClaims Escrow address.
     */
    function setClaimsEscrow(address _claimsEscrow) external;

    /**
     * @notice Adds a new product.
     * Can only be called by the current governor.
     * @param _product The product to add.
     */
    function addProduct(address _product) external;

    /**
     * @notice Removes a product.
     * Can only be called by the current governor.
     * @param _product The product to remove.
     */
    function removeProduct(address _product) external;

    /**
     * @notice Returns the number of products.
     * @return The number of products.
     */
    function numProducts() external view returns (uint256);

    /**
     * @notice Returns the product at the given index.
     * @param _productNum The index to query.
     * @return The address of the product.
     */
    function getProduct(uint256 _productNum) external view returns (address);

    /**
     * @notice Returns true if the given address is a product.
     * @param _product The address to query.
     * @return True if the address is a product.
     */
    function isProduct(address _product) external view returns (bool);
}


// File contracts/RegistryProxy.sol


pragma solidity 0.8.0;


/**
 * @title Registry
 * @author solace.fi
 * @notice Tracks the contracts in the Solaverse.
 */
contract RegistryProxy {

    /// @notice Governor.
    address public governance;
    /// @notice Governance to take over.
    address public newGovernance;
    /// @notice The Registry implementation.
    address public implementation;

    // events
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);
    // Emitted when implementation is set
    event RegistrySet(address _implementation);

    /**
     * @notice Constructs the registry contract.
     * @param _governance Address of the governor.
     */
    constructor(address _governance, address _implementation) {
        governance = _governance;
        implementation = _implementation;
    }

    /**
     * @notice Allows governance to be transferred to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        newGovernance = _governance;
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external {
        // can only be called by new governor
        require(msg.sender == newGovernance, "!governance");
        governance = newGovernance;
        newGovernance = address(0x0);
        emit GovernanceTransferred(msg.sender);
    }

    /**
     * @notice Sets the Registry implementation contract.
     * Can only be called by the current governor.
     * @param _implementation The new Registry implementation address.
     */
    function setImplementation(address _implementation) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        implementation = _implementation;
        emit RegistrySet(_implementation);
    }

    fallback () external payable {
        /*
        address _implementation = implementation;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            //let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            let result := staticcall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
        */
        // delegate all other functions to current implementation
        (bool success, ) = implementation.staticcall(msg.data);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}