// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Body SVG generator
library BodyDetail {
    /// @dev Body N°1 => Blood Robot
    function item_1() public pure returns (string memory) {
        return base(body("E31466"), "Robot Blood");
    }

    /// @dev Body N°2 => Moon Robot
    function item_2() public pure returns (string memory) {
        return base(body("2A2C38"), "Robot Moon");
    }

    /// @dev Body N°3 => Robot
    function item_3() public pure returns (string memory) {
        return base(body("FFDAEA"), "Robot");
    }

    /// @dev Body N°4 => Kintaro
    function item_4() public pure returns (string memory) {
        return
            base(
                '<linearGradient id="Neck" gradientUnits="userSpaceOnUse" x1="210.607" y1="386.503" x2="210.607" y2="256.4"> <stop offset="0" style="stop-color:#FFB451"/> <stop offset="0.4231" style="stop-color:#F7E394"/> <stop offset="1" style="stop-color:#FF9B43"/> </linearGradient> <path id="Neck" fill="url(#Neck)" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d=" M175.8,276.8c0.8,10,1.1,20.2-0.7,30.4c-0.5,2.6-2.2,4.9-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2c-8.1,2.3-9.5,12.4-2.1,16.4 c71.9,38.5,146.3,42.5,224.4,7c7.2-3.3,7.3-12.7,0.1-16c-22.3-10.3-43.5-23.1-54.9-29.9c-3-1.8-4.8-5.2-5.1-8.3 c-0.7-7.7-0.7-12.5-0.1-22.2c0.7-11.3,2.6-21.2,4.6-29.3"/> <path id="Shadow" opacity="0.51" enable-background="new " d="M178.1,279c0,0,24.2,35,41,30.6s41.7-21.6,41.7-21.6 c1.2-9.1,1.9-17.1,3.7-26c-4.8,4.9-10.4,9.2-18.8,14.5c-11.3,7.1-22,11.3-29.8,13.3L178.1,279z"/> <linearGradient id="Head" gradientUnits="userSpaceOnUse" x1="222.2862" y1="294.2279" x2="222.2862" y2="63.3842"> <stop offset="0" style="stop-color:#FFB451"/> <stop offset="0.4231" style="stop-color:#F7E394"/> <stop offset="1" style="stop-color:#FF9B43"/> </linearGradient> <path id="Head" fill="url(#Head)" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d=" M313.9,168.8c-0.6-0.8-12.2,8.3-12.2,8.3c0.3-4.9,11.8-53.1-17.3-86c-15.9-17.4-42.2-27.1-69.9-27.7 c-24.5-0.5-48.7,10.9-61.6,24.4c-33.5,35-20.1,98.2-20.1,98.2c0.6,10.9,9.1,63.4,21.3,74.6c0,0,33.7,25.7,42.4,30.6 c8.8,5,17.1,2.3,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l0.2-0.2c6.9-9.1,3.9-5.8,11.2-14.8c1.3-1.5,3-2.2,4.8-1.8 c4.1,0.8,11.7,1.3,13.3-7c2.4-11.5,2.6-25.1,8.6-35.5C311.7,190.8,315.9,184.6,313.9,168.8z"/> <linearGradient id="Ear" gradientUnits="userSpaceOnUse" x1="130.4586" y1="236.7255" x2="130.4586" y2="171.798"> <stop offset="0" style="stop-color:#FFB451"/> <stop offset="0.4231" style="stop-color:#F7E394"/> <stop offset="1" style="stop-color:#FF9B43"/> </linearGradient> <path id="Ear" fill="url(#Ear)" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d=" M141.9,236c0.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7"/> <g id="Ear2"> <path d="M304,174.7c-0.5,1.3-0.3,2.2-1.2,3.1c-0.9,0.8-2.3,2.1-3.2,2.9c-1.8,1.7-4.4,3-6,5s-2.9,4.1-4.2,6.3 c-0.6,1-1.3,2.2-1.9,3.3l-1.7,3.4l-0.2-0.1l1.4-3.6c0.5-1.1,0.9-2.4,1.5-3.5c1.1-2.3,2.3-4.6,3.8-6.8s3-4.4,5.1-5.9 c1-0.8,2.2-1.5,3.2-2.1c1.1-0.6,2.2-1.1,3.1-2L304,174.7z"/> </g> <g id="Body"> <g> <path d="M222.2,339.7c18.6-1.3,37.3-2,55.9-2C259.5,339,240.9,339.8,222.2,339.7z"/> </g> <g> <path d="M142.3,337.2c16.9,0.1,33.7,1,50.6,2.3C176,339.2,159.3,338.5,142.3,337.2z"/> </g> <g> <path d="M199.3,329.2c7.3,14.3,4.6,10.4,17.1,0.1C207.5,339,204.7,346.2,199.3,329.2z"/> </g> <path opacity="0.19" enable-background="new " d="M199.3,329.2c0,0,3.5,9.3,5.3,10.1c1.8,0.8,11.6-10,11.6-10 C209.9,330.9,204,331.1,199.3,329.2z"/> </g> <line fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" x1="132.7" y1="184.2" x2="130.7" y2="182.3"/>',
                "Kintaro"
            );
    }

    function body(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path id="Neck" display="inline"  fill="#',
                    color,
                    '" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d="M175.8,276.8c0.8,10,1.1,20.2-0.7,30.4c-0.5,2.6-2.2,4.9-4.7,6.3c-16.4,8.9-41.4,17.2-70.2,25.2c-8.1,2.3-9.5,12.4-2.1,16.4c71.9,38.5,146.3,42.5,224.4,7c7.2-3.3,7.3-12.7,0.1-16c-22.3-10.3-43.5-23.1-54.9-29.9c-3-1.8-4.8-5.2-5.1-8.3c-0.7-7.7-0.7-12.5-0.1-22.2c0.7-11.3,2.6-21.2,4.6-29.3"  /><path id="Shadow" display="inline" opacity="0.51"  enable-background="new    " d="M178.1,279c0,0,24.2,35,41,30.6s41.7-21.6,41.7-21.6c1.2-9.1,1.9-17.1,3.7-26c-4.8,4.9-10.4,9.2-18.8,14.5c-11.3,7.1-22,11.3-29.8,13.3L178.1,279z"  /><path id="Head" display="inline"  fill="#',
                    color,
                    '" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d="M313.9,168.8c-0.6-0.8-12.2,8.3-12.2,8.3c0.3-4.9,11.8-53.1-17.3-86c-15.9-17.4-42.2-27.1-69.9-27.7c-24.5-0.5-48.7,10.9-61.6,24.4c-33.5,35-20.1,98.2-20.1,98.2c0.6,10.9,9.1,63.4,21.3,74.6c0,0,33.7,25.7,42.4,30.6c8.8,5,17.1,2.3,17.1,2.3c16-5.9,47.7-25.9,56.8-37.6l0.2-0.2c6.9-9.1,3.9-5.8,11.2-14.8c1.3-1.5,3-2.2,4.8-1.8c4.1,0.8,11.7,1.3,13.3-7c2.4-11.5,2.6-25.1,8.6-35.5C311.7,190.8,315.9,184.6,313.9,168.8z"  /><path id="Ear" display="inline"  fill="#',
                    color,
                    '" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-miterlimit="10" d="M141.9,236c0.1,1.1-8.3,3-9.7-12.1s-7.3-31-12.6-48c-3.8-12.2,12.2,6.7,12.2,6.7"  /><g id="Ear2" display="inline" ><path d="M304,174.7c-0.5,1.3-0.3,2.2-1.2,3.1c-0.9,0.8-2.3,2.1-3.2,2.9c-1.8,1.7-4.4,3-6,5s-2.9,4.1-4.2,6.3c-0.6,1-1.3,2.2-1.9,3.3l-1.7,3.4l-0.2-0.1l1.4-3.6c0.5-1.1,0.9-2.4,1.5-3.5c1.1-2.3,2.3-4.6,3.8-6.8s3-4.4,5.1-5.9c1-0.8,2.2-1.5,3.2-2.1c1.1-0.6,2.2-1.1,3.1-2L304,174.7z" /></g><g id="Body" display="inline" ><g><path d="M222.2,339.7c18.6-1.3,37.3-2,55.9-2C259.5,339,240.9,339.8,222.2,339.7z" /></g><g><path d="M142.3,337.2c16.9,0.1,33.7,1,50.6,2.3C176,339.2,159.3,338.5,142.3,337.2z" /></g><g><path d="M199.3,329.2c7.3,14.3,4.6,10.4,17.1,0.1C207.5,339,204.7,346.2,199.3,329.2z" /></g><path opacity="0.19"  enable-background="new    " d="M199.3,329.2c0,0,3.5,9.3,5.3,10.1c1.8,0.8,11.6-10,11.6-10C209.9,330.9,204,331.1,199.3,329.2z" /></g> <line x1="132.69" y1="184.23" x2="130.73" y2="182.28" fill="#e31466" stroke="#000" stroke-linecap="round" stroke-miterlimit="10" stroke-width="2"/>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Robot Blood";
        } else if (id == 2) {
            name = "Robot Moon";
        } else if (id == 3) {
            name = "Robot";
        } else if (id == 4) {
            name = "Kintaro";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="body"><g id="', name, '">', children, "</g></g>"));
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