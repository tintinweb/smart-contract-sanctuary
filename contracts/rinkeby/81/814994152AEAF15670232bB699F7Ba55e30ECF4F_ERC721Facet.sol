// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {LibStrings} from '../libraries/LibStrings.sol';
import {AppStorage} from '../libraries/LibAppStorage.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
// import "hardhat/console.sol";
import {LibMeta} from '../libraries/LibMeta.sol';
import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Base64} from '../libraries/Base64.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC165} from '../interfaces/IERC165.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {ERC721Tradable} from '../libraries/ERC721Tradable.sol';
import {IERC173} from '../interfaces/IERC173.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Facet is
	IERC721,
	IERC721Enumerable,
	IERC721Metadata,
	IERC721Receiver
{
	AppStorage internal s;

	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes calldata _data
	) public override returns (bytes4) {}

	function setContractURI(string memory newContractURI) public {
		LibAccessControl.requireRole(s.DEFAULT_ADMIN_ROLE);
		s.contractURI = newContractURI;
	}

	function contractURI() public view returns (string memory) {
		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(bytes(s.contractURI))
				)
			);
	}

	function DEFAULT_ADMIN_ROLE() public view returns (bytes32) {
		return s.DEFAULT_ADMIN_ROLE;
	}

	function PAUSER_ROLE() public view returns (bytes32) {
		return s.PAUSER_ROLE;
	}

	function MINTER_ROLE() public view returns (bytes32) {
		return s.MINTER_ROLE;
	}

	function UPGRADER_ROLE() public view returns (bytes32) {
		return s.UPGRADER_ROLE;
	}

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() public view override returns (uint256 totalSupply_) {
		return LibERC721.totalSupply();
	}

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this.
	///  function throws for queries about the zero address.
	/// @param owner An address for whom to query the balance
	/// @return balance The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address owner)
		public
		view
		override
		returns (uint256 balance)
	{
		return LibERC721.balanceOf(owner);
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

	/// @notice Get all the Ids of NFTs owned by an address
	/// @param _owner The address to check for the NFTs
	/// @return tokenIds_ an array of unsigned integers,each representing the tokenId of each NFT
	function tokenIdsOfOwner(address _owner)
		public
		view
		returns (uint256[] memory tokenIds_)
	{
		return LibERC721.tokenIdsOfOwner(_owner);
	}

	/// @notice Get all details about all the NFTs owned by an address
	/// @param _owner The address to check for the NFTs
	/// @return meemInfos_ an array of structs,where each struct contains all the details of each NFT
	// function allMeemsOfOwner(address _owner)
	// 	external
	// 	view
	// 	returns (MeemInfo[] memory meemInfos_)
	// {
	// 	uint256 length = s.ownerTokenIds[_owner].length;
	// 	meemInfos_ = new MeemInfo[](length);
	// 	for (uint256 i; i < length; i++) {
	// 		meemInfos_[i] = LibAavegotchi.getAavegotchi(
	// 			s.ownerTokenIds[_owner][i]
	// 		);
	// 	}
	// }

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param tokenId The identifier for an NFT
	/// @return owner The address of the owner of the NFT
	function ownerOf(uint256 tokenId)
		public
		view
		override
		returns (address owner)
	{
		return LibERC721.ownerOf(tokenId);
	}

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param tokenId The NFT to find the approved address for
	/// @return operator The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 tokenId)
		public
		view
		override
		returns (address operator)
	{
		require(tokenId < s.tokenCounter, 'ERC721: tokenId is invalid');
		operator = s.approved[tokenId];
	}

	/// @notice Query if an address is an authorized operator for another address
	/// @param owner The address that owns the NFTs
	/// @param operator The address that acts on behalf of the owner
	/// @return approved_ True if `_operator` is an approved operator for `_owner`, false otherwise
	// function isApprovedForAll(address owner, address operator)
	// 	public
	// 	view
	// 	override
	// 	returns (bool)
	// {
	// 	// Whitelist OpenSea proxy contract for easy trading.
	// 	ProxyRegistry proxyRegistry = ProxyRegistry(s.proxyRegistryAddress);
	// 	if (address(proxyRegistry.proxies(owner)) == operator) {
	// 		return true;
	// 	}

	// 	return s.operators[owner][operator];
	// }

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param from The current owner of the NFT
	/// @param to The new owner
	/// @param tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata _data
	) public override {
		address sender = LibMeta.msgSender();
		internalTransferFrom(sender, from, to, tokenId);
		LibERC721._checkOnERC721Received(sender, from, to, tokenId, _data);
	}

	// @notice Transfers the ownership of multiple  NFTs from one address to another at once
	/// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
	///  operator, or the approved address of each of the NFTs in `_tokenIds`. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if one of the NFTs in
	///  `_tokenIds` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFTs
	/// @param _to The new owner
	/// @param _tokenIds An array containing the identifiers of the NFTs to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeBatchTransferFrom(
		address _from,
		address _to,
		uint256[] calldata _tokenIds,
		bytes calldata _data
	) external {
		address sender = LibMeta.msgSender();
		for (uint256 index = 0; index < _tokenIds.length; index++) {
			uint256 _tokenId = _tokenIds[index];
			internalTransferFrom(sender, _from, _to, _tokenId);
			LibERC721._checkOnERC721Received(
				sender,
				_from,
				_to,
				_tokenId,
				_data
			);
		}
	}

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param from The current owner of the NFT
	/// @param to The new owner
	/// @param tokenId The NFT to transfer
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override {
		address sender = LibMeta.msgSender();
		internalTransferFrom(sender, from, to, tokenId);
		LibERC721._checkOnERC721Received(sender, from, to, tokenId, '');
	}

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `LibMeta.msgSender()` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param from The current owner of the NFT
	/// @param to The new owner
	/// @param tokenId The NFT to transfer
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override {
		internalTransferFrom(LibMeta.msgSender(), from, to, tokenId);
	}

	function internalTransferFrom(
		address _sender,
		address _from,
		address _to,
		uint256 _tokenId
	) internal {
		require(_to != address(0), "ERC721Facet: Can't transfer to 0 address");
		require(_from != address(0), "ERC721Facet: _from can't be 0 address");
		require(
			_from == s.meems[_tokenId].owner,
			'ERC721Facet: _from is not owner, transfer failed'
		);
		require(
			_sender == _from ||
				s.operators[_from][_sender] ||
				_sender == s.approved[_tokenId],
			'ERC721Facet: Not owner or approved to transfer'
		);
		LibMeem.transfer(_from, _to, _tokenId);
		// LibERC721Marketplace.updateERC721Listing(
		// 	address(this),
		// 	_tokenId,
		// 	_from
		// );
	}

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `LibMeta.msgSender()` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param to The new approved NFT controller
	/// @param tokenId The NFT to approve
	function approve(address to, uint256 tokenId) public override {
		address owner = s.meems[tokenId].owner;
		require(
			owner == LibMeta.msgSender() ||
				s.operators[owner][LibMeta.msgSender()],
			'ERC721: Not owner or operator of token.'
		);
		s.approved[tokenId] = to;
		emit LibERC721.Approval(owner, to, tokenId);
	}

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `LibMeta.msgSender()`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address operator, bool _approved)
		public
		override
	{
		s.operators[LibMeta.msgSender()][operator] = _approved;
		emit LibERC721.ApprovalForAll(LibMeta.msgSender(), operator, _approved);
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
		return 'https://meem.wtf/tokens';
	}

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 tokenId)
		public
		pure
		override
		returns (string memory)
	{
		// return s.tokenURIs[_tokenId];
		return
			'https://raw.githubusercontent.com/meemproject/metadata/master/meem/1.json';
	}

	function isApprovedForAll(address owner, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(s.proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return false;
		// return super.isApprovedForAll(owner, operator);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		return
			interfaceId == type(IERC165).interfaceId ||
			interfaceId == type(IERC173).interfaceId ||
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			interfaceId == type(IERC721Receiver).interfaceId ||
			interfaceId == type(IERC721Enumerable).interfaceId;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
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
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibMeta} from '../libraries/LibMeta.sol';
import {Meem, Chain} from './MeemStandard.sol';

struct RoleData {
	mapping(address => bool) members;
	bytes32 adminRole;
}

struct AppStorage {
	address proxyRegistryAddress;
	/** AccessControl Role: Admin */
	bytes32 DEFAULT_ADMIN_ROLE;
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
	// uint32[] tokenIds;
	/** Mapping of addresses => all tokens they own */
	mapping(address => uint256[]) ownerTokenIds;
	/** Mapping of addresses => number of tokens owned */
	mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
	/** Mapping of token to approved address */
	mapping(uint256 => address) approved;
	/** Mapping of address to operators */
	mapping(address => mapping(address => bool)) operators;
	/** Mapping of token => Meem data  */
	mapping(uint256 => Meem) meems;
	/** The minimum amount that must be allocated to non-owners of a token in splits */
	uint256 nonOwnerSplitAllocationAmount;
	/** The contract URI. Used to describe this NFT collection */
	string contractURI;
	/** The depth allowed for minting of children. If 0, no child copies are allowed. */
	uint256 copyDepth;
	/** Mapping of token => URIs for each token */
	mapping(uint256 => string) tokenURIs;
	/** Mapping of token to all children */
	mapping(uint256 => uint256[]) children;
	/** Keeps track of assigned roles */
	mapping(bytes32 => RoleData) roles;
	/** Mapping from token ID to owner address */
	mapping(uint256 => address) owners;
	// Mapping owner address to token count
	// mapping(address => uint256) balances;

	/** Mapping from token ID to approved address */
	mapping(uint256 => address) tokenApprovals;
	/** Mapping from owner to operator approvals */
	mapping(address => mapping(address => bool)) operatorApprovals;
}

library LibAppStorage {
	function diamondStorage() internal pure returns (AppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}

	function abs(int256 x) internal pure returns (uint256) {
		return uint256(x >= 0 ? x : -x);
	}
}

contract Modifiers {
	AppStorage internal s;
	modifier onlyTokenOwner(uint256 _tokenId) {
		require(
			LibMeta.msgSender() == s.meems[_tokenId].owner,
			'LibAppStorage: Only aavegotchi owner can call this function'
		);
		_;
	}

	modifier onlyContractOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import './MeemStandard.sol';
import './MeemPropsLibrary.sol';
import {AppStorage, LibAppStorage} from './LibAppStorage.sol';
import {LibERC721} from '../libraries/LibERC721.sol';

library LibMeem {
	using MeemPropsLibrary for MeemProperties;

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.addPermission(permissionType, permission);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.removePermissionAt(permissionType, idx);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.updatePermissionAt(permissionType, idx, permission);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.addSplit(
			ownerOf(tokenId),
			s.nonOwnerSplitAllocationAmount,
			split
		);
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) internal {
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.removeSplitAt(idx);
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		requireOwnsToken(tokenId);
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.updateSplitAt(
			ownerOf(tokenId),
			idx,
			s.nonOwnerSplitAllocationAmount,
			split
		);
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		AppStorage storage s = LibAppStorage.diamondStorage();

		if (propertyType == PropertyType.Meem) {
			// return _properties[tokenId];
			return s.meems[tokenId].properties;
		} else if (propertyType == PropertyType.Child) {
			// return _childProperties[tokenId];
			return s.meems[tokenId].childProperties;
		}

		revert('Invalid property type');
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = getProperties(tokenId, propertyType);
		props.setProperties(mProperties);
		props.validateSplits(ownerOf(tokenId), s.nonOwnerSplitAllocationAmount);
	}

	function requireOwnsToken(uint256 tokenId) internal view {
		// require(
		// 	ownerOf(tokenId) == msg.sender ||
		// 		hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
		// 	'Not owner of token'
		// );
		require(ownerOf(tokenId) == msg.sender, 'Not owner of token');
	}

	function ownerOf(uint256 _tokenId) internal view returns (address owner_) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		owner_ = s.meems[_tokenId].owner;
		require(owner_ != address(0), 'LibMeem: invalid _tokenId');
	}

	function transfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();

		// remove
		uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
		uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
		if (index != lastIndex) {
			uint256 lastTokenId = s.ownerTokenIds[_from][lastIndex];
			s.ownerTokenIds[_from][index] = lastTokenId;
			s.ownerTokenIdIndexes[_from][lastTokenId] = index;
		}
		s.ownerTokenIds[_from].pop();
		delete s.ownerTokenIdIndexes[_from][_tokenId];
		if (s.approved[_tokenId] != address(0)) {
			delete s.approved[_tokenId];
			emit LibERC721.Approval(_from, address(0), _tokenId);
		}
		// add
		s.meems[_tokenId].owner = _to;
		s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
		s.ownerTokenIds[_to].push(_tokenId);
		emit LibERC721.Transfer(_from, _to, _tokenId);
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
import {AppStorage, LibAppStorage} from './LibAppStorage.sol';
import {LibArray} from '../libraries/LibArray.sol';
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

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() internal view returns (uint256 totalSupply_) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		// totalSupply_ = s.tokenIds.length;
		totalSupply_ = s.tokenCounter;
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) internal view returns (uint256) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(
			owner != address(0),
			'ERC721: balance query for the zero address'
		);
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(_index < s.tokenCounter, 'ERC721: index beyond supply');
		// tokenId_ = s.tokenIds[_index];
		tokenId_ = _index;
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(
			_index < s.ownerTokenIds[_owner].length,
			'ERC721Facet: index beyond owner balance'
		);
		tokenId_ = s.ownerTokenIds[_owner][_index];
	}

	/// @notice Get all the Ids of NFTs owned by an address
	/// @param _owner The address to check for the NFTs
	/// @return tokenIds_ an array of unsigned integers,each representing the tokenId of each NFT
	function tokenIdsOfOwner(address _owner)
		internal
		view
		returns (uint256[] memory tokenIds_)
	{
		AppStorage storage s = LibAppStorage.diamondStorage();
		tokenIds_ = s.ownerTokenIds[_owner];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) internal view returns (address) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = s.owners[tokenId];
		require(
			owner != address(0),
			'ERC721: owner query for nonexistent token'
		);
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() internal view returns (string memory) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() internal view returns (string memory) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.symbol;
	}

	function tokenURI(uint256 tokenId) internal view returns (string memory) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(
			_exists(tokenId),
			'ERC721Metadata: URI query for nonexistent token'
		);

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

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) internal {
		address owner = ownerOf(tokenId);
		require(to != owner, 'ERC721: approval to current owner');

		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
			'ERC721: approve caller is not owner nor approved for all'
		);

		_approve(to, tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) internal view returns (address) {
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(
			_exists(tokenId),
			'ERC721: approved query for nonexistent token'
		);

		return s.tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(operator != _msgSender(), 'ERC721: approve to caller');

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
		AppStorage storage s = LibAppStorage.diamondStorage();
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
		//solhint-disable-next-line max-line-length
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);

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
		require(
			_isApprovedOrOwner(_msgSender(), tokenId),
			'ERC721: transfer caller is not owner nor approved'
		);
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
		require(
			_checkOnERC721Received(from, to, tokenId, _data),
			'ERC721: transfer to non ERC721Receiver implementer'
		);
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.owners[tokenId] != address(0);
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
		require(
			_exists(tokenId),
			'ERC721: operator query for nonexistent token'
		);
		address owner = ownerOf(tokenId);
		return (spender == owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(owner, spender));
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
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
			'ERC721: transfer to non ERC721Receiver implementer'
		);
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(to != address(0), 'ERC721: mint to the zero address');
		require(!_exists(tokenId), 'ERC721: token already minted');

		_beforeTokenTransfer(address(0), to, tokenId);

		// s.balances[to] += 1;
		// s.owners[tokenId] = to;
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length;
		s.owners[tokenId] = to;

		emit Transfer(address(0), to, tokenId);
	}

	/**
	 * @dev Destroys `tokenId`.
	 * The approval is cleared when the token is burned.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 *
	 * Emits a {Transfer} event.
	 */
	function _burn(uint256 tokenId) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = ownerOf(tokenId);

		_beforeTokenTransfer(owner, address(0), tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		uint256 index = s.ownerTokenIdIndexes[owner][tokenId];
		LibArray.removeAt(s.ownerTokenIds[owner], index);
		delete s.owners[tokenId];

		emit Transfer(owner, address(0), tokenId);
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		require(
			ownerOf(tokenId) == from,
			'ERC721: transfer of token that is not own'
		);
		require(to != address(0), 'ERC721: transfer to the zero address');

		_beforeTokenTransfer(from, to, tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		uint256 index = s.ownerTokenIdIndexes[from][tokenId];
		LibArray.removeAt(s.ownerTokenIds[from], index);
		s.ownerTokenIds[to].push(tokenId);
		s.owners[tokenId] = to;

		emit Transfer(from, to, tokenId);
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
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
	) private returns (bool) {
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
					revert(
						'ERC721: transfer to non ERC721Receiver implementer'
					);
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

	// function _checkOnERC721Received(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId,
	// 	bytes memory _data
	// ) internal returns (bool) {
	// 	if (to.isContract()) {
	// 		try
	// 			IERC721Receiver(to).onERC721Received(
	// 				_msgSender(),
	// 				from,
	// 				tokenId,
	// 				_data
	// 			)
	// 		returns (bytes4 retval) {
	// 			return retval == IERC721Receiver.onERC721Received.selector;
	// 		} catch (bytes memory reason) {
	// 			if (reason.length == 0) {
	// 				revert(
	// 					'ERC721: transfer to non ERC721Receiver implementer'
	// 				);
	// 			} else {
	// 				assembly {
	// 					revert(add(32, reason), mload(reason))
	// 				}
	// 			}
	// 		}
	// 	} else {
	// 		return true;
	// 	}
	// }

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
		AppStorage storage s = LibAppStorage.diamondStorage();

		require(
			s.meems[tokenId].parent == address(this) ||
				s.meems[tokenId].parent == address(0),
			'Only Meem copies or original works may be transferred'
		);

		require(from != to, 'Token can not be transferred to self');
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol';
import {AppStorage, LibAppStorage} from './LibAppStorage.sol';

library LibAccessControl {
	/**
	 * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
	 *
	 * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
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
	 * @dev Modifier that checks that an account has a specific role. Reverts
	 * with a standardized message including the required role.
	 *
	 * The format of the revert reason is given by the following regular expression:
	 *
	 *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
			revert('Sender does not have required role');
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
		AppStorage storage s = LibAppStorage.diamondStorage();
		return s.roles[role].members[account];
	}

	/**
	 * @dev Revert with a standard message if `account` is missing `role`.
	 *
	 * The format of the revert reason is given by the following regular expression:
	 *
	 *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
	 */
	function _checkRole(bytes32 role, address account) internal view {
		if (!hasRole(role, account)) {
			revert(
				string(
					abi.encodePacked(
						'AccessControl: account ',
						toHexString(uint160(account), 20),
						' is missing role ',
						toHexString(uint256(role), 32)
					)
				)
			);
		}
	}

	/**
	 * @dev Returns the admin role that controls `role`. See {grantRole} and
	 * {revokeRole}.
	 *
	 * To change a role's admin, use {_setRoleAdmin}.
	 */
	function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
		AppStorage storage s = LibAppStorage.diamondStorage();
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
	function grantRole(bytes32 role, address account)
		internal
		onlyRole(getRoleAdmin(role))
	{
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
	function revokeRole(bytes32 role, address account)
		internal
		onlyRole(getRoleAdmin(role))
	{
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
		require(
			account == _msgSender(),
			'AccessControl: can only renounce roles for self'
		);

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
		AppStorage storage s = LibAppStorage.diamondStorage();
		bytes32 previousAdminRole = getRoleAdmin(role);
		s.roles[role].adminRole = adminRole;
		emit RoleAdminChanged(role, previousAdminRole, adminRole);
	}

	function _grantRole(bytes32 role, address account) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
		if (!hasRole(role, account)) {
			s.roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		AppStorage storage s = LibAppStorage.diamondStorage();
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
	/// @notice Query if a contract implements an interface
	/// @param interfaceId The interface identifier, as specified in ERC-165
	/// @dev Interface identification is specified in ERC-165. This function
	///  uses less than 30,000 gas.
	/// @return `true` if the contract implements `interfaceID` and
	///  `interfaceID` is not 0xffffffff, `false` otherwise
	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './ContentMixin.sol';
import './NativeMetaTransaction.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
	ContextMixin,
	ERC721Enumerable,
	NativeMetaTransaction,
	Ownable
{
	using SafeMath for uint256;

	address proxyRegistryAddress;
	uint256 private _currentTokenId = 0;

	constructor(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress
	) ERC721(_name, _symbol) {
		proxyRegistryAddress = _proxyRegistryAddress;
		_initializeEIP712(_name);
	}

	/**
	 * @dev Mints a token to an address with a tokenURI.
	 * @param _to address of the future owner of the token
	 */
	function mintTo(address _to) public onlyOwner {
		uint256 newTokenId = _getNextTokenId();
		_mint(_to, newTokenId);
		_incrementTokenId();
	}

	/**
	 * @dev calculates the next token ID based on value of _currentTokenId
	 * @return uint256 for the next token ID
	 */
	function _getNextTokenId() private view returns (uint256) {
		return _currentTokenId.add(1);
	}

	/**
	 * @dev increments the value of _currentTokenId
	 */
	function _incrementTokenId() private {
		_currentTokenId++;
	}

	function baseTokenURI() public pure virtual returns (string memory);

	function tokenURI(uint256 _tokenId)
		public
		pure
		override
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
			);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	/**
	 * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
	 */
	function _msgSender() internal view override returns (address sender) {
		return ContextMixin.msgSender();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
	/// @notice Get the address of the owner
	/// @return owner_ The address of the owner.
	function owner() external view returns (address owner_);

	/// @notice Set the address of the new owner of the contract
	/// @dev Set _newOwner to address(0) to renounce any ownership.
	/// @param _newOwner The address of the new owner of the contract
	function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from '../interfaces/IDiamondCut.sol';
import {IDiamondLoupe} from '../interfaces/IDiamondLoupe.sol';
import {IERC165} from '../interfaces/IERC165.sol';
import {IERC173} from '../interfaces/IERC173.sol';
import {LibMeta} from './LibMeta.sol';

library LibDiamond {
	bytes32 constant DIAMOND_STORAGE_POSITION =
		keccak256('diamond.standard.diamond.storage');

	struct FacetAddressAndPosition {
		address facetAddress;
		uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
	}

	struct FacetFunctionSelectors {
		bytes4[] functionSelectors;
		uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
	}

	struct DiamondStorage {
		// maps function selector to the facet address and
		// the position of the selector in the facetFunctionSelectors.selectors array
		mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
		// maps facet addresses to function selectors
		mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
		// facet addresses
		address[] facetAddresses;
		// Used to query if a contract implements an interface.
		// Used to implement ERC-165.
		mapping(bytes4 => bool) supportedInterfaces;
		// owner of the contract
		address contractOwner;
	}

	function diamondStorage()
		internal
		pure
		returns (DiamondStorage storage ds)
	{
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	function setContractOwner(address _newOwner) internal {
		DiamondStorage storage ds = diamondStorage();
		address previousOwner = ds.contractOwner;
		ds.contractOwner = _newOwner;
		emit OwnershipTransferred(previousOwner, _newOwner);
	}

	function contractOwner() internal view returns (address contractOwner_) {
		contractOwner_ = diamondStorage().contractOwner;
	}

	function enforceIsContractOwner() internal view {
		require(
			LibMeta.msgSender() == diamondStorage().contractOwner,
			'LibDiamond: Must be contract owner'
		);
	}

	event DiamondCut(
		IDiamondCut.FacetCut[] _diamondCut,
		address _init,
		bytes _calldata
	);

	function addDiamondFunctions(
		address _diamondCutFacet,
		address _diamondLoupeFacet,
		address _ownershipFacet
	) internal {
		IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
		bytes4[] memory functionSelectors = new bytes4[](1);
		functionSelectors[0] = IDiamondCut.diamondCut.selector;
		cut[0] = IDiamondCut.FacetCut({
			facetAddress: _diamondCutFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: functionSelectors
		});
		functionSelectors = new bytes4[](5);
		functionSelectors[0] = IDiamondLoupe.facets.selector;
		functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
		functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
		functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
		functionSelectors[4] = IERC165.supportsInterface.selector;
		cut[1] = IDiamondCut.FacetCut({
			facetAddress: _diamondLoupeFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: functionSelectors
		});
		functionSelectors = new bytes4[](2);
		functionSelectors[0] = IERC173.transferOwnership.selector;
		functionSelectors[1] = IERC173.owner.selector;
		cut[2] = IDiamondCut.FacetCut({
			facetAddress: _ownershipFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: functionSelectors
		});
		diamondCut(cut, address(0), '');
	}

	// Internal function version of diamondCut
	function diamondCut(
		IDiamondCut.FacetCut[] memory _diamondCut,
		address _init,
		bytes memory _calldata
	) internal {
		for (
			uint256 facetIndex;
			facetIndex < _diamondCut.length;
			facetIndex++
		) {
			IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
			if (action == IDiamondCut.FacetCutAction.Add) {
				addFunctions(
					_diamondCut[facetIndex].facetAddress,
					_diamondCut[facetIndex].functionSelectors
				);
			} else if (action == IDiamondCut.FacetCutAction.Replace) {
				replaceFunctions(
					_diamondCut[facetIndex].facetAddress,
					_diamondCut[facetIndex].functionSelectors
				);
			} else if (action == IDiamondCut.FacetCutAction.Remove) {
				removeFunctions(
					_diamondCut[facetIndex].facetAddress,
					_diamondCut[facetIndex].functionSelectors
				);
			} else {
				revert('LibDiamondCut: Incorrect FacetCutAction');
			}
		}
		emit DiamondCut(_diamondCut, _init, _calldata);
		initializeDiamondCut(_init, _calldata);
	}

	function addFunctions(
		address _facetAddress,
		bytes4[] memory _functionSelectors
	) internal {
		require(
			_functionSelectors.length > 0,
			'LibDiamondCut: No selectors in facet to cut'
		);
		DiamondStorage storage ds = diamondStorage();
		// uint16 selectorCount = uint16(diamondStorage().selectors.length);
		require(
			_facetAddress != address(0),
			"LibDiamondCut: Add facet can't be address(0)"
		);
		uint16 selectorPosition = uint16(
			ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
		);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			enforceHasContractCode(
				_facetAddress,
				'LibDiamondCut: New facet has no code'
			);
			ds
				.facetFunctionSelectors[_facetAddress]
				.facetAddressPosition = uint16(ds.facetAddresses.length);
			ds.facetAddresses.push(_facetAddress);
		}
		for (
			uint256 selectorIndex;
			selectorIndex < _functionSelectors.length;
			selectorIndex++
		) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds
				.selectorToFacetAndPosition[selector]
				.facetAddress;
			require(
				oldFacetAddress == address(0),
				"LibDiamondCut: Can't add function that already exists"
			);
			ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
				selector
			);
			ds
				.selectorToFacetAndPosition[selector]
				.facetAddress = _facetAddress;
			ds
				.selectorToFacetAndPosition[selector]
				.functionSelectorPosition = selectorPosition;
			selectorPosition++;
		}
	}

	function replaceFunctions(
		address _facetAddress,
		bytes4[] memory _functionSelectors
	) internal {
		require(
			_functionSelectors.length > 0,
			'LibDiamondCut: No selectors in facet to cut'
		);
		DiamondStorage storage ds = diamondStorage();
		require(
			_facetAddress != address(0),
			"LibDiamondCut: Add facet can't be address(0)"
		);
		uint16 selectorPosition = uint16(
			ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
		);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			enforceHasContractCode(
				_facetAddress,
				'LibDiamondCut: New facet has no code'
			);
			ds
				.facetFunctionSelectors[_facetAddress]
				.facetAddressPosition = uint16(ds.facetAddresses.length);
			ds.facetAddresses.push(_facetAddress);
		}
		for (
			uint256 selectorIndex;
			selectorIndex < _functionSelectors.length;
			selectorIndex++
		) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds
				.selectorToFacetAndPosition[selector]
				.facetAddress;
			require(
				oldFacetAddress != _facetAddress,
				"LibDiamondCut: Can't replace function with same function"
			);
			if (oldFacetAddress != address(0)) {
				removeFunction(oldFacetAddress, selector);
			}
			// add function
			ds
				.selectorToFacetAndPosition[selector]
				.functionSelectorPosition = selectorPosition;
			ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
				selector
			);
			ds
				.selectorToFacetAndPosition[selector]
				.facetAddress = _facetAddress;
			selectorPosition++;
		}
	}

	function removeFunctions(
		address _facetAddress,
		bytes4[] memory _functionSelectors
	) internal {
		require(
			_functionSelectors.length > 0,
			'LibDiamondCut: No selectors in facet to cut'
		);
		DiamondStorage storage ds = diamondStorage();
		// if function does not exist then do nothing and return
		require(
			_facetAddress == address(0),
			'LibDiamondCut: Remove facet address must be address(0)'
		);
		for (
			uint256 selectorIndex;
			selectorIndex < _functionSelectors.length;
			selectorIndex++
		) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds
				.selectorToFacetAndPosition[selector]
				.facetAddress;
			removeFunction(oldFacetAddress, selector);
		}
	}

	function removeFunction(address _facetAddress, bytes4 _selector) internal {
		DiamondStorage storage ds = diamondStorage();
		require(
			_facetAddress != address(0),
			"LibDiamondCut: Can't remove function that doesn't exist"
		);
		// an immutable function is a function defined directly in a diamond
		require(
			_facetAddress != address(this),
			"LibDiamondCut: Can't remove immutable function"
		);
		// replace selector with last selector, then delete last selector
		uint256 selectorPosition = ds
			.selectorToFacetAndPosition[_selector]
			.functionSelectorPosition;
		uint256 lastSelectorPosition = ds
			.facetFunctionSelectors[_facetAddress]
			.functionSelectors
			.length - 1;
		// if not the same then replace _selector with lastSelector
		if (selectorPosition != lastSelectorPosition) {
			bytes4 lastSelector = ds
				.facetFunctionSelectors[_facetAddress]
				.functionSelectors[lastSelectorPosition];
			ds.facetFunctionSelectors[_facetAddress].functionSelectors[
					selectorPosition
				] = lastSelector;
			ds
				.selectorToFacetAndPosition[lastSelector]
				.functionSelectorPosition = uint16(selectorPosition);
		}
		// delete the last selector
		ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
		delete ds.selectorToFacetAndPosition[_selector];

		// if no more selectors for facet address then delete the facet address
		if (lastSelectorPosition == 0) {
			// replace facet address with last facet address and delete last facet address
			uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
			uint256 facetAddressPosition = ds
				.facetFunctionSelectors[_facetAddress]
				.facetAddressPosition;
			if (facetAddressPosition != lastFacetAddressPosition) {
				address lastFacetAddress = ds.facetAddresses[
					lastFacetAddressPosition
				];
				ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
				ds
					.facetFunctionSelectors[lastFacetAddress]
					.facetAddressPosition = uint16(facetAddressPosition);
			}
			ds.facetAddresses.pop();
			delete ds
				.facetFunctionSelectors[_facetAddress]
				.facetAddressPosition;
		}
	}

	function initializeDiamondCut(address _init, bytes memory _calldata)
		internal
	{
		if (_init == address(0)) {
			require(
				_calldata.length == 0,
				'LibDiamondCut: _init is address(0) but_calldata is not empty'
			);
		} else {
			require(
				_calldata.length > 0,
				'LibDiamondCut: _calldata is empty but _init is not address(0)'
			);
			if (_init != address(this)) {
				enforceHasContractCode(
					_init,
					'LibDiamondCut: _init address has no code'
				);
			}
			(bool success, bytes memory error) = _init.delegatecall(_calldata);
			if (success == false) {
				if (error.length > 0) {
					// bubble up the error
					revert(string(error));
				} else {
					revert('LibDiamondCut: _init function reverted');
				}
			}
		}
	}

	function enforceHasContractCode(
		address _contract,
		string memory _errorMessage
	) internal view {
		uint256 contractSize;
		assembly {
			contractSize := extcodesize(_contract)
		}
		require(contractSize != 0, _errorMessage);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Chain {
	Ethereum,
	Polygon,
	Cardano
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
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	uint256 totalCopies;
	address totalCopiesLockedBy;
}

struct Meem {
	address owner;
	Chain chain;
	address parent;
	uint256 parentTokenId;
	MeemProperties properties;
	MeemProperties childProperties;
	uint256 totalSupply;
}

// mapping(uint256 => Chain) chain;
// mapping(uint256 => address) parent;
// mapping(uint256 => uint256) parentTokenId;
// mapping(uint256 => MeemProperties) properties;
// mapping(uint256 => MeemProperties) childProperties;

interface MeemStandard {
	function mint(
		address to,
		string memory mTokenURI,
		Chain chain,
		address parent,
		uint256 parentTokenId,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external;

	// function mintChild(
	// 	address to,
	// 	string memory mTokenURI,
	// 	Chain chain,
	// 	uint256 parentTokenId,
	// 	MeemProperties memory properties,
	// 	MeemProperties memory childProperties
	// ) external;

	// Get children meems
	function childrenOf(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function numChildrenOf(uint256 tokenId) external view returns (uint256);

	function setTotalCopies(uint256 tokenId, uint256 newTotalCopies) external;

	function lockTotalCopies(uint256 tokenId) external;

	// function addPermission(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	PermissionType permissionType,
	// 	MeemPermission memory permission
	// ) external;

	// function removePermissionAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	PermissionType permissionType,
	// 	uint256 idx
	// ) external;

	// function updatePermissionAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	PermissionType permissionType,
	// 	uint256 idx,
	// 	MeemPermission memory permission
	// ) external;

	// function addSplit(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	Split memory split
	// ) external;

	// function removeSplitAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	uint256 idx
	// ) external;

	// function updateSplitAt(
	// 	uint256 tokenId,
	// 	PropertyType propertyType,
	// 	uint256 idx,
	// 	Split memory split
	// ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
	enum FacetCutAction {
		Add,
		Replace,
		Remove
	}

	struct FacetCut {
		address facetAddress;
		FacetCutAction action;
		bytes4[] functionSelectors;
	}

	/// @notice Add/replace/remove any number of functions and optionally execute
	///         a function with delegatecall
	/// @param _diamondCut Contains the facet addresses and function selectors
	/// @param _init The address of the contract or facet to execute _calldata
	/// @param _calldata A function call, including function selector and arguments
	///                  _calldata is executed with delegatecall on _init
	function diamondCut(
		FacetCut[] calldata _diamondCut,
		address _init,
		bytes calldata _calldata
	) external;

	event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
	/// These functions are expected to be called frequently
	/// by tools.

	struct Facet {
		address facetAddress;
		bytes4[] functionSelectors;
	}

	/// @notice Gets all facet addresses and their four byte function selectors.
	/// @return facets_ Facet
	function facets() external view returns (Facet[] memory facets_);

	/// @notice Gets all the function selectors supported by a specific facet.
	/// @param _facet The facet address.
	/// @return facetFunctionSelectors_
	function facetFunctionSelectors(address _facet)
		external
		view
		returns (bytes4[] memory facetFunctionSelectors_);

	/// @notice Get all the facet addresses used by a diamond.
	/// @return facetAddresses_
	function facetAddresses()
		external
		view
		returns (address[] memory facetAddresses_);

	/// @notice Gets the facet that supports the given selector.
	/// @dev If facet is not found return address(0).
	/// @param _functionSelector The function selector.
	/// @return facetAddress_ The facet address.
	function facetAddress(bytes4 _functionSelector)
		external
		view
		returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import './MeemStandard.sol';

library MeemPropsLibrary {
	function properties(MeemProperties storage self)
		public
		pure
		returns (MeemProperties memory)
	{
		return self;
	}

	function addPermission(
		MeemProperties storage self,
		PermissionType permissionType,
		MeemPermission memory permission
	) public {
		MeemPermission[] storage perms = getPermissions(self, permissionType);

		perms.push(permission);
	}

	function updatePermissionAt(
		MeemProperties storage self,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) public {
		permissionNotLocked(self, permissionType);

		MeemPermission[] storage perms = getPermissions(self, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		perms[idx] = permission;
	}

	function removePermissionAt(
		MeemProperties storage self,
		PermissionType permissionType,
		uint256 idx
	) public {
		permissionNotLocked(self, permissionType);

		MeemPermission[] storage perms = getPermissions(self, permissionType);
		require(
			perms[idx].lockedBy == address(0),
			'Permission is locked at that index'
		);

		if (idx >= perms.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < perms.length - 1; i++) {
			perms[i] = perms[i + 1];
		}

		delete perms[perms.length - 1];
	}

	function addSplit(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount,
		Split memory split
	) public {
		require(self.splitsLockedBy == address(0), 'Splits are locked');
		self.splits.push(split);
		validateSplits(self, tokenOwner, nonOwnerSplitAllocationAmount);
	}

	function removeSplitAt(MeemProperties storage self, uint256 idx) public {
		require(self.splitsLockedBy == address(0), 'Splits are locked');
		require(
			self.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		if (idx >= self.splits.length) {
			revert('Index out of range');
		}

		for (uint256 i = idx; i < self.splits.length - 1; i++) {
			self.splits[i] = self.splits[i + 1];
		}

		delete self.splits[self.splits.length - 1];
	}

	function updateSplitAt(
		MeemProperties storage self,
		address tokenOwner,
		uint256 idx,
		uint256 nonOwnerSplitAllocationAmount,
		Split memory split
	) public {
		require(self.splitsLockedBy == address(0), 'Splits are locked');
		require(
			self.splits[idx].lockedBy == address(0),
			'Split at index is locked'
		);

		self.splits[idx] = split;
		validateSplits(self, tokenOwner, nonOwnerSplitAllocationAmount);
	}

	function validateSplits(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) public view {
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

		require(
			totalAmount <= 10000,
			'Total basis points amount must be less than 10000 (100%)'
		);

		require(
			totalAmountOfNonOwner >= nonOwnerSplitAllocationAmount,
			'Split allocation for non-owner is too low'
		);
	}

	function getPermissions(
		MeemProperties storage self,
		PermissionType permissionType
	) public view returns (MeemPermission[] storage) {
		if (permissionType == PermissionType.Copy) {
			require(
				self.copyPermissionsLockedBy == address(0),
				'Copy permissions are locked'
			);
			return self.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			require(
				self.remixPermissionsLockedBy == address(0),
				'Remix permissions are locked'
			);
			return self.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			require(
				self.readPermissionsLockedBy == address(0),
				'Read permissions are locked'
			);
			return self.readPermissions;
		}

		revert('Invalid permission type');
	}

	function permissionNotLocked(
		MeemProperties storage self,
		PermissionType permissionType
	) public view {
		if (permissionType == PermissionType.Copy) {
			require(
				self.copyPermissionsLockedBy == address(0),
				'Copy permissions are locked'
			);
		} else if (permissionType == PermissionType.Remix) {
			require(
				self.remixPermissionsLockedBy == address(0),
				'Remix permissions are locked'
			);
		} else if (permissionType == PermissionType.Read) {
			require(
				self.readPermissionsLockedBy == address(0),
				'Read permissions are locked'
			);
		}
	}

	function setProperties(
		MeemProperties storage self,
		MeemProperties memory mProperties
	) public {
		for (uint256 i = 0; i < mProperties.copyPermissions.length; i++) {
			self.copyPermissions.push(mProperties.copyPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.remixPermissions.length; i++) {
			self.remixPermissions.push(mProperties.remixPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.readPermissions.length; i++) {
			self.readPermissions.push(mProperties.readPermissions[i]);
		}

		for (uint256 i = 0; i < mProperties.splits.length; i++) {
			self.splits.push(mProperties.splits[i]);
		}

		self.totalCopies = mProperties.totalCopies;
		self.totalCopiesLockedBy = mProperties.totalCopiesLockedBy;
		self.copyPermissionsLockedBy = mProperties.copyPermissionsLockedBy;
		self.remixPermissionsLockedBy = mProperties.remixPermissionsLockedBy;
		self.readPermissionsLockedBy = mProperties.readPermissionsLockedBy;
		self.splitsLockedBy = mProperties.splitsLockedBy;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
		delete array[array.length - 1];
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ContextMixin {
	function msgSender() internal view returns (address payable sender) {
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender = payable(msg.sender);
		}
		return sender;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {EIP712Base} from './EIP712Base.sol';

contract NativeMetaTransaction is EIP712Base {
	using SafeMath for uint256;
	bytes32 private constant META_TRANSACTION_TYPEHASH =
		keccak256(
			bytes(
				'MetaTransaction(uint256 nonce,address from,bytes functionSignature)'
			)
		);
	event MetaTransactionExecuted(
		address userAddress,
		address payable relayerAddress,
		bytes functionSignature
	);
	mapping(address => uint256) nonces;

	/*
	 * Meta transaction structure.
	 * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
	 * He should call the desired function directly in that case.
	 */
	struct MetaTransaction {
		uint256 nonce;
		address from;
		bytes functionSignature;
	}

	function executeMetaTransaction(
		address userAddress,
		bytes memory functionSignature,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) public payable returns (bytes memory) {
		MetaTransaction memory metaTx = MetaTransaction({
			nonce: nonces[userAddress],
			from: userAddress,
			functionSignature: functionSignature
		});

		require(
			verify(userAddress, metaTx, sigR, sigS, sigV),
			'Signer and signature do not match'
		);

		// increase nonce for user (to avoid re-use)
		nonces[userAddress] = nonces[userAddress].add(1);

		emit MetaTransactionExecuted(
			userAddress,
			payable(msg.sender),
			functionSignature
		);

		// Append userAddress and relayer address at the end to extract it from calling context
		(bool success, bytes memory returnData) = address(this).call(
			abi.encodePacked(functionSignature, userAddress)
		);
		require(success, 'Function call not successful');

		return returnData;
	}

	function hashMetaTransaction(MetaTransaction memory metaTx)
		internal
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encode(
					META_TRANSACTION_TYPEHASH,
					metaTx.nonce,
					metaTx.from,
					keccak256(metaTx.functionSignature)
				)
			);
	}

	function getNonce(address user) public view returns (uint256 nonce) {
		nonce = nonces[user];
	}

	function verify(
		address signer,
		MetaTransaction memory metaTx,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) internal view returns (bool) {
		require(signer != address(0), 'NativeMetaTransaction: INVALID_SIGNER');
		return
			signer ==
			ecrecover(
				toTypedMessageHash(hashMetaTransaction(metaTx)),
				sigV,
				sigR,
				sigS
			);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

pragma solidity ^0.8.4;

import {Initializable} from './Initializable.sol';

contract EIP712Base is Initializable {
	struct EIP712Domain {
		string name;
		string version;
		address verifyingContract;
		bytes32 salt;
	}

	string public constant ERC712_VERSION = '1';

	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
		keccak256(
			bytes(
				'EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)'
			)
		);
	bytes32 internal domainSeperator;

	// supposed to be called once while initializing.
	// one of the contracts that inherits this contract follows proxy pattern
	// so it is not possible to do this in a constructor
	function _initializeEIP712(string memory name) internal initializer {
		_setDomainSeperator(name);
	}

	function _setDomainSeperator(string memory name) internal {
		domainSeperator = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(ERC712_VERSION)),
				address(this),
				bytes32(getChainId())
			)
		);
	}

	function getDomainSeperator() public view returns (bytes32) {
		return domainSeperator;
	}

	function getChainId() public view returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}

	/**
	 * Accept message hash and returns hash message in EIP712 compatible form
	 * So that it can be used to recover signer from signature signed using EIP712 formatted data
	 * https://eips.ethereum.org/EIPS/eip-712
	 * "\\x19" makes the encoding deterministic
	 * "\\x01" is the version byte to make it compatible to EIP-191
	 */
	function toTypedMessageHash(bytes32 messageHash)
		internal
		view
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked('\x19\x01', getDomainSeperator(), messageHash)
			);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Initializable {
	bool inited = false;

	modifier initializer() {
		require(!inited, 'already inited');
		_;
		inited = true;
	}
}