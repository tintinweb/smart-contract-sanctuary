// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Background SVG generator
library BackgroundDetail {
    /// @dev background N°1 => Ordinary
    function item_1() public pure returns (string memory) {
        return base("636363", "CFCFCF", "ABABAB");
    }

    /// @dev background N°2 => Unusual
    function item_2() public pure returns (string memory) {
        return base("004A06", "61E89B", "12B55F");
    }

    /// @dev background N°3 => Surprising
    function item_3() public pure returns (string memory) {
        return base("1A4685", "6BF0E3", "00ADC7");
    }

    /// @dev background N°4 => Impressive
    function item_4() public pure returns (string memory) {
        return base("380113", "D87AE6", "8A07BA");
    }

    /// @dev background N°5 => Extraordinary
    function item_5() public pure returns (string memory) {
        return base("A33900", "FAF299", "FF9121");
    }

    /// @dev background N°6 => Phenomenal
    function item_6() public pure returns (string memory) {
        return base("000000", "C000E8", "DED52C");
    }

    /// @dev background N°7 => Artistic
    function item_7() public pure returns (string memory) {
        return base("FF00E3", "E8E18B", "00C4AD");
    }

    /// @dev background N°8 => Unreal
    function item_8() public pure returns (string memory) {
        return base("CCCC75", "54054D", "001E2E");
    }

    /// @notice Return the background name of the given id
    /// @param id The background Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Ordinary";
        } else if (id == 2) {
            name = "Unusual";
        } else if (id == 3) {
            name = "Surprising";
        } else if (id == 4) {
            name = "Impressive";
        } else if (id == 5) {
            name = "Extraordinary";
        } else if (id == 6) {
            name = "Phenomenal";
        } else if (id == 7) {
            name = "Artistic";
        } else if (id == 8) {
            name = "Unreal";
        }
    }

    /// @dev The base SVG for the backgrounds
    function base(
        string memory stop1,
        string memory stop2,
        string memory stop3
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Background">',
                    '<radialGradient id="gradient" cx="210" cy="-134.05" r="210.025" gradientTransform="matrix(1 0 0 -1 0 76)" gradientUnits="userSpaceOnUse">',
                    "<style>",
                    ".color-anim {animation: col 6s infinite;animation-timing-function: ease-in-out;}",
                    "@keyframes col {0%,51% {stop-color:none} 52% {stop-color:#FFBAF7} 53%,100% {stop-color:none}}",
                    "</style>",
                    "<stop offset='0' class='color-anim' style='stop-color:#",
                    stop1,
                    "'/>",
                    "<stop offset='0.66' style='stop-color:#",
                    stop2,
                    "'><animate attributeName='offset' dur='18s' values='0.54;0.8;0.54' repeatCount='indefinite' keyTimes='0;.4;1'/></stop>",
                    "<stop offset='1' style='stop-color:#",
                    stop3,
                    "'><animate attributeName='offset' dur='18s' values='0.86;1;0.86' repeatCount='indefinite'/></stop>",
                    abi.encodePacked(
                        "</radialGradient>",
                        '<path fill="url(#gradient)" d="M390,420H30c-16.6,0-30-13.4-30-30V30C0,13.4,13.4,0,30,0h360c16.6,0,30,13.4,30,30v360C420,406.6,406.6,420,390,420z"/>',
                        '<path id="Border" opacity="0.4" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-miterlimit="10" d="M383.4,410H36.6C21.9,410,10,398.1,10,383.4V36.6C10,21.9,21.9,10,36.6,10h346.8c14.7,0,26.6,11.9,26.6,26.6v346.8 C410,398.1,398.1,410,383.4,410z"/>',
                        '<path id="Mask" opacity="0.1" fill="#48005E" d="M381.4,410H38.6C22.8,410,10,397.2,10,381.4V38.6 C10,22.8,22.8,10,38.6,10h342.9c15.8,0,28.6,12.8,28.6,28.6v342.9C410,397.2,397.2,410,381.4,410z"/>',
                        "</g>"
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

