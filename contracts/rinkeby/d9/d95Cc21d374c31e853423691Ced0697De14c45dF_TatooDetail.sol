// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Tatoo SVG generator
library TatooDetail {
    /// @dev Tatoo N°1 => Nothing
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Tatoo N°2 => Freckle
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<circle fill="#E08F56" cx="242.5" cy="220.9" r="1.1"/>',
                        '<circle fill="#E08F56" cx="247.2" cy="223" r="1.1"/>',
                        '<circle fill="#E08F56" cx="238.7" cy="223.7" r="1.1"/>',
                        '<circle fill="#E08F56" cx="242.4" cy="225.8" r="1.1"/>',
                        '<circle fill="#E08F56" cx="153.7" cy="220.6" r="1.1"/>',
                        '<circle fill="#E08F56" cx="158.4" cy="222.7" r="1.1"/>',
                        '<circle fill="#E08F56" cx="149.9" cy="223.4" r="1.1"/>',
                        '<circle fill="#E08F56" cx="153.6" cy="225.5" r="1.1"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°3 => Chin
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M201.3,291.9c0.2-0.6,0.4-1.3,1-1.8c0.3-0.2,0.7-0.4,1.1-0.3c0.4,0.1,0.7,0.4,0.9,0.7c0.4,0.6,0.5,1.4,0.5,2.1 c0,0.7-0.3,1.5-0.8,2c-0.5,0.6-1.3,0.9-2.1,0.8c-0.8-0.1-1.5-0.5-2-0.9c-0.6-0.4-1.1-1-1.5-1.6c-0.4-0.6-0.6-1.4-0.6-2.2 c0.2-1.6,1.4-2.8,2.7-3.4c1.3-0.6,2.8-0.8,4.2-0.5c0.7,0.1,1.4,0.4,2,0.9c0.6,0.5,0.9,1.2,1,1.9c0.2,1.4-0.2,2.9-1.2,3.9 c0.7-1.1,1-2.5,0.7-3.8c-0.2-0.6-0.5-1.2-1-1.5c-0.5-0.4-1.1-0.6-1.7-0.6c-1.3-0.1-2.6,0-3.7,0.6c-1.1,0.5-2,1.5-2.1,2.6 c-0.1,1.1,0.7,2.2,1.6,3c0.5,0.4,1,0.8,1.5,0.8c0.5,0.1,1.1-0.1,1.5-0.5c0.4-0.4,0.7-0.9,0.7-1.6c0.1-0.6,0-1.3-0.3-1.8 c-0.1-0.3-0.4-0.5-0.6-0.6c-0.3-0.1-0.6,0-0.8,0.1C201.9,290.7,201.5,291.3,201.3,291.9z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°4 => Moon
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#7F0068" d="M197.2,142.1c-5.8,0-10.9,2.9-13.9,7.3c2.3-2.3,5.4-3.7,8.9-3.7c7.1,0,12.9,5.9,12.9,13.3 s-5.8,13.3-12.9,13.3c-3.4,0-6.6-1.4-8.9-3.7c3.1,4.4,8.2,7.3,13.9,7.3c9.3,0,16.9-7.6,16.9-16.9S206.6,142.1,197.2,142.1z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°5 => Dot
    function item_5() public pure returns (string memory) {
        return base(string(abi.encodePacked('<circle cx="260.8" cy="215.8" r="2.1"/>')));
    }

    /// @dev Tatoo N°6 => Scars 1
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path id="Scar" fill="#FF7478" d="M236.2,148.7c0,0-7.9,48.9-1.2,97.3C235,246,243.8,201.5,236.2,148.7z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°7 => Scars 2
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M153.8,228.8c0,0,37.7-3.7,39.1-9.4 c0,0,21.5,7.1,59.6,9.4"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="162.6" y1="225.3" x2="162.6" y2="232.4"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="174.1" y1="223.5" x2="174.1" y2="230.7"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="221.2" y1="222.4" x2="221.2" y2="229.5"/>',
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" x1="242.1" y1="225.2" x2="242.1" y2="232.3"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°8 => Ether
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#2B2B2B" stroke="#000000" stroke-miterlimit="10" d="M196.5,159.9l-12.4-5.9l12.4,21.6l12.4-21.6L196.5,159.9z"/>',
                        '<path fill="#2B2B2B" stroke="#000000" stroke-miterlimit="10" d="M207.5,149.6l-11-19.1l-11,19.2l11-5.2L207.5,149.6z"/>',
                        '<path fill="#2B2B2B" stroke="#000000" stroke-miterlimit="10" d="M186.5,152.2l10.1,4.8l10.1-4.8l-10.1-4.8L186.5,152.2z"/>'
                    )
                )
            );
    }

    /// @dev Tatoo N°9 => Tori
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="231.2" y1="221.5" x2="231.2" y2="228.4"/>',
                        '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M228.6,221.2c0,0,3.2,0.4,5.5,0.2"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M237.3,221.5c0,0-3.5,3.1,0,6.3C240.8,231,242.2,221.5,237.3,221.5z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M243.2,227.8l-1.2-6.4c0,0,8.7-2,1,2.8l3.2,3"/>',
                        '<line fill-rule="evenodd" clip-rule="evenodd" fill="#FFEBB4" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" x1="248.5" y1="221" x2="248.5" y2="227.5"/>',
                        '<path d="M254.2,226c0,0,0.1,0,0.1,0c0,0,0.1,0,0.1-0.1l1.3-2.2c0.5-0.9-0.2-2.2-1.2-2c-0.6,0.1-0.8,0.7-0.9,0.8 c-0.1-0.1-0.5-0.5-1.1-0.4c-1,0.2-1.3,1.7-0.4,2.3L254.2,226z"/>'
                    )
                )
            );
    }

    /// @notice Return the tatoo name of the given id
    /// @param id The tatoo Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Nothing";
        } else if (id == 2) {
            name = "Freckle";
        } else if (id == 3) {
            name = "Chin";
        } else if (id == 4) {
            name = "Moon";
        } else if (id == 5) {
            name = "Dot";
        } else if (id == 6) {
            name = "Scars 1";
        } else if (id == 7) {
            name = "Scars 2";
        } else if (id == 8) {
            name = "Ether";
        } else if (id == 9) {
            name = "Tori";
        }
    }

    /// @dev The base SVG for the hair
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Tatoo">', children, "</g>"));
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

