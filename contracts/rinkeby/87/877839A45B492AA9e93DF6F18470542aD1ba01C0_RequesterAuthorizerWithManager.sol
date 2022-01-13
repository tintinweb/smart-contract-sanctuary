/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File verify/0.3.1/@api3/airnode-protocol/contracts/access-control-registry/RoleDeriver.sol

pragma solidity 0.8.9;

/// @title Contract that implements the AccessControlRegistry role derivation
/// logic
/// @notice If a contract interfaces with AccessControlRegistry and needs to
/// derive roles, it should inherit this contract instead of re-implementing
/// the logic
contract RoleDeriver {
    /// @notice Derives the root role of the manager
    /// @param manager Manager address
    /// @return rootRole Root role
    function _deriveRootRole(address manager)
        internal
        pure
        returns (bytes32 rootRole)
    {
        rootRole = keccak256(abi.encodePacked(manager));
    }

    /// @notice Derives the role using its admin role and description
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param description Human-readable description of the role
    /// @return role Role
    function _deriveRole(bytes32 adminRole, string memory description)
        internal
        pure
        returns (bytes32 role)
    {
        role = _deriveRole(adminRole, keccak256(abi.encodePacked(description)));
    }

    /// @notice Derives the role using its admin role and description hash
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param descriptionHash Hash of the human-readable description of the
    /// role
    /// @return role Role
    function _deriveRole(bytes32 adminRole, bytes32 descriptionHash)
        internal
        pure
        returns (bytes32 role)
    {
        role = keccak256(abi.encodePacked(adminRole, descriptionHash));
    }
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/access-control-registry/interfaces/IAccessControlClient.sol

pragma solidity 0.8.9;

interface IAccessControlClient {
    function accessControlRegistry() external view returns (address);
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/access-control-registry/AccessControlClient.sol

pragma solidity 0.8.9;

contract AccessControlClient is IAccessControlClient {
    /// @notice Address of the AccessControlRegistry contract that keeps the
    /// roles
    address public immutable override accessControlRegistry;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    constructor(address _accessControlRegistry) {
        require(_accessControlRegistry != address(0), "ACR address zero");
        accessControlRegistry = _accessControlRegistry;
    }
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/whitelist/interfaces/IWhitelistRoles.sol

pragma solidity 0.8.9;

interface IWhitelistRoles {
    function adminRoleDescription() external view returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function INDEFINITE_WHITELISTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/whitelist/WhitelistRoles.sol

pragma solidity 0.8.9;



/// @title Contract that implements generic AccessControlRegistry roles for a
/// whitelist contract
contract WhitelistRoles is RoleDeriver, AccessControlClient, IWhitelistRoles {
    // There are four roles implemented in this contract:
    // Root
    // └── (1) Admin (can grant and revoke the roles below)
    //     ├── (2) Whitelist expiration extender
    //     ├── (3) Whitelist expiration setter
    //     └── (4) Indefinite whitelister
    // Their IDs are derived from the descriptions below. Refer to
    // AccessControlRegistry for more information.
    string public override adminRoleDescription;
    string
        public constant
        override WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION =
        "Whitelist expiration extender";
    string
        public constant
        override WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION =
        "Whitelist expiration setter";
    string public constant override INDEFINITE_WHITELISTER_ROLE_DESCRIPTION =
        "Indefinite whitelister";
    bytes32 internal adminRoleDescriptionHash;
    bytes32
        internal constant WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION_HASH =
        keccak256(
            abi.encodePacked(WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION)
        );
    bytes32
        internal constant WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION_HASH =
        keccak256(
            abi.encodePacked(WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION)
        );
    bytes32 internal constant INDEFINITE_WHITELISTER_ROLE_DESCRIPTION_HASH =
        keccak256(abi.encodePacked(INDEFINITE_WHITELISTER_ROLE_DESCRIPTION));

    /// @dev Contracts deployed with the same admin role descriptions will have
    /// the same roles, meaning that granting an account a role will authorize
    /// it in multiple contracts. Unless you want your deployed contract to
    /// reuse the role configuration of another contract, use a unique admin
    /// role description.
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription
    ) AccessControlClient(_accessControlRegistry) {
        require(
            bytes(_adminRoleDescription).length > 0,
            "Admin role description empty"
        );
        adminRoleDescription = _adminRoleDescription;
        adminRoleDescriptionHash = keccak256(
            abi.encodePacked(_adminRoleDescription)
        );
    }

    /// @notice Derives the admin role for the specific manager address
    /// @param manager Manager address
    /// @return adminRole Admin role
    function _deriveAdminRole(address manager)
        internal
        view
        returns (bytes32 adminRole)
    {
        adminRole = _deriveRole(
            _deriveRootRole(manager),
            adminRoleDescriptionHash
        );
    }

    /// @notice Derives the whitelist expiration extender role for the specific
    /// manager address
    /// @param manager Manager address
    /// @return whitelistExpirationExtenderRole Whitelist expiration extender
    /// role
    function _deriveWhitelistExpirationExtenderRole(address manager)
        internal
        view
        returns (bytes32 whitelistExpirationExtenderRole)
    {
        whitelistExpirationExtenderRole = _deriveRole(
            _deriveAdminRole(manager),
            WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION_HASH
        );
    }

    /// @notice Derives the whitelist expiration setter role for the specific
    /// manager address
    /// @param manager Manager address
    /// @return whitelistExpirationSetterRole Whitelist expiration setter role
    function _deriveWhitelistExpirationSetterRole(address manager)
        internal
        view
        returns (bytes32 whitelistExpirationSetterRole)
    {
        whitelistExpirationSetterRole = _deriveRole(
            _deriveAdminRole(manager),
            WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION_HASH
        );
    }

    /// @notice Derives the indefinite whitelister role for the specific
    /// manager address
    /// @param manager Manager address
    /// @return indefiniteWhitelisterRole Indefinite whitelister role
    function _deriveIndefiniteWhitelisterRole(address manager)
        internal
        view
        returns (bytes32 indefiniteWhitelisterRole)
    {
        indefiniteWhitelisterRole = _deriveRole(
            _deriveAdminRole(manager),
            INDEFINITE_WHITELISTER_ROLE_DESCRIPTION_HASH
        );
    }
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/whitelist/interfaces/IWhitelistRolesWithManager.sol

pragma solidity 0.8.9;

interface IWhitelistRolesWithManager is IWhitelistRoles {
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);

    function whitelistExpirationExtenderRole() external view returns (bytes32);

    function whitelistExpirationSetterRole() external view returns (bytes32);

    function indefiniteWhitelisterRole() external view returns (bytes32);
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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


// File verify/0.3.1/@api3/airnode-protocol/contracts/access-control-registry/interfaces/IAccessControlRegistry.sol

pragma solidity 0.8.9;

interface IAccessControlRegistry is IAccessControl {
    event InitializedManager(bytes32 indexed rootRole, address indexed manager);

    event InitializedRole(
        bytes32 indexed role,
        bytes32 indexed adminRole,
        string description,
        address sender
    );

    function initializeManager(address manager) external;

    function initializeRole(bytes32 adminRole, string calldata description)
        external
        returns (bytes32 role);

    function initializeAndGrantRoles(
        bytes32[] calldata adminRoles,
        string[] calldata descriptions,
        address[] calldata accounts
    ) external returns (bytes32[] memory roles);

    function deriveRootRole(address manager)
        external
        pure
        returns (bytes32 rootRole);

    function deriveRole(bytes32 adminRole, string calldata description)
        external
        pure
        returns (bytes32 role);
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/whitelist/WhitelistRolesWithManager.sol

pragma solidity 0.8.9;



/// @title Contract that implements AccessControlRegistry roles for a whitelist
/// contract controlled by a single manager account
contract WhitelistRolesWithManager is
    WhitelistRoles,
    IWhitelistRolesWithManager
{
    /// @notice Address of the manager that manages the related
    /// AccessControlRegistry roles
    address public immutable override manager;

    // Since there will be a single manager, we can derive the roles beforehand
    bytes32 public immutable override adminRole;
    bytes32 public immutable override whitelistExpirationExtenderRole;
    bytes32 public immutable override whitelistExpirationSetterRole;
    bytes32 public immutable override indefiniteWhitelisterRole;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    ) WhitelistRoles(_accessControlRegistry, _adminRoleDescription) {
        require(_manager != address(0), "Manager address zero");
        manager = _manager;
        adminRole = _deriveAdminRole(_manager);
        whitelistExpirationExtenderRole = _deriveWhitelistExpirationExtenderRole(
            _manager
        );
        whitelistExpirationSetterRole = _deriveWhitelistExpirationSetterRole(
            _manager
        );
        indefiniteWhitelisterRole = _deriveIndefiniteWhitelisterRole(_manager);
    }

    /// @dev Returns if the account has the whitelist expiration extender role
    /// or is the manager
    /// @param account Account address
    /// @return If the account has the whitelist extender role or is the
    /// manager
    function hasWhitelistExpirationExtenderRoleOrIsManager(address account)
        internal
        view
        returns (bool)
    {
        return
            manager == account ||
            IAccessControlRegistry(accessControlRegistry).hasRole(
                whitelistExpirationExtenderRole,
                account
            );
    }

    /// @dev Returns if the account has the whitelist expriation setter role or
    /// is the manager
    /// @param account Account address
    /// @return If the account has the whitelist setter role or is the
    /// manager
    function hasWhitelistExpirationSetterRoleOrIsManager(address account)
        internal
        view
        returns (bool)
    {
        return
            manager == account ||
            IAccessControlRegistry(accessControlRegistry).hasRole(
                whitelistExpirationSetterRole,
                account
            );
    }

    /// @dev Returns if the account has the indefinite whitelister role or is the
    /// manager
    /// @param account Account address
    /// @return If the account has the indefinite whitelister role or is the
    /// manager
    function hasIndefiniteWhitelisterRoleOrIsManager(address account)
        internal
        view
        returns (bool)
    {
        return
            manager == account ||
            IAccessControlRegistry(accessControlRegistry).hasRole(
                indefiniteWhitelisterRole,
                account
            );
    }
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/whitelist/Whitelist.sol

pragma solidity 0.8.9;

/// @title Contract that implements temporary and permanent whitelists for
/// multiple services identified with a hash
/// @notice This contract implements two kinds of whitelisting:
///   (1) Temporary, ends when the expiration timestamp is in the past
///   (2) Indefinite, ends when the indefinite whitelist count is zero
/// Multiple senders can idefinitely whitelist/unwhitelist independently. The
/// user will be considered whitelisted as long as there is at least one active
/// indefinite whitelisting.
/// @dev The interface of this contract is not implemented. It should be
/// inherited and its functions should be exposed with a sort of an
/// authorization scheme.
contract Whitelist {
    struct WhitelistStatus {
        uint64 expirationTimestamp;
        uint192 indefiniteWhitelistCount;
    }

    mapping(bytes32 => mapping(address => WhitelistStatus))
        internal serviceIdToUserToWhitelistStatus;

    mapping(bytes32 => mapping(address => mapping(address => bool)))
        internal serviceIdToUserToSetterToIndefiniteWhitelistStatus;

    /// @notice Extends the expiration of the temporary whitelist of the user
    /// for the service
    /// @param serviceId Service ID
    /// @param user User address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function _extendWhitelistExpiration(
        bytes32 serviceId,
        address user,
        uint64 expirationTimestamp
    ) internal {
        require(
            expirationTimestamp >
                serviceIdToUserToWhitelistStatus[serviceId][user]
                    .expirationTimestamp,
            "Does not extend expiration"
        );
        serviceIdToUserToWhitelistStatus[serviceId][user]
            .expirationTimestamp = expirationTimestamp;
    }

    /// @notice Sets the expiration of the temporary whitelist of the user for
    /// the service
    /// @dev Unlike `extendWhitelistExpiration()`, this can hasten expiration
    /// @param serviceId Service ID
    /// @param user User address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function _setWhitelistExpiration(
        bytes32 serviceId,
        address user,
        uint64 expirationTimestamp
    ) internal {
        serviceIdToUserToWhitelistStatus[serviceId][user]
            .expirationTimestamp = expirationTimestamp;
    }

    /// @notice Sets the indefinite whitelist status of the user for the
    /// service
    /// @dev As long as at least there is at least one account that has set the
    /// indefinite whitelist status of the user for the service as true, the
    /// user will be considered whitelisted.
    /// @param serviceId Service ID
    /// @param user User address
    /// @param status Indefinite whitelist status
    function _setIndefiniteWhitelistStatus(
        bytes32 serviceId,
        address user,
        bool status
    ) internal returns (uint192 indefiniteWhitelistCount) {
        indefiniteWhitelistCount = serviceIdToUserToWhitelistStatus[serviceId][
            user
        ].indefiniteWhitelistCount;
        if (
            status &&
            !serviceIdToUserToSetterToIndefiniteWhitelistStatus[serviceId][
                user
            ][msg.sender]
        ) {
            serviceIdToUserToSetterToIndefiniteWhitelistStatus[serviceId][user][
                msg.sender
            ] = true;
            indefiniteWhitelistCount++;
            serviceIdToUserToWhitelistStatus[serviceId][user]
                .indefiniteWhitelistCount = indefiniteWhitelistCount;
        } else if (
            !status &&
            serviceIdToUserToSetterToIndefiniteWhitelistStatus[serviceId][user][
                msg.sender
            ]
        ) {
            serviceIdToUserToSetterToIndefiniteWhitelistStatus[serviceId][user][
                msg.sender
            ] = false;
            indefiniteWhitelistCount--;
            serviceIdToUserToWhitelistStatus[serviceId][user]
                .indefiniteWhitelistCount = indefiniteWhitelistCount;
        }
    }

    /// @notice Revokes the indefinite whitelist status granted to the user for
    /// the service by a specific account
    /// @param serviceId Service ID
    /// @param user User address
    /// @param setter Setter of the indefinite whitelist status
    function _revokeIndefiniteWhitelistStatus(
        bytes32 serviceId,
        address user,
        address setter
    ) internal returns (bool revoked, uint192 indefiniteWhitelistCount) {
        indefiniteWhitelistCount = serviceIdToUserToWhitelistStatus[serviceId][
            user
        ].indefiniteWhitelistCount;
        if (
            serviceIdToUserToSetterToIndefiniteWhitelistStatus[serviceId][user][
                setter
            ]
        ) {
            serviceIdToUserToSetterToIndefiniteWhitelistStatus[serviceId][user][
                setter
            ] = false;
            indefiniteWhitelistCount--;
            serviceIdToUserToWhitelistStatus[serviceId][user]
                .indefiniteWhitelistCount = indefiniteWhitelistCount;
            revoked = true;
        }
    }

    /// @notice Returns if the user is whitelised to use the service
    /// @param serviceId Service ID
    /// @param user User address
    /// @return isWhitelisted If the user is whitelisted
    function userIsWhitelisted(bytes32 serviceId, address user)
        internal
        view
        returns (bool isWhitelisted)
    {
        WhitelistStatus
            storage whitelistStatus = serviceIdToUserToWhitelistStatus[
                serviceId
            ][user];
        return
            whitelistStatus.indefiniteWhitelistCount > 0 ||
            whitelistStatus.expirationTimestamp > block.timestamp;
    }
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/authorizers/interfaces/IAuthorizer.sol

pragma solidity 0.8.9;

interface IAuthorizer {
    function isAuthorized(
        bytes32 requestId,
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool);
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/authorizers/interfaces/IRequesterAuthorizer.sol

pragma solidity 0.8.9;

interface IRequesterAuthorizer is IAuthorizer {
    event ExtendedWhitelistExpiration(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed sender,
        uint256 expiration
    );

    event SetWhitelistExpiration(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed sender,
        uint256 expiration
    );

    event SetIndefiniteWhitelistStatus(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed sender,
        bool status,
        uint192 indefiniteWhitelistCount
    );

    event RevokedIndefiniteWhitelistStatus(
        address indexed airnode,
        bytes32 endpointId,
        address indexed requester,
        address indexed setter,
        address sender,
        uint192 indefiniteWhitelistCount
    );

    function extendWhitelistExpiration(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) external;

    function setWhitelistExpiration(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) external;

    function setIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        bool status
    ) external;

    function revokeIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) external;

    function requesterIsWhitelisted(
        address airnode,
        bytes32 endpointId,
        address requester
    ) external view returns (bool isWhitelisted);

    function airnodeToEndpointIdToRequesterToWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester
    )
        external
        view
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount);

    function airnodeToEndpointIdToRequesterToSetterToIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) external view returns (bool indefiniteWhitelistStatus);
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/authorizers/RequesterAuthorizer.sol

pragma solidity 0.8.9;


/// @title Abstract contract that can be used to build Airnode authorizers that
/// temporarily or permanently whitelist requesters for Airnode–endpoint pairs
abstract contract RequesterAuthorizer is Whitelist, IRequesterAuthorizer {
    /// @notice Extends the expiration of the temporary whitelist of
    /// `requester` for the `airnode`–`endpointId` pair and emits an event
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function _extendWhitelistExpirationAndEmit(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) internal {
        _extendWhitelistExpiration(
            deriveServiceId(airnode, endpointId),
            requester,
            expirationTimestamp
        );
        emit ExtendedWhitelistExpiration(
            airnode,
            endpointId,
            requester,
            msg.sender,
            expirationTimestamp
        );
    }

    /// @notice Sets the expiration of the temporary whitelist of `requester`
    /// for the `airnode`–`endpointId` pair and emits an event
    /// @dev Unlike `_extendWhitelistExpiration()`, this can hasten expiration.
    /// Emits the event even if it does not change the state.
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function _setWhitelistExpirationAndEmit(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) internal {
        _setWhitelistExpiration(
            deriveServiceId(airnode, endpointId),
            requester,
            expirationTimestamp
        );
        emit SetWhitelistExpiration(
            airnode,
            endpointId,
            requester,
            msg.sender,
            expirationTimestamp
        );
    }

    /// @notice Sets the indefinite whitelist status of `requester` for the
    /// `airnode`–`endpointId` pair and emits an event
    /// @dev Emits the event even if it does not change the state.
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param status Indefinite whitelist status
    function _setIndefiniteWhitelistStatusAndEmit(
        address airnode,
        bytes32 endpointId,
        address requester,
        bool status
    ) internal {
        uint192 indefiniteWhitelistCount = _setIndefiniteWhitelistStatus(
            deriveServiceId(airnode, endpointId),
            requester,
            status
        );
        emit SetIndefiniteWhitelistStatus(
            airnode,
            endpointId,
            requester,
            msg.sender,
            status,
            indefiniteWhitelistCount
        );
    }

    /// @notice Revokes the indefinite whitelist status granted to `requester`
    /// for the `airnode`–`endpointId` pair by a specific account and emits an
    /// event
    /// @dev Only emits the event if it changes the state
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param setter Setter of the indefinite whitelist status
    function _revokeIndefiniteWhitelistStatusAndEmit(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) internal {
        (
            bool revoked,
            uint192 indefiniteWhitelistCount
        ) = _revokeIndefiniteWhitelistStatus(
                deriveServiceId(airnode, endpointId),
                requester,
                setter
            );
        if (revoked) {
            emit RevokedIndefiniteWhitelistStatus(
                airnode,
                endpointId,
                requester,
                setter,
                msg.sender,
                indefiniteWhitelistCount
            );
        }
    }

    /// @notice Returns if `requester` is whitelisted for the
    /// `airnode`–`endpointId` pair
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @return isWhitelisted If `requester` is whitelisted for the
    /// `airnode`–`endpointId` pair
    function requesterIsWhitelisted(
        address airnode,
        bytes32 endpointId,
        address requester
    ) public view override returns (bool isWhitelisted) {
        isWhitelisted = userIsWhitelisted(
            deriveServiceId(airnode, endpointId),
            requester
        );
    }

    /// @notice Verifies the authorization status of a request
    /// @dev This method has redundant arguments because all authorizer
    /// contracts have to have the same interface and potential authorizer
    /// contracts may require to access the arguments that are redundant here
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param sponsor Sponsor address
    /// @param requester Requester address
    /// @return Authorization status of the request
    function isAuthorized(
        bytes32 requestId, // solhint-disable-line no-unused-vars
        address airnode,
        bytes32 endpointId,
        address sponsor, // solhint-disable-line no-unused-vars
        address requester
    ) external view override returns (bool) {
        return requesterIsWhitelisted(airnode, endpointId, requester);
    }

    /// @notice Returns the whitelist status of `requester` for the
    /// `airnode`–`endpointId` pair
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @return expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    /// @return indefiniteWhitelistCount Number of times `requester` was
    /// whitelisted indefinitely for the `airnode`–`endpointId` pair
    function airnodeToEndpointIdToRequesterToWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester
    )
        external
        view
        override
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount)
    {
        WhitelistStatus
            storage whitelistStatus = serviceIdToUserToWhitelistStatus[
                deriveServiceId(airnode, endpointId)
            ][requester];
        expirationTimestamp = whitelistStatus.expirationTimestamp;
        indefiniteWhitelistCount = whitelistStatus.indefiniteWhitelistCount;
    }

    /// @notice Returns if an account has indefinitely whitelisted `requester`
    /// for the `airnode`–`endpointId` pair
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param setter Address of the account that has potentially whitelisted
    /// `requester` for the `airnode`–`endpointId` pair indefinitely
    /// @return indefiniteWhitelistStatus If `setter` has indefinitely
    /// whitelisted `requester` for the `airnode`–`endpointId` pair
    function airnodeToEndpointIdToRequesterToSetterToIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) external view override returns (bool indefiniteWhitelistStatus) {
        indefiniteWhitelistStatus = serviceIdToUserToSetterToIndefiniteWhitelistStatus[
            deriveServiceId(airnode, endpointId)
        ][requester][setter];
    }

    /// @notice Called privately to derive a service ID out of the Airnode
    /// address and the endpoint ID
    /// @dev This is done to re-use the more general Whitelist contract for
    /// the specific case of Airnode–endpoint pairs
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @return serviceId Service ID
    function deriveServiceId(address airnode, bytes32 endpointId)
        private
        pure
        returns (bytes32 serviceId)
    {
        serviceId = keccak256(abi.encodePacked(airnode, endpointId));
    }
}


// File verify/0.3.1/@api3/airnode-protocol/contracts/authorizers/interfaces/IRequesterAuthorizerWithManager.sol

pragma solidity 0.8.9;


interface IRequesterAuthorizerWithManager is
    IWhitelistRolesWithManager,
    IRequesterAuthorizer
{}


// File verify/0.3.1/@api3/airnode-protocol/contracts/authorizers/RequesterAuthorizerWithManager.sol

pragma solidity 0.8.9;



/// @title Authorizer contract that a manager can use to temporarily or
/// indefinitely whitelist requesters for Airnode–endpoint pairs
/// @notice The manager address here is expected to belong to an
/// AccessControlAgent contract that is owned by the DAO
contract RequesterAuthorizerWithManager is
    WhitelistRolesWithManager,
    RequesterAuthorizer,
    IRequesterAuthorizerWithManager
{
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    )
        WhitelistRolesWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
    {}

    /// @notice Extends the expiration of the temporary whitelist of
    /// `requester` for the `airnode`–`endpointId` pair if the sender has the
    /// whitelist expiration extender role
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function extendWhitelistExpiration(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) external override {
        require(
            hasWhitelistExpirationExtenderRoleOrIsManager(msg.sender),
            "Not expiration extender"
        );
        _extendWhitelistExpirationAndEmit(
            airnode,
            endpointId,
            requester,
            expirationTimestamp
        );
    }

    /// @notice Sets the expiration of the temporary whitelist of `requester`
    /// for the `airnode`–`endpointId` pair if the sender has the whitelist
    /// expiration setter role
    /// @dev Unlike `extendWhitelistExpiration()`, this can hasten expiration
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function setWhitelistExpiration(
        address airnode,
        bytes32 endpointId,
        address requester,
        uint64 expirationTimestamp
    ) external override {
        require(
            hasWhitelistExpirationSetterRoleOrIsManager(msg.sender),
            "Not expiration setter"
        );
        _setWhitelistExpirationAndEmit(
            airnode,
            endpointId,
            requester,
            expirationTimestamp
        );
    }

    /// @notice Sets the indefinite whitelist status of `requester` for the
    /// `airnode`–`endpointId` pair if the sender has the indefinite
    /// whitelister role
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param status Indefinite whitelist status
    function setIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        bool status
    ) external override {
        require(
            hasIndefiniteWhitelisterRoleOrIsManager(msg.sender),
            "Not indefinite whitelister"
        );
        _setIndefiniteWhitelistStatusAndEmit(
            airnode,
            endpointId,
            requester,
            status
        );
    }

    /// @notice Revokes the indefinite whitelist status granted by a specific
    /// account that no longer has the indefinite whitelister role
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID
    /// @param requester Requester address
    /// @param setter Setter of the indefinite whitelist status
    function revokeIndefiniteWhitelistStatus(
        address airnode,
        bytes32 endpointId,
        address requester,
        address setter
    ) external override {
        require(
            !hasIndefiniteWhitelisterRoleOrIsManager(setter),
            "setter is indefinite whitelister"
        );
        _revokeIndefiniteWhitelistStatusAndEmit(
            airnode,
            endpointId,
            requester,
            setter
        );
    }
}