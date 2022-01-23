/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.0;


// 
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol
// Subject to the MIT license.
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

// 
/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public virtual view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback () payable external {
    address _impl = implementation();
    require(_impl != address(0));
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

// 
/**
 * @title PlayerStoxTokenUpgradableProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract PlayerStoxTokenUpgradableProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner(), "Only owner is allowed to do this.");
    _;
  }

  /**
   * @dev Constructor function
   */
  constructor(address _implementation) {
    setImplementation(_implementation);
    setProxyOwner(msg.sender);
  }

  /**
   * @dev Tells the address of the owner
   * @return owner the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }
  /**
   * @dev Tells the address of the current implementation
   * @return impl address of the current implementation
   */
  function implementation() public view override returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param _implementation address representing the new implementation to be set
   */
  function setImplementation(address _implementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, _implementation)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param _proxyOwner address representing the new implementation to be set
   */
  function setProxyOwner(address _proxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, _proxyOwner)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param _implementation representing the address of the new implementation to be set
   */
  function upgradeTo(address _implementation) external onlyProxyOwner {
    require(_implementation != address(0));
    address currentImplementation = implementation();
    require(currentImplementation != _implementation, "New implementation can't be same as old implementation");
    setImplementation(_implementation);
    emit Upgraded(_implementation);
  }
}

// 
interface IPlayerStoxToken {

    function initialize(string memory name_, string memory symbol_, uint8 decimals_) external;

    function upgradeTo(address _implementation) external;
  
}

// 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

// 
contract PlayerStoxFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public playerStoxImplementation;
    address public curveWallet;
    address public adminWallet;
    address public USDT;
    EnumerableSet.AddressSet private playerStoxs;

    constructor(address playerStoxImpl_, address curveWallet_, address adminWallet_, address USDT_) {
        playerStoxImplementation = address(playerStoxImpl_);
        curveWallet = address(curveWallet_);
        adminWallet = address(adminWallet_);
        USDT = address(USDT_);
    }

    modifier onlyAdmin {
      require(msg.sender == adminWallet);
      _;
    }

    function playerStoxsLength() external view returns (uint256) {
        return playerStoxs.length();
    }

    function playerStoxAtIndex(uint256 index_) external view returns (address) {
        return playerStoxs.at(index_);
    }

    function getPlayerStox(address playerStox_) external view returns (bool) {
        return playerStoxs.contains(playerStox_);
    }

    function createPlayerStox(string memory name_, string memory symbol_, uint8 decimals_) external onlyAdmin {
        PlayerStoxTokenUpgradableProxy playerStox = new PlayerStoxTokenUpgradableProxy(playerStoxImplementation);
        IPlayerStoxToken(address(playerStox)).initialize(name_, symbol_, decimals_);
        playerStoxs.add(address(playerStox));
    }

    function deletePlayerStox(address playerStox_) external onlyAdmin {
        require(playerStoxs.contains(playerStox_), "Player does not exist.");
        playerStoxs.remove(address(playerStox_));
    }

    function userWithdraw(address token_, address user_, uint256 amount_) external {
        require(playerStoxs.contains(msg.sender), "Can be called only by player stox contract.");
        IERC20 token = IERC20(token_);
        require(token.allowance(adminWallet, address(this)) >= amount_, "Not enough allowance");
        token.transferFrom(adminWallet, user_, amount_);
    }

    function userDeposit(address token_, address user_, uint256 amount_) external {
        require(playerStoxs.contains(msg.sender), "Can be called only by player stox contract.");
        IERC20 token = IERC20(token_);
        require(token.allowance(user_, address(this)) >= amount_, "Not enough allowance");
        token.transferFrom(user_, curveWallet, amount_);
    }

    function migratePlayerStoxImplementation(address newPlayerStoxImpl_) external onlyAdmin {
        playerStoxImplementation = address(newPlayerStoxImpl_);
        for (uint i = 0; i < playerStoxs.length(); i++) {
          address playerStox = playerStoxs.at(i);
          IPlayerStoxToken(playerStox).upgradeTo(playerStoxImplementation);
        }
    }

    function updateAdminWallet(address newAdminWallet_) external onlyAdmin {
        adminWallet = newAdminWallet_;
    }

    function updateCurveWallet(address newCurveWallet_) external onlyAdmin {
        curveWallet = newCurveWallet_;
    }

}

//block deposit & withdraw for any token other than USDT