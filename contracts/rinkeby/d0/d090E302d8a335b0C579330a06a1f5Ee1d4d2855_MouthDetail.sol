// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mouth SVG generator
library MouthDetail {
    /// @dev Mouth N°1 => Neutral
    function item_1() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M178.3,262.7c3.3-0.2,6.6-0.1,9.9,0c3.3,0.1,6.6,0.3,9.8,0.8c-3.3,0.3-6.6,0.3-9.9,0.2C184.8,263.6,181.5,263.3,178.3,262.7z"/>',
                        '<path d="M201.9,263.4c1.2-0.1,2.3-0.1,3.5-0.2l3.5-0.2l6.9-0.3c2.3-0.1,4.6-0.2,6.9-0.4c1.2-0.1,2.3-0.2,3.5-0.3l1.7-0.2c0.6-0.1,1.1-0.2,1.7-0.2c-2.2,0.8-4.5,1.1-6.8,1.4s-4.6,0.5-7,0.6c-2.3,0.1-4.6,0.2-7,0.1C206.6,263.7,204.3,263.6,201.9,263.4z"/>',
                        '<path d="M195.8,271.8c0.8,0.5,1.8,0.8,2.7,1s1.8,0.4,2.7,0.5s1.8,0,2.8-0.1c0.9-0.1,1.8-0.5,2.8-0.8c-0.7,0.7-1.6,1.3-2.6,1.6c-1,0.3-2,0.5-3,0.4s-2-0.3-2.9-0.8C197.3,273.2,196.4,272.7,195.8,271.8z"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°2 => Smile
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M178.2,259.6c1.6,0.5,3.3,0.9,4.9,1.3c1.6,0.4,3.3,0.8,4.9,1.1c1.6,0.4,3.3,0.6,4.9,0.9c1.7,0.3,3.3,0.4,5,0.6c-1.7,0.2-3.4,0.3-5.1,0.2c-1.7-0.1-3.4-0.3-5.1-0.7C184.5,262.3,181.2,261.2,178.2,259.6z"/>',
                        '<path d="M201.9,263.4l7-0.6c2.3-0.2,4.7-0.4,7-0.7c2.3-0.2,4.6-0.6,6.9-1c0.6-0.1,1.2-0.2,1.7-0.3l1.7-0.4l1.7-0.5l1.6-0.7c-0.5,0.3-1,0.7-1.5,0.9l-1.6,0.8c-1.1,0.4-2.2,0.8-3.4,1.1c-2.3,0.6-4.6,1-7,1.3s-4.7,0.4-7.1,0.5C206.7,263.6,204.3,263.6,201.9,263.4z"/>',
                        '<path d="M195.8,271.8c0.8,0.5,1.8,0.8,2.7,1s1.8,0.4,2.7,0.5s1.8,0,2.8-0.1c0.9-0.1,1.8-0.5,2.8-0.8c-0.7,0.7-1.6,1.3-2.6,1.6c-1,0.3-2,0.5-3,0.4s-2-0.3-2.9-0.8C197.3,273.2,196.4,272.7,195.8,271.8z"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°3 => Sulk
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M179.2,263.2c0,0,24.5,3.1,43.3-0.6"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M176.7,256.8c0,0,6.7,6.8-0.6,11"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M225.6,256.9c0,0-6.5,7,1,11"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°4 => Poker
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line id="Poker" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" x1="180" y1="263" x2="226" y2="263"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°5 => Angry
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M207.5,257.1c-7,1.4-17.3,0.3-21-0.9c-4-1.2-7.7,3.1-8.6,7.2c-0.5,2.5-1.2,7.4,3.4,10.1c5.9,2.4,5.6,0.1,9.2-1.9c3.4-2,10-1.1,15.3,1.9c5.4,3,13.4,2.2,17.9-0.4c2.9-1.7,3.3-7.6-4.2-14.1C217.3,257.2,215.5,255.5,207.5,257.1"/>',
                        '<path fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M205.9,265.5l4.1-2.2c0,0,3.7,2.9,5,3s4.9-3.2,4.9-3.2l3.9,1.4"/>',
                        '<polyline fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="177.8,265.3 180.2,263.4 183.3,265.5 186,265.4"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°6 => Big Smile
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" d="M238.1,255.9c-26.1,4-68.5,0.3-68.5,0.3C170.7,256.3,199.6,296.4,238.1,255.9"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M176.4,262.7c0,0,7.1,2.2,12,2.1"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#FFFFFF" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M230.6,262.8c0,0-10.4,2.1-17.7,1.8"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°7 => Evil
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" d="M174.7,261.7c0,0,16.1-1.1,17.5-1.5s34.5,6.3,36.5,5.5s4.6-1.9,4.6-1.9s-14.1,8-43.6,7.9c0,0-3.9-0.7-4.7-1.8S177.1,262.1,174.7,261.7z"/>',
                        '<polyline fill="none" stroke="#000000" stroke-miterlimit="10" points="181.6,266.7 185.5,265.3 189.1,266.5 190.3,265.9"/>',
                        '<polyline fill="none" stroke="#000000" stroke-miterlimit="10" points="198.2,267 206.3,266.2 209.6,267.7 213.9,266.3 216.9,267.5 225.3,267"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°8 => Tongue
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FF155D" d="M206.5,263.1c0,0,4,11.2,12.5,9.8c11.3-1.8,6.3-11.8,6.3-11.8L206.5,263.1z"/>',
                        '<line fill="none" stroke="#73093E" stroke-miterlimit="10" x1="216.7" y1="262.5" x2="218.5" y2="267.3"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M201.9,263.4c0,0,20.7,0.1,27.7-4.3"/>',
                        '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M178.2,259.6c0,0,9.9,4.2,19.8,3.9"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°9 => Drool
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FEBCA6" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M190.4,257.5c2.5,0.6,5.1,0.8,7.7,0.5l17-2.1c0,0,13.3-1.8,12,3.6c-1.3,5.4-2.4,9.3-5.3,9.8c0,0,3.2,9.7-2.9,9c-3.7-0.4-2.4-7.7-2.4-7.7s-15.4,4.6-33.1-1.7c-1.8-0.6-3.6-2.6-4.4-3.9c-5.1-7.7-2-9.5-2-9.5S175.9,253.8,190.4,257.5z"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°10 => O
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.9952 -9.745440e-02 9.745440e-02 0.9952 -24.6525 20.6528)" opacity="0.84" fill-rule="evenodd" clip-rule="evenodd" cx="199.1" cy="262.7" rx="3.2" ry="4.6"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°11 => Dubu
    function item_11() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="0.75" stroke-linecap="round" stroke-miterlimit="10" d="M204.2,262c-8.9-7-25.1-3.5-4.6,6.6c-22-3.8-3.2,11.9,4.8,6"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°12 => Stitch
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<g opacity="0.84" fill-rule="evenodd" clip-rule="evenodd">',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.8992 6.2667)" cx="179.6" cy="264.5" rx="2.3" ry="4.3"/>',
                        '<ellipse transform="matrix(0.9996 -2.866329e-02 2.866329e-02 0.9996 -7.485 5.0442)"  cx="172.2" cy="263.6" rx="1.5" ry="2.9"/>',
                        '<ellipse transform="matrix(0.9996 -2.866329e-02 2.866329e-02 0.9996 -7.4594 6.6264)" cx="227.4" cy="263.5" rx="1.5" ry="2.9"/>',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.8828 7.6318)"  cx="219.7" cy="264.7" rx="2.5" ry="4.7"/>',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.9179 6.57)" cx="188.5" cy="265.2" rx="2.9" ry="5.4"/>',
                        '<ellipse transform="matrix(0.9994 -3.403963e-02 3.403963e-02 0.9994 -8.9153 7.3225)" cx="210.6" cy="265.5" rx="2.9" ry="5.4"/>',
                        '<ellipse transform="matrix(0.9992 -3.983298e-02 3.983298e-02 0.9992 -10.4094 8.1532)" cx="199.4" cy="265.3" rx="4" ry="7.2"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Mouth N°13 => Uwu
    function item_13() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<polyline fill="#FFFFFF" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" points="212.7,262.9 216,266.5 217.5,261.7"/>',
                        '<path fill="none" stroke="#000000" stroke-width="0.75" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M176.4,256c0,0,5.7,13.4,23.1,4.2"/>',
                        '<path fill="none" stroke="#000000" stroke-width="0.75" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M224.7,254.8c0,0-9.5,15-25.2,5.4"/>'
                    )
                )
            );
    }

    /// @dev Mouth N°14 => Monster
    function item_14() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M161.4,255c0,0,0.5,0.1,1.3,0.3 c4.2,1,39.6,8.5,84.8-0.7C247.6,254.7,198.9,306.9,161.4,255z"/>',
                        '<polyline fill="none" stroke="#000000" stroke-width="0.75" stroke-linejoin="round" stroke-miterlimit="10" points="165.1,258.9 167,256.3 170.3,264.6 175.4,257.7 179.2,271.9 187,259.1 190.8,276.5 197,259.7 202.1,277.5 207.8,259.1 213.8,275.4 217.9,258.7 224.1,271.2 226.5,257.9 232.7,266.2 235.1,256.8 238.6,262.1 241.3,255.8 243.8,257.6"/>'
                    )
                )
            );
    }

    /// @notice Return the mouth name of the given id
    /// @param id The mouth Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Neutral";
        } else if (id == 2) {
            name = "Smile";
        } else if (id == 3) {
            name = "Sulk";
        } else if (id == 4) {
            name = "Poker";
        } else if (id == 5) {
            name = "Angry";
        } else if (id == 6) {
            name = "Big Smile";
        } else if (id == 7) {
            name = "Evil";
        } else if (id == 8) {
            name = "Tongue";
        } else if (id == 9) {
            name = "Drool";
        } else if (id == 10) {
            name = "O";
        } else if (id == 11) {
            name = "Dubu";
        } else if (id == 12) {
            name = "Stitch";
        } else if (id == 13) {
            name = "Uwu";
        } else if (id == 14) {
            name = "Monster";
        }
    }

    /// @dev The base SVG for the mouth
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Mouth">', children, "</g>"));
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

