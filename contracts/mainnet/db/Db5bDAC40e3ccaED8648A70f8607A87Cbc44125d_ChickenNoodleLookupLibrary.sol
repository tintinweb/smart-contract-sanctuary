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

    function mint(address to, uint16 tokenId) external;

    function finalize(
        uint16 tokenId,
        ChickenNoodleTraits memory traits,
        address thief
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IChickenNoodle.sol';

library ChickenNoodleLookupLibrary {
    function totalNoodles(address chickenNoodleAddress)
        public
        view
        returns (uint16)
    {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        uint16 counter = 0;

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (uint16 tokenId = 1; tokenId <= supply; tokenId++) {
            if (
                chickenNoodle.tokenTraits(tokenId).minted &&
                !chickenNoodle.tokenTraits(tokenId).isChicken
            ) {
                counter++;
            }
        }

        return counter;
    }

    function getTokensForOwner(
        address chickenNoodleAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        uint256 tokensOwned = chickenNoodle.balanceOf(tokenOwner);

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        uint16[] memory tokens = new uint16[](tokensSize);

        uint16 skipCounter = 0;
        uint16 counter = 0;

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counter < tokens.length;
            tokenId++
        ) {
            if (chickenNoodle.ownerOf(tokenId) == tokenOwner) {
                if (skipCounter < pageStart) {
                    skipCounter++;
                    continue;
                }

                tokens[counter] = tokenId;
                counter++;
            }
        }

        return tokens;
    }

    function getTokenTypesBalanceOf(
        address chickenNoodleAddress,
        address tokenOwner
    )
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles,
            uint16 unminted
        )
    {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (uint16 tokenId = 1; tokenId <= supply; tokenId++) {
            if (chickenNoodle.ownerOf(tokenId) != tokenOwner) {
                continue;
            }

            if (!chickenNoodle.tokenTraits(tokenId).minted) {
                unminted++;
                continue;
            }

            if (chickenNoodle.tokenTraits(tokenId).isChicken) {
                chickens++;
            } else {
                uint8 tier = chickenNoodle.tokenTraits(tokenId).tier;

                if (tier == 5) {
                    tier5Noodles++;
                } else if (tier == 4) {
                    tier4Noodles++;
                } else if (tier == 3) {
                    tier3Noodles++;
                } else if (tier == 2) {
                    tier2Noodles++;
                } else if (tier == 1) {
                    tier1Noodles++;
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

    function getMintedForOwner(
        address chickenNoodleAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        (, , , , , , , uint16 tokensOwned) = getTokenTypesBalanceOf(
            chickenNoodleAddress,
            tokenOwner
        );

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        uint16[] memory tokens = new uint16[](tokensSize);

        uint16 skipCounter = 0;
        uint16 counter = 0;

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counter < tokens.length;
            tokenId++
        ) {
            if (chickenNoodle.ownerOf(tokenId) != tokenOwner) {
                continue;
            }

            if (chickenNoodle.tokenTraits(tokenId).minted) {
                if (skipCounter < pageStart) {
                    skipCounter++;
                    continue;
                }

                tokens[counter] = tokenId;
                counter++;
            }
        }

        return tokens;
    }

    function getUnmintedForOwner(
        address chickenNoodleAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        (, , , , , , , uint16 tokensOwned) = getTokenTypesBalanceOf(
            chickenNoodleAddress,
            tokenOwner
        );

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        uint16[] memory tokens = new uint16[](tokensSize);

        uint16 skipCounter = 0;
        uint16 counter = 0;

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counter < tokens.length;
            tokenId++
        ) {
            if (chickenNoodle.ownerOf(tokenId) != tokenOwner) {
                continue;
            }

            if (!chickenNoodle.tokenTraits(tokenId).minted) {
                if (skipCounter < pageStart) {
                    skipCounter++;
                    continue;
                }

                tokens[counter] = tokenId;
                counter++;
            }
        }

        return tokens;
    }

    function getChickensForOwner(
        address chickenNoodleAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        (uint16 tokensOwned, , , , , , , ) = getTokenTypesBalanceOf(
            chickenNoodleAddress,
            tokenOwner
        );

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        uint16[] memory tokens = new uint16[](tokensSize);

        uint16 skipCounter = 0;
        uint16 counter = 0;

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counter < tokens.length;
            tokenId++
        ) {
            if (
                !chickenNoodle.tokenTraits(tokenId).minted ||
                chickenNoodle.ownerOf(tokenId) != tokenOwner
            ) {
                continue;
            }

            if (chickenNoodle.tokenTraits(tokenId).isChicken) {
                if (skipCounter < pageStart) {
                    skipCounter++;
                    continue;
                }

                tokens[counter] = tokenId;
                counter++;
            }
        }

        return tokens;
    }

    function getNoodlesForOwner(
        address chickenNoodleAddress,
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        IChickenNoodle chickenNoodle = IChickenNoodle(chickenNoodleAddress);

        (, uint16 tokensOwned, , , , , , ) = getTokenTypesBalanceOf(
            chickenNoodleAddress,
            tokenOwner
        );

        uint256 pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        uint256 tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);

        uint16[] memory tokens = new uint16[](tokensSize);

        uint16 skipCounter = 0;
        uint16 counter = 0;

        uint16 supply = uint16(chickenNoodle.totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counter < tokens.length;
            tokenId++
        ) {
            if (
                !chickenNoodle.tokenTraits(tokenId).minted ||
                chickenNoodle.ownerOf(tokenId) != tokenOwner
            ) {
                continue;
            }

            if (!chickenNoodle.tokenTraits(tokenId).isChicken) {
                if (skipCounter < pageStart) {
                    skipCounter++;
                    continue;
                }

                tokens[counter] = tokenId;
                counter++;
            }
        }

        return tokens;
    }
}