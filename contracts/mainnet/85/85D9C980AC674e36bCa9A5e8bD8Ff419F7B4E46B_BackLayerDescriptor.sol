// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ILayerDescriptor.sol";

contract BackLayerDescriptor is ILayerDescriptor {
    constructor() {}

    function svgLayer(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        external
        override
        view
        returns (string memory)
    {
        string memory backgroundColor = "#2c3e50";
        return string(abi.encodePacked(
            '<rect width="100%" height="100%" fill="',backgroundColor,'" />'
        ));
    }

    function svgMask(uint8 maskType, string memory borderColor, bool isDef, bool isMask)
        public
        override
        pure
        returns (string memory)
    {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IOGCards.sol";

interface ILayerDescriptor {
    struct Layer {
        bool isGiveaway;
        uint8 maskType;
        uint8 transparencyLevel;
        uint256 tokenId;
        uint256 dna;
        uint256 mintTokenId;
        string font;
        string borderColor;
        address ogCards;
    }
    function svgLayer(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        external
        view
        returns (string memory);

    function svgMask(uint8 maskType, string memory borderColor, bool isDef, bool isMask)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IOGCards {
    struct Card {
        bool isGiveaway;
        uint8 borderType;
        uint8 transparencyLevel;
        uint8 maskType;
        uint256 dna;
        uint256 mintTokenId;
        address[] holders;
    }

    function cardDetails(uint256 tokenId) external view returns (Card memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isOG(address _og) external view returns (bool);

    function holderName(address _holder) external view returns (string memory);

    function ogHolders(uint256 tokenId)
        external
        view
        returns (address[] memory, string[] memory);
}

