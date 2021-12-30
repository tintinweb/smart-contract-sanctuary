// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IACLRegistry {
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
   * @dev Returns `true` if `account` has been granted `permission`.
   */
  function hasPermission(bytes32 permission, address account) external view returns (bool);

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

  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  function grantPermission(bytes32 permission, address account) external;

  function revokePermission(bytes32 permission) external;

  function requireApprovedContractOrEOA(address account) external view;

  function requireRole(bytes32 role, address account) external view;

  function requirePermission(bytes32 permission, address account) external view;

  function isRoleAdmin(bytes32 role, address account) external view;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IACLRegistry.sol";
import "../interfaces/IContractRegistry.sol";

/**
 * @dev This Contract holds reference to all our contracts. Every contract A that needs to interact with another contract B calls this contract
 * to ask for the address of B.
 * This allows us to update addresses in one central point and reduces constructing and management overhead.
 */
contract ContractRegistry is IContractRegistry {
  struct Contract {
    address contractAddress;
    bytes32 version;
  }

  /* ========== STATE VARIABLES ========== */

  IACLRegistry public aclRegistry;

  mapping(bytes32 => Contract) public contracts;
  bytes32[] public contractNames;

  /* ========== EVENTS ========== */

  event ContractAdded(bytes32 _name, address _address, bytes32 _version);
  event ContractUpdated(bytes32 _name, address _address, bytes32 _version);
  event ContractDeleted(bytes32 _name);

  /* ========== CONSTRUCTOR ========== */

  constructor(IACLRegistry _aclRegistry) {
    aclRegistry = _aclRegistry;
    contracts[keccak256("ACLRegistry")] = Contract({contractAddress: address(_aclRegistry), version: keccak256("1")});
    contractNames.push(keccak256("ACLRegistry"));
  }

  /* ========== VIEW FUNCTIONS ========== */

  function getContractNames() external view returns (bytes32[] memory) {
    return contractNames;
  }

  function getContract(bytes32 _name) external view override returns (address) {
    return contracts[_name].contractAddress;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function addContract(
    bytes32 _name,
    address _address,
    bytes32 _version
  ) external {
    aclRegistry.requireRole(keccak256("DAO"), msg.sender);
    require(contracts[_name].contractAddress == address(0), "contract already exists");
    contracts[_name] = Contract({contractAddress: _address, version: _version});
    contractNames.push(_name);
    emit ContractAdded(_name, _address, _version);
  }

  function updateContract(
    bytes32 _name,
    address _newAddress,
    bytes32 _version
  ) external {
    aclRegistry.requireRole(keccak256("DAO"), msg.sender);
    require(contracts[_name].contractAddress != address(0), "contract doesnt exist");
    contracts[_name] = Contract({contractAddress: _newAddress, version: _version});
    emit ContractUpdated(_name, _newAddress, _version);
  }

  function deleteContract(bytes32 _name, uint256 _contractIndex) external {
    aclRegistry.requireRole(keccak256("DAO"), msg.sender);
    require(contracts[_name].contractAddress != address(0), "contract doesnt exist");
    require(contractNames[_contractIndex] == _name, "this is not the contract you are looking for");
    delete contracts[_name];
    delete contractNames[_contractIndex];
    emit ContractDeleted(_name);
  }
}