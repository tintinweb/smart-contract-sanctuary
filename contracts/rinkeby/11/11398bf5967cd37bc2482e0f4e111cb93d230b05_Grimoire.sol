//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./strings.sol";

contract Grimoire {
    using strings for string;
    using strings for strings.slice;

    string private constant traitNames =
        "Black-Blue-Green-Red-Card Magician-Desert Wear-Shoulder Cape Green-Shoulder Cape Red-Banded Overall-Brown Tunic-Grey Tunic-White Tunic-Blue Big Buckle-Green Big Buckle-Blue Lined Coveralls-Green Lined Coveralls-Space Chroma-Cape in the Wind-Green Caped Traveller-Orange Caped Traveller-Purple Caped Traveller-Spandex  Green-Spandex  Dark-Overcoat-Tech Coat-Deeze Body-Jester Diamonds-Double Sash-Blue Elven Cloak-Green Elven Cloak-Yellow Elven Cloak-Purple Yoga-Purple Yoga-Red Yoga-Rose Yoga-Blue Hip Pouch-Green Hip Pouch-Red Hip Pouch-Green Cloak-Purple Cloak-Formal Suit-Blue Coveralls-Brown Coveralls-Green Coveralls-Red Coveralls-White Coveralls-SupaFly-Gfunk-Gold Chain-Green Hip Scarf-Orange Hip Scarf-Cheetah Print-Ice Robe-Loopify-Red Cleric-Yellow Cleric-Pink Cosmic-Swashbuckling Gear-Poncho-Brown Harem Pants-Orange Harem Pants-Purple Harem Pants-Green Scholar-Orange Scholar-Rainbow Suit-Red Suit-All Seeing Robe-Green Mantle Robe-Purple Mantle Robe-Punker-Skeleton Flame-Gold Skeleton-Silver Skeleton-Tundra Wear-Dapper Formal-Cosmic Cardigan-Aristocrat Blue-Aristocrat Green-Aristocrat Purple-Two Tone Fringe-Skipper-Vest Blue-Vest Green-Celestial Sash-Wicker Wear-Black Wraith-White Wraith-Robe of Shadow-Forever Bat-Dirt Rabbit-Psychic Rabbit-Pink Butterfly-Bengal Cat-Lucky Black Cat-Sun Cat-Bliss Cat-Mesozoic Cockatrice-Crackerjack Crow-Pink Footed Crow-Field Dog-White Dog-Fox Trickster-3D Frog-Golden Toad-Swamp Bullfrog-Ember Frog-Jewled Hummingbird-Giant Ladybug-Merlin's Monkey-Great Owl-Blue Rat-Plague Rat-Albino Rat-Skramps-Sapphire Slime-Emerald Slime-Topaz Slime-Astral Snail-Golden Viper-Green Asp-Red Mamba-Ancient Sphinx-Rain Toucan-Onyx Wolf-Aura Wolf-Ascetic-Kabuki-Thelemist-Djinn-Kelt-ArtChick-Huntress-Floral Master-Woodland Shapeshifter-Bernardo-Enchantress-Evil One-BrainDrain-Skylord-Dark Sister-Felis-Cloud Prophet-Stranger-Claire Silver-Corvid-Great Old One-Black Mage-Arcadian Master-Deeze-Houngan-Dapper Arcanist-Bippadotta-Vampyre-Professor-Vegetable-Witch-Empress-Big Gross Eyeball-Flaming Skull-Swamp Witch-Eastern Arcanist-9272ETH-Cosmic Arcanist-GFunk Head-Dream Master-Gruffling-Hag-Hunter-Fiskantes-Hue Master-Illuminatus-Imp-Pumpkin Head-Wildman-Labyrinthian-Joey Billboard-Crone-Strongman-Koopling-Creol-Kempo-Loopify-Lycanthrope-MachoMan-Marlo-Warlock-Seer-Mambo-Olympian-Faustian-Coven Sister-Red Priestess-Myrddin-Canaanite-Death Eater-Fungus-Philosopher-Fortune Seeker-Botanic Master-Man Behind the Curtain-Anuran-Wooden Boy-Sandman-Durm and Strang-Swashbuckler-Rogue Arcanist-Animist-Bard-Charmer-Wild Woman-LeggoGreggo-Hermit-Astrologer-Medicine Man-Prophet-Scholar-WereBeast-Mandinka-Master of Wood, Water, and Hill-Punjabi-Polar Shapeshifter-Diviner-Dark Arcanist-Vamp-Darkling-Weird Wizz-Wicked Wizard-Blue Wizard-Brown Wizard-Green Wizard-Purple Wizard-Red Wizard-White Wizard-Yellow Wizard-Wolfkin-Kobold-Shaolin-Trickster-Astral Arcanist-Gold Skeleton-Cyborg Skeleton Arcanist-Cyborg Skeleton Rogue-Silver Skeleton-Tengu Preist-Fur Gnome-Mug of Ale-Isaac's Apple-Siren's Bell-Vile of Virgin's Blood-Book of Magic-Candle of Intuition-Ace in the Hole-Crystal Ball-Egg of Unknown Beast-Gorgon's Eye-Dragon Fireworks-Goblet of Immortality-Siren's Harp-Lucky Horseshoe-Sphinx's Hourglass-Key of the 7th Realm-Bag of Tricks-Green Mushroom-Red Mushroom-Shaman's Peyote-Phoenix Feather-Wizard's Pipe-Astral Potion-Cannabis Potion-Mandrake Potion-Nightshade Potion-Passion Potion-Chroma Crystal-Eternal Rose-Crystal Skull-Mystic Ice Cream-A dumb stick...-Prometheus's Torch-Venus Fly Trap-Flesh Eating Plant-The Midas Rod-The World Egg-Rune of Air-Rune of Brass-Rune of Brimstone-Rune of Cinnabar-Rune of Down-Rune of Earth-Rune of Fire-Rune of Infinity-Rune of Jupiter-Rune of Lime-Rune of Mars-Rune of Mercury-Rune of Neptune-Rune of Omega-Rune of Pluto-Rune of Saturn-Rune of Sigma-Rune of Steel-Rune of Sun-Rune of Up Only-Rune of Uranus-Rune of Venus-Rune of Water-Thor's Wrath: the Lightning Spell-Fairy Glamour: the Dazzle Spell-Grim Reaper's Breath: the Death Spell-The Gnome's Tooth: the Earth Spell-Salamander's Tongue: the Fire Spell-Hobgoblin's Flame: the Wayward Spell-Aphrodite's Heart: the Love Spell-Dryad's Ear: the Plant Spell-Loki's Bridge: the Rainbow Spell-Kelpie's Fury: the Water Spell-Zephyr's Laugh: the Wind Spell-Ruby Staff-Emerald Staff-The Orb Staff-A Big Magic Stick-The Bone Stave-Guillaume's Broom-Caduceus-Harmony Staff-Staff-Jinx Staff-Courage Staff-Peace Staff-Joy Staff-Ether Staff-Phosphorus Spear-Golden Bull Staff-Lunar Staff-Indigo Moon Staff-Chaos Staff-Soul Harvester-Golden Soul Reaper-The Mamba Stick-Stellar Staff-Solar Staff-Garnet Staff";

    string private constant affinityNames =
        "Academic-Ascetic-Kumadori-Air-Drunk-Thelema-Desert-Djinn-Khelt-Apple-Arm Sash-Artgirl-Huntress-Astral-Magic Bag-Banded Overall-Bat-Bell-Floral Master-Woodland Shapeshifter-Bernardo-Enchantress-Blackness-Evil One-Blood-Blue Shift-Electrification-Bone-Book-Boots-BrainDrain-Brass-Brimstone-Broom-Brownish-Brownish Red-Buckle-Butterfly-Caduceus-Skylord-Candle-Cape-Cardistry-Dark Sister-Cat-Cat-Cloud Prophet-Chemistry-Stranger-Cinnabar-Urban-Claire-Coat-Cockatrice-Cold-Corvid-Cosmic-Crook-Crow-Ctulu-Cyan-Darkness-Black Mage-Arcadian Master-Dazzling-Death-Deeze-Desert-Dog-DooVoo-Dapper Arcanist-Dotta-Down-Vampyre-Drape-Professor-Earth-Earth-Egg-Vegetable-Witch-Electrification-Elven-Empress-Ether-Eyeball-Eyeball-Feather-Feminine-Fire-Firework-Flame-Swamp Witch-Food-Forest-Formal-Fox-Frog-Eastern Arcanist-Urban-Gender Neutral-Cosmic Arcanist-GFunk-Goblet-Dream Master-Gold-Goofy-Verdant-Grey-Gruffling-Hag-Harp-Stag-Cardistry-Horseshoe-Hourglass-Hue-Hummingbird-Hunter-Icecream-Illuminatus-Imp-Infinity-Pumpkin-Wildman-Labyrinthian-Jester-JB-Jungle-Crone-Jupiter-Strongman-Key-Koopling-Ladybug-Creol-Greggo-Light-Lime-Kempo-Loopify-Love-Lucky-Lycanthrope-MachoMan-Masculine-Alien-Warlock-Mars-Seer-Mambo-Olympian-Faustian-Coven Sister-Red Preistess-Mercury-Myrddin-Middle Sash-Canaanite-Monk-Monkey-Moon-Mountains-Death Man-Mushroom-Music-Nature-Nature-Neptune-Philosopher-Ocean-Olive-Omega-Oracle-Orange-Orb-Owl-Fortune Seeker-Botanic Master-Man Behind the Curtain-Peyote-Anuran-Pink-Alien-Wooden Boy-Pipe-Pirate-Flora-Pluto-Poison-Poncho-Potion-Prism-Prophecy-Prophecy-Sandman-Purple Haze-Lagomorph-Rainbow-Rodent-Durm and Strang-Crimson-Red Suit-Robe-Swashbuckler-Rogue Arcanist-Animist-Bard-Rose-Rugged-Rune-Saturn-Charmer-Academic-Scythe-Sea-Shaman-Wild Woman-Sigma-Quick Silver-Skeleton-Tone Dark-Tone Green-Tone Light-Skramps-Skull-Slime-Snail-Snake-Hermit-Astrologer-Sparkles-Spell-Sphinx-Staff-Star-Steel-Stick-Medicine Man-Suit-Suit-Sun-Prophet-Swamp-Scholar-Tengu Preist-Were Beast-Time-Mandinka-Master of Wood, Water, and Hill-Torch-Toucan-Punjabi-Tundra-Polar Shapeshifter-Tunic-Unihorn-Unique-Up-Uranus-Urban-Diviner-Fur Gnome-Dark Arcanist-Venus Flytrap-Vamp-Void-Darkling-Voodoo-Wand-Warm-Water Magic-White Magic-Wicker-Wind-Wizzle-Wizzy-Lupus-Lupus-Kobold-World Egg-Wraith-Amber-Shaolin-Trickster-Astral Arcanist";

    uint16[] private affinityOccurrences = [
        372,
        119,
        122,
        313,
        198,
        118,
        484,
        98,
        124,
        194,
        343,
        25,
        163,
        648,
        196,
        130,
        359,
        164,
        158,
        101,
        1,
        122,
        3541,
        24,
        1291,
        5414,
        178,
        202,
        190,
        371,
        26,
        308,
        314,
        299,
        5291,
        124,
        366,
        15,
        191,
        80,
        197,
        613,
        113,
        121,
        1201,
        9,
        88,
        1409,
        100,
        309,
        4718,
        1,
        129,
        87,
        946,
        103,
        6748,
        949,
        355,
        25,
        756,
        5209,
        9,
        128,
        197,
        712,
        1,
        2361,
        226,
        90,
        74,
        1,
        119,
        8,
        180,
        122,
        504,
        365,
        198,
        24,
        121,
        270,
        493,
        102,
        118,
        379,
        9,
        198,
        2534,
        1453,
        173,
        89,
        121,
        902,
        4977,
        3884,
        227,
        1276,
        122,
        48,
        1242,
        121,
        2,
        189,
        119,
        1961,
        2136,
        5891,
        153,
        125,
        124,
        34,
        88,
        1,
        200,
        118,
        25,
        93,
        1,
        35,
        26,
        122,
        33,
        25,
        121,
        75,
        160,
        1,
        1568,
        123,
        311,
        125,
        155,
        79,
        227,
        75,
        1,
        159,
        313,
        124,
        1,
        623,
        200,
        85,
        74,
        6261,
        1,
        124,
        309,
        122,
        122,
        103,
        123,
        98,
        165,
        312,
        120,
        366,
        90,
        1179,
        224,
        189,
        2603,
        94,
        453,
        488,
        354,
        4457,
        309,
        9,
        1490,
        501,
        119,
        290,
        4644,
        160,
        229,
        88,
        124,
        72,
        112,
        126,
        15,
        1,
        126,
        112,
        1273,
        922,
        313,
        192,
        134,
        796,
        9,
        8,
        597,
        99,
        4901,
        594,
        1540,
        1182,
        108,
        6715,
        152,
        232,
        124,
        88,
        100,
        126,
        159,
        7129,
        6122,
        304,
        125,
        6723,
        123,
        1502,
        112,
        123,
        121,
        74,
        16,
        193,
        36,
        653,
        18,
        579,
        1031,
        91,
        764,
        122,
        121,
        197,
        1719,
        8,
        2597,
        160,
        312,
        190,
        120,
        364,
        50,
        763,
        129,
        2917,
        92,
        89,
        85,
        236,
        122,
        122,
        189,
        9,
        121,
        133,
        123,
        472,
        9,
        9,
        118,
        317,
        48,
        76,
        9,
        101,
        318,
        122,
        51,
        9,
        307,
        139,
        472,
        611,
        3607,
        130,
        192,
        108,
        704,
        381,
        9,
        100,
        8,
        3883,
        5036,
        122,
        99,
        119
    ];
    mapping(uint256 => bool) public hasTraitsStored;

    bool private canStoreAffinities = true;
    bytes32 public merkleRootTraitsTree;
    bytes32 public merkleRootNamesTree;
    mapping(uint256 => bytes) private wizardToTraits;
    mapping(uint256 => string) private wizardToName;
    mapping(uint16 => uint16[]) private traitsToAffinities;
    mapping(uint16 => uint16[]) private traitsToIdentity;
    mapping(uint16 => uint16[]) private traitsToPositive;
    //mapping(uint16 => uint16) private affinityOccurrences;

    event StoredTrait(uint256 wizardId, string name, bytes encodedTraits);

    constructor(bytes32 _rootTraits, bytes32 _rootNames) {
        merkleRootTraitsTree = _rootTraits;
        merkleRootNamesTree = _rootNames;
    }

    // Store traits for a list of Wizards
    function storeWizardTraits(
        uint256 wizardId,
        string calldata name,
        uint16[] calldata traits,
        bytes32[] calldata proofsName,
        bytes32[] calldata proofsTraits
    ) public {
        require(traits.length == 7, "Invalid Length");
        require(traits[0] == wizardId, "WizardsId to Trait mismatch");
        require(!hasTraitsStored[wizardId], "Traits are already stored");

        require(
            _verifyName(proofsName, wizardId, name),
            "Merkle Proof for name is invalid!"
        );

        bytes memory encodedTraits = _encode(
            traits[0],
            traits[1],
            traits[2],
            traits[3],
            traits[4],
            traits[5],
            traits[6]
        );
        require(
            _verifyEncodedTraits(proofsTraits, encodedTraits),
            "Merkle Proof for traits is invalid!"
        );

        wizardToName[wizardId] = name;
        wizardToTraits[wizardId] = encodedTraits;
        hasTraitsStored[wizardId] = true;

        emit StoredTrait(wizardId, name, encodedTraits);
    }

    // Store related affinities for a list of traits
    function storeTraitAffinities(
        uint16[] calldata traits,
        uint16[][] calldata affinities,
        uint16[][] calldata identity,
        uint16[][] calldata positive
    ) public {
        require(canStoreAffinities, "Storing is over");
        for (uint256 i = 0; i < traits.length; i++) {
            traitsToAffinities[traits[i]] = affinities[i];
            traitsToIdentity[traits[i]] = identity[i];
            traitsToPositive[traits[i]] = positive[i];
        }
    }

    function stopStoring() public {
        require(canStoreAffinities, "Store is already over");
        canStoreAffinities = false;
    }

    /**
        VIEWS
     */

    function getWizardTraits(uint256 wizardId)
        public
        view
        returns (
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        )
    {
        //ignore id
        (, t0, t1, t2, t3, t4, t5) = _decode(wizardToTraits[wizardId]);
    }

    function getTraitAffinities(uint16 traitId)
        public
        view
        returns (uint16[] memory)
    {
        return traitsToAffinities[traitId];
    }

    function getAllTraitsAffinities(uint16[5] memory traitId)
        public
        view
        returns (uint16[] memory)
    {
        uint16[] storage affinityT1 = traitsToAffinities[traitId[0]];
        uint16[] storage affinityT2 = traitsToAffinities[traitId[1]];
        uint16[] storage affinityT3 = traitsToAffinities[traitId[2]];
        uint16[] storage affinityT4 = traitsToAffinities[traitId[3]];
        uint16[] storage affinityT5 = traitsToAffinities[traitId[4]];

        uint16[] memory affinitiesList = new uint16[](
            affinityT1.length +
                affinityT2.length +
                affinityT3.length +
                affinityT4.length +
                affinityT5.length
        );

        uint256 lastIndexWritten = 0;

        // 7777 is used as a filler for empty Trait slots
        if (traitId[0] != 7777) {
            for (uint256 i = 0; i < affinityT1.length; i++) {
                affinitiesList[i] = affinityT1[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT1.length;
        }

        if (traitId[1] != 7777) {
            for (uint256 i = 0; i < affinityT2.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT2[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT2.length;
        }

        if (traitId[2] != 7777) {
            for (uint8 i = 0; i < affinityT3.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT3[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT3.length;
        }

        if (traitId[3] != 7777) {
            for (uint8 i = 0; i < affinityT4.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT4[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT4.length;
        }

        if (traitId[4] != 7777) {
            for (uint8 i = 0; i < affinityT5.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT5[i];
            }
        }

        return affinitiesList;
    }

    function getTraitIdentityAffinities(uint16 traitId)
        public
        view
        returns (uint16[] memory)
    {
        return traitsToIdentity[traitId];
    }

    function getTraitPositiveAffinities(uint16 traitId)
        public
        view
        returns (uint16[] memory)
    {
        return traitsToPositive[traitId];
    }

    function getAffinityOccurrences(uint16 id) public view returns (uint16) {
        return affinityOccurrences[id];
    }

    function getWizardName(uint256 wizardId)
        public
        view
        returns (string memory)
    {
        return wizardToName[wizardId];
    }

    function wizardAffintyCount(uint256 wizardId, uint16 affinity)
        public
        view
        returns (uint256 affinityCount)
    {
        uint16[] memory wizAffinities = getWizardAffinities(wizardId);
        // count how many times selected wizard has affinity
        affinityCount = 0;
        for (uint8 i = 0; i < wizAffinities.length; i++) {
            if (wizAffinities[i] == affinity) {
                affinityCount += 1;
            }
        }
    }

    function wizardIdentityAffintyCount(uint256 wizardId, uint16 affinity)
        public
        view
        returns (uint256 affinityCount)
    {
        uint16[] memory wizAffinities = getWizardIdentityAffinities(wizardId);
        // count how many times selected wizard has affinity
        affinityCount = 0;
        for (uint8 i = 0; i < wizAffinities.length; i++) {
            if (wizAffinities[i] == affinity) {
                affinityCount += 1;
            }
        }
    }

    function wizardPositiveAffintyCount(uint256 wizardId, uint16 affinity)
        public
        view
        returns (uint256 affinityCount)
    {
        uint16[] memory wizAffinities = getWizardPositiveAffinities(wizardId);
        // count how many times selected wizard has affinity
        affinityCount = 0;
        for (uint8 i = 0; i < wizAffinities.length; i++) {
            if (wizAffinities[i] == affinity) {
                affinityCount += 1;
            }
        }
    }

    function wizardHasTrait(uint256 wizardId, uint16 trait)
        public
        view
        returns (bool)
    {
        (
            ,
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        ) = _decode(wizardToTraits[wizardId]);
        uint16[6] memory wizTraits = [t0, t1, t2, t3, t4, t5];

        for (uint8 i = 0; i < wizTraits.length; i++) {
            if (wizTraits[i] == trait) {
                return true;
            }
        }
        return false;
    }

    function getWizardAffinities(uint256 wizardId)
        public
        view
        returns (uint16[] memory)
    {
        // ignore id and t0 (background has no affinity)
        (, , uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) = _decode(
            wizardToTraits[wizardId]
        );

        return getAllTraitsAffinities([t1, t2, t3, t4, t5]);
    }

    function getWizardIdentityAffinities(uint256 wizardId)
        public
        view
        returns (uint16[] memory)
    {
        // ignore id and t0 (background has no affinity)
        (, , uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) = _decode(
            wizardToTraits[wizardId]
        );

        uint16[] storage affinityT1 = traitsToIdentity[t1];
        uint16[] storage affinityT2 = traitsToIdentity[t2];
        uint16[] storage affinityT3 = traitsToIdentity[t3];
        uint16[] storage affinityT4 = traitsToIdentity[t4];
        uint16[] storage affinityT5 = traitsToIdentity[t5];

        uint16[] memory affinitiesList = new uint16[](
            affinityT1.length +
                affinityT2.length +
                affinityT3.length +
                affinityT4.length +
                affinityT5.length
        );

        uint256 lastIndexWritten = 0;

        // 7777 is used as a filler for empty Trait slots
        if (t1 != 7777) {
            for (uint256 i = 0; i < affinityT1.length; i++) {
                affinitiesList[i] = affinityT1[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT1.length;
        }

        if (t2 != 7777) {
            for (uint256 i = 0; i < affinityT2.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT2[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT2.length;
        }

        if (t3 != 7777) {
            for (uint8 i = 0; i < affinityT3.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT3[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT3.length;
        }

        if (t4 != 7777) {
            for (uint8 i = 0; i < affinityT4.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT4[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT4.length;
        }

        if (t5 != 7777) {
            for (uint8 i = 0; i < affinityT5.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT5[i];
            }
        }

        return affinitiesList;
    }

    function getWizardPositiveAffinities(uint256 wizardId)
        public
        view
        returns (uint16[] memory)
    {
        // ignore id and t0 (background has no affinity)
        (, , uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) = _decode(
            wizardToTraits[wizardId]
        );

        uint16[] storage affinityT1 = traitsToPositive[t1];
        uint16[] storage affinityT2 = traitsToPositive[t2];
        uint16[] storage affinityT3 = traitsToPositive[t3];
        uint16[] storage affinityT4 = traitsToPositive[t4];
        uint16[] storage affinityT5 = traitsToPositive[t5];

        uint16[] memory affinitiesList = new uint16[](
            affinityT1.length +
                affinityT2.length +
                affinityT3.length +
                affinityT4.length +
                affinityT5.length
        );

        uint256 lastIndexWritten = 0;

        // 7777 is used as a filler for empty Trait slots
        if (t1 != 7777) {
            for (uint256 i = 0; i < affinityT1.length; i++) {
                affinitiesList[i] = affinityT1[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT1.length;
        }

        if (t2 != 7777) {
            for (uint256 i = 0; i < affinityT2.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT2[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT2.length;
        }

        if (t3 != 7777) {
            for (uint8 i = 0; i < affinityT3.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT3[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT3.length;
        }

        if (t4 != 7777) {
            for (uint8 i = 0; i < affinityT4.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT4[i];
            }
            lastIndexWritten = lastIndexWritten + affinityT4.length;
        }

        if (t5 != 7777) {
            for (uint8 i = 0; i < affinityT5.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT5[i];
            }
        }

        return affinitiesList;
    }

    function getTraitName(uint256 index) public pure returns (string memory) {
        strings.slice memory strSlice = traitNames.toSlice();
        string memory separatorStr = "-";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function getAffinityName(uint256 index)
        public
        pure
        returns (string memory)
    {
        strings.slice memory strSlice = affinityNames.toSlice();
        string memory separatorStr = "-";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function getWizardTraitsEncoded(uint256 id)
        public
        view
        returns (bytes memory)
    {
        return wizardToTraits[id];
    }

    /**
        INTERNAL
     */

    function _verifyName(
        bytes32[] memory proof,
        uint256 wizardId,
        string memory name
    ) internal view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                merkleRootNamesTree,
                keccak256(abi.encode(wizardId, name))
            );
    }

    function _verifyEncodedTraits(bytes32[] memory proof, bytes memory traits)
        internal
        view
        returns (bool)
    {
        bytes32 hashedTraits = keccak256(abi.encodePacked(traits));
        return MerkleProof.verify(proof, merkleRootTraitsTree, hashedTraits);
    }

    function _encode(
        uint16 id,
        uint16 t0,
        uint16 t1,
        uint16 t2,
        uint16 t3,
        uint16 t4,
        uint16 t5
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(16);

        assembly {
            mstore(add(data, 32), 32)

            mstore(add(data, 34), shl(240, id))
            mstore(add(data, 36), shl(240, t0))
            mstore(add(data, 38), shl(240, t1))
            mstore(add(data, 40), shl(240, t2))
            mstore(add(data, 42), shl(240, t3))
            mstore(add(data, 44), shl(240, t4))
            mstore(add(data, 46), shl(240, t5))
        }

        return data;
    }

    function _decode(bytes memory data)
        internal
        pure
        returns (
            uint16 id,
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        )
    {
        assembly {
            let len := mload(add(data, 0))

            id := mload(add(data, 4))
            t0 := mload(add(data, 6))
            t1 := mload(add(data, 8))
            t2 := mload(add(data, 10))
            t3 := mload(add(data, 12))
            t4 := mload(add(data, 14))
            t5 := mload(add(data, 16))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

//SPDX-License-Identifier: UNLICENSED
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }
}

