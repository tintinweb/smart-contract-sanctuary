// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SharkGenes is AccessControl {
    uint8 GENES_VERSION = 1;

    // types
    uint8 public constant TYPE_SHARK = 0;
    uint8 public constant TYPE_SKIN = 1;

    // numerators
    uint256 hundredNumerator = 100;

    // probabilities
    uint8 public constant VARIATION_RATE = 5;
    uint8 public constant ETHNIC_RATE = 50;
    uint32[] public PART_GENETIC_RATE = [37500, 9375, 3125, 37500, 9375, 3125];
    uint32 public constant PART_GENETIC_RATE_TOTAL = 100000;

    // positions
    uint8 public constant POS_VERSION = 0;
    uint8 public constant POS_ETHNIC = 1;
    uint8 public constant POS_STAR = 2;
    uint8 public constant POS_BODY = 3;

    // limit
    uint8 public MAX_STAR = 6;

    // ranges
    uint8 public constant RANGE_ETHNIC = 6;
    uint8 public constant RANGE_BODY = 4;
    uint8[] public RANGE_HEAD = [6, 6, 6, 6, 6, 6];
    uint8[] public RANGE_MOUTH = [4, 4, 4, 4, 4, 4];
    uint8[] public RANGE_GORSAL = [6, 6, 6, 6, 6, 6];
    uint8[] public RANGE_TAIL = [6, 6, 6, 6, 6, 6];
    uint8[] public RANGE_VENTRAL = [4, 4, 4, 4, 4, 4];
    uint8[] public RANGE_NECK = [4, 4, 4, 4, 4, 4];

    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event SetMaxStar(uint8 indexed starLimit);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function setMaxStar(uint8 starLimit) external onlyRole(MANAGER_ROLE) {
        require(starLimit != MAX_STAR);
        MAX_STAR = starLimit;

        emit SetMaxStar(starLimit);
    }

    function born() external view onlyRole(WHITELIST_ROLE) returns (uint256) {
        uint256 seed;

        uint8[32] memory _genes;
        // version
        _genes[POS_VERSION] = _formatVersion(GENES_VERSION, TYPE_SHARK);
        // ethnic
        _genes[POS_ETHNIC] = uint8(_rand(RANGE_ETHNIC, seed++));
        // star
        _genes[POS_STAR] = 1;
        // body
        _genes[POS_BODY] = uint8(_rand(RANGE_BODY, seed++));
        // head
        (_genes[4], _genes[5],_genes[6]) = _genParts(RANGE_HEAD, new uint8[](0), seed++);
        // mouth
        (_genes[7], _genes[8],_genes[9]) = _genParts(RANGE_MOUTH, new uint8[](0), seed++);
        // gorsal
        (_genes[10], _genes[11],_genes[12]) = _genParts(RANGE_GORSAL, new uint8[](0), seed++);
        // tail
        (_genes[13], _genes[14],_genes[15]) = _genParts(RANGE_TAIL, new uint8[](0), seed++);
        // ventral
        (_genes[16], _genes[17],_genes[18]) = _genParts(RANGE_VENTRAL, new uint8[](0), seed++);
        // neck
        (_genes[19], _genes[20],_genes[21]) = _genParts(RANGE_NECK, new uint8[](0), seed++);

        return _format(_genes);
    }

    function breeding(
        uint256 sireGenes,
        uint256 matronGenes
    )
        external
        view
        onlyRole(WHITELIST_ROLE)
        returns (uint256)
    {
        uint256 seed;
        
        uint8[32] memory sire = _parse(sireGenes);
        uint8[32] memory matron = _parse(matronGenes);
        _checkBreedingCondition(sire, matron);

        uint8[32] memory _genes;
        // version
        _genes[POS_VERSION] = _formatVersion(GENES_VERSION, TYPE_SHARK);
        //star
        _genes[POS_STAR] = sire[POS_STAR] + 1;
        // ethnic & body
        if (uint8(_rand(hundredNumerator, seed++)) < ETHNIC_RATE) {
            _genes[POS_ETHNIC] = sire[POS_ETHNIC];
            _genes[POS_BODY] = sire[POS_BODY];
        } else {
            _genes[POS_ETHNIC] = matron[POS_ETHNIC];
            _genes[POS_BODY] = matron[POS_BODY];
        }
        // head
        uint8[] memory parentParts = new uint8[](6);
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[4],sire[5],sire[6],matron[4],matron[5],matron[6]);
        (_genes[4], _genes[5],_genes[6]) = _genParts(RANGE_HEAD, parentParts, seed++);
        // mouth
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[7],sire[8],sire[9],matron[7],matron[8],matron[9]);
        (_genes[7], _genes[8],_genes[9]) = _genParts(RANGE_MOUTH, parentParts, seed++);
        // gorsal
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[10],sire[11],sire[12],matron[10],matron[11],matron[12]);
        (_genes[10], _genes[11],_genes[12]) = _genParts(RANGE_GORSAL, parentParts, seed++);
        // tail
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[13],sire[14],sire[15],matron[13],matron[14],matron[15]);
        (_genes[13], _genes[14],_genes[15]) = _genParts(RANGE_TAIL, parentParts, seed++);
        // ventral
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[16],sire[17],sire[18],matron[16],matron[17],matron[18]);
        (_genes[16], _genes[17],_genes[18]) = _genParts(RANGE_VENTRAL, parentParts, seed++);
        // neck
        (parentParts[0],parentParts[1],parentParts[2],parentParts[3],parentParts[4],parentParts[5]) = (sire[19],sire[20],sire[21],matron[19],matron[20],matron[21]);
        (_genes[19], _genes[20],_genes[21]) = _genParts(RANGE_NECK, parentParts, seed++);

        return _format(_genes);
    }

    function _genParts(
        uint8[] memory range,
        uint8[] memory parentParts,
        uint256 seed
    )
        internal
        view
        returns (uint8 D, uint8 R1, uint8 R2)
    {
        seed *= 10;
        if (parentParts.length == 0) {
            return _genNewParts(range, seed);
        }
        return _genGeneticsParts(range, parentParts, seed);
    }

    function _genGeneticsParts(
        uint8[] memory range,
        uint8[] memory parentParts,
        uint256 seed
    )
        internal
        view
        returns (uint8 D, uint8 R1, uint8 R2)
    {
        seed *= 10;

        uint8[] memory parts = _drawParts(parentParts, 3, seed++);
        for (uint8 i = 0; i < 3; i++) {
            if (_checkVariation(seed++)) {
                parts[i] = _genNewPart(range, seed++);
            }
        }
        return (parts[0], parts[1], parts[2]);
    }

    function _genNewParts(
        uint8[] memory range,
        uint256 seed
    )
        internal
        view 
        returns (uint8 D, uint8 R1, uint8 R2)
    {
        seed *= 10;
        return (
            _genNewPart(range, seed++),
            _genNewPart(range, seed++),
            _genNewPart(range, seed++)
        );
    }

    function _genNewPart(uint8[] memory range,  uint256 seed) internal view returns (uint8 part) {
        seed *= 10;
        uint8 part1 = uint8(_rand(range.length, seed++));
        uint8 part2 = uint8(_rand(range[part1], seed++));
        return part1 << 5 | part2;
    }

    function _drawParts(uint8[] memory parentParts, uint8 n, uint256 seed)
        internal
        view 
        returns(uint8[] memory)
    {
        assert(parentParts.length >= n);
        assert(parentParts.length == PART_GENETIC_RATE.length);

        uint8[] memory result = new uint8[](n);

        seed *= 10;

        uint32[6] memory rates = [
            PART_GENETIC_RATE[0],
            PART_GENETIC_RATE[1],
            PART_GENETIC_RATE[2],
            PART_GENETIC_RATE[3],
            PART_GENETIC_RATE[4],
            PART_GENETIC_RATE[5]
        ];
        uint256 total = PART_GENETIC_RATE_TOTAL;
        uint256 sum;

        for (uint i = 0; i < n; i++) {
            uint256 randVal = _rand(total, seed++); // 2000

            sum = 0;
            for (uint8 j = 0; j < parentParts.length; j++) {
                sum += rates[j];
                if (randVal < sum) {
                    result[i] = parentParts[j];

                    total -= rates[j];
                    rates[j] = 0;

                    break;
                }
            }
        }
        return result;
    }

    function _checkVariation(uint256 seed) internal view returns(bool) {
        return _rand(hundredNumerator, seed) < VARIATION_RATE;
    }

    function _checkBreedingCondition(uint8[32] memory sire, uint8[32] memory matron) internal view {
        require(sire[POS_STAR] == matron[POS_STAR], "Breeding: star not matched");
        require(sire[POS_STAR] < MAX_STAR, "Breeding: star limit");
        // only shark can be breed
        (,uint8 sireType) = _parseVersion(sire[POS_VERSION]);
        (,uint8 matronType) = _parseVersion(sire[POS_VERSION]);
        require(sireType == TYPE_SHARK && matronType == TYPE_SHARK, "Breeding: only shark");
    }

    function _parse(uint256 genes) internal pure returns(uint8[32] memory) {
        uint8[32] memory parts;
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = uint8(genes >> ((parts.length - i - 1) * 8));
        }
        return parts;
    }

    function _parsePart(uint256 genes, uint8 index) internal pure returns (uint8) {
        return uint8((genes << index * 8) >> 248);
    }

    function _parseVersion(
        uint8 version
    )
        internal 
        pure 
        returns(uint8, uint8)
    {
        uint8 _version = version >> 4;
        uint8 _type = version & 15;

        return (_version, _type);
    }

    function _format(uint8[32] memory parts) internal pure returns(uint256) {
        uint256 genes;
        for (uint i = 0; i < parts.length; i++) {
            genes |= (uint256(parts[i]) << 256 - (i + 1) * 8);
        }
        return genes;
    }

    function _formatVersion(
        uint8 _version,
        uint8 _type
    )
        internal 
        pure 
        returns(uint8)
    {
        return _version << 4 | _type;
    }

    function _rand(uint256 length, uint256 seed) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp +
            block.difficulty +
            uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp +
            block.gaslimit +
            uint256(keccak256(abi.encodePacked(msg.sender))) / block.timestamp +
            seed
        ))) % length;
    }
}

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