// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./interfaces/ILayerDescriptor.sol";
import "./interfaces/IOGCards.sol";

contract FrontLayerDescriptor is ILayerDescriptor {
    constructor() {}

    function svgLayer(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        external
        override
        view
        returns (string memory)
    {
        (, string[] memory names) = IOGCards(ogCards).ogHolders(tokenId);
        address owner = IOGCards(ogCards).ownerOf(tokenId);
        string memory ownerName = IOGCards(ogCards).holderName(owner);
        string memory backgroundColor = _colorWithTransparencyLevelString("#212429", card.transparencyLevel);
        return string(abi.encodePacked(
            '<g mask="url(#mask)">',
                '<g>',
                    '<rect width="100%" height="100%" fill="',backgroundColor,'"></rect>',
                    '<g class="mask-path">',
                        svgMask(card.maskType, borderColor, false, false),
                    '</g>',
                    '<text text-rendering="optimizeSpeed">',
                        _svgTextPath(names, ownerName, font, borderColor),
                    '</text>',
                    '<use href="#token-id" stroke="',borderColor,'" stroke-width="2" />',
                '</g>',
            '</g>'
        ));
    }

    function svgMask(uint8 maskType, string memory borderColor, bool isDef, bool isMask)
        public
        override
        pure
        returns (string memory)
    {
        return (maskType == 0 ? _ethMask(borderColor, isDef, isMask) :
                (maskType == 1 ? _punkMask(borderColor, isDef, isMask) : 
                    (maskType == 2 ? _acbMask(borderColor, isDef, isMask) :
                        (maskType == 3 ? _purrMask(borderColor, isDef, isMask) : ''))));
    }

    function _colorWithTransparencyLevelString(string memory color, uint8 transparencyLevel)
        private
        pure
        returns (string memory)
    {
        string memory transparencyString = (
            (transparencyLevel < 96 ? 'F2' :
                (transparencyLevel < 97 ? 'F5' :
                    (transparencyLevel < 98 ? 'F7' :
                        (transparencyLevel < 99 ? 'FA' : 'FC')))));
                    
        return string(abi.encodePacked(
            color,
            transparencyString
        ));
    }

    function _svgTextPath(string[] memory names, string memory ownerName, string memory font, string memory borderColor)
        private
        pure
        returns (string memory)
    {
        string memory ogNamesText = _ogNamesText(names, borderColor);
        return string(abi.encodePacked(
            '<textPath startOffset="-100%" fill="white" font-family="',font,'" font-size="12px" href="#text-path-border">',
                ogNamesText,
                ' Owner [ <tspan fill="',borderColor,'">',ownerName,'</tspan> ] ',
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="15s" repeatCount="indefinite"></animate></textPath>',
            '<textPath startOffset="0%" fill="white" font-family="',font,'" font-size="12px" href="#text-path-border">',
                ogNamesText,
                ' Owner [ <tspan fill="',borderColor,'">',ownerName,'</tspan> ] ',
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="15s" repeatCount="indefinite"></animate></textPath>'
        ));
    }

    function _ogNamesText(string[] memory names, string memory ogColor)
        private
        pure
        returns (string memory)
    {
        string memory ogsList;
        uint256 totalLength;

        for (uint256 i = 0; i < names.length; i++) {
            uint256 index = names.length-1-i;
            string memory name = names[index];
            totalLength += _utfStringLength(name) + 2;
            if (totalLength < 100) {
                ogsList = string(abi.encodePacked(
                    ' <tspan fill="',ogColor,'">', name, '</tspan>',
                    i > 0 ? ',' : '',
                    ogsList
                ));
            } else {
                break;
            }
        }
        return string(abi.encodePacked(
            ' OGs [ ',
            ogsList,
            ' ]'
        ));
    }

    function _utfStringLength(string memory str) internal pure
    returns (uint length)
    {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (uint8(string_rep[i]>>7)==0)
                i+=1;
            else if (uint8(string_rep[i]>>5)==0x6)
                i+=2;
            else if (uint8(string_rep[i]>>4)==0xE)
                i+=3;
            else if (uint8(string_rep[i]>>3)==0x1E)
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    function _ethMask(string memory borderColor, bool isDef, bool isMask)
        private
        pure
        returns (string memory)
    {
        if (isDef) {
            if (isMask) {
                return string(abi.encodePacked(
                    '<use href="#eth-mask-top" />',
                    '<use href="#eth-mask-bottom" />'
                ));
            }
            return string(abi.encodePacked(
                '<path id="eth-mask-top" d="M150 50 l49.875 92.85714285714286 l-49.875 28.571428571428573 l-49.875 -28.571428571428573 z" fill="#000000"></path>',
                '<path id="eth-mask-bottom" d="M150 250 l49.875 -92.85714285714286 l-49.875 28.571428571428573 l-49.875 -28.571428571428573 z" fill="#000000"></path>'
            ));
        }
        return string(abi.encodePacked(
            '<use href="#eth-mask-top" stroke="',borderColor,'" stroke-width="3" />',
            '<use href="#eth-mask-bottom" stroke="',borderColor,'" stroke-width="3" />'
        ));
    }

    function _punkMask(string memory borderColor, bool isDef, bool isMask)
        private
        pure
        returns (string memory)
    {
        if (isDef) {
            if (isMask) {
                return '<use href="#punk-mask" />';
            }
            return '<path id="punk-mask" d="M116.66 50 h77.77 v11.11 h11.11 v144.44 h-11.11 v11.11 h-55.55 v33.33 h-33.33 v-111.11 h-11.11 v-22.22 h11.11 v-55.55 h11.11 z" fill="#000000"></path>';
        }
        return string(abi.encodePacked(
            '<use href="#punk-mask" stroke="',borderColor,'" stroke-width="3" />'
        ));
    }

    function _acbMask(string memory borderColor, bool isDef, bool isMask)
        private
        pure
        returns (string memory)
    {
        if (isDef) {
            if (isMask) {
                return '<use href="#acb-mask" />';
            }
            return '<path id="acb-mask" d="M90 75h15 v15 h15 v15 h60 v-15 h15 v-15 h15 v75 h15 v15 h-15 v15 h15 v15 h-15 v15 h-15 v15 h-90 v-15 h-15 v-15 h-15 v-15 h15 v-15 h-15 v-15 h15 z" fill="#000000"></path>';
        }
        return string(abi.encodePacked(
            '<use href="#acb-mask" stroke="',borderColor,'" stroke-width="3" />'
        ));
    }

    function _purrMask(string memory borderColor, bool isDef, bool isMask)
        private
        pure
        returns (string memory)
    {
        if (isDef) {
            if (isMask) {
                return '<use href="#purr-mask" />';
            }
            return '<path id="purr-mask" d="M105 60 a200 110 0 0 1 30 45 h30 a200 110 0 0 1 30 -45 a150 110 0 0 1 30 45 v60 a100 100 0 0 1 -45 60 h-60 a100 100 0 0 1 -45 -60 v-60 a150 110 0 0 1 30 -45 z" fill="#000000"></path>';
        }
        return string(abi.encodePacked(
            '<use href="#purr-mask" stroke="',borderColor,'" stroke-width="3" />'
        ));
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

