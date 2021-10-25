// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { LootItem } from "./LootItem.sol";

/// @author 0xBlackbeard
contract LootLegs is LootItem {
	constructor() LootItem("Programmable Loot [Legs]", "pLOOT/legs") {
		items = [
			"Bath towel",
			"Braies",
			"Breeches",
			"Chausses",
			"Garters",
			"Greaves",
			"Hold-ups",
			"Hose",
			"Jeans",
			"Knee highs",
			"Leggings",
			"Legwarmers",
			"Miniskirt",
			"Pants",
			"Pantyhose",
			"Shendyt",
			"Skirt",
			"Stockings",
			"Trousers",
			"Trunks",
			"Yoga pants"
		];
	}

	/**
	 * @dev See {LootContainer-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		return lootURI(tokenId, Items.LEGS);
	}
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";
import { IGovernable } from "./IGovernable.sol";
import { ILootItem } from "./ILootItem.sol";

interface ILootContainer is IERC721Enumerable, IERC721Permit {
	enum Containers {
		SACK,
		BARREL,
		CRATE,
		URN,
		COFFER,
		CHEST,
		TROVE,
		RELIQUARY
	}

	struct Container {
		Containers class;
		uint256 seed;
		uint80 timestamp;
	}

	event ContainerMinted(
		uint256 indexed id,
		ILootContainer.Containers container,
		uint256 randomness,
		address indexed to
	);

	event LootWithdrawn(uint256 containerId, ILootItem.Items item, uint256 indexed itemId);
	event LootDeposited(uint256 containerId, ILootItem.Items item, uint256 indexed itemId);

	function mint(
		address to,
		Containers container,
		uint256 seed
	) external returns (uint256);

	function withdraw(
		uint256 containerId,
		ILootItem.Items item,
		address to
	) external;

	function withdrawAll(uint256 containerId, address to) external;

	function deposit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId
	) external;

	function depositWithPermit(
		uint256 containerId,
		ILootItem.Items item,
		uint256 itemId,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable quotes */

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ILootContainer } from "./interfaces/ILootContainer.sol";
import { ILootItem } from "./interfaces/ILootItem.sol";
import { Base64 } from "./libraries/Base64.sol";
import { ERC721Base } from "./libraries/ERC721Base.sol";
import { Randomness } from "./libraries/Randomness.sol";

/// @author 0xBlackbeard
abstract contract LootItem is ERC721Base, Ownable, Randomness, ILootItem {
	using Strings for uint256;

	uint256 internal constant COMMON_CEILING = 80_87665e13;
	uint256 internal constant UNCOMMON_CEILING = 90_99999e13;
	uint256 internal constant RARE_CEILING = 96_65036e13;
	uint256 internal constant EPIC_CEILING = 99_65430e13;
	uint256 internal constant LEGENDARY_CEILING = 99_99200e13;
	uint256 internal constant MYTHIC_CEILING = 99_99965e13;
	uint256 internal constant RELIC_CEILING = 99_99995e13;

	mapping(uint256 => Item) public loot;

	string[] public items;

	string[] internal appearances = [
		"Ancient",
		"Blunt",
		"Colossal",
		"Corrupted",
		"Degraded",
		"Depleted",
		"Dusty",
		"Elite",
		"Enchanted",
		"Exquisite",
		"Fine",
		"Flawless",
		"Flimsy",
		"Giant",
		"Grand",
		"Great",
		"Greater",
		"Inferior",
		"Large",
		"Lesser",
		"Mighty",
		"Musky",
		"Noble",
		"Ornate",
		"Petty",
		"Polished",
		"Potent",
		"Rough",
		"Ruined",
		"Rusty",
		"Small",
		"Superior",
		"Ugly",
		"Unique"
	];

	string[] internal prefixes = [
		"Acrobat",
		"Agony",
		"Alchemical",
		"Alloy",
		"Alluring",
		"Aluminum",
		"Amazon",
		"Amber",
		"Antimony",
		"Anubis",
		"Apocalypse",
		"Apothecary",
		"Archer",
		"Arctic",
		"Armageddon",
		"Armorer",
		"Assassin",
		"Atlantean",
		"Avenger",
		"Barbarian",
		"Bard",
		"Basilisk",
		"Beastly",
		"Bedrock",
		"Behemoth",
		"Bishop",
		"Bismuth",
		"Blight",
		"Blood",
		"Botryoidal",
		"Bramble",
		"Brimstone",
		"Brood",
		"Calcite",
		"Cancer",
		"Carbon",
		"Carrion",
		"Cataclysm",
		"Celtic",
		"Centaur",
		"Cerberus",
		"Chainmail",
		"Chameleon",
		"Chilling",
		"Chimera",
		"Chimeric",
		"Chronos",
		"Combusting",
		"Copper",
		"Corpse",
		"Crusader",
		"Crystal",
		"Cursed",
		"Death",
		"Demon",
		"Demonic",
		"Devotion",
		"Devouring",
		"Diamond",
		"Dire",
		"Disciple",
		"Disease",
		"Divine",
		"Doom",
		"Draconian",
		"Dragon",
		"Dread",
		"Druid",
		"Dusk",
		"Dwarven",
		"Eagle",
		"Earthly",
		"Ebony",
		"Eden",
		"Elder",
		"Elemental",
		"Elven",
		"Ember",
		"Empyrean",
		"Ethereal",
		"Executioner's",
		"Fair",
		"Fate",
		"Feather",
		"Feral",
		"Flame",
		"Fluorite",
		"Foe",
		"Fossil",
		"Frost",
		"Fur",
		"Gale",
		"Gallic",
		"Garnet",
		"Genesis",
		"Ghastly",
		"Ghoul",
		"Glacier",
		"Glass",
		"Gleam",
		"Gloom",
		"Glowing",
		"Glyph",
		"Goblin",
		"Golden",
		"Golem",
		"Griffin",
		"Grim",
		"Harpy",
		"Hate",
		"Havoc",
		"Healer",
		"Herald",
		"Hollow",
		"Holy",
		"Honour",
		"Horror",
		"Hunt",
		"Hunting",
		"Hydra",
		"Hypnotic",
		"Imperial",
		"Incandescent",
		"Iridescent",
		"Iron",
		"Jade",
		"Juggernaut",
		"Keeper",
		"Knight",
		"Kraken",
		"Lead",
		"Leather",
		"Legion",
		"Light",
		"Loath",
		"Lust",
		"Madness",
		"Maelstrom",
		"Mage",
		"Malevolence",
		"Mandrake",
		"Manticore",
		"Martyrdom",
		"Merchant's",
		"Mercury",
		"Metallic",
		"Meteorite",
		"Mind",
		"Minion",
		"Minotaur",
		"Miracle",
		"Molding",
		"Monk",
		"Morbid",
		"Mutagen",
		"Mutant",
		"Mystic",
		"Necromancer",
		"Nickel",
		"Night-Eye",
		"Oblivion",
		"Obsidian",
		"Oganesson",
		"Ogre",
		"Olympian",
		"Onslaught",
		"Opal",
		"Orcish",
		"Osiris",
		"Pain",
		"Pandemonium",
		"Pangolin",
		"Phoenix",
		"Pilgrim",
		"Pirate",
		"Plague",
		"Platinum",
		"Poison",
		"Porous",
		"Rage",
		"Ragnarok",
		"Ramming",
		"Rapture",
		"Raven",
		"Reaper",
		"Relic",
		"Relict",
		"Rogue",
		"Royal",
		"Rune",
		"Ruthless",
		"Sailor",
		"Samurai",
		"Savage",
		"Saviour",
		"Scourge",
		"Scout",
		"Scribe",
		"Sentient",
		"Shade",
		"Shadow",
		"Shimmering",
		"Shivering",
		"Silent",
		"Silver",
		"Skull",
		"Snakeskin",
		"Sneak",
		"Solstice",
		"Sorcerer",
		"Sorrow",
		"Soul",
		"Spectre",
		"Sphinx",
		"Spirit",
		"Sponge",
		"Spring",
		"Stalwart",
		"Steel",
		"Stone",
		"Storm",
		"Sunken",
		"Swamp",
		"Sylvan",
		"Tempest",
		"Thief",
		"Titan",
		"Titanium",
		"Topaz",
		"Torment",
		"Tourmaline",
		"Treacherous",
		"Troll",
		"Ursine",
		"Valkyrie",
		"Vampire",
		"Vengeance",
		"Venom",
		"Vermilion",
		"Vesper",
		"Victory",
		"Viking",
		"Viper",
		"Vortex",
		"Vulcan",
		"Warrior",
		"Water",
		"Whispering",
		"Witch",
		"Witch-hunter",
		"Woe",
		"Wooden",
		"Worms'",
		"Wrath",
		"Xeon",
		"Zealot"
	];

	string[] internal suffixes = [
		"of Abatement",
		"of Abhorrence",
		"of Aggression",
		"of Agility",
		"of Alteration",
		"of Amelioration",
		"of Anger",
		"of Animosity",
		"of Annihilation",
		"of Beguilement",
		"of Brilliance",
		"of Caress",
		"of Carnage",
		"of Castration",
		"of Charm",
		"of Clarity",
		"of Conjuration",
		"of Coping",
		"of Corruption",
		"of Creation",
		"of Damnation",
		"of Decay",
		"of Deflection",
		"of Depletion",
		"of Destruction",
		"of Detection",
		"of Detonation",
		"of Disbelief",
		"of Discipline",
		"of Disease",
		"of Doom",
		"of Dread",
		"of Elation",
		"of Encumbrance",
		"of Endurance",
		"of Enlightenment",
		"of Eruption",
		"of Eternity",
		"of Evasion",
		"of Extermination",
		"of Fairness",
		"of Faith",
		"of Fire",
		"of Folks",
		"of Fortitude",
		"of Freedom",
		"of Frost",
		"of Fury",
		"of Giants",
		"of Greed",
		"of Hatred",
		"of Holiness",
		"of Honesty",
		"of Illusion",
		"of Immolation",
		"of Immunity",
		"of Incredulity",
		"of Infection",
		"of Infliction",
		"of Influx",
		"of Inhibition",
		"of Invigoration",
		"of Invincibility",
		"of Languor",
		"of Lava",
		"of Levitation",
		"of Levity",
		"of Love",
		"of Mages",
		"of Mysticism",
		"of Negligence",
		"of Night-eye",
		"of Nullification",
		"of Numbing",
		"of Paralysis",
		"of Perfection",
		"of Personality",
		"of Placation",
		"of Poison",
		"of Possession",
		"of Power",
		"of Promiscuity",
		"of Propagation",
		"of Protection",
		"of Purity",
		"of Rage",
		"of Reciprocity",
		"of Reflection",
		"of Refusal",
		"of Replenishment",
		"of Resilience",
		"of Restoration",
		"of Retribution",
		"of Righteousness",
		"of Sand",
		"of Severance",
		"of Shock",
		"of Slumber",
		"of Sneaking",
		"of Speech",
		"of Speed",
		"of Stamina",
		"of Starvation",
		"of Storms",
		"of Symbiosis",
		"of Tempest",
		"of Tenderness",
		"of Thieving",
		"of Titans",
		"of Torture",
		"of Transmutation",
		"of Treachery",
		"of Ugliness",
		"of Usurpation",
		"of Vengeance",
		"of Vitriol",
		"of Warding",
		"of Water-breathing",
		"of Welding",
		"of Wonder",
		"of the Abyss",
		"of the Academic",
		"of the Acrobat",
		"of the Alchemist",
		"of the Apothecary",
		"of the Apotheosis",
		"of the Apprentice",
		"of the Arachnids",
		"of the Arcane",
		"of the Arch-mage",
		"of the Archer",
		"of the Artisan",
		"of the Ashes",
		"of the Assassin",
		"of the Bandit",
		"of the Bane",
		"of the Bard",
		"of the Basilisk",
		"of the Bear",
		"of the Beast",
		"of the Blizzard",
		"of the Boar",
		"of the Buccaneer",
		"of the Captive",
		"of the Cave",
		"of the Citadel",
		"of the Colossus",
		"of the Craft",
		"of the Crown",
		"of the Crusader",
		"of the Crypt",
		"of the Curse",
		"of the Cyclops",
		"of the Dawn",
		"of the Depths",
		"of the Desert",
		"of the Despicable",
		"of the Divine",
		"of the Dragon",
		"of the Drowned",
		"of the Druid",
		"of the Elder",
		"of the Elements",
		"of the Fall",
		"of the Fallen",
		"of the Feline",
		"of the Fish",
		"of the Flagellant",
		"of the Flow",
		"of the Forge",
		"of the Fox",
		"of the Gargoyles",
		"of the Genesis",
		"of the Glacier",
		"of the Gorgon",
		"of the Harpies",
		"of the Healer",
		"of the Herald",
		"of the Hive",
		"of the Hunt",
		"of the Inquisitor",
		"of the Island",
		"of the Jarl",
		"of the Jester",
		"of the Knight",
		"of the Kraken",
		"of the Labyrinth",
		"of the Lady",
		"of the Lair",
		"of the Legion",
		"of the Lover",
		"of the Mage",
		"of the Magician",
		"of the Mandrake",
		"of the Martyr",
		"of the Mere",
		"of the Mermaid",
		"of the Meteorite",
		"of the Mine",
		"of the Monarch",
		"of the Monk",
		"of the Mountain",
		"of the Necromancer",
		"of the Night",
		"of the North",
		"of the Ocean",
		"of the Ogres",
		"of the Oracle",
		"of the Orcs",
		"of the Pangolin",
		"of the Pariah",
		"of the Pharaoh",
		"of the Phoenix",
		"of the Pilgrim",
		"of the Plague",
		"of the Plains",
		"of the Priest",
		"of the Princess",
		"of the Prophet",
		"of the Rats",
		"of the Raven",
		"of the Reaper",
		"of the River",
		"of the Rogue",
		"of the Sage",
		"of the Scales",
		"of the Scout",
		"of the Sea",
		"of the Sentinel",
		"of the Serpent",
		"of the Shadows",
		"of the Shepherd",
		"of the Shrine",
		"of the Sorcerer",
		"of the Steed",
		"of the Storm",
		"of the Swamp",
		"of the Sybil",
		"of the Thief",
		"of the Tower",
		"of the Trolls",
		"of the Twins",
		"of the Undead",
		"of the Unknown",
		"of the Vampire",
		"of the Void",
		"of the Volcano",
		"of the Warrior",
		"of the Water",
		"of the Well",
		"of the Whale",
		"of the Will",
		"of the Wizard",
		"of the Wolf",
		"of the Woods",
		"of the Worms"
	];

	constructor(string memory name, string memory symbol) ERC721Base(name, symbol) {} // solhint-disable-line no-empty-blocks

	function mint(
		address to,
		ILootContainer.Containers container,
		uint256 seed
	) external override onlyOwner {
		uint256 id = totalSupply() + 1;
		_safeMint(to, id);
		loot[id].seed = seed;

		uint256 lootIndex = (uint256(keccak256(abi.encode(randomize(seed), items.length))) % 100e18) % items.length;
		loot[id].index = uint8(lootIndex);

		Rarity rarity = whatRarity(container, Items.HEAD, seed);
		loot[id].rarity = rarity;
		loot[id].appearance = whatAppearance(rarity, seed);
		loot[id].prefix = whichPrefix(rarity, seed);
		loot[id].suffix = whichSuffix(rarity, seed);
		loot[id].augmentation = whichAugmentation(rarity, seed);

		emit ItemMinted(id, Items.HEAD, rarity);
	}

	function whatRarity(
		ILootContainer.Containers container,
		Items item,
		uint256 seed
	) internal view virtual returns (Rarity) {
		uint256 chance = uint256(keccak256(abi.encode(randomize(seed), container, item, totalSupply()))) % 100e18;

		if (container == ILootContainer.Containers.SACK) {
			if (chance > EPIC_CEILING) {
				if (chance % 2 != 1) chance -= chance % (1e17);
			}
		}

		if (container == ILootContainer.Containers.BARREL || container == ILootContainer.Containers.CRATE) {
			if (chance < COMMON_CEILING) chance += chance % (12 * 1e18);
		}

		if (container == ILootContainer.Containers.URN || container == ILootContainer.Containers.COFFER) {
			if (chance < COMMON_CEILING) chance += chance % (16 * 1e18);
			if (chance < UNCOMMON_CEILING) chance += chance % (8 * 1e18);
		}

		if (container == ILootContainer.Containers.CHEST) {
			if (chance < COMMON_CEILING) chance += chance % (18 * 1e18);
			if (chance < UNCOMMON_CEILING) chance += chance % (9 * 1e18);
			else if (chance < RARE_CEILING) chance += chance % (3 * 1e18);
		}

		if (container == ILootContainer.Containers.TROVE) {
			if (chance < COMMON_CEILING) chance += chance % (20 * 1e18);
			else if (chance < UNCOMMON_CEILING) chance += chance % (12 * 1e18);
			else if (chance < RARE_CEILING) chance += chance % (5 * 1e18);
		}

		if (container == ILootContainer.Containers.RELIQUARY) {
			if (chance < COMMON_CEILING) chance += chance % (25 * 1e18);
			else if (chance < UNCOMMON_CEILING) chance += chance % (15 * 1e18);
			else if (chance < RARE_CEILING) chance += chance % (7 * 1e18);
		}

		if (chance <= COMMON_CEILING) return Rarity.COMMON;
		else if (chance <= UNCOMMON_CEILING) return Rarity.UNCOMMON;
		else if (chance <= RARE_CEILING) return Rarity.RARE;
		else if (chance <= EPIC_CEILING) return Rarity.EPIC;
		else if (chance <= LEGENDARY_CEILING) return Rarity.LEGENDARY;
		else if (chance <= MYTHIC_CEILING) return Rarity.MYTHIC;
		else if (chance >= RELIC_CEILING) return Rarity.RELIC;
		else return Rarity.UNKNOWN;
	}

	function whatAppearance(Rarity rarity, uint256 seed) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(randomize(seed), rarity, appearances.length))) % 100e18;

		if (rarity >= Rarity.UNCOMMON) {
			return uint8(chance % appearances.length);
		}

		return 0;
	}

	function whichPrefix(Rarity rarity, uint256 seed) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(randomize(seed), rarity, prefixes.length))) % 100e18;

		if (rarity >= Rarity.RARE) {
			return uint8(chance % prefixes.length);
		}

		return 0;
	}

	function whichSuffix(Rarity rarity, uint256 seed) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(randomize(seed), rarity, suffixes.length))) % 100e18;

		if (rarity >= Rarity.EPIC) {
			return uint8(chance % suffixes.length);
		}

		return 0;
	}

	function whichAugmentation(Rarity rarity, uint256 seed) internal view virtual returns (uint8) {
		uint256 chance = uint256(keccak256(abi.encode(randomize(seed), rarity, 10))) % 100e18;

		if (rarity == Rarity.LEGENDARY) {
			return uint8((chance % 5) + 1);
		} else if (rarity == Rarity.MYTHIC) {
			return uint8((chance % 4) + 6);
		} else if (rarity == Rarity.RELIC) {
			return 10;
		}

		return 0;
	}

	// solhint-disable-next-line no-unused-vars
	function tokenURI(uint256 id) public view virtual override returns (string memory) {
		revert("LootItem::tokenURI: not implemented"); // solhint-disable-line reason-string
	}

	function lootURI(uint256 id, Items itemType) public view virtual override returns (string memory) {
		string[3] memory parts;
		parts[0] = string(
			abi.encodePacked(
				'<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 480 40">',
				"<style>.ploot__base { font-family: serif; font-size: 14px; }",
				".ploot__common { fill: #FFFFFF; }",
				".ploot__uncommon { fill: #DDDDDD; }",
				".ploot__rare { fill: #0088ff; }",
				".ploot__epic { fill: #01FF70; }",
				".ploot__legendary { fill: #FFDD00; }",
				".ploot__mythic { fill: #EB00FF; }",
				".ploot__relic { fill: #FF0099; }</style>",
				'<rect width="100%" height="100%" fill="#000" />'
			)
		);
		parts[1] = lootSVG(id, itemType, true);
		parts[2] = "</svg>";

		string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

		string memory itemName;
		if (itemType == Items.HEAD) itemName = '{"name": "Head #';
		else if (itemType == Items.NECK) itemName = '{"name": "Neck #';
		else if (itemType == Items.CHEST) itemName = '{"name": "Chest #';
		else if (itemType == Items.HANDS) itemName = '{"name": "Hands #';
		else if (itemType == Items.LEGS) itemName = '{"name": "Legs #';
		else if (itemType == Items.FEET) itemName = '{"name": "Feet #';
		else if (itemType == Items.WEAPON) itemName = '{"name": "Weapon #';
		else if (itemType == Items.OFF_HAND) itemName = '{"name": "Off-hand #';

		string memory json = Base64.encode(
			bytes(
				string(
					abi.encodePacked(
						itemName,
						id.toString(),
						'", "description": "Programmable Loot is economically scarce and verifiably randomized loot metadata generated and stored on-chain. Maximum supply is dynamic, originally increasing at 1/10th of Ethereum\'s block rate. Stats, images, and other functionality are omitted for others to interpret. Rarity is probabilistically determined at genesis time. Loot is programmable as items can be exchanged across containers at any time", "image": "data:image/svg+xml;base64,',
						Base64.encode(bytes(output)),
						'"}'
					)
				)
			)
		);
		output = string(abi.encodePacked("data:application/json;base64,", json));

		return output;
	}

	function lootSVG(
		uint256 id,
		Items itemType,
		bool single
	) public view virtual override returns (string memory) {
		if (id == 0) return "";
		if (id > totalSupply()) revert("LootItem::lootSVG: invalid item id"); // solhint-disable-line reason-string
		Item memory item = loot[id];

		string memory output;
		string memory class;
		if (item.rarity == Rarity.COMMON) {
			output = string(abi.encodePacked(items[item.index]));
			class = 'class="ploot__base ploot__common"';
		} else if (item.rarity == Rarity.UNCOMMON) {
			output = string(abi.encodePacked(appearances[item.appearance], " ", items[item.index]));
			class = 'class="ploot__base ploot__uncommon"';
		} else if (item.rarity == Rarity.RARE) {
			output = string(
				abi.encodePacked(appearances[item.appearance], " ", prefixes[item.prefix], " ", items[item.index])
			);
			class = 'class="ploot__base ploot__rare"';
		} else if (item.rarity == Rarity.EPIC) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix]
				)
			);
			class = 'class="ploot__base ploot__epic"';
		} else if (item.rarity == Rarity.LEGENDARY) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix],
					" +",
					item.augmentation
				)
			);
			class = 'class="ploot__base ploot__legendary"';
		} else if (item.rarity == Rarity.MYTHIC) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix],
					" +",
					item.augmentation
				)
			);
			class = 'class="ploot__base ploot__mythic"';
		} else if (item.rarity == Rarity.RELIC) {
			output = string(
				abi.encodePacked(
					appearances[item.appearance],
					" ",
					prefixes[item.prefix],
					" ",
					items[item.index],
					" ",
					suffixes[item.suffix],
					" +",
					item.augmentation
				)
			);
			class = 'class="ploot__base ploot__relic"';
		}

		string memory y;
		if (single) y = 'y="25"';
		else if (itemType == Items.HEAD) y = 'y="25"';
		else if (itemType == Items.NECK) y = 'y="50"';
		else if (itemType == Items.CHEST) y = 'y="75"';
		else if (itemType == Items.HANDS) y = 'y="100"';
		else if (itemType == Items.LEGS) y = 'y="125"';
		else if (itemType == Items.FEET) y = 'y="150"';
		else if (itemType == Items.WEAPON) y = 'y="175"';
		else if (itemType == Items.OFF_HAND) y = 'y="200"';

		return string(abi.encodePacked('<text x="15" ', y, " ", class, ">", output, "</text>"));
	}
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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;
/* solhint-disable func-name-mixedcase */

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Permit is IERC721 {
	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function nonces(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

interface IGovernable {
	function governance() external view returns (address);

	function pendingGovernance() external view returns (address);

	function changeGovernance(address newGov) external;

	function acceptGovernance() external;

	function removeGovernance() external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";
import { IGovernable } from "./IGovernable.sol";
import { ILootContainer } from "./ILootContainer.sol";

interface ILootItem is IERC721Enumerable, IERC721Permit {
	enum Items {
		FREE_SLOT,
		HEAD,
		NECK,
		CHEST,
		HANDS,
		LEGS,
		FEET,
		WEAPON,
		OFF_HAND
	}

	enum Rarity {
		UNKNOWN,
		COMMON,
		UNCOMMON,
		RARE,
		EPIC,
		LEGENDARY,
		MYTHIC,
		RELIC
	}

	struct Item {
		uint256 seed;
		uint8 index;
		uint8 appearance;
		uint8 prefix;
		uint8 suffix;
		uint8 augmentation;
		Rarity rarity;
	}

	event ItemMinted(uint256 indexed id, Items item, Rarity rarity);

	function mint(
		address to,
		ILootContainer.Containers container,
		uint256 seed
	) external;

	function lootURI(uint256 id, Items itemType) external view returns (string memory);

	function lootSVG(
		uint256 id,
		Items itemType,
		bool single
	) external view returns (string memory);
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
pragma solidity ^0.8.9;

/* solhint-disable no-inline-assembly, no-empty-blocks */

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
	string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	function encode(bytes memory data) internal pure returns (string memory) {
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
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
				resultPtr := add(resultPtr, 1)
				mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable reason-string */

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import { IERC721Permit } from "../interfaces/IERC721Permit.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds enumerability of all the token ids
 * in the contract as well as all token ids owned by each account; along with some add-ons (i.e. permits)
 */
abstract contract ERC721Base is ERC721, EIP712, IERC721Enumerable, IERC721Permit {
	using Counters for Counters.Counter;

	// solhint-disable-next-line var-name-mixedcase
	bytes32 public constant override PERMIT_TYPEHASH =
		keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private _ownedTokensIndex;

	// Array with all token ids, used for enumeration
	uint256[] private _allTokens;

	// Mapping from token id to position in the allTokens array
	mapping(uint256 => uint256) private _allTokensIndex;

	mapping(uint256 => Counters.Counter) private _nonces;

	/**
	 * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
	 *
	 * It's a good idea to use the same `name` that is defined as the ERC20 token name.
	 */
	constructor(string memory name, string memory symbol) ERC721(name, symbol) EIP712(name, "1") {} // solhint-disable-line no-empty-blocks

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
		require(index < ERC721.balanceOf(owner), "ERC721Base::tokenOfOwnerByIndex: owner index out of bounds");
		return _ownedTokens[owner][index];
	}

	function tokensOfOwner(address owner) public view returns (uint256[] memory) {
		uint256 tokensBalance = ERC721.balanceOf(owner);
		uint256[] memory ownedTokens = new uint256[](tokensBalance);

		if (tokensBalance > 0) {
			for (uint256 i = 0; i < tokensBalance; i++) {
				uint256 ownedToken = _ownedTokens[owner][i];
				ownedTokens[i] = ownedToken;
			}
		}

		return ownedTokens;
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
		require(index < totalSupply(), "ERC721Base::tokenByIndex: global index out of bounds");
		return _allTokens[index];
	}

	/**
	 * @notice Approve of a specific token ID for spending by spender via signature
	 * @param spender The account that is being approved
	 * @param tokenId The ID of the token that is being approved for spending
	 * @param deadline The deadline (timestamp) by which the call must be mined for the approval to succeed
	 * @param v The recovery byte of the signature
	 * @param r Half of the ECDSA signature pair
	 * @param s Half of the ECDSA signature pair
	 */
	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		require(block.timestamp <= deadline, "ERC721Base::permit: expired deadline"); // solhint-disable-line not-rely-on-time
		address owner = ownerOf(tokenId);
		require(spender != owner, "ERC721Base::permit: approval to current owner");

		bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, _useNonce(tokenId), deadline));
		bytes32 digest = _hashTypedDataV4(structHash);

		require(
			SignatureChecker.isValidSignatureNow(owner, digest, abi.encodePacked(r, s, v)),
			"ERC721Base::permit: unauthorized"
		);

		_approve(spender, tokenId);
	}

	/**
	 * @dev Returns the current nonce for `owner`. This value must be included whenever a new `permit` sig is crafted.
	 * Every successful call to {permit} increases ``owner``'s nonce by one. This prevents sig from being re-used
	 */
	function nonces(uint256 tokenId) public view virtual override returns (uint256) {
		return _nonces[tokenId].current();
	}

	function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
		return _isApprovedOrOwner(spender, tokenId);
	}

	/// @notice The domain separator used in the permit signature
	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view override returns (bytes32) {
		return _domainSeparatorV4();
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting.
	 *
	 * Calling conditions:
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
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

		if (to != from) {
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
	 * @dev Consumes a nonce: return the current value and increment it
	 */
	function _useNonce(uint256 tokenId) internal virtual returns (uint256 current) {
		Counters.Counter storage nonce = _nonces[tokenId];
		current = nonce.current();
		nonce.increment();
	}
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.9;

/// @dev Abstract class to provide for complementary "randomness"
abstract contract Randomness {
	/// @dev even weaker in rollups
	function randomize(uint256 nonce) internal view returns (uint256 seed) {
		seed = uint256(
			keccak256(
				abi.encodePacked(
					keccak256(abi.encodePacked(nonce)),
					keccak256(abi.encodePacked(block.timestamp)), // solhint-disable-line not-rely-on-time
					keccak256(abi.encodePacked(block.difficulty)),
					keccak256(abi.encodePacked(block.basefee)),
					keccak256(abi.encodePacked(block.number)),
					keccak256(abi.encodePacked(block.gaslimit)),
					keccak256(abi.encodePacked(block.coinbase)),
					keccak256(abi.encodePacked(block.chainid)),
					keccak256(abi.encodePacked(msg.sender)),
					keccak256(abi.encodePacked(gasleft()))
				)
			)
		);
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
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

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}