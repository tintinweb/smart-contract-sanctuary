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

    /// @dev Eyebrow N°3 => Punk
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M258.6,179.1l-2-2.3 c3.1,0.4,5.6,1,7.6,1.7C264.2,178.6,262,178.8,258.6,179.1z M249.7,176.3c-0.7,0-1.5,0-2.3,0c-7.6,0-36.1,3.2-36.1,3.2 c-0.4,2.9-3.8,3.5,8.1,3c6.6-0.3,23.6-2,32.3-2.8L249.7,176.3z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M140.2,179.1l1.9-2.3 c-3,0.4-5.4,1-7.3,1.7C134.8,178.6,136.9,178.8,140.2,179.1z M148.8,176.3c0.7,0,1.4,0,2.2,0c7.3,0,34.7,3.2,34.7,3.2 c0.4,2.9,3.6,3.5-7.8,3c-6.3-0.3-22.7-2-31-2.8L148.8,176.3z"/>'
                    )
                )
            );
    }

    /// @dev Eyebrow N°4 => Small
    function item_4() public pure returns (string memory) {
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

    /// @dev Eyebrow N°5 => Shaved
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g opacity="0.06">',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M214.5,178 c0,0,20.6-3.5,26.1-3.3s9.4,1.6,12,3.4c0,0-19.4,2.8-28,3.1C215.9,181.6,215.6,181.3,214.5,178z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" stroke="#000000" stroke-miterlimit="10" d="M180.8,178 c0,0-20.1-3.6-25.5-3.4c-5.4,0.2-9.1,1.5-11.7,3.4c0,0,18.9,2.8,27.4,3.2C179.4,181.6,179.8,181.3,180.8,178z"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Eyebrow N°6 => Elektric
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M208.9,177.6c14.6-1.5,47.8-6.5,51.6-6.6l-14.4,4.1l19.7,3.2 c-20.2-0.4-40.9-0.1-59.2,2.6C206.6,179.9,207.6,178.5,208.9,177.6z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M185.1,177.7c-13.3-1.5-43.3-6.7-46.7-6.9l13.1,4.2l-17.8,3.1 c18.2-0.3,37,0.1,53.6,2.9C187.2,180,186.2,178.6,185.1,177.7z"/>'
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
            name = "Punk";
        } else if (id == 4) {
            name = "Small";
        } else if (id == 5) {
            name = "Shaved";
        } else if (id == 6) {
            name = "Elektric";
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

