// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// |  \/  (_)              |  _ \          | |   | (_)
// | \  / |_  ___ _ __ ___ | |_) |_   _  __| | __| |_  ___  ___ ™
// | |\/| | |/ __| '__/ _ \|  _ <| | | |/ _` |/ _` | |/ _ \/ __|
// | |  | | | (__| | | (_) | |_) | |_| | (_| | (_| | |  __/\__ \
// |_|  |_|_|\___|_|  \___/|____/ \__,_|\__,_|\__,_|_|\___||___/ 2021

import "./interfaces/IMutations.sol";

contract Mutations is IMutations {
    uint48[20] private wBear = [
        9895705641217,
        10995250561281,
        26388480917763,
        27487992611075,
        28587672142083,
        29687200874755,
        30786712895747,
        32006550978819,
        15393246740740,
        16492775342340,
        17592354341124,
        18691882549508,
        19791411085572,
        20890922844420,
        21990451314948,
        23089963008260,
        8796160262406,
        9895688601862,
        10995234111750
    ];
    uint48[20] private yeast = [
        7696615014913,
        8796176974337,
        9895688798721,
        10995217007105,
        12094728831489,
        23089912545795,
        24189558915587,
        25289087386115,
        26487433789955,
        12094728831492,
        7696615014918,
        8796143419910,
        9895671824902,
        10995200426502,
        12120431329798
    ];
    uint48[20] private fungi = [
        7696615015169,
        8796160328449,
        9895688602369,
        10995200426753,
        12094728831745,
        13194240525057,
        23089963074307,
        24189525099267,
        25383610352387,
        12094762517252,
        13194290594564,
        14293802550020,
        15393314243332,
        16492842582788,
        17592354407172,
        7696631857926,
        8796160197382,
        9895688602374,
        10995217007366
    ];
    uint48[20] private virus = [
        6597136942081,
        7696631792641,
        8796176974849,
        9895688668161,
        23089946231811,
        24189524771843,
        25289104098307,
        26487433790467,
        12094678369284,
        13194274145284,
        14293785838596,
        15393314309124,
        16492842583044,
        17592354276356,
        18691865969668,
        6597136942086,
        7696665478150,
        8813323289606
    ];
    uint48[20] private bacteria = [
        6597136942337,
        7696665412865,
        8796177106177,
        9895688799489,
        23090080974083,
        24279786915075,
        12094745740548,
        13194274080004,
        14293802681604,
        15393330889988,
        16492842779908,
        7696648570118,
        8796160263430,
        9895671956742,
        11016658355462
    ];
    uint48[20] private amoeba = [
        6597103388161,
        7696631858689,
        8796160263681,
        9895688668673,
        23089996760579,
        24189525165571,
        25289104098819,
        26388615857667,
        27591257228803,
        14293768930820,
        15393280624132,
        16492876400132,
        17592388093444,
        6597103388166,
        7696631858694,
        8796160263686,
        9895688668678
    ];
    uint48[20] private archaea = [
        6597103388417,
        7696648636161,
        23090064000771,
        24189592078083,
        25383610353411,
        15393364838148,
        16492893308676,
        6597136942854,
        7696648636166,
        8796160329478,
        9895688668934,
        11012346611462
    ];
    uint48[20] private protist = [
        6597120231425,
        23090047027203,
        24279786915843,
        17592421255172,
        18691933341700,
        19791461877764,
        6597103388678,
        7696648701958,
        8796176975878
    ];
    uint48[20] private protozoa = [
        6597137008897,
        24189541878019,
        25289053702403,
        26487433791747,
        17592370989316,
        18691949398276,
        19791461091588,
        20890973505796,
        6597120166150,
        7696665348358,
        8817635166470
    ];
    uint48[20] private algae = [
        7696648702465,
        8796177172993,
        9895705577985,
        23089979853315,
        24189542009347,
        25289070348803,
        26388615858691,
        27591257229827,
        15393347471876,
        16492892785156,
        17592404478468,
        18691916171780,
        19791428192772,
        20946740316676,
        6597153720838,
        7696665479686,
        8796177172998,
        9917113108998,
        11016641513990,
        12116169918982
    ];

    uint256 private rWBear =
        172216058720200479622157520300678969232755245944563696642;
    uint256 private rYeast =
        147599600789009690523564688927162191429287379506355831554;
    uint256 private rFungi =
        147503445673286764548201518353432901300625957459662733825;
    uint256 private rVirus =
        122887736048128424420532989729623253781942800029118104321;
    uint256 private rBacteria =
        147599976394930746583037216758420041367404104648082326017;
    uint256 private rAmoeba =
        122983891163784623748681185902094766651162946645744943617;
    uint256 private rArchaea =
        122983517019387506447209321800185510623001828193848263426;
    uint256 private rProtist =
        122983892625353336863190147299750350219023666562816279298;
    uint256 private rProtozoa =
        122983892625308564210752079539240100429286553480862106370;
    uint256 private rAlgae =
        122983891163829402187238294473027256317680717655966024450;

    // Returns the max trait ID for a trait rarity
    function getRarity(uint8 species, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        if (species == 1) {
            return BuddyLib.sliceNumber(rWBear, 8, index * 8);
        } else if (species == 2) {
            return BuddyLib.sliceNumber(rYeast, 8, index * 8);
        } else if (species == 3) {
            return BuddyLib.sliceNumber(rFungi, 8, index * 8);
        } else if (species == 4) {
            return BuddyLib.sliceNumber(rVirus, 8, index * 8);
        } else if (species == 5) {
            return BuddyLib.sliceNumber(rBacteria, 8, index * 8);
        } else if (species == 6) {
            return BuddyLib.sliceNumber(rAmoeba, 8, index * 8);
        } else if (species == 7) {
            return BuddyLib.sliceNumber(rArchaea, 8, index * 8);
        } else if (species == 8) {
            return BuddyLib.sliceNumber(rProtist, 8, index * 8);
        } else if (species == 9) {
            return BuddyLib.sliceNumber(rProtozoa, 8, index * 8);
        } else {
            return BuddyLib.sliceNumber(rAlgae, 8, index * 8);
        }
    }

    function getMutation(
        uint8 species,
        uint8 trait,
        uint8 r1,
        uint8 r2,
        uint8 r3,
        uint8 r4,
        uint8 traitType
    ) external view override returns (uint8) {
        uint8 mutation = 255;
        uint48[20] memory mutations = getMutations(species);

        for (uint8 i = 0; i < mutations.length; i++) {
            if (mutations[i] == 0) {
                break;
            }

            uint8 mTraitType = uint8(
                BuddyLib.sliceNumber(mutations[i], 8, 0 * 8)
            );

            if (traitType + 1 == mTraitType) {
                bool dMatched = false;
                bool matched = false;
                bool matched3 = false;

                for (uint8 j = 2; j < 5; j++) {
                    uint8 mTrait = uint8(
                        BuddyLib.sliceNumber(mutations[i], 8, j * 8)
                    );

                    if (mTrait == 0) {
                        matched3 = true;
                    } else if (mTrait == trait) {
                        dMatched = true;
                    } else if (
                        mTrait == r1 ||
                        mTrait == r2 ||
                        mTrait == r3 ||
                        mTrait == r4
                    ) {
                        // Dominant trait must be the rarest of the mutation
                        if (mTrait > trait) {
                            break;
                        } else if (matched) {
                            matched3 = true;
                        } else {
                            matched = true;
                        }
                    }
                }

                if (dMatched && matched && matched3) {
                    return uint8(BuddyLib.sliceNumber(mutations[i], 8, 5 * 8));
                }
            } else if (traitType + 1 < mTraitType) {
                break;
            }
        }

        return mutation;
    }

    function getMutations(uint8 species)
        private
        view
        returns (uint48[20] memory mutations)
    {
        if (species == 1) {
            mutations = wBear;
        } else if (species == 2) {
            mutations = yeast;
        } else if (species == 3) {
            mutations = fungi;
        } else if (species == 4) {
            mutations = virus;
        } else if (species == 5) {
            mutations = bacteria;
        } else if (species == 6) {
            mutations = amoeba;
        } else if (species == 7) {
            mutations = archaea;
        } else if (species == 8) {
            mutations = protist;
        } else if (species == 9) {
            mutations = protozoa;
        } else {
            mutations = algae;
        }

        return mutations;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/BuddyLib.sol";

interface IMutations {
    function getMutation(
        uint8 species,
        uint8 trait,
        uint8 r1,
        uint8 r2,
        uint8 r3,
        uint8 r4,
        uint8 traitType
    ) external view returns (uint8);

    function getRarity(uint8 species, uint256 index)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// |  \/  (_)              |  _ \          | |   | (_)
// | \  / |_  ___ _ __ ___ | |_) |_   _  __| | __| |_  ___  ___ ™
// | |\/| | |/ __| '__/ _ \|  _ <| | | |/ _` |/ _` | |/ _ \/ __|
// | |  | | | (__| | | (_) | |_) | |_| | (_| | (_| | |  __/\__ \
// |_|  |_|_|\___|_|  \___/|____/ \__,_|\__,_|\__,_|_|\___||___/ 2021

library BuddyLib {
    //Special - 0 = None - 1 = Blackhole - 2 = Founder
    struct Buddy {
        uint8 species;
        uint8[30] traits;
        uint8 gen;
        uint8 repMax;
        uint8 repCur;
        uint8 special;
        uint256 dna;
        uint256 birth;
        uint256 totalProduced;
        uint256 lastRewardTime;
        uint256 parent;
    }

    function generate(uint256 dna) external view returns (Buddy memory base) {
        uint8[] memory unpack = decode(dna);
        base.species = unpack[0];

        for (uint8 i = 1; i < 31; i++) {
            base.traits[i - 1] = unpack[i];
        }

        base.birth = block.timestamp;
        base.totalProduced = 0;
        base.lastRewardTime = block.timestamp;
        base.dna = dna;
        base.gen = unpack[31];
        base.repMax = 5;
        base.repCur = 0;

        return base;
    }

    function decode(uint256 dna) public pure returns (uint8[] memory) {
        uint8[] memory traits = new uint8[](32);
        uint256 i;
        for (i = 0; i < 32; i++) {
            traits[i] = uint8(sliceNumber(dna, 8, i * 8));
        }
        return traits;
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function sliceNumber(
        uint256 _n,
        uint256 _nbits,
        uint256 _offset
    ) public pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = (pow(2, _nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    function pow(uint256 A, uint256 B) public pure returns (uint256) {
        return A**B;
    }

    function encode(uint8[] memory traits) external pure returns (uint256 dna) {
        dna = 0;
        for (uint256 i = 0; i < 32; i++) {
            dna = dna << 8;
            // bitwise OR trait with _genes
            dna = dna | traits[31 - i];
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 800
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
  "libraries": {
    "contracts/libraries/BuddyLib.sol": {
      "BuddyLib": "0x0ee5ae5470ba9c15457222f93c3feb1d70d07246"
    }
  }
}