// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../libraries/NornirStructs.sol';

/**
 * Nornir Resolver Contract
 *
 * Implements Condition + Component Name resolution functionality, defining the probability distributions of each asset within their sets
 *
 * Separated from the main Nornir Contract due to the Spurious Dragon Contract size limit, as well as to enable pre-launch tweaks and additions to the Viking asset set
 */
contract NornirResolver {

	/**
	 * Given a VikingStats, resolve and return a VikingConditions, denoting the Conditions of each of the Viking's items
	 *
	 * @param stats the VikingStats numerically representing a Viking
	 *
	 * @return the VikingConditions resolved from the stats
	 */
    function resolveConditions(NornirStructs.VikingStats memory stats) external pure returns (NornirStructs.VikingConditions memory) {
        return NornirStructs.VikingConditions(
			resolveClothesCondition(stats.speed),
			resolveClothesCondition(stats.stamina),
			resolveItemCondition(stats.intelligence),
			resolveItemCondition(stats.defence),
			resolveItemCondition(stats.attack)
		);
    }

	/**
	 * Given a VikingStats and a VikingConditions, resolve and return a VikingComponents, denoting the names of the nine Viking assets
	 *
	 * @param stats the VikingStats numerically representing a Viking
	 * @param conditions the VikingConditions denoting the Condition of each of the Viking's items, used to augment items as appropriate
	 *
	 * @return the resolved VikingComponents
	 */
    function resolveComponents(NornirStructs.VikingStats memory stats, NornirStructs.VikingConditions memory conditions) external pure returns (NornirStructs.VikingComponents memory) {
        return NornirStructs.VikingComponents(
			resolveBeard(stats.appearance / 1000000),
			resolveBody((stats.appearance / 10000) % 100),
			resolveFace((stats.appearance / 100) % 100),
			resolveTop(stats.appearance % 100),
			resolveBoots(stats.boots, conditions.boots),
			resolveBottoms(stats.bottoms, conditions.bottoms),
			resolveHelmet(stats.helmet, conditions.helmet),
			resolveShield(stats.shield, conditions.shield),
			resolveWeapon(stats.weapon, conditions.weapon)
		);
    }

	/**
	 * Given a statistic, resolve the Condition of an item of Clothing
	 *
	 * Clothes Conditions for Boots and Bottoms are dictated by the Speed and Stamina statistics respectively
	 *
	 * @param stat the statistic to resolve by
	 *
	 * @return the name of the Condition
	 */
    function resolveClothesCondition(uint256 stat) internal pure returns (string memory) {
		// 10%
        if (stat <= 9) {
            return 'Standard';
        }

        // 30%
        if (stat <= 39) {
            return 'Ragged';
        }

        // 25%
        if (stat <= 64) {
            return 'Rough';
        }

        // 20%
        if (stat <= 84) {
            return 'Used';
        }

        // 10%
        if (stat <= 94) {
            return 'Good';
        }

        // 5%
        return 'Perfect';
	}

	/**
	 * Given a statistic, resolve the Condition of an Item
	 *
	 * Item Conditions for Helmets, Shields and Weapons are dictated by the Intelligence, Defence and Attack statistics respectively
	 *
	 * @param stat the statistic to resolve by
	 *
	 * @return the name of the Condition
	 */
	function resolveItemCondition(uint256 stat) internal pure returns (string memory) {
		// 10%
        if (stat <= 9) {
            return 'None';
        }

        // 30%
        if (stat <= 39) {
            return 'Destroyed';
        }

        // 25%
        if (stat <= 64) {
            return 'Battered';
        }

        // 20%
        if (stat <= 84) {
            return 'War Torn';
        }

        // 10%
        if (stat <= 94) {
            return 'Battle Ready';
        }

        // 5%
        return 'Flawless';
	}

	/**
	 * Given a selector from a VikingStats, resolve the name of a Viking's Beard asset
	 *
	 * NB: Beard's selector is unique in that it's the first 2 digits of 'appearance', and thus ranged 10-99
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Beard asset
	 */
	function resolveBeard(uint256 selector) internal pure returns (string memory) {
		// 20% (18 / 90)
        if (selector <= 27) {
            return 'Stubble';
        }

        // 20% (18 / 90)
        if (selector <= 45) {
            return 'Trim';
        }

        // ~15.56% (14 / 90)
        if (selector <= 59) {
            return 'Bushy';
        }

        // ~14.43% (13 / 90)
        if (selector <= 72) {
            return 'Beaded';
        }

        // 10% (9 / 90)
        if (selector <= 81) {
            return 'Straggly';
        }

        // 10% (9 / 90)
        if (selector <= 90) {
            return 'Goatee';
        }

        // ~6.67% (6 / 90)
        if (selector <= 96) {
            return 'Slick';
        }

        // 3.32%% (3 / 90)
        return 'Sophisticated';
	}

	/**
	 * Given a selector from a VikingStats, resolve the name of a Viking's Body asset
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Body asset
	 */
	function resolveBody(uint256 selector) internal pure returns (string memory) {
		// 13%
        if (selector <= 12) {
            return 'Base 1';
        }

        // 13%
        if (selector <= 25) {
            return 'Base 2';
        }

        // 13%
        if (selector <= 38) {
            return 'Base 3';
        }

        // 13%
        if (selector <= 51) {
            return 'Tatted';
        }

        // 11%
        if (selector <= 62) {
            return 'Inked';
        }

        // 9%
        if (selector <= 71) {
            return 'Devil';
        }

        // 9%
        if (selector <= 80) {
            return 'Zombie (Green)';
        }

        // 7%
        if (selector <= 87) {
            return 'Pigman';
        }

        // 6%
        if (selector <= 93) {
            return 'Robot';
        }

        // 4%
        if (selector <= 97) {
            return 'Zombie (Blue)';
        }

        // 2%
        return 'Wolfman';
	}

	/**
	 * Given a selector from a VikingStats, resolve the name of a Viking's Face asset
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Face asset
	 */
	function resolveFace(uint256 selector) internal pure returns (string memory) {
		// 15%
        if (selector <= 14) {
            return 'Smirk';
        }

        // 15%
        if (selector <= 29) {
            return 'Stern';
        }

        // 15%
        if (selector <= 44) {
            return 'Grin';
        }

        // 12%
        if (selector <= 56) {
            return 'Angry';
        }

        // 10%
        if (selector <= 66) {
            return 'Singer';
        }

        // 10%
        if (selector <= 76) {
            return 'Worried';
        }

        // 8%
        if (selector <= 84) {
            return 'Fangs';
        }

        // 7%
        if (selector <= 91) {
            return 'Patch';
        }

        // 5%
        if (selector <= 96) {
            return 'Cyclops';
        }

        // 3%
        return 'Cool';
	}

	/**
	 * Given a selector from a VikingStats, resolve the name of a Viking's Top asset
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Top asset
	 */
	function resolveTop(uint256 selector) internal pure returns (string memory) {
		// 10%
        if (selector <= 9) {
            return 'Tattered (Blue)';
        }

        // 10%
        if (selector <= 19) {
            return 'Strap';
        }

        // 8%
        if (selector <= 27) {
            return 'Tattered (Grey)';
        }

        // 8%
        if (selector <= 35) {
            return 'Gorget';
        }

        // 7%
        if (selector <= 42) {
            return 'Tattered (Red)';
        }

        // 7%
        if (selector <= 49) {
            return 'V Neck (Pink)';
        }

        // 7%
        if (selector <= 56) {
            return 'Shirt (Grey)';
        }

        // 6%
        if (selector <= 62) {
            return 'Traditional';
        }

        // 5%
        if (selector <= 67) {
            return 'V Neck (Blue)';
        }

        // 5%
        if (selector <= 72) {
            return 'Shirt (Red)';
        }

        // 4%
        if (selector <= 76) {
            return 'Jacket (Pink)';
        }

        // 4%
        if (selector <= 80) {
            return 'Jacket (Grey)';
        }

        // 4%
        if (selector <= 84) {
            return 'Vest (Green)';
        }

        // 4%
        if (selector <= 88) {
            return 'Vest (Pink)';
        }

        // 3%
        if (selector <= 91) {
            return 'V Neck (Grey)';
        }

        // 3%
        if (selector <= 94) {
            return 'Shirt (Blue)';
        }

        // 2%
        if (selector <= 96) {
            return 'Jacket (Purple)';
        }

        // 2%
        if (selector <= 98) {
            return 'Vest (Yellow)';
        }

        // 1%
        return 'Pendant';
	}

	/**
	 * Given a selector from a VikingStats and a condition from a VikingConditions, resolve the name of a Viking's Boots asset
	 *
	 * Clothes are potentially replaced with a standard asset if the Statistic was low enough to resolve the Condition as 'Standard'
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Boots asset
	 */
	function resolveBoots(uint256 selector, string memory condition) internal pure returns (string memory) {
		// (10%)
		if (strEqual(condition, 'Standard')) return condition;

		// 30% (28% overall)
        if (selector <= 29) {
            return 'Leather';
        }

        // 25% (23% overall)
        if (selector <= 54) {
            return 'Laced';
        }

        // 25% (23% overall)
        if (selector <= 79) {
            return 'Sandals';
        }

        // 12% (10% overall)
        if (selector <= 91) {
            return 'Tailored';
        }

        // 8% (6% overall)
        return 'Steel Capped';
	}

	/**
	 * Given a selector from a VikingStats and a condition from a VikingConditions, resolve the name of a Viking's Bottoms asset
	 *
	 * Clothes are potentially replaced with a standard asset if the Statistic was low enough to resolve the Condition as 'Standard'
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Bottoms asset
	 */
	function resolveBottoms(uint256 selector, string memory condition) internal pure returns (string memory) {
		// (10%)
		if (strEqual(condition, 'Standard')) return condition;

		// 30% (28% overall)
        if (selector <= 29) {
            return 'Shorts';
        }

        // 25% (23% overall)
        if (selector <= 54) {
            return 'Buckled';
        }

        // 25% (23% overall)
        if (selector <= 79) {
            return 'Patchwork';
        }

        // 12% (10% overall)
        if (selector <= 91) {
            return 'Short Shorts';
        }

        // 8% (6% overall)
        return 'Kingly';
	}

	/**
	 * Given a selector from a VikingStats and a condition from a VikingConditions, resolve the name of a Viking's Helmet asset
	 *
	 * Items are potentially voided if the Statistic was low enough to resolve the Condition as 'None'
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Helmet asset
	 */
	function resolveHelmet(uint256 selector, string memory condition) internal pure returns (string memory) {
		// (10%)
		if (strEqual(condition, 'None')) return condition;

		// 30% (28% overall)
        if (selector <= 29) {
            return 'Cap';
        }

        // 25% (23% overall)
        if (selector <= 54) {
            return 'Horned';
        }

        // 25% (23% overall)
        if (selector <= 79) {
            return 'Headband';
        }

        // 12% (10% overall)
        if (selector <= 91) {
            return 'Spiky';
        }

        // 8% (6% overall)
        return 'Bejeweled';
	}

	/**
	 * Given a selector from a VikingStats and a condition from a VikingConditions, resolve the name of a Viking's Shield asset
	 *
	 * Items are potentially voided if the Statistic was low enough to resolve the Condition as 'None'
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Shield asset
	 */
	function resolveShield(uint256 selector, string memory condition) internal pure returns (string memory) {
		// (10%)
		if (strEqual(condition, 'None')) return condition;

		// 30% (28% overall)
        if (selector <= 29) {
            return 'Wooden';
        }

        // 25% (23% overall)
        if (selector <= 54) {
            return 'Ornate';
        }

        // 25% (23% overall)
        if (selector <= 79) {
            return 'Scutum';
        }

        // 12% (10% overall)
        if (selector <= 91) {
            return 'Reinforced';
        }

        // 8% (6% overall)
        return 'Bones';
	}

	/**
	 * Given a selector from a VikingStats and a condition from a VikingConditions, resolve the name of a Viking's Weapon asset
	 *
	 * Items are potentially voided if the Statistic was low enough to resolve the Condition as 'None'
	 *
	 * @param selector the selector to resolve by
	 *
	 * @return the name of the Viking's Weapon asset
	 */
	function resolveWeapon(uint256 selector, string memory condition) internal pure returns (string memory) {
		// (10%)
		if (strEqual(condition, 'None')) return condition;

		// 23% (~21.572% overall)
        if (selector <= 22) {
            return 'Axe';
        }

        // 20% (~18.572% overall))
        if (selector <= 42) {
            return 'Trident';
        }

        // 18% (~16.572% overall)
        if (selector <= 60) {
            return 'Plank';
        }

        // 16% (~14.572% overall)
        if (selector <= 76) {
            return 'Sword';
        }

        // 12% (~10.572% overall)
        if (selector <= 88) {
            return 'Bow';
        }

        // 7% (~5.572% overall)
        if (selector < 95) {
            return 'Bat';
        }

        // 4% (~2.572% overall)
        return 'Hammer';
	}

	/**
	 * String comparison method
	 */
	function strEqual(string memory a, string memory b) internal pure returns (bool) {
		return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Structs required by both Nornir and NornirResolver implemented in a library for sharing
 */
library NornirStructs {

	/** VikingStats - a store for the VRF-derived numerical representation of a Viking */
    struct VikingStats {
		string name;
		uint256 boots;
		uint256 bottoms;
		uint256 helmet;
		uint256 shield;
		uint256 weapon;
		uint256 attack;
		uint256 defence;
		uint256 intelligence;
		uint256 speed;
		uint256 stamina;
		uint256 appearance;
	}

	/** VikingComponents - a store for the VikingStats-derived resolved Component asset names for a Viking */
	struct VikingComponents {
		string beard;
		string body;
		string face;
		string top;
		string boots;
		string bottoms;
		string helmet;
		string shield;
		string weapon;
	}

	/** VikingConditions - a store for the VikingStats-derived resolved Component Condition names for a Viking's Clothes + Items */
	struct VikingConditions {
		string boots;
		string bottoms;
		string helmet;
		string shield;
		string weapon;
	}
}

{
  "optimizer": {
    "enabled": true,
    "runs": 175
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}