// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IdentityStore
 * @version 1.0.0
 * @author Francesco Sullo <[email protected]>
 * @dev Key/value store for identities
 */


// import "hardhat/console.sol";
import "./Application.sol";
import "./interfaces/IDeIDStore.sol";

// the store will be managed by DeIDClaimer and IdentityManager

contract DeIDStore is Application, IDeIDStore {

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint constant public maxNumberOfChains = 100;

    mapping(uint => mapping(uint => address)) private _addressById;
    mapping(uint => mapping(address => uint)) private _idByAddress;
    mapping(uint => uint) public totalIdentities;

    uint public lastTweedentityId;

    // Assigned during the deployment
    uint public chainProgressiveId;

    struct Extra {
        bool isSupported;
        bool isUnique;
        bool isImmutable;
    }

    mapping(bytes32 => Extra) public supportedExtras;
    mapping(uint => mapping(bytes32 => bytes)) public extras;
    mapping(uint => mapping(bytes32 => bytes32)) public uniqueExtras;
    mapping(bytes32 => mapping(bytes32 => bool)) public uniqueExtraExists;


    modifier isSupported(bytes32 key_, bool _isUnique) {
        require(
            supportedExtras[key_].isSupported,
            "Key not supported"
        );
        require(
            supportedExtras[key_].isUnique == _isUnique,
            "Invalid uniqueness"
        );
        _;
    }

    constructor(
        uint chainProgressiveId_
    )
    {
        require(
            chainProgressiveId_ < maxNumberOfChains,
            "chainProgressiveId_ must be < 100"
        );
        chainProgressiveId = chainProgressiveId_;
        addApp(0x7477697474657200000000000000000000000000000000000000000000000000);
        addApp(0x7265646469740000000000000000000000000000000000000000000000000000);
        addApp(0x696e7374616772616d0000000000000000000000000000000000000000000000);
    }

    function setExtraKey(
        bytes32 key_,
        bool unique_,
        bool immutable_
    ) external override
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        require(
            !supportedExtras[key_].isSupported,
            "Key already active"
        );
        supportedExtras[key_] = Extra(true, unique_, immutable_);
    }

    function getExtras(
        address address_,
        bytes32 key_
    ) public view override
    isSupported(key_, false)
    returns (bytes memory value_)
    {
        uint id = _idByAddress[0][address_];
        require(
            id != 0,
            "Account not found"
        );
        return extras[id][key_];
    }


    function setExtras(
        bytes32 key_,
        bytes calldata value_
    ) external override
    isSupported(key_, false)
    {
        uint id = _idByAddress[0][msg.sender];
        require(
            id != 0,
            "Account not found"
        );
        extras[id][key_] = value_;
        emit DataChanged(id, key_, value_);
    }


    function getUniqueExtras(
        address address_,
        bytes32 key_
    ) public view override
    isSupported(key_, true)
    returns (bytes32 value_)
    {
        uint id = _idByAddress[0][address_];
        require(
            id != 0,
            "Account not found"
        );
        return uniqueExtras[id][key_];
    }


    function setUniqueExtras(
        bytes32 key_,
        bytes32 value_
    ) external override
    isSupported(key_, true)
    {
        uint id = _idByAddress[0][msg.sender];
        require(
            id != 0,
            "Account not found"
        );
        if (supportedExtras[key_].isImmutable) {
            require(
                uniqueExtras[id][key_] == 0,
                "Immutable key"
            );
        } else {
            require(
                uniqueExtras[id][key_] != value_,
                "No change required"
            );
            if (uniqueExtras[id][key_] != 0) {
                uniqueExtraExists[key_][uniqueExtras[id][key_]] = false;
            }
        }
        uniqueExtraExists[key_][value_] = true;
        uniqueExtras[id][key_] = value_;
        emit UniqueDataChanged(id, key_, value_);
    }

    // solium-disable-next-line security/no-assign-params
    function setAddressAndIdByAppId(
        uint appId_,
        address address_,
        uint id_
    ) external override
    {
        require(hasRole(MANAGER_ROLE, msg.sender), "Not authorized");
        require(
            apps[appId_] > 0,
            "Unsupported app"
        );
        require(
            address_ != address(0),
            "address_ cannot be 0x0"
        );
        require(
            _idByAddress[appId_][address_] == 0,
            "Existing identity found for appId_/address_"
        );
        if (appId_ == 0) {
            lastTweedentityId++;
            id_ = lastTweedentityId;
        }
        require(
            _addressById[appId_][id_] == address(0),
            "Existing identity found for appId_/id_"
        );

        _idByAddress[appId_][address_] = id_;
        _addressById[appId_][id_] = address_;
        totalIdentities[appId_]++;
        emit IdentitySet(appId_, id_, address_);
    }


    function updateAddressByAppId(
        uint appId_,
        address oldAddress_,
        address newAddress_
    ) external override
    {
        require(hasRole(MANAGER_ROLE, msg.sender), "Not authorized");
        require(
            newAddress_ != address(0),
            "newAddress_ cannot be 0x0"
        );
        require(
            newAddress_ != oldAddress_,
            "No change required"
        );
        require(
            _idByAddress[appId_][oldAddress_] != 0,
            "No identity found for appId_/oldAddress_"
        );
        require(
            _idByAddress[appId_][newAddress_] == 0,
            "Existing identity found for appId_/newAddress_"
        );

        uint id = _idByAddress[appId_][oldAddress_];
        _idByAddress[appId_][newAddress_] = id;
        _addressById[appId_][id] = newAddress_;
        delete _idByAddress[appId_][oldAddress_];
        emit IdentityUpdated(appId_, id, newAddress_);
    }


    function profile(
        address address_
    ) public view override
    returns (uint[] memory)
    {
        uint[] memory ids = new uint[](lastAppId);
        for (uint i = 0; i <= lastAppId; i++) {
            if (_idByAddress[i][address_] != 0) {
                ids[i] = _idByAddress[i][address_];
            }
        }
        return ids;
    }


    function profile() public view override
    returns (uint[] memory)
    {
        return profile(msg.sender);
    }


    function idByAddress(
        uint appId_,
        address address_
    ) public view override
    returns (uint)
    {
        return _idByAddress[appId_][address_];
    }


    function addressById(
        uint appId_,
        uint id_
    ) public view override
    returns (address)
    {
        return _addressById[appId_][id_];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Application
 * @version 1.0.0
 * @author Francesco Sullo <[email protected]>
 * @dev Key/value store for apps
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
// import "hardhat/console.sol";

import "./interfaces/IApplication.sol";

contract Application is AccessControl, IApplication {

    uint constant public maxNumberOfApps = 100;

    uint public lastAppId;
    mapping(uint => bytes32) public apps;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        apps[0] = 0x64656661756c7400000000000000000000000000000000000000000000000000;
    }

    function addApp(
        bytes32 nickname_
    ) public override
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        require(
            nickname_ > 0,
            "Empty nickname"
        );
        require(
            lastAppId < maxNumberOfApps - 1,
            "Limit reached. New apps not allowed"
        );

        lastAppId++;
        apps[lastAppId] = nickname_;
        emit AppAdded(lastAppId, nickname_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDeIDStore
 * @author Francesco Sullo <[email protected]>
 */


interface IDeIDStore {
    event IdentitySet(uint indexed appId_, uint indexed _id, address indexed address_);

    event IdentityUpdated(uint indexed appId_, uint indexed _id, address indexed address_);

    event DataChanged(uint indexed _id, bytes32 indexed key, bytes value);

    event UniqueDataChanged(uint indexed _id, bytes32 indexed key, bytes32 value);

    function setExtraKey(bytes32 key_, bool unique_, bool immutable_) external;

    function getExtras(address address_, bytes32 key_) external view returns (bytes memory value_);

    function setExtras(bytes32 key_, bytes calldata value_) external;

    function getUniqueExtras(address address_, bytes32 key_) external view returns (bytes32 value_);

    function setUniqueExtras(bytes32 key_, bytes32 value_) external;

    function setAddressAndIdByAppId(uint appId_, address address_, uint id_) external;

    function updateAddressByAppId(uint appId_, address oldAddress_, address newAddress_) external;

    function profile(address address_) external view returns (uint[] memory);

    function profile() external view returns (uint[] memory);

    function idByAddress(uint appId_, address address_) external view returns (uint);

    function addressById(uint appId_, uint id_) external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IApplication
 * @author Francesco Sullo <[email protected]>
 * @dev Key/value store for apps
 */


interface IApplication {

    event AppAdded(uint indexed id, bytes32 indexed nickname);

    function addApp(bytes32 nickname_) external;

}

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

{
  "optimizer": {
    "enabled": true,
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