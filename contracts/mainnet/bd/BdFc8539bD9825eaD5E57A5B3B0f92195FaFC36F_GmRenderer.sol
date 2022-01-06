// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface GmDataInterface {
    struct GmDataSet {
        bytes imageName;
        bytes compressedImage;
        uint256 compressedSize;
    }

    function getSvg(uint256 index) external pure returns (GmDataSet memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {InflateLib} from "./InflateLib.sol";
import {GmDataInterface} from "./GmDataInterface.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface ICourierFont {
    function font() external view returns (string memory);
}

contract GmRenderer {
    ICourierFont private immutable font;
    GmDataInterface private immutable gmData1;
    GmDataInterface private immutable gmData2;

    struct Color {
        bytes hexNum;
        bytes name;
    }

    constructor(
        ICourierFont fontAddress,
        GmDataInterface gmData1Address,
        GmDataInterface gmData2Address
    ) {
        font = fontAddress;
        gmData1 = gmData1Address;
        gmData2 = gmData2Address;
    }

    /// @notice decompresses the GmDataSet
    /// @param gmData, compressed ascii svg data
    function decompress(GmDataInterface.GmDataSet memory gmData)
        public
        pure
        returns (bytes memory, bytes memory)
    {
        (, bytes memory inflated) = InflateLib.puff(
            gmData.compressedImage,
            gmData.compressedSize
        );
        return (gmData.imageName, inflated);
    }

    /// @notice returns an svg filter
    /// @param index, a random number derived from the seed
    function _getFilter(uint256 index) internal pure returns (bytes memory) {

        // 1 || 2 || 3 || 4 || 5 -> noise 5%
        if (
            (index == 1) ||
            (index == 2) ||
            (index == 3) ||
            (index == 4) ||
            (index == 5)
        ) {
            return "noise";
        }

        // 7 || 8 || 98 -> scribble 3%
        if ((index == 7) || (index == 8) || (index == 9)) {
            return "scribble";
        }

        // 10 - 29 -> morph 20%
        if (((100 - index) > 70) && ((100 - index) <= 90)) {
            return "morph";
        }

        // 30 - 39 -> glow 10%
        if (((100 - index) > 60) && ((100 - index) <= 70)) {
            return "glow";
        }

        // 69 -> fractal 1%
        if (index == 69) {
            return "fractal";
        }

        return "none";
    }

    /// @notice returns a background color and font color
    /// @param seed, pseudo random seed
    function _getColors(bytes32 seed)
        internal
        pure
        returns (Color memory bgColor, Color memory fontColor)
    {
        uint32 bgRand = uint32(bytes4(seed)) % 111;
        uint32 fontJitter = uint32(bytes4(seed << 32)) % 5;
        uint32 fontOperation = uint8(bytes1(seed << 64)) % 2;
        uint32 fontRand;
        if (fontOperation == 0) {
            fontRand = (bgRand + (55 + fontJitter)) % 111;
        } else {
            fontRand = (bgRand + (55 - fontJitter)) % 111;
        }

        return (_getColor(bgRand), _getColor(fontRand));
    }

    /// @notice executes string comparison against two strings
    /// @param a, first string
    /// @param b, second string
    function strCompare(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    /// @notice returns the raw svg yielded by seed
    /// @param seed, pseudo random seed
    function svgRaw(bytes32 seed)
        external
        view
        returns (
            bytes memory,
            bytes memory,
            bytes memory,
            bytes memory,
            bytes memory
        )
    {
        uint32 style = uint32(bytes4(seed << 65)) % 69;
        uint32 filterRand = uint32(bytes4(seed << 97)) % 100;
        bytes memory filter = _getFilter(filterRand);

        (Color memory bgColor, Color memory fontColor) = _getColors(seed);

        bytes memory inner;
        bytes memory name;
        if (style < 50) {
            (name, inner) = decompress(gmData1.getSvg(style));
        } else {
            (name, inner) = decompress(gmData2.getSvg(style));
        }

        if ((strCompare(string(name), "Hex")) || (strCompare(string(name), "Binary")) || (strCompare(string(name), "Morse")) || (strCompare(string(name), "Mnemonic"))){
            filter = "none";
        }

        return (
            abi.encodePacked(
                svgPreambleString(bgColor.hexNum, fontColor.hexNum, filter),
                inner,
                "</svg>"
            ),
            name,
            bgColor.name,
            fontColor.name,
            filter
        );
    }

    /// @notice returns the svg filters
    function svgFilterDefs() private view returns (bytes memory) {
        return
            abi.encodePacked(
                '<defs><filter id="fractal" filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%" ><feTurbulence id="turbulence" type="fractalNoise" baseFrequency="0.03" numOctaves="1" ><animate attributeName="baseFrequency" values="0.01;0.4;0.01" dur="100s" repeatCount="indefinite" /></feTurbulence><feDisplacementMap in="SourceGraphic" scale="50"></feDisplacementMap></filter><filter id="morph"><feMorphology operator="dilate" radius="0"><animate attributeName="radius" values="0;5;0" dur="8s" repeatCount="indefinite" /></feMorphology></filter><filter id="glow" filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%" ><feGaussianBlur stdDeviation="5" result="blur2" in="SourceGraphic" /><feMerge><feMergeNode in="blur2" /><feMergeNode in="SourceGraphic" /></feMerge></filter><filter id="noise"><feTurbulence baseFrequency="0.05"/><feColorMatrix type="hueRotate" values="0"><animate attributeName="values" from="0" to="360" dur="1s" repeatCount="indefinite"/></feColorMatrix><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0"/><feDisplacementMap in="SourceGraphic" scale="10"/></filter><filter id="none"><feOffset></feOffset></filter><filter id="scribble"><feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="turbulence"/><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G"/></filter><filter id="tile" x="10" y="10" width="10%" height="10%"><feTile in="SourceGraphic" x="10" y="10" width="10" height="10" /><feTile/></filter></defs>'
            );
    }

    /// @notice returns the svg preamble
    /// @param bgColor, color of the background as hex string
    /// @param fontColor, color of the font as hex string
    /// @param filter, filter for the svg
    function svgPreambleString(
        bytes memory bgColor,
        bytes memory fontColor,
        bytes memory filter
    ) private view returns (bytes memory) {
        return
            abi.encodePacked(
                "<svg viewBox='0 0 640 640' width='100%' height='100%' xmlns='http://www.w3.org/2000/svg'><style> @font-face { font-family: CourierFont; src: url('",
                font.font(),
                "') format('opentype'); }",
                ".base{filter:url(#",
                filter,
                ");fill:",
                fontColor,
                ";font-family:CourierFont;font-size: 16px;}</style>",
                svgFilterDefs(),
                '<rect width="100%" height="100%" fill="',
                bgColor,
                '" /> '
            );
    }

    /// @notice returns the Color yielded by index
    /// @param index, random number determined by seed
    function _getColor(uint32 index)
        internal
        pure
        returns (Color memory color)
    {
        // AUTOGEN:START

        if (index == 0) {
            color.hexNum = "#000000";
            color.name = "Black";
        }

        if (index == 1) {
            color.hexNum = "#004c6a";
            color.name = "Navy Dark Blue";
        }

        if (index == 2) {
            color.hexNum = "#0098d4";
            color.name = "Bayern Blue";
        }

        if (index == 3) {
            color.hexNum = "#00e436";
            color.name = "Lexaloffle Green";
        }

        if (index == 4) {
            color.hexNum = "#1034a6";
            color.name = "Egyptian Blue";
        }

        if (index == 5) {
            color.hexNum = "#008811";
            color.name = "Lush Garden";
        }

        if (index == 6) {
            color.hexNum = "#06d078";
            color.name = "Underwater Fern";
        }

        if (index == 7) {
            color.hexNum = "#1c1cf0";
            color.name = "Bluebonnet";
        }

        if (index == 8) {
            color.hexNum = "#127453";
            color.name = "Green Velvet";
        }

        if (index == 9) {
            color.hexNum = "#14bab4";
            color.name = "Super Rare Jade";
        }

        if (index == 10) {
            color.hexNum = "#111122";
            color.name = "Corbeau";
        }

        if (index == 11) {
            color.hexNum = "#165d95";
            color.name = "Lapis Jewel";
        }

        if (index == 12) {
            color.hexNum = "#16b8f3";
            color.name = "Zima Blue";
        }

        if (index == 13) {
            color.hexNum = "#1ef876";
            color.name = "Synthetic Spearmint";
        }

        if (index == 14) {
            color.hexNum = "#214fc6";
            color.name = "New Car";
        }

        if (index == 15) {
            color.hexNum = "#249148";
            color.name = "Paperboy's Lawn";
        }

        if (index == 16) {
            color.hexNum = "#24da91";
            color.name = "Reptile Green";
        }

        if (index == 17) {
            color.hexNum = "#223311";
            color.name = "Darkest Forest";
        }

        if (index == 18) {
            color.hexNum = "#297f6d";
            color.name = "Mermaid Sea";
        }

        if (index == 19) {
            color.hexNum = "#22cccc";
            color.name = "Mermaid Net";
        }

        if (index == 20) {
            color.hexNum = "#2e2249";
            color.name = "Elderberry";
        }

        if (index == 21) {
            color.hexNum = "#326ab1";
            color.name = "Dover Straits";
        }

        if (index == 22) {
            color.hexNum = "#2bc51b";
            color.name = "Felwood Leaves";
        }

        if (index == 23) {
            color.hexNum = "#391285";
            color.name = "Pixie Powder";
        }

        if (index == 24) {
            color.hexNum = "#2e58e8";
            color.name = "Veteran's Day Blue";
        }

        if (index == 25) {
            color.hexNum = "#419f59";
            color.name = "Chateau Green";
        }

        if (index == 26) {
            color.hexNum = "#45e9c1";
            color.name = "Aphrodite Aqua";
        }

        if (index == 27) {
            color.hexNum = "#424330";
            color.name = "Garden Path";
        }

        if (index == 28) {
            color.hexNum = "#429395";
            color.name = "Catalan";
        }

        if (index == 29) {
            color.hexNum = "#44dd00";
            color.name = "Magic Blade";
        }

        if (index == 30) {
            color.hexNum = "#432e6f";
            color.name = "Her Highness";
        }

        if (index == 31) {
            color.hexNum = "#4477dd";
            color.name = "Andrea Blue";
        }

        if (index == 32) {
            color.hexNum = "#5ad33e";
            color.name = "Verdant Fields";
        }

        if (index == 33) {
            color.hexNum = "#3a18b1";
            color.name = "Indigo Blue";
        }

        if (index == 34) {
            color.hexNum = "#556611";
            color.name = "Forestial Outpost";
        }

        if (index == 35) {
            color.hexNum = "#55bb88";
            color.name = "Bleached Olive";
        }

        if (index == 36) {
            color.hexNum = "#5500ee";
            color.name = "Tezcatlipoca Blue";
        }

        if (index == 37) {
            color.hexNum = "#545554";
            color.name = "Carbon Copy";
        }

        if (index == 38) {
            color.hexNum = "#58a0bc";
            color.name = "Dupain";
        }

        if (index == 39) {
            color.hexNum = "#55ff22";
            color.name = "Traffic Green";
        }

        if (index == 40) {
            color.hexNum = "#5b3e90";
            color.name = "Daisy Bush";
        }

        if (index == 41) {
            color.hexNum = "#6688ff";
            color.name = "Deep Denim";
        }

        if (index == 42) {
            color.hexNum = "#61e160";
            color.name = "Lightish Green";
        }

        if (index == 43) {
            color.hexNum = "#6a31ca";
            color.name = "Sagat Purple";
        }

        if (index == 44) {
            color.hexNum = "#667c3e";
            color.name = "Military Green";
        }

        if (index == 45) {
            color.hexNum = "#68c89d";
            color.name = "Intense Jade";
        }

        if (index == 46) {
            color.hexNum = "#6d1008";
            color.name = "Chestnut Brown";
        }

        if (index == 47) {
            color.hexNum = "#696374";
            color.name = "Purple Punch";
        }

        if (index == 48) {
            color.hexNum = "#6fb7e0";
            color.name = "Life Force";
        }

        if (index == 49) {
            color.hexNum = "#770044";
            color.name = "Dawn of the Fairies";
        }

        if (index == 50) {
            color.hexNum = "#7851a9";
            color.name = "Royal Lavender";
        }

        if (index == 51) {
            color.hexNum = "#769c18";
            color.name = "Luminescent Green";
        }

        if (index == 52) {
            color.hexNum = "#7be892";
            color.name = "Ragweed";
        }

        if (index == 53) {
            color.hexNum = "#703be7";
            color.name = "Bluish Purple";
        }

        if (index == 54) {
            color.hexNum = "#7b8b5d";
            color.name = "Sage Leaves";
        }

        if (index == 55) {
            color.hexNum = "#82d9c5";
            color.name = "Tender Turquoise";
        }

        if (index == 56) {
            color.hexNum = "#7e2530";
            color.name = "Scarlet Shade";
        }

        if (index == 57) {
            color.hexNum = "#83769c";
            color.name = "Voxatron Purple";
        }

        if (index == 58) {
            color.hexNum = "#88cc00";
            color.name = "Fabulous Frog";
        }

        if (index == 59) {
            color.hexNum = "#881166";
            color.name = "Possessed Purple";
        }

        if (index == 60) {
            color.hexNum = "#8756e4";
            color.name = "Gloomy Purple";
        }

        if (index == 61) {
            color.hexNum = "#93b13d";
            color.name = "Green Tea Ice Cream";
        }

        if (index == 62) {
            color.hexNum = "#90fda9";
            color.name = "Foam Green";
        }

        if (index == 63) {
            color.hexNum = "#914b13";
            color.name = "Parasite Brown";
        }

        if (index == 64) {
            color.hexNum = "#919c81";
            color.name = "Whispering Willow";
        }

        if (index == 65) {
            color.hexNum = "#99eeee";
            color.name = "Freezy Breezy";
        }

        if (index == 66) {
            color.hexNum = "#983d53";
            color.name = "Algae Red";
        }

        if (index == 67) {
            color.hexNum = "#9c87c1";
            color.name = "Petrified Purple";
        }

        if (index == 68) {
            color.hexNum = "#98da2c";
            color.name = "Effervescent Lime";
        }

        if (index == 69) {
            color.hexNum = "#942193";
            color.name = "Acai Juice";
        }

        if (index == 70) {
            color.hexNum = "#a675fe";
            color.name = "Purple Illusionist";
        }

        if (index == 71) {
            color.hexNum = "#a4c161";
            color.name = "Jungle Juice";
        }

        if (index == 72) {
            color.hexNum = "#aa00cc";
            color.name = "Ferocious Fuchsia";
        }

        if (index == 73) {
            color.hexNum = "#a85e39";
            color.name = "Earthen Jug";
        }

        if (index == 74) {
            color.hexNum = "#aaa9a4";
            color.name = "Ellie Grey";
        }

        if (index == 75) {
            color.hexNum = "#aaee11";
            color.name = "Glorious Green Glitter";
        }

        if (index == 76) {
            color.hexNum = "#ad4379";
            color.name = "Mystic Maroon";
        }

        if (index == 77) {
            color.hexNum = "#b195e4";
            color.name = "Dreamy Candy Forest";
        }

        if (index == 78) {
            color.hexNum = "#b1dd52";
            color.name = "Conifer";
        }

        if (index == 79) {
            color.hexNum = "#c034af";
            color.name = "Pink Perennial";
        }

        if (index == 80) {
            color.hexNum = "#b78727";
            color.name = "University of California Gold";
        }

        if (index == 81) {
            color.hexNum = "#b9d08b";
            color.name = "Young Leaves";
        }

        if (index == 82) {
            color.hexNum = "#bb11ee";
            color.name = "Promiscuous Pink";
        }

        if (index == 83) {
            color.hexNum = "#c06960";
            color.name = "Tapestry Red";
        }

        if (index == 84) {
            color.hexNum = "#bebbc9";
            color.name = "Silverberry";
        }

        if (index == 85) {
            color.hexNum = "#bf0a30";
            color.name = "Old Glory Red";
        }

        if (index == 86) {
            color.hexNum = "#c35b99";
            color.name = "Llilacquered";
        }

        if (index == 87) {
            color.hexNum = "#caa906";
            color.name = "Christmas Gold";
        }

        if (index == 88) {
            color.hexNum = "#c2f177";
            color.name = "Cucumber Milk";
        }

        if (index == 89) {
            color.hexNum = "#d648d7";
            color.name = "Pinkish Purple";
        }

        if (index == 90) {
            color.hexNum = "#cf9346";
            color.name = "Fleshtone Shade Wash";
        }

        if (index == 91) {
            color.hexNum = "#d3e0b1";
            color.name = "Rockmelon Rind";
        }

        if (index == 92) {
            color.hexNum = "#d22d1d";
            color.name = "Pure Red";
        }

        if (index == 93) {
            color.hexNum = "#d28083";
            color.name = "Galah";
        }

        if (index == 94) {
            color.hexNum = "#d5c7e8";
            color.name = "Foggy Love";
        }

        if (index == 95) {
            color.hexNum = "#db1459";
            color.name = "Rubylicious";
        }

        if (index == 96) {
            color.hexNum = "#dd66bb";
            color.name = "Pink Charge";
        }

        if (index == 97) {
            color.hexNum = "#e2b227";
            color.name = "Gold Tips";
        }

        if (index == 98) {
            color.hexNum = "#ee0099";
            color.name = "Love Vessel";
        }

        if (index == 99) {
            color.hexNum = "#dd55ff";
            color.name = "Flaming Flamingo";
        }

        if (index == 100) {
            color.hexNum = "#eda367";
            color.name = "Adventure Orange";
        }

        if (index == 101) {
            color.hexNum = "#e9f1d0";
            color.name = "Yellowish White";
        }

        if (index == 102) {
            color.hexNum = "#ef3939";
            color.name = "Vivaldi Red";
        }

        if (index == 103) {
            color.hexNum = "#e78ea5";
            color.name = "Underwater Flare";
        }

        if (index == 104) {
            color.hexNum = "#eedd11";
            color.name = "Yellow Buzzing";
        }

        if (index == 105) {
            color.hexNum = "#ee2277";
            color.name = "Furious Fuchsia";
        }

        if (index == 106) {
            color.hexNum = "#f075e6";
            color.name = "Lian Hong Lotus Pink";
        }

        if (index == 107) {
            color.hexNum = "#f7c34c";
            color.name = "Creamy Sweet Corn";
        }

        if (index == 108) {
            color.hexNum = "#fc0fc0";
            color.name = "CGA Pink";
        }

        if (index == 109) {
            color.hexNum = "#ff6622";
            color.name = "Sparrows Fire";
        }

        if (index == 110) {
            color.hexNum = "#fbaf8d";
            color.name = "Orange Grove";
        }

        // AUTOGEN:END
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

//
// inflate content script:
// var pako = require('pako')
// var deflate = (str) => [str.length,Buffer.from(pako.deflateRaw(Buffer.from(str, 'utf-8'), {level: 9})).toString('hex')]
//

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Bit accumulator (can use up to 20 bits)
        uint256 val;

        // Load at least need bits into val
        val = s.bitbuf;
        while (s.bitcnt < need) {
            if (s.incnt == s.input.length) {
                // Out of input
                return (ErrorCode.ERR_NOT_TERMINATED, 0);
            }

            // Load eight bits
            val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
            s.bitcnt += 8;
        }

        // Drop need bits and update buffer, always zero to seven bits left
        s.bitbuf = val >> need;
        s.bitcnt -= need;

        // Return need bits, zeroing the bits above that
        uint256 ret = (val & ((1 << need) - 1));
        return (ErrorCode.ERR_NONE, ret);
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        // Length of stored block
        uint256 len;

        // Discard leftover bits from current byte (assumes s.bitcnt < 8)
        s.bitbuf = 0;
        s.bitcnt = 0;

        // Get length and check against its one's complement
        if (s.incnt + 4 > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        len = uint256(uint8(s.input[s.incnt++]));
        len |= uint256(uint8(s.input[s.incnt++])) << 8;

        if (
            uint8(s.input[s.incnt++]) != (~len & 0xFF) ||
            uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)
        ) {
            // Didn't match complement!
            return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
        }

        // Copy len bytes from in to out
        if (s.incnt + len > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        if (s.outcnt + len > s.output.length) {
            // Not enough output space
            return ErrorCode.ERR_OUTPUT_EXHAUSTED;
        }
        while (len != 0) {
            // Note: Solidity reverts on underflow, so we decrement here
            len -= 1;
            s.output[s.outcnt++] = s.input[s.incnt++];
        }

        // Done with a valid stored block
        return ErrorCode.ERR_NONE;
    }

    function _decode(State memory s, Huffman memory h)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Current number of bits in code
        uint256 len;
        // Len bits being decoded
        uint256 code = 0;
        // First code of length len
        uint256 first = 0;
        // Number of codes of length len
        uint256 count;
        // Index of first code of length len in symbol table
        uint256 index = 0;
        // Error code
        ErrorCode err;

        for (len = 1; len <= MAXBITS; len++) {
            // Get next bit
            uint256 tempCode;
            (err, tempCode) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, 0);
            }
            code |= tempCode;
            count = h.counts[len];

            // If length len, return symbol
            if (code < first + count) {
                return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
            }
            // Else update for next length
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }

        // Ran out of codes
        return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        // Current symbol when stepping through lengths[]
        uint256 symbol;
        // Current length when stepping through h.counts[]
        uint256 len;
        // Number of possible codes left of current length
        uint256 left;
        // Offsets in symbol table for each length
        uint256[MAXBITS + 1] memory offs;

        // Count number of codes of each length
        for (len = 0; len <= MAXBITS; len++) {
            h.counts[len] = 0;
        }
        for (symbol = 0; symbol < n; symbol++) {
            // Assumes lengths are within bounds
            h.counts[lengths[start + symbol]]++;
        }
        // No codes!
        if (h.counts[0] == n) {
            // Complete, but decode() will fail
            return (ErrorCode.ERR_NONE);
        }

        // Check for an over-subscribed or incomplete set of lengths

        // One possible code of zero length
        left = 1;

        for (len = 1; len <= MAXBITS; len++) {
            // One more bit, double codes left
            left <<= 1;
            if (left < h.counts[len]) {
                // Over-subscribed--return error
                return ErrorCode.ERR_CONSTRUCT;
            }
            // Deduct count from possible codes

            left -= h.counts[len];
        }

        // Generate offsets into symbol table for each length for sorting
        offs[1] = 0;
        for (len = 1; len < MAXBITS; len++) {
            offs[len + 1] = offs[len] + h.counts[len];
        }

        // Put symbols in table sorted by length, by symbol order within each length
        for (symbol = 0; symbol < n; symbol++) {
            if (lengths[start + symbol] != 0) {
                h.symbols[offs[lengths[start + symbol]]++] = symbol;
            }
        }

        // Left > 0 means incomplete
        return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        // Decoded symbol
        uint256 symbol;
        // Length for copy
        uint256 len;
        // Distance for copy
        uint256 dist;
        // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
        // Size base for length codes 257..285
        uint16[29] memory lens =
            [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
        // Extra bits for length codes 257..285
        uint8[29] memory lext =
            [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
        // Offset base for distance codes 0..29
        uint16[30] memory dists =
            [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
        // Extra bits for distance codes 0..29
        uint8[30] memory dext =
            [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
        // Error code
        ErrorCode err;

        // Decode literals and length/distance pairs
        while (symbol != 256) {
            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return err;
            }

            if (symbol < 256) {
                // Literal: symbol is the byte
                // Write out the literal
                if (s.outcnt == s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                s.output[s.outcnt] = bytes1(uint8(symbol));
                s.outcnt++;
            } else if (symbol > 256) {
                uint256 tempBits;
                // Length
                // Get and compute length
                symbol -= 257;
                if (symbol >= 29) {
                    // Invalid fixed code
                    return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                }

                (err, tempBits) = bits(s, lext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                len = lens[symbol] + tempBits;

                // Get and check distance
                (err, symbol) = _decode(s, distcode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }
                (err, tempBits) = bits(s, dext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                dist = dists[symbol] + tempBits;
                if (dist > s.outcnt) {
                    // Distance too far back
                    return ErrorCode.ERR_DISTANCE_TOO_FAR;
                }

                // Copy length bytes from distance bytes back
                if (s.outcnt + len > s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                while (len != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    len -= 1;
                    s.output[s.outcnt] = s.output[s.outcnt - dist];
                    s.outcnt++;
                }
            } else {
                s.outcnt += len;
            }
        }

        // Done with a valid fixed or dynamic block
        return ErrorCode.ERR_NONE;
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        // Build fixed Huffman tables
        // TODO this is all a compile-time constant
        uint256 symbol;
        uint256[] memory lengths = new uint256[](FIXLCODES);

        // Literal/length table
        for (symbol = 0; symbol < 144; symbol++) {
            lengths[symbol] = 8;
        }
        for (; symbol < 256; symbol++) {
            lengths[symbol] = 9;
        }
        for (; symbol < 280; symbol++) {
            lengths[symbol] = 7;
        }
        for (; symbol < FIXLCODES; symbol++) {
            lengths[symbol] = 8;
        }

        _construct(s.lencode, lengths, FIXLCODES, 0);

        // Distance table
        for (symbol = 0; symbol < MAXDCODES; symbol++) {
            lengths[symbol] = 5;
        }

        _construct(s.distcode, lengths, MAXDCODES, 0);

        return ErrorCode.ERR_NONE;
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        // Decode data until end-of-block code
        return _codes(s, s.lencode, s.distcode);
    }

    function _build_dynamic_lengths(State memory s)
        private
        pure
        returns (ErrorCode, uint256[] memory)
    {
        uint256 ncode;
        // Index of lengths[]
        uint256 index;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Error code
        ErrorCode err;
        // Permutation of code length codes
        uint8[19] memory order =
            [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

        (err, ncode) = bits(s, 4);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
        }
        ncode += 4;

        // Read code length code lengths (really), missing lengths are zero
        for (index = 0; index < ncode; index++) {
            (err, lengths[order[index]]) = bits(s, 3);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
        }
        for (; index < 19; index++) {
            lengths[order[index]] = 0;
        }

        return (ErrorCode.ERR_NONE, lengths);
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        // Number of lengths in descriptor
        uint256 nlen;
        uint256 ndist;
        // Index of lengths[]
        uint256 index;
        // Error code
        ErrorCode err;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Length and distance codes
        Huffman memory lencode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
        Huffman memory distcode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
        uint256 tempBits;

        // Get number of lengths in each table, check lengths
        (err, nlen) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        nlen += 257;
        (err, ndist) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        ndist += 1;

        if (nlen > MAXLCODES || ndist > MAXDCODES) {
            // Bad counts
            return (
                ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES,
                lencode,
                distcode
            );
        }

        (err, lengths) = _build_dynamic_lengths(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }

        // Build huffman table for code lengths codes (use lencode temporarily)
        err = _construct(lencode, lengths, 19, 0);
        if (err != ErrorCode.ERR_NONE) {
            // Require complete code set here
            return (
                ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE,
                lencode,
                distcode
            );
        }

        // Read length/literal and distance code length tables
        index = 0;
        while (index < nlen + ndist) {
            // Decoded value
            uint256 symbol;
            // Last length to repeat
            uint256 len;

            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return (err, lencode, distcode);
            }

            if (symbol < 16) {
                // Length in 0..15
                lengths[index++] = symbol;
            } else {
                // Repeat instruction
                // Assume repeating zeros
                len = 0;
                if (symbol == 16) {
                    // Repeat last length 3..6 times
                    if (index == 0) {
                        // No last length!
                        return (
                            ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH,
                            lencode,
                            distcode
                        );
                    }
                    // Last length
                    len = lengths[index - 1];
                    (err, tempBits) = bits(s, 2);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else if (symbol == 17) {
                    // Repeat zero 3..10 times
                    (err, tempBits) = bits(s, 3);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else {
                    // == 18, repeat zero 11..138 times
                    (err, tempBits) = bits(s, 7);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 11 + tempBits;
                }

                if (index + symbol > nlen + ndist) {
                    // Too many lengths!
                    return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                }
                while (symbol != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    symbol -= 1;

                    // Repeat last or zero symbol times
                    lengths[index++] = len;
                }
            }
        }

        // Check for end-of-block code -- there better be one!
        if (lengths[256] == 0) {
            return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
        }

        // Build huffman table for literal/length codes
        err = _construct(lencode, lengths, nlen, 0);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                nlen != lencode.counts[0] + lencode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        // Build huffman table for distance codes
        err = _construct(distcode, lengths, ndist, nlen);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                ndist != distcode.counts[0] + distcode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        return (ErrorCode.ERR_NONE, lencode, distcode);
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        // Length and distance codes
        Huffman memory lencode;
        Huffman memory distcode;
        // Error code
        ErrorCode err;

        (err, lencode, distcode) = _build_dynamic(s);
        if (err != ErrorCode.ERR_NONE) {
            return err;
        }

        // Decode data until end-of-block code
        return _codes(s, lencode, distcode);
    }

    function puff(bytes memory source, uint256 destlen)
        internal
        pure
        returns (ErrorCode, bytes memory)
    {
        // Input/output state
        State memory s =
            State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
        // Temp: last bit
        uint256 last;
        // Temp: block type bit
        uint256 t;
        // Error code
        ErrorCode err;

        // Build fixed Huffman tables
        err = _build_fixed(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
        }

        // Process blocks until last block or error
        while (last == 0) {
            // One if last block
            (err, last) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Block type 0..3
            (err, t) = bits(s, 2);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            err = (
                t == 0
                    ? _stored(s)
                    : (
                        t == 1
                            ? _fixed(s)
                            : (
                                t == 2
                                    ? _dynamic(s)
                                    : ErrorCode.ERR_INVALID_BLOCK_TYPE
                            )
                    )
            );
            // type == 3, invalid

            if (err != ErrorCode.ERR_NONE) {
                // Return with error
                break;
            }
        }

        return (err, s.output);
    }
}