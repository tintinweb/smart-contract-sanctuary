// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChickenNoodle {
    // struct to store each token's traits
    struct ChickenNoodleTraits {
        bool minted;
        bool isChicken;
        uint8 backgrounds;
        uint8 snakeBodies;
        uint8 mouthAccessories;
        uint8 pupils;
        uint8 bodyAccessories;
        uint8 hats;
        uint8 tier;
    }

    function MAX_TOKENS() external view returns (uint256);

    function PAID_TOKENS() external view returns (uint256);

    function tokenTraits(uint256 tokenId)
        external
        view
        returns (ChickenNoodleTraits memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to, uint256 tokenId) external;

    function finalize(
        uint256 tokenId,
        ChickenNoodleTraits memory traits,
        address thief
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IChickenNoodle.sol';
import './IFarm.sol';

interface IChickenNoodleSoup {
    function rarities(uint8 i) external view returns (uint8[] memory);

    function aliases(uint8 i) external view returns (uint8[] memory);

    function chickenNoodle() external view returns (IChickenNoodle);

    function farm() external view returns (IFarm);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IChickenNoodle.sol';

interface IFarm {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    function totalChickenStaked() external view returns (uint256);

    function MINIMUM_TO_EXIT() external view returns (uint256);

    function MAX_TIER_SCORE() external view returns (uint256);

    function MAXIMUM_GLOBAL_EGG() external view returns (uint256);

    function DAILY_GEN0_EGG_RATE() external view returns (uint256);

    function DAILY_GEN1_EGG_RATE() external view returns (uint256);

    function eggPerTierScore() external view returns (uint256);

    function totalEggEarned() external view returns (uint256);

    function lastClaimTimestamp() external view returns (uint256);

    function henHouse(uint256 tokenIndex) external view returns (Stake memory);

    function den(uint256 tokenId) external view returns (Stake[] memory);

    function denIndices(uint256 tokenId) external view returns (uint256);

    function chickenNoodle() external view returns (IChickenNoodle);

    function isChicken(uint256 tokenId) external view returns (bool);

    function tierScoreForNoodle(uint256 tokenId) external view returns (uint8);

    function randomNoodleOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IChickenNoodleSoup.sol';
import '../interfaces/IChickenNoodle.sol';

library ChickenNoodleSoupGeneratorLibrary {
    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(
        address chickenNoodleSoupAddress,
        uint16 seed,
        uint8 traitType
    ) public view returns (uint8) {
        IChickenNoodleSoup chickenNoodleSoup = IChickenNoodleSoup(
            chickenNoodleSoupAddress
        );

        uint8 trait = uint8(seed) %
            uint8(chickenNoodleSoup.rarities(traitType).length);
        if (seed >> 8 < chickenNoodleSoup.rarities(traitType)[trait])
            return trait;
        return chickenNoodleSoup.aliases(traitType)[trait];
    }

    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked noodle
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Noodle thief's owner)
     */
    function selectRecipient(
        address chickenNoodleSoupAddress,
        uint256 tokenId,
        uint256 seed
    ) public view returns (address) {
        IChickenNoodleSoup chickenNoodleSoup = IChickenNoodleSoup(
            chickenNoodleSoupAddress
        );

        if (
            tokenId <= chickenNoodleSoup.chickenNoodle().PAID_TOKENS() ||
            ((seed >> 245) % 10) != 0
        ) return chickenNoodleSoup.chickenNoodle().ownerOf(tokenId); // top 10 bits haven't been used
        address thief = chickenNoodleSoup.farm().randomNoodleOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0))
            return chickenNoodleSoup.chickenNoodle().ownerOf(tokenId);
        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(
        address chickenNoodleSoupAddress,
        uint256 tokenId,
        uint256 seed
    ) public view returns (IChickenNoodle.ChickenNoodleTraits memory t) {
        t.minted = true;

        t.isChicken = (seed & 0xFFFF) % 10 != 0;

        seed >>= 16;
        t.backgrounds = selectTrait(
            chickenNoodleSoupAddress,
            uint16(seed & 0xFFFF),
            0
        );

        seed >>= 16;
        t.mouthAccessories = selectTrait(
            chickenNoodleSoupAddress,
            uint16(seed & 0xFFFF),
            1
        );

        seed >>= 16;
        t.pupils = selectTrait(
            chickenNoodleSoupAddress,
            uint16(seed & 0xFFFF),
            2
        );

        seed >>= 16;
        t.hats = selectTrait(
            chickenNoodleSoupAddress,
            uint16(seed & 0xFFFF),
            3
        );

        seed >>= 16;
        t.bodyAccessories = t.isChicken
            ? 0
            : selectTrait(chickenNoodleSoupAddress, uint16(seed & 0xFFFF), 4);

        seed >>= 16;
        uint8 tier = selectTrait(
            chickenNoodleSoupAddress,
            uint16(seed & 0xFFFF),
            5
        );

        seed >>= 16;
        t.snakeBodies = selectTrait(
            chickenNoodleSoupAddress,
            uint16(seed & 0xFFFF),
            6 + t.tier
        );

        t.tier = t.isChicken
            ? 0
            : (
                tokenId <=
                    IChickenNoodleSoup(chickenNoodleSoupAddress)
                        .chickenNoodle()
                        .PAID_TOKENS()
                    ? 5
                    : 4
            ) - tier;
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(IChickenNoodle.ChickenNoodleTraits memory s)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.minted,
                        s.isChicken,
                        s.backgrounds,
                        s.snakeBodies,
                        s.mouthAccessories,
                        s.pupils,
                        s.bodyAccessories,
                        s.hats,
                        s.tier
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number
     * @param tokenId a value ensure different outcomes for different sources in the same block
     * @param mintBlockhash minthash stored at time of initial mint
     * @param seed vrf random value
     * @return a pseudorandom value
     */
    function random(
        uint256 tokenId,
        bytes32 mintBlockhash,
        uint256 seed
    ) public pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(tokenId, mintBlockhash, seed)));
    }
}