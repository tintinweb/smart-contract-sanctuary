// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyebrow SVG generator
library EyebrowDetail {
    /// @dev Eyebrow N°1 => Classic
    function item_1() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#150000" d="M213.9,183.1c13.9-5.6,28.6-3,42.7-0.2C244,175,225.8,172.6,213.9,183.1z"/>',
                        '<path fill="#150000" d="M179.8,183.1c-10.7-10.5-27-8.5-38.3-0.5C154.1,179.7,167.6,177.5,179.8,183.1z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°2 => Thick
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M211.3,177.6c0,0,28.6-6.6,36.2-6.2c7.7,0.4,13,3,16.7,6.4c0,0-26.9,5.3-38.9,5.9C213.3,184.3,212.9,183.8,211.3,177.6z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M188.2,177.6c0,0-27.9-6.7-35.4-6.3c-7.5,0.4-12.7,2.9-16.2,6.3c0,0,26.3,5.3,38,6C186.2,184.3,186.7,183.7,188.2,177.6z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°3 => Small
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M236.3,177c-11.3-5.1-18-3.1-20.3-2.1c-0.1,0-0.2,0.1-0.3,0.2c-0.3,0.1-0.5,0.3-0.6,0.3l0,0l0,0l0,0c-1,0.7-1.7,1.7-1.9,3c-0.5,2.6,1.2,5,3.8,5.5s5-1.2,5.5-3.8c0.1-0.3,0.1-0.6,0.1-1C227.4,175.6,236.3,177,236.3,177z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M160.2,176.3c10.8-4.6,17.1-2.5,19.2-1.3c0.1,0,0.2,0.1,0.3,0.2c0.3,0.1,0.4,0.3,0.5,0.3l0,0l0,0l0,0c0.9,0.7,1.6,1.8,1.8,3.1c0.4,2.6-1.2,5-3.7,5.4s-4.7-1.4-5.1-4c-0.1-0.3-0.1-0.6-0.1-1C168.6,175.2,160.2,176.3,160.2,176.3z"/>'
                    )
                )
            );
    }

    /// @notice Return the eyebrow name of the given id
    /// @param id The eyebrow Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Thick";
        } else if (id == 3) {
            name = "Small";
        }
    }

    /// @dev The base SVG for the Eyebrow
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Eyebrow">', children, "</g>"));
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

