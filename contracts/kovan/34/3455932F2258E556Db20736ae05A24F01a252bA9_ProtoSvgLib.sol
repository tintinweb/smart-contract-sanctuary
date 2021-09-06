/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: OpenZeppelin/[email protected]/Strings

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

// File: protosvglib.sol

// General format for bytes array to Svg shape:
// [0] : id => i1, i2, i3.. unset if '0'.
// [1] : class => c1, c2, c3..
// [2] : if 0, no ending tag '/>', just '>'. Assumes that you close the tag.
// Specifics :
// - styleColor : [3], [4], [5], [6] : RGBA
// - ellipse: 
//   [3] : cx 
//   [4] : cy Where cx,cy defines the center.
//   [5] : rx = X radius
//   [6] : ry = Y radius
// - triangle:
//   [3],[4] x,y 1st point.
//   [5],[6] x,y 2nd point.
//   [7],[8] x,y 3rd point.


contract ProtoSvgLib {
    using Strings for uint256;
    using Strings for uint8;
    bytes constant etherLogo_p0 = hex"fafe01404e4000006a";
    bytes constant etherLogo_p1 = hex"fbfe01404e4000806a";
    bytes constant etherLogo_p2 = hex"fcfe01404e4090006a";
    bytes constant etherLogo_p3 = hex"fdfe01404e4090806a";
    bytes constant etherLogo_p4 = hex"feff0140d0409c0076";
    bytes constant etherLogo_p5 = hex"ffff0140d0409c8076";

    function startSvg(uint _x, uint _y, uint _length, uint _width) external view returns (bytes memory) {
        return abi.encodePacked(
            "<svg viewBox='",
            _x.toString(), " ",
            _y.toString(), " ",
            _length.toString(), " ",
            _width.toString(), "' xmlns='http://www.w3.org/2000/svg'>");
    }

    function endSvg() external view returns (bytes memory) {
        return("</svg>");
    }

    function styleColor(bytes memory _element, bytes memory _b ) external view returns (bytes memory) {
        return abi.encodePacked(
                "<style>", 
                _element, "{ fill: rgba(",
                 byte2uint8(_b, 0).toString(), ",",
                 byte2uint8(_b, 1).toString(), ",",
                 byte2uint8(_b, 2).toString(), ",",
                 byte2uint8(_b, 3).toString(), ");",
                "}",
                "</style>"
        );
    }

    function ellipse(bytes memory _b) external view returns (bytes memory) {
        return abi.encodePacked(
            "<ellipse ", setIdClass(_b),
            " cx='", byte2uint8(_b, 3).toString(),
            "' cy='", byte2uint8(_b, 4).toString(),
            "' rx='", byte2uint8(_b, 5).toString(),
            "' ry='", byte2uint8(_b, 6).toString(),
            "'", endingtag(_b)
        );  
    }

    function path(bytes memory _b, string memory _path) external view returns (bytes memory) {
        return abi.encodePacked(
            "<path ", setIdClass(_b),
            "d='", _path, "'", endingtag(_b)
        );
    }
    // Bonus etherLogo
    function renderEtherLogo() external view returns(bytes memory) {
        return abi.encodePacked(
            this.triangle(etherLogo_p0),
            this.triangle(etherLogo_p1),
            this.triangle(etherLogo_p2),
            this.triangle(etherLogo_p3),
            this.triangle(etherLogo_p4),
            this.triangle(etherLogo_p5)
        );
    }

    function triangle(bytes memory _b) external view returns (bytes memory) {
        return abi.encodePacked(
            "<polygon ", setIdClass(_b),
            " points='",
            byte2uint8(_b, 3).toString(), " ",
            byte2uint8(_b, 4).toString(), " ",
            byte2uint8(_b, 5).toString(), " ",
            byte2uint8(_b, 6).toString(), " ",
            byte2uint8(_b, 7).toString(), " ",
            byte2uint8(_b, 8).toString(),
            "'", endingtag(_b)
        );
    }

// ------ tools -----------

    // @dev define id and class in css format "id='in' class='cn'" 
    // where 0 <= n  >= 255  
    function setIdClass(bytes memory _b) pure internal  returns (bytes memory) {
        bytes memory idText;
        if (byte2uint8(_b, 0) > 0){
            //idText = string(abi.encodePacked(
            idText = abi.encodePacked(
                "id='i",
                byte2uint8(_b, 0).toString(),
                "'"
            );
        }
        return abi.encodePacked(
            idText,
            "class='c", byte2uint8(_b, 1).toString(),
            "'"
        );
    }
    
    // Returns the ending tag as defined in_b[3]
    function endingtag(bytes memory _b) pure internal returns (string memory) {
        if (byte2uint8(_b,2) > 0) {
            return " />";
        }
        return ">";
    }


    // Returns one uint8 in a byte array
    function byte2uint8(bytes memory _data, uint256 _offset) pure internal returns (uint8) { 
        require (_data.length > _offset, "Out of range");
        return uint8(_data[_offset]);
    }
}