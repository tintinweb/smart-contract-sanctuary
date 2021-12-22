// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';

/// @title Role-based access control for limiting access to some functions of the contract
/// @notice Assign roles to grant access to otherwise limited functions of the contract
contract AccessControlFacet {
	/// @notice An admin of the contract.
	/// @return Hashed value that represents this role.
	function ADMIN_ROLE() external view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ADMIN_ROLE;
	}

	/// @notice Can mint root level Meems
	/// @return Hashed value that represents this role.
	function MINTER_ROLE() external view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.MINTER_ROLE;
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to grant the role to
	/// @param role The role to grant
	function grantRole(address user, bytes32 role) external {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		LibAccessControl._grantRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function revokeRole(address user, bytes32 role) external {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		LibAccessControl._revokeRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function hasRole(address user, bytes32 role) external view returns (bool) {
		return LibAccessControl.hasRole(role, user);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {LibMeta} from '../libraries/LibMeta.sol';
import {MeemBase, MeemProperties, Chain} from '../interfaces/MeemStandard.sol';

library LibAppStorage {
	bytes32 constant DIAMOND_STORAGE_POSITION =
		keccak256('meemproject.app.storage');

	struct RoleData {
		mapping(address => bool) members;
		bytes32 adminRole;
	}

	struct AppStorage {
		address proxyRegistryAddress;
		/** AccessControl Role: Admin */
		bytes32 ADMIN_ROLE;
		/** AccessControl Role: Pauser */
		bytes32 PAUSER_ROLE;
		/** AccessControl Role: Minter */
		bytes32 MINTER_ROLE;
		/** AccessControl Role: Upgrader */
		bytes32 UPGRADER_ROLE;
		/** Counter of next incremental token */
		uint256 tokenCounter;
		/** ERC721 Name */
		string name;
		/** ERC721 Symbol */
		string symbol;
		/** Mapping of addresses => all tokens they own */
		mapping(address => uint256[]) ownerTokenIds;
		/** Mapping of addresses => number of tokens owned */
		mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
		/** Mapping of token to approved address */
		mapping(uint256 => address) approved;
		/** Mapping of address to operators */
		mapping(address => mapping(address => bool)) operators;
		/** Mapping of token => Meem data  */
		mapping(uint256 => MeemBase) meems;
		mapping(uint256 => MeemProperties) meemProperties;
		mapping(uint256 => MeemProperties) meemChildProperties;
		/** The minimum amount that must be allocated to non-owners of a token in splits */
		uint256 nonOwnerSplitAllocationAmount;
		/** The contract URI. Used to describe this NFT collection */
		string contractURI;
		/** The depth allowed for minting of children. If 0, no child copies are allowed. */
		uint256 childDepth;
		/** Mapping of token => URIs for each token */
		mapping(uint256 => string) tokenURIs;
		/** Mapping of token to all children */
		mapping(uint256 => uint256[]) children;
		/** Mapping of token to all decendants */
		mapping(uint256 => uint256[]) decendants;
		/** Keeps track of assigned roles */
		mapping(bytes32 => RoleData) roles;
		/** Mapping from token ID to approved address */
		mapping(uint256 => address) tokenApprovals;
		/** Mapping from owner to operator approvals */
		mapping(address => mapping(address => bool)) operatorApprovals;
		// All tokenIds that have been minted and the corresponding index in allTokens
		uint256[] allTokens;
		// Index of tokenId => allTokens index
		mapping(uint256 => uint256) allTokensIndex;
		// Keep track of whether a tokenId has been minted
		mapping(uint256 => bool) mintedTokens;
		// Keep track of tokens that have already been wrapped
		mapping(Chain => mapping(address => mapping(uint256 => uint256))) chainWrappedNFTs;
		// Mapping of (parent) tokenId to owners and the child tokenIds they own
		mapping(uint256 => mapping(address => uint256[])) childrenOwnerTokens;
		// Keep track of original Meems
		uint256[] originalMeemTokens;
		// Index of tokenId => allTokens index
		mapping(uint256 => uint256) originalMeemTokensIndex;
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

library LibMeta {
	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
		keccak256(
			bytes(
				'EIP712Domain(string name,string version,uint256 salt,address verifyingContract)'
			)
		);

	function domainSeparator(string memory name, string memory version)
		internal
		view
		returns (bytes32 domainSeparator_)
	{
		domainSeparator_ = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version)),
				getChainID(),
				address(this)
			)
		);
	}

	function getChainID() internal view returns (uint256 id) {
		assembly {
			id := chainid()
		}
	}

	function msgSender() internal view returns (address sender_) {
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender_ := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender_ = msg.sender;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Chain {
	Ethereum,
	Polygon,
	Cardano,
	Solana,
	Rinkeby
}

enum PermissionType {
	Copy,
	Remix,
	Read
}

enum Permission {
	Owner,
	Anyone,
	Addresses,
	Holders
}

enum PropertyType {
	Meem,
	Child
}

struct Split {
	address toAddress;
	uint256 amount;
	address lockedBy;
}
struct MeemPermission {
	Permission permission;
	address[] addresses;
	uint256 numTokens;
	address lockedBy;
}

struct MeemProperties {
	int256 totalChildren;
	address totalChildrenLockedBy;
	int256 childrenPerWallet;
	address childrenPerWalletLockedBy;
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
}

struct MeemBase {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	uint256 mintedAt;
	string data;
}

struct Meem {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	MeemProperties properties;
	MeemProperties childProperties;
	uint256 mintedAt;
	string data;
}

struct WrappedItem {
	Chain chain;
	address contractAddress;
	uint256 tokenId;
}

struct MeemMintParameters {
	address to;
	string mTokenURI;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	PermissionType permissionType;
	string data;
}

interface IMeemBaseStandard {
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);

	function mint(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external;

	// TODO: Implement child minting
	// function mintChild(
	// 	address to,
	// 	string memory mTokenURI,
	// 	Chain chain,
	// 	uint256 parentTokenId,
	// 	MeemProperties memory properties,
	// 	MeemProperties memory childProperties
	// ) external;
}

interface IMeemQueryStandard {
	// Get children meems
	function childrenOf(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function ownedChildrenOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numChildrenOf(uint256 tokenId) external view returns (uint256);

	function childDepth() external returns (uint256);

	function tokenIdsOfOwner(address _owner)
		external
		view
		returns (uint256[] memory tokenIds_);

	function isNFTWrapped(
		Chain chain,
		address contractAddress,
		uint256 tokenId
	) external view returns (bool);

	function wrappedTokens(WrappedItem[] memory items)
		external
		view
		returns (uint256[] memory);

	function getMeem(uint256 tokenId) external view returns (Meem memory);
}

interface IMeemAdminStandard {
	function setNonOwnerSplitAllocationAmount(uint256 amount) external;

	function setChildDepth(uint256 newChildDepth) external;

	function setTokenCounter(uint256 tokenCounter) external;

	function setContractURI(string memory newContractURI) external;
}

interface IMeemSplitsStandard {
	event SplitsSet(uint256 tokenId, Split[] splits);

	function nonOwnerSplitAllocationAmount() external view returns (uint256);

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) external;

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) external;

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) external;
}

interface IMeemPermissionsStandard {
	event TotalChildrenSet(uint256 tokenId, int256 newTotalChildren);
	event TotalChildrenLocked(uint256 tokenId, address lockedBy);
	event ChildrenPerWalletSet(uint256 tokenId, int256 newTotalChildren);
	event ChildrenPerWalletLocked(uint256 tokenId, address lockedBy);

	event PermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) external;

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) external;

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) external;

	function setTotalChildren(uint256 tokenId, int256 newTotalChildren)
		external;

	function lockTotalChildren(uint256 tokenId) external;

	function setChildrenPerWallet(uint256 tokenId, int256 newChildrenPerWallet)
		external;

	function lockChildrenPerWallet(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error MissingRequiredRole(bytes32 requiredRole);

error NotTokenOwner(uint256 tokenId);

error InvalidNonOwnerSplitAllocationAmount(
	uint256 minAmount,
	uint256 maxAmount
);

error NoRenounceOthers();

error InvalidZeroAddressQuery();

error IndexOutOfRange(uint256 idx, uint256 max);

error TokenNotFound(uint256 tokenId);

error TokenAlreadyExists(uint256 tokenId);

error NoApproveSelf();

error NotApproved();

error ERC721ReceiverNotImplemented();

error ToAddressInvalid(address to);

error NoTransferWrappedNFT(address parentAddress, uint256 parentTokenId);

error NFTAlreadyWrapped(address parentAddress, uint256 parentTokenId);

error PropertyLocked(address lockedBy);

error InvalidPropertyType();

error InvalidPermissionType();

error InvalidTotalChildren(uint256 currentTotalChildren);

error TotalChildrenExceeded();

error ChildrenPerWalletExceeded();

error NoPermission();

error InvalidChildGeneration();

error InvalidParent();

error ChildDepthExceeded();

error MissingRequiredPermissions();

error MissingRequiredSplits();