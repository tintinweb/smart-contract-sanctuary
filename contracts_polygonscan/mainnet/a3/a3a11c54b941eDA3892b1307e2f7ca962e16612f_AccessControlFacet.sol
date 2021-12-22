// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';

/// @title Role-based access control for limiting access to some functions of the contract
/// @notice Assign roles to grant access to otherwise limited functions of the contract
contract AccessControlFacet {
	/// @notice An admin of the contract.
	/// @return Hashed value that represents this role.
	function ADMIN_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ADMIN_ROLE;
	}

	function ID_VERIFIER_ROLE() public view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ID_VERIFIER_ROLE;
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to grant the role to
	/// @param role The role to grant
	function grantRole(address user, bytes32 role) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		LibAccessControl._grantRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function revokeRole(address user, bytes32 role) public {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		LibAccessControl._revokeRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function hasRole(address user, bytes32 role) public view returns (bool) {
		return LibAccessControl.hasRole(role, user);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MeemID} from '../interfaces/IMeemID.sol';

library LibAppStorage {
	bytes32 constant DIAMOND_STORAGE_POSITION = keccak256('meemid.app.storage');

	struct RoleData {
		mapping(address => bool) members;
		bytes32 adminRole;
	}

	struct AppStorage {
		/** AccessControl Role: Admin */
		bytes32 ADMIN_ROLE;
		bytes32 ID_VERIFIER_ROLE;
		mapping(bytes32 => RoleData) roles;
		MeemID[] ids;
		/** Ids */
		mapping(address => uint256) walletIdIndex;
		mapping(string => uint256) twitterIdIndex;
	}

	function diamondStorage() internal pure returns (AppStorage storage ds) {
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {MissingRequiredRole, NoRenounceOthers} from './Errors.sol';

library LibAccessControl {
	/**
	 * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
	 *
	 * `ADMIN_ROLE` is the starting admin for all roles, despite
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
	 * bearer except when using {AccessControl-_setupRole}.
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

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	// function supportsInterface(bytes4 interfaceId)
	// 	internal
	// 	view
	// 	virtual
	// 	returns (bool)
	// {
	// 	return
	// 		interfaceId == type(IAccessControlUpgradeable).interfaceId ||
	// 		super.supportsInterface(interfaceId);
	// }

	function requireRole(bytes32 role) internal view {
		if (!hasRole(role, msg.sender)) {
			revert MissingRequiredRole(role);
		}
	}

	/**
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.roles[role].members[account];
	}

	/**
	 * @dev Returns the admin role that controls `role`. See {grantRole} and
	 * {revokeRole}.
	 *
	 * To change a role's admin, use {_setRoleAdmin}.
	 */
	function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.roles[role].adminRole;
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
	function grantRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
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
	function revokeRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
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
	function renounceRole(bytes32 role, address account) internal {
		if (account != _msgSender()) {
			revert NoRenounceOthers();
		}

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
	function _setupRole(bytes32 role, address account) internal {
		_grantRole(role, account);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	 */
	function toHexString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return '0x00';
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
	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes16 _HEX_SYMBOLS = '0123456789abcdef';
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, 'Strings: hex length insufficient');
		return string(buffer);
	}

	/**
	 * @dev Sets `adminRole` as ``role``'s admin role.
	 *
	 * Emits a {RoleAdminChanged} event.
	 */
	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		bytes32 previousAdminRole = getRoleAdmin(role);
		s.roles[role].adminRole = adminRole;
		emit RoleAdminChanged(role, previousAdminRole, adminRole);
	}

	function _grantRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (!hasRole(role, account)) {
			s.roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (hasRole(role, account)) {
			s.roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
		}
	}

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct MeemID {
	address[] wallets;
	string[] twitters;
}

interface IMeemID {
	function createOrAddMeemID(address addy, string memory twitterId) external;

	function removeWalletAddressByWalletAddress(
		address lookupWalletAddress,
		address addressToRemove
	) external;

	function removeWalletAddressByTwitterId(
		string memory twitterId,
		address addressToRemove
	) external;

	function removeTwitterIdByWalletAddress(
		address lookupWalletAddress,
		string memory twitterIdToRemove
	) external;

	function removeTwitterIdByTwitterId(
		string memory lookupTwitterId,
		string memory twitterIdToRemove
	) external;

	function getMeemIDByWalletAddress(address addy)
		external
		view
		returns (MeemID memory);

	function getMeemIDByTwitterId(string memory twitterId)
		external
		view
		returns (MeemID memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error MissingRequiredRole(bytes32 requiredRole);

error NoRenounceOthers();

error TwitterAlreadyAdded();

error MeemIDNotFound();

error MeemIDAlreadyExists();

error MeemIDAlreadyAssociated();

error NoRemoveSelf();

error IndexOutOfRange();