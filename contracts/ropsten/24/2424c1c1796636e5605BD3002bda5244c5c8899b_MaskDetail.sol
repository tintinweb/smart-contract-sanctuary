// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Masks SVG generator
library MaskDetail {
    /// @dev Mask N°1 => Maskless
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Mask N°2 => Classic
    function item_2() public pure returns (string memory) {
        return base(classicMask("575673"));
    }

    /// @dev Mask N°3 => Blue
    function item_3() public pure returns (string memory) {
        return base(classicMask(Colors.BLUE));
    }

    /// @dev Mask N°4 => Pink
    function item_4() public pure returns (string memory) {
        return base(classicMask(Colors.PINK));
    }

    /// @dev Mask N°5 => Black
    function item_5() public pure returns (string memory) {
        return base(classicMask(Colors.BLACK));
    }

    /// @dev Mask N°6 => Bandage White
    function item_6() public pure returns (string memory) {
        return base(string(abi.encodePacked(classicMask("F5F5F5"), bandage())));
    }

    /// @dev Mask N°7 => Bandage Classic
    function item_7() public pure returns (string memory) {
        return base(string(abi.encodePacked(classicMask("575673"), bandage())));
    }

    /// @dev Mask N°8 => Nihon
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        classicMask("F5F5F5"),
                        '<ellipse opacity="0.87" fill="#FF0039" cx="236.1" cy="259.8" rx="13.4" ry="14.5"/>'
                    )
                )
            );
    }

    /// @dev Generate classic mask SVG with the given color
    function classicMask(string memory color) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="#',
                    color,
                    '" stroke="#000000" stroke-miterlimit="10" d=" M175.7,317.7c0,0,20,15.1,82.2,0c0,0-1.2-16.2,3.7-46.8l14-18.7c0,0-41.6-27.8-77.6-37.1c-1.1-0.3-3-0.7-4-0.2 c-19.1,8.1-51.5,33-51.5,33s7.5,20.9,9.9,22.9s24.8,19.4,24.8,19.4s0,0,0,0.1C177.3,291.2,178,298.3,175.7,317.7z"/>',
                    '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M177.1,290.1 c0,0,18.3,14.7,26.3,15s15.1-3.8,15.9-4.3c0.9-0.4,11.6-4.5,25.2-14.1"/>',
                    '<line fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="266.6" y1="264.4" x2="254.5" y2="278.7"/>',
                    '<path opacity="0.21" d="M197.7,243.5l-7.9-3.5c-0.4-0.2-0.5-0.7-0.2-1.1l3.2-3.3 c0.4-0.4,1-0.5,1.5-0.3l12.7,4.6c0.6,0.2,0.6,1.1-0.1,1.3l-8.7,2.4C198,243.6,197.8,243.6,197.7,243.5z"/>',
                    '<path opacity="0.24" fill-rule="evenodd" clip-rule="evenodd" d="M177.2,291.1 c0,0,23,32.3,39.1,28.1s41.9-20.9,41.9-20.9c1.2-8.7,2.1-18.9,3.2-27.6c-4.6,4.7-12.8,13.2-20.9,18.3c-5,3.1-21.2,14.5-34.9,16 C198.3,305.8,177.2,291.1,177.2,291.1z"/>'
                )
            );
    }

    /// @dev Generate bandage SVG
    function bandage() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M142.9,247.9c34.3-21.9,59.3-27.4,92.4-18.5 M266.1,264.1c-21-16.2-60.8-36.4-73.9-29.1c-12.8,7.1-36.4,15.6-45.8,22.7 M230.9,242.8c-32.4,2.5-54.9,0.1-81.3,22.7 M259.8,272.3c-19.7-13.9-46.1-24.1-70.3-25.9 M211.6,250.1c-18.5,1.9-41.8,11.2-56.7,22 M256.7,276.1c-46-11.9-50.4-25.6-94,2.7 M229,267.5c-19.9,0.3-42,9.7-60.6,15.9 M238.4,290.6c-11-3.9-39.3-14.6-51.2-14 M214.5,282.5c-10.3-2.8-23,7.6-30.7,12.6 M221.6,299.8c-3.8-5.5-22.1-7.1-27-11.4 M176.2,312.4c8.2,7.3,65.1,6.4,81.2-2.6 M177.3,305.3c11.1,3.6,15.5,4.2,34.6,2.9 c14.5-1,33.2-2.7,46.2-9.2 M224.4,298.4c9,0,25.6-3.3,34.1-6 M249,285.8c3.6-0.2,7.1-1,10.5-2.3 M215.1,225.7 c-6-1.3-11.9-2.3-17.9-3.6c-4.8-1-9.8-2.1-14.7-1.3"/>'
                )
            );
    }

    /// @notice Return the mask name of the given id
    /// @param id The mask Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Maskless";
        } else if (id == 2) {
            name = "Classic";
        } else if (id == 3) {
            name = "Blue";
        } else if (id == 4) {
            name = "Pink";
        } else if (id == 5) {
            name = "Black";
        } else if (id == 6) {
            name = "Bandage White";
        } else if (id == 7) {
            name = "Bandage Classic";
        } else if (id == 8) {
            name = "Nihon";
        }
    }

    /// @dev The base SVG for the eyes
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Mask">', children, "</g>"));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma abicoder v2;

/// @title Color constants
library Colors {
    string internal constant BLACK = "33333D";
    string internal constant BLACK_DEEP = "000000";
    string internal constant BLUE = "7FBCFF";
    string internal constant BROWN = "735742";
    string internal constant GRAY = "7F8B8C";
    string internal constant GREEN = "2FC47A";
    string internal constant PINK = "FF78A9";
    string internal constant PURPLE = "A839A4";
    string internal constant RED = "D9005E";
    string internal constant SAIKI = "F02AB6";
    string internal constant WHITE = "F7F7F7";
    string internal constant YELLOW = "EFED8F";
}