// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./IHonestFarmerClubV2.sol";
import "./IMigrationTractor.sol";
import "./IRegistryFarmer.sol";
import "./IRevealFarmer.sol";

import "./LibraryFarmer.sol";

enum RevealType {
	PreMigration,
	PostMigration
}

contract RevealFarmer is IRevealFarmer, VRFConsumerBase, Ownable {
	IRegistryFarmer public registryFarmer;

	event Reveal(uint256 indexed tokenId, uint256 indexed internalTokenId);

	uint256 public MAX_FARMER_SUPPLY;
	uint256 public PRE_MIGRATION_TOKEN_COUNT;

	// Chainlink VRF
	bytes32 internal keyHash;
	uint256 internal fee;

	// Metadata assignment
	uint256[] public unassignedInternalTokenIds;
	mapping(uint256 => uint256) public internalTokenIdByTokenId;

	// Reveal
	mapping(RevealType => uint256) public vrfRequestIdByRevealType;
	mapping(RevealType => uint256) public randomnessByRevealType;
	mapping(RevealType => uint256) public highestRevealedTokenIdByRevealType;

	constructor(
		IRegistryFarmer _registryFarmer,
		address _vrfCoordinator,
		address _link,
		bytes32 _keyHash,
		uint256 _fee
	) VRFConsumerBase(_vrfCoordinator, _link) {
		registryFarmer = _registryFarmer;

		// Fetch onchain constants
		IHonestFarmerClubV2 honestFarmerClubV2 = IHonestFarmerClubV2(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV2
			)
		);
		MAX_FARMER_SUPPLY = honestFarmerClubV2.MAX_FARMER_SUPPLY();

		IMigrationTractor migrationTractor = IMigrationTractor(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.MigrationTractor
			)
		);
		PRE_MIGRATION_TOKEN_COUNT = migrationTractor.PRE_MIGRATION_TOKEN_COUNT();

		// VRF
		keyHash = _keyHash;
		fee = _fee;
	}

	modifier hasSetRandomness(RevealType revealType) {
		require(randomnessByRevealType[revealType] > 0, "Randomness not set");
		_;
	}

	modifier hasUnrevealedFarmers(RevealType revealType) {
		require(
			getNumberOfUnrevealedFarmers(revealType) > 0,
			"No farmers to reveal"
		);
		_;
	}

	modifier isUnrevealedFarmer(uint256 tokenId) {
		require(!isRevealed(tokenId), "Farmer already revealed");
		_;
	}

	// Reveal
	function _revealFarmer(
		uint256 tokenId,
		uint256 randomness,
		uint256 indexShift
	) private isUnrevealedFarmer(tokenId) {
		uint256 _numberOfUnassignedInternalTokenIds = numberOfUnassignedInternalTokenIds();

		uint256 randomIndex = randomness % _numberOfUnassignedInternalTokenIds; // 0 .. _numberOfUnassignedInternalTokenIds - 1
		uint256 shiftedRandomIndex = randomIndex + indexShift;
		uint256 cleanedRandomIndex = shiftedRandomIndex >
			_numberOfUnassignedInternalTokenIds
			? shiftedRandomIndex % _numberOfUnassignedInternalTokenIds
			: shiftedRandomIndex;

		_assignInternalTokenId(tokenId, cleanedRandomIndex);
	}

	function _revealFarmers(RevealType revealType, uint256 limit)
		private
		hasSetRandomness(revealType)
		hasUnrevealedFarmers(revealType)
	{
		uint256 highestRevealedTokenId = getHighestRevealedTokenId(revealType);
		(
			uint256 numberOfFarmersToBeRevealed,
			bool hasUnrevealedFarmersLeft
		) = getNumberOfFarmersToBeRevealed(revealType, limit);

		for (uint256 i = 0; i < numberOfFarmersToBeRevealed; i++) {
			uint256 tokenId = highestRevealedTokenId + i + 1;
			_revealFarmer(tokenId, randomnessByRevealType[revealType], i);
		}

		// Increase reveal counter
		highestRevealedTokenIdByRevealType[revealType] =
			highestRevealedTokenId +
			numberOfFarmersToBeRevealed;

		// Reset randomness for next reveal, unless there are still unrevealed, already minted farmers left after this batch
		if (
			!hasUnrevealedFarmersLeft && revealType == RevealType.PostMigration
		) {
			randomnessByRevealType[RevealType.PostMigration] = 0;
		}
	}

	function revealOGFarmers(uint256 limit) public onlyOwner {
		_revealFarmers(RevealType.PreMigration, limit);
	}

	function revealFarmers(uint256 limit) public onlyOwner {
		_revealFarmers(RevealType.PostMigration, limit);
	}

	function emergencyRevealFarmers(
		RevealType revealType,
		uint256[] memory internalTokenIds
	) public onlyOwner {
		uint256 highestRevealedTokenId = getHighestRevealedTokenId(revealType);

		for (uint256 i = 0; i < internalTokenIds.length; i++) {
			uint256 tokenId = highestRevealedTokenId + i + 1;
			uint256 internalTokenId = internalTokenIds[i];

			// Find index of internal id in unassigned list
			uint256 index = _findIndexOfUnassignedInternalTokenId(
				internalTokenId
			);
			_assignInternalTokenId(tokenId, index);
		}

		// Increase reveal counter
		highestRevealedTokenIdByRevealType[revealType] =
			highestRevealedTokenId +
			internalTokenIds.length;
	}

	// VRF
	function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
		require(
			LINK.balanceOf(address(this)) >= fee,
			"Not enough LINK tokens for VRF call"
		);
		return requestRandomness(keyHash, fee);
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness)
		internal
		override
	{
		bool hasSetPreMigrationRandomness = randomnessByRevealType[
			RevealType.PreMigration
		] > 0;

		randomnessByRevealType[
			hasSetPreMigrationRandomness
				? RevealType.PostMigration
				: RevealType.PreMigration
		] = randomness;
	}

	// Utilities
	function isOGFarmer(uint256 tokenId) public view returns (bool) {
		return tokenId <= PRE_MIGRATION_TOKEN_COUNT;
	}

	function isRevealed(uint256 tokenId) public view returns (bool) {
		uint256 highestRevealedTokenId = getHighestRevealedTokenId(
			isOGFarmer(tokenId)
				? RevealType.PreMigration
				: RevealType.PostMigration
		);
		return tokenId <= highestRevealedTokenId;
	}

	function isRevealedBatch(uint256[] memory tokenIds)
		public
		view
		returns (bool[] memory)
	{
		bool[] memory revealeadFarmers = new bool[](tokenIds.length);

		for (uint256 i = 0; i < tokenIds.length; i++) {
			revealeadFarmers[i] = isRevealed(tokenIds[i]);
		}

		return revealeadFarmers;
	}

	function getHighestRevealedTokenId(RevealType revealType)
		public
		view
		returns (uint256)
	{
		uint256 highestRevealedTokenId = highestRevealedTokenIdByRevealType[
			revealType
		];

		if (revealType == RevealType.PostMigration) {
			return
				highestRevealedTokenId == 0
					? PRE_MIGRATION_TOKEN_COUNT
					: highestRevealedTokenId;
		}

		return highestRevealedTokenId;
	}

	function getInternalTokenId(uint256 tokenId)
		public
		view
		returns (uint256 internalTokenId)
	{
		return internalTokenIdByTokenId[tokenId];
	}

	function numberOfUnassignedInternalTokenIds()
		public
		view
		returns (uint256)
	{
		return unassignedInternalTokenIds.length;
	}

	function getCurrentHighestTokenId(RevealType revealType)
		public
		view
		returns (uint256)
	{
		return
			revealType == RevealType.PreMigration
				? PRE_MIGRATION_TOKEN_COUNT
				: PRE_MIGRATION_TOKEN_COUNT +
					_numberOfPostMigrationFarmersMinted();
	}

	function getNumberOfUnrevealedFarmers(RevealType revealType)
		public
		view
		returns (uint256)
	{
		uint256 highestRevealedTokenId = getHighestRevealedTokenId(revealType);
		uint256 currentHighestTokenId = getCurrentHighestTokenId(revealType);

		if (revealType == RevealType.PostMigration) {
			return currentHighestTokenId - highestRevealedTokenId;
		}

		return currentHighestTokenId - highestRevealedTokenId;
	}

	function getNumberOfFarmersToBeRevealed(
		RevealType revealType,
		uint256 limit
	)
		public
		view
		returns (
			uint256 numberOfFarmersToBeRevealed,
			bool hasUnrevealedFarmersLeft
		)
	{
		uint256 _numberOfUnrevealedFarmers = getNumberOfUnrevealedFarmers(
			revealType
		);

		if (_numberOfUnrevealedFarmers < limit) {
			return (_numberOfUnrevealedFarmers, false);
		}
		if (_numberOfUnrevealedFarmers == limit) {
			return (limit, false);
		}

		return (limit, true);
	}

	function _assignInternalTokenId(
		uint256 tokenId,
		uint256 indexOfUnassignedInternalTokenId
	) private {
		require(
			indexOfUnassignedInternalTokenId <
				unassignedInternalTokenIds.length,
			"Index out of bounds"
		);
		uint256 internalTokenId = unassignedInternalTokenIds[
			indexOfUnassignedInternalTokenId
		];
		internalTokenIdByTokenId[tokenId] = internalTokenId;

		// Replace with last array element
		unassignedInternalTokenIds[
			indexOfUnassignedInternalTokenId
		] = unassignedInternalTokenIds[
			numberOfUnassignedInternalTokenIds() - 1
		];

		// Pop last element
		unassignedInternalTokenIds.pop();

		emit Reveal(tokenId, internalTokenId);
	}

	function _findIndexOfUnassignedInternalTokenId(uint256 internalTokenId)
		private
		view
		returns (uint256)
	{
		for (
			uint256 index = 0;
			index < numberOfUnassignedInternalTokenIds();
			index++
		) {
			if (unassignedInternalTokenIds[index] == internalTokenId) {
				return index;
			}
		}

		revert("Internal id not found in unassigned list");
	}

	function _tokenCount() private view returns (uint256 tokenCount) {
		IHonestFarmerClubV2 honestFarmerClubV2 = IHonestFarmerClubV2(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV2
			)
		);
		return honestFarmerClubV2.tokenCount();
	}

	function _numberOfPostMigrationFarmersMinted()
		private
		view
		returns (uint256 tokenCount)
	{
		IHonestFarmerClubV2 honestFarmerClubV2 = IHonestFarmerClubV2(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.HonestFarmerClubV2
			)
		);
		return honestFarmerClubV2.numberOfPostMigrationFarmersMinted();
	}

	function emergencySetRandomness(RevealType revealtype, uint256 randomness)
		public
		onlyOwner
	{
		randomnessByRevealType[revealtype] = randomness;
	}

	function fillUnassignedInternalIds(uint256 ceil) public onlyOwner {
		require(
			numberOfUnassignedInternalTokenIds() < MAX_FARMER_SUPPLY,
			"Already filled all unassigned internal ids"
		);

		uint256 prevNumberOfUnassignedInternalTokenIds = numberOfUnassignedInternalTokenIds();
		uint256 floor = prevNumberOfUnassignedInternalTokenIds + 1;

		// Setup unrevealed ids
		for (uint256 i = floor; i <= ceil; i++) {
			unassignedInternalTokenIds.push(i);
		}
	}

	function setKeyhash(bytes32 _keyHash) public onlyOwner {
		keyHash = _keyHash;
	}

	function setFee(uint256 _fee) public onlyOwner {
		fee = _fee;
	}
}