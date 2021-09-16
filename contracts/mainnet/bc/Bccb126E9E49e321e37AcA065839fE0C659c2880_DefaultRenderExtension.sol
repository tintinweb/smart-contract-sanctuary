//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../RenderExtension.sol";

// solhint-disable quotes
contract DefaultRenderExtension is RenderExtension {
    uint256 public constant COLOR_CNT = 16;

    string[] public colorNames = ["Red", "Pink", "Purple", "Deep Puple", "Indigo", "Blue", "Light Blue", "Cyan", "Teal", "Green", "Light Green", "Lime", "Yellow", "Amber", "Orange", "Deep Orange"];
    string[] public colors = [
        "#f44336",
        "#e91e63",
        "#9c27b0",
        "#673ab7",
        "#3f51b5",
        "#2196f3",
        "#03a9f4",
        "#00bcd4",
        "#009688",
        "#4caf50",
        "#8bc34a",
        "#cddc39",
        "#ffeb3b",
        "#ffc107",
        "#ff9800",
        "#ff5722"
    ];

    function generate(uint256 tokenId, uint256) external view override returns (GenerateResult memory generateResult) {
        string[30] memory parts;
        string[30] memory attrs;

        uint256 rand = random(string(abi.encodePacked(address(this), "Boxes.", toString(tokenId))));
        uint256 numOfBoxesPos = rand % 10;
        if (numOfBoxesPos == 0) {
            numOfBoxesPos = 1;
        }
        uint256 totalBoxes = 0;

        for (uint256 ix = 1; ix <= numOfBoxesPos * 3; ix = ix + 3) {
            uint256 bx = random(string(abi.encodePacked(toString(ix), ".Boxes.", toString(tokenId)))) % numOfBoxesPos;
            uint256 i = ix - 1;
            uint256 clr = random(string(abi.encodePacked("Colors.", toString(ix), ".Boxes.", toString(tokenId)))) % COLOR_CNT;

            if (i == 0 && bx == 0) {
                parts[i] = '<rect x="10" y="10" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 1","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 3 && bx == 1) {
                parts[i] = '<rect x="123" y="10" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 2","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 6 && bx == 2) {
                parts[i] = '<rect x="236" y="10" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 3","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 9 && bx == 3) {
                parts[i] = '<rect x="10" y="123" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 4","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 12 && bx == 4) {
                parts[i] = '<rect x="123" y="123" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 5","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 15 && bx == 5) {
                parts[i] = '<rect x="236" y="123" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 6","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 18 && bx == 6) {
                parts[i] = '<rect x="10" y="236" width="103" height="80" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 7","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 21 && bx == 7) {
                parts[i] = '<rect x="123" y="236" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 8","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            } else if (i == 24 && bx == 8) {
                parts[i] = '<rect x="236" y="236" width="103" height="103" rx="5" stroke="white" fill="';
                parts[i + 1] = colors[clr];
                parts[i + 2] = '" fill-opacity="1.0" />';

                attrs[i] = ',{"trait_type":"OG Box 9","value":"';
                attrs[i + 1] = colorNames[clr];
                attrs[i + 2] = '"}';

                totalBoxes = totalBoxes + 1;
            }
        }

        if (totalBoxes == 0) {
            uint256 clr = random(string(abi.encodePacked("Colors.", "Boxes.", toString(tokenId)))) % COLOR_CNT;

            parts[0] = '<rect x="123" y="123" width="103" height="103" rx="5" fill="black" stroke="';
            parts[1] = colors[clr];
            parts[2] = '" fill-opacity="0.0" />';
        }

        attrs[27] = ',{"trait_type":"OG Boxes","value":"';
        attrs[28] = toString(totalBoxes);
        attrs[29] = '"}';

        parts[27] = '<text x="10" y="338" class="base">';
        parts[28] = toString(tokenId);
        parts[29] = "</text>";

        string memory svgOutput = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        svgOutput = string(abi.encodePacked(svgOutput, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        svgOutput = string(abi.encodePacked(svgOutput, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        svgOutput = string(abi.encodePacked(svgOutput, parts[25], parts[26], parts[27], parts[28], parts[29]));

        string memory attrOutput = string(abi.encodePacked(attrs[0], attrs[1], attrs[2], attrs[3], attrs[4], attrs[5], attrs[6], attrs[7], attrs[8]));
        attrOutput = string(abi.encodePacked(attrOutput, attrs[9], attrs[10], attrs[11], attrs[12], attrs[13], attrs[14], attrs[15], attrs[16]));
        attrOutput = string(abi.encodePacked(attrOutput, attrs[17], attrs[18], attrs[19], attrs[20], attrs[21], attrs[22], attrs[23], attrs[24]));
        attrOutput = string(abi.encodePacked(attrOutput, attrs[25], attrs[26], attrs[27], attrs[28], attrs[29]));

        generateResult = GenerateResult({svgPart: svgOutput, attributes: attrOutput});
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IRenderExtension.sol";

abstract contract RenderExtension is IRenderExtension {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IRenderExtension).interfaceId;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRenderExtension is IERC165 {
    struct GenerateResult {
        string svgPart;
        string attributes;
    }

    struct Attribute {
        string displayType;
        string traitType;
        string value;
    }

    function generate(uint256 tokenId, uint256 generationId) external view returns (GenerateResult memory generateResult);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 20
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
  "libraries": {}
}