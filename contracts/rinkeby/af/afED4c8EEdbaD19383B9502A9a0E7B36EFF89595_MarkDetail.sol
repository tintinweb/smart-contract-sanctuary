// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mark SVG generator
library MarkDetail {
    /// @dev Mark N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Mark N°2 => Blush Cheeks
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g opacity="0.71">',
                        '<ellipse fill="#FF7478" cx="257.6" cy="221.2" rx="11.6" ry="3.6"/>',
                        '<ellipse fill="#FF7478" cx="146.9" cy="221.5" rx="9.6" ry="3.6"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Mark N°3 => Dark Circle
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M160.1,223.2c4.4,0.2,8.7-1.3,12.7-3.2C169.3,222.7,164.4,223.9,160.1,223.2z"/>',
                        '<path d="M156.4,222.4c-2.2-0.4-4.3-1.6-6.1-3C152.3,220.3,154.4,221.4,156.4,222.4z"/>',
                        '<path d="M234.5,222.7c4.9,0.1,9.7-1.4,14.1-3.4C244.7,222.1,239.3,223.4,234.5,222.7z"/>',
                        '<path d="M230.3,221.9c-2.5-0.4-4.8-1.5-6.7-2.9C225.9,219.9,228.2,221,230.3,221.9z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°4 => Chin scar
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#E83342" d="M195.5,285.7l17,8.9C212.5,294.6,206.1,288.4,195.5,285.7z"/>',
                        '<path fill="#E83342" d="M211.2,285.7l-17,8.9C194.1,294.6,200.6,288.4,211.2,285.7z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°5 => Blush
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse opacity="0.52" fill-rule="evenodd" clip-rule="evenodd" fill="#FF7F83" cx="196.8" cy="222" rx="32.8" ry="1.9"/>'
                    )
                )
            );
    }

    /// @dev Mark N°6 => Chin
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M201.3,291.9c0.2-0.6,0.4-1.3,1-1.8c0.3-0.2,0.7-0.4,1.1-0.3c0.4,0.1,0.7,0.4,0.9,0.7c0.4,0.6,0.5,1.4,0.5,2.1 c0,0.7-0.3,1.5-0.8,2c-0.5,0.6-1.3,0.9-2.1,0.8c-0.8-0.1-1.5-0.5-2-0.9c-0.6-0.4-1.1-1-1.5-1.6c-0.4-0.6-0.6-1.4-0.6-2.2 c0.2-1.6,1.4-2.8,2.7-3.4c1.3-0.6,2.8-0.8,4.2-0.5c0.7,0.1,1.4,0.4,2,0.9c0.6,0.5,0.9,1.2,1,1.9c0.2,1.4-0.2,2.9-1.2,3.9 c0.7-1.1,1-2.5,0.7-3.8c-0.2-0.6-0.5-1.2-1-1.5c-0.5-0.4-1.1-0.6-1.7-0.6c-1.3-0.1-2.6,0-3.7,0.6c-1.1,0.5-2,1.5-2.1,2.6 c-0.1,1.1,0.7,2.2,1.6,3c0.5,0.4,1,0.8,1.5,0.8c0.5,0.1,1.1-0.1,1.5-0.5c0.4-0.4,0.7-0.9,0.7-1.6c0.1-0.6,0-1.3-0.3-1.8 c-0.1-0.3-0.4-0.5-0.6-0.6c-0.3-0.1-0.6,0-0.8,0.1C201.9,290.7,201.5,291.3,201.3,291.9z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°7 => Yinyang
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.86" d="M211.5,161.1c0-8.2-6.7-14.9-14.9-14.9c-0.2,0-0.3,0-0.5,0l0,0 H196c-0.1,0-0.2,0-0.2,0c-0.2,0-0.4,0-0.5,0c-7.5,0.7-13.5,7.1-13.5,14.8c0,8.2,6.7,14.9,14.9,14.9 C204.8,176,211.5,169.3,211.5,161.1z M198.4,154.2c0,1-0.8,1.9-1.9,1.9c-1,0-1.9-0.8-1.9-1.9c0-1,0.8-1.9,1.9-1.9 C197.6,152.3,198.4,153.1,198.4,154.2z M202.9,168.2c0,3.6-3.1,6.6-6.9,6.6l0,0c-7.3-0.3-13.2-6.3-13.2-13.7c0-6,3.9-11.2,9.3-13 c-2,1.3-3.4,3.6-3.4,6.2c0,4,3.3,7.3,7.3,7.3l0,0C199.8,161.6,202.9,164.5,202.9,168.2z M196.6,170.3c-1,0-1.9-0.8-1.9-1.9 c0-1,0.8-1.9,1.9-1.9c1,0,1.9,0.8,1.9,1.9C198.4,169.5,197.6,170.3,196.6,170.3z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°8 => Scar
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path id="Scar" fill="#FF7478" d="M236.2,148.7c0,0-7.9,48.9-1.2,97.3C235,246,243.8,201.5,236.2,148.7z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°9 => Sun
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<circle fill="#7F0068" cx="195.8" cy="161.5" r="11.5"/>',
                        '<polygon fill="#7F0068" points="195.9,142.4 192.4,147.8 199.3,147.8"/>',
                        '<polygon fill="#7F0068" points="209.6,158.1 209.6,164.9 214.9,161.5"/>',
                        '<polygon fill="#7F0068" points="195.9,180.6 199.3,175.2 192.4,175.2"/>',
                        '<polygon fill="#7F0068" points="182.1,158.1 176.8,161.5 182.1,164.9"/>',
                        '<polygon fill="#7F0068" points="209.3,148 203.1,149.4 208,154.2"/>',
                        '<polygon fill="#7F0068" points="209.3,175 208,168.8 203.1,173.6"/>',
                        '<polygon fill="#7F0068" points="183.7,168.8 182.4,175 188.6,173.6"/>',
                        '<polygon fill="#7F0068" points="188.6,149.4 182.4,148 183.7,154.2"/>'
                    )
                )
            );
    }

    /// @dev Mark N°10 => Moon
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#7F0068" d="M197.2,142.1c-5.8,0-10.9,2.9-13.9,7.3c2.3-2.3,5.4-3.7,8.9-3.7c7.1,0,12.9,5.9,12.9,13.3 s-5.8,13.3-12.9,13.3c-3.4,0-6.6-1.4-8.9-3.7c3.1,4.4,8.2,7.3,13.9,7.3c9.3,0,16.9-7.6,16.9-16.9S206.6,142.1,197.2,142.1z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°11 => Third Eye
    function item_11() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path opacity="0.81" fill="#FFFFFF" d="M184.4,159.3c0.7,3.5,0.8,8.5,6.3,8.8 c5.5,1.6,23.2,4.2,23.8-7.6c1.2-6.1-10-9.5-15.5-9.3C193.8,152.6,184.1,153.5,184.4,159.3z"/>',
                        '<path d="M213.6,155.6c-0.2-0.2-0.4-0.4-0.6-0.6"/>',
                        '<path d="M211.8,154c-7.7-6.6-23.5-4.9-29.2,3.6c9.9-7.1,26.1-6.1,34.4,2.4c0-0.3-0.7-1.5-2-3.1"/>',
                        '<path d="M197.3,146.8c4.3-0.6,9.1,0.3,12.7,2.7C206,147.7,201.8,146.5,197.3,146.8L197.3,146.8z M193.6,147.5 c-2,0.9-4.1,1.8-6.1,2.6C189.2,148.8,191.5,147.8,193.6,147.5z"/>',
                        '<path d="M187.6,167.2c5.2,2,18.5,3.2,23.3,0.1C206.3,171.3,192.7,170,187.6,167.2z"/>',
                        '<path fill="#0B1F26" d="M199.6,151c11.1-0.2,11.1,17.4,0,17.3C188.5,168.4,188.5,150.8,199.6,151z"/>'
                    )
                )
            );
    }

    /// @dev Mark N°12 => Tori
    function item_12() public pure returns (string memory) {
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

    /// @dev Mark N°13 => Ether
    function item_13() public pure returns (string memory) {
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

    /// @notice Return the mark name of the given id
    /// @param id The mark Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Blush Cheeks";
        } else if (id == 3) {
            name = "Dark Circle";
        } else if (id == 4) {
            name = "Chin Scar";
        } else if (id == 5) {
            name = "Blush";
        } else if (id == 6) {
            name = "Chin";
        } else if (id == 7) {
            name = "Yinyang";
        } else if (id == 8) {
            name = "Scar";
        } else if (id == 9) {
            name = "Sun";
        } else if (id == 10) {
            name = "Moon";
        } else if (id == 11) {
            name = "Third Eye";
        } else if (id == 12) {
            name = "Tori";
        } else if (id == 13) {
            name = "Ether";
        }
    }

    /// @dev The base SVG for the hair
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Mark">', children, "</g>"));
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

