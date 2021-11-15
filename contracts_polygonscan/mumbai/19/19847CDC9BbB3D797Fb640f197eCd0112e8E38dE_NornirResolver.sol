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

        // 40%
        if (stat <= 49) {
            return 'Ragged';
        }

        // 25%
        if (stat <= 74) {
            return 'Rough';
        }

        // 15%
        if (stat <= 89) {
            return 'Used';
        }

        // 7%
        if (stat <= 96) {
            return 'Good';
        }

        // 3%
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

        // 40%
        if (stat <= 49) {
            return 'Destroyed';
        }

        // 25%
        if (stat <= 74) {
            return 'Battered';
        }

        // 15%
        if (stat <= 89) {
            return 'War Torn';
        }

        // 7%
        if (stat <= 96) {
            return 'Battle Ready';
        }

        // 3%
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
		// 20%
        if (selector <= 27) {
            return 'Stubble';
        }

        // 20%
        if (selector <= 45) {
            return 'Trim';
        }

        // 20%
        if (selector <= 63) {
            return 'Bushy';
        }

        // 10%
        if (selector <= 72) {
            return 'Beaded';
        }

        // 10%
        if (selector <= 81) {
            return 'Straggly';
        }

        // 10%
        if (selector <= 90) {
            return 'Goatee';
        }

        // ~6.7%
        if (selector <= 96) {
            return 'Slick';
        }

        // ~3.3%
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
		// 20%
        if (selector <= 19) {
            return 'Base 1';
        }

        // 20%
        if (selector <= 39) {
            return 'Base 2';
        }

        // 20%
        if (selector <= 59) {
            return 'Base 3';
        }

        // 10%
        if (selector <= 69) {
            return 'Inked';
        }

        // 10%
        if (selector <= 79) {
            return 'Tatted';
        }

        // 5%
        if (selector <= 84) {
            return 'Devil';
        }

        // 5%
        if (selector <= 89) {
            return 'Zombie (Green)';
        }

        // 4%
        if (selector <= 93) {
            return 'Pigman';
        }

        // 3%
        if (selector <= 96) {
            return 'Robot';
        }

        // 2%
        if (selector <= 98) {
            return 'Zombie (Blue)';
        }

        // 1%
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

        // 13%
        if (selector <= 42) {
            return 'Worried';
        }

        // 12%
        if (selector <= 54) {
            return 'Angry';
        }

        // 10%
        if (selector <= 64) {
            return 'Singer';
        }

        // 10%
        if (selector <= 74) {
            return 'Grin';
        }

        // 10%
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
		/* Tattered - 30% overall */
        // 6%
        if (selector <= 5) {
            return 'Tattered (Blue)';
        }

        // 6%
        if (selector <= 11) {
            return 'Tattered (Dark Grey)';
        }

        // 6%
        if (selector <= 17) {
            return 'Tattered (Light Grey)';
        }

        // 6%
        if (selector <= 23) {
            return 'Tattered (Purple)';
        }

        // 4%
        if (selector <= 27) {
            return 'Tattered (Red)';
        }

        // 2%
        if (selector <= 29) {
            return 'Tattered (Yellow)';
        }

        /* Tank Top - 20% overall */
        // 4%
        if (selector <= 33) {
            return 'Tank Top (Blue)';
        }

        // 4%
        if (selector <= 37) {
            return 'Tank Top (Dark Grey)';
        }

        // 4%
        if (selector <= 41) {
            return 'Tank Top (Green)';
        }

        // 3%
        if (selector <= 44) {
            return 'Tank Top (Light Grey)';
        }

        // 3%
        if (selector <= 47) {
            return 'Tank Top (Pink)';
        }

        // 2%
        if (selector <= 49) {
            return 'Tank Top (Red)';
        }

        /* Vest - 20% overall */
        // 5%
        if (selector <= 54) {
            return 'Vest (Blue)';
        }

        // 5%
        if (selector <= 59) {
            return 'Vest (Green)';
        }

        // 5%
        if (selector <= 64) {
            return 'Vest (Pink)';
        }

        // 3%
        if (selector <= 67) {
            return 'Vest (White)';
        }

        // 2%
        if (selector <= 69) {
            return 'Vest (Yellow)';
        }

        /* Winter Jacket - 15% overall */
        // 3%
        if (selector <= 72) {
            return 'Winter Jacket (Blue)';
        }

        // 3%
        if (selector <= 75) {
            return 'Winter Jacket (Dark Grey)';
        }

        // 3%
        if (selector <= 78) {
            return 'Winter Jacket (Green)';
        }

        // 2%
        if (selector <= 80) {
            return 'Winter Jacket (Light Grey)';
        }

        // 2%
        if (selector <= 82) {
            return 'Winter Jacket (Pink)';
        }

        // 2%
        if (selector <= 84) {
            return 'Winter Jacket (Purple)';
        }

        /* Fitted Shirt - 10% overall */
        // 2%
        if (selector <= 86) {
            return 'Fitted Shirt (Blue)';
        }

        // 2%
        if (selector <= 88) {
            return 'Fitted Shirt (Green)';
        }

        // 2%
        if (selector <= 90) {
            return 'Fitted Shirt (Grey)';
        }

        // 2%
        if (selector <= 92) {
            return 'Fitted Shirt (Pink)';
        }

        // 1%
        if (selector <= 93) {
            return 'Fitted Shirt (Red)';
        }

        // 1%
        if (selector <= 94) {
            return 'Fitted Shirt (Yellow)';
        }

        /* Strapped - 5% */
        return 'Strapped';
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
		if (strEqual(condition, 'Standard')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Leather';
        }

        // 25%
        if (selector <= 59) {
            return 'Laced';
        }

        // 20%
        if (selector <= 79) {
            return 'Sandals';
        }

        // 12%
        if (selector <= 91) {
            return 'Tailored';
        }

        // 8%
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
		if (strEqual(condition, 'Standard')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Shorts';
        }

        // 25%
        if (selector <= 59) {
            return 'Buckled';
        }

        // 20%
        if (selector <= 79) {
            return 'Patchwork';
        }

        // 12%
        if (selector <= 91) {
            return 'Short Shorts';
        }

        // 8%
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
		if (strEqual(condition, 'None')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Cap';
        }

        // 25%
        if (selector <= 59) {
            return 'Horned';
        }

        // 20%
        if (selector <= 79) {
            return 'Headband';
        }

        // 12%
        if (selector <= 91) {
            return 'Spiky';
        }

        // 8%
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
		if (strEqual(condition, 'None')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Wooden';
        }

        // 25%
        if (selector <= 59) {
            return 'Ornate';
        }

        // 20%
        if (selector <= 79) {
            return 'Reinforced';
        }

        // 12%
        if (selector <= 91) {
            return 'Scutum';
        }

        // 8%
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
		if (strEqual(condition, 'None')) return condition;

		// 35%
        if (selector <= 34) {
            return 'Plank';
        }

        // 25%
        if (selector <= 59) {
            return 'Axe';
        }

        // 20%
        if (selector <= 79) {
            return 'Sword';
        }

        // 10%
        if (selector <= 89) {
            return 'Trident';
        }

        // 6%
        if (selector <= 95) {
            return 'Bat';
        }

        // 4%
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

