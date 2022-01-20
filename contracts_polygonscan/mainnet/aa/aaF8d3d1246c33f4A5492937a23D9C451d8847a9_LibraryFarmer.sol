/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library LibraryFarmer {
	// Metadata
	enum Passion {
		Harvesting,
		Fishing,
		Planting
	}

	enum Skill {
		Degen,
		Honesty,
		Fitness,
		Strategy,
		Patience,
		Agility
	}

	enum VisualTraitType {
		Background,
		Skin,
		Clothing,
		Mouth,
		Nose,
		Head,
		Eyes,
		Ears
	}

	struct FarmerMetadata {
		uint256 internalTokenId;
		uint8[8] visualTraitValueIds;
		bool isSpecial;
		string ipfsHash;
	}

	// Mint
	enum MintType {
		PUBLIC,
		WHITELIST,
		FREE
	}

	function isWhitelistMintType(LibraryFarmer.MintType mintType)
		public
		pure
		returns (bool)
	{
		return mintType == LibraryFarmer.MintType.WHITELIST;
	}

	// Infrastructure
	enum FarmerContract {
		HonestFarmerClubV1,
		HonestFarmerClubV2,
		EnergyFarmer,
		MetaFarmer,
		MigrationTractor,
		OnchainArtworkFarmer,
		RevealFarmer,
		WhitelistFarmer
	}
}