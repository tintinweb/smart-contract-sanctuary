// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// |  \/  (_)              |  _ \          | |   | (_)
// | \  / |_  ___ _ __ ___ | |_) |_   _  __| | __| |_  ___  ___ ™
// | |\/| | |/ __| '__/ _ \|  _ <| | | |/ _` |/ _` | |/ _ \/ __|
// | |  | | | (__| | | (_) | |_) | |_| | (_| | (_| | |  __/\__ \
// |_|  |_|_|\___|_|  \___/|____/ \__,_|\__,_|\__,_|_|\___||___/ 2021
import "./interfaces/IBuddyLogic.sol";
import "./interfaces/ISynthesizer.sol";
import "./interfaces/IMutations.sol";
import "./interfaces/IBuddyRandomness.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Synthesizer is ISynthesizer, Ownable {
    IBuddyLogic public _buddyLogic;
    IBuddyRandomness _buddyRandomness;
    IMutations public _mutations;

    uint32 public _ALGAE_COUNT = 400;
    uint32 public _PROTOZOA_COUNT = _ALGAE_COUNT + 325;
    uint32 public _PROTIST_COUNT = _PROTOZOA_COUNT + 325;
    uint32 public _ARCHAEA_COUNT = _PROTIST_COUNT + 205;

    uint32 public _AMOEBA_COUNT = _ARCHAEA_COUNT + 300;
    uint32 public _BACTERIA_COUNT = _AMOEBA_COUNT + 250;
    uint16 public _VIRUS_COUNT = uint16(_BACTERIA_COUNT) + 205;

    uint16 public _FUNGI_COUNT = _VIRUS_COUNT + 250;
    uint16 public _YEAST_COUNT = _FUNGI_COUNT + 200;

    uint16 public _WATERBEAR_COUNT = _YEAST_COUNT + 30;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 private randomResult;
    uint256 private _nonce;

    constructor(address _buddyRandomnessAddr, address _mutationsAddr) {
        _buddyRandomness = IBuddyRandomness(_buddyRandomnessAddr);
        _mutations = IMutations(_mutationsAddr);
    }

    function setBuddyLogicContract(address buddyLogicContractAddr)
        public
        onlyOwner
    {
        _buddyLogic = IBuddyLogic(buddyLogicContractAddr);
    }

    function setRandomnessContract(address _randomnessContractAddr)
        external
        onlyOwner
    {
        _buddyRandomness = IBuddyRandomness(_randomnessContractAddr);
    }

    function setMutationsContract(address _mutationsContractAddr)
        external
        override
        onlyBuddyLogic
    {
        _mutations = IMutations(_mutationsContractAddr);
    }

    modifier onlyBuddyLogic() {
        require(msg.sender == address(_buddyLogic), "Unauthorized");
        _;
    }

    function grabRandomBuddy(uint256 tokenId)
        external
        onlyBuddyLogic
        returns (uint256)
    {
        uint256 dna = buildDNA(tokenId, getSpecies(tokenId));
        return dna;
    }

    function getSpecies(uint256 tokenId) private returns (uint8 species) {
        require(_WATERBEAR_COUNT > 0, "All Gen 0s have been claimed!");
        uint256 r = _buddyRandomness.rng(tokenId, _WATERBEAR_COUNT);

        if (r <= _ALGAE_COUNT) {
            _ALGAE_COUNT -= 1;
            _PROTOZOA_COUNT -= 1;
            _PROTIST_COUNT -= 1;
            _ARCHAEA_COUNT -= 1;
            _AMOEBA_COUNT -= 1;
            _BACTERIA_COUNT -= 1;
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 10;
        } else if (r <= _PROTOZOA_COUNT) {
            _PROTOZOA_COUNT -= 1;
            _PROTIST_COUNT -= 1;
            _ARCHAEA_COUNT -= 1;
            _AMOEBA_COUNT -= 1;
            _BACTERIA_COUNT -= 1;
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 9;
        } else if (r <= _PROTIST_COUNT) {
            _PROTIST_COUNT -= 1;
            _ARCHAEA_COUNT -= 1;
            _AMOEBA_COUNT -= 1;
            _BACTERIA_COUNT -= 1;
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 8;
        } else if (r <= _ARCHAEA_COUNT) {
            _ARCHAEA_COUNT -= 1;
            _AMOEBA_COUNT -= 1;
            _BACTERIA_COUNT -= 1;
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 7;
        } else if (r <= _AMOEBA_COUNT) {
            _AMOEBA_COUNT -= 1;
            _BACTERIA_COUNT -= 1;
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 6;
        } else if (r <= _BACTERIA_COUNT) {
            _BACTERIA_COUNT -= 1;
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 5;
        } else if (r <= _VIRUS_COUNT) {
            _VIRUS_COUNT -= 1;
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 4;
        } else if (r <= _FUNGI_COUNT) {
            _FUNGI_COUNT -= 1;
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 3;
        } else if (r <= _YEAST_COUNT) {
            _YEAST_COUNT -= 1;
            _WATERBEAR_COUNT -= 1;
            return 2;
        } else if (r <= _WATERBEAR_COUNT) {
            _WATERBEAR_COUNT -= 1;
            return 1;
        }
    }

    function buildDNA(uint256 tokenId, uint8 species)
        private
        returns (uint256)
    {
        uint8[] memory traits = new uint8[](32);
        traits[0] = species;

        // Top (dominant, recessive, recessive, recessive, recessive, recessive)
        // We don't want 5 to be possible in rtop because that is the rare+
        bool common = false;
        uint256 rTop = _buddyRandomness.rng(tokenId, 4);
        for (uint256 i = 1; i < 6; i++) {
            uint256 rand = 0;

            if (i != rTop) {
                if (species > 3 && i > 1 && !common) {
                    rand = 255;
                    common = true;
                } else {
                    rand = raribleRandom(tokenId, calcTraitType(0), i, species);
                }
            }

            traits[i] = uint8(rand);
        }
        // Mouth (dominant, recessive, recessive, recessive, recessive, recessive)
        common = false;
        for (uint256 i = 6; i < 11; i++) {
            uint256 rand = 0;

            if (species > 3 && i > 6 && !common) {
                rand = 255;
                common = true;
            } else {
                rand = raribleRandom(tokenId, calcTraitType(1), i, species);
            }

            traits[i] = uint8(rand);
        }
        // Eyes (dominant, recessive, recessive, recessive, recessive, recessive)
        common = false;
        for (uint256 i = 11; i < 16; i++) {
            uint256 rand = 0;

            if (species > 3 && i > 11 && !common) {
                rand = 255;
                common = true;
            } else {
                rand = raribleRandom(tokenId, calcTraitType(2), i, species);
            }

            traits[i] = uint8(rand);
        }
        // Body Patterns (dominant, recessive, recessive, recessive, recessive,
        // recessive)
        common = false;
        uint256 rBP = _buddyRandomness.rng(tokenId, 4);
        for (uint256 i = 16; i < 21; i++) {
            uint256 rand = 0;

            if (i - 15 != rBP) {
                if (species > 3 && i > 16 && !common) {
                    rand = 255;
                    common = true;
                } else {
                    rand = raribleRandom(tokenId, calcTraitType(3), i, species);
                }
            }

            traits[i] = uint8(rand);
        }
        // Body Color (dominant, recessive, recessive, recessive, recessive, recessive)
        common = false;
        for (uint256 i = 21; i < 26; i++) {
            uint256 rand = 0;

            if (species > 3 && i > 21 && !common) {
                rand = 255;
                common = true;
            } else {
                rand = raribleRandom(tokenId, calcTraitType(4), i, species);
            }

            traits[i] = uint8(rand);
        }
        // Bottoms (dominant, recessive, recessive, recessive, recessive, recessive)
        common = false;
        uint256 rB = _buddyRandomness.rng(tokenId, 4);
        for (uint256 i = 26; i < 31; i++) {
            uint256 rand = 0;

            if (i - 25 != rB) {
                if (species > 3 && i > 26 && !common) {
                    rand = 255;
                    common = true;
                } else {
                    rand = raribleRandom(tokenId, calcTraitType(5), i, species);
                }
            }

            traits[i] = uint8(rand);
        }

        traits[31] = 0;

        return BuddyLib.encode(traits);
    }

    function calcTraitType(uint8 offset)
        private
        pure
        returns (uint8 traitType)
    {
        if (offset == 0) {
            traitType = 3;
        } else if (offset == 1) {
            traitType = 7;
        } else if (offset == 2) {
            traitType = 11;
        } else if (offset == 3) {
            traitType = 15;
        } else if (offset == 4) {
            traitType = 19;
        } else {
            traitType = 23;
        }
    }

    function raribleRandom(
        uint256 tokenId,
        uint256 traitType,
        uint256 i,
        uint8 species
    ) private returns (uint256) {
        uint256 min = 1;
        uint256 max = 1;
        uint256 rarity;

        // Guarantees one trait is rare or better
        if (i % 5 == 0) {
            rarity = _buddyRandomness.rng(tokenId, 14) > 1
                ? 96
                : _buddyRandomness.rng(tokenId, 20) + 80;
        } else {
            rarity = _buddyRandomness.rng(tokenId, 100);
        }

        // Common
        if (rarity <= 80) {
            max = _mutations.getRarity(species, traitType - 3);
            // Rare
        } else if (rarity <= 96) {
            min = _mutations.getRarity(species, traitType - 3) + 1;
            max = _mutations.getRarity(species, traitType - 2);
            // Legendary
        } else if (rarity <= 99) {
            min = _mutations.getRarity(species, traitType - 2) + 1;
            max = _mutations.getRarity(species, traitType - 1);
            // Exalted
        } else {
            min = _mutations.getRarity(species, traitType - 1) + 1;
            max = _mutations.getRarity(species, traitType);
        }

        return traitRandom(tokenId, min, max);
    }

    function traitRandom(
        uint256 tokenId,
        uint256 min,
        uint256 max
    ) private returns (uint256 trait) {
        uint256 n = max - (min - 1);
        uint256 total = ((n * 2 + 1) * n * (n + 1)) / 6;

        uint256 rand = _buddyRandomness.rng(tokenId, total);

        for (uint256 i = min; i <= max; i++) {
            // Lower numbers = higher probability
            total -= BuddyLib.pow(max - (i - 1), 2);

            if (total <= rand) {
                return i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/BuddyLib.sol";

interface IBuddyLogic {
    function getMaxGen() external pure returns (uint8);

    function calcFounderClaim(BuddyLib.Buddy calldata)
        external
        view
        returns (uint256);

    function founderClaim(BuddyLib.Buddy calldata) external returns (uint256);

    function createGen0(uint256) external returns (uint256);

    function calcClaim(BuddyLib.Buddy calldata) external view returns (uint256);

    function calcGGPD(
        BuddyLib.Buddy calldata,
        bool,
        bool
    ) external view returns (uint256);

    function getMaxBalance(BuddyLib.Buddy calldata)
        external
        view
        returns (uint256);

    function calcApop(uint256) external view returns (uint256);

    function replicatePreview(
        int8[6] calldata,
        int8[24] calldata,
        BuddyLib.Buddy calldata
    ) external view returns (uint256);

    function repBuddy(
        uint256,
        BuddyLib.Buddy calldata,
        int8[6] calldata,
        int8[24] calldata
    ) external returns (uint256);

    function simpleReplicatePreview(BuddyLib.Buddy calldata)
        external
        view
        returns (uint256);

    function simpleRepBuddy(uint256, BuddyLib.Buddy calldata)
        external
        returns (uint256);

    function calcReps(uint256, uint8) external returns (uint8);

    function calcPeg() external view returns (uint256);

    function getFund() external view returns (address);

    function getBurnPercent() external view returns (uint256);

    function getPayment() external view returns (uint256);

    function getStartingGoo() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/BuddyLib.sol";

interface ISynthesizer {
    function setMutationsContract(address) external;

    function grabRandomBuddy(uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

interface IBuddyRandomness {
    function setBuddySynthesizerAddr(address) external;

    function setBuddyLogicAddr(address) external;

    function generateRandom(uint256) external;

    function getRandomResult(uint256) external view returns (uint256);

    function rng(uint256, uint256) external returns (uint256);
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
pragma solidity 0.8.10;

// |  \/  (_)              |  _ \          | |   | (_)
// | \  / |_  ___ _ __ ___ | |_) |_   _  __| | __| |_  ___  ___ ™
// | |\/| | |/ __| '__/ _ \|  _ <| | | |/ _` |/ _` | |/ _ \/ __|
// | |  | | | (__| | | (_) | |_) | |_| | (_| | (_| | |  __/\__ \
// |_|  |_|_|\___|_|  \___/|____/ \__,_|\__,_|\__,_|_|\___||___/ 2021

library BuddyLib {
    //Specials
    // 0 = None
    // 1 = Blackhole
    // 2 = Founder
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
        uint256 lock;
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
        base.lock = block.timestamp - 420;

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