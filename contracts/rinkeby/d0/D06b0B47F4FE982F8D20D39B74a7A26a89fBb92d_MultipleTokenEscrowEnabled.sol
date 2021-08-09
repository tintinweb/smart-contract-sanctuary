// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/[email protected]
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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


// File @openzeppelin/contracts/utils/structs/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]



/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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


// File @openzeppelin/contracts/access/[email protected]


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}


// File @openzeppelin/contracts/security/[email protected]


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/BasicRelayRecipient.sol


/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address);

    function versionRecipient() external view virtual returns (string memory);
}

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient, Context, Ownable {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function setTrustedForwarder(address _trustedForwarder) public onlyOwner {
        trustedForwarder = _trustedForwarder;
    }

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(
            msg.sender == address(trustedForwarder),
            "Function can only be called through the trusted Forwarder"
        );
        _;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        override
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, IRelayRecipient)
        returns (address ret)
    {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}


// File contracts/MultipleTokenEscrowEnabled.sol

/**
By default the amount is not reserved.
 */

contract MultipleTokenEscrowEnabled is
    Ownable,
    BaseRelayRecipient,
    ReentrancyGuard
{
    /**
    The Wallet struct holds the data for all transactions.
    There are essentially three kinds of users that can modify state of the contract.
    - Owner
    - Admin
    - System

    The kinds of balances are:
    - totalBalance - Balance currently held.
    This does up when user `deposits` to escrow.
    This does up when user `withdraws` to escrow.
    (total-reserved) balance is always withdrawable.

    - reservedBalance - Balance which the user cannot use. This is part of total balance.
    The system can increase or decrease the reserved balance of any account.
    It cannot move reservedBalance from one account to another.
    Essentially it move the balance between a `reserved` and `unReserved`(or withdrawable state)

    - pendingBalance - Balance which is not part of total balance.
    The system can move currency from reservedBalance of account A to pending Balance of account B.
    By default, this balance is held until moved to totalBalance.
    There is an hourly(can be dynamically by admin) limit on the transfers which system can do from 
    `reservedBalance of account A to pending Balance of account B`;
    In case the amount exceeds the limit the pendingBalance needs to be approved by the admin.
    
     */

    event Deposit(
        address indexed addr,
        uint256 amount,
        address indexed tokenAddr
    );
    event Reserve(
        address indexed addr,
        uint256 amount,
        address indexed tokenAddr
    );
    event UnReserve(
        address indexed addr,
        uint256 amount,
        address indexed tokenAddr
    );
    event Withdraw(
        address indexed addr,
        uint256 amount,
        address indexed tokenAddr
    );

    event Transfer(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        address indexed tokenAddr
    );

    event TransferToPending(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        address indexed tokenAddr
    );

    event PendingApproved(
        address indexed addr,
        uint256 amount,
        address indexed tokenAddr
    );

    /**
    @notice ADMIN ROLE
    Admin can call transfer to Owner.
    */
    mapping(address => bool) public admins;

    /**
    @notice SYSTEM ROLE - Allowed to reserve balance on behalf of owners
    The system can reserve and unreserve balances.
    It will maintain with database as source of truth.
    */
    mapping(address => bool) public systems;

    /**
    @dev last Update Time for limit of system for reserved to pending.
     */
    uint256 lastUpdateTime;

    /**
    @dev duration after which limits of system go to zero.
     */
    uint256 public updateDuration;

    /**
    @dev the limits defined for Wallet.
     */
    struct Limits {
        uint256 totalLimit;
        uint256 usedLimit;
    }

    /**
    @dev The time after which system limits go to zero for every tokenAddr.
     */
    mapping(address => Limits) public limits;

    /**
    @notice - onlyAdmin
    */
    modifier onlyAdmin() {
        require(admins[_msgSender()], "MultipleTokenEscrowEnabled: Not admin.");
        _;
    }

    /**
    Allow admin access. */
    function addAdmin(address addr, bool enabled) external onlyOwner {
        admins[addr] = enabled;
    }

    /**
    @notice - onlySystem.
    onlySystem can update.
    */
    modifier onlySystem() {
        require(
            systems[_msgSender()],
            "MultipleTokenEscrowEnabled: Not system."
        );
        _;
    }

    /**
    @notice grant access to system role
     */
    function addSystem(address addr, bool enabled) external onlyOwner {
        systems[addr] = enabled;
    }

    /**
    @notice
    Update the duration for limit updates.
     */
    function setUpdateDuration(uint256 _updateDuration) external onlyAdmin {
        updateDuration = _updateDuration;
        lastUpdateTime = block.timestamp;
    }

    /**
    @notice add limit for every token
     */
    function setLimit(address tokenAddr, uint256 limit) external onlyAdmin {
        limits[tokenAddr].totalLimit = limit;
        limits[tokenAddr].usedLimit = 0;
    }

    /**
    @notice updateLimits for given tokenAddr.
    If current time is greater than lastTimestamp convert used limit to zero.
    Call this function before pendingTransfer by system.
    For native currency, address(0) is used.
     */
    modifier updateLimits(address tokenAddr) {
        if (lastUpdateTime + updateDuration > block.timestamp) {
            limits[tokenAddr].usedLimit = 0;
            lastUpdateTime = block.timestamp;
        }
        _;
    }

    /**
    The wallet structure with total, reserved, and pending.
     */
    struct Wallet {
        uint256 totalBalance;
        uint256 reservedBalance;
        uint256 pendingBalance;
    }

    /**
    @dev
    Mapping of ERC20 balances.
    User => Token => Wallet.
     */
    mapping(address => mapping(address => Wallet)) public balances;

    /**
    @dev
    Mapping of default currency (ETH on Ethereum Network and Polygon on Polygon network).
    User => Wallet.
     */
    mapping(address => Wallet) public defaultBalances;

    /**
    redundant
    @notice - getBalance for User for a given token.
    */
    function getBalance(address tokenAddr)
        public
        view
        returns (Wallet memory wallet)
    {
        return balances[_msgSender()][tokenAddr];
    }

    /**
    Overload for Biconomy Relayer.
    */
    function _msgSender()
        internal
        view
        virtual
        override(Context, BaseRelayRecipient)
        returns (address ret)
    {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
    constructor
     */
    constructor() {}

    /**
    initialize for proxy */
    function initialize(address _owner, address _trustedForwarder)
        external
        onlyOwner
    {
        transferOwnership(_owner);
        setupRoles(_owner);
        trustedForwarder = _trustedForwarder;
        lastUpdateTime = block.timestamp;
        updateDuration = 3600;
    }

    /**
    @dev Amount  
    User can custody his funds in ERC20 with us.
    */
    function deposit(uint256 amount, address tokenAddr) external nonReentrant {
        IERC20(tokenAddr).transferFrom(_msgSender(), address(this), amount);

        balances[_msgSender()][tokenAddr].totalBalance += amount;
        emit Deposit(_msgSender(), amount, tokenAddr);
    }

    /**
    @dev default currency deposit
    */
    function deposit_default() external payable nonReentrant {
        defaultBalances[_msgSender()].totalBalance += msg.value;
        emit Deposit(_msgSender(), msg.value, address(0));
    }

    /**
    @notice Added amount to reserve.
    System can increase the reserved funds of a a particular user.
    This is not `withdrawable` balance.
    If a user places a bid, the reserved balance goes up.
     */
    function reserve(
        address addr,
        uint256 amount,
        address tokenAddr
    ) external onlySystem {
        require(
            amount <=
                balances[addr][tokenAddr].totalBalance -
                    balances[addr][tokenAddr].reservedBalance,
            "MultipleTokenEscrowEnabled: Added amount exceeds allowed reservable balance."
        );
        balances[addr][tokenAddr].reservedBalance += amount;
        emit Reserve(addr, amount, tokenAddr);
    }

    /**
    @dev default currency reserve
    */
    function reserveDefault(address addr, uint256 amount) external onlySystem {
        require(
            amount <=
                defaultBalances[addr].totalBalance -
                    defaultBalances[addr].reservedBalance,
            "MultipleTokenEscrowEnabled: Added amount exceeds allowed reservable balance."
        );
        defaultBalances[addr].reservedBalance += amount;
        emit Reserve(addr, amount, address(0));
    }

    /**
    @notice Removed amount from reserved 
    Move back the currency to unReserved by system.
    If a user is outBid by another user, the un-reserved balance of user goes up.
    */
    function unReserve(
        address addr,
        uint256 amount,
        address tokenAddr
    ) external onlySystem {
        require(
            amount <= balances[addr][tokenAddr].reservedBalance,
            "MultipleTokenEscrowEnabled: UnReserve amount exceeds reservable balance."
        );

        balances[addr][tokenAddr].reservedBalance -= amount;
        emit UnReserve(addr, amount, tokenAddr);
    }

    /**
    @dev default currency unReserve
    */
    function unReserveDefault(address addr, uint256 amount)
        external
        onlySystem
    {
        require(
            amount <= defaultBalances[addr].reservedBalance,
            "MultipleTokenEscrowEnabled: UnReserve amount exceeds reservable balance."
        );

        defaultBalances[addr].reservedBalance -= amount;
        emit UnReserve(addr, amount, address(0));
    }

    /**
    System can move balance from A's reserved  to B's pending.
    This happens when a bid is completed.
    add emit?
     */
    function transferPendingBalance(
        address from,
        address to,
        uint256 amount,
        address tokenAddr
    ) external onlySystem {
        require(
            amount <= balances[from][tokenAddr].reservedBalance,
            "MultipleTokenEscrowEnabled: Transfer amount exceeds reservable balance."
        );
        balances[from][tokenAddr].reservedBalance -= amount;
        balances[from][tokenAddr].totalBalance -= amount;
        balances[to][tokenAddr].pendingBalance += amount;

        emit TransferToPending(from, to, amount, tokenAddr);
    }

    /**
    default pending transfer.
     */
    function transferDefaultPendingBalance(
        address from,
        address to,
        uint256 amount
    ) external onlySystem {
        require(
            amount <= defaultBalances[from].reservedBalance,
            "MultipleTokenEscrowEnabled: Transfer amount exceeds reservable balance."
        );
        defaultBalances[from].reservedBalance -= amount;
        defaultBalances[from].totalBalance -= amount;
        defaultBalances[to].pendingBalance += amount;
        emit TransferToPending(from, to, amount, address(0));
    }

    /**
    Pending balance can moved to totalBalance by admin and approved.
     */
    function approvePendingBalance(
        address addr,
        uint256 amount,
        address tokenAddr
    ) external onlyAdmin {
        require(
            amount <= balances[addr][tokenAddr].pendingBalance,
            "MultipleTokenEscrowEnabled: Approval amount exceeds pending balance."
        );
        balances[addr][tokenAddr].pendingBalance -= amount;
        balances[addr][tokenAddr].totalBalance += amount;
        emit PendingApproved(addr, amount, tokenAddr);
    }

    /**
    @dev
    Pending balance can moved to totalBalance by System.
    Requires `updateLimits` modifier.
    If system can move the amount(totalLimit - usedLimit) of the ERC20 token, 
    the usedLimit goes up.
     */
    function approvePendingBalanceBySystem(
        address addr,
        uint256 amount,
        address tokenAddr
    ) external onlySystem updateLimits(tokenAddr) {
        require(
            amount <= balances[addr][tokenAddr].pendingBalance,
            "MultipleTokenEscrowEnabled: Approval amount exceeds pending balance."
        );
        require(
            amount <=
                limits[tokenAddr].totalLimit - limits[tokenAddr].usedLimit,
            "MultipleTokenEscrowEnabled: Approval amount exceed total limit."
        );
        limits[tokenAddr].usedLimit += amount;
        balances[addr][tokenAddr].pendingBalance -= amount;
        balances[addr][tokenAddr].totalBalance += amount;
        emit PendingApproved(addr, amount, tokenAddr);
    }

    /**
    @dev approveDefaultPendingBalance - Native currency
    **/
    function approveDefaultPendingBalance(address addr, uint256 amount)
        external
        onlyAdmin
    {
        require(
            amount <= defaultBalances[addr].pendingBalance,
            "MultipleTokenEscrowEnabled: Approval amount exceeds pending balance."
        );
        defaultBalances[addr].pendingBalance -= amount;
        defaultBalances[addr].totalBalance += amount;
        emit PendingApproved(addr, amount, address(0));
    }

    /**
    @dev approveDefaultPendingBalanceBySystem - Native currency
    **/
    function approveDefaultPendingBalanceBySystem(address addr, uint256 amount)
        external
        onlySystem
        updateLimits(address(0))
    {
        require(
            amount <= defaultBalances[addr].pendingBalance,
            "MultipleTokenEscrowEnabled: Approval amount exceeds pending balance."
        );
        require(
            amount <=
                limits[address(0)].totalLimit - limits[address(0)].usedLimit,
            "MultipleTokenEscrowEnabled: Approval amount exceed total limit."
        );

        limits[address(0)].usedLimit += amount;
        defaultBalances[addr].pendingBalance -= amount;
        defaultBalances[addr].totalBalance += amount;
        emit PendingApproved(addr, amount, address(0));
    }

    /**
    @notice Transfer funds to owner on auction end.
    The admin can transfer funds to treasury or owner from any reservedBalance.
     */
    function transferToOwner(
        address addr,
        uint256 amount,
        address tokenAddr
    ) external onlyAdmin {
        require(
            amount <= balances[addr][tokenAddr].reservedBalance,
            "MultipleTokenEscrowEnabled: Transfer amount exceeds reserved balance."
        );

        balances[addr][tokenAddr].totalBalance -= amount;
        balances[addr][tokenAddr].reservedBalance -= amount;

        balances[owner()][tokenAddr].totalBalance += amount;

        emit Transfer(addr, owner(), amount, tokenAddr);
    }

    /**
    @dev native currency
    The admin can transfer funds to treasury or owner from any reservedBalance.
    */
    function transferToOwnerDefault(address addr, uint256 amount)
        external
        onlyAdmin
    {
        require(
            amount <= defaultBalances[addr].reservedBalance,
            "MultipleTokenEscrowEnabled: Transfer amount exceeds reserved balance."
        );

        defaultBalances[addr].totalBalance -= amount;
        defaultBalances[addr].reservedBalance -= amount;

        defaultBalances[owner()].totalBalance += amount;

        emit Transfer(addr, owner(), amount, address(0));
    }

    /**
    @notice Withdraw funds from contract to owner.
     */
    function exit(uint256 amount, address tokenAddr) external onlyOwner {
        require(
            amount <= balances[owner()][tokenAddr].totalBalance,
            "Cannot exit, amount exceeds than total balance."
        );

        balances[owner()][tokenAddr].totalBalance -= amount;

        IERC20(tokenAddr).transfer(_msgSender(), amount);
        emit Withdraw(owner(), amount, tokenAddr);
    }

    /**
    @notice Withdraw funds from contract to owner.
     */
    function exitDefault(uint256 amount) external onlyOwner {
        require(
            amount <= defaultBalances[owner()].totalBalance,
            "Cannot exit, amount exceeds than total balance."
        );

        defaultBalances[owner()].totalBalance -= amount;

        address payable addr = payable(owner());
        addr.transfer(amount);
        // ERC20(tokenAddr).transfer(_msgSender(), amount);
        emit Withdraw(owner(), amount, address(0));
    }

    /**
    Allow users to withdraw from totalBalance - reservedBalance
     */
    function withdraw(uint256 amount, address tokenAddr) external nonReentrant {
        require(
            amount <=
                balances[_msgSender()][tokenAddr].totalBalance -
                    balances[_msgSender()][tokenAddr].reservedBalance,
            "MultipleTokenEscrowEnabled: Withdraw amount exceeds (total-reserved) balance."
        );

        balances[_msgSender()][tokenAddr].totalBalance -= amount;

        IERC20(tokenAddr).transfer(_msgSender(), amount);

        emit Withdraw(_msgSender(), amount, tokenAddr);
    }

    function withdrawDefault(uint256 amount) external nonReentrant {
        require(
            amount <=
                defaultBalances[_msgSender()].totalBalance -
                    defaultBalances[_msgSender()].reservedBalance,
            "MultipleTokenEscrowEnabled: Withdraw amount exceeds (total-reserved) balance."
        );

        defaultBalances[_msgSender()].totalBalance -= amount;

        address payable sender = payable(_msgSender());
        sender.transfer(amount);

        emit Withdraw(_msgSender(), amount, address(0));
    }

    function setupRoles(address _owner) internal {
        admins[_owner] = true;
        systems[_owner] = true;
    }
}

{
  "optimizer": {
    "enabled": false,
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