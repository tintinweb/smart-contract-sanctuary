/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// File: contracts/whitelist/traits/Administrated.sol

/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;



/**
 * @title Administrated
 *
 * @dev Contract provides a basic access control mechanism for Admin role.
 */
contract Administrated is Initializable, OwnableUpgradeSafe {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);

    EnumerableSet.AddressSet internal admins;

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Administrated: sender is not admin");
        _;
    }

    /**
     * @dev Checks if an account is admin.
     * @param _admin The address of admin account to check.
     */
    function isAdmin(address _admin) public view returns (bool) {
        return admins.contains(_admin);
    }

    /**
     * @dev Returns count of added admins accounts.
     */
    function getAdminCount() external view returns (uint256) {
        return admins.length();
    }

    /**
     * @dev Allows the owner to add admin account.
     *
     * Emits a {AddAdmin} event with `admin` set to new added admin address.
     *
     * @param _admin The address of admin account to add.
     */
    function addAdmin(address _admin) external onlyOwner {
        admins.add(_admin);
        emit AddAdmin(_admin);
    }

    /**
     * @dev Allows the owner to remove admin account.
     *
     * Emits a {RemoveAdmin} event with `admin` set to removed admin address.
     *
     * @param _admin The address of admin account to remove.
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins.remove(_admin);
        emit RemoveAdmin(_admin);
    }
}

// File: contracts/whitelist/traits/Managed.sol

/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity 0.6.12;


/**
 * @title Managed
 *
 * @dev Contract provides a basic access control mechanism for Manager role.
 * The contract also includes control of access rights for Admin and Manager roles both.
 */
contract Managed is Initializable, Administrated {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddManager(address indexed manager, address indexed admin);
    event RemoveManager(address indexed manager, address indexed admin);

    EnumerableSet.AddressSet internal managers;

    /**
     * @dev Throws if called by any account other than the admin or manager.
     */
    modifier onlyAdminOrManager() {
        require(
            isAdmin(msg.sender) || isManager(msg.sender),
            "Managered: sender is not admin or manager"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(isManager(msg.sender), "Managered: sender is not manager");
        _;
    }


    /**
     * @dev Checks if an account is manager.
     * @param _manager The address of manager account to check.
     */
    function isManager(address _manager) public view returns (bool) {
        return managers.contains(_manager);
    }

    /**
     * @dev Returns count of added managers accounts.
     */
    function getManagerCount() external view returns (uint256) {
        return managers.length();
    }

    /**
     * @dev Allows the admin to add manager account.
     *
     * Emits a {AddManager} event with `manager` set to new added manager address
     * and `admin` to who added it.
     *
     * @param _manager The address of manager account to add.
     */
    function addManager(address _manager) external onlyAdmin {
        managers.add(_manager);
        emit AddManager(_manager, msg.sender);
    }

    /**
     * @dev Allows the admin to remove manager account.
     *
     * Emits a {removeManager} event with `manager` set to removed manager address
     * and `admin` to who removed it.
     *
     * @param _manager The address of manager account to remove.
     */
    function removeManager(address _manager) external onlyAdmin {
        managers.remove(_manager);
        emit RemoveManager(_manager, msg.sender);
    }
}

// File: contracts/whitelist/traits/Pausable.sol

/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity 0.6.12;


/**
 * @title Pausable
 *
 * @dev Contract provides a stop emergency mechanism.
 */
contract Pausable is Initializable, OwnableUpgradeSafe {
    event Paused();
    event Unpaused();

    bool private _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Allows the owner to pause, triggers stopped state.
     *
     * Emits a {Paused} event.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Allows the owner to do unpause, returns to normal state.
     *
     * Emits a {Unpaused} event.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

// File: contracts/whitelist/interfaces/ICarTokenController.sol

/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
pragma solidity >=0.6.0;

/**
 * @dev Interface of CarTokenController (part of security token contracts).
 *
 * CarTokenController contract source: https://github.com/CurioTeam/security-token-contracts/blob/dd5c82e566d24d0e87639316a9420afdb9b30e71/contracts/CarTokenController.sol
 */
interface ICarTokenController {
    function isInvestorAddressActive(address account) external view returns (bool);
}

// File: contracts/whitelist/DexWhitelist.sol

/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;




/**
 * @title DexWhitelist
 *
 * @dev The contract stores a whitelist of users (investors) and allows to
 * manage it. The contract also provides for a separate whitelist for tokens addresses.
 * It is possible to check the whitelisted status of users from the whitelist
 * located in the separate CarTokenController contract (part of security token contracts).
 * All user/tokens checks can be disabled by owner.
 *
 * CarTokenController contract source: https://github.com/CurioTeam/security-token-contracts/blob/dd5c82e566d24d0e87639316a9420afdb9b30e71/contracts/CarTokenController.sol
 */
contract DexWhitelist is Initializable, Managed, Pausable {
    ICarTokenController public controller;

    struct Investor {
        address addr;
        bool active;
    }

    /**
     * @dev Whitelist of users (investors)
     */
    mapping(bytes32 => Investor) public investors;
    mapping(address => bytes32) public keyOfInvestor;

    /**
     * @dev Whitelist of tokens
     */
    mapping(address => bool) public tokens;

    /**
     * @dev Enable/disable whitelist's statuses for several groups of operations.
     *
     * 'liquidity wl' - for operations with liquidity pools
     * 'swap wl' - for operations with swap mechanism
     * 'farm wl' - for operations with farming mechanism
     * 'token wl' - for whitelist of supported tokens
     */
    bool public isLiquidityWlActive;
    bool public isSwapWlActive;
    bool public isFarmWlActive;
    bool public isTokenWlActive;

    event SetController(address indexed controller);

    event AddNewInvestor(bytes32 indexed key, address indexed addr);
    event SetInvestorActive(bytes32 indexed key, bool active);
    event ChangeInvestorAddress(
        address indexed sender,
        bytes32 indexed key,
        address indexed oldAddr,
        address newAddr
    );

    event SetLiquidityWlActive(bool active);
    event SetSwapWlActive(bool active);
    event SetFarmWlActive(bool active);
    event SetTokenWlActive(bool active);

    event SetTokenAddressActive(address indexed token, bool active);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @dev Checks if an investor's account is whitelisted. Check is done
     * in the whitelist of the contract and also in the CarTokenController.
     *
     * @param _addr The address of investor's account to check.
     */
    function isInvestorAddressActive(address _addr) public view returns (bool) {
        return
            investors[keyOfInvestor[_addr]].active ||
            (
                address(controller) != address(0)
                    ? controller.isInvestorAddressActive(_addr)
                    : false
            );
    }

    /**
     * @dev Returns true if address is in investor's whitelist
     * or liquidity whitelist is not active.
     *
     * @param _addr The address of investor's account to check.
     */
    function isLiquidityAddressActive(address _addr)
        public
        view
        returns (bool)
    {
        return !isLiquidityWlActive || isInvestorAddressActive(_addr);
    }

    /**
     * @dev Returns true if address is in investor's whitelist
     * or swap whitelist is not active.
     *
     * @param _addr The address of investor's account to check.
     */
    function isSwapAddressActive(address _addr) public view returns (bool) {
        return !isSwapWlActive || isInvestorAddressActive(_addr);
    }

    /**
     * @dev Returns true if address is in investor's whitelist
     * or farm whitelist is not active.
     *
     * @param _addr The address of investor's account to check.
     */
    function isFarmAddressActive(address _addr) public view returns (bool) {
        return !isFarmWlActive || isInvestorAddressActive(_addr);
    }

    /**
     * @dev Returns true if address is in token's whitelist
     * or token's whitelist is not active.
     *
     * @param _addr The address of token to check.
     */
    function isTokenAddressActive(address _addr) public view returns (bool) {
        return !isTokenWlActive || tokens[_addr];
    }

    /**
     * @dev Allows the msg.sender change your address in whitelist.
     *
     * Requirements:
     * - the contract must not be paused.
     *
     * @param _investorKey The key of investor.
     * @param _newAddr The address of investor's account.
     */
    function changeMyAddress(bytes32 _investorKey, address _newAddr)
        external
        whenNotPaused
    {
        require(
            investors[_investorKey].addr == msg.sender,
            "Investor address and msg.sender does not match"
        );

        _changeInvestorAddress(_investorKey, _newAddr);
    }

    /**
     * @dev Allows the admin or manager to add new investors
     * to whitelist.
     *
     * Requirements:
     * - lengths of keys and address arrays should be equal.
     *
     * @param _keys The keys of investors.
     * @param _addrs The addresses of investors accounts.
     */
    function addNewInvestors(
        bytes32[] calldata _keys,
        address[] calldata _addrs
    ) external onlyAdminOrManager {
        uint256 len = _keys.length;
        require(
            len == _addrs.length,
            "Lengths of keys and address does not match"
        );

        for (uint256 i = 0; i < len; i++) {
            _setInvestorAddress(_keys[i], _addrs[i]);

            emit AddNewInvestor(_keys[i], _addrs[i]);
        }
    }

    /**
     * @dev Allows the admin or manager to change investor's
     * whitelisted status.
     *
     * Emits a {SetInvestorActive} event with investor's key and new status.
     *
     * Requirements:
     * - the investor must be added to whitelist.
     *
     * @param _key The keys of investor.
     * @param _active The new status of investor's account.
     */
    function setInvestorActive(bytes32 _key, bool _active)
        external
        onlyAdminOrManager
    {
        require(investors[_key].addr != address(0), "Investor does not exists");
        investors[_key].active = _active;

        emit SetInvestorActive(_key, _active);
    }

    /**
     * @dev Allows the admin to change investor's address.
     *
     * @param _investorKey The keys of investor.
     * @param _newAddr The new address of investor's account.
     */
    function changeInvestorAddress(bytes32 _investorKey, address _newAddr)
        external
        onlyAdmin
    {
        _changeInvestorAddress(_investorKey, _newAddr);
    }

    /**
     * @dev Allows the admin to set token's whitelisted status.
     *
     * @param _token The address of token.
     * @param _active The token status.
     */
    function setTokenAddressActive(address _token, bool _active)
        external
        onlyAdmin
    {
        _setTokenAddressActive(_token, _active);
    }

    /**
     * @dev Allows the admin to set tokens as whitelisted or not.
     *
     * Requirements:
     * - lengths of tokens and statuses arrays should be equal.
     *
     * @param _tokens The addresses of tokens.
     * @param _active The tokens statuses.
     */
    function setTokenAddressesActive(
        address[] calldata _tokens,
        bool[] calldata _active
    ) external onlyAdmin {
        uint256 len = _tokens.length;
        require(
            len == _active.length,
            "Lengths of tokens and active does not match"
        );

        for (uint256 i = 0; i < len; i++) {
            _setTokenAddressActive(_tokens[i], _active[i]);
        }
    }

    /**
     * @dev Allows the owner to set CarTokenController contract.
     *
     * Emits a {SetController} event with `controller` set to
     * CarTokenController contract's address.
     *
     * @param _controller The address of CarTokenController contract.
     */
    function setController(ICarTokenController _controller) external onlyOwner {
        controller = _controller;
        emit SetController(address(_controller));
    }

    /**
     * @dev Allows the owner to enable/disable investors whitelist functionality
     * for operations with liquidity pools.
     *
     * @param _active Investors whitelist check status.
     */
    function setLiquidityWlActive(bool _active) external onlyOwner {
        _setLiquidityWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable investors whitelist functionality
     * for operations with swap.
     *
     * @param _active Investors whitelist check status.
     */
    function setSwapWlActive(bool _active) external onlyOwner {
        _setSwapWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable investors whitelist functionality
     * for operations with farming mechanism.
     *
     * @param _active Investors whitelist check status.
     */
    function setFarmWlActive(bool _active) external onlyOwner {
        _setFarmWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable tokens whitelist functionality.
     *
     * @param _active Tokens whitelist check status.
     */
    function setTokenWlActive(bool _active) external onlyOwner {
        _setTokenWlActive(_active);
    }

    /**
     * @dev Allows the owner to enable/disable investors and tokens whitelist
     * for all groups of operations in single transaction.
     *
     * @param _liquidityWlActive Investors whitelist check status for liquidity pools operations.
     * @param _swapWlActive Investors whitelist check status for swap operations.
     * @param _farmWlActive Investors whitelist check status for farming operations.
     * @param _tokenWlActive Tokens whitelist check status.
     */
    function setWlActive(
        bool _liquidityWlActive,
        bool _swapWlActive,
        bool _farmWlActive,
        bool _tokenWlActive
    ) external onlyOwner {
        _setLiquidityWlActive(_liquidityWlActive);
        _setSwapWlActive(_swapWlActive);
        _setFarmWlActive(_farmWlActive);
        _setTokenWlActive(_tokenWlActive);
    }


    /**
     * @dev Saves the investor's key and address and sets the status as whitelisted.
     *
     * Requirements:
     * - key and address must be empty.
     *
     * @param _key The key of investor.
     * @param _addr The address of investor.
     */
    function _setInvestorAddress(bytes32 _key, address _addr) internal {
        require(investors[_key].addr == address(0), "Investor already exists");
        require(keyOfInvestor[_addr] == bytes32(0), "Address already claimed");

        investors[_key] = Investor(_addr, true);
        keyOfInvestor[_addr] = _key;
    }

    /**
     * @dev Changes the address of the investor with the given key.
     *
     * Emits a {ChangeInvestorAddress} event with parameters: `sender` as msg.sender,
     * `key`, `oldAddr`, `newAddr`.
     *
     * Requirements:
     * - the new address must be different from the old one.
     *
     * @param _investorKey The key of investor.
     * @param _newAddr The new address of investor.
     */
    function _changeInvestorAddress(bytes32 _investorKey, address _newAddr)
        internal
    {
        address oldAddress = investors[_investorKey].addr;
        require(oldAddress != _newAddr, "Old address and new address the same");

        keyOfInvestor[investors[_investorKey].addr] = bytes32(0);
        investors[_investorKey] = Investor(address(0), false);

        _setInvestorAddress(_investorKey, _newAddr);

        emit ChangeInvestorAddress(
            msg.sender,
            _investorKey,
            oldAddress,
            _newAddr
        );
    }

    /**
     * @dev Sets token's whitelisted status.
     *
     * Emits a {SetTokenAddressActive} event token's address and new status.
     *
     * @param _token The address of token.
     * @param _active Token's whitelisted status.
     */
    function _setTokenAddressActive(address _token, bool _active) internal {
        tokens[_token] = _active;
        emit SetTokenAddressActive(_token, _active);
    }

    /**
     * @dev Sets status of enable/disable of investors whitelist
     * for operations with liquidity pools.
     *
     * Emits a {SetLiquidityWlActive} event with new status.
     *
     * @param _active Investors whitelist check status.
     */
    function _setLiquidityWlActive(bool _active) internal {
        isLiquidityWlActive = _active;
        emit SetLiquidityWlActive(_active);
    }

    /**
     * @dev Sets status of enable/disable of investors whitelist
     * for operations with swap.
     *
     * Emits a {SetSwapWlActive} event with new status.
     *
     * @param _active Investors whitelist check status.
     */
    function _setSwapWlActive(bool _active) internal {
        isSwapWlActive = _active;
        emit SetSwapWlActive(_active);
    }

    /**
     * @dev Sets status of enable/disable of investors whitelist
     * for operations with farming.
     *
     * Emits a {SetFarmWlActive} event with new status.
     *
     * @param _active Investors whitelist check status.
     */
    function _setFarmWlActive(bool _active) internal {
        isFarmWlActive = _active;
        emit SetFarmWlActive(_active);
    }

    /**
     * @dev Sets status of enable/disable of tokens whitelist.
     *
     * Emits a {SetTokenWlActive} event with new status.
     *
     * @param _active Tokens whitelist check status.
     */
    function _setTokenWlActive(bool _active) internal {
        isTokenWlActive = _active;
        emit SetTokenWlActive(_active);
    }
}