// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

contract ChainFaces2Renderer {

    using Strings for uint256;

    address public constant happyFacePlace = 0x7039D65E346FDEEBbc72514D718C88699c74ba4b;

    // Rendering constants
    string[18] public leftFaceArray = [unicode"ლ", unicode"ᕦ", unicode"(ง", unicode"𐐋", unicode"ᖳ", unicode"Ƹ", unicode"ᛩ", unicode"⦃", unicode"{", unicode"⦗", unicode"〈", unicode"⧼", unicode"|", unicode"〘", unicode"〚", unicode"【", unicode"[", unicode"❪"];
    string[20] public leftEyeArray = [unicode"⚈", unicode"⚙", unicode"⊗", unicode"⋗", unicode" ͡°", unicode"◈", unicode"◬", unicode"≻", unicode"᛫", unicode"⨕", unicode"★", unicode"Ͼ", unicode"ᗒ", unicode"◠", unicode"⊡", unicode"⊙", unicode"▸", unicode"˘", unicode"⦿", unicode"●"];
    string[22] public mouthArray = [unicode"෴", unicode"∪", unicode"ᨏ", unicode"᎔", unicode"᎑", unicode"⋏", unicode"⚇", unicode"_", unicode"۷", unicode"▾", unicode"ᨎ", unicode"ʖ", unicode"ܫ", unicode"໒", unicode"𐑒", unicode"⌴", unicode"‿", unicode"𐠑", unicode"⌒", unicode"◡", unicode"⥿", unicode"⩊"];
    string[20] public rightEyeArray = [unicode"⚈", unicode"⚙", unicode"⊗", unicode"⋖", unicode" ͡°", unicode"◈", unicode"◬", unicode"≺", unicode"᛫", unicode"⨕", unicode"★", unicode"Ͽ", unicode"ᗕ", unicode"◠", unicode"⊡", unicode"⊙", unicode"◂", unicode"˘", unicode"⦿", unicode"●"];
    string[18] public rightFaceArray = [unicode"ლ", unicode"ᕤ", unicode")ง", unicode"𐐙", unicode"ᖰ", unicode"Ʒ", unicode"ᚹ", unicode"⦄", unicode"}", unicode"⦘", unicode"〉", unicode"⧽", unicode"|", unicode"〙", unicode"〛", unicode"】", unicode"]", unicode"❫"];

    uint256[22] rarityArray = [0, 2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135, 152, 170, 189, 209, 230, 252];

    uint256[5][] ancients;

    constructor() {
        ancients.push([0, 0, 0, 0, 0]);
        ancients.push([1, 1, 1, 1, 1]);
        ancients.push([2, 2, 2, 2, 2]);
        ancients.push([3, 3, 3, 3, 3]);
        ancients.push([4, 4, 4, 4, 4]);
        ancients.push([5, 5, 5, 5, 5]);
        ancients.push([6, 6, 6, 6, 6]);
        ancients.push([7, 7, 7, 7, 7]);
        ancients.push([8, 8, 8, 8, 8]);
        ancients.push([9, 9, 9, 9, 9]);
    }

    function getLeftFace(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return leftFaceArray[ancients[id][0]];
        }

        uint256 raritySelector = seed % 189;

        uint256 charSelector = 0;

        for (uint i = 0; i < 18; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return leftFaceArray[charSelector];
    }

    function getLeftEye(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return leftEyeArray[ancients[id][1]];
        }

        uint256 raritySelector = seed % 230;

        uint256 charSelector = 0;

        for (uint i = 0; i < 20; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return leftEyeArray[charSelector];
    }

    function getMouth(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return mouthArray[ancients[id][2]];
        }

        uint256 raritySelector = seed % 275;

        uint256 charSelector = 0;

        for (uint i = 0; i < 22; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return mouthArray[charSelector];
    }

    function getRightEye(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return rightEyeArray[ancients[id][3]];
        }

        uint256 raritySelector = uint256(keccak256(abi.encodePacked(seed))) % 230;

        uint256 charSelector = 0;

        for (uint i = 0; i < 20; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return rightEyeArray[charSelector];
    }

    function getRightFace(uint256 id, uint256 seed) public view returns (string memory) {
        if (id < ancients.length) {
            return rightFaceArray[ancients[id][4]];
        }

        uint256 raritySelector = uint256(keccak256(abi.encodePacked(seed))) % 189;

        uint256 charSelector = 0;

        for (uint i = 0; i < 18; i++) {
            if (raritySelector >= rarityArray[i]) {
                charSelector = i;
            }
        }

        return rightFaceArray[charSelector];
    }

    function assembleFace(bool revealComplete, uint256 id, uint256 seed) public view returns (string memory face) {
        if (!revealComplete) {
            return '(._.)';
        }

        return string(abi.encodePacked(
                getLeftFace(id, seed),
                getLeftEye(id, seed),
                getMouth(id, seed),
                getRightEye(id, seed),
                getRightFace(id, seed)
            ));
    }

    function calculateGolfScore(uint256 id, uint256 seed) public view returns (uint256) {
        if (id < ancients.length) {
            return 0;
        }

        uint256 leftFaceRarity = seed % 189;
        uint256 lefEyeRarity = seed % 230;
        uint256 mouthRarity = seed % 275;
        uint256 rightEyeRarity = uint256(keccak256(abi.encodePacked(seed))) % 230;
        uint256 rightFaceRarity = uint256(keccak256(abi.encodePacked(seed))) % 189;

        uint256 leftFaceGolf = 0;
        uint256 leftEyeGolf = 0;
        uint256 mouthGolf = 0;
        uint256 rightEyeGolf = 0;
        uint256 rightFaceGolf = 0;
        uint256 i = 0;

        for (i = 0; i < 18; i++) {
            if (leftFaceRarity >= rarityArray[i]) {
                leftFaceGolf = i;
            }
        }
        for (i = 0; i < 20; i++) {
            if (lefEyeRarity >= rarityArray[i]) {
                leftEyeGolf = i;
            }
        }
        for (i = 0; i < 22; i++) {
            if (mouthRarity >= rarityArray[i]) {
                mouthGolf = i;
            }
        }
        for (i = 0; i < 20; i++) {
            if (rightEyeRarity >= rarityArray[i]) {
                rightEyeGolf = i;
            }
        }
        for (i = 0; i < 18; i++) {
            if (rightFaceRarity >= rarityArray[i]) {
                rightFaceGolf = i;
            }
        }

        return leftFaceGolf + leftEyeGolf + mouthGolf + rightEyeGolf + rightFaceGolf;
    }

    function calculateSymmetry(uint256 id, uint256 seed) public view returns (string memory) {

        uint256 symCount = 0;

        if (id < ancients.length) {
            symCount = 2;
        } else {
            uint256 leftFaceRarity = seed % 189;
            uint256 lefEyeRarity = seed % 230;
            uint256 rightEyeRarity = uint256(keccak256(abi.encodePacked(seed))) % 230;
            uint256 rightFaceRarity = uint256(keccak256(abi.encodePacked(seed))) % 189;

            uint256 leftFaceIndex = 0;
            uint256 leftEyeIndex = 0;
            uint256 rightEyeIndex = 0;
            uint256 rightFaceIndex = 0;
            uint256 i = 0;

            for (i = 0; i < 18; i++) {
                if (leftFaceRarity >= rarityArray[i]) {
                    leftFaceIndex = i;
                }
            }
            for (i = 0; i < 20; i++) {
                if (lefEyeRarity >= rarityArray[i]) {
                    leftEyeIndex = i;
                }
            }
            for (i = 0; i < 20; i++) {
                if (rightEyeRarity >= rarityArray[i]) {
                    rightEyeIndex = i;
                }
            }
            for (i = 0; i < 18; i++) {
                if (rightFaceRarity >= rarityArray[i]) {
                    rightFaceIndex = i;
                }
            }

            if (leftFaceIndex == rightFaceIndex) {
                symCount = symCount + 1;
            }
            if (leftEyeIndex == rightEyeIndex) {
                symCount = symCount + 1;
            }
        }

        if (symCount == 2) {
            return "100% Symmetry";
        }
        else if (symCount == 1) {
            return "Partial Symmetry";
        }
        else {
            return "No Symmetry";
        }
    }

    function getTextColor(uint256 id) public view returns (string memory) {
        if (id < ancients.length) {
            return 'RGB(148,256,209)';
        } else {
            return 'RGB(0,0,0)';
        }
    }

    function getBackgroundColor(uint256 id, uint256 seed, address owner) public view returns (string memory){
        if (id < ancients.length) {
            return 'RGB(128,128,128)';
        }

        uint256 golf = calculateGolfScore(id, seed);
        uint256 red;
        uint256 green;
        uint256 blue;

        if (owner == happyFacePlace) {
            red = 255;
            green = 128;
            blue = 128;
        }
        else if (golf >= 56) {
            red = 255;
            green = 255;
            blue = 255 - (golf - 56) * 4;
        }
        else {
            red = 255 - (56 - golf) * 4;
            green = 255 - (56 - golf) * 4;
            blue = 255;
        }

        return string(abi.encodePacked("RGB(", red.toString(), ",", green.toString(), ",", blue.toString(), ")"));
    }

    string constant headerText = 'data:application/json;ascii,{"description": "We are warrior ChainFaces. Here to watch over you forever, unless we get eaten by lions.","image":"data:image/svg+xml;base64,';
    string constant attributesText = '","attributes":[{"trait_type":"Golf Score","value":';
    string constant symmetryText = '},{"trait_type":"Symmetry","value":"';
    string constant leftFaceText = '"},{"trait_type":"Left Face","value":"';
    string constant leftEyeText = '"},{"trait_type":"Left Eye","value":"';
    string constant mouthText = '"},{"trait_type":"Mouth","value":"';
    string constant rightEyeText = '"},{"trait_type":"Right Eye","value":"';
    string constant rightFaceText = '"},{"trait_type":"Right Face","value":"';
    string constant arenaDurationText = '"},{"trait_type":"Arena Score","value":';
    string constant ancientText = '},{"trait_type":"Ancient","value":"';
    string constant footerText = '"}]}';

    function renderMetadata(bool revealComplete, uint256 id, uint256 seed, uint256 arenaDuration, address owner) external view returns (string memory) {
        if (!revealComplete) {
            return preRevealMetadata();
        }

        uint256 golfScore = calculateGolfScore(id, seed);

        string memory svg = b64Encode(bytes(renderSvg(true, id, seed, arenaDuration, owner)));

        string memory attributes = string(abi.encodePacked(attributesText, golfScore.toString()));
        attributes = string(abi.encodePacked(attributes, symmetryText, calculateSymmetry(id, seed)));
        attributes = string(abi.encodePacked(attributes, leftFaceText, getLeftFace(id, seed)));
        attributes = string(abi.encodePacked(attributes, leftEyeText, getLeftEye(id, seed)));
        attributes = string(abi.encodePacked(attributes, mouthText, getMouth(id, seed)));
        attributes = string(abi.encodePacked(attributes, rightEyeText, getRightEye(id, seed)));
        attributes = string(abi.encodePacked(attributes, rightFaceText, getRightFace(id, seed)));
        attributes = string(abi.encodePacked(attributes, arenaDurationText, arenaDuration.toString()));

        if (id < ancients.length) {
            attributes = string(abi.encodePacked(attributes, ancientText, 'Ancient'));
        } else {
            attributes = string(abi.encodePacked(attributes, ancientText, 'Not Ancient'));
        }

        attributes = string(abi.encodePacked(attributes, footerText));

        return string(abi.encodePacked(headerText, svg, attributes));
    }

    string constant svg1 = "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400' style='background-color:";
    string constant svg2 = "'>";
    string constant svg3 = "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px' fill='";
    string constant svg4 = "'>";
    string constant svg5 = "</text></svg>";

    function renderSvg(bool revealComplete, uint256 id, uint256 seed, uint256 arenaDuration, address owner) public view returns (string memory) {
        if (!revealComplete) {
            return preRevealSvg();
        }

        string memory face = assembleFace(true, id, seed);
        string memory scars;

        if (arenaDuration > 0) {
            scars = generateScars(arenaDuration, seed);
        }

        return string(abi.encodePacked(svg1, getBackgroundColor(id, seed, owner), svg2, scars, svg3, getTextColor(id), svg4, face, svg5));
    }

    string constant scarSymbol = "<symbol id='scar'><g stroke='RGBA(200,40,40,.35)'><text x='40' y='40' dominant-baseline='middle' text-anchor='middle' font-weight='bold' font-size='22px' fill='RGBA(200,40,40,.45)'>++++++</text></g></symbol>";
    string constant scarPlacement1 = "<g transform='translate(";
    string constant scarPlacement2 = ") scale(";
    string constant scarPlacement3 = ") rotate(";
    string constant scarPlacement4 = ")'><use href='#scar'/></g>";

    function generateScars(uint256 arenaDuration, uint256 seed) internal pure returns (string memory) {
        string memory scars;
        string memory scarsTemp;

        uint256 count = arenaDuration / 10;

        if (count > 500) {
            count = 500;
        }

        for (uint256 i = 0; i < count; i++) {
            string memory scar;

            uint256 scarSeed = uint256(keccak256(abi.encodePacked(seed, i)));

            uint256 scale1 = scarSeed % 2;
            uint256 scale2 = scarSeed % 5;
            if (scale1 == 0) {
                scale2 += 5;
            }
            uint256 xShift = scarSeed % 332;
            uint256 yShift = scarSeed % 354;
            int256 rotate = int256(scarSeed % 91) - 45;

            scar = string(abi.encodePacked(scar, scarPlacement1, xShift.toString(), " ", yShift.toString(), scarPlacement2, scale1.toString(), ".", scale2.toString()));

            if (rotate >= 0) {
                scar = string(abi.encodePacked(scar, scarPlacement3, uint256(rotate).toString(), scarPlacement4));
            } else {
                scar = string(abi.encodePacked(scar, scarPlacement3, "-", uint256(0 - rotate).toString(), scarPlacement4));
            }

            scarsTemp = string(abi.encodePacked(scarsTemp, scar));

            if (i % 10 == 0) {
                scars = string(abi.encodePacked(scars, scarsTemp));
                scarsTemp = "";
            }
        }

        return string(abi.encodePacked(scarSymbol, scars, scarsTemp));
    }

    function preRevealMetadata() internal pure returns (string memory) {
        string memory JSON;
        string memory svg = preRevealSvg();
        JSON = string(abi.encodePacked('data:application/json;ascii,{"description": "We are warrior ChainFaces. Here to watch over you forever, unless we get eaten by lions.","image":"data:image/svg+xml;base64,', b64Encode(bytes(svg)), '"}'));
        return JSON;
    }

    function preRevealSvg() internal pure returns (string memory) {
        return "<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400' style='background-color:RGB(255,255,255);'><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' font-size='75px'>?????</text></svg>";
    }

    string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function b64Encode(bytes memory _data) internal pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = TABLE;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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