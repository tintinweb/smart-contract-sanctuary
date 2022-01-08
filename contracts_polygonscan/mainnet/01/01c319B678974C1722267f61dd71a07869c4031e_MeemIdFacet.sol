// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibArray} from '../libraries/LibArray.sol';
import {LibStrings} from '../libraries/LibStrings.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {TwitterAlreadyAdded, MeemIDNotFound, MeemIDAlreadyExists, MeemIDAlreadyAssociated, NoRemoveSelf} from '../libraries/Errors.sol';
import {IMeemID, MeemID} from '../interfaces/IMeemID.sol';

contract MeemIdFacet is IMeemID {
	function createOrAddMeemID(address addy, string memory twitterId)
		external
		override
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ID_VERIFIER_ROLE);
		uint256 idx = s.walletIdIndex[addy];
		uint256 twitterIdx = s.twitterIdIndex[twitterId];

		if (idx == 0 && twitterIdx == 0) {
			// Create the ID
			address[] memory wallets = new address[](1);
			string[] memory twitters = new string[](1);
			wallets[0] = addy;
			twitters[0] = twitterId;

			s.idxCounter++;

			s.ids[s.idxCounter] = MeemID({
				wallets: wallets,
				twitters: twitters,
				defaultWallet: addy,
				defaultTwitter: twitterId
			});

			s.walletIdIndex[addy] = s.idxCounter;
			s.twitterIdIndex[twitterId] = s.idxCounter;
		} else if (idx != 0 && twitterIdx == 0) {
			// Add twitter
			s.ids[idx].twitters.push(twitterId);
			s.twitterIdIndex[twitterId] = idx;

			if (bytes(s.ids[idx].defaultTwitter).length == 0) {
				s.ids[idx].defaultTwitter = twitterId;
			}
			if (s.ids[idx].defaultWallet == address(0)) {
				s.ids[idx].defaultWallet = addy;
			}
		} else if (idx == 0 && twitterIdx != 0) {
			// Add wallet
			s.ids[twitterIdx].wallets.push(addy);
			s.walletIdIndex[addy] = twitterIdx;

			if (bytes(s.ids[twitterIdx].defaultTwitter).length == 0) {
				s.ids[twitterIdx].defaultTwitter = twitterId;
			}
			if (s.ids[twitterIdx].defaultWallet == address(0)) {
				s.ids[twitterIdx].defaultWallet = addy;
			}
		} else if (idx != 0 && twitterIdx != 0 && idx != twitterIdx) {
			// Mismatched ids
			revert MeemIDAlreadyAssociated();
		} else {
			if (bytes(s.ids[idx].defaultTwitter).length == 0) {
				s.ids[idx].defaultTwitter = twitterId;
			}
			if (s.ids[idx].defaultWallet == address(0)) {
				s.ids[idx].defaultWallet = addy;
			}
		}

		// Else it's already been added. Nothing to do.
	}

	function getMeemIDByWalletAddress(address addy)
		external
		view
		override
		returns (MeemID memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.walletIdIndex[addy] == 0) {
			revert MeemIDNotFound();
		}

		return s.ids[s.walletIdIndex[addy]];
	}

	function getMeemIDByTwitterId(string memory twitterId)
		external
		view
		override
		returns (MeemID memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.twitterIdIndex[twitterId] == 0) {
			revert MeemIDNotFound();
		}

		return s.ids[s.twitterIdIndex[twitterId]];
	}

	function getMeemIDIndexByWalletAddress(address addy)
		external
		view
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.walletIdIndex[addy] == 0) {
			revert MeemIDNotFound();
		}

		return s.walletIdIndex[addy];
	}

	function getMeemIDIndexByTwitterId(string memory twitterId)
		external
		view
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.twitterIdIndex[twitterId] == 0) {
			revert MeemIDNotFound();
		}

		return s.twitterIdIndex[twitterId];
	}

	function getMeemIDByIndex(uint256 idx)
		external
		view
		returns (MeemID memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		return s.ids[idx];
	}

	function getNumberOfMeemIds() external view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		return s.idxCounter;
	}

	function removeWalletAddressByWalletAddress(
		address lookupWalletAddress,
		address addressToRemove
	) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ID_VERIFIER_ROLE);

		if (lookupWalletAddress == addressToRemove) {
			revert NoRemoveSelf();
		}

		uint256 idx = s.walletIdIndex[lookupWalletAddress];

		if (idx == 0) {
			revert MeemIDNotFound();
		}

		for (uint256 i = 0; i < s.ids[idx].wallets.length; i++) {
			if (s.ids[idx].wallets[i] == addressToRemove) {
				s.ids[idx].wallets = LibArray.removeAddressAt(
					s.ids[idx].wallets,
					i
				);

				delete s.walletIdIndex[addressToRemove];
			}
		}

		if (s.ids[idx].defaultWallet == addressToRemove) {
			s.ids[idx].defaultWallet = s.ids[idx].wallets[0];
		}
	}

	function removeWalletAddressByTwitterId(
		string memory lookupTwitterId,
		address addressToRemove
	) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ID_VERIFIER_ROLE);

		uint256 idx = s.twitterIdIndex[lookupTwitterId];

		if (idx == 0) {
			revert MeemIDNotFound();
		}

		for (uint256 i = 0; i < s.ids[idx].wallets.length; i++) {
			if (s.ids[idx].wallets[i] == addressToRemove) {
				s.ids[idx].wallets = LibArray.removeAddressAt(
					s.ids[idx].wallets,
					i
				);

				delete s.walletIdIndex[addressToRemove];
			}
		}

		if (s.ids[idx].defaultWallet == addressToRemove) {
			s.ids[idx].defaultWallet = s.ids[idx].wallets[0];
		}
	}

	function removeTwitterIdByWalletAddress(
		address lookupWalletAddress,
		string memory twitterIdToRemove
	) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ID_VERIFIER_ROLE);

		uint256 idx = s.walletIdIndex[lookupWalletAddress];

		if (idx == 0) {
			revert MeemIDNotFound();
		}

		for (uint256 i = 0; i < s.ids[idx].twitters.length; i++) {
			if (
				LibStrings.compareStrings(
					s.ids[idx].twitters[i],
					twitterIdToRemove
				)
			) {
				s.ids[idx].twitters = LibArray.removeStringAt(
					s.ids[idx].twitters,
					i
				);

				delete s.twitterIdIndex[twitterIdToRemove];
			}
		}

		if (
			LibStrings.compareStrings(
				s.ids[idx].defaultTwitter,
				twitterIdToRemove
			)
		) {
			s.ids[idx].defaultTwitter = s.ids[idx].twitters[0];
		}
	}

	function removeTwitterIdByTwitterId(
		string memory lookupTwitterId,
		string memory twitterIdToRemove
	) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ID_VERIFIER_ROLE);

		if (LibStrings.compareStrings(lookupTwitterId, twitterIdToRemove)) {
			revert NoRemoveSelf();
		}

		uint256 idx = s.twitterIdIndex[lookupTwitterId];

		if (idx == 0) {
			revert MeemIDNotFound();
		}

		for (uint256 i = 0; i < s.ids[idx].twitters.length; i++) {
			if (
				LibStrings.compareStrings(
					s.ids[idx].twitters[i],
					twitterIdToRemove
				)
			) {
				s.ids[idx].twitters = LibArray.removeStringAt(
					s.ids[idx].twitters,
					i
				);

				delete s.twitterIdIndex[twitterIdToRemove];
			}
		}

		if (
			LibStrings.compareStrings(
				s.ids[idx].defaultTwitter,
				twitterIdToRemove
			)
		) {
			s.ids[idx].defaultTwitter = s.ids[idx].twitters[0];
		}
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
		// MeemID[] ids;
		mapping(uint256 => MeemID) ids;
		uint256 idxCounter;
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

import {IndexOutOfRange} from './Errors.sol';

library LibArray {
	function removeStringAt(string[] storage array, uint256 index)
		internal
		returns (string[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAddressAt(address[] storage array, uint256 index)
		internal
		returns (address[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeUintAt(uint256[] storage array, uint256 index)
		internal
		returns (uint256[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
	function compareStrings(string memory s1, string memory s2)
		internal
		pure
		returns (bool)
	{
		return
			keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` representation.
	 */
	function strWithUint(string memory _str, uint256 value)
		internal
		pure
		returns (string memory)
	{
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
		bytes memory buffer;
		unchecked {
			if (value == 0) {
				return string(abi.encodePacked(_str, '0'));
			}
			uint256 temp = value;
			uint256 digits;
			while (temp != 0) {
				digits++;
				temp /= 10;
			}
			buffer = new bytes(digits);
			uint256 index = digits - 1;
			temp = value;
			while (temp != 0) {
				buffer[index--] = bytes1(uint8(48 + (temp % 10)));
				temp /= 10;
			}
		}
		return string(abi.encodePacked(_str, buffer));
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

error MissingRequiredRole(bytes32 requiredRole);

error NoRenounceOthers();

error TwitterAlreadyAdded();

error MeemIDNotFound();

error MeemIDAlreadyExists();

error MeemIDAlreadyAssociated();

error NoRemoveSelf();

error IndexOutOfRange();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct MeemID {
	address[] wallets;
	string[] twitters;
	address defaultWallet;
	string defaultTwitter;
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