// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./IEnergyFarmer.sol";
import "./IMetaFarmer.sol";
import "./IOnchainArtworkFarmer.sol";
import "./IRegistryFarmer.sol";
import "./IRevealFarmer.sol";

import "./LibraryFarmer.sol";

contract MetaFarmer is IMetaFarmer, Ownable {
	using LibraryFarmer for LibraryFarmer.Passion;
	using LibraryFarmer for LibraryFarmer.Skill;
	using LibraryFarmer for LibraryFarmer.VisualTraitType;
	using LibraryFarmer for LibraryFarmer.FarmerContract;
	using LibraryFarmer for LibraryFarmer.FarmerMetadata;
	using Counters for Counters.Counter;
	using Strings for uint8;
	using Strings for uint256;

	IRegistryFarmer public registryFarmer;

	// Metadata
	string[3] public passions = [
		"Harvesting", // 0
		"Fishing", // 1
		"Planting" // 2
	];
	string[6] public skills = [
		"Degen", // 0
		"Honesty", // 1
		"Fitness", // 2
		"Strategy", // 3
		"Patience", // 4
		"Agility" // 5
	];
	string[8] public visualTraitTypes = [
		"Background", // 0
		"Skin", // 1
		"Clothing", // 2
		"Mouth", // 3
		"Nose", // 4
		"Head", // 5
		"Eyes", // 6
		"Ears" // 7
	];
	mapping(uint256 => uint256) public passionIdByInternalTokenId;
	mapping(uint256 => bool) public isSpecialByInternalTokenId;
	mapping(uint256 => string) public specialNameByInternalTokenId;

	mapping(LibraryFarmer.VisualTraitType => mapping(uint256 => string))
		public visualTraitsByTraitIdByTraitType;
	mapping(LibraryFarmer.VisualTraitType => mapping(uint256 => uint256))
		public visualTraitValueIdByInternalTokenIdByTraitType;

	// Artwork
	mapping(uint256 => string) public ipfsHashByInternalTokenId;
	string public unrevealedIpfsHash;
	bool public isOnChainArtworkReady;

	constructor(
		IRegistryFarmer _registryFarmer,
		string memory _unrevealedIpfsHash
	) {
		registryFarmer = _registryFarmer;
		unrevealedIpfsHash = _unrevealedIpfsHash;
	}

	// Passion
	function getPassionTraitMetadata(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		uint256 passionId = passionIdByInternalTokenId[internalTokenId];

		return
			string(
				abi.encodePacked(
					'{"trait_type":"Passion",',
					'"value":"',
					isRevealed ? passions[passionId] : "Howdy",
					'"}'
				)
			);
	}

	// Skills
	function getSkillTraitMetadata(
		LibraryFarmer.Skill skillId,
		uint256 internalTokenId
	) public view returns (string memory) {
		string memory skillName = skills[uint256(skillId)];

		IEnergyFarmer energyFarmer = IEnergyFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.EnergyFarmer)
		);
		uint8 level = energyFarmer.getSkillLevel(skillId, internalTokenId);
		uint8 MAX_SKILL_LEVEL = energyFarmer.MAX_SKILL_LEVEL();

		return
			string(
				abi.encodePacked(
					'{"trait_type":"',
					skillName,
					'","value":',
					level.toString(),
					',"max_value":',
					MAX_SKILL_LEVEL.toString(),
					"}"
				)
			);
	}

	function compileSkillTraits(uint256 internalTokenId)
		public
		view
		returns (string memory)
	{
		string memory skillTraits = string(
			abi.encodePacked(
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Degen,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Honesty,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Fitness,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Strategy,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Patience,
					internalTokenId
				),
				",",
				getSkillTraitMetadata(
					LibraryFarmer.Skill.Agility,
					internalTokenId
				)
			)
		);
		return skillTraits;
	}

	// Visuals
	function getVisualTraitMetadata(
		LibraryFarmer.VisualTraitType traitTypeId,
		uint256 internalTokenId,
		bool isRevealed
	) public view returns (string memory) {
		string memory traitType = visualTraitTypes[uint256(traitTypeId)];

		uint256 traitValueId = visualTraitValueIdByInternalTokenIdByTraitType[
			traitTypeId
		][internalTokenId];
		string memory traitValue = isRevealed
			? visualTraitsByTraitIdByTraitType[traitTypeId][traitValueId]
			: "Howdy";

		return
			string(
				abi.encodePacked(
					'{"trait_type":"',
					traitType,
					'","value":"',
					traitValue,
					'"}'
				)
			);
	}

	function compileVisualTraits(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		string memory visualTraits = string(
			abi.encodePacked(
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Background,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Skin,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Clothing,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Mouth,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Nose,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Head,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Eyes,
					internalTokenId,
					isRevealed
				),
				",",
				getVisualTraitMetadata(
					LibraryFarmer.VisualTraitType.Ears,
					internalTokenId,
					isRevealed
				)
			)
		);

		return visualTraits;
	}

	function compileAttributes(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		string memory passionTrait = getPassionTraitMetadata(
			internalTokenId,
			isRevealed
		);
		string memory skillTraits = compileSkillTraits(internalTokenId);

		bool isSpecial = isSpecialByInternalTokenId[internalTokenId];
		if (isSpecial) {
			string memory specialName = specialNameByInternalTokenId[
				internalTokenId
			];
			string memory visualTrait = string(
				abi.encodePacked(
					'{"trait_type":"Specials","value":"',
					specialName,
					'"}'
				)
			);

			return _getPackedAttributes(passionTrait, skillTraits, visualTrait);
		}

		string memory visualTraits = compileVisualTraits(
			internalTokenId,
			isRevealed
		);

		return _getPackedAttributes(passionTrait, skillTraits, visualTraits);
	}

	// Artwork
	function getIPFSImageUrl(uint256 internalTokenId, bool isRevealed)
		public
		view
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(
					"https://ipfs.io/ipfs/",
					isRevealed
						? ipfsHashByInternalTokenId[internalTokenId]
						: unrevealedIpfsHash
				)
			);
	}

	function getOnChainSVGBase64ImageUrl(
		uint256 internalTokenId,
		bool isRevealed
	) public view returns (string memory) {
		IOnchainArtworkFarmer onchainArtworkFarmer = IOnchainArtworkFarmer(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.OnchainArtworkFarmer
			)
		);
		return onchainArtworkFarmer.uri(internalTokenId, isRevealed);
	}

	function getMetadata(uint256 tokenId) public view returns (string memory) {
		uint256 internalTokenId = getInternalTokenId(tokenId);
		bool isRevealed = internalTokenId >= 1;

		string memory imageUrl = isOnChainArtworkReady
			? getOnChainSVGBase64ImageUrl(internalTokenId, isRevealed)
			: getIPFSImageUrl(internalTokenId, isRevealed);
		string memory metadata = string(
			abi.encodePacked(
				'{"name":"Honest Farmer #',
				tokenId.toString(),
				'","description":"Just some honest farmers.","image":"',
				imageUrl,
				'","attributes":',
				compileAttributes(internalTokenId, isRevealed),
				"}"
			)
		);

		return metadata;
	}

	function uri(uint256 tokenId) public view returns (string memory) {
		string memory metadata = getMetadata(tokenId);

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					base64(bytes(metadata))
				)
			);
	}

	// Utilities
	function getInternalTokenId(uint256 tokenId) public view returns (uint256) {
		IRevealFarmer revealFarmer = IRevealFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.RevealFarmer)
		);

		return revealFarmer.getInternalTokenId(tokenId);
	}

	function _getPackedAttributes(
		string memory passionTrait,
		string memory skillTraits,
		string memory visualTrait
	) private pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					"[",
					passionTrait,
					",",
					skillTraits,
					",",
					visualTrait,
					"]"
				)
			);
	}

	function setVisualTraitValues(
		LibraryFarmer.VisualTraitType traitTypeId,
		string[] memory visualTraitValues
	) public onlyOwner {
		for (uint256 i = 0; i < visualTraitValues.length; i++) {
			string memory visualTraitValue = visualTraitValues[i];

			visualTraitsByTraitIdByTraitType[traitTypeId][i] = visualTraitValue;
		}
	}

	function setSpecialName(uint256 internalTokenId, string memory specialName)
		public
		onlyOwner
	{
		specialNameByInternalTokenId[internalTokenId] = specialName;
	}

	function setIsOnChainArtworkReady(bool _isOnChainArtworkReady)
		public
		onlyOwner
	{
		isOnChainArtworkReady = _isOnChainArtworkReady;
	}

	/**
	 * Visual trait sets are hand picked, but randomly assigned
	 */
	function setInternalTokenMetadata(
		LibraryFarmer.FarmerMetadata[] memory metadata
	) public onlyOwner {
		for (uint256 i = 0; i < metadata.length; i++) {
			uint256 internalTokenId = metadata[i].internalTokenId;

			ipfsHashByInternalTokenId[internalTokenId] = metadata[i].ipfsHash;

			for (uint8 j = 0; j < 8; j++) {
				uint8 visualTraitValueId = metadata[i].visualTraitValueIds[j];

				visualTraitValueIdByInternalTokenIdByTraitType[
					LibraryFarmer.VisualTraitType(j)
				][internalTokenId] = visualTraitValueId;
			}

			if (metadata[i].isSpecial) {
				isSpecialByInternalTokenId[internalTokenId] = true;
			}
		}
	}

	/** BASE 64 - Credits to WizardsAndDragons/Brech Devos */
	string internal constant TABLE =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function base64(bytes memory data) internal pure returns (string memory) {
		if (data.length == 0) return "";

		// load the table into memory
		string memory table = TABLE;

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((data.length + 2) / 3);

		// add some extra buffer at the end required for the writing
		string memory result = new string(encodedLen + 32);

		assembly {
			// set the actual output length
			mstore(result, encodedLen)

			// prepare the lookup table
			let tablePtr := add(table, 1)

			// input ptr
			let dataPtr := data
			let endPtr := add(dataPtr, mload(data))

			// result ptr, jump over length
			let resultPtr := add(result, 32)

			// run over the input, 3 bytes at a time
			for {

			} lt(dataPtr, endPtr) {

			} {
				dataPtr := add(dataPtr, 3)

				// read 3 bytes
				let input := mload(dataPtr)

				// write 4 characters
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
				mstore(
					resultPtr,
					shl(248, mload(add(tablePtr, and(input, 0x3F))))
				)
				resultPtr := add(resultPtr, 1)
			}

			// padding with '='
			switch mod(mload(data), 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}
		}

		return result;
	}
}