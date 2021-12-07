/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/whitelist/Whitelist.sol

// SPDX-License-Identifier: MIT
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


// File contracts/access-control-registry/RoleDeriver.sol

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


// File contracts/access-control-registry/interfaces/IAccessControlClient.sol

pragma solidity 0.8.9;

interface IAccessControlClient {
    function accessControlRegistry() external view returns (address);
}


// File contracts/access-control-registry/AccessControlClient.sol

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


// File contracts/whitelist/interfaces/IWhitelistRoles.sol

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


// File contracts/whitelist/WhitelistRoles.sol

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


// File contracts/whitelist/interfaces/IWhitelistRolesWithManager.sol

pragma solidity 0.8.9;

interface IWhitelistRolesWithManager is IWhitelistRoles {
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);

    function whitelistExpirationExtenderRole() external view returns (bytes32);

    function whitelistExpirationSetterRole() external view returns (bytes32);

    function indefiniteWhitelisterRole() external view returns (bytes32);
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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


// File contracts/access-control-registry/interfaces/IAccessControlRegistry.sol

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


// File contracts/whitelist/WhitelistRolesWithManager.sol

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


// File contracts/rrp/interfaces/IAuthorizationUtils.sol

pragma solidity 0.8.9;

interface IAuthorizationUtils {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}


// File contracts/rrp/interfaces/ITemplateUtils.sol

pragma solidity 0.8.9;

interface ITemplateUtils {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}


// File contracts/rrp/interfaces/IWithdrawalUtils.sol

pragma solidity 0.8.9;

interface IWithdrawalUtils {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}


// File contracts/rrp/interfaces/IAirnodeRrp.sol

pragma solidity 0.8.9;



interface IAirnodeRrp is IAuthorizationUtils, ITemplateUtils, IWithdrawalUtils {
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}


// File contracts/rrp/requesters/RrpRequester.sol

pragma solidity 0.8.9;

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequester {
    IAirnodeRrp public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrp(_airnodeRrp);
        IAirnodeRrp(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}


// File contracts/rrp/requesters/interfaces/IRrpBeaconServer.sol

pragma solidity 0.8.9;

interface IRrpBeaconServer {
    event ExtendedWhitelistExpiration(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed sender,
        uint256 expiration
    );

    event SetWhitelistExpiration(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed sender,
        uint256 expiration
    );

    event SetIndefiniteWhitelistStatus(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed sender,
        bool status,
        uint192 indefiniteWhitelistCount
    );

    event RevokedIndefiniteWhitelistStatus(
        bytes32 indexed beaconId,
        address indexed reader,
        address indexed setter,
        address sender,
        uint192 indefiniteWhitelistCount
    );

    event SetUpdatePermissionStatus(
        address indexed sponsor,
        address indexed updateRequester,
        bool status
    );

    event RequestedBeaconUpdate(
        bytes32 indexed beaconId,
        address indexed sponsor,
        address indexed requester,
        bytes32 requestId,
        bytes32 templateId,
        address sponsorWallet,
        bytes parameters
    );

    event UpdatedBeacon(
        bytes32 indexed beaconId,
        bytes32 requestId,
        int224 value,
        uint32 timestamp
    );

    function extendWhitelistExpiration(
        bytes32 beaconId,
        address reader,
        uint64 expirationTimestamp
    ) external;

    function setWhitelistExpiration(
        bytes32 beaconId,
        address reader,
        uint64 expirationTimestamp
    ) external;

    function setIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        bool status
    ) external;

    function revokeIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        address setter
    ) external;

    function setUpdatePermissionStatus(address updateRequester, bool status)
        external;

    function requestBeaconUpdate(
        bytes32 beaconId,
        address requester,
        address designatedWallet,
        bytes calldata parameters
    ) external;

    function fulfill(bytes32 requestId, bytes calldata data) external;

    function readBeacon(bytes32 beaconId)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readerCanReadBeacon(bytes32 beaconId, address reader)
        external
        view
        returns (bool);

    function beaconIdToReaderToWhitelistStatus(bytes32 beaconId, address reader)
        external
        view
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount);

    function beaconIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        address setter
    ) external view returns (bool indefiniteWhitelistStatus);

    function sponsorToUpdateRequesterToPermissionStatus(
        address sponsor,
        address updateRequester
    ) external view returns (bool permissionStatus);

    function deriveBeaconId(bytes32 templateId, bytes calldata parameters)
        external
        pure
        returns (bytes32 beaconId);
}


// File contracts/rrp/requesters/RrpBeaconServer.sol

pragma solidity 0.8.9;




/// @title The contract that serves beacons using Airnode RRP
/// @notice A beacon is a live data point associated with a beacon ID, which is
/// derived from a template ID and additional parameters. This is suitable
/// where the more recent data point is always more favorable, e.g., in the
/// context of an asset price data feed. Another definition of beacons are
/// one-Airnode data feeds that can be used individually or combined to build
/// decentralized data feeds.
/// @dev This contract casts the reported data point to `int224`. If this is
/// a problem (because the reported data may not fit into 224 bits or it is of
/// a completely different type such as `bytes32`), do not use this contract
/// and implement a customized version instead.
/// The contract casts the timestamps to `uint32`, which means it will not work
/// work past-2106 in the current form. If this is an issue, consider casting
/// the timestamps to a larger type.
contract RrpBeaconServer is
    Whitelist,
    WhitelistRolesWithManager,
    RrpRequester,
    IRrpBeaconServer
{
    struct Beacon {
        int224 value;
        uint32 timestamp;
    }

    /// @notice Returns if a sponsor has permitted an account to request
    /// updates at this contract
    mapping(address => mapping(address => bool))
        public
        override sponsorToUpdateRequesterToPermissionStatus;

    mapping(bytes32 => Beacon) private beacons;
    mapping(bytes32 => bytes32) private requestIdToBeaconId;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        address _airnodeRrp
    )
        WhitelistRolesWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
        RrpRequester(_airnodeRrp)
    {}

    /// @notice Extends the expiration of the temporary whitelist of `reader`
    /// to be able to read the beacon with `beaconId` if the sender has the
    /// whitelist expiration extender role
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function extendWhitelistExpiration(
        bytes32 beaconId,
        address reader,
        uint64 expirationTimestamp
    ) external override {
        require(
            hasWhitelistExpirationExtenderRoleOrIsManager(msg.sender),
            "Not expiration extender"
        );
        _extendWhitelistExpiration(beaconId, reader, expirationTimestamp);
        emit ExtendedWhitelistExpiration(
            beaconId,
            reader,
            msg.sender,
            expirationTimestamp
        );
    }

    /// @notice Sets the expiration of the temporary whitelist of `reader` to
    /// be able to read the beacon with `beaconId` if the sender has the
    /// whitelist expiration setter role
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @param expirationTimestamp Timestamp at which the temporary whitelist
    /// will expire
    function setWhitelistExpiration(
        bytes32 beaconId,
        address reader,
        uint64 expirationTimestamp
    ) external override {
        require(
            hasWhitelistExpirationSetterRoleOrIsManager(msg.sender),
            "Not expiration setter"
        );
        _setWhitelistExpiration(beaconId, reader, expirationTimestamp);
        emit SetWhitelistExpiration(
            beaconId,
            reader,
            msg.sender,
            expirationTimestamp
        );
    }

    /// @notice Sets the indefinite whitelist status of `reader` to be able to
    /// read the beacon with `beaconId` if the sender has the indefinite
    /// whitelister role
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @param status Indefinite whitelist status
    function setIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        bool status
    ) external override {
        require(
            hasIndefiniteWhitelisterRoleOrIsManager(msg.sender),
            "Not indefinite whitelister"
        );
        uint192 indefiniteWhitelistCount = _setIndefiniteWhitelistStatus(
            beaconId,
            reader,
            status
        );
        emit SetIndefiniteWhitelistStatus(
            beaconId,
            reader,
            msg.sender,
            status,
            indefiniteWhitelistCount
        );
    }

    /// @notice Revokes the indefinite whitelist status granted by a specific
    /// account that no longer has the indefinite whitelister role
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @param setter Setter of the indefinite whitelist status
    function revokeIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        address setter
    ) external override {
        require(
            !hasIndefiniteWhitelisterRoleOrIsManager(setter),
            "setter is indefinite whitelister"
        );
        (
            bool revoked,
            uint192 indefiniteWhitelistCount
        ) = _revokeIndefiniteWhitelistStatus(beaconId, reader, setter);
        if (revoked) {
            emit RevokedIndefiniteWhitelistStatus(
                beaconId,
                reader,
                setter,
                msg.sender,
                indefiniteWhitelistCount
            );
        }
    }

    /// @notice Called by the sponsor to set the update request permission
    /// status of an account
    /// @param updateRequester Update requester address
    /// @param status Update permission status of the update requester
    function setUpdatePermissionStatus(address updateRequester, bool status)
        external
        override
    {
        require(updateRequester != address(0), "Update requester zero");
        sponsorToUpdateRequesterToPermissionStatus[msg.sender][
            updateRequester
        ] = status;
        emit SetUpdatePermissionStatus(msg.sender, updateRequester, status);
    }

    /// @notice Called to request a beacon to be updated
    /// @dev There are two requirements for this method to be called: (1) The
    /// sponsor must call `setSponsorshipStatus()` of AirnodeRrp to sponsor
    /// this RrpBeaconServer contract, (2) The sponsor must call
    /// `setUpdatePermissionStatus()` of this RrpBeaconServer contract to give
    /// request update permission to the caller of this method.
    /// The template and additional parameters used here must specify a single
    /// point of data of type `int256` and an additional timestamp of type
    /// `uint256` to be returned because this is what `fulfill()` expects.
    /// This point of data must be castable to `int224` and the timestamp must
    /// be castable to `uint32`.
    /// @param templateId Template ID of the beacon to be updated
    /// @param sponsor Sponsor whose wallet will be used to fulfill this
    /// request
    /// @param sponsorWallet Sponsor wallet that will be used to fulfill this
    /// request
    /// @param parameters Parameters provided by the requester in addition to
    /// the parameters in the template
    function requestBeaconUpdate(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        bytes calldata parameters
    ) external override {
        require(
            sponsorToUpdateRequesterToPermissionStatus[sponsor][msg.sender],
            "Caller not permitted"
        );
        bytes32 beaconId = deriveBeaconId(templateId, parameters);
        bytes32 requestId = airnodeRrp.makeTemplateRequest(
            templateId,
            sponsor,
            sponsorWallet,
            address(this),
            this.fulfill.selector,
            parameters
        );
        requestIdToBeaconId[requestId] = beaconId;
        emit RequestedBeaconUpdate(
            beaconId,
            sponsor,
            msg.sender,
            requestId,
            templateId,
            sponsorWallet,
            parameters
        );
    }

    /// @notice Called by AirnodeRrp to fulfill the request
    /// @dev It is assumed that the fulfillment will be made with a single
    /// point of data of type `int256` and an additional timestamp of type
    /// `uint256`
    /// @param requestId ID of the request being fulfilled
    /// @param data Fulfillment data (a single `int256` and an additional
    /// timestamp of type `uint256` encoded as `bytes`)
    function fulfill(bytes32 requestId, bytes calldata data)
        external
        override
        onlyAirnodeRrp
    {
        bytes32 beaconId = requestIdToBeaconId[requestId];
        require(beaconId != bytes32(0), "No such request made");
        delete requestIdToBeaconId[requestId];
        (int256 decodedData, uint256 decodedTimestamp) = abi.decode(
            data,
            (int256, uint256)
        );
        require(
            decodedData >= type(int224).min && decodedData <= type(int224).max,
            "Value typecasting error"
        );
        require(
            decodedTimestamp <= type(uint32).max,
            "Timestamp typecasting error"
        );
        require(
            decodedTimestamp > beacons[beaconId].timestamp,
            "Fulfillment older than beacon"
        );
        require(
            decodedTimestamp + 1 hours > block.timestamp,
            "Fulfillment stale"
        );
        require(
            decodedTimestamp - 1 hours < block.timestamp,
            "Fulfillment from future"
        );
        beacons[beaconId] = Beacon({
            value: int224(decodedData),
            timestamp: uint32(decodedTimestamp)
        });
        emit UpdatedBeacon(
            beaconId,
            requestId,
            int224(decodedData),
            uint32(decodedTimestamp)
        );
    }

    /// @notice Called to read the beacon
    /// @dev The caller must be whitelisted.
    /// If the `timestamp` of a beacon is zero, this means that it was never
    /// written to before, and the zero value in the `value` field is not
    /// valid. In general, make sure to check if the timestamp of the beacon is
    /// fresh enough, and definitely disregard beacons with zero `timestamp`.
    /// @param beaconId ID of the beacon that will be returned
    /// @return value Beacon value
    /// @return timestamp Beacon timestamp
    function readBeacon(bytes32 beaconId)
        external
        view
        override
        returns (int224 value, uint32 timestamp)
    {
        require(
            readerCanReadBeacon(beaconId, msg.sender),
            "Caller not whitelisted"
        );
        Beacon storage beacon = beacons[beaconId];
        return (beacon.value, beacon.timestamp);
    }

    /// @notice Called to check if a reader is whitelisted to read the beacon
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @return isWhitelisted If the reader is whitelisted
    function readerCanReadBeacon(bytes32 beaconId, address reader)
        public
        view
        override
        returns (bool)
    {
        return userIsWhitelisted(beaconId, reader) || reader == address(0);
    }

    /// @notice Called to get the detailed whitelist status of the reader for
    /// the beacon
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @return expirationTimestamp Timestamp at which the whitelisting of the
    /// reader will expire
    /// @return indefiniteWhitelistCount Number of times `reader` was
    /// whitelisted indefinitely for `templateId`
    function beaconIdToReaderToWhitelistStatus(bytes32 beaconId, address reader)
        external
        view
        override
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount)
    {
        WhitelistStatus
            storage whitelistStatus = serviceIdToUserToWhitelistStatus[
                beaconId
            ][reader];
        expirationTimestamp = whitelistStatus.expirationTimestamp;
        indefiniteWhitelistCount = whitelistStatus.indefiniteWhitelistCount;
    }

    /// @notice Returns if an account has indefinitely whitelisted the reader
    /// for the beacon
    /// @param beaconId Beacon ID
    /// @param reader Reader address
    /// @param setter Address of the account that has potentially whitelisted
    /// the reader for the beacon indefinitely
    /// @return indefiniteWhitelistStatus If `setter` has indefinitely
    /// whitelisted reader for the beacon
    function beaconIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 beaconId,
        address reader,
        address setter
    ) external view override returns (bool indefiniteWhitelistStatus) {
        indefiniteWhitelistStatus = serviceIdToUserToSetterToIndefiniteWhitelistStatus[
            beaconId
        ][reader][setter];
    }

    /// @notice Derives the beacon ID from the respective template ID and
    /// additional parameters
    /// @param templateId Template ID
    /// @param parameters Parameters provided by the requester in addition to
    /// the parameters in the template
    /// @return beaconId Beacon ID
    function deriveBeaconId(bytes32 templateId, bytes calldata parameters)
        public
        pure
        override
        returns (bytes32 beaconId)
    {
        beaconId = keccak256(abi.encodePacked(templateId, parameters));
    }
}