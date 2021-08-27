pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import './AccessControlRci.sol';
import './../interfaces/IRegistry.sol';


contract Registry is AccessControlRci, IRegistry{
    struct Comp{
        bool active;
        address competitionAddress;
        bytes32 rulesLocation;
    }

    struct Ext{
        bool active;
        address extensionAddress;
        bytes32 informationLocation;
    }
    address private _token;
    mapping(string => Comp) private _competition;
    mapping(string => Ext) private _extension;
    string[] private _competitionNames;
    string[] private _extensionNames;


    constructor()
    {
        _initializeRciAdmin();
    }

    function registerNewCompetition(string calldata competitionName, address competitionAddress, bytes32 rulesLocation)
    external override onlyAdmin
    {
        require(_competition[competitionName].competitionAddress == address(0), "Registry - registerNewCompetition: Competition already exists.");
        _competition[competitionName] = Comp({active:true, competitionAddress:competitionAddress, rulesLocation:rulesLocation});
        _competitionNames.push(competitionName);

        emit NewCompetitionRegistered(competitionName, competitionAddress, rulesLocation);
    }

    function toggleCompetitionActive(string calldata competitionName)
    external override onlyAdmin
    {
        require(_competition[competitionName].competitionAddress != address(0), "Registry - toggleCompetitionActive: Competition does not exist. Use function 'registerNewCompetition' instead.");
        _competition[competitionName].active = !_competition[competitionName].active;

        emit CompetitionActiveToggled(competitionName);
    }

    function changeCompetitionRulesLocation(string calldata competitionName, bytes32 newLocation)
    external override onlyAdmin
    {
        require(_competition[competitionName].competitionAddress != address(0), "Registry - changeCompetitionRulesLocation: Competition does not exist. Use function 'registerNewCompetition' instead.");
        require(newLocation != bytes32(0), "Registry - changeCompetitionRulesLocation: Cannot set to 0 address.");
        _competition[competitionName].rulesLocation = newLocation;

        emit CompetitionRulesLocationChanged(competitionName, newLocation);
    }

    function changeTokenAddress(address newAddress)
    external override onlyAdmin
    {
        require(newAddress != address(0), "Registry - changeTokenAddress: Cannot set to 0 address.");
        _token = newAddress;

        emit TokenAddressChanged(newAddress);
    }

    function registerNewExtension(string calldata extensionName,address extensionAddress, bytes32 informationLocation)
    external override onlyAdmin
    {
        require(_extension[extensionName].extensionAddress == address(0), "Registry - registerNewExtension: Extension already exists.");
        _extension[extensionName] = Ext({active:true, extensionAddress:extensionAddress, informationLocation:informationLocation});
        _extensionNames.push(extensionName);

        emit NewExtensionRegistered(extensionName, extensionAddress, informationLocation);
    }
    
    function toggleExtensionActive(string calldata extensionName)
    external override onlyAdmin
    {
        require(_extension[extensionName].extensionAddress != address(0), "Registry - toggleExtensionActive: Extension does not exist. Use function 'registerNewExtension' instead.");
        _extension[extensionName].active = !_extension[extensionName].active;

        emit ExtensionActiveToggled(extensionName);
    }
    
    function changeExtensionInfoLocation(string calldata extensionName, bytes32 newLocation)
    external override onlyAdmin
    {
        require(_extension[extensionName].extensionAddress != address(0), "Registry - changeExtensionInfoLocation: Competition does not exist. Use function 'registerNewCompetition' instead.");
        require(newLocation != bytes32(0), "Registry - changeExtensionInfoLocation: Cannot set to 0 address.");
        _extension[extensionName].informationLocation = newLocation;

        emit ExtensionInfoLocationChanged(extensionName, newLocation);
    }

    // convenience function for DAPP.
    function batchCall(address[] calldata addresses, bytes[] calldata data)
    external view
    returns (bytes[] memory)
    {
        bytes[] memory returnDataList = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++){
            (bool success, bytes memory returnedData) = addresses[i].staticcall(data[i]);
            returnDataList[i] = returnedData;
        }
        return returnDataList;
    }

    /* READ METHODS */

    function getCompetitionList()
    view external override
    returns (string[] memory competitionNames)
    {
        competitionNames = _competitionNames;
    }

    function getExtensionList()
    view external override
    returns (string[] memory extensionNames)
    {
        extensionNames = _extensionNames;
    }

    function getCompetitionActive(string calldata competitionName)
    view external override
    returns (bool active)
    {
        active = _competition[competitionName].active;
    }

    function getCompetitionAddress(string calldata competitionName)
    view external override
    returns (address competitionAddress)
    {
        competitionAddress = _competition[competitionName].competitionAddress;
    }

    function getCompetitionRulesLocation(string calldata competitionName)
    view external override
    returns (bytes32 rulesLocation)
    {
        rulesLocation = _competition[competitionName].rulesLocation;
    }

    function getTokenAddress()
    view external override
    returns (address token)
    {
        token = _token;
    }

    function getExtensionAddress(string calldata extensionName)
    view external override
    returns (address extensionAddress)
    {
        extensionAddress = _extension[extensionName].extensionAddress;
    }

    function getExtensionActive(string calldata extensionName)
    view external override
    returns (bool active)
    {
        active = _extension[extensionName].active;
    }

    function getExtensionInfoLocation(string calldata extensionName)
    view external override
    returns (bytes32 informationLocation)
    {
        informationLocation = _extension[extensionName].informationLocation;
    }
}

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import './standard/access/AccessControl.sol';

abstract contract AccessControlRci is AccessControl{
    bytes32 public constant RCI_MAIN_ADMIN = keccak256('RCI_MAIN_ADMIN');
    bytes32 public constant RCI_CHILD_ADMIN = keccak256('RCI_CHILD_ADMIN');

    modifier onlyMainAdmin()
    {
        require(hasRole(RCI_MAIN_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    modifier onlyAdmin()
    {
        require(hasRole(RCI_CHILD_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    function _initializeRciAdmin()
    internal
    {
        _setupRole(RCI_MAIN_ADMIN, msg.sender);
        _setRoleAdmin(RCI_MAIN_ADMIN, RCI_MAIN_ADMIN);

        _setupRole(RCI_CHILD_ADMIN, msg.sender);
        _setRoleAdmin(RCI_CHILD_ADMIN, RCI_MAIN_ADMIN);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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

pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

interface IRegistry{

    function registerNewCompetition(string calldata competitionName, address competitionAddress, bytes32 rulesLocation) external;
    
    function toggleCompetitionActive(string calldata competitionName) external;

    function changeCompetitionRulesLocation(string calldata competitionName, bytes32 newLocation) external;
    
    function changeTokenAddress(address newAddress) external;

    function registerNewExtension(string calldata extensionName,address extensionAddress, bytes32 informationLocation) external;

    function toggleExtensionActive(string calldata extensionName) external;

    function changeExtensionInfoLocation(string calldata extensionName, bytes32 newLocation) external;

    function getCompetitionList() view external returns (string[] memory competitionNames);

    function getExtensionList() view external returns (string[] memory extensionNames);

    function getCompetitionActive(string calldata competitionName) view external returns (bool active);

    function getCompetitionAddress(string calldata competitionName) view external returns (address competitionAddress);

    function getCompetitionRulesLocation(string calldata competitionName) view external returns (bytes32 rulesLocation);

    function getTokenAddress() view external returns (address token);

    function getExtensionAddress(string calldata extensionName) view external returns (address extensionAddress);

    function getExtensionActive(string calldata extensionName) view external returns (bool active);

    function getExtensionInfoLocation(string calldata extensionName) view external returns (bytes32 informationLocation);

    event NewCompetitionRegistered(string indexed competitionName, address indexed competitionAddress, bytes32 rulesLocation);
    event CompetitionActiveToggled(string indexed competitionName);
    event CompetitionRulesLocationChanged(string indexed competitionName, bytes32 indexed newLocation);
    event TokenAddressChanged(address indexed newAddress);
    event NewExtensionRegistered(string indexed extensionName, address indexed extensionAddress, bytes32 indexed informationLocation);
    event ExtensionActiveToggled(string indexed extensionName);
    event ExtensionInfoLocationChanged(string indexed extensionName, bytes32 indexed newLocation);
}

{
  "metadata": {
    "useLiteralContent": true
  },
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
  }
}