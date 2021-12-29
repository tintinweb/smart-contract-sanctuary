// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Strings.sol";
import "./VRFConsumerBase.sol";

import "./IHonestTraits.sol";

contract HonestTraits is IHonestTraits, Ownable, VRFConsumerBase {
	using Strings for uint8;
	using Strings for uint256;

	bool public _isRevealed = false;

	// Skills
	uint8 public maxSkillLevel = 30;
	uint256 public xpRequirementForLevelUp = 1000;
	string[6] private skills = [
		"Degen",
		"Honesty",
		"Fitness",
		"Strategy",
		"Patience",
		"Agility"
	];

	string[3] private passions = ["Harvesting", "Fishing", "Planting"];

	/**
	 * Visual
	 */
	string public imageBaseUri;
	string[8] private visualAttributeCategories = [
		"Background",
		"Skin",
		"Clothing",
		"Mouth",
		"Nose",
		"Head",
		"Eyes",
		"Ears"
	];

	// Visuals
	// Maps internal token id to array of attribute value ids, index of ids maps to category ids
	mapping(uint256 => uint8[8]) public visualAttributeValueIdsByInternalId;
	mapping(uint256 => bool) public isSpecialItemByInternalId;
	// Maps attribute category Id to attribute values
	mapping(uint8 => string[])
		public visualAttributeValuesByAttributeValueCategoryId;
	mapping(uint256 => string) public ipfsHashByInternalId;

	// Gameplay
	mapping(uint256 => uint256) public xpByInternalId;
	mapping(uint256 => uint8) public passionIdByInternalId;
	mapping(uint256 => uint8[6]) public skillLevelsByInternalId;

	// Internal id mapping, used for provable fair assignment of metadata
	mapping(uint256 => uint256) public internalIdByTokenId;

	// Chainlink VRF
	bytes32 internal keyHash;
	uint256 internal fee;
	uint256 public randomResult;

	constructor(
		string memory _imageBaseUri,
		string memory _unrevealedIpfsHash,
		address _vrfCoordinator,
		address _link,
		bytes32 _keyHash,
		uint256 _fee
	) VRFConsumerBase(_vrfCoordinator, _link) {
		imageBaseUri = _imageBaseUri;
		keyHash = _keyHash;
		fee = _fee;

		// Assign unrevealed metadata
		ipfsHashByInternalId[1] = _unrevealedIpfsHash;
		for (uint8 k = 0; k < 6; k++) {
			skillLevelsByInternalId[1][k] = 1;
		}
	}

	modifier isRevelead() {
		if (_isRevealed) {
			_;
		}
	}

	function getPassion(uint256 internalId)
		public
		view
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(
					'{"trait_type":"Passion",',
					'"value":"',
					passions[passionIdByInternalId[internalId]],
					'"}'
				)
			);
	}

	function getSkillAttribute(uint256 internalId, uint8 skillId)
		public
		view
		returns (string memory)
	{
		string memory skillName = skills[skillId];
		uint8 level = skillLevelsByInternalId[internalId][skillId];

		return
			string(
				abi.encodePacked(
					'{"trait_type":"',
					skillName,
					'","value":',
					level.toString(),
					',"max_value":',
					maxSkillLevel.toString(),
					"}"
				)
			);
	}

	function getVisualAttribute(
		uint256 internalId,
		uint8 visualAttributeCategoryId
	) public view returns (string memory) {
		string memory visualAttributeCategory = visualAttributeCategories[
			visualAttributeCategoryId
		];

		uint8 visualAttributeValueId = visualAttributeValueIdsByInternalId[
			internalId
		][visualAttributeCategoryId];

		string
			memory visualAttributeValue = visualAttributeValuesByAttributeValueCategoryId[
				visualAttributeCategoryId
			][visualAttributeValueId];

		return
			string(
				abi.encodePacked(
					'{"trait_type":"',
					visualAttributeCategory,
					'","value":"',
					visualAttributeValue,
					'"}'
				)
			);
	}

	function compileAttributes(uint256 internalId)
		public
		view
		returns (string memory)
	{
		string memory passion = getPassion(internalId);

		string memory skillAttributes = string(
			abi.encodePacked(
				",",
				getSkillAttribute(internalId, 0),
				",",
				getSkillAttribute(internalId, 1),
				",",
				getSkillAttribute(internalId, 2),
				",",
				getSkillAttribute(internalId, 3),
				",",
				getSkillAttribute(internalId, 4),
				",",
				getSkillAttribute(internalId, 5),
				","
			)
		);

		string memory visualAttributes = string(
			abi.encodePacked(
				getVisualAttribute(internalId, 0),
				",",
				getVisualAttribute(internalId, 1),
				",",
				getVisualAttribute(internalId, 2),
				",",
				getVisualAttribute(internalId, 3),
				",",
				getVisualAttribute(internalId, 4),
				",",
				getVisualAttribute(internalId, 5),
				",",
				getVisualAttribute(internalId, 6),
				",",
				getVisualAttribute(internalId, 7)
			)
		);

		bool isSpecial = isSpecialItemByInternalId[internalId];
		string memory specialAttributes = isSpecial
			? ',{"trait_type":"Special","value":"True"}'
			: "";

		return
			string(
				abi.encodePacked(
					"[",
					passion,
					skillAttributes,
					visualAttributes,
					specialAttributes,
					"]"
				)
			);
	}

	function getImageUrl(uint256 internalId)
		public
		view
		returns (string memory)
	{
		return
			string(
				abi.encodePacked(imageBaseUri, ipfsHashByInternalId[internalId])
			);
	}

	function getMetadata(uint256 tokenId) public view returns (string memory) {
		uint256 internalId = getInternalId(tokenId);

		string memory imageUrl = getImageUrl(internalId);
		string memory metadata = string(
			abi.encodePacked(
				'{"name":"Honest Farmer #',
				tokenId.toString(),
				'","description":"Just some honest farmers.","image":"',
				imageUrl,
				'","attributes":',
				compileAttributes(internalId),
				"}"
			)
		);

		return metadata;
	}

	function uri(uint256 tokenId) external view returns (string memory) {
		string memory metadata = getMetadata(tokenId);

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					base64(bytes(metadata))
				)
			);
	}

	function increaseXP(uint256 tokenId, uint256 xp)
		external
		onlyOwner
		isRevelead
	{
		uint256 internalId = getInternalId(tokenId);
		uint256 prevXp = xpByInternalId[internalId];
		uint256 newXp = prevXp + xp;

		xpByInternalId[internalId] = newXp > xpRequirementForLevelUp
			? xpRequirementForLevelUp
			: newXp;
	}

	function levelUp(uint256 tokenId, uint8 levelId) external isRevelead {
		uint256 internalId = getInternalId(tokenId);
		uint256 xp = xpByInternalId[internalId];
		uint8 prevSkillLevel = skillLevelsByInternalId[internalId][levelId];

		require(prevSkillLevel < maxSkillLevel, "Max level reached");
		require(xp >= xpRequirementForLevelUp, "Not enough xp for level up");

		skillLevelsByInternalId[internalId][levelId] = prevSkillLevel + 1;
		xpByInternalId[internalId] = 0;
	}

	/**
	 * Reveal & VRF
	 */
	function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
		require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
		return requestRandomness(keyHash, fee);
	}

	function fulfillRandomness(bytes32 requestId, uint256 randomness)
		internal
		override
	{
		randomResult = (randomness % 3000) + 1;
	}

	function reveal() public onlyOwner {
		require(!_isRevealed, "Already revealed");
		require(randomResult > 0, "No randomness");

		for (uint256 id = 1; id <= 3000; id++) {
			uint256 shiftedId = id + randomResult;
			uint256 internalId = shiftedId > 3000
				? shiftedId - 3000
				: shiftedId;
			internalIdByTokenId[id] = internalId;

			uint8 shiftedPassiondId = uint8((id + randomResult) % 3); // Random number between 0 and 2
			passionIdByInternalId[internalId] = shiftedPassiondId;
		}

		_isRevealed = true;
	}

	/**
	 * Utilities
	 */
	function uploadVisualTraitValues(
		uint8 visualTraitCategoryId,
		string[] memory visualTraitValues
	) public onlyOwner {
		for (uint256 i = 0; i < visualTraitValues.length; i++) {
			string memory visualTraitValue = visualTraitValues[i];

			visualAttributeValuesByAttributeValueCategoryId[
				visualTraitCategoryId
			].push(visualTraitValue);
		}
	}

	struct InitalMetadata {
		uint256 internalId;
		uint8[8] visualTraitValueIds;
		bool isSpecial;
		string ipfsHash;
	}

	/**
	 * Visual trait sets are hand picked, but randomly assigned
	 */
	function uploadInitialMetadata(InitalMetadata[] memory metadata)
		public
		onlyOwner
	{
		for (uint256 i = 0; i < metadata.length; i++) {
			uint256 internalId = metadata[i].internalId;

			ipfsHashByInternalId[internalId] = metadata[i].ipfsHash;

			for (uint8 j = 0; j < 8; j++) {
				uint8 visualTraitValueId = metadata[i].visualTraitValueIds[j];
				visualAttributeValueIdsByInternalId[internalId][
					j
				] = visualTraitValueId;
			}

			for (uint8 k = 0; k < 6; k++) {
				skillLevelsByInternalId[internalId][k] = 1;
			}

			if (metadata[i].isSpecial) {
				isSpecialItemByInternalId[internalId] = true;
			}
		}
	}

	function getInternalId(uint256 tokenId) public view returns (uint256) {
		uint256 internalId = internalIdByTokenId[tokenId];
		if (!_isRevealed || internalId == 0) return 1;
		return internalIdByTokenId[tokenId];
	}

	function setImageBaseUri(string memory _imageBaseUri) public onlyOwner {
		imageBaseUri = _imageBaseUri;
	}

	function setMaxSkillLevel(uint8 _maxSkillLevel) public onlyOwner {
		maxSkillLevel = _maxSkillLevel;
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