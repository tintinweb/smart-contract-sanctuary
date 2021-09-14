/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.8.7;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

contract OriginGenie  {


 // thank you to all the projects and devs that have inspired this!! (openPalette, loot, etc...)

    constructor(){}
   

    function generateData(uint _tokenId, string[5] memory _colors, string memory _lat, string memory _long, string memory _dir, string memory _x, string memory _y, string memory _z, string memory _t ) external pure  returns (string memory) {
        
        string[2] memory chunk;
        chunk[0] = _getHead(_colors, _lat, _long); // #aaa #333 #fff #f00 #333
        
        chunk[1] = string(abi.encodePacked(
            _getRects(_colors),   
            text("28", "172", "f", _dir),
            text("241", "150", "c",_x),
            text("241", "170", "c", _y),
            text("241", "190", "c", _z),
            text("24", "292", "t", _t),
            '</svg>'
         ));
         
        string memory _image = string(abi.encodePacked(chunk[0], chunk[1]));         
    
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Origin #',
                        toString(_tokenId),
                        '", "description": "Origins is an on-chain space & time coordinate generator providing Lat/Long, Compass, Digital (XYZ)',
                        ', and Time (DDD:HH:MM:SS) primitives for use in decentralized applications and games.',
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_image)),
                        '", "attributes" :[',
                         '{"trait_type": "Lat", "value": "', _lat, '"},',
                         '{"trait_type": "Long", "value": "', _long, '"},',
                         '{"trait_type": "Magnetic", "value": "', _dir, '"},',
                         '{"trait_type": "XYZ", "value": "', _x,', ',_y,', ',_z,', ', '"},',
                         '{"trait_type": "Time", "value": "', _t, '"}',
                        ']}'
                    )
                )
            )
        );


        return string(abi.encodePacked("data:application/json;base64,", json));
    
    
    }

    function _getRects(string[5] memory _colors) internal pure returns (string memory) {
        return string(abi.encodePacked(    
            rect("100%", "1","0", "58", "none", "e"),
            rect("48%", "10%","20", "147", _colors[1], "d"),
            rect("30%", "20%","232", "130", _colors[2], "d"),
            rect("95%", "20%","10", "245", _colors[3], "d")
            ));
    }

    function _getHead(string[5] memory _colors, string memory _lat, string memory _long) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" class="a">',
            '<style> .a{font-family:"FreeMono", monospace;font-weight:800;} .b{fill:white;font-size:25px;} .c{font-size:14px;}',
            ' .t{font-size:42px;font-weight:200;} .m{fill:#080108;} .d{stroke-width:1;} .e{fill:',_colors[0],';} .f{font-size:22px;} </style>',
            rect("100%","100%","0","0",_colors[4],"m"),
            text("70", "50", "b", _lat),
            text("70", "83", "b", _long)
            ));
    }
    //0top, 1time, 2compass, 3xyz, 4border
    function rect(string memory _width, string memory _height, string memory _x, string memory _y, string memory _fill, string memory _class ) public pure returns(string memory) {
        return string(abi.encodePacked('<rect rx="1" ry="1" class="',_class,'" width="',_width,'" height="',_height,'" x="',_x,'" y="',_y,'" stroke="',_fill,'" /> '));
    }
    
    function text(string memory _x, string memory _y, string memory _class, string memory _text) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<text fill="#fff" x="', _x,'" y="',_y,'" class="', _class,'">',_text,'</text> '));
    }

    function toString(uint256 value) internal pure returns (string memory) {
    
    // From loot (for adventurers)
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