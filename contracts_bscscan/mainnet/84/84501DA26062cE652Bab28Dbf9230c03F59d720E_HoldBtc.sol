/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


pragma solidity ^0.8.0;

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


pragma solidity ^0.8.0;




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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: @openzeppelin/contracts/access/AccessControlEnumerable.sol


pragma solidity ^0.8.0;



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

// File: contracts/pancakeswap/IPancakeFactory.sol

pragma solidity 0.8.4;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/pancakeswap/IPancakeERC20.sol

pragma solidity 0.8.4;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts/pancakeswap/IPancakePair.sol

pragma solidity 0.8.4;


interface IPancakePair is IPancakeERC20 {
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/pancakeswap/IPancakeRouter01.sol

pragma solidity 0.8.4;

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/pancakeswap/IPancakeRouter02.sol

pragma solidity 0.8.4;


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/dividends/IDividendPayingToken.sol

pragma solidity 0.8.4;

interface IDividendPayingToken {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeRewardDividends(uint256 amount) external;
  function withdrawDividend() external;

  event DividendsDistributed(address indexed from, uint256 weiAmount);
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// File: contracts/dividends/IDividendPayingTokenOptional.sol

pragma solidity 0.8.4;

interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/pancakeswap/ERC20.sol


pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/dividends/DividendPayingToken.sol

pragma solidity 0.8.4;





contract DividendPayingToken is
  Ownable,
  IDividendPayingToken,
  IDividendPayingTokenOptional,
  ERC20
{
  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;

  address public immutable _dividendToken;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(
    string memory _name,
    string memory _symbol,
    address dividendToken_
  ) ERC20(_name, _symbol) {
    _dividendToken = dividendToken_;
  }

  function decimals() public pure override returns(uint8) {
    return 9;
  }

  function distributeRewardDividends(uint256 amount)
    external
    override
    onlyOwner
  {
    require(totalSupply() > 0);

    if(amount > 0) {
      magnifiedDividendPerShare += (amount * magnitude) / totalSupply();
      totalDividendsDistributed += amount;

      emit DividendsDistributed(msg.sender, amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend()
    public
    virtual
    override
  {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user)
    internal
    returns(uint256)
  {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);

    if(_withdrawableDividend > 0) {
      withdrawnDividends[user] += _withdrawableDividend;

      bool success = IERC20(_dividendToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] -= _withdrawableDividend;
        return 0;
      }

      emit DividendWithdrawn(user, _withdrawableDividend);
      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner)
    public
    view
    override
    returns(uint256)
  {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner)
    public
    view
    override
    returns(uint256)
  {
    return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner)
    public
    view
    override
    returns(uint256)
  {
    return withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner)
    public
    view
    override
    returns(uint256)
  {
    int256 accumulativeDividends = int256(magnifiedDividendPerShare * balanceOf(_owner));
    accumulativeDividends += magnifiedDividendCorrections[_owner];

    return uint256(accumulativeDividends) / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value)
    internal
    virtual
    override
  {
    int256 _magCorrection = int256(magnifiedDividendPerShare * value);

    magnifiedDividendCorrections[from] += _magCorrection;
    magnifiedDividendCorrections[to] -= _magCorrection;
  }

  function _distributeDividendTokens(address account, uint256 value) internal {
    require(account != address(0), 'ZERO_ADDRESS');

    _beforeTokenTransfer(address(0), account, value);

    _totalSupply += value;
    _balances[account] += value;
    emit Transfer(address(0), account, value);

    _afterTokenTransfer(address(0), account, value);

    magnifiedDividendCorrections[account] -= int256(magnifiedDividendPerShare * value);
  }

  function _destroyDividendTokens(address account, uint256 value) internal {
    require(account != address(0), 'ZERO_ADDRESS');

    _beforeTokenTransfer(account, address(0), value);

    uint256 accountBalance = _balances[account];

    require(accountBalance >= value, 'Destroy amount exceeds balance');

    unchecked {
      _balances[account] = accountBalance - value;
    }

    _totalSupply -= value;

    emit Transfer(account, address(0), value);

    _afterTokenTransfer(account, address(0), value);

    magnifiedDividendCorrections[account] += int256(magnifiedDividendPerShare * value);
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 rewardAmount = newBalance - currentBalance;
      _distributeDividendTokens(account, rewardAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _destroyDividendTokens(account, burnAmount);
    }
  }

  receive() external payable {}
}

// File: contracts/dividends/DividendTracker.sol

pragma solidity 0.8.4;


library IterableMapping {
  // iterable mapping from address to uint;
  struct Map {
    address[] keys;
    mapping(address => uint) values;
    mapping(address => uint) indexOf;
    mapping(address => bool) inserted;
  }

  function get(Map storage map, address key)
    internal
    view
    returns(uint)
  {
    return map.values[key];
  }

  function getIndexOfKey(Map storage map, address key)
    internal
    view
    returns(int)
  {
    if(!map.inserted[key]) {
      return -1;
    }

    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(Map storage map, uint index)
    internal
    view
    returns(address)
  {
    return map.keys[index];
  }

  function size(Map storage map)
    internal
    view
    returns(uint)
  {
    return map.keys.length;
  }

  function set(Map storage map, address key, uint val) internal {
    if(map.inserted[key]) {
      map.values[key] = val;
    } else {
      map.inserted[key] = true;
      map.values[key] = val;
      map.indexOf[key] = map.keys.length;
      map.keys.push(key);
    }
  }

  function remove(Map storage map, address key) internal {
    if(!map.inserted[key]) {
      return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }
}

contract DividendTracker is DividendPayingToken {
  using IterableMapping for IterableMapping.Map;

  IterableMapping.Map private tokenHoldersMap;
  uint256 public lastProcessedIndex;

  mapping(address => bool) public excludedFromDividends;
  mapping(address => uint256) public lastClaimTimes;

  uint256 public claimWait;
  uint256 public immutable minimumTokenBalanceForDividends;

  event ExcludeFromDividends(address indexed account);

  event ClaimWaitUpdated(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );

  event Claim(
    address indexed account,
    uint256 amount,
    bool indexed automatic
  );

  constructor(
    string memory name_,
    string memory symbol_,
    address dividendTokenAddress_,
    uint256 claimWait_
  ) DividendPayingToken(
    string(abi.encodePacked(name_, ': Dividend Tracker')),
    string(abi.encodePacked(symbol_, '_DIVIDEND_TRACKER')),

    dividendTokenAddress_
  ) {
    claimWait = claimWait_;
    minimumTokenBalanceForDividends = 1_000_000_000 * 10**9; // must hold 1 billion tokens which equates to 0.0001% of the total HoldBtc supply
  }

  function _transfer(address, address, uint256)
    internal
    pure
    override
  {
    require(false, 'DividendTracker: No transfers allowed');
  }

  function withdrawDividend()
    public
    pure
    override
  {
    require(false, 'DividendTracker: withdrawDividend disabled. Use the \'claim\' function on the main contract.');
  }

  function excludeFromDividends(address account) external onlyOwner {
    require(!excludedFromDividends[account]);
    excludedFromDividends[account] = true;

    _setBalance(account, 0);
    tokenHoldersMap.remove(account);

    emit ExcludeFromDividends(account);
  }

  function updateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(newClaimWait >= 3600 && newClaimWait <= 86400, 'DividendTracker: claimWait must be updated to between 1 and 24 hours');
    require(newClaimWait != claimWait, 'DividendTracker: Cannot update claimWait to same value');

    emit ClaimWaitUpdated(newClaimWait, claimWait);

    claimWait = newClaimWait;
  }

  function getLastProcessedIndex()
    external
    view
    returns(uint256)
  {
    return lastProcessedIndex;
  }

  function getNumberOfTokenHolders()
    external
    view
    returns(uint256)
  {
    return tokenHoldersMap.keys.length;
  }

  function getAccount(address _account)
    public
    view
    returns(
      address account,
      int256 index,
      int256 iterationsUntilProcessed,
      uint256 withdrawableDividends,
      uint256 totalDividends,
      uint256 lastClaimTime,
      uint256 nextClaimTime,
      uint256 secondsUntilAutoClaimAvailable
    )
  {
    account = _account;
    index = tokenHoldersMap.getIndexOfKey(account);
    iterationsUntilProcessed = -1;

    if(index >= 0) {
      if(uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index - int256(lastProcessedIndex);
      } else {
        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
          ? tokenHoldersMap.keys.length - lastProcessedIndex
          : 0;

        iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    totalDividends = accumulativeDividendOf(account);

    lastClaimTime = lastClaimTimes[account];

    nextClaimTime = lastClaimTime > 0
      ? lastClaimTime + claimWait
      : 0;

    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
      ? nextClaimTime - block.timestamp
      : 0;
  }

  function getAccountAtIndex(uint256 index)
    public
    view
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    if(index >= tokenHoldersMap.size()) {
      return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    }

    address account = tokenHoldersMap.getKeyAtIndex(index);

    return getAccount(account);
  }

  function canAutoClaim(uint256 lastClaimTime)
    private
    view
    returns(bool)
  {
    if(lastClaimTime > block.timestamp) {
      return false;
    }

    return (block.timestamp - lastClaimTime) >= claimWait;
  }

  function setBalance(address payable account, uint256 newBalance)
    external
    onlyOwner
  {
    if(excludedFromDividends[account]) {
      return;
    }

    if(newBalance >= minimumTokenBalanceForDividends) {
      _setBalance(account, newBalance);
      tokenHoldersMap.set(account, newBalance);
    } else {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    }

    processAccount(account, true);
  }

  function process(uint256 gas)
    public
    returns(
      uint256,
      uint256,
      uint256
    )
  {
    uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    if(numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }

    uint256 _lastProcessedIndex = lastProcessedIndex;

    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();

    uint256 iterations = 0;
    uint256 claims = 0;

    while(gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex += 1;

      if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }

      address account = tokenHoldersMap.keys[_lastProcessedIndex];

      if(canAutoClaim(lastClaimTimes[account])) {
        if(processAccount(payable(account), true)) {
          claims += 1;
        }
      }

      iterations += 1;

      uint256 newGasLeft = gasleft();

      if(gasLeft > newGasLeft) {
        gasUsed += (gasLeft - newGasLeft);
      }

      gasLeft = newGasLeft;
    }

    lastProcessedIndex = _lastProcessedIndex;

    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(address payable account, bool automatic)
    public
    onlyOwner
    returns(bool)
  {
    uint256 amount = _withdrawDividendOfUser(account);

    if(amount > 0) {
      lastClaimTimes[account] = block.timestamp;
      emit Claim(account, amount, automatic);
      return true;
    }

    return false;
  }
}

// File: contracts/IHoldBtc.sol

pragma solidity 0.8.4;






interface IHoldBtc is IERC20, IERC20Metadata {
  event UpdateDividendTracker(
    address indexed newAddress,
    address indexed oldAddress
  );

  event UpdateUniswapV2Router(
    address indexed newAddress,
    address indexed oldAddress
  );

  event ExcludeFromFees(
    address indexed account,
    bool isExcluded
  );

  event ExcludeMultipleAccountsFromFees(
    address[] accounts,
    bool isExcluded
  );

  event SetAutomatedMarketMakerPair(
    address indexed pair,
    bool indexed value
  );

  event LiquidityWalletUpdated(
    address indexed newLiquidityWallet,
    address indexed oldLiquidityWallet
  );

  event GasForProcessingUpdated(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);

  event SwapAndLiquify(
    uint256 half,
    uint256 newBalance,
    uint256 otherHalf
  );

  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  event SniperCaught(address sniperAddress);

  event SendDividends(
    uint256 tokensSwapped,
    uint256 amount
  );

  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns(bool);

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns(bool);

  function isSniper(address account) external view returns(bool);

  // There is no way to add to the blacklist except through the initial sniper check.
  // But this can remove from the blacklist if someone human somehow made it onto the list.
  function removeSniper(address account) external;
  function setSniperProtectionEnabled(bool enabled) external;

  // Adjusted to allow for smaller than 1%'s, as low as 0.1%
  function setMaxTxPercent(uint256 _maxTxPercent) external;
  function maxTxAmountUI() external view returns(uint256);
  function setMaxWalletPercent(uint256 maxWalletPercent_) external;
  function maxWalletUI() external view returns(uint256);
  function setSwapAndLiquifyEnabled(bool _enabled) external;
  function excludeFromDividends(address exclude) external;
  function excludeFromFee(address account) external;
  function includeInFee(address account) external;
  function excludeFromMaxWallet(address account) external;
  function includeInMaxWallet(address account) external;
  function excludeFromMaxTx(address account) external;
  function includeInMaxTx(address account) external;

  function setDxSaleAddress(address dxRouter, address presaleRouter) external;
  function setAutomatedMarketMakerPair(address pair, bool value) external;

  function updateClaimWait(uint256 claimWait) external;

  function getClaimWait() external view returns(uint256);

  function getTotalDividendsDistributed() external view returns(uint256);
  function withdrawableDividendOf(address account) external view returns(uint256);
  function dividendRewardTokenBalanceOf(address account) external view returns(uint256);

  function getAccountDividendsInfo(address account)
    external
    view
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function getAccountDividendsInfoAtIndex(uint256 index)
    external
    view
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function processDividendTracker(uint256 gas) external;
  function claim() external;
  function getLastProcessedIndex() external view returns(uint256);
  function getNumberOfDividendTokenHolders() external view returns(uint256);

  function isExcludedFromFee(address account) external view returns(bool);
  function isExcludedFromMaxTx(address account) external view returns(bool);
  function isExcludedFromMaxWallet(address account) external view returns(bool);
  function withdrawLockedETH(address recipient) external;

  // withdraw any tokens that are not supposed to be insided this contract.
  function withdrawLockedTokens(address recipient, address _token) external;
  function setMarketingWallet(address payable newWallet) external;
  function setLiquidityWallet(address payable newWallet) external;
  function updateDividendTracker(address newAddress) external;
  function changeFees(uint256 liquidityFee, uint256 marketingFee, uint256 usdtFee)  external;
}

// File: contracts/HoldBtc.sol

pragma solidity 0.8.4;










contract HoldBtc is
  IHoldBtc,
  Context,
  AccessControlEnumerable,
  ReentrancyGuard
{
  using Address for address;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) public automatedMarketMakerPairs;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcludedFromMaxTx;
  mapping(address => bool) private _isExcludedFromMaxWallet;
  mapping(address => bool) private _liquidityHolders;
  mapping(address => bool) private _isSniper;

  uint256 private constant MAX = type(uint256).max;

  uint8 private _decimals = 9;
  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  uint256 public _totalFee;
  uint256 private _previousTotalFee;

  uint256 public _marketingFee;
  uint256 public _liquidityFee;
  uint256 public _dividendRewardsFee;

  uint256 private _withdrawableBalance;

  DividendTracker public dividendTracker;
  address private _dividendRewardToken;
  uint256 public gasForProcessing = 300000;

  IPancakeRouter02 public pancakeswapV2Router;
  address public pancakeswapV2Pair;

  address public burnAddress = 0x000000000000000000000000000000000000dEaD;

  address _marketingWallet;
  address _liquidityWallet;

  bool private swapping;
  bool private setPresaleAddresses = true;
  bool public maxWalletEnabled = true;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 private _maxTxDivisor = 100;
  uint256 private _maxTxAmount;
  uint256 private _previousMaxTxAmount;

  uint256 private _maxWalletDivisor = 100;
  uint256 private _maxWalletAmount;
  uint256 private _perviousMaxWalletAmount;

  uint256 private _numTokensSellToAddToLiquidity;

  bool private _sniperProtection = true;
  bool private _hasLiqBeenAdded = false;
  bool private _tradingEnabled = false;

  uint256 private _liqAddBlock = 0;
  uint256 private _snipeBlockAmount = 2;
  uint256 private _manualSnipeBlock = 2;
  uint256 public snipersCaught = 0;

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 supply_,
    uint256 maxTxPercent_,
    uint256 maxWalletPercent_,
    uint256 liquidityThresholdPercentage_,

    uint256 liquidityFee_,
    uint256 marketingFee_,
    uint256 dividendRewardsFee_,

    address[3] memory addresses_,
    address v2Router_
  ) {
    _name = name_;
    _symbol = symbol_;
    _totalSupply = supply_ * (10**uint256(_decimals));
    _numTokensSellToAddToLiquidity = (_totalSupply * liquidityThresholdPercentage_) / 10000;

    _dividendRewardToken = addresses_[0];
    _marketingWallet = addresses_[1];
    _liquidityWallet = addresses_[2];

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    _setupDividendTracker();

    setMaxTxPercent(maxTxPercent_);
    setMaxWalletPercent(maxWalletPercent_);
    changeFees(liquidityFee_, marketingFee_, dividendRewardsFee_);

    _setupPancakeswap(v2Router_);
    _setupExclusions();

    _balances[_msgSender()] = _totalSupply;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function _setupPancakeswap(address _routerAddress) private {
    pancakeswapV2Router = IPancakeRouter02(_routerAddress);

    // create a pancakeswap pair for this new token
    pancakeswapV2Pair = IPancakeFactory(pancakeswapV2Router.factory())
      .createPair(address(this), pancakeswapV2Router.WETH());

    _setAutomatedMarketMakerPair(pancakeswapV2Pair, true);
  }

  function _setupExclusions() private {
    _isExcludedFromFee[msg.sender] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_marketingWallet] = true;
    _liquidityHolders[msg.sender] = true;
    _isExcludedFromMaxTx[msg.sender] = true;
    _isExcludedFromMaxTx[address(this)] = true;
    _isExcludedFromMaxTx[_marketingWallet] = true;
    _isExcludedFromMaxWallet[msg.sender] = true;
    _isExcludedFromMaxWallet[address(this)] = true;
    _isExcludedFromMaxWallet[pancakeswapV2Pair] = true;
    _isExcludedFromMaxWallet[_marketingWallet] = true;
  }

  function _setupDividendTracker() private {
    dividendTracker = new DividendTracker(
      _name,
      _symbol,
      _dividendRewardToken,
      3600 // 1h claim
    );

    dividendTracker.excludeFromDividends(address(dividendTracker));
    dividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(msg.sender);
    dividendTracker.excludeFromDividends(address(pancakeswapV2Router));
  }

  function name()
    public
    view
    override
    returns(string memory)
  {
    return _name;
  }

  function symbol()
    public
    view
    override
    returns(string memory)
  {
    return _symbol;
  }

  function decimals()
    public
    view
    override
    returns(uint8)
  {
    return _decimals;
  }

  function totalSupply()
    public
    view
    override
    returns(uint256)
  {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    override
    returns(uint256)
  {
    return _balances[account];
  }

  function allowance(
    address owner,
    address spender
  )
    public
    view
    override
    returns(uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  )
    public
    override
    returns(bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transfer(
    address recipient,
    uint256 amount
  )
    public
    override
    returns(bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    public
    override
    returns(bool)
  {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    override
    returns(bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    override
    returns(bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  function isSniper(address account)
    public
    view
    override
    returns(bool)
  {
    return _isSniper[account];
  }

  // There is no way to add to the blacklist except through the initial sniper check.
  // But this can remove from the blacklist if someone human somehow made it onto the list.
  function removeSniper(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_isSniper[account], 'Account is not a recorded sniper.');
    _isSniper[account] = false;
  }

  function setSniperProtectionEnabled(bool enabled)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _sniperProtection = enabled;
  }

  // developers have the option to pinpoint and exclude bots from trading on launch.
  function addBotToList(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(block.number - _liqAddBlock < _manualSnipeBlock);
    _isSniper[account] = true;
  }

  function enableTrading() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _tradingEnabled = true;
  }

  // adjusted to allow for smaller than 1%'s, as low as 0.1%
  function setMaxTxPercent(uint256 maxTxPercent_)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(maxTxPercent_ >= 1); // cannot set to 0.

    // division by 1000, set to 20 for 2%, set to 2 for 0.2%
    _maxTxAmount = (_totalSupply * maxTxPercent_) / 1000;
  }

  function maxTxAmountUI()
    external
    view
    override
    returns(uint256)
  {
    return _maxTxAmount / uint256(_decimals);
  }

  // adjusted to allow for smaller than 1%'s, as low as 0.1%
  function setMaxWalletPercent(uint256 maxWalletPercent_)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(maxWalletPercent_ >= 1); // cannot set to 0.

    // division by 1000, set to 20 for 2%, set to 2 for 0.2%
    _maxWalletAmount = (_totalSupply * maxWalletPercent_) / 1000;
  }

  function maxWalletUI()
    external
    view
    override
    returns(uint256)
  {
    return _maxWalletAmount / uint256(_decimals);
  }

  function setSwapAndLiquifyEnabled(bool _enabled)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function excludeFromDividends(address exclude)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    dividendTracker.excludeFromDividends(address(exclude));
  }

  function excludeFromMaxWallet(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _isExcludedFromMaxWallet[account] = true;
  }

  function includeInMaxWallet(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _isExcludedFromMaxWallet[account] = false;
  }

  function excludeFromMaxTx(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _isExcludedFromMaxTx[account] = true;
  }

  function includeInMaxTx(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _isExcludedFromMaxTx[account] = false;
  }

  function excludeFromFee(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _isExcludedFromFee[account] = false;
  }

  function setDxSaleAddress(address dxRouter, address presaleRouter)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(setPresaleAddresses == true, 'You can only set the presale addresses once!');

    setPresaleAddresses = false;
    _liquidityHolders[dxRouter] = true;
    _isExcludedFromFee[dxRouter] = true;
    _liquidityHolders[presaleRouter] = true;
    _isExcludedFromFee[presaleRouter] = true;
    _isExcludedFromMaxTx[dxRouter] = true;
    _isExcludedFromMaxTx[presaleRouter] = true;
    _isExcludedFromMaxWallet[dxRouter] = true;
    _isExcludedFromMaxWallet[presaleRouter] = true;
  }

  function setAutomatedMarketMakerPair(address pair, bool value)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(
      pair != pancakeswapV2Pair,
      'HoldBtc: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs'
    );

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(
      automatedMarketMakerPairs[pair] != value,
      'HoldBtc: Automated market maker pair is already set to that value'
    );

    automatedMarketMakerPairs[pair] = value;

    if(value) {
      dividendTracker.excludeFromDividends(pair);
    }

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function updateClaimWait(uint256 claimWait)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    dividendTracker.updateClaimWait(claimWait);
  }

  function getClaimWait()
    external
    view
    override
    returns(uint256)
  {
    return dividendTracker.claimWait();
  }

  function getTotalDividendsDistributed()
    external
    view
    override
    returns(uint256)
  {
    return dividendTracker.totalDividendsDistributed();
  }

  function withdrawableDividendOf(address account)
    external
    view
    override
    returns(uint256)
  {
    return dividendTracker.withdrawableDividendOf(account);
  }

  function dividendRewardTokenBalanceOf(address account)
    external
    view
    override
    returns(uint256)
  {
    return dividendTracker.balanceOf(account);
  }

  function getAccountDividendsInfo(address account)
    external
    view
    override
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccount(account);
  }

  function getAccountDividendsInfoAtIndex(uint256 index)
    external
    view
    override
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccountAtIndex(index);
  }

  function processDividendTracker(uint256 gas) external override {
    (
      uint256 iterations,
      uint256 claims,
      uint256 lastProcessedIndex
    ) = dividendTracker.process(gas);

    emit ProcessedDividendTracker(
      iterations,
      claims,
      lastProcessedIndex,
      false,
      gas,
      tx.origin
    );
  }

  function claim() external override {
    dividendTracker.processAccount(payable(msg.sender), false);
  }

  function getLastProcessedIndex()
    external
    view
    override
    returns(uint256)
  {
    return dividendTracker.getLastProcessedIndex();
  }

  function getNumberOfDividendTokenHolders()
    external
    view
    override
    returns(uint256)
  {
    return dividendTracker.getNumberOfTokenHolders();
  }

  function _removeAllFee() private {
    if(_totalFee == 0) {
      return;
    }

    _previousTotalFee = _totalFee;
    _totalFee = 0;
  }

  function _restoreAllFee() private {
    _totalFee = _previousTotalFee;
  }

  function isExcludedFromFee(address account)
    public
    view
    override
    returns(bool)
  {
    return _isExcludedFromFee[account];
  }

  function isExcludedFromMaxTx(address account)
    public
    view
    override
    returns(bool)
  {
    return _isExcludedFromMaxTx[account];
  }

  function isExcludedFromMaxWallet(address account)
    public
    view
    override
    returns(bool)
  {
    return _isExcludedFromMaxWallet[account];
  }

  function checkWalletLimit(address to, uint256 amount)
    internal
    view
  {
    if(maxWalletEnabled) {
      uint256 contractBalanceRecepient = balanceOf(to);

      require(
        contractBalanceRecepient + amount <= _maxWalletAmount || _isExcludedFromMaxWallet[to],
        'Max Wallet Amount Exceeded'
      );
    }
  }

  function checkTxLimit(address from, address to, uint256 amount) internal view {
    if(from == pancakeswapV2Pair) {
      require(amount <= _maxTxAmount || _isExcludedFromMaxTx[to], 'TX Limit Exceeded');
    } else {
      require(amount <= _maxTxAmount || _isExcludedFromMaxTx[from], 'TX Limit Exceeded');
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');

    if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
      require(_tradingEnabled, 'Trading is currently disabled');
    }

    checkWalletLimit(to, amount);
    checkTxLimit(from, to, amount);

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is pancakeswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if(contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    if(
      (contractTokenBalance >= _numTokensSellToAddToLiquidity)
        && !inSwapAndLiquify
        && from != pancakeswapV2Pair
        && swapAndLiquifyEnabled
    ) {
      // set inSwapAndLiquify to true so the contract isnt looping through adding liquididty
      inSwapAndLiquify = true;

      contractTokenBalance = _numTokensSellToAddToLiquidity;
      uint256 swapForLiq = (contractTokenBalance * _liquidityFee) / _totalFee;
      _swapAndLiquify(swapForLiq);

      uint256 swapForDividends = (contractTokenBalance * _dividendRewardsFee) / _totalFee;
      _swapAndSendTokenDividends(swapForDividends);

      uint256 swapForMarketing = contractTokenBalance - swapForDividends - swapForLiq;
      _swapTokensForMarketing(swapForMarketing);

      // dust ETH after executing all swaps
      _withdrawableBalance = address(this).balance;

      inSwapAndLiquify = false;
    }

    // indicates if fee should be deducted from transfer
    bool takeFee = true;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    // transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function _swapAndLiquify(uint256 tokens) private {
    // split the contract balance into halves
    uint256 half = (tokens / 2);
    uint256 otherHalf = tokens - half;

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    _swapTokensForETH(half);

    // get the delta balance from the swap
    uint256 deltaBalance = (address(this).balance - initialBalance);

    // add liquidity to pancakeswap
    _addLiquidity(otherHalf, deltaBalance);

    emit SwapAndLiquify(half, deltaBalance, otherHalf);
  }

  function _swapTokensForETH(uint256 tokenAmount) private {
    // generate the pancakeswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeswapV2Router.WETH();

    _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    // make the swap
    pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function _swapTokensForMarketing(uint256 tokenAmount) private {
    // generate the pancakeswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeswapV2Router.WETH();

    _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    // make the swap
    pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      _marketingWallet,
      block.timestamp
    );
  }

  function withdrawLockedETH(address recipient)
    external
    override
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(recipient != address(0), 'Cannot withdraw the ETH balance to the zero address');
    require(_withdrawableBalance > 0, 'The ETH balance must be greater than 0');

    uint256 amount = _withdrawableBalance;
    _withdrawableBalance = 0;

    (bool success,) = payable(recipient).call{value: amount}('');

    if(!success) {
      revert();
    }
  }

  function _swapTokensForDividends(uint256 tokenAmount, address recipient) private {
    // generate the pancakeswap pair path of weth -> dividend
    address[] memory path = new address[](3);
    path[0] = address(this);
    path[1] = pancakeswapV2Router.WETH();
    path[2] = _dividendRewardToken;

    _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    // make the swap
    pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of tokens
      path,
      recipient,
      block.timestamp
    );
  }

  // withdraw any tokens that are not supposed to be insided this contract.
  function withdrawLockedTokens(address recipient, address _token)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_token != pancakeswapV2Router.WETH());
    require(_token != address(this));

    uint256 amountToWithdraw = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(payable(recipient), amountToWithdraw);
  }

  function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(pancakeswapV2Router), tokenAmount);

    // add the liquidity
    pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      _liquidityWallet,
      block.timestamp
    );
  }

  function _checkLiquidityAdd(address from, address to) private {
    // if liquidity is added by the _liquidityholders set trading enables to true and start the anti sniper timer
    require(!_hasLiqBeenAdded, 'Liquidity already added and marked.');

    if(_liquidityHolders[from] && to == pancakeswapV2Pair) {
      _hasLiqBeenAdded = true;
      _tradingEnabled = true;
      _liqAddBlock = block.number;
    }
  }

  // this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    // failsafe, disable the whole system if needed.
    if(_sniperProtection) {
      // if sender is a sniper address, reject the sell.
      if(isSniper(sender)) {
        revert('Sniper rejected.');
      }

      // check if this is the liquidity adding tx to startup.
      if(!_hasLiqBeenAdded) {
        _checkLiquidityAdd(sender, recipient);
      } else {
        if(
          _liqAddBlock > 0
            && sender == pancakeswapV2Pair
            && !_liquidityHolders[sender]
            && !_liquidityHolders[recipient]
        ) {
          if(block.number - _liqAddBlock < _snipeBlockAmount) {
            _isSniper[recipient] = true;
            snipersCaught++;
            emit SniperCaught(recipient);
          }
        }
      }
    }

    if(!takeFee) {
      _removeAllFee();
    }

    _takeLiquidityAndTransfer(sender, recipient, amount);

    try dividendTracker.setBalance(payable(sender), balanceOf(sender)) {} catch {}
    try dividendTracker.setBalance(payable(recipient), balanceOf(recipient)) {} catch {}

    if(!inSwapAndLiquify) {
      uint256 gas = gasForProcessing;

      try dividendTracker.process(gas) returns(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex
      ) {
        emit ProcessedDividendTracker(
          iterations,
          claims,
          lastProcessedIndex,
          true,
          gas,
          tx.origin
        );
      } catch {}
    }

    if(!takeFee) {
      _restoreAllFee();
    }
  }

  function _takeLiquidityAndTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    _balances[sender] -= amount;

    uint256 liquidityAmount = (amount / 100) * _totalFee;
    uint256 transferAmount = amount - liquidityAmount;

    _balances[recipient] += transferAmount;

    if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
      emit Transfer(sender, recipient, transferAmount);
      return;
    }

    _balances[address(this)] += liquidityAmount;

    emit Transfer(sender, address(this), liquidityAmount);
    emit Transfer(sender, recipient, transferAmount);
  }

  function setMarketingWallet(address payable newWallet)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_marketingWallet != newWallet, 'Wallet already set!');
    _marketingWallet = newWallet;
  }

  function setLiquidityWallet(address payable newWallet)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_liquidityWallet != newWallet, 'Wallet already set!');
    _liquidityWallet = newWallet;
  }

  function updateDividendTracker(address newAddress)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(
      newAddress != address(dividendTracker),
      'HoldBtc: The dividend tracker already has that address'
    );

    DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

    require(
      newDividendTracker.owner() == address(this),
      'HoldBtc: The new dividend tracker must be owned by the token contract'
    );

    newDividendTracker.excludeFromDividends(address(newDividendTracker));
    newDividendTracker.excludeFromDividends(address(this));
    newDividendTracker.excludeFromDividends(msg.sender);
    newDividendTracker.excludeFromDividends(address(pancakeswapV2Router));

    emit UpdateDividendTracker(newAddress, address(dividendTracker));

    dividendTracker = newDividendTracker;
  }

  function _swapAndSendTokenDividends(uint256 tokens) private {
    _swapTokensForDividends(tokens, address(this));
    uint256 dividends = IERC20(_dividendRewardToken).balanceOf(address(this));
    bool success = IERC20(_dividendRewardToken).transfer(address(dividendTracker), dividends);

    if(success) {
      dividendTracker.distributeRewardDividends(dividends);
      emit SendDividends(tokens, dividends);
    }
  }

  function changeFees(
    uint256 liquidityFee,
    uint256 marketingFee,
    uint256 dividendFee
  )
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    // fees are setup so they can not exceed 30% in total
    // and specific limits for each one.
    require(liquidityFee <= 5);
    require(marketingFee <= 5);
    require(dividendFee <= 20);

    _liquidityFee = liquidityFee;
    _marketingFee = marketingFee;
    _dividendRewardsFee = dividendFee;

    _totalFee = liquidityFee + marketingFee + dividendFee;
  }

  receive() external payable {}
}