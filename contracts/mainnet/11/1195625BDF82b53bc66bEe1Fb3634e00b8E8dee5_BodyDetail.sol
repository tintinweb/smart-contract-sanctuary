// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Body SVG generator
library BodyDetail {
    /// @dev Body N°1 => Human
    function item_1() public pure returns (string memory) {
        return base("FFEBB4", "FFBE94");
    }

    /// @dev Body N°2 => Shadow
    function item_2() public pure returns (string memory) {
        return base("2d2d2d", "000000");
    }

    /// @dev Body N°3 => Light
    function item_3() public pure returns (string memory) {
        return base("ffffff", "696969");
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Human";
        } else if (id == 2) {
            name = "Shadow";
        } else if (id == 3) {
            name = "Light";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory skin, string memory shadow) private pure returns (string memory) {
        string memory pathBase = "<path fill-rule='evenodd' clip-rule='evenodd' fill='#";
        string memory strokeBase = "' stroke='#000000' stroke-linecap='round' stroke-miterlimit='10'";

        return
            string(
                abi.encodePacked(
                    '<g id="Body">',
                    pathBase,
                    skin,
                    strokeBase,
                    " d='M177.1,287.1c0.8,9.6,0.3,19.3-1.5,29.2c-0.5,2.5-2.1,4.7-4.5,6c-15.7,8.5-41.1,16.4-68.8,24.2c-7.8,2.2-9.1,11.9-2,15.7c69,37,140.4,40.9,215.4,6.7c6.9-3.2,7-12.2,0.1-15.4c-21.4-9.9-42.1-19.7-53.1-26.2c-2.5-1.5-4-3.9-4.3-6.5c-0.7-7.4-0.9-16.1-0.3-25.5c0.7-10.8,2.5-20.3,4.4-28.2'/>",
                    abi.encodePacked(
                        pathBase,
                        shadow,
                        "' d='M177.1,289c0,0,23.2,33.7,39.3,29.5s40.9-20.5,40.9-20.5c1.2-8.7,2.4-17.5,3.5-26.2c-4.6,4.7-10.9,10.2-19,15.3c-10.8,6.8-21,10.4-28.5,12.4L177.1,289z'/>",
                        pathBase,
                        skin,
                        strokeBase,
                        " d='M301.3,193.6c2.5-4.6,10.7-68.1-19.8-99.1c-29.5-29.9-96-34-128.1-0.3s-23.7,105.6-23.7,105.6s12.4,59.8,24.2,72c0,0,32.3,24.8,40.7,29.5c8.4,4.8,16.4,2.2,16.4,2.2c15.4-5.7,25.1-10.9,33.3-17.4'/>",
                        pathBase
                    ),
                    skin,
                    strokeBase,
                    " d='M141.8,247.2c0.1,1.1-11.6,7.4-12.9-7.1c-1.3-14.5-3.9-18.2-9.3-34.5s9.1-8.4,9.1-8.4'/>",
                    abi.encodePacked(
                        pathBase,
                        skin,
                        strokeBase,
                        " d='M254.8,278.1c7-8.6,13.9-17.2,20.9-25.8c1.2-1.4,2.9-2.1,4.6-1.7c3.9,0.8,11.2,1.2,12.8-6.7c2.3-11,6.5-23.5,12.3-33.6c3.2-5.7,0.7-11.4-2.2-15.3c-2.1-2.8-6.1-2.7-7.9,0.2c-2.6,4-5,7.9-7.6,11.9'/>",
                        "<polygon fill-rule='evenodd' clip-rule='evenodd' fill='#",
                        skin,
                        "' points='272,237.4 251.4,270.4 260.9,268.6 276.9,232.4'/>",
                        "<path d='M193.3,196.4c0.8,5.1,1,10.2,1,15.4c0,2.6-0.1,5.2-0.4,7.7c-0.3,2.6-0.7,5.1-1.3,7.6h-0.1c0.1-2.6,0.3-5.1,0.4-7.7c0.2-2.5,0.4-5.1,0.6-7.6c0.1-2.6,0.2-5.1,0.1-7.7C193.5,201.5,193.4,198.9,193.3,196.4L193.3,196.4z'/>",
                        "<path fill='#",
                        shadow
                    ),
                    "' d='M197.8,242.8l-7.9-3.5c-0.4-0.2-0.5-0.7-0.2-1.1l3.2-3.3c0.4-0.4,1-0.5,1.5-0.3l12.7,4.6c0.6,0.2,0.6,1.1-0.1,1.3l-8.7,2.4C198.1,242.9,197.9,242.9,197.8,242.8z'/>",
                    "</g>"
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

