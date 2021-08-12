/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File deps/@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol

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
library EnumerableSetUpgradeable {
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


// File contracts/BadgerRegistry.sol

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract BadgerRegistry {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  //@dev is the vault at the experimental, guarded or open stage? Only for Prod Vaults
  enum VaultStatus { experimental, guarded, open }

  struct VaultData {
    string version;
    VaultStatus status;
    address[] list;
  }

  //@dev Multisig. Vaults from here are considered Production ready
  address public governance;
  address public devGovernance; //@notice an address with some powers to make things easier in development

  //@dev Given an Author Address, and Token, Return the Vault
  mapping(address => mapping(string => EnumerableSetUpgradeable.AddressSet)) private vaults;
  mapping(string => address) public addresses;

  //@dev Given Version and VaultStatus, returns the list of Vaults in production
  mapping(string => mapping(VaultStatus => EnumerableSetUpgradeable.AddressSet)) private productionVaults;

  // Known constants you can use
  string[] public keys; //@notice, you don't have a guarantee of the key being there, it's just a utility
  string[] public versions; //@notice, you don't have a guarantee of the key being there, it's just a utility

  event NewVault(address author, string version, address vault);
  event RemoveVault(address author, string version, address vault);
  event PromoteVault(address author, string version, address vault, VaultStatus status);
  event DemoteVault(address author, string version, address vault, VaultStatus status);

  event Set(string key, address at);
  event AddKey(string key);
  event AddVersion(string version);

  function initialize(address newGovernance) public {
    require(governance == address(0));
    governance = newGovernance;
    devGovernance = address(0);

    versions.push("v1"); //For v1
    versions.push("v2"); //For v2
  }

  function setGovernance(address _newGov) public {
    require(msg.sender == governance, "!gov");
    governance = _newGov;
  }

  function setDev(address newDev) public {
    require(msg.sender == governance || msg.sender == devGovernance, "!gov");
    devGovernance = newDev;
  }

  //@dev Utility function to add Versions for Vaults, 
  //@notice No guarantee that it will be properly used
  function addVersions(string memory version) public {
    require(msg.sender == governance, "!gov");
    versions.push(version);

    emit AddVersion(version);
  }


  //@dev Anyone can add a vault to here, it will be indexed by their address
  function add(string memory version, address vault) public {
    bool added = vaults[msg.sender][version].add(vault);
    if (added) { 
      emit NewVault(msg.sender, version, vault);
    }
  }

  //@dev Remove the vault from your index
  function remove(string memory version, address vault) public {
    bool removed = vaults[msg.sender][version].remove(vault);
    if (removed) { 
      emit RemoveVault(msg.sender, version, vault); 
     }
  }

  //@dev Promote a vault to Production
  //@dev Promote just means indexed by the Governance Address
  function promote(string memory version, address vault, VaultStatus status) public {
    require(msg.sender == governance || msg.sender == devGovernance, "!gov");

    VaultStatus actualStatus = status;
    if(msg.sender == devGovernance) {
      actualStatus = VaultStatus.experimental;
    }

    bool added = productionVaults[version][actualStatus].add(vault);

    // If added remove from old and emit event
    if (added) { 
      // also remove from old prod
      if(uint256(actualStatus) == 2){
        // Remove from prev2
        productionVaults[version][VaultStatus(0)].remove(vault);
        productionVaults[version][VaultStatus(1)].remove(vault);
      }
      if(uint256(actualStatus) == 1){
        // Remove from prev1
        productionVaults[version][VaultStatus(0)].remove(vault);
      }

      emit PromoteVault(msg.sender, version, vault, actualStatus); 
    }
  }

  function demote(string memory version, address vault, VaultStatus status) public {
    require(msg.sender == governance || msg.sender == devGovernance, "!gov");

    VaultStatus actualStatus = status;
    if(msg.sender == devGovernance) {
      actualStatus = VaultStatus.experimental;
    }

    bool removed = productionVaults[version][actualStatus].remove(vault);

    if (removed) { 
      emit DemoteVault(msg.sender, version, vault, status);
    }
  }

  /** KEY Management */

  //@dev Set the value of a key to a specific address
  //@notice e.g. controller = 0x123123 
  function set(string memory key, address at) public {
    require(msg.sender == governance, "!gov");
    _addKey(key);
    addresses[key] = at;
    emit Set(key, at);
  }

  //@dev Retrieve the value of a key
  function get(string memory key) public view returns (address){
    return addresses[key];
  }

  //@dev Add a key to the list of keys
  //@notice This is used to make it easier to discover keys, 
  //@notice however you have no guarantee that all keys will be in the list
  function _addKey(string memory key) internal {
    //If we find the key, skip
    bool found = false;
    for(uint256 x = 0; x < keys.length; x++){
      // Compare strings via their hash because solidity
      if(keccak256(bytes(key)) == keccak256(bytes(keys[x]))) {
        found = true;
      }
    }

    if(found) {
      return;
    }

    // Else let's add it and emit the event
    keys.push(key);

    emit AddKey(key);
  }

  //@dev Retrieve a list of all Vault Addresses from the given author
  function getVaults(string memory version, address author) public view returns (address[] memory) {
    uint256 length = vaults[author][version].length();

    address[] memory list = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      list[i] = vaults[author][version].at(i);
    }
    return list;
  }

  //@dev Retrieve a list of all Vaults that are in production, based on Version and Status
  function getFilteredProductionVaults(string memory version, VaultStatus status) public view returns (address[] memory) {
    uint256 length = productionVaults[version][status].length();

    address[] memory list = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      list[i] = productionVaults[version][status].at(i);
    }
    return list;
  }

  function getProductionVaults() public view returns (VaultData[] memory) {
    uint256 versionsCount = versions.length;

    VaultData[] memory data = new VaultData[](versionsCount * 3);

    for(uint256 x = 0; x < versionsCount; x++) {
      for(uint256 y = 0; y < 3; y++) {
        uint256 length = productionVaults[versions[x]][VaultStatus(y)].length();
        address[] memory list = new address[](length);
        for(uint256 z = 0; z < length; z++){
          list[z] = productionVaults[versions[x]][VaultStatus(y)].at(z);
        }
        data[x * (versionsCount - 1) + y * 2] = VaultData({
          version: versions[x],
          status: VaultStatus(y),
          list: list
        });
      }
    }

    return data;
  }
}