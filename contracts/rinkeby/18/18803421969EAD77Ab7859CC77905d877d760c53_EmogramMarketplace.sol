/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.2;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IAccessControl

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

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

// Part: OpenZeppelin/[email protected]/SafeMath

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// Part: OpenZeppelin/[email protected]/Strings

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

// Part: OpenZeppelin/[email protected]/ERC165

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

// Part: OpenZeppelin/[email protected]/IERC1155

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// Part: OpenZeppelin/[email protected]/AccessControl

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

// Part: OpenZeppelin/[email protected]/ERC165Storage

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: EmogramMarketplace.sol

contract EmogramMarketplace is AccessControl, ReentrancyGuard, ERC165Storage {


    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    bytes4 constant ERC2981ID = 0x2a55205a;

    bool isTestPeriod;

    struct initAuction {
        bool isInitialAuction;
        uint256 cycle;
    }

    bool public isInitialAuction = true;

    // Struct for a fixed price sell
    // sellId - Id of the sale
    // tokenAddress - the address of the token contract
    // tokenId - the Id of the NFT token on sale
    // seller - address of the seller (also current owner)
    // price - price to sell for
    // isSold - is the item already sold
    struct sellItem {
        uint256 sellId;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    // auctionId - Unique ID of the auction
    // tokenAddress - Address of the token contract
    // tokenId - Id of the NFT being auctioned
    // seller - Address of the seller
    // highestBidder - Address of the current highest bidder
    // startPrice - The starting price of the auction
    // highestBid -  The current highest bid (bid of the highestBidder)
    // duration - How long the auction is running for
    // onAuction - Is the emogram currently on auction
    struct auctionItem {
        uint256 auctionId;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        address payable highestBidder;
        uint256 startPrice;
        uint256 highestBid;
        uint256 endDate;
        bool onAuction;
    }

    initAuction public initialAuction;

    // All emograms in the marketplace
    sellItem[] public emogramsOnSale;
    auctionItem[] public emogramsOnAuction;

    //The order of the emograms during the initial auction period
    mapping(uint256 => uint256) private initialEmogramsorder;

    // Emograms in the marketplace currently up for sale or auction
    mapping(address => mapping(uint256 => bool)) public activeEmograms;
    mapping(address => mapping(uint256 => bool)) public activeAuctions;

    event EmogramAdded(uint256 indexed id, uint256 indexed tokenId, address indexed tokenAddress, uint256 askingPrice);
    event SellCancelled(address indexed sender, address indexed tokenAddress, uint256 indexed tokenId);
    event EmogramSold (uint256 indexed id, uint256 indexed tokenId, address indexed buyer, uint256 askingPrice, address seller);
    event BidPlaced(uint256 indexed id, uint256 indexed tokenId, address indexed bidder, uint256 bid);
    event AuctionCreated(uint256 indexed id, uint256 indexed tokenId, address indexed seller, address tokenAddress, uint256 startPrice, uint256 duration);
    event AuctionCanceled(uint256 indexed id, uint256 indexed tokenId, address indexed seller, address tokenAddress);
    event AuctionFinished(uint256 indexed id, uint256 indexed tokenId, address indexed highestBidder, address seller, uint256 highestBid);
    event InitialAuctionSale(uint256 indexed id, uint256 indexed tokenid, address highestBidder, uint256 highestBid);
    event InitialAuctionFinished();

    // Check if the caller is actually the owner
    modifier isTheOwner(address _tokenAddress, uint256 _tokenId, address _owner) {
        IERC1155 tokenContract = IERC1155(_tokenAddress);
        require(tokenContract.balanceOf(_owner, _tokenId) != 0, "Not owner");
        _;
    }

    modifier isTheHighestBidder(address _bidder, uint256 _auctionId) {
        require(emogramsOnAuction[_auctionId].highestBidder == _bidder, "Not the highest Bidder");
        _;
    }

    // Check if marketplace has approval to sell/buy on behalf of the caller
    // TODO: Add royalty check here
    modifier hasTransferApproval (address tokenAddress, uint256 tokenId) {
        IERC1155 tokenContract = IERC1155(tokenAddress);
        require(tokenContract.isApprovedForAll(msg.sender, address(this)) == true, "No Approval");
        _;
    }

    modifier isInitialAuctionPeriod() {
        require(initialAuction.isInitialAuction == true, "The initial auction period has already ended");
        _;
    }

    modifier auctionNotEnded(uint256 _auctionId) {
        require(emogramsOnAuction[_auctionId].endDate > block.timestamp, "Auction has already ended");
        _;
    }

        modifier auctionEnded(uint256 _auctionId) {
        require(emogramsOnAuction[_auctionId].endDate < block.timestamp, "Auction is still ongoing");
        _;
    }

    modifier AuctionActive(uint256 _auctionId) {
        require(activeAuctions[emogramsOnAuction[_auctionId].tokenAddress][emogramsOnAuction[_auctionId].tokenId] == true, "Auction already finished");
        _;
    }

    // Check if the item exists
    modifier itemExists(uint256 id){
        require(id <= emogramsOnSale.length && emogramsOnSale[id].sellId == id, "Could not find item");
        _;
    }
    
    modifier itemExistsAuction(uint256 id) {
        require(id <= emogramsOnAuction.length && emogramsOnAuction[id].auctionId == id, "Could not find item");
        _;
    }

    // Check if the item is actually up for sale
    modifier isForSale(uint256 id) {
        require(emogramsOnSale[id].isSold == false, "Item is already sold");
        _;
    }

    constructor(bool _isTest) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FOUNDER_ROLE, msg.sender);

        _registerInterface(ERC2981ID);
        isTestPeriod = _isTest;

        initialAuction.isInitialAuction = true;
        initialAuction.cycle = 0;
    }

    function setInitialorder(uint256[99] memory _ids) 
     public
     onlyRole(FOUNDER_ROLE) {
         require(_ids.length == 99, "id length mismatch");
         for(uint256 i = 0; i < _ids.length; i++) {
             initialEmogramsorder[i] = _ids[i];
         }
    }


    // Add new founders
    function addFounder(address _newFounder)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) {

            grantRole(FOUNDER_ROLE, msg.sender);
        }

    function emogramsOnSaleLength()
        public
        view
        returns (uint256) {
            return emogramsOnSale.length;
        }

    function emogramsOnAuctionLength()
        public
        view
        returns (uint256) {
            return emogramsOnAuction.length;
        }

    //Sell ID
    //transfers royalty to receiver
    //returns the amount to send to the seller and the seller
    function sendRoyalty(uint256 _id) 
    private 
    returns(address, uint256) {

        //Calculating royalty
        (bool succes, bytes memory result) = emogramsOnSale[_id].tokenAddress.call(abi.encodeWithSignature("royaltyInfo(uint256,uint256)", emogramsOnSale[_id].tokenId, emogramsOnSale[_id].price));
        (address receiver, uint256 royAmount) = abi.decode(result, (address, uint256));
        uint256 toSend = SafeMath.sub(emogramsOnSale[_id].price,royAmount);

        //Sending the royalty
        (bool sent, bytes memory data) = receiver.call{value: royAmount}("");
        require(sent, "Failed to send royalty");

        return (emogramsOnSale[_id].seller, toSend);

    }

    //Auction ID
    //transfers royalty to receiver
    //returns amount to send after royalty and highestbidder
    function sendRoyaltyAuction(uint256 _id)
    private
    returns(address, uint256) {

        //Calculating royalty
        (bool succes, bytes memory result) = emogramsOnAuction[_id].tokenAddress.call(abi.encodeWithSignature("royaltyInfo(uint256,uint256)", emogramsOnAuction[_id].tokenId, emogramsOnAuction[_id].highestBid));
        (address receiver, uint256 royAmount) = abi.decode(result, (address, uint256));

        uint256 toSend = emogramsOnAuction[_id].highestBid - royAmount;

        //Sending the royalty
        (bool sent, bytes memory data) = receiver.call{value: royAmount}("");
        require(sent, "Failed to send royalty");

        return (emogramsOnAuction[_id].highestBidder, toSend);
    }

    // A function to add a new Emogram to the marketplace for sale
    function addEmogramToMarket(uint256 tokenId, address tokenAddress, uint256 askingPrice) 
    hasTransferApproval(tokenAddress, tokenId)
    nonReentrant() 
    external 
    returns(uint256) {
        require(activeEmograms[tokenAddress][tokenId] == false, "Item is already up for sale");
        require(activeAuctions[tokenAddress][tokenId] == false, "Item already up for auction");
        uint256 newItemId = emogramsOnSale.length;
        emogramsOnSale.push(sellItem(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice, false));
        activeEmograms[tokenAddress][tokenId] = true;

        assert(emogramsOnSale[newItemId].sellId == newItemId);
        emit EmogramAdded(newItemId, tokenId, tokenAddress, askingPrice);
        return newItemId;
    }

    function cancelSell(uint256 _id) 
    itemExists(_id)
    isForSale(_id)
    isTheOwner(emogramsOnSale[_id].tokenAddress, emogramsOnSale[_id].tokenId, msg.sender)
    public {
        
        emit SellCancelled(msg.sender, emogramsOnSale[_id].tokenAddress, emogramsOnSale[_id].tokenId);
        activeEmograms[emogramsOnSale[_id].tokenAddress][emogramsOnSale[_id].tokenId] = false;
        delete emogramsOnSale[_id];
    } 

    // Buy the Emogram
    function buyEmogram(uint256 id) 
    payable  
    external
    nonReentrant() 
    itemExists(id) 
    isForSale(id) 
    {
        require(msg.value >= emogramsOnSale[id].price, "Not enough funds for purchase");
        require(msg.sender != emogramsOnSale[id].seller, "Cannot buy own item");

        emogramsOnSale[id].isSold = true;
        activeEmograms[emogramsOnSale[id].tokenAddress][emogramsOnSale[id].tokenId] = false;
        IERC1155(emogramsOnSale[id].tokenAddress).safeTransferFrom(emogramsOnSale[id].seller, msg.sender, emogramsOnSale[id].tokenId, 1, "");

        (address receiver, uint256 toSend) = sendRoyalty(id);

        //Sending the payment
        (bool sentSucces, bytes memory dataRec) = emogramsOnSale[id].seller.call{value: toSend}("");
        require(sentSucces, "Failed to buy");

        emit EmogramSold(id, emogramsOnSale[id].tokenId, msg.sender, emogramsOnSale[id].price, emogramsOnSale[id].seller);
    }

    function createAuction(uint256 _tokenId, address _tokenAddress, uint256 _duration, uint256 _startPrice) 
    hasTransferApproval(_tokenAddress, _tokenId)
    isTheOwner(_tokenAddress, _tokenId, msg.sender)
    nonReentrant()
    public
    returns (uint256) 
    {
        require(activeAuctions[_tokenAddress][_tokenId] == false, "Emogram is already up for auction");
        require(activeEmograms[_tokenAddress][_tokenId] == false, "Item is already up for sale");
        uint256 durationToDays;

        if(isTestPeriod == true) {
            durationToDays = block.timestamp + _duration; //TODO: actually in secs
        }
        else {
            durationToDays = block.timestamp + _duration * 1 days;
         }

        emogramsOnAuction.push(auctionItem(emogramsOnAuction.length, _tokenAddress, _tokenId, payable(msg.sender), payable(msg.sender), _startPrice, _startPrice, durationToDays, true));
        activeAuctions[_tokenAddress][_tokenId] = true;

        assert(emogramsOnAuction[emogramsOnAuction.length - 1].auctionId == emogramsOnAuction.length - 1);
        emit AuctionCreated(emogramsOnAuction[emogramsOnAuction.length - 1].auctionId, _tokenId, msg.sender, _tokenAddress, _startPrice, durationToDays);

        return emogramsOnAuction[emogramsOnAuction.length - 1].auctionId;
    }

    function cancelAuction(uint256 _auctionId, uint256 _tokenId, address _tokenAddress)
    hasTransferApproval(_tokenAddress, _tokenId)
    isTheOwner(_tokenAddress, _tokenId, msg.sender)
    auctionNotEnded(_auctionId)
    nonReentrant()
    payable
    external
    returns(uint256) 
    {
        require(activeAuctions[_tokenAddress][_tokenId] == true, "This auction doesn't exits anymore");

        if(emogramsOnAuction[_auctionId].highestBid == emogramsOnAuction[_auctionId].startPrice) {

            activeAuctions[_tokenAddress][_tokenId] = false;
            delete emogramsOnAuction[_auctionId];
            emit AuctionCanceled(_auctionId, _tokenId, msg.sender, _tokenAddress);
        }

        else {

            (bool sent, bytes memory data) = emogramsOnAuction[_auctionId].highestBidder.call{value: emogramsOnAuction[_auctionId].highestBid}("");
            require(sent, "Failed to cancel");
            activeAuctions[_tokenAddress][_tokenId] = false;
            delete emogramsOnAuction[_auctionId];

            emit AuctionCanceled(_auctionId, _tokenId, msg.sender, _tokenAddress);
        }
    }

    function PlaceBid(uint256 _auctionId, uint256 _tokenId, address _tokenAddress)
    auctionNotEnded(_auctionId)
    nonReentrant()
    payable
    external
    returns(uint256)
    {
        require(activeAuctions[_tokenAddress][_tokenId] == true, "Auction has already finished");
        require(emogramsOnAuction[_auctionId].highestBid <= msg.value, "Bid too low");
        require(emogramsOnAuction[_auctionId].seller != msg.sender, "Can't bid on your own auction!");

        if(emogramsOnAuction[_auctionId].highestBid != emogramsOnAuction[_auctionId].startPrice) {    
        (bool sent, bytes memory data) = emogramsOnAuction[_auctionId].highestBidder.call{value: emogramsOnAuction[_auctionId].highestBid}("");
        require(sent, "Failed to place bid");

        emogramsOnAuction[_auctionId].highestBidder = payable(msg.sender);
        emogramsOnAuction[_auctionId].highestBid = msg.value;

        emit BidPlaced(_auctionId, emogramsOnAuction[_auctionId].tokenId, msg.sender, msg.value);
        return _auctionId;
        }

        else {
            require(emogramsOnAuction[_auctionId].highestBid < msg.value, "Bid too low");
            emogramsOnAuction[_auctionId].highestBidder = payable(msg.sender);
            emogramsOnAuction[_auctionId].highestBid = msg.value;

            emit BidPlaced(_auctionId, emogramsOnAuction[_auctionId].tokenId, msg.sender, msg.value);
            return _auctionId;
        }
    }

    function stepAuctions(address _tokenAddress, uint256 _startPrice, uint256 _duration)
    isInitialAuctionPeriod()
    onlyRole(FOUNDER_ROLE)
    payable
    external
     {
        require(initialAuction.cycle <= 33, "Max cycles already reached");

        if(emogramsOnAuction.length == 3) {
            for(uint i = 0; i < 3; i++) {
                if(emogramsOnAuction[i].highestBidder == msg.sender) {
                    endAuctionWithNoBid(_tokenAddress, emogramsOnAuction[i].tokenId, emogramsOnAuction[i].auctionId);
                }
                else {
                    endAuctionWithBid(_tokenAddress, emogramsOnAuction[i].tokenId, emogramsOnAuction[i].auctionId);
                }
            }
        }

        for(uint256 i = (initialAuction.cycle * 3); i < (initialAuction.cycle * 3 + 3); i++) {

            createAuction(initialEmogramsorder[i], _tokenAddress, _duration, _startPrice);
        }

        initialAuction.cycle = initialAuction.cycle + 1;

        if(initialAuction.cycle >= 33) {
            initialAuction.isInitialAuction = false;
            emit InitialAuctionFinished();
        }

     }

    function endAuctionWithBid(address _tokenAddress, uint256 _tokenId, uint256 _auctionId) private {

        require(emogramsOnAuction[_auctionId].highestBid != 0, "Highest bid cannot be zero in endAuctionWithBid()");

        (address receiver, uint256 toSend) = sendRoyaltyAuction(_auctionId);

        (bool sentSucces, bytes memory dataReceived) = emogramsOnAuction[_auctionId].seller.call{value: toSend}("");
        require(sentSucces, "Failed to cancel");

        IERC1155(emogramsOnAuction[_auctionId].tokenAddress).safeTransferFrom(emogramsOnAuction[_auctionId].seller, emogramsOnAuction[_auctionId].highestBidder, emogramsOnAuction[_auctionId].tokenId, 1, "");
            
        activeAuctions[_tokenAddress][_tokenId] = false;
        emit AuctionFinished(_auctionId, _tokenId, emogramsOnAuction[_auctionId].highestBidder, emogramsOnAuction[_auctionId].seller, emogramsOnAuction[_auctionId].highestBid);
        delete emogramsOnAuction[_auctionId];
     }

    function endAuctionWithNoBid(address _tokenAddress, uint256 _tokenId, uint256 _auctionId) private {

        require(activeAuctions[_tokenAddress][_tokenId] == true);
        require(emogramsOnAuction[_auctionId].highestBid == emogramsOnAuction[_auctionId].startPrice && emogramsOnAuction[_auctionId].highestBidder == emogramsOnAuction[_auctionId].seller);

        activeAuctions[_tokenAddress][_tokenId] = false;
        emit AuctionFinished(_auctionId, _tokenId, emogramsOnAuction[_auctionId].highestBidder, emogramsOnAuction[_auctionId].seller, emogramsOnAuction[_auctionId].highestBid);     
        delete emogramsOnAuction[_auctionId];    
     }

    function finishAuction(address _tokenAddress, uint256 _tokenId, uint256 _auctionId)
     auctionEnded(_auctionId)
     AuctionActive(_auctionId)
     nonReentrant()
     hasTransferApproval(_tokenAddress, _tokenId)
     itemExistsAuction(_auctionId) 
     public
     returns (bool)
     {
        IERC1155 tokenContract = IERC1155(_tokenAddress);
        require(tokenContract.balanceOf(msg.sender, _tokenId) != 0 || emogramsOnAuction[_auctionId].highestBidder == msg.sender, "Not the owner or highest bidder");

        if(emogramsOnAuction[_auctionId].highestBid != emogramsOnAuction[_auctionId].startPrice) {

            endAuctionWithBid(_tokenAddress, _tokenId, _auctionId);
            return true;
        }

        else if(emogramsOnAuction[_auctionId].highestBid == emogramsOnAuction[_auctionId].startPrice && emogramsOnAuction[_auctionId].highestBidder == emogramsOnAuction[_auctionId].seller) {

            endAuctionWithNoBid(_tokenAddress, _tokenId, _auctionId);
            return true;
        }
     }

    function setPeriod(bool _isTest)
    onlyRole(FOUNDER_ROLE)
    public
    returns (bool) {
        isTestPeriod = _isTest;
        return isTestPeriod;
    }

    function supportsInterface(bytes4 interfaceId)
     public
     view
     override(AccessControl, ERC165Storage)
     returns (bool) {
        
        return super.supportsInterface(interfaceId);
    }
    
    receive() external payable {}
}