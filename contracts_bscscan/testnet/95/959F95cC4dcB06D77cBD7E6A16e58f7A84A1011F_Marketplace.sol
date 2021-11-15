// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import './interfaces/IBEP20.sol';
import './interfaces/IProfileNFT.sol';
import './interfaces/IVersionedContract.sol';

contract Marketplace is
	AccessControlUpgradeable,
	ReentrancyGuardUpgradeable,
	ERC721HolderUpgradeable,
	IVersionedContract
{
	using Counters for Counters.Counter;

	/*
   =======================================================================
   ======================== Structures ===================================
   =======================================================================
 */

	struct SaleInfo {
		address seller;
		address buyer;
		uint256 profileId;
		uint256 sellingPrice;
		address currency; // Token address in which seller will get paid
		uint256 sellTimeStamp; // here, if sellTimeStamp is zero it means nft is available to purchase
		uint256 cancelTimeStamp;
	}

	struct AuctionInfo {
		uint256 profileId;
		address sellerAddress;
		uint256 initialPrice; //base price for bid
		address currency;
		uint256 startBlock;
		uint256 duration;
		uint256 status; //Active = 1, Closed = 0, Canceled = 2
		uint256 winningBidId;
		uint256[] bidIds;
		uint256 cancelTimeStamp;
		uint256 buyTimestamp;
	}

	struct Bid {
		uint256 auctionId;
		address bidderAddress;
		uint256 bidAmount;
	}

	/*
   =======================================================================
   ======================== Private Variables ============================
   =======================================================================
 */
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	Counters.Counter private saleIdCounter;
	Counters.Counter private auctionIdCounter;
	Counters.Counter private bidIdCounter;

	/*
   =======================================================================
   ======================== Public Variables ============================
   =======================================================================
 */

	/// @notice ERC721 NFT contract
	IProfileNFT public profileNFT;

	/// @notice minimum duration for auction period
	uint256 public minDuration;

	/// @notice saleId -> saleInfo
	mapping(uint256 => SaleInfo) public sale;

	/// @notice userAddress -> user`s sale ids
	mapping(address => uint256[]) public userSaleIds;

	/// @notice auctionId -> auctionInfo
	mapping(uint256 => AuctionInfo) public auction;

	/// @notice sellerAddress -> user`s auction ids
	mapping(address => uint256[]) public userAuctionIds;

	/// @notice bidId -> Bid
	mapping(uint256 => Bid) public bid;

	/// @notice BidderAddress -> bidIds
	mapping(address => uint256[]) public userBidIds;

	/// @notice list of supported tokens
	address[] public supportedTokens;

	/*
   =======================================================================
   ======================== Events =======================================
   =======================================================================
 */
	event NewNFTListing(address indexed seller, uint256 indexed saleId);
	event NFTAuction(address indexed seller, uint256 indexed auctionId);
	event BuySaleNFT(address indexed buyer, uint256 indexed profileId, uint256 saleId);
	event BuyAuctionNFT(address indexed buyer, uint256 indexed profileId, uint256 auctionId);
	event PlaceBid(
		uint256 auctionId,
		uint256 indexed bidId,
		address indexed bidderAddress,
		uint256 bidAmount,
		uint256 timestamp
	);

	/*
   =======================================================================
   ======================== Constructor/Initializer ======================
   =======================================================================
 */

	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 * @param _profileNFTAddress indicates the ERC721 NFT contract address
	 */
	function initialize(address _profileNFTAddress) external virtual initializer {
		require(_profileNFTAddress != address(0), 'Market: INVALID_NFT_CONTRACT');

		__AccessControl_init();
		__ReentrancyGuard_init();

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		profileNFT = IProfileNFT(_profileNFTAddress);

		minDuration = 1 days;
	}

	/*
   =======================================================================
   ======================== Modifiers ====================================
   =======================================================================
 */
	modifier onlyAdmin() {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Market: ONLY_ADMIN_CAN_CALL');
		_;
	}

	modifier onlySupportedTokens(address _tokenAddress) {
		(bool isSupported, ) = isSupportedToken(_tokenAddress);
		require(isSupported, 'Market: UNSUPPORTED_TOKEN');
		_;
	}

	modifier onlyValidProfileId(uint256 _profileId) {
		require(
			_profileId > 0 && _profileId <= profileNFT.getCurrentTokenId(),
			'Market:INVALID_PROFILE_ID'
		);
		_;
	}

	modifier onlyValidAuctionId(uint256 _auctionId) {
		require(
			_auctionId > 0 && _auctionId <= auctionIdCounter.current(),
			'Market: INVALID_AUCTION_ID'
		);

		_;
	}

	modifier onlyValidSaleId(uint256 _saleId) {
		require(_saleId > 0 && _saleId <= saleIdCounter.current(), 'Market: INVALID_SALE_ID');
		_;
	}

	/*
   =======================================================================
   ======================== Public Methods ===============================
   =======================================================================
 */
	/**
	 * @notice This method allows the NFT owner/seller to sell his nft at a fix price. owner needs to approve his nft to this contract first. anyone with nft can call this method.
	 * @param _profileId indicates the nft id which user wants to sell
	 * @param _nftPrice indicates the fix price for the NFT at which user wants to sell his NFT.
	 * @param _tokenAddress indicates the the ERC20/BEP20 token address in which nft seller/owner wants to get paid in
	 * @return saleId - indicates the new sale id in which owners nft is sold
	 */
	function sellProfileNFT(
		uint256 _profileId,
		uint256 _nftPrice,
		address _tokenAddress
	) external virtual onlyValidProfileId(_profileId) nonReentrant returns (uint256 saleId) {
		require(_nftPrice > 0, 'Market: INVALID_NFT_PRICE');

		//get NFT tokens from seller
		profileNFT.safeTransferFrom(msg.sender, address(this), _profileId);

		saleId = _sellNFT(_profileId, _nftPrice, _tokenAddress);
	}

	/**
	 * @notice This method allows anyone with NFT to put his NFT in Auction.
	 * @param _profileId indicates the NFT id for which user wants to creat auction.
	 * @param _initialPrice indicates the startting price for the auction. all the bids should be greater than the initial price.
	 * @param _tokenAddress indicates the the ERC20/BEP20 token address in which nft seller/owner wants to get paid in
	 * @param _duration indicates the duration after which auction will get closed.
	 * @return auctionId - indicates the auctionId in which owner puts his nft for sale.
	 */
	function createProfileNFTAuction(
		uint256 _profileId,
		uint256 _initialPrice,
		address _tokenAddress,
		uint256 _duration
	) external virtual onlyValidProfileId(_profileId) nonReentrant returns (uint256 auctionId) {
		require(_initialPrice > 0, 'Market: INVALID_INITIAL_NFT_PRICE');

		//get nft copy from sender and put it in auction
		profileNFT.safeTransferFrom(msg.sender, address(this), _profileId);

		auctionId = _createAuction(_profileId, _initialPrice, _tokenAddress, _duration);
	}

	/**
	 * @notice This method allows NFT sale creator to cancel the sale and claim back the nft token
	 * @param _saleId indicates the saleId which user wants to cancel
	 */
	function cancelSaleAndClaimToken(uint256 _saleId)
		external
		virtual
		onlyValidSaleId(_saleId)
		nonReentrant
	{
		SaleInfo storage _sale = sale[_saleId];

		require(_sale.seller == msg.sender, 'Market: ONLY_SELLER_CAN_CANCEL');
		require(isActiveSale(_saleId), 'Market: CANNOT_CANCEL_INACTIVE_SALE');

		profileNFT.safeTransferFrom(address(this), msg.sender, _sale.profileId);

		_sale.cancelTimeStamp = block.timestamp;
	}

	/**
	 * @notice This method allows auction creator to cancel the auction and claim back the nft. Auction can be cancel only if it does not have any bids.
	 * @param _auctionId indicates the auctionId which user wants to cancel
	 */
	function cancelAuctionAndClaimToken(uint256 _auctionId)
		external
		virtual
		onlyValidAuctionId(_auctionId)
		nonReentrant
	{
		AuctionInfo storage _auction = auction[_auctionId];

		require(isActiveAuction(_auctionId), 'Market: CANNOT_CANCEL_INACTIVE_AUCTION');
		require(_auction.sellerAddress == msg.sender, 'Market: ONLY_NFT_SELLER_CAN_CANCEL');
		require(_auction.bidIds.length == 0, 'Market: CANNOT_CANCEL_AUCTION_WITH_NON_ZERO_BIDS');

		profileNFT.safeTransferFrom(address(this), msg.sender, _auction.profileId);

		_auction.status = 2; // canceled
		_auction.cancelTimeStamp = block.timestamp;
	}

	/**
	 * @notice This method allows auction creator to update the auction starting price and extend the auction only if auction is ended with no bids.
	 * @param _auctionId indicates the id of auction whose details needs to update
	 * @param _newPrice indicates the new starting price for the auction.
	 * @param _timeExtension indicates the extended time for the auction. it can be zero if user only wants to update the auction price.
	 */
	function updateAuction(
		uint256 _auctionId,
		uint256 _newPrice,
		uint256 _timeExtension
	) external virtual onlyValidAuctionId(_auctionId) {
		AuctionInfo storage _auction = auction[_auctionId];
		require(msg.sender == _auction.sellerAddress, 'Market:ONLY_SELLER_CAN_UPDATE');
		require(_newPrice > 0 && _newPrice != _auction.initialPrice, 'Market: INVALID_INITIAL_PRICE');
		require(_auction.status == 1, 'Market: CANNOT_UPDATE_INACTIVE_AUCTION');
		require(_auction.bidIds.length == 0, 'Market: CANNOT_UPDATE_AUCTION_WITH_NON_ZERO_BIDS');

		_auction.duration = _auction.duration + _timeExtension;
		_auction.initialPrice = _newPrice;
	}

	/**
	 * @notice This method allows sale creator to update the sale starting price and extend the auction only if auction is ended with no bids.
	 * @param _saleId indicates the id of sale whose details needs to update
	 * @param _newPrice indicates the new starting price for the auction.
	 */
	function updateSale(uint256 _saleId, uint256 _newPrice)
		external
		virtual
		onlyValidSaleId(_saleId)
	{
		SaleInfo storage _sale = sale[_saleId];
		require(msg.sender == _sale.seller, 'Market:ONLY_SELLER_CAN_UPDATE');
		require(_sale.sellTimeStamp == 0, 'Market: SALE_ALREADY_ENDED');
		require(_newPrice > 0 && _newPrice != _sale.sellingPrice, 'Market: INVALID_SELLING_PRICE');
		_sale.sellingPrice = _newPrice;
	}

	/**
	 * @notice This method allows auction creator to move his NFT in sale only if auction is ended with zero bids.
	 * @param _auctionId indicates the auction id
	 * @param _sellingPrice indicates the fix selling price for the nft
	 * @return saleId - indicates the sale id in which nft will be available for sale.
	 */
	function moveNftInSale(uint256 _auctionId, uint256 _sellingPrice)
		external
		virtual
		onlyValidAuctionId(_auctionId)
		returns (uint256 saleId)
	{
		require(isActiveAuction(_auctionId), 'Market: CANNOT_MOVE_NFT_FROM_INACTIVE_AUCTION');
		require(_sellingPrice > 0, 'Market: INVALID_SELLING_PRICE');

		AuctionInfo storage _auction = auction[_auctionId];
		require(msg.sender == _auction.sellerAddress, 'Market: CALLER_NOT_THE_AUCTION_CREATOR');
		require(_auction.bidIds.length == 0, 'Market: CANNOT_UPDATE_AUCTION');

		//cancel the auction
		_auction.status = 2;

		//create sale
		saleId = _sellNFT(_auction.profileId, _sellingPrice, _auction.currency);
	}

	/**
    * @notice This method allows anyone with accepted tokens to purchase the NFT from the particular sale. user needs to approve his ERC20/BEP20 tokens to this contract.
              buyer cannot buy/hold more than one copy of same nft.
    * @param _saleId indicates the saleId in from which buyer buys required NFT at specified price.
   */
	function buyNFT(uint256 _saleId) external virtual onlyValidSaleId(_saleId) nonReentrant {
		require(isActiveSale(_saleId), 'Market: CANNOT_BUY_FROM_INACTIVE_SALE');
		SaleInfo storage _sale = sale[_saleId];

		// check the royalty amount
		(address royaltyReceiver, uint256 royaltyAmount) = profileNFT.royaltyInfo(
			_sale.profileId,
			_sale.sellingPrice
		);

		uint256 sellerAmount = _sale.sellingPrice - royaltyAmount;

		//transfer tokens to the seller
		require(
			IBEP20(_sale.currency).transferFrom(msg.sender, _sale.seller, sellerAmount),
			'Market: TRANSFER_FROM_FAILED'
		);

		//transfer royaly amount to royalty receiver
		require(
			IBEP20(_sale.currency).transferFrom(msg.sender, royaltyReceiver, royaltyAmount),
			'Market: TRANSFER_FROM_FAILED'
		);

		//transfer profile nft to buyer
		profileNFT.safeTransferFrom(address(this), msg.sender, _sale.profileId);

		_sale.buyer = msg.sender;
		_sale.sellTimeStamp = block.timestamp;

		emit BuySaleNFT(msg.sender, _sale.profileId, _saleId);
	}

	/**
	 * @notice This method allows anyone with accepted token to place the bid on auction to buy NFT. bidder need to approve his accepted tokens.
	 * @param _auctionId indicates the auctionId for which user wants place bid.
	 * @param _bidAmount indicates the bidAmount which must be greater than the existing winning bid amount or startingPrice in case of first bid.
	 */
	function placeBid(uint256 _auctionId, uint256 _bidAmount)
		external
		virtual
		onlyValidAuctionId(_auctionId)
		returns (uint256 bidId)
	{
		require(isActiveAuction(_auctionId), 'Market: CANNOT_BID_ON_INACTIVE_AUCTION');
		AuctionInfo storage _auction = auction[_auctionId];
		require(_auction.sellerAddress != msg.sender, 'Market: OWNER_CANNOT_PLACE_BID');

		require(block.timestamp >= _auction.startBlock, 'Market: CANNOT_BID_BEFORE_AUCTION_STARTS');

		require(
			block.timestamp <= (_auction.startBlock + _auction.duration),
			'Market: CANNOT_BID_AFTER_AUCTION_ENDS'
		);

		if (_auction.bidIds.length == 0) {
			require(_bidAmount >= _auction.initialPrice, 'Market: INVALID_BID_AMOUNT');
		} else {
			require(_bidAmount > bid[_auction.winningBidId].bidAmount, 'Market: INVALID_BID_AMOUNT');
		}

		//transferFrom the tokens
		require(
			IBEP20(_auction.currency).transferFrom(msg.sender, address(this), _bidAmount),
			'Market: TRANSFER_FROM_FAILED'
		);

		if (_auction.winningBidId != 0) {
			//transfer back the tokens to the previous winner
			require(
				IBEP20(_auction.currency).transfer(
					bid[_auction.winningBidId].bidderAddress,
					bid[_auction.winningBidId].bidAmount
				),
				'Market: TRANSFER_FAILED'
			);
		}
		//place bid
		bidIdCounter.increment();
		bidId = bidIdCounter.current();

		bid[bidId] = Bid(_auctionId, msg.sender, _bidAmount);

		_auction.winningBidId = bidId;
		_auction.bidIds.push(bidId);

		userBidIds[msg.sender].push(bidId);

		emit PlaceBid(_auctionId, bidId, msg.sender, _bidAmount, block.timestamp);
	}

	/**
	 * @notice This method finds the winner of the Auction and transfer the nft to winning bidder and accepted tokens to the nft seller/owner
	 * @param _auctionId indicates the auctionId which is to be resolve
	 */
	function resolveAuction(uint256 _auctionId)
		external
		virtual
		onlyValidAuctionId(_auctionId)
		nonReentrant
	{
		AuctionInfo storage _auction = auction[_auctionId];
		require(isActiveAuction(_auctionId), 'Market: CANNOT_RESOLVE_INACTIVE_AUCTION');
		require(
			block.timestamp > (_auction.startBlock + _auction.duration),
			'Market: CANNOT_RESOLVE_DURING_AUCTION'
		);
		require(
			_auction.winningBidId != 0 && _auction.bidIds.length > 0,
			'Market: CANNOT_RESOLVE_AUCTION_WITH_NO_BIDS'
		);

		// check the royalty amount
		(address royaltyReceiver, uint256 royaltyAmount) = profileNFT.royaltyInfo(
			_auction.profileId,
			bid[_auction.winningBidId].bidAmount
		);

		uint256 sellerAmount = bid[_auction.winningBidId].bidAmount - royaltyAmount;

		// transfer the tokens to the auction creator
		require(
			IBEP20(_auction.currency).transfer(_auction.sellerAddress, sellerAmount),
			'Market: TRANSFER_FAILED'
		);

		// transfer the royalty amount to the royaltyReceiver
		require(
			IBEP20(_auction.currency).transfer(royaltyReceiver, royaltyAmount),
			'Market: TRANSFER_FAILED'
		);

		profileNFT.safeTransferFrom(
			address(this),
			bid[_auction.winningBidId].bidderAddress,
			_auction.profileId
		);

		//close auction
		_auction.status = 0;
		_auction.buyTimestamp = block.timestamp;

		emit BuyAuctionNFT(bid[_auction.winningBidId].bidderAddress, _auction.profileId, _auctionId);
	}

	/**
	 * @notice This method allows admin to add the ERC20/BEP20 token which will be acceted for purchasing/selling NFT.
	 * @param _tokenAddress indicates the ERC20/BEP20 token address
	 */
	function addSupportedToken(address _tokenAddress) external virtual onlyAdmin {
		(bool isSupported, ) = isSupportedToken(_tokenAddress);
		require(!isSupported, 'Market: TOKEN_ALREADY_ADDED');
		supportedTokens.push(_tokenAddress);
	}

	/**
	 * @notice This method allows admin to remove the ERC20/BEP20 token from the accepted token list.
	 * @param _tokenAddress indicates the ERC20/BEP20 token address
	 */
	function removeSupportedToken(address _tokenAddress) external virtual onlyAdmin {
		uint256 noOfsupportedTokens = supportedTokens.length;
		require(noOfsupportedTokens > 0, 'MARKET: NO_SUPPORTED_TOKENS_ADDED');

		// check and remove if the last token is supported token to be removed.
		if (supportedTokens[noOfsupportedTokens - 1] == _tokenAddress) {
			supportedTokens.pop();
			return;
		}

		(bool isSupported, uint256 index) = isSupportedToken(_tokenAddress);
		require(isSupported, 'Market: TOKEN_DOES_NOT_EXISTS');

		// move supported token to last
		if (noOfsupportedTokens > 1) {
			address temp = supportedTokens[noOfsupportedTokens - 1];
			supportedTokens[index] = temp;
		}

		//remove supported token
		supportedTokens.pop();
	}

	/**
	 * @notice This method allows admin to update minimum duration for the auction period.
	 * @param _newDuration indicates the new mint limit
	 */
	function updateMinimumDuration(uint256 _newDuration) external virtual onlyAdmin {
		require(_newDuration > 0 && _newDuration != minDuration, 'Market: INVALID_MINIMUM_DURATION');
		minDuration = _newDuration;
	}

	/*
   =======================================================================
   ======================== Getter Methods ===============================
   =======================================================================
 */

	/**
	 * @notice This method allows user to get the winning bid of the particular auction.
	 * @param _auctionId indicates the id of auction.
	 * @return returns the details of winning bid.
	 */
	function getAuctionWinningBid(uint256 _auctionId)
		external
		view
		virtual
		onlyValidAuctionId(_auctionId)
		returns (Bid memory)
	{
		return bid[auction[_auctionId].winningBidId];
	}

	/**
	 * @notice This method returns the current sale Id
	 */
	function getCurrentSaleId() external view virtual returns (uint256) {
		return saleIdCounter.current();
	}

	/**
	 * @notice This method returns the current Auction Id
	 */
	function getCurrentAuctionId() external view virtual returns (uint256) {
		return auctionIdCounter.current();
	}

	/**
	 * @notice This method returns the current bid Id
	 */
	function getCurrentBidId() external view virtual returns (uint256) {
		return bidIdCounter.current();
	}

	/**
	 * @notice This method allows user to check if particular auction is acive or not.
	 * @param _auctionId indicates the auction id.
	 * @return isActive - returns true if auction is active false otherwise.
	 */
	function isActiveAuction(uint256 _auctionId)
		public
		view
		virtual
		onlyValidAuctionId(_auctionId)
		returns (bool isActive)
	{
		if (auction[_auctionId].status == 1) return true;
	}

	/**
	 * @notice This method allows user to check if particular sale is acive or not.
	 * @param _saleId indicates the sale id.
	 * @return isActive - returns true if sale is active false otherwise.
	 */
	function isActiveSale(uint256 _saleId)
		public
		view
		virtual
		onlyValidSaleId(_saleId)
		returns (bool isActive)
	{
		if (sale[_saleId].sellTimeStamp == 0 && sale[_saleId].cancelTimeStamp == 0) return true;
	}

	/**
	 * @notice This method allows user to check if particular token is supported to purchase the NFT or not.
	 * @param _tokenAddress indicates EC20/BEP20 token address
	 * @return isSupported - returns true if token is supported false otherwise. index - index of the supported token from the list of supported tokens
	 */
	function isSupportedToken(address _tokenAddress)
		public
		view
		virtual
		returns (bool isSupported, uint256 index)
	{
		for (uint256 i = 0; i < supportedTokens.length; i++) {
			if (supportedTokens[i] == _tokenAddress) {
				isSupported = true;
				index = i;
				break;
			}
		}
	}

	/**
	 * @dev Checks if the NFT being sold on your marketplace implemented royalties
	 * @param _contract - indicates NFT contract
	 */
	function checkRoyalties(address _contract) public view virtual returns (bool) {
		bool success = IERC165Upgradeable(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
		return success;
	}

	/*
   =======================================================================
   ======================== Internal Methods ===============================
   =======================================================================
 */

	function _sellNFT(
		uint256 _profileId,
		uint256 _nftPrice,
		address _tokenAddress
	) internal virtual onlySupportedTokens(_tokenAddress) returns (uint256 saleId) {
		//create sale
		saleIdCounter.increment();

		saleId = saleIdCounter.current();

		sale[saleId] = SaleInfo(msg.sender, address(0), _profileId, _nftPrice, _tokenAddress, 0, 0);

		userSaleIds[msg.sender].push(saleId);

		emit NewNFTListing(msg.sender, saleId);
	}

	function _createAuction(
		uint256 _profileId,
		uint256 _initialPrice,
		address _tokenAddress,
		uint256 _duration
	) internal virtual onlySupportedTokens(_tokenAddress) returns (uint256 auctionId) {
		require(_duration >= minDuration, 'Market: INVALID_DURATION');

		//create Auction
		auctionIdCounter.increment();
		auctionId = auctionIdCounter.current();

		uint256[] memory bidIds;

		auction[auctionId] = AuctionInfo(
			_profileId,
			msg.sender,
			_initialPrice,
			_tokenAddress,
			block.timestamp,
			_duration,
			1,
			0,
			bidIds,
			0,
			0
		);

		userAuctionIds[msg.sender].push(auctionId);

		emit NFTAuction(msg.sender, auctionId);
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(AccessControlUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

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

	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		virtual
		override
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		return (1, 0, 0);
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the token name.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external view returns (address);

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
	function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IProfileNFT is IERC721Upgradeable {
	function getCurrentTokenId() external view returns (uint256);

	function royaltyInfo(uint256 tokenId, uint256 _salePrice)
		external
		view
		returns (address royaltyReceiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionedContract {
	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		returns (
			uint256,
			uint256,
			uint256
		);
}

