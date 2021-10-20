/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity ^0.8.0;

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



pragma solidity ^0.8.0;




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


// File @openzeppelin/contracts/utils/structs/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;



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


// File contracts/token/interface/IHC.sol


pragma solidity >=0.8.7;

/**
 * @title HC Interface
 * @author HASHLAND-TEAM
 * @notice Interface of the HC
 */
interface IHC is IERC20 {
    function harvestToken() external returns (uint256);

    function getTokenRewards(address poolAddr) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/token/interface/IHN.sol


pragma solidity >=0.8.7;

/**
 * @title HN Interface
 * @author HASHLAND-TEAM
 * @notice Interface of the HN
 */
abstract contract IHN is IERC721Enumerable {
    mapping(uint256 => string) public name;
    mapping(uint256 => uint256) public ip;
    mapping(uint256 => uint256) public series;
    mapping(uint256 => uint256) public level;
    mapping(uint256 => uint256) public spawntime;
    mapping(uint256 => uint256[]) public hashrates;

    mapping(uint256 => mapping(string => uint256)) public data;
    mapping(uint256 => mapping(string => uint256[])) public datas;

    function spawnHn(
        address to,
        uint256 _ip,
        uint256 _series,
        uint256 _level,
        uint256[] calldata _hashrates
    ) external virtual returns (uint256);

    function setLevel(uint256 hnId, uint256 _level) external virtual;

    function setHashrates(uint256 hnId, uint256[] calldata _hashrates)
        external
        virtual;

    function setData(
        uint256 hnId,
        string calldata slot,
        uint256 _data
    ) external virtual;

    function setDatas(
        uint256 hnId,
        string calldata slot,
        uint256[] calldata _datas
    ) external virtual;

    function renameHn(uint256 hnId, string calldata _name) external virtual;

    function safeTransferFromBatch(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external virtual;

    function getHashrates(uint256 hnId)
        external
        view
        virtual
        returns (uint256[] memory);

    function getDatas(uint256 hnId, string calldata slot)
        external
        view
        virtual
        returns (uint256[] memory);

    function tokensOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view virtual returns (uint256[] memory, uint256);

    function getRandomNumber(
        uint256 hnId,
        string calldata slot,
        uint256 base,
        uint256 range
    ) external pure virtual returns (uint256);
}


// File contracts/pool/interface/IInvitePool.sol


pragma solidity >=0.8.7;

/**
 * @title Invite Pool Interface
 * @author HASHLAND-TEAM
 * @notice Interface of the Invite Pool
 */
interface IInvitePool {
    function depositInviter(address user, uint256 hashrate) external;

    function withdrawInviter(address user, uint256 hashrate) external;
}


// File contracts/pool/interface/IHNMarket.sol


pragma solidity >=0.8.7;

/**
 * @title HN Market Interface
 * @author HASHLAND-TEAM
 * @notice Interface of the HN Market
 */
interface IHNMarket {
    function hnPoolCancel(address seller, uint256[] calldata _hnIds) external;
}


// File contracts/pool/HNPool.sol


pragma solidity >=0.8.9;








/**
 * @title HN Pool Contract
 * @author HASHLAND-TEAM
 * @notice In this Contract users can stake HN to harvest HC and Tokens
 */
contract HNPool is ERC721Holder, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    IHN public hn;
    IInvitePool public invitePool;
    IHNMarket public hnMarket;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    bool public openStatus = false;
    uint256 public maxSlots = 6;
    uint256 public slotBasePrice = 4;
    uint256 public lastRewardBlock;
    address public receivingAddress;
    address public hnMarketAddress;

    address[] public tokenAddrs;
    uint256[] public tokensPerBlock = [0, 10416666666666];

    mapping(uint256 => uint256) public stakes;
    mapping(uint256 => uint256) public accTokensPerStake;
    mapping(uint256 => uint256) public releasedTokens;
    mapping(uint256 => uint256) public harvestedTokens;

    mapping(uint256 => uint256) public airdropedTokens;
    mapping(uint256 => uint256) public lastAirdropedTokens;
    mapping(uint256 => uint256) public lastAirdropTimes;

    mapping(address => uint256) public userSlots;
    mapping(address => mapping(uint256 => uint256)) public userStakes;
    mapping(address => mapping(uint256 => uint256))
        public userLastAccTokensPerStake;
    mapping(address => mapping(uint256 => uint256)) public userStoredTokens;
    mapping(address => mapping(uint256 => uint256)) public userHarvestedTokens;

    EnumerableSet.UintSet private hnIds;
    EnumerableSet.AddressSet private users;
    mapping(address => EnumerableSet.UintSet) private userHnIds;

    event Deposit(address indexed user, uint256[] hnIds);
    event Withdraw(address indexed user, uint256[] hnIds);
    event HNMarketWithdraw(
        address indexed buyer,
        address indexed seller,
        uint256 hnId
    );
    event HarvestTokens(
        address indexed user,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event BuySlot(address indexed user, uint256 amount);

    /**
     * @param hnAddr Initialize HN Address
     * @param _tokenAddrs Initialize Tokens Address
     * @param receivingAddr Initialize Receiving Address
     * @param manager Initialize Manager Role
     */
    constructor(
        address hnAddr,
        address[] memory _tokenAddrs,
        address receivingAddr,
        address manager
    ) {
        hn = IHN(hnAddr);
        tokenAddrs = _tokenAddrs;

        receivingAddress = receivingAddr;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, manager);
    }

    /**
     * @dev Set Tokens Info
     */
    function setTokensInfo(
        address[] calldata _tokenAddrs,
        uint256[] calldata _tokensPerBlock
    ) external onlyRole(MANAGER_ROLE) {
        require(
            _tokenAddrs.length == _tokensPerBlock.length,
            "Tokens info length mismatch"
        );
        tokenAddrs = _tokenAddrs;
        tokensPerBlock = _tokensPerBlock;
    }

    /**
     * @dev Set Open Status
     */
    function setOpenStatus(bool status) external onlyRole(MANAGER_ROLE) {
        openStatus = status;
    }

    /**
     * @dev Set Max Slots
     */
    function setMaxSlots(uint256 slots) external onlyRole(MANAGER_ROLE) {
        maxSlots = slots;
    }

    /**
     * @dev Set Slot Base Price
     */
    function setSlotBasePrice(uint256 price) external onlyRole(MANAGER_ROLE) {
        slotBasePrice = price;
    }

    /**
     * @dev Set Receiving Address
     */
    function setReceivingAddress(address receivingAddr)
        external
        onlyRole(MANAGER_ROLE)
    {
        receivingAddress = receivingAddr;
    }

    /**
     * @dev Set Invite Pool Address
     */
    function setInvitePoolAddress(address invitePoolAddr)
        external
        onlyRole(MANAGER_ROLE)
    {
        invitePool = IInvitePool(invitePoolAddr);
    }

    /**
     * @dev Set HN Market Address
     */
    function setHNMarketAddress(address hnMarketAddr)
        external
        onlyRole(MANAGER_ROLE)
    {
        hnMarket = IHNMarket(hnMarketAddr);
    }

    /**
     * @dev Withdraw Token
     */
    function withdrawToken(
        address _tokenAddrs,
        address to,
        uint256 amount
    ) external onlyRole(MANAGER_ROLE) {
        IERC20 token = IERC20(_tokenAddrs);
        token.transfer(to, amount);
    }

    /**
     * @dev Withdraw NFT
     */
    function withdrawNFT(
        address nftAddr,
        address to,
        uint256 tokenId
    ) external onlyRole(MANAGER_ROLE) {
        IERC721Enumerable nft = IERC721Enumerable(nftAddr);
        nft.safeTransferFrom(address(this), to, tokenId);
    }

    /**
     * @dev Airdrop Tokens
     */
    function airdropTokens(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata releaseBlocks
    ) external onlyRole(MANAGER_ROLE) {
        require(
            tokenIds.length == amounts.length &&
                tokenIds.length == releaseBlocks.length,
            "Tokens data length mismatch"
        );

        updatePool();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "Token id must > 0");
            require(releaseBlocks[i] > 0, "Release seconds must > 0");

            IERC20 token = IERC20(tokenAddrs[tokenIds[i]]);
            token.transferFrom(msg.sender, address(this), amounts[i]);
            tokensPerBlock[tokenIds[i]] = amounts[i] / releaseBlocks[i];

            airdropedTokens[tokenIds[i]] += amounts[i];
            lastAirdropedTokens[tokenIds[i]] = amounts[i];
            lastAirdropTimes[tokenIds[i]] = block.timestamp;
        }
    }

    /**
     * @dev Deposit
     */
    function deposit(uint256[] calldata _hnIds) external {
        require(openStatus, "This pool is not opened");
        require(
            _hnIds.length <= getUserLeftSlots(msg.sender),
            "Not enough slots"
        );

        updatePool();
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (userStakes[msg.sender][i] > 0) {
                uint256 pendingToken = (userStakes[msg.sender][i] *
                    (accTokensPerStake[i] -
                        userLastAccTokensPerStake[msg.sender][i])) / 1e18;
                if (pendingToken > 0) {
                    userStoredTokens[msg.sender][i] += pendingToken;
                }
            }
        }

        uint256 hcHashrate;
        for (uint256 i = 0; i < _hnIds.length; i++) {
            hn.safeTransferFrom(msg.sender, address(this), _hnIds[i]);
            uint256[] memory hashrates = hn.getHashrates(_hnIds[i]);
            for (uint256 j = 0; j < hashrates.length; j++) {
                if (hashrates[j] > 0) {
                    userStakes[msg.sender][j] += hashrates[j];
                    stakes[j] += hashrates[j];
                }
            }
            hnIds.add(_hnIds[i]);
            userHnIds[msg.sender].add(_hnIds[i]);
            if (hashrates[0] > 0) hcHashrate += hashrates[0];
        }

        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (userStakes[msg.sender][i] > 0) {
                userLastAccTokensPerStake[msg.sender][i] = accTokensPerStake[i];
            }
        }
        users.add(msg.sender);

        invitePool.depositInviter(msg.sender, hcHashrate);

        emit Deposit(msg.sender, _hnIds);
    }

    /**
     * @dev Withdraw
     */
    function withdraw(uint256[] calldata _hnIds) external {
        updatePool();
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (userStakes[msg.sender][i] > 0) {
                uint256 pendingToken = (userStakes[msg.sender][i] *
                    (accTokensPerStake[i] -
                        userLastAccTokensPerStake[msg.sender][i])) / 1e18;
                if (pendingToken > 0) {
                    userStoredTokens[msg.sender][i] += pendingToken;
                }
            }
        }

        uint256 hcHashrate;
        for (uint256 i = 0; i < _hnIds.length; i++) {
            require(hnIds.contains(_hnIds[i]), "This HN does not exist");
            require(
                userHnIds[msg.sender].contains(_hnIds[i]),
                "This HN is not own"
            );

            uint256[] memory hashrates = hn.getHashrates(_hnIds[i]);
            for (uint256 j = 0; j < hashrates.length; j++) {
                if (hashrates[j] > 0) {
                    userStakes[msg.sender][j] -= hashrates[j];
                    stakes[j] -= hashrates[j];
                }
            }
            hnIds.remove(_hnIds[i]);
            userHnIds[msg.sender].remove(_hnIds[i]);
            if (hashrates[0] > 0) hcHashrate += hashrates[0];
            hn.safeTransferFrom(address(this), msg.sender, _hnIds[i]);
        }

        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (userStakes[msg.sender][i] > 0) {
                userLastAccTokensPerStake[msg.sender][i] = accTokensPerStake[i];
            }
        }

        invitePool.withdrawInviter(msg.sender, hcHashrate);
        hnMarket.hnPoolCancel(msg.sender, _hnIds);

        emit Withdraw(msg.sender, _hnIds);
    }

    /**
     * @dev HN Market Withdraw
     */
    function hnMarketWithdraw(
        address buyer,
        address seller,
        uint256 hnId
    ) external {
        require(
            msg.sender == address(hnMarket),
            "Only HN Market contract can call"
        );

        updatePool();
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (userStakes[seller][i] > 0) {
                uint256 pendingToken = (userStakes[seller][i] *
                    (accTokensPerStake[i] -
                        userLastAccTokensPerStake[seller][i])) / 1e18;
                if (pendingToken > 0) {
                    userStoredTokens[seller][i] += pendingToken;
                }
            }
        }

        uint256 hcHashrate;
        require(hnIds.contains(hnId), "This HN does not exist");
        require(userHnIds[seller].contains(hnId), "This HN is not own");

        uint256[] memory hashrates = hn.getHashrates(hnId);
        for (uint256 j = 0; j < hashrates.length; j++) {
            if (hashrates[j] > 0) {
                userStakes[seller][j] -= hashrates[j];
                stakes[j] -= hashrates[j];
            }
        }
        hnIds.remove(hnId);
        userHnIds[seller].remove(hnId);
        if (hashrates[0] > 0) hcHashrate = hashrates[0];
        hn.safeTransferFrom(address(this), buyer, hnId);

        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (userStakes[seller][i] > 0) {
                userLastAccTokensPerStake[seller][i] = accTokensPerStake[i];
            }
        }

        invitePool.withdrawInviter(seller, hcHashrate);
        uint256[] memory _hnId = new uint256[](1);
        _hnId[0] = hnId;
        hnMarket.hnPoolCancel(seller, _hnId);

        emit HNMarketWithdraw(buyer, seller, hnId);
    }

    /**
     * @dev Harvest Tokens
     */
    function harvestTokens(uint256[] calldata tokenIds) external {
        updatePool();

        uint256[] memory amounts = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 pendingToken = (userStakes[msg.sender][tokenIds[i]] *
                (accTokensPerStake[tokenIds[i]] -
                    userLastAccTokensPerStake[msg.sender][tokenIds[i]])) / 1e18;
            amounts[i] =
                userStoredTokens[msg.sender][tokenIds[i]] +
                pendingToken;

            if (amounts[i] > 0) {
                userStoredTokens[msg.sender][tokenIds[i]] = 0;
                userLastAccTokensPerStake[msg.sender][
                    tokenIds[i]
                ] = accTokensPerStake[tokenIds[i]];
                userHarvestedTokens[msg.sender][tokenIds[i]] += amounts[i];
                harvestedTokens[tokenIds[i]] += amounts[i];

                IERC20 token = IERC20(tokenAddrs[tokenIds[i]]);
                token.transfer(msg.sender, amounts[i]);
            }
        }

        emit HarvestTokens(msg.sender, tokenIds, amounts);
    }

    /**
     * @dev Buy Slot
     */
    function buySlot() external {
        require(
            getUserSlots(msg.sender) < maxSlots,
            "Slots has reached the limit"
        );

        uint256 amount = getUserSlotPrice(msg.sender);
        IHC hc = IHC(tokenAddrs[0]);
        hc.transferFrom(msg.sender, receivingAddress, amount);
        userSlots[msg.sender]++;

        emit BuySlot(msg.sender, amount);
    }

    /**
     * @dev Get Token Total Rewards of a User
     */
    function getTokenTotalRewards(address user, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return
            userHarvestedTokens[user][tokenId] + getTokenRewards(user, tokenId);
    }

    /**
     * @dev Get Tokens Info
     */
    function getTokensInfo()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        return (tokenAddrs, tokensPerBlock);
    }

    /**
     * @dev Get HnIds Length
     */
    function getHnIdsLength() external view returns (uint256) {
        return hnIds.length();
    }

    /**
     * @dev Get HnIds by Size
     */
    function getHnIdsBySize(uint256 cursor, uint256 size)
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256 length = size;
        if (length > hnIds.length() - cursor) {
            length = hnIds.length() - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = hnIds.at(cursor + i);
        }

        return (values, cursor + length);
    }

    /**
     * @dev Get Users Length
     */
    function getUsersLength() external view returns (uint256) {
        return users.length();
    }

    /**
     * @dev Get Users by Size
     */
    function getUsersBySize(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256)
    {
        uint256 length = size;
        if (length > users.length() - cursor) {
            length = users.length() - cursor;
        }

        address[] memory values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = users.at(cursor + i);
        }

        return (values, cursor + length);
    }

    /**
     * @dev Get User HnId Existence
     */
    function getUserHnIdExistence(address user, uint256 hnId)
        external
        view
        returns (bool)
    {
        return userHnIds[user].contains(hnId);
    }

    /**
     * @dev Get User HnIds Length
     */
    function getUserHnIdsLength(address user) external view returns (uint256) {
        return userHnIds[user].length();
    }

    /**
     * @dev Get User HnIds by Size
     */
    function getUserHnIdsBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userHnIds[user].length() - cursor) {
            length = userHnIds[user].length() - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userHnIds[user].at(cursor + i);
        }

        return (values, cursor + length);
    }

    /**
     * @dev Update Pool
     */
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (i == 0) {
                if (stakes[i] > 0) {
                    IHC hc = IHC(tokenAddrs[i]);
                    uint256 amount = hc.harvestToken();
                    accTokensPerStake[i] += (amount * 1e18) / stakes[i];
                    releasedTokens[i] += amount;
                }
            } else {
                if (block.number > lastRewardBlock && stakes[i] > 0) {
                    uint256 amount = tokensPerBlock[i] *
                        (block.number - lastRewardBlock);
                    accTokensPerStake[i] += (amount * 1e18) / stakes[i];
                    releasedTokens[i] += amount;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    /**
     * @dev Get Token Rewards of a User
     */
    function getTokenRewards(address user, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 accTokenPerStakeTemp = accTokensPerStake[tokenId];
        if (tokenId == 0) {
            if (stakes[tokenId] > 0) {
                IHC hc = IHC(tokenAddrs[0]);
                accTokenPerStakeTemp +=
                    (hc.getTokenRewards(address(this)) * 1e18) /
                    stakes[tokenId];
            }
        } else {
            if (block.number > lastRewardBlock && stakes[tokenId] > 0) {
                accTokenPerStakeTemp +=
                    (tokensPerBlock[tokenId] *
                        (block.number - lastRewardBlock) *
                        1e18) /
                    stakes[tokenId];
            }
        }

        return
            userStoredTokens[user][tokenId] +
            ((userStakes[user][tokenId] *
                (accTokenPerStakeTemp -
                    userLastAccTokensPerStake[user][tokenId])) / 1e18);
    }

    /**
     * @dev Get User Slots
     */
    function getUserSlots(address user) public view returns (uint256) {
        return 2 + userSlots[user];
    }

    /**
     * @dev Get User Left Slots
     */
    function getUserLeftSlots(address user) public view returns (uint256) {
        return getUserSlots(user) - userHnIds[user].length();
    }

    /**
     * @dev Get User Slot Price
     */
    function getUserSlotPrice(address user) public view returns (uint256) {
        return slotBasePrice**(getUserSlots(user) - 1) * 1e18;
    }
}