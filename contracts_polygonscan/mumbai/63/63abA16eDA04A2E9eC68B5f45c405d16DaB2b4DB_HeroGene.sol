// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IHeroGene.sol";
import "./base/RNGCallerBase.sol";
import "./base/SecurityBase.sol";
import "./utils/Integers.sol";
import "./utils/ExStrings.sol";
import "./HeroGeneShowSkill.sol";

contract HeroGene is IHeroGene, RNGCallerBase, SecurityBase {
    using ExStrings for string;
    using Integers for uint256;

    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address _HeroGeneShowSkillContract;

    bool HasData;
    uint[] RandIntList;
    uint index;

    constructor() {
    }

    function getHeroGeneShowSkillContract() public view returns (address) {
        return _HeroGeneShowSkillContract;
    }

    function setHeroGeneShowSkillContract(address addr) public onlyMinter {
        _HeroGeneShowSkillContract = addr;
    }

    function _checkRNGModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function parseIntSelf(string memory s) private pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (uint(uint8(b[i])) >= 48 && uint(uint8(b[i])) <= 57) {
                result = result * 10 + (uint(uint8(b[i])) - 48);
            }
        }
        return result;
    }

    function get_rand_int(uint x, uint step, address owner) internal returns(uint mold){
        if (x == 0) {
            return step;
        }
        if (HasData == false) {
            // RandIntList = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25];
            RandIntList = _expandRandomness(owner, 25);
            HasData = true;
        }
        uint v = RandIntList[index];
        mold = v%(x) + step;
        if (index == 24){
            HasData = false;
            index = 0;
        }
        index = index + 1;
    }

    struct ParentADNA{
        string batchA;
        string unitA;
        string campA;
        string attrA;
        string showA;
        string skillA;
        string showA_r1;
        string skillA_r1;
        string showA_r2;
        string skillA_r2;
    }

    struct ParentBDNA{
        string batchB;
        string unitB;
        string campB;
        string attrB;
        string showB;
        string skillB;
        string showB_r1;
        string skillB_r1;
        string showB_r2;
        string skillB_r2;
    }

    struct BornDNAInfo{
        string batchC;
        string unitC;
        string campC;
        string attrC;
        string showC;
        string skillC;
        string showC_r1;
        string skillC_r1;
        string showC_r2;
        string skillC_r2;
    }

    struct Attr{
        uint attrA_health;
        uint attrA_speed;
        uint attrA_skill;
        uint attrA_mood;
        uint attrB_health;
        uint attrB_speed;
        uint attrB_skill;
        uint attrB_mood;
        uint attrC_health;
        uint attrC_speed;
        uint attrC_skill;
        uint attrC_mood;
    }

    function get_unit(string memory unitA, string memory unitB, address owner, uint256 limit) internal returns(string memory){
        uint r = get_rand_int(100000, 1, owner);
        if (r <= limit) {
            return unitA;
        } else {
            return unitB;
        }
    }

    function get_camp(string memory campA, string memory campB, address owner) internal returns(string memory){
        uint r = get_rand_int(100000, 1, owner);
        if (r <= 50000) {
            return campA;
        } else {
            return campB;
        }
    }

    function get_attr(string memory attrA, string memory attrB) internal pure returns(string memory res){
        Attr memory attr;
        attr.attrA_health = parseIntSelf(attrA._substring(2, 0));
        attr.attrA_speed = parseIntSelf(attrA._substring(2, 2));
        attr.attrA_skill = parseIntSelf(attrA._substring(2, 4));
        attr.attrA_mood = parseIntSelf(attrA._substring(2, 6));
        attr.attrB_health = parseIntSelf(attrB._substring(2, 0));
        attr.attrB_speed = parseIntSelf(attrB._substring(2, 2));
        attr.attrB_skill = parseIntSelf(attrB._substring(2, 4));
        attr.attrB_mood = parseIntSelf(attrB._substring(2, 6));

        attr.attrC_health = (attr.attrA_health + attr.attrB_health)/2;
        attr.attrC_speed = (attr.attrA_speed + attr.attrB_speed)/2;
        attr.attrC_skill = (attr.attrA_skill + attr.attrB_skill)/2;
        attr.attrC_mood = (attr.attrA_mood + attr.attrB_mood)/2;
        uint attr_total = attr.attrC_health + attr.attrC_speed + attr.attrC_skill + attr.attrC_mood;
        uint add = 140 - attr_total;
        while (add > 0) {
            add = add - 1;
            if (attr.attrC_health < 43) {
                attr.attrC_health = attr.attrC_health + 1;
                continue;
            }
            if (attr.attrC_speed < 43) {
                attr.attrC_speed = attr.attrC_speed + 1;
                continue;
            }
            if (attr.attrC_skill < 43) {
                attr.attrC_skill = attr.attrC_skill + 1;
                continue;
            }          
            if (attr.attrC_mood < 43) {
                attr.attrC_mood = attr.attrC_mood + 1;
                continue;
            }
        }
        res = Integers.toString(attr.attrC_health);
        res = res.concat(Integers.toString(attr.attrC_speed));
        res = res.concat(Integers.toString(attr.attrC_skill));
        res = res.concat(Integers.toString(attr.attrC_mood));
        return res;
    }

    function getBornDNA(uint256 parent_a_dna, uint256 parent_b_dna, address owner) public override returns(uint256 _dna) {
        bool isSeedReady = isRNGSeedReady(owner);
        require(isSeedReady, "RNG seed is not ready");

        string memory parentA_dna = Integers.toString(parent_a_dna);
        string memory parentB_dna = Integers.toString(parent_b_dna);
        ParentADNA memory ParentA;
        ParentBDNA memory ParentB;
        BornDNAInfo memory DNA;

        ParentA.batchA = parentA_dna._substring(2, 0); // 2
        ParentA.unitA = parentA_dna._substring(3, 2);  //3
        ParentA.campA = parentA_dna._substring(2, 5);  //2
        ParentA.attrA = parentA_dna._substring(8, 7); //8
        ParentA.showA = parentA_dna._substring(12, 15); //12
        ParentA.skillA = parentA_dna._substring(8, 27); //8
        ParentA.showA_r1 = parentA_dna._substring(12, 35); //12
        ParentA.skillA_r1 = parentA_dna._substring(8, 47); //8
        ParentA.showA_r2 = parentA_dna._substring(12, 55); // 12
        ParentA.skillA_r2 = parentA_dna._substring(8, 67); // 8

        ParentB.batchB = parentB_dna._substring(2, 0); // 2
        ParentB.unitB = parentB_dna._substring(3, 2);  //3
        ParentB.campB = parentB_dna._substring(2, 5);  //2
        ParentB.attrB = parentB_dna._substring(8, 7); //8
        ParentB.showB = parentB_dna._substring(12, 15); //12
        ParentB.skillB = parentB_dna._substring(8, 27); //8
        ParentB.showB_r1 = parentB_dna._substring(12, 35); //12
        ParentB.skillB_r1 = parentB_dna._substring(8, 47); //8
        ParentB.showB_r2 = parentB_dna._substring(12, 55); // 12
        ParentB.skillB_r2 = parentB_dna._substring(8, 67); // 8

        DNA.batchC = "10";
        DNA.unitC = get_unit(ParentA.unitA, ParentB.unitB, owner, 70000);
        DNA.campC = get_unit(ParentA.campA, ParentB.campB, owner, 50000);
        DNA.attrC = get_attr(ParentA.attrA, ParentB.attrB);
        string[6] memory show_skill= HeroGeneShowSkill(_HeroGeneShowSkillContract).get_show_skill([ParentA.showA, ParentA.skillA, ParentB.showB, ParentB.skillB,
                        ParentA.showA_r1, ParentA.skillA_r1, ParentA.showA_r2, ParentA.skillA_r2,
                        ParentB.showB_r1, ParentB.skillB_r1, ParentB.showB_r2, ParentB.skillB_r2], owner);

        string memory dna = DNA.batchC.concat(DNA.unitC);
        dna = dna.concat(DNA.campC);
        dna = dna.concat(DNA.attrC);
        dna = dna.concat(show_skill[0]);
        dna = dna.concat(show_skill[1]);
        dna = dna.concat(show_skill[2]);
        dna = dna.concat(show_skill[3]);
        dna = dna.concat(show_skill[4]);
        dna = dna.concat(show_skill[5]);
        _dna = parseIntSelf(dna);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IHeroGene.sol";
import "./base/RNGCallerBase.sol";
import "./utils/Integers.sol";
import "./utils/ExStrings.sol";

contract HeroGeneShowSkill is RNGCallerBase {
    using ExStrings for string;
    using Integers for uint256;

    bool HasData;
    uint[] RandIntList;
    uint index;

    function _checkRNGModifier(address caller) internal virtual override {
        // _checkRole(MINTER_ROLE, caller);
    }

    struct InfoAData {
        string showA_head;
        string showA_hand;
        string showA_body;
        string showA_weapon;
        string showA_platform;
        string showA_flag;
        string skillA_head;
        string skillA_hand;
        string skillA_body;
        string skillA_weapon;
    }

    struct InfoBData {
        string showB_head;
        string showB_hand;
        string showB_body;
        string showB_weapon;
        string showB_platform;
        string showB_flag;
        string skillB_head;
        string skillB_hand;
        string skillB_body;
        string skillB_weapon;
    }

    struct InfoAR1Data {
        string showA_r1_head;
        string showA_r1_hand;
        string showA_r1_body;
        string showA_r1_weapon;
        string showA_r1_platform;
        string showA_r1_flag;
        string skillA_r1_head;
        string skillA_r1_hand;
        string skillA_r1_body;
        string skillA_r1_weapon;
    }

    struct InfoBR1Data {
        string showB_r1_head;
        string showB_r1_hand;
        string showB_r1_body;
        string showB_r1_weapon;
        string showB_r1_platform;
        string showB_r1_flag;
        string skillB_r1_head;
        string skillB_r1_hand;
        string skillB_r1_body;
        string skillB_r1_weapon;
    }

    struct InfoAR2Data {
        string showA_r2_head;
        string showA_r2_hand;
        string showA_r2_body;
        string showA_r2_weapon;
        string showA_r2_platform;
        string showA_r2_flag;
        string skillA_r2_head;
        string skillA_r2_hand;
        string skillA_r2_body;
        string skillA_r2_weapon;
    }

    struct InfoBR2Data {
        string showB_r2_head;
        string showB_r2_hand;
        string showB_r2_body;
        string showB_r2_weapon;
        string showB_r2_platform;
        string showB_r2_flag;
        string skillB_r2_head;
        string skillB_r2_hand;
        string skillB_r2_body;
        string skillB_r2_weapon;
    }

    struct BornDnaData {
        string show_head;
        string show_hand;
        string show_body;
        string show_weapon;
        string show_platform;
        string show_flag;
        string skill_head;
        string skill_hand;
        string skill_body;
        string skill_weapon;

        string show_r1_head;
        string show_r1_hand;
        string show_r1_body;
        string show_r1_weapon;
        string show_r1_platform;
        string show_r1_flag;
        string skill_r1_head;
        string skill_r1_hand;
        string skill_r1_body;
        string skill_r1_weapon;

        string show_r2_head;
        string show_r2_hand;
        string show_r2_body;
        string show_r2_weapon;
        string show_r2_platform;
        string show_r2_flag;
        string skill_r2_head;
        string skill_r2_hand;
        string skill_r2_body;
        string skill_r2_weapon;

        string showC;
        string skillC;
        string showC_r1;
        string skillC_r1;
        string showC_r2;
        string skillC_r2;
    }

    struct ShowCResData{
        string[4] showC_head_res;
        string[4] showC_hand_res;
        string[4] showC_body_res;
        string[4] showC_weapon_res;
        string[2] showC_platform_res;
        string[2] showC_flag_res;
    }

    function get_rand_int(uint x, uint step, address owner) internal returns(uint mold){
        if (x == 0) {
            return step;
        }
        if (HasData == false) {
            // RandIntList = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25];
            RandIntList = _expandRandomness(owner, 25);
            HasData = true;
        }
        uint v = RandIntList[index];
        mold = v%(x) + step;
        if (index == 24){
            HasData = false;
            index = 0;
        }
        index = index + 1;
    }

    function legend_to_normal(string memory s) internal pure returns(string memory){
        if (s.compareTo("51")){
            return "11";
        }
        if (s.compareTo("61")){
            return "21";
        }
        if (s.compareTo("71")){
            return "31";
        }
        if (s.compareTo("81")){
            return "41";
        }
        return s;
    }

    function get_showC_skill(string[12] memory list_skill, address owner) internal returns(string[2] memory){
        // 1~37500 A;37501~75000 B;75001 ~ 84375 A_r1;84376~93750 B_r1;93751~96875 A_r2;96876~100000 B_r2
        string memory showC_ = "";
        string memory skillC_ = "";
        uint r = get_rand_int(100000, 1, owner);
        if (r <= 37500){
            showC_ = list_skill[0];
            skillC_ = list_skill[1];
        }
        if (r>37501 && r<=75000){
            showC_ = list_skill[2];
            skillC_ = list_skill[3];
        }
        if (r>75001 && r<=84375){
            showC_ = list_skill[4];
            skillC_ = list_skill[5];
        }
        if (r>84376 && r<=93750){
            showC_ = list_skill[6];
            skillC_ = list_skill[7];
        }
        if (r>93751 && r<=96875){
            showC_ = list_skill[8];
            skillC_ = list_skill[9];
        }
        if (r>96876 && r<=100000){
            showC_ = list_skill[10];
            skillC_ = list_skill[11];
        }
        return [showC_, skillC_];
    }

    function get_showC_platform_or_flag(string[6] memory pre_platform, address owner) internal returns(string memory){
        // 1~37500 A;37501~75000 B;75001 ~ 84375 A_r1;84376~93750 B_r1;93751~96875 A_r2;96876~100000 B_r2
        string memory showC_platform_or_flog = "";
        uint r = get_rand_int(100000, 1, owner);
        if (r <= 37500){
            showC_platform_or_flog = pre_platform[0];
        } else if (r>37501 && r<=75000){
            showC_platform_or_flog = pre_platform[1];
        } else if (r>75001 && r<=84375){
            showC_platform_or_flog = pre_platform[2];
        } else if (r>84376 && r<=93750){
            showC_platform_or_flog = pre_platform[3];
        } else if (r>93751 && r<=96875){
            showC_platform_or_flog = pre_platform[4];
        } else if (r>96876 && r<=100000){
            showC_platform_or_flog = pre_platform[5];
        }
        return showC_platform_or_flog;
    }

    function get_C_r1_r2(string[6] memory list_show, string[6] memory list_skill,
                        string memory showC_check) internal pure returns(string[4] memory) {
        uint i = 0;
        uint j = 0;
        while (showC_check.compareTo(list_show[i]) && i < 5){
            i = i + 1;
        }
        while ((showC_check.compareTo(list_show[j]) || (list_show[i].compareTo(list_show[j]))) && (j < 5)){
            j = j + 1;
        }
        return [list_show[i], list_skill[i], list_show[j], list_skill[j]];
    }

    function get_showC_r1_r2_platform_or_flag(string[6] memory list_show_platform_or_flag,
                                        string memory showC_platform_or_flag) internal pure returns(string[2] memory) {
                                    
        uint i = 0;
        uint j = 0;
        while (showC_platform_or_flag.compareTo(list_show_platform_or_flag[i])  && i < 5){
            i = i + 1;
        }
        while (((showC_platform_or_flag.compareTo(list_show_platform_or_flag[j])) || 
        (list_show_platform_or_flag[i].compareTo(list_show_platform_or_flag[j]))) && (j < 5)){
            j = j + 1;
        }
        return [list_show_platform_or_flag[i], list_show_platform_or_flag[j]];
    }

    function get_show_skill(string[12] memory per_show_skill, address owner) public returns(string[6] memory){
        InfoAData memory InfoA;
        InfoBData memory InfoB;
        InfoAR1Data memory InfoAR1;
        InfoBR1Data memory InfoBR1;
        InfoAR2Data memory InfoAR2;
        InfoBR2Data memory InfoBR2;
        BornDnaData memory BornDNA;
        ShowCResData memory ShowCRes;

        // show skill
        InfoA.showA_head = per_show_skill[0]._substring(2, 0);
        InfoA.showA_hand = per_show_skill[0]._substring(2, 2);
        InfoA.showA_body = per_show_skill[0]._substring(2, 4);
        InfoA.showA_weapon = per_show_skill[0]._substring(2, 6);
        InfoA.showA_platform = per_show_skill[0]._substring(2, 8);
        InfoA.showA_flag = per_show_skill[0]._substring(2, 10);
        InfoA.showA_head = legend_to_normal(InfoA.showA_head);
        InfoA.showA_hand = legend_to_normal(InfoA.showA_hand);
        InfoA.showA_body = legend_to_normal(InfoA.showA_body);
        InfoA.showA_weapon = legend_to_normal(InfoA.showA_weapon);

        InfoA.skillA_head = per_show_skill[1]._substring(2, 0);
        InfoA.skillA_hand = per_show_skill[1]._substring(2, 2);
        InfoA.skillA_body = per_show_skill[1]._substring(2, 4);
        InfoA.skillA_weapon = per_show_skill[1]._substring(2, 6);

        InfoB.showB_head = per_show_skill[2]._substring(2, 0);
        InfoB.showB_hand = per_show_skill[2]._substring(2, 2);
        InfoB.showB_body = per_show_skill[2]._substring(2, 4);
        InfoB.showB_weapon = per_show_skill[2]._substring(2, 6);
        InfoB.showB_platform = per_show_skill[2]._substring(2, 8);
        InfoB.showB_flag = per_show_skill[2]._substring(2, 10);
        InfoB.showB_head = legend_to_normal(InfoB.showB_head);
        InfoB.showB_hand = legend_to_normal(InfoB.showB_hand);
        InfoB.showB_body = legend_to_normal(InfoB.showB_body);
        InfoB.showB_weapon = legend_to_normal(InfoB.showB_weapon);

        InfoB.skillB_head = per_show_skill[3]._substring(2, 0);
        InfoB.skillB_hand = per_show_skill[3]._substring(2, 2);
        InfoB.skillB_body = per_show_skill[3]._substring(2, 4);
        InfoB.skillB_weapon = per_show_skill[3]._substring(2, 6);

        // r1 show skill
        InfoAR1.showA_r1_head = per_show_skill[4]._substring(2, 0);
        InfoAR1.showA_r1_hand = per_show_skill[4]._substring(2, 2);
        InfoAR1.showA_r1_body = per_show_skill[4]._substring(2, 4);
        InfoAR1.showA_r1_weapon = per_show_skill[4]._substring(2, 6);
        InfoAR1.showA_r1_platform = per_show_skill[4]._substring(2, 8);
        InfoAR1.showA_r1_flag = per_show_skill[4]._substring(2, 10);
        InfoAR1.showA_r1_head = legend_to_normal(InfoAR1.showA_r1_head);
        InfoAR1.showA_r1_hand = legend_to_normal(InfoAR1.showA_r1_hand);
        InfoAR1.showA_r1_body = legend_to_normal(InfoAR1.showA_r1_body);
        InfoAR1.showA_r1_weapon = legend_to_normal(InfoAR1.showA_r1_weapon);

        InfoAR1.skillA_r1_head = per_show_skill[5]._substring(2, 0);
        InfoAR1.skillA_r1_hand = per_show_skill[5]._substring(2, 2);
        InfoAR1.skillA_r1_body = per_show_skill[5]._substring(2, 4);
        InfoAR1.skillA_r1_weapon = per_show_skill[5]._substring(2, 6);

        InfoBR1.showB_r1_head = per_show_skill[6]._substring(2, 0);
        InfoBR1.showB_r1_hand = per_show_skill[6]._substring(2, 2);
        InfoBR1.showB_r1_body = per_show_skill[6]._substring(2, 4);
        InfoBR1.showB_r1_weapon = per_show_skill[6]._substring(2, 6);
        InfoBR1.showB_r1_platform = per_show_skill[6]._substring(2, 8);
        InfoBR1.showB_r1_flag = per_show_skill[6]._substring(2, 10);
        InfoBR1.showB_r1_head = legend_to_normal(InfoBR1.showB_r1_head);
        InfoBR1.showB_r1_hand = legend_to_normal(InfoBR1.showB_r1_hand);
        InfoBR1.showB_r1_body = legend_to_normal(InfoBR1.showB_r1_body);
        InfoBR1.showB_r1_weapon = legend_to_normal(InfoBR1.showB_r1_weapon);

        InfoBR1.skillB_r1_head = per_show_skill[7]._substring(2, 0);
        InfoBR1.skillB_r1_hand = per_show_skill[7]._substring(2, 2);
        InfoBR1.skillB_r1_body = per_show_skill[7]._substring(2, 4);
        InfoBR1.skillB_r1_weapon = per_show_skill[7]._substring(2, 6);

        // r2 show skill
        InfoAR2.showA_r2_head = per_show_skill[8]._substring(2, 0);
        InfoAR2.showA_r2_hand = per_show_skill[8]._substring(2, 2);
        InfoAR2.showA_r2_body = per_show_skill[8]._substring(2, 4);
        InfoAR2.showA_r2_weapon = per_show_skill[8]._substring(2, 6);
        InfoAR2.showA_r2_platform = per_show_skill[8]._substring(2, 8);
        InfoAR2.showA_r2_flag = per_show_skill[8]._substring(2, 10);
        InfoAR2.showA_r2_head = legend_to_normal(InfoAR2.showA_r2_head);
        InfoAR2.showA_r2_hand = legend_to_normal(InfoAR2.showA_r2_hand);
        InfoAR2.showA_r2_body = legend_to_normal(InfoAR2.showA_r2_body);
        InfoAR2.showA_r2_weapon = legend_to_normal(InfoAR2.showA_r2_weapon);

        InfoAR2.skillA_r2_head = per_show_skill[9]._substring(2, 0);
        InfoAR2.skillA_r2_hand = per_show_skill[9]._substring(2, 2);
        InfoAR2.skillA_r2_body = per_show_skill[9]._substring(2, 4);
        InfoAR2.skillA_r2_weapon = per_show_skill[9]._substring(2, 6);

        InfoBR2.showB_r2_head = per_show_skill[10]._substring(2, 0);
        InfoBR2.showB_r2_hand = per_show_skill[10]._substring(2, 2);
        InfoBR2.showB_r2_body = per_show_skill[10]._substring(2, 4);
        InfoBR2.showB_r2_weapon = per_show_skill[10]._substring(2, 6);
        InfoBR2.showB_r2_platform = per_show_skill[10]._substring(2, 8);
        InfoBR2.showB_r2_flag = per_show_skill[10]._substring(2, 10);
        InfoBR2.showB_r2_head = legend_to_normal(InfoBR2.showB_r2_head);
        InfoBR2.showB_r2_hand = legend_to_normal(InfoBR2.showB_r2_hand);
        InfoBR2.showB_r2_body = legend_to_normal(InfoBR2.showB_r2_body);
        InfoBR2.showB_r2_weapon = legend_to_normal(InfoBR2.showB_r2_weapon);

        InfoBR2.skillB_r2_head = per_show_skill[11]._substring(2, 0);
        InfoBR2.skillB_r2_hand = per_show_skill[11]._substring(2, 2);
        InfoBR2.skillB_r2_body = per_show_skill[11]._substring(2, 4);
        InfoBR2.skillB_r2_weapon = per_show_skill[11]._substring(2, 6);

        string[2] memory showC_skill_head = get_showC_skill([InfoA.showA_head, InfoA.skillA_head, InfoB.showB_head, InfoB.skillB_head,
                                                InfoAR1.showA_r1_head, InfoAR1.skillA_r1_head, InfoBR1.showB_r1_head, InfoBR1.skillB_r1_head,
                                                InfoAR2.showA_r2_head, InfoAR2.skillA_r2_head, InfoBR2.showB_r2_head, InfoBR2.skillB_r2_head], owner);   
        BornDNA.show_head = showC_skill_head[0];
        BornDNA.skill_head = showC_skill_head[1];
        string[2] memory showC_skill_hand = get_showC_skill([InfoA.showA_hand, InfoA.skillA_hand, InfoB.showB_hand, InfoB.skillB_hand,
                                                InfoAR1.showA_r1_hand, InfoAR1.skillA_r1_hand, InfoBR1.showB_r1_hand, InfoBR1.skillB_r1_hand,
                                                InfoAR2.showA_r2_hand, InfoAR2.skillA_r2_hand, InfoBR2.showB_r2_hand, InfoBR2.skillB_r2_hand], owner);   
        BornDNA.show_hand = showC_skill_hand[0];
        BornDNA.skill_hand = showC_skill_hand[1];
        string[2] memory showC_skill_body = get_showC_skill([InfoA.showA_body, InfoA.skillA_body, InfoB.showB_body, InfoB.skillB_body,
                                                InfoAR1.showA_r1_body, InfoAR1.skillA_r1_body, InfoBR1.showB_r1_body, InfoBR1.skillB_r1_body,
                                                InfoAR2.showA_r2_body, InfoAR2.skillA_r2_body, InfoBR2.showB_r2_body, InfoBR2.skillB_r2_body], owner);   
        BornDNA.show_body = showC_skill_body[0];
        BornDNA.skill_body = showC_skill_body[1];
        string[2] memory showC_skill_weapon = get_showC_skill([InfoA.showA_weapon, InfoA.skillA_weapon, InfoB.showB_weapon, InfoB.skillB_weapon,
                                                InfoAR1.showA_r1_weapon, InfoAR1.skillA_r1_weapon, InfoBR1.showB_r1_weapon, InfoBR1.skillB_r1_weapon,
                                                InfoAR2.showA_r2_weapon, InfoAR2.skillA_r2_weapon, InfoBR2.showB_r2_weapon, InfoBR2.skillB_r2_weapon], owner);   
        BornDNA.show_weapon = showC_skill_weapon[0];
        BornDNA.skill_weapon = showC_skill_weapon[1];
        
        BornDNA.show_platform = get_showC_platform_or_flag([InfoA.showA_platform, InfoB.showB_platform,
                                                        InfoAR1.showA_r1_platform, InfoBR1.showB_r1_platform,
                                                        InfoAR2.showA_r2_platform, InfoBR2.showB_r2_platform], owner);
          
        
        BornDNA.show_flag = get_showC_platform_or_flag([InfoA.showA_flag, InfoB.showB_flag,
                                                   InfoAR1.showA_r1_flag, InfoBR1.showB_r1_flag,
                                                   InfoAR2.showA_r2_flag, InfoBR2.showB_r2_flag], owner);

        BornDNA.showC = BornDNA.show_head.concat(BornDNA.show_hand);
        BornDNA.showC = BornDNA.showC.concat(BornDNA.show_body).concat(BornDNA.show_weapon);
        BornDNA.showC = BornDNA.showC.concat(BornDNA.show_platform).concat(BornDNA.show_flag);

        BornDNA.skillC = BornDNA.skill_head.concat(BornDNA.skill_hand);
        BornDNA.skillC = BornDNA.skillC.concat(BornDNA.skill_body).concat(BornDNA.skill_weapon);

        ShowCRes.showC_head_res = get_C_r1_r2([InfoA.showA_head, InfoB.showB_head, InfoAR1.showA_r1_head, 
                                    InfoBR1.showB_r1_head, InfoAR2.showA_r2_head, InfoBR2.showB_r2_head],
                                    [InfoA.skillA_head, InfoB.skillB_head, InfoAR1.skillA_r1_head,
                                    InfoBR1.skillB_r1_head, InfoAR2.skillA_r2_head, InfoBR2.skillB_r2_head], 
                                    BornDNA.show_head);
        ShowCRes.showC_hand_res = get_C_r1_r2([InfoA.showA_hand, InfoB.showB_hand, InfoAR1.showA_r1_hand,
                                    InfoBR1.showB_r1_hand, InfoAR2.showA_r2_hand, InfoBR2.showB_r2_hand],
                                    [InfoA.skillA_hand, InfoB.skillB_hand, InfoAR1.skillA_r1_hand, 
                                    InfoBR1.skillB_r1_hand, InfoAR2.skillA_r2_hand, InfoBR2.skillB_r2_hand],
                                    BornDNA.show_hand);
        ShowCRes.showC_body_res = get_C_r1_r2([InfoA.showA_body, InfoB.showB_body, InfoAR1.showA_r1_body, 
                                    InfoBR1.showB_r1_body, InfoAR2.showA_r2_body, InfoBR2.showB_r2_body],
                                    [InfoA.skillA_body, InfoB.skillB_body, InfoAR1.skillA_r1_body, 
                                    InfoBR1.skillB_r1_body, InfoAR2.skillA_r2_body, InfoBR2.skillB_r2_body],
                                    BornDNA.show_body);
        ShowCRes.showC_weapon_res = get_C_r1_r2([InfoA.showA_weapon, InfoB.showB_weapon, InfoAR1.showA_r1_weapon, 
                                    InfoBR1.showB_r1_weapon, InfoAR2.showA_r2_weapon, InfoBR2.showB_r2_weapon],
                                    [InfoA.skillA_weapon, InfoB.skillB_weapon, InfoAR1.skillA_r1_weapon, 
                                    InfoBR1.skillB_r1_weapon, InfoAR2.skillA_r2_weapon, InfoBR2.skillB_r2_weapon],
                                    BornDNA.show_weapon);
        ShowCRes.showC_platform_res = get_showC_r1_r2_platform_or_flag([InfoA.showA_platform, InfoB.showB_platform, InfoAR1.showA_r1_platform, 
                                    InfoBR1.showB_r1_platform, InfoAR2.showA_r2_platform, InfoBR2.showB_r2_platform], BornDNA.show_platform);
        ShowCRes.showC_flag_res = get_showC_r1_r2_platform_or_flag([InfoA.showA_flag, InfoB.showB_flag, InfoAR1.showA_r1_flag,
                                    InfoBR1.showB_r1_flag, InfoAR2.showA_r2_flag, InfoBR2.showB_r2_flag], BornDNA.show_flag);
        BornDNA.showC_r1 = ShowCRes.showC_head_res[0].concat(ShowCRes.showC_hand_res[0]);
        BornDNA.showC_r1 = BornDNA.showC_r1.concat(ShowCRes.showC_body_res[0]);
        BornDNA.showC_r1 = BornDNA.showC_r1.concat(ShowCRes.showC_weapon_res[0]);
        BornDNA.showC_r1 = BornDNA.showC_r1.concat(ShowCRes.showC_platform_res[0]);
        BornDNA.showC_r1 = BornDNA.showC_r1.concat(ShowCRes.showC_flag_res[0]);

        BornDNA.skillC_r1 = ShowCRes.showC_head_res[1].concat(ShowCRes.showC_hand_res[1]);
        BornDNA.skillC_r1 = BornDNA.skillC_r1.concat(ShowCRes.showC_body_res[1]);
        BornDNA.skillC_r1 = BornDNA.skillC_r1.concat(ShowCRes.showC_weapon_res[1]);

        BornDNA.showC_r2 = ShowCRes.showC_head_res[2].concat(ShowCRes.showC_hand_res[2]);
        BornDNA.showC_r2 = BornDNA.showC_r2.concat(ShowCRes.showC_body_res[2]);
        BornDNA.showC_r2 = BornDNA.showC_r2.concat(ShowCRes.showC_weapon_res[2]);
        BornDNA.showC_r2 = BornDNA.showC_r2.concat(ShowCRes.showC_platform_res[1]);
        BornDNA.showC_r2 = BornDNA.showC_r2.concat(ShowCRes.showC_flag_res[1]);

        BornDNA.skillC_r2 = ShowCRes.showC_head_res[3].concat(ShowCRes.showC_hand_res[3]);
        BornDNA.skillC_r2 = BornDNA.skillC_r2.concat(ShowCRes.showC_body_res[3]);
        BornDNA.skillC_r2 = BornDNA.skillC_r2.concat(ShowCRes.showC_weapon_res[3]);

        return [BornDNA.showC, BornDNA.skillC, BornDNA.showC_r1, BornDNA.skillC_r1, BornDNA.showC_r2, BornDNA.skillC_r2];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IIdleRNG.sol";

abstract contract RNGCallerBase {

    address internal _RNGContract;

    constructor() {
    }

    modifier RNGReady() {
        require(_RNGContract != address(0), "RNG contract is not ready");
        _;
    }

    function _checkRNGModifier(address caller) internal virtual;

    function RNGContract() public view returns (address) {
        return _RNGContract;
    }

    function setRNGContract(address addr) public {
        _checkRNGModifier(msg.sender);
        _RNGContract = addr;
    }

    function isRNGSeedReady(address from) public view RNGReady returns (bool) {
        return IIdleRNG(_RNGContract).isSeedReady(from);
    }

    function _generateRNGSeedTo(address from) internal RNGReady {
        IIdleRNG(_RNGContract).getRandomNumber(from);
    }

    function _expandRandomness(address from, uint256 n) internal RNGReady returns (uint256[] memory expandedValues) {
        return IIdleRNG(_RNGContract).expandRandomness(from, n);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SecurityBase is AccessControlEnumerable, Pausable {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _;
    }

    constructor() {
        _init_admin_role();
    }

    // init creator as admin role
    function _init_admin_role() internal virtual {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function grantMinter(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)) {
        _setupRole(MINTER_ROLE, account);
    }

    function grantPauser(address account) public virtual onlyRole(getRoleAdmin(PAUSER_ROLE)) {
        _setupRole(PAUSER_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// market contract interface
interface IHeroGene {
    function getBornDNA(uint parent_a_dna, uint parent_b_dna, address owner) external returns(uint256 _dna);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract interface
interface IIdleRNG {
    function getRandomNumber(address from) external;

    function expandRandomness(address from, uint256 n) external returns (uint256[] memory expandedValues);

    function isSeedReady(address from) external view returns (bool);

    function setRandomSeed(address addr, uint256 randomness) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * ExStrings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <[email protected]>
 */
library ExStrings {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }


    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Integers Library
 * 
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 * 
 * @author James Lockhart <[email protected]>
 */
library Integers {

    function parseInt(string memory _value)
        public
        pure
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function toByte(uint8 _base)
        public
        pure
        returns (bytes1 _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            mstore8(m_alloc, _base)
            _ret := mload(m_alloc)
        }
    }


    function toBytes(uint _base)
        internal
        pure
        returns (bytes memory _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            _ret := mload(m_alloc)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _base)
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}