// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
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
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

library AccessControlEvents {
    event OwnerSet(address indexed owner);

    event OwnerTransferred(address indexed owner, address indexed prevOwner);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/roles.sol";

abstract contract int_hasRole_AccessControl_v1 is sto_AccessControl_Roles {
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool hasRole_)
    {
        hasRole_ = accessControlRolesStore().roles[role].members[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./has-role.sol";

abstract contract int_requireAuthorization_AccessControl_v1 is
    int_hasRole_AccessControl_v1
{
    function _requireAuthorization(bytes32 role, address account)
        internal
        view
    {
        require(_hasRole(role, account), "AccessControl: unauthorized");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    int_requireAuthorization_AccessControl_v1
} from "../internal/require-authorization.sol";

abstract contract mod_authorized_AccessControl_v1 is
    int_requireAuthorization_AccessControl_v1
{
    modifier authorized(bytes32 role, address account) {
        _requireAuthorization(role, account);
        _;
    }
}

abstract contract mod_authorized_AccessControl is
    mod_authorized_AccessControl_v1
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RoleData } from "../data.sol";

contract sto_AccessControl_Roles {
    bytes32 internal constant POS =
        keccak256("teller_protocol.storage.access_control.roles");

    struct AccessControlRolesStorage {
        mapping(bytes32 => RoleData) roles;
    }

    function accessControlRolesStore()
        internal
        pure
        returns (AccessControlRolesStorage storage s)
    {
        bytes32 position = POS;

        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakeableNFT {
    function tokenBaseLoanSize(uint256 tokenId) external view returns (uint256);

    function tokenURIHash(uint256 tokenId)
        external
        view
        returns (string memory);

    function tokenContributionAsset(uint256 tokenId)
        external
        view
        returns (address);

    function tokenContributionSize(uint256 tokenId)
        external
        view
        returns (uint256);

    function tokenContributionMultiplier(uint256 tokenId)
        external
        view
        returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Interfaces
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ITellerNFT {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    /**
     * @notice The contract metadata URI.
     * @return the contractURI in string
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice It returns information about a Tier with from a tier index
     * @param index Tier index to get info.
     * @return tier_ the tier which belongs to the respective index
     */
    function getTier(uint256 index) external view returns (Tier memory tier_);

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     * @return index_ the index of the tier the tokenID belongs in
     * @return tier_ the tier where the tokenID belongs in
     */
    function getTokenTier(uint256 tokenId)
        external
        view
        returns (uint256 index_, Tier memory tier_);

    /**
     * @notice It returns an array of hashes in a tier
     * @param tierIndex the tier index to get the tier hashes
     * @return hashes_ all the tokenID hashes
     */
    function getTierHashes(uint256 tierIndex)
        external
        view
        returns (string[] memory hashes_);

    /**
     * @notice It returns an array of token IDs owned by an address.
     * @dev It uses a EnumerableSet to store values and loops over each element to add to the array.
     * @dev Can be costly if calling within a contract for address with many tokens.
     * @return owned the array of tokenIDs owned by the address
     */
    function getOwnedTokens(address owner)
        external
        view
        returns (uint256[] memory owned);

    /**
     * @notice It mints a new token for a Tier index.
     * @param tierIndex the tier index to mint the token in
     * @param owner the owner of the new token
     * Requirements:
     *  - Caller must be an authorized minter
     */
    function mint(uint256 tierIndex, address owner) external;

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {MINTER} role
     */
    function addTier(Tier memory newTier) external;

    /**
     * @notice Sets the contract level metadata URI hash.
     * @param contractURIHash The hash to the initial contract level metadata.
     */
    function setContractURIHash(string memory contractURIHash) external;

    /**
     * @notice Initializes the TellerNFT.
     * @param minters The addresses that should allowed to mint tokens.
     */
    function initialize(address[] calldata minters) external;
}

/**
 * @notice TellerNFTDictionary Version 1.02
 *
 * @notice This contract is used to gather data for TellerV1 NFTs more efficiently.
 * @notice This contract has data which must be continuously synchronized with the TellerV1 NFT data
 *
 * @author [email protected]
 */

pragma solidity ^0.8.0;

// Contracts
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Interfaces
import "./IStakeableNFT.sol";

/**
 * @notice This contract is used by borrowers to call Dapp functions (using delegate calls).
 * @notice This contract should only be constructed using it's upgradeable Proxy contract.
 * @notice In order to call a Dapp function, the Dapp must be added in the DappRegistry instance.
 *
 * @author [email protected]
 */
contract TellerNFTDictionary is IStakeableNFT, AccessControlUpgradeable {
    struct Tier {
        uint256 baseLoanSize;
        string[] hashes;
        address contributionAsset;
        uint256 contributionSize;
        uint8 contributionMultiplier;
    }

    mapping(uint256 => uint256) public baseLoanSizes;
    mapping(uint256 => string[]) public hashes;
    mapping(uint256 => address) public contributionAssets;
    mapping(uint256 => uint256) public contributionSizes;
    mapping(uint256 => uint8) public contributionMultipliers;

    /* Constants */

    bytes32 public constant ADMIN = keccak256("ADMIN");

    /* State Variables */

    mapping(uint256 => uint256) public _tokenTierMappingCompressed;
    bool public _tokenTierMappingCompressedSet;

    /* Modifiers */

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "TellerNFTDictionary: not admin");
        _;
    }

    function initialize(address initialAdmin) public {
        _setupRole(ADMIN, initialAdmin);
        _setRoleAdmin(ADMIN, ADMIN);

        __AccessControl_init();
    }

    /* External Functions */

    /**
     * @notice It returns information about a Tier for a token ID.
     * @param tokenId ID of the token to get Tier info.
     */
    function getTokenTierIndex(uint256 tokenId)
        public
        view
        returns (uint8 index_)
    {
        //32 * 8 = 256 - each uint256 holds the data of 32 tokens . 8 bits each.

        uint256 mappingIndex = tokenId / 32;

        uint256 compressedRegister = _tokenTierMappingCompressed[mappingIndex];

        //use 31 instead of 32 to account for the '0x' in the start.
        //the '31 -' reverses our bytes order which is necessary

        uint256 offset = ((31 - (tokenId % 32)) * 8);

        uint8 tierIndex = uint8((compressedRegister >> offset));

        return tierIndex;
    }

    function getTierHashes(uint256 tierIndex)
        external
        view
        returns (string[] memory)
    {
        return hashes[tierIndex];
    }

    /**
     * @notice Adds a new Tier to be minted with the given information.
     * @dev It auto increments the index of the next tier to add.
     * @param newTier Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTier(uint256 index, Tier memory newTier)
        external
        onlyAdmin
        returns (bool)
    {
        baseLoanSizes[index] = newTier.baseLoanSize;
        hashes[index] = newTier.hashes;
        contributionAssets[index] = newTier.contributionAsset;
        contributionSizes[index] = newTier.contributionSize;
        contributionMultipliers[index] = newTier.contributionMultiplier;

        return true;
    }

    /**
     * @notice Sets the tiers for each tokenId using compressed data.
     * @param tiersMapping Information about the new tiers to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setAllTokenTierMappings(uint256[] memory tiersMapping)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            !_tokenTierMappingCompressedSet,
            "TellerNFTDictionary: token tier mapping already set"
        );
        for (uint256 i = 0; i < tiersMapping.length; i++) {
            _tokenTierMappingCompressed[i] = tiersMapping[i];
        }

        _tokenTierMappingCompressedSet = true;
        return true;
    }

    /**
     * @notice Sets the tiers for each tokenId using compressed data.
     * @param index the mapping row, each holds data for 32 tokens
     * @param tierMapping Information about the new tier to add.
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTokenTierMapping(uint256 index, uint256 tierMapping)
        public
        onlyAdmin
        returns (bool)
    {
        _tokenTierMappingCompressed[index] = tierMapping;

        return true;
    }

    /**
     * @notice Sets a specific tier for a specific tokenId using compressed data.
     * @param tokenIds the NFT token Ids for which to add data
     * @param tokenTier the index of the tier that these tokenIds should have
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTokenTierForTokenIds(
        uint256[] calldata tokenIds,
        uint256 tokenTier
    ) public onlyAdmin returns (bool) {
        for (uint256 i; i < tokenIds.length; i++) {
            setTokenTierForTokenId(tokenIds[i], tokenTier);
        }

        return true;
    }

    /**
     * @notice Sets a specific tier for a specific tokenId using compressed data.
     * @param tokenId the NFT token Id for which to add data
     * @param tokenTier the index of the tier that these tokenIds should have
     *
     * Requirements:
     *  - Caller must have the {Admin} role
     */
    function setTokenTierForTokenId(uint256 tokenId, uint256 tokenTier)
        public
        onlyAdmin
        returns (bool)
    {
        uint256 mappingIndex = tokenId / 32;

        uint256 existingRegister = _tokenTierMappingCompressed[mappingIndex];

        uint256 offset = ((31 - (tokenId % 32)) * 8);

        uint256 updateMaskShifted =
            0x00000000000000000000000000000000000000000000000000000000000000FF <<
                offset;

        uint256 updateMaskShiftedNegated = ~updateMaskShifted;

        uint256 tokenTierShifted =
            ((0x0000000000000000000000000000000000000000000000000000000000000000 |
                tokenTier) << offset);

        uint256 existingRegisterClearedWithMask =
            existingRegister & updateMaskShiftedNegated;

        uint256 updatedRegister =
            existingRegisterClearedWithMask | tokenTierShifted;

        _tokenTierMappingCompressed[mappingIndex] = updatedRegister;

        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IStakeableNFT).interfaceId ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
        New methods for the dictionary
    */

    /**
     * @notice It returns Base Loan Size for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenBaseLoanSize(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return baseLoanSizes[tokenTier];
    }

    /**
     * @notice It returns Token URI Hash for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenURIHash(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        string[] memory tierImageHashes = hashes[tokenTier];
        return tierImageHashes[tokenId % (tierImageHashes.length)];
    }

    /**
     * @notice It returns Contribution Asset for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionAsset(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return contributionAssets[tokenTier];
    }

    /**
     * @notice It returns Contribution Size for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionSize(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return contributionSizes[tokenTier];
    }

    /**
     * @notice It returns Contribution Multiplier for a token ID.
     * @param tokenId ID of the token to get info.
     */
    function tokenContributionMultiplier(uint256 tokenId)
        public
        view
        override
        returns (uint8)
    {
        uint8 tokenTier = getTokenTierIndex(tokenId);

        return contributionMultipliers[tokenTier];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant ADMIN = keccak256("ADMIN");
bytes32 constant MINTER = keccak256("MINTER");

struct MerkleRoot {
    bytes32 merkleRoot;
    uint256 tierIndex;
}

struct ClaimNFTRequest {
    uint256 merkleIndex;
    uint256 nodeIndex;
    uint256 amount;
    bytes32[] merkleProof;
}

library DistributorEvents {
    event Claimed(address indexed account);

    event MerkleAdded(uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../store.sol";
import "../../../contexts/access-control/modifiers/authorized.sol";

import "../internal/distributor.sol";

// Utils
import { ClaimNFTRequest, ADMIN, DistributorEvents } from "../data.sol";

contract ent_claim_NFTDistributor_v1 is
    sto_NFTDistributor,
    int_distributor_NFT_v1,
    mod_authorized_AccessControl_v1
{
    /**
     * @notice Claims TellerNFTs for a given verifiable merkle proofs for each tier.
     * @param account The address to claim NFTs on behalf.
     * @param requests An array requests data generated from the merkle tree.
     *
     * Requirements:
     *  - Node in the merkle root must not be claimed already
     *  - Proof of the node must match the merkle tree
     */
    function claim(address account, ClaimNFTRequest[] calldata requests)
        external
    {
        for (uint256 i; i < requests.length; i++) {
            require(
                !_isClaimed(requests[i].merkleIndex, requests[i].nodeIndex),
                "TellerNFT Distributor: already claimed"
            );
            require(
                _verifyProof(account, requests[i]),
                "TellerNFT Distributor: invalid proof"
            );

            // Mark it claimed and send the token.
            _setClaimed(requests[i].merkleIndex, requests[i].nodeIndex);
            uint256 tierIndex =
                distributorStore().merkleRoots[requests[i].merkleIndex]
                    .tierIndex;
            for (uint256 j; j < requests[i].amount; j++) {
                distributorStore().nft.mint(tierIndex, account);
            }

            //Find the newly minted tokens and add to memory
            uint256[] memory postOwnedTokens =
                distributorStore().nft.getOwnedTokens(account);

            uint256[] memory newlyMintedTokenIds =
                new uint256[](requests[i].amount);

            uint256 offset = postOwnedTokens.length - requests[i].amount;

            for (uint256 k; k < requests[i].amount; k++) {
                newlyMintedTokenIds[k] = postOwnedTokens[k + offset];
            }

            //For each newly minted token, set the tier index in the Dictionary contract
            distributorStore().dictionary.setTokenTierForTokenIds(
                newlyMintedTokenIds,
                tierIndex
            );
        }

        emit DistributorEvents.Claimed(account);
    }

    function setNFTDictionaryAddress(address dictionary)
        external
        authorized(ADMIN, msg.sender)
    {
        distributorStore().dictionary = TellerNFTDictionary(dictionary);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../store.sol";

// Libraries
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Utils
import { ClaimNFTRequest } from "../data.sol";

contract int_distributor_NFT_v1 is sto_NFTDistributor {
    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleIndex Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     */
    function _setClaimed(uint256 merkleIndex, uint256 nodeIndex) internal {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        distributorStore().claimedBitMap[merkleIndex][claimedWordIndex] =
            distributorStore().claimedBitMap[merkleIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleIndex Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     * @return claimed_ returns a boolean to check if the tier has already been claimed
     */
    function _isClaimed(uint256 merkleIndex, uint256 nodeIndex)
        internal
        view
        returns (bool)
    {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        uint256 claimedWord =
            distributorStore().claimedBitMap[merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice it verifies the request's merkle proof with the merkle root in order to claim an NFT
     * @param account the account's address to be hashed and verified with the claim
     * @param request the request with the merkle proof to verify
     */
    function _verifyProof(address account, ClaimNFTRequest memory request)
        internal
        view
        returns (bool verified)
    {
        verified = MerkleProof.verify(
            request.merkleProof,
            distributorStore().merkleRoots[request.merkleIndex].merkleRoot,
            keccak256(
                abi.encodePacked(request.nodeIndex, account, request.amount)
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces
import "../ITellerNFT.sol";
import "../TellerNFTDictionary.sol";

// Utils
import { MerkleRoot } from "./data.sol";

abstract contract sto_NFTDistributor {
    struct DistributorStorage {
        ITellerNFT nft;
        MerkleRoot[] merkleRoots;
        mapping(uint256 => mapping(uint256 => uint256)) claimedBitMap;
        TellerNFTDictionary dictionary;
    }

    bytes32 constant POSITION = keccak256("teller_nft.distributor");

    function distributorStore()
        internal
        pure
        returns (DistributorStorage storage s)
    {
        bytes32 P = POSITION;
        assembly {
            s.slot := P
        }
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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