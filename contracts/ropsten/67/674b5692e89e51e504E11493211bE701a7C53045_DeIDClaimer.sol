// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title DeIDClaimer
 * @version 1.0.0
 * @author Francesco Sullo <[email protected]>
 * @dev Manages identity claims
 */

import "./StoreCaller.sol";
import "./interfaces/IDeIDClaimer.sol";

contract DeIDClaimer is StoreCaller, IDeIDClaimer {

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint public probationTime = 1 weeks;
    uint public afterProbationTime = 1 weeks;

    mapping(uint => mapping(uint => Claim)) private _claimById;
    mapping(uint => mapping(address => uint)) private _claimByAddress;


    constructor(
        address store_
    )
    StoreCaller(store_)
    {
    }


    function updateProbationTimes(
        uint probationTime_,
        uint afterProbationTime_
    ) external override
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        probationTime = probationTime_;
        afterProbationTime = afterProbationTime_;
        emit ProbationTimesUpdated(probationTime_, afterProbationTime_);
    }


    // getters

    function activeClaimsByOrAgainst()
    public view override
    returns (FullClaim[] memory)
    {
        FullClaim[] memory claims;
        uint j;
        for (uint appId = 1; appId <= store.lastAppId(); appId++) {
            uint id = store.idByAddress(appId, msg.sender);
            if (id == 0) {
                id = _claimByAddress[appId][msg.sender];
            }
            if (id != 0) {
                // solium-disable-next-line security/no-block-members
                if (_claimById[appId][id].when > block.timestamp - probationTime - afterProbationTime) {
                    claims[j] = FullClaim(_claimById[appId][id].claimer, appId, id, _claimById[appId][id].when);
                    j++;
                }
            }
        }
        return claims;
    }


    // setters

    function setClaim(
        uint appId_,
        uint id_,
        address claimer_
    ) external override
    onlyIfStoreSet
    {
        require(hasRole(MANAGER_ROLE, msg.sender), "Not authorized");
        require(
            appId_ > 0,
            "Tweedentity id can't be claimed"
        );
        require(
            claimer_ != address(0),
            "claimer_ cannot be 0x0"
        );
        require(
            store.addressById(appId_, id_) != address(0),
            "Claimed identity not found"
        );
        require(
            store.idByAddress(appId_, claimer_) == 0,
            "Claimer owns some identity"
        );
        require(
            // solium-disable-next-line security/no-block-members
            _claimById[appId_][id_].claimer == address(0) || _claimById[appId_][id_].when < block.timestamp - probationTime - afterProbationTime,
            "Active claim found for identity"
        );
        require(
            // solium-disable-next-line security/no-block-members
            _claimByAddress[appId_][claimer_] == 0 || _claimById[appId_][_claimByAddress[appId_][claimer_]].when < block.timestamp - probationTime - afterProbationTime,
            "Active claim found for claimer"
        );
        // solium-disable-next-line security/no-block-members
        _claimById[appId_][id_] = Claim(claimer_, block.timestamp);
        _claimByAddress[appId_][claimer_] = id_;
        emit ClaimStarted(appId_, id_, claimer_);
    }


    function cancelActiveClaim(
        uint appId_
    ) external override
    onlyIfStoreSet
    {
        require(
            _claimByAddress[appId_][msg.sender] != 0,
            "Claim by msg.sender not found"
        );

        uint id = _claimByAddress[appId_][msg.sender];
        delete _claimById[appId_][id];
        delete _claimByAddress[appId_][msg.sender];
        emit ClaimCanceled(appId_, id, msg.sender);
    }


    function setClaimedIdentity(
        uint appId_,
        uint id_,
        address claimer_
    ) external override
    onlyIfStoreSet
    {
        require(hasRole(MANAGER_ROLE, msg.sender), "Not authorized");
        require(
            store.idByAddress(appId_, claimer_) == 0,
            "Claimer owns another identity"
        );
        require(
            _claimById[appId_][id_].claimer == claimer_,
            "Claim not found"
        );
        require(
            // solium-disable-next-line security/no-block-members
            _claimById[appId_][id_].when < block.timestamp - probationTime,
            "Probation time not passed yet"
        );
        require(
            // solium-disable-next-line security/no-block-members
            _claimById[appId_][id_].when > block.timestamp - probationTime - afterProbationTime,
            "Claim is expired"
        );

        store.updateAddressByAppId(appId_, store.addressById(appId_, id_), claimer_);
    }


    function claimByAddress(
        uint appId_,
        address address_
    ) public view override
    returns (uint)
    {
        return _claimByAddress[appId_][address_];
    }


    function claimById(
        uint appId_,
        uint id_
    ) public view override
    returns (Claim memory)
    {
        return _claimById[appId_][id_];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title StoreCaller
 * @version 1.0.0
 * @author Francesco Sullo <[email protected]>
 * @dev Manages identities
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IStoreCaller.sol";

interface IStoreMinimal {

    function totalIdentities() external view returns (uint);

    function lastAppId() external view returns (uint);

    function chainProgressiveId() external view returns (uint);

    function maxNumberOfChains() external view returns (uint);

    function maxNumberOfApps() external view returns (uint);

    function idByAddress(uint appId_, address address_) external view returns (uint);

    function addressById(uint appId_, uint id_) external view returns (address);

    function setAddressAndIdByAppId(uint appId_, address address_, uint id_) external;

    function setNickname(bytes32 nickname_) external;

    function updateAddressByAppId(uint appId_, address oldAddress_, address newAddress_) external;
}

contract StoreCaller is AccessControl, IStoreCaller {

    IStoreMinimal public store;

    bool public storeSet;

    modifier onlyIfStoreSet() {
        require(
            storeSet,
            "Store not set yet"
        );
        _;
    }

    constructor(
        address store_
    )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setStore(store_);
    }

    function setStore(
        address store_
    ) public override
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        if (!storeSet && store_ != address(0)) {
            store = IStoreMinimal(store_);
            storeSet = true;
            emit StoreSet(store_);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title IDeIDClaimer
 * @author Francesco Sullo <[email protected]>
 */

interface IDeIDClaimer {

    event ClaimStarted(uint indexed appId, uint indexed id, address indexed claimer);

    event ClaimCompleted(uint indexed appId, uint indexed id, address indexed claimer);

    event ClaimCanceled(uint indexed appId, uint indexed id, address indexed claimer);

    event ProbationTimesUpdated(uint probationTime, uint afterProbationTime);

    struct Claim {
        address claimer;
        uint when;
    }

    struct FullClaim {
        address claimer;
        uint appId;
        uint id;
        uint when;
    }

    function updateProbationTimes(uint probationTime_, uint afterProbationTime_) external;

    function activeClaimsByOrAgainst() external view returns (FullClaim[] memory);

    function setClaim(uint appId_, uint id_, address claimer_) external;

    function cancelActiveClaim(uint appId_) external;

    function setClaimedIdentity(uint appId_, uint id_, address claimer_) external;

    function claimByAddress(uint appId_, address address_) external view returns (uint);

    function claimById(uint appId_, uint id_) external view returns (Claim memory);

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
 * @title IStoreCaller
 * @author Francesco Sullo <[email protected]>
 */


interface IStoreCaller {
    event StoreSet(address indexed _store);

    function setStore(address store_) external;

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