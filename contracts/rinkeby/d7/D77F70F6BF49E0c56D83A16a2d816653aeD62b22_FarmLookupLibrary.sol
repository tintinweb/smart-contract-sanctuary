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

import '../interfaces/IFarm.sol';

library FarmLookupLibrary {
    struct Counters {
        uint256 skipCounter;
        uint256 counter;
    }

    function getTotalStaked(address farmAddress)
        public
        view
        returns (
            uint256 chickens,
            uint256 noodles,
            uint256 tier5Noodles,
            uint256 tier4Noodles,
            uint256 tier3Noodles,
            uint256 tier2Noodles,
            uint256 tier1Noodles
        )
    {
        IFarm farm = IFarm(farmAddress);

        chickens = farm.totalChickenStaked();

        tier5Noodles = farm.den(farm.MAX_TIER_SCORE()).length;
        tier4Noodles = farm.den(farm.MAX_TIER_SCORE() - 1).length;
        tier3Noodles = farm.den(farm.MAX_TIER_SCORE() - 2).length;
        tier2Noodles = farm.den(farm.MAX_TIER_SCORE() - 3).length;
        tier1Noodles = farm.den(farm.MAX_TIER_SCORE() - 4).length;

        noodles =
            tier5Noodles +
            tier4Noodles +
            tier3Noodles +
            tier2Noodles +
            tier1Noodles;
    }

    function getStakedBalanceOf(address farmAddress, address tokenOwner)
        public
        view
        returns (
            uint256 chickens,
            uint256 noodles,
            uint256 tier5Noodles,
            uint256 tier4Noodles,
            uint256 tier3Noodles,
            uint256 tier2Noodles,
            uint256 tier1Noodles
        )
    {
        IFarm farm = IFarm(farmAddress);

        uint256 supply = farm.chickenNoodle().totalSupply();

        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (farm.isChicken(tokenId)) {
                if (farm.henHouse(tokenId).owner == tokenOwner) {
                    chickens++;
                }
            } else {
                uint256 tierScore = farm.tierScoreForNoodle(tokenId);

                if (
                    farm.den(tierScore)[farm.denIndices(tokenId)].owner ==
                    tokenOwner
                ) {
                    if (tierScore == 8) {
                        tier5Noodles++;
                    } else if (tierScore == 7) {
                        tier4Noodles++;
                    } else if (tierScore == 5) {
                        tier3Noodles++;
                    } else if (tierScore == 4) {
                        tier2Noodles++;
                    } else if (tierScore == 3) {
                        tier1Noodles++;
                    }
                }
            }
        }

        noodles =
            tier5Noodles +
            tier4Noodles +
            tier3Noodles +
            tier2Noodles +
            tier1Noodles;
    }

    function getStakedChickensForOwner(
        address farmAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    )
        public
        view
        returns (
            uint256[] memory tokens,
            uint256[] memory timeTellUnlock,
            uint256[] memory earnedEgg
        )
    {
        IFarm farm = IFarm(farmAddress);

        (uint256 tokensOwned, , , , , , ) = getStakedBalanceOf(
            farmAddress,
            tokenOwner
        );

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        tokens = new uint256[](tokensSize);
        timeTellUnlock = new uint256[](tokensSize);
        earnedEgg = new uint256[](tokensSize);

        uint256 skipCounter = 0;
        uint256 counter = 0;

        uint256 supply = farm.chickenNoodle().totalSupply();

        for (
            uint256 tokenId = 1;
            tokenId <= supply && counter < tokens.length;
            tokenId++
        ) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (farm.isChicken(tokenId)) {
                IFarm.Stake memory stake = farm.henHouse(tokenId);

                if (stake.owner == tokenOwner) {
                    if (skipCounter < pageStart) {
                        skipCounter++;
                        continue;
                    }

                    tokens[counter] = tokenId;
                    timeTellUnlock[counter] = block.timestamp - stake.value <
                        farm.MINIMUM_TO_EXIT()
                        ? block.timestamp - stake.value
                        : 0;

                    if (farm.totalEggEarned() < farm.MAXIMUM_GLOBAL_EGG()) {
                        earnedEgg[counter] =
                            ((block.timestamp - stake.value) *
                                (
                                    tokenId <=
                                        farm.chickenNoodle().PAID_TOKENS()
                                        ? farm.DAILY_GEN0_EGG_RATE()
                                        : farm.DAILY_GEN1_EGG_RATE()
                                )) /
                            1 days;
                    } else if (stake.value > farm.lastClaimTimestamp()) {
                        earnedEgg[counter] = 0; // $EGG production stopped already
                    } else {
                        earnedEgg[counter] =
                            ((farm.lastClaimTimestamp() - stake.value) *
                                (
                                    tokenId <=
                                        farm.chickenNoodle().PAID_TOKENS()
                                        ? farm.DAILY_GEN0_EGG_RATE()
                                        : farm.DAILY_GEN1_EGG_RATE()
                                )) /
                            1 days; // stop earning additional $EGG if it's all been earned
                    }

                    counter++;
                }
            }
        }
    }

    function getStakedNoodlesForOwner(
        address farmAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    )
        public
        view
        returns (
            uint256[] memory tokens,
            uint8[] memory tier,
            uint256[] memory taxedEgg
        )
    {
        IFarm farm = IFarm(farmAddress);

        (, uint256 tokensOwned, , , , , ) = getStakedBalanceOf(
            farmAddress,
            tokenOwner
        );

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        tokens = new uint256[](tokensSize);
        tier = new uint8[](tokensSize);
        taxedEgg = new uint256[](tokensSize);

        Counters memory counters;

        uint256 supply = farm.chickenNoodle().totalSupply();

        for (
            uint256 tokenId = 1;
            tokenId <= supply && counters.counter < tokens.length;
            tokenId++
        ) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (!farm.isChicken(tokenId)) {
                uint8 tierScore = farm.tierScoreForNoodle(tokenId);

                IFarm.Stake memory stake = farm.den(tierScore)[
                    farm.denIndices(tokenId)
                ];

                if (stake.owner == tokenOwner) {
                    if (counters.skipCounter < pageStart) {
                        counters.skipCounter++;
                        continue;
                    }

                    tokens[counters.counter] = tokenId;
                    tier[counters.counter] = tierScore - 3;
                    taxedEgg[counters.counter] =
                        (tierScore) *
                        (farm.eggPerTierScore() - stake.value);
                    counters.counter++;
                }
            }
        }
    }
}