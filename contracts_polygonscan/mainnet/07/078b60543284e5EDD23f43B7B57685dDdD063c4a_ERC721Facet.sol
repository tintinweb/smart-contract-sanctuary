// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibMeta} from '../libraries/LibMeta.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Base64} from '../libraries/Base64.sol';
import {IERC721} from '../interfaces/IERC721.sol';
import {IERC721Enumerable} from '@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol';
import {IERC721Metadata} from '@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol';
import {ERC721BaseStorage} from '@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol';

contract ERC721Facet is IERC721, IERC721Enumerable, IERC721Metadata {
	function contractURI() public view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(bytes(s.contractURI))
				)
			);
	}

	function contractAddress() public view returns (address) {
		return address(this);
	}

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() public view override returns (uint256 totalSupply_) {
		return LibERC721.totalSupply();
	}

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return tokenId_ The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index)
		public
		view
		override
		returns (uint256 tokenId_)
	{
		return LibERC721.tokenByIndex(_index);
	}

	function ownerOf(uint256 tokenId) public view override returns (address) {
		return LibERC721.ownerOf(tokenId);
	}

	function balanceOf(address _owner)
		public
		view
		override
		returns (uint256 balance)
	{
		return LibERC721.balanceOf(_owner);
	}

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return tokenId_ The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		public
		view
		override
		returns (uint256 tokenId_)
	{
		return LibERC721.tokenOfOwnerByIndex(_owner, _index);
	}

	///@notice Return the universal name of the NFT
	function name() public view override returns (string memory) {
		return LibERC721.name();
	}

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() public view override returns (string memory) {
		return LibERC721.symbol();
	}

	function baseTokenURI() public pure returns (string memory) {
		return LibERC721.baseTokenURI();
	}

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
		return LibERC721.tokenURI(tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function getApproved(uint256 tokenId)
		public
		view
		override
		returns (address)
	{
		return LibERC721.getApproved(tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function isApprovedForAll(address account, address operator)
		public
		view
		override
		returns (bool)
	{
		return LibERC721.isApprovedForAll(account, operator);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override {
		return LibERC721.transferFrom(from, to, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override {
		return LibERC721.safeTransferFrom(from, to, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public payable override {
		return LibERC721._safeTransfer(from, to, tokenId, data);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function approve(address operator, uint256 tokenId)
		public
		payable
		override
	{
		return LibERC721.approve(operator, tokenId);
	}

	/**
	 * @inheritdoc IERC721
	 */
	function setApprovalForAll(address operator, bool status) public override {
		return LibERC721.setApprovalForAll(operator, status);
	}

	function burn(uint256 tokenId) public {
		return LibERC721.burn(tokenId);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		LibERC721._transfer(from, to, tokenId);
	}

	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return LibERC721._exists(tokenId);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		virtual
		returns (bool)
	{
		return LibERC721._isApprovedOrOwner(spender, tokenId);
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
pragma experimental ABIEncoderV2;

import '../interfaces/MeemStandard.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {LibPart} from '../../royalties/LibPart.sol';
import {ERC721ReceiverNotImplemented, PropertyLocked, IndexOutOfRange, InvalidPropertyType, InvalidPermissionType, InvalidTotalChildren, NFTAlreadyWrapped, InvalidNonOwnerSplitAllocationAmount, TotalChildrenExceeded, ChildrenPerWalletExceeded, NoPermission, InvalidChildGeneration, InvalidParent, ChildDepthExceeded, TokenNotFound, MissingRequiredPermissions, MissingRequiredSplits} from '../libraries/Errors.sol';

library LibMeem {
	// Rarible royalties event
	event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

	// MeemStandard events
	event PermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);
	event SplitsSet(uint256 tokenId, Split[] splits);
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);
	event TotalChildrenSet(uint256 tokenId, int256 newTotalChildren);
	event TotalChildrenLocked(uint256 tokenId, address lockedBy);
	event ChildrenPerWalletSet(uint256 tokenId, int256 newTotalChildren);
	event ChildrenPerWalletLocked(uint256 tokenId, address lockedBy);

	function getRaribleV2Royalties(uint256 tokenId)
		internal
		view
		returns (LibPart.Part[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		uint256 numSplits = s.meemProperties[tokenId].splits.length;
		LibPart.Part[] memory parts = new LibPart.Part[](numSplits);
		for (uint256 i = 0; i < s.meemProperties[tokenId].splits.length; i++) {
			parts[i] = LibPart.Part({
				account: payable(s.meemProperties[tokenId].splits[i].toAddress),
				value: uint96(s.meemProperties[tokenId].splits[i].amount)
			});
		}

		return parts;
	}

	function mint(
		address to,
		string memory mTokenURI,
		Chain parentChain,
		address parent,
		uint256 parentTokenId,
		Chain rootChain,
		address root,
		uint256 rootTokenId,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties,
		PermissionType permissionType
	) internal returns (uint256 tokenId_) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.MINTER_ROLE);
		LibMeem.requireValidMeem(parentChain, parent, parentTokenId);
		uint256 tokenId = s.tokenCounter;
		LibERC721._safeMint(to, tokenId);
		s.tokenURIs[tokenId] = mTokenURI;

		if (root == address(this) && parent != address(this)) {
			revert InvalidParent();
		}

		// Initializes mapping w/ default values
		delete s.meems[tokenId];

		s.meems[tokenId].parentChain = parentChain;
		s.meems[tokenId].rootChain = rootChain;
		s.meems[tokenId].parent = parent;
		s.meems[tokenId].parentTokenId = parentTokenId;
		s.meems[tokenId].root = root;
		s.meems[tokenId].rootTokenId = rootTokenId;
		s.meems[tokenId].owner = to;
		s.meems[tokenId].mintedAt = block.timestamp;

		// Set generation of Meem
		if (parent == address(this)) {
			s.meems[tokenId].generation = s.meems[parentTokenId].generation + 1;

			// Merge parent childProperties into this child
			LibMeem.setProperties(
				tokenId,
				PropertyType.Meem,
				mProperties,
				parentTokenId,
				true
			);
			LibMeem.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties,
				parentTokenId,
				true
			);
		} else {
			s.meems[tokenId].generation = 0;
			LibMeem.setProperties(tokenId, PropertyType.Meem, mProperties);
			LibMeem.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties
			);
		}

		if (s.meems[tokenId].generation > s.childDepth) {
			revert ChildDepthExceeded();
		}

		// Keep track of children Meems
		if (parent == address(this)) {
			// Verify token exists
			if (s.meems[parentTokenId].owner == address(0)) {
				revert TokenNotFound(parentTokenId);
			}
			// Verify we can mint based on permissions
			requireCanMintChildOf(to, permissionType, parentTokenId);
			s.children[parentTokenId].push(tokenId);
			s.childrenOwnerTokens[parentTokenId][to].push(tokenId);
		} else if (parent != address(0)) {
			// Keep track of wrapped NFTs
			s.chainWrappedNFTs[parentChain][parent][parentTokenId] = tokenId;
		} else if (parent == address(0)) {
			s.originalMeemTokensIndex[tokenId] = s.originalMeemTokens.length;
			s.originalMeemTokens.push(tokenId);
		}

		if (root == address(this)) {
			s.decendants[rootTokenId].push(tokenId);
		}

		s.tokenCounter += 1;

		if (!LibERC721._checkOnERC721Received(address(0), to, tokenId, '')) {
			revert ERC721ReceiverNotImplemented();
		}

		return tokenId;
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		MeemPermission[] storage perms = getPermissions(props, permissionType);
		perms.push(permission);

		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		if (perms[idx].lockedBy != address(0)) {
			revert PropertyLocked(perms[idx].lockedBy);
		}

		if (idx >= perms.length) {
			revert IndexOutOfRange(idx, perms.length - 1);
		}

		for (uint256 i = idx; i < perms.length - 1; i++) {
			perms[i] = perms[i + 1];
		}

		perms.pop();
		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);

		if (perms[idx].lockedBy != address(0)) {
			revert PropertyLocked(perms[idx].lockedBy);
		}

		perms[idx] = permission;
		emit PermissionsSet(tokenId, propertyType, permissionType, perms);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);

		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}
		props.splits.push(split);
		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}

		if (props.splits[idx].lockedBy != address(0)) {
			revert PropertyLocked(props.splits[idx].lockedBy);
		}

		if (idx >= props.splits.length) {
			revert IndexOutOfRange(idx, props.splits.length - 1);
		}

		for (uint256 i = idx; i < props.splits.length - 1; i++) {
			props.splits[i] = props.splits[i + 1];
		}

		props.splits.pop();
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		if (props.splitsLockedBy != address(0)) {
			revert PropertyLocked(props.splitsLockedBy);
		}

		if (props.splits[idx].lockedBy != address(0)) {
			revert PropertyLocked(props.splits[idx].lockedBy);
		}

		props.splits[idx] = split;
		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);
		emit SplitsSet(tokenId, props.splits);
		emit RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function getMeem(uint256 tokenId) internal view returns (Meem memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		Meem memory meem = Meem(
			s.meems[tokenId].owner,
			s.meems[tokenId].parentChain,
			s.meems[tokenId].parent,
			s.meems[tokenId].parentTokenId,
			s.meems[tokenId].rootChain,
			s.meems[tokenId].root,
			s.meems[tokenId].rootTokenId,
			s.meems[tokenId].generation,
			s.meemProperties[tokenId],
			s.meemChildProperties[tokenId],
			s.meems[tokenId].mintedAt
		);

		return meem;
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (propertyType == PropertyType.Meem) {
			return s.meemProperties[tokenId];
		} else if (propertyType == PropertyType.Child) {
			return s.meemChildProperties[tokenId];
		}

		revert InvalidPropertyType();
	}

	// Merges the base properties with any overrides
	function mergeProperties(
		MeemProperties memory baseProperties,
		MeemProperties memory overrideProps
	) internal pure returns (MeemProperties memory) {
		MeemProperties memory mergedProps = baseProperties;

		if (overrideProps.totalChildrenLockedBy != address(0)) {
			mergedProps.totalChildrenLockedBy = overrideProps
				.totalChildrenLockedBy;
			mergedProps.totalChildren = overrideProps.totalChildren;
		}

		if (overrideProps.childrenPerWalletLockedBy != address(0)) {
			mergedProps.childrenPerWalletLockedBy = overrideProps
				.childrenPerWalletLockedBy;
			mergedProps.childrenPerWallet = overrideProps.childrenPerWallet;
		}

		// Merge / validate properties
		if (overrideProps.copyPermissionsLockedBy != address(0)) {
			mergedProps.copyPermissionsLockedBy = overrideProps
				.copyPermissionsLockedBy;
			mergedProps.copyPermissions = overrideProps.copyPermissions;
		} else {
			validatePermissions(
				mergedProps.copyPermissions,
				overrideProps.copyPermissions
			);
		}

		if (overrideProps.remixPermissionsLockedBy != address(0)) {
			mergedProps.remixPermissionsLockedBy = overrideProps
				.remixPermissionsLockedBy;
			mergedProps.remixPermissions = overrideProps.remixPermissions;
		} else {
			validatePermissions(
				mergedProps.remixPermissions,
				overrideProps.remixPermissions
			);
		}

		if (overrideProps.readPermissionsLockedBy != address(0)) {
			mergedProps.readPermissionsLockedBy = overrideProps
				.readPermissionsLockedBy;
			mergedProps.readPermissions = overrideProps.readPermissions;
		} else {
			validatePermissions(
				mergedProps.readPermissions,
				overrideProps.readPermissions
			);
		}

		// Validate splits
		if (overrideProps.splitsLockedBy != address(0)) {
			mergedProps.splitsLockedBy = overrideProps.splitsLockedBy;
			mergedProps.splits = overrideProps.splits;
		} else {
			validateOverrideSplits(mergedProps.splits, overrideProps.splits);
		}

		return mergedProps;
	}

	function validatePermissions(
		MeemPermission[] memory basePermissions,
		MeemPermission[] memory overridePermissions
	) internal pure {
		for (uint256 i = 0; i < overridePermissions.length; i++) {
			if (overridePermissions[i].lockedBy != address(0)) {
				// Find the permission in basePermissions
				bool wasFound = false;
				for (uint256 j = 0; j < basePermissions.length; j++) {
					if (
						basePermissions[j].lockedBy ==
						overridePermissions[i].lockedBy &&
						basePermissions[j].permission ==
						overridePermissions[i].permission &&
						basePermissions[j].numTokens ==
						overridePermissions[i].numTokens &&
						addressArraysMatch(
							basePermissions[j].addresses,
							overridePermissions[i].addresses
						)
					) {
						wasFound = true;
						break;
					}
				}
				if (!wasFound) {
					revert MissingRequiredPermissions();
				}
			}
		}
	}

	function validateOverrideSplits(
		Split[] memory baseSplits,
		Split[] memory overrideSplits
	) internal pure {
		for (uint256 i = 0; i < overrideSplits.length; i++) {
			if (overrideSplits[i].lockedBy != address(0)) {
				// Find the permission in basePermissions
				bool wasFound = false;
				for (uint256 j = 0; j < baseSplits.length; j++) {
					if (
						baseSplits[j].lockedBy == overrideSplits[i].lockedBy &&
						baseSplits[j].amount == overrideSplits[i].amount &&
						baseSplits[j].toAddress == overrideSplits[i].toAddress
					) {
						wasFound = true;
						break;
					}
				}
				if (!wasFound) {
					revert MissingRequiredSplits();
				}
			}
		}
	}

	function addressArraysMatch(address[] memory arr1, address[] memory arr2)
		internal
		pure
		returns (bool)
	{
		if (arr1.length != arr2.length) {
			return false;
		}

		for (uint256 i = 0; i < arr1.length; i++) {
			if (arr1[i] != arr2[i]) {
				return false;
			}
		}

		return true;
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		setProperties(tokenId, propertyType, mProperties, 0, false);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties,
		uint256 parentTokenId,
		bool mergeParent
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);
		MeemProperties memory newProps = mProperties;
		if (mergeParent) {
			newProps = mergeProperties(
				mProperties,
				s.meemChildProperties[parentTokenId]
			);
		}

		for (uint256 i = 0; i < newProps.copyPermissions.length; i++) {
			props.copyPermissions.push(newProps.copyPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.remixPermissions.length; i++) {
			props.remixPermissions.push(newProps.remixPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.readPermissions.length; i++) {
			props.readPermissions.push(newProps.readPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.splits.length; i++) {
			props.splits.push(newProps.splits[i]);
		}

		props.totalChildren = newProps.totalChildren;
		props.totalChildrenLockedBy = newProps.totalChildrenLockedBy;
		props.childrenPerWallet = newProps.childrenPerWallet;
		props.childrenPerWalletLockedBy = newProps.childrenPerWalletLockedBy;
		props.copyPermissionsLockedBy = newProps.copyPermissionsLockedBy;
		props.remixPermissionsLockedBy = newProps.remixPermissionsLockedBy;
		props.readPermissionsLockedBy = newProps.readPermissionsLockedBy;
		props.splitsLockedBy = newProps.splitsLockedBy;

		validateSplits(
			props,
			LibERC721.ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount
		);

		emit PropertiesSet(tokenId, propertyType, props);
	}

	function permissionNotLocked(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view {
		if (permissionType == PermissionType.Copy) {
			if (self.copyPermissionsLockedBy != address(0)) {
				revert PropertyLocked(self.copyPermissionsLockedBy);
			}
		} else if (permissionType == PermissionType.Remix) {
			if (self.remixPermissionsLockedBy != address(0)) {
				revert PropertyLocked(self.remixPermissionsLockedBy);
			}
		} else if (permissionType == PermissionType.Read) {
			if (self.readPermissionsLockedBy != address(0)) {
				revert PropertyLocked(self.readPermissionsLockedBy);
			}
		}
	}

	function validateSplits(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) internal view {
		// Ensure addresses are unique
		for (uint256 i = 0; i < self.splits.length; i++) {
			address split1 = self.splits[i].toAddress;

			for (uint256 j = 0; j < self.splits.length; j++) {
				address split2 = self.splits[j].toAddress;
				if (i != j && split1 == split2) {
					revert('Split addresses must be unique');
				}
			}
		}

		uint256 totalAmount = 0;
		uint256 totalAmountOfNonOwner = 0;
		// Require that split amounts
		for (uint256 i = 0; i < self.splits.length; i++) {
			totalAmount += self.splits[i].amount;
			if (self.splits[i].toAddress != tokenOwner) {
				totalAmountOfNonOwner += self.splits[i].amount;
			}
		}

		if (
			totalAmount > 10000 ||
			totalAmountOfNonOwner < nonOwnerSplitAllocationAmount
		) {
			revert InvalidNonOwnerSplitAllocationAmount(
				nonOwnerSplitAllocationAmount,
				10000
			);
		}
	}

	function getPermissions(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view returns (MeemPermission[] storage) {
		if (permissionType == PermissionType.Copy) {
			return self.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			return self.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			return self.readPermissions;
		}

		revert InvalidPermissionType();
	}

	function setTotalChildren(uint256 tokenId, int256 newTotalChildren)
		internal
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (newTotalChildren > -1) {
			if (uint256(newTotalChildren) < s.children[tokenId].length) {
				revert InvalidTotalChildren(s.children[tokenId].length);
			}
		}

		if (s.meemProperties[tokenId].totalChildrenLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].totalChildrenLockedBy
			);
		}

		s.meemProperties[tokenId].totalChildren = newTotalChildren;
		emit TotalChildrenSet(tokenId, newTotalChildren);
	}

	function lockTotalChildren(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (s.meemProperties[tokenId].totalChildrenLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].totalChildrenLockedBy
			);
		}

		s.meemProperties[tokenId].totalChildrenLockedBy = msg.sender;
		emit TotalChildrenLocked(tokenId, msg.sender);
	}

	function setChildrenPerWallet(uint256 tokenId, int256 newTotalChildren)
		internal
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (s.meemProperties[tokenId].childrenPerWalletLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].childrenPerWalletLockedBy
			);
		}

		s.meemProperties[tokenId].childrenPerWallet = newTotalChildren;
		emit ChildrenPerWalletSet(tokenId, newTotalChildren);
	}

	function lockChildrenPerWallet(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibERC721.requireOwnsToken(tokenId);

		if (s.meemProperties[tokenId].childrenPerWalletLockedBy != address(0)) {
			revert PropertyLocked(
				s.meemProperties[tokenId].childrenPerWalletLockedBy
			);
		}

		s.meemProperties[tokenId].childrenPerWalletLockedBy = msg.sender;
		emit ChildrenPerWalletLocked(tokenId, msg.sender);
	}

	function requireValidMeem(
		Chain chain,
		address parent,
		uint256 tokenId
	) internal view {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		// Meem must be unique address(0) or not have a corresponding parent / tokenId already minted
		if (parent != address(0) && parent != address(this)) {
			if (s.chainWrappedNFTs[chain][parent][tokenId] != 0) {
				revert NFTAlreadyWrapped(parent, tokenId);
				// revert('NFT_ALREADY_WRAPPED');
			}
		}
	}

	function isNFTWrapped(
		Chain chainId,
		address contractAddress,
		uint256 tokenId
	) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.chainWrappedNFTs[chainId][contractAddress][tokenId] != 0) {
			return true;
		}

		return false;
	}

	function wrappedTokens(WrappedItem[] memory items)
		internal
		view
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		uint256[] memory result = new uint256[](items.length);

		for (uint256 i = 0; i < items.length; i++) {
			result[i] = s.chainWrappedNFTs[items[i].chain][
				items[i].contractAddress
			][items[i].tokenId];
		}

		return result;
	}

	// Checks if "to" can mint a child of tokenId
	function requireCanMintChildOf(
		address to,
		PermissionType permissionType,
		uint256 tokenId
	) internal view {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemBase storage parent = s.meems[tokenId];
		MeemProperties storage parentProperties = s.meemProperties[tokenId];
		uint256 currentChildren = s.children[tokenId].length;

		// Check total children
		if (
			parentProperties.totalChildren >= 0 &&
			currentChildren + 1 > uint256(parentProperties.totalChildren)
		) {
			revert TotalChildrenExceeded();
		}

		// Check total children per wallet
		uint256 numChildrenAlreadyHeld = s
		.childrenOwnerTokens[tokenId][to].length;
		if (
			parentProperties.childrenPerWallet >= 0 &&
			numChildrenAlreadyHeld + 1 >
			uint256(parentProperties.childrenPerWallet)
		) {
			revert ChildrenPerWalletExceeded();
		}

		// Check permissions
		MeemPermission[] storage perms = getPermissions(
			parentProperties,
			permissionType
		);

		bool hasPermission = false;
		for (uint256 i = 0; i < perms.length; i++) {
			MeemPermission storage perm = perms[i];
			if (
				// Allowed if permission is anyone
				perm.permission == Permission.Anyone ||
				// Allowed if permission is owner and this is the owner
				(perm.permission == Permission.Owner && parent.owner == to)
			) {
				hasPermission = true;
				break;
			} else if (perm.permission == Permission.Addresses) {
				// Allowed if to is in the list of approved addresses
				for (uint256 j = 0; j < perm.addresses.length; j++) {
					if (perm.addresses[j] == to) {
						hasPermission = true;
						break;
					}
				}

				if (hasPermission) {
					break;
				}
			}
		}

		if (!hasPermission) {
			revert NoPermission();
		}
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

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibArray} from '../libraries/LibArray.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem} from '../interfaces/MeemStandard.sol';
import {NotTokenOwner, InvalidZeroAddressQuery, IndexOutOfRange, TokenNotFound, NotApproved, NoApproveSelf, ERC721ReceiverNotImplemented, TokenAlreadyExists, ToAddressInvalid, NoTransferWrappedNFT} from '../libraries/Errors.sol';
import '../interfaces/IERC721TokenReceiver.sol';

library LibERC721 {
	/**
	 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
	 */
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
	 */
	event Approval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	 */
	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	function requireOwnsToken(uint256 tokenId) internal view {
		if (ownerOf(tokenId) != msg.sender) {
			revert NotTokenOwner(tokenId);
		}
	}

	function burn(uint256 tokenId) internal {
		requireOwnsToken(tokenId);

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = ownerOf(tokenId);

		_beforeTokenTransfer(owner, address(0), tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		// Make zero address new owner
		uint256 index = s.ownerTokenIdIndexes[owner][tokenId];
		s.ownerTokenIds[owner] = LibArray.removeAt(
			s.ownerTokenIds[owner],
			index
		);
		delete s.ownerTokenIdIndexes[owner][tokenId];

		s.ownerTokenIds[address(0)].push(tokenId);
		s.ownerTokenIdIndexes[address(0)][tokenId] =
			s.ownerTokenIds[address(0)].length -
			1;

		emit Transfer(owner, address(0), tokenId);
	}

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.allTokens.length;
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (owner == address(0)) {
			revert InvalidZeroAddressQuery();
		}
		return s.ownerTokenIds[owner].length;
	}

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return tokenId_ The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index)
		internal
		view
		returns (uint256 tokenId_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (_index >= s.allTokens.length) {
			revert IndexOutOfRange(_index, s.allTokens.length - 1);
		}
		tokenId_ = s.allTokens[_index];
	}

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return tokenId_ The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		internal
		view
		returns (uint256 tokenId_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (_index >= s.ownerTokenIds[_owner].length) {
			revert IndexOutOfRange(_index, s.ownerTokenIds[_owner].length - 1);
		}
		tokenId_ = s.ownerTokenIds[_owner][_index];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) internal view returns (address) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = s.meems[tokenId].owner;
		if (owner == address(0)) {
			revert TokenNotFound(tokenId);
		}
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.symbol;
	}

	function tokenURI(uint256 tokenId) internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!_exists(tokenId)) {
			revert TokenNotFound(tokenId);
		}

		return s.tokenURIs[tokenId];
	}

	/**
	 * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
	 * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
	 * by default, can be overriden in child contracts.
	 */
	function _baseURI() internal pure returns (string memory) {
		return '';
	}

	function baseTokenURI() internal pure returns (string memory) {
		return 'https://meem.wtf/tokens/';
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) internal {
		address owner = ownerOf(tokenId);

		if (to == owner) {
			revert NoApproveSelf();
		}

		if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
			revert NotApproved();
		}

		_approve(to, tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) internal view returns (address) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!_exists(tokenId)) {
			revert TokenNotFound(tokenId);
		}

		return s.tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (operator == _msgSender()) {
			revert NoApproveSelf();
		}

		s.operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address owner, address operator)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.operatorApprovals[owner][operator];
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) internal {
		if (
			!_isApprovedOrOwner(_msgSender(), tokenId) &&
			!_canFacilitateClaim(_msgSender(), tokenId)
		) {
			revert NotApproved();
		}

		_transfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) internal {
		safeTransferFrom(from, to, tokenId, '');
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
			revert NotApproved();
		}

		_safeTransfer(from, to, tokenId, _data);
	}

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
	 *
	 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
	 * implement alternative mechanisms to perform token transfer, such as signature-based.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		_transfer(from, to, tokenId);

		if (!_checkOnERC721Received(from, to, tokenId, _data)) {
			revert ERC721ReceiverNotImplemented();
		}
	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 * and stop existing when they are burned (`_burn`).
	 */
	function _exists(uint256 tokenId) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.mintedTokens[tokenId];
	}

	/**
	 * @dev Returns whether `spender` is allowed to manage `tokenId`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		if (!_exists(tokenId)) {
			revert TokenNotFound(tokenId);
		}
		address _owner = ownerOf(tokenId);
		return (spender == _owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(_owner, spender));
	}

	/**
	 * @dev Safely mints `tokenId` and transfers it to `to`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeMint(address to, uint256 tokenId) internal {
		_safeMint(to, tokenId, '');
	}

	/**
	 * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
	 * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
	 */
	function _safeMint(
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		_mint(to, tokenId);

		if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
			revert ERC721ReceiverNotImplemented();
		}
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - `to` cannot be the zero address.
	 *
	 * Emits a {Transfer} event.
	 */
	function _mint(address to, uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (to == address(0)) {
			revert ToAddressInvalid(to);
		}

		if (_exists(tokenId)) {
			revert TokenAlreadyExists(tokenId);
		}

		_beforeTokenTransfer(address(0), to, tokenId);

		s.allTokens.push(tokenId);
		s.allTokensIndex[tokenId] = s.allTokens.length;
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length - 1;
		s.mintedTokens[tokenId] = true;

		emit Transfer(address(0), to, tokenId);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		bool canFacilitateClaim = _canFacilitateClaim(_msgSender(), tokenId);

		if (ownerOf(tokenId) != from && !canFacilitateClaim) {
			revert NotTokenOwner(tokenId);
		}

		if (to == address(0)) {
			revert ToAddressInvalid(address(0));
		}

		if (!canFacilitateClaim) {
			_beforeTokenTransfer(from, to, tokenId);
		}

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		uint256 index = s.ownerTokenIdIndexes[from][tokenId];
		LibArray.removeAt(s.ownerTokenIds[from], index);
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length;
		s.meems[tokenId].owner = to;

		emit Transfer(from, to, tokenId);
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
	}

	/**
	 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
	 * The call is not executed if the target address is not a contract.
	 *
	 * @param from address representing the previous owner of the given token ID
	 * @param to target address that will receive the tokens
	 * @param tokenId uint256 ID of the token to be transferred
	 * @param _data bytes optional data to send along with the call
	 * @return bool whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal returns (bool) {
		if (isContract(to)) {
			try
				IERC721TokenReceiver(to).onERC721Received(
					_msgSender(),
					from,
					tokenId,
					_data
				)
			returns (bytes4 retval) {
				return retval == IERC721TokenReceiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert ERC721ReceiverNotImplemented();
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	function _checkOnERC721Received(
		address _operator,
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal {
		uint256 size;
		assembly {
			size := extcodesize(_to)
		}
		if (size > 0) {
			require(
				ERC721_RECEIVED ==
					IERC721TokenReceiver(_to).onERC721Received(
						_operator,
						_from,
						_tokenId,
						_data
					),
				'LibERC721: Transfer rejected/failed by _to'
			);
		}
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning.
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal view {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (
			s.meems[tokenId].parent != address(this) &&
			s.meems[tokenId].parent != address(0)
		) {
			revert NoTransferWrappedNFT(
				s.meems[tokenId].parent,
				s.meems[tokenId].parentTokenId
			);
		}

		if (from == to) {
			revert ToAddressInvalid(to);
		}
	}

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function _canFacilitateClaim(address user, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		Meem memory meem = LibMeem.getMeem(tokenId);
		bool isAdmin = LibAccessControl.hasRole(s.ADMIN_ROLE, user);
		if (
			!isAdmin ||
			meem.parent == address(0) ||
			meem.parent == address(this)
		) {
			// Meem is an original or a child of another meem and can only be transferred by the owner
			return false;
		}

		return true;
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

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return '';

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((len + 2) / 3);

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
				let i := 0
			} lt(i, len) {

			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)

				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
				)
				out := shl(224, out)

				mstore(resultPtr, out)

				resultPtr := add(resultPtr, 4)
			}

			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}

			mstore(result, encodedLen)
		}

		return string(result);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721Internal} from '@solidstate/contracts/token/ERC721/IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal {
	/**
	 * @notice query the balance of given address
	 * @return balance quantity of tokens held
	 */
	function balanceOf(address account) external view returns (uint256 balance);

	/**
	 * @notice query the owner of given token
	 * @param tokenId token to query
	 * @return owner token owner
	 */
	function ownerOf(uint256 tokenId) external view returns (address owner);

	/**
	 * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
	 * @param from sender of token
	 * @param to receiver of token
	 * @param tokenId token id
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external payable;

	/**
	 * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
	 * @param from sender of token
	 * @param to receiver of token
	 * @param tokenId token id
	 * @param data data payload
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata data
	) external payable;

	/**
	 * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
	 * @param from sender of token
	 * @param to receiver of token
	 * @param tokenId token id
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external payable;

	/**
	 * @notice grant approval to given account to spend token
	 * @param operator address to be approved
	 * @param tokenId token to approve
	 */
	function approve(address operator, uint256 tokenId) external payable;

	/**
	 * @notice get approval status for given token
	 * @param tokenId token to query
	 * @return operator address approved to spend token
	 */
	function getApproved(uint256 tokenId)
		external
		view
		returns (address operator);

	/**
	 * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
	 * @param operator address to be approved
	 * @param status approval status
	 */
	function setApprovalForAll(address operator, bool status) external;

	/**
	 * @notice query approval status of given operator with respect to given address
	 * @param account address to query for approval granted
	 * @param operator address to query for approval received
	 * @return status whether operator is approved to spend tokens held by account
	 */
	function isApprovedForAll(address account, address operator)
		external
		view
		returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(uint256 tokenId) internal view returns (bool) {
        return ERC721BaseStorage.layout().tokenOwners.contains(tokenId);
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
}

struct WrappedItem {
	Chain chain;
	address contractAddress;
	uint256 tokenId;
}

interface IMeemBaseStandard {
	event PropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);

	function mint(
		address to,
		string memory mTokenURI,
		Chain parentChain,
		address parent,
		uint256 parentTokenId,
		Chain rootChain,
		address root,
		uint256 rootTokenId,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		PermissionType permissionType
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

library LibPart {
	bytes32 public constant TYPE_HASH =
		keccak256('Part(address account,uint96 value)');

	struct Part {
		address payable account;
		uint96 value;
	}

	function hash(Part memory part) internal pure returns (bytes32) {
		return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
	}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibArray {
	function removeAt(uint256[] storage array, uint256 index)
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

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes calldata _data
	) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        return map._entries[keyIndex - 1]._value;
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            uint256 index = keyIndex - 1;
            MapEntry storage last = map._entries[map._entries.length - 1];

            // move last entry to now-vacant index

            map._entries[index] = last;
            map._indexes[last._key] = index + 1;

            // clear last index

            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes32 last = set._values[set._values.length - 1];

            // move last value to now-vacant index

            set._values[index] = last;
            set._indexes[last] = index + 1;

            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}