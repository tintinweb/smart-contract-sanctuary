// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyebrow SVG generator
library EyebrowDetail {
    /// @dev Eyebrow N°1 => Kitsune Blood
    function item_1() public pure returns (string memory) {
        return base(kitsune("B50D5E"), "Kitsune Blood");
    }

    /// @dev Eyebrow N°2 => Kitsune Moon
    function item_2() public pure returns (string memory) {
        return base(kitsune("000000"), "Kitsune Moon");
    }

    /// @dev Eyebrow N°3 => Slayer Blood
    function item_3() public pure returns (string memory) {
        return base(slayer("B50D5E"), "Slayer Blood");
    }

    /// @dev Eyebrow N°4 => Slayer Moon
    function item_4() public pure returns (string memory) {
        return base(slayer("000000"), "Slayer Moon");
    }

    /// @dev Eyebrow N°5 => Shaved
    function item_5() public pure returns (string memory) {
        return
            base(
                '<g opacity="0.06"><path d="M218.3,173s24.22-3.6,30.64-3.4,11,1.7,14.08,3.5c0,0-22.75,2.9-32.89,3.2S219.77,176.44,218.3,173Z" transform="translate(-0.4)" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/> <path d="M187,173.34s-23.54-3.8-30-3.5-10.7,1.6-13.74,3.5c0,0,22.19,2.9,32.21,3.3C185.24,177,185.91,176.74,187,173.34Z" transform="translate(-0.4)" stroke="#000" stroke-miterlimit="10" fill-rule="evenodd"/></g>',
                "Shaved"
            );
    }

    /// @dev Eyebrow N°6 => Thick Blood
    function item_6() public pure returns (string memory) {
        return base(thick("B50D5E"), "Thick Blood");
    }

    /// @dev Eyebrow N°7 => Thick Moon
    function item_7() public pure returns (string memory) {
        return base(thick("000000"), "Thick Moon");
    }

    /// @dev Eyebrow N°8 => None
    function item_8() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Eyebrow N°9 => Electric Blood
    function item_9() public pure returns (string memory) {
        return base(electric("B50D5E"), "Electric Blood");
    }

    /// @dev Eyebrow N°10 => Electric Moon
    function item_10() public pure returns (string memory) {
        return base(electric("000000"), "Electric Moon");
    }

    /// @dev Eyebrow N°11 => Robot Blood
    function item_11() public pure returns (string memory) {
        return base(robot("B50D5E"), "Robot Blood");
    }

    /// @dev Eyebrow N°12 => Robot Moon
    function item_12() public pure returns (string memory) {
        return base(robot("000000"), "Robot Moon");
    }

    /// @dev Eyebrow N°13 => Tomoe Blood
    function item_13() public pure returns (string memory) {
        return base(tomoe("B50D5E"), "Tomoe Blood");
    }

    /// @dev Eyebrow N°14 => Tomoe Moon
    function item_14() public pure returns (string memory) {
        return base(tomoe("000000"), "Tomoe Moon");
    }

    /// @dev Eyebrow N°15 => Kitsune Pure
    function item_15() public pure returns (string memory) {
        return base(kitsune("FFEDED"), "Kitsune Pure");
    }

    /// @dev Eyebrow N°16 => Slayer Pure
    function item_16() public pure returns (string memory) {
        return base(slayer("FFEDED"), "Slayer Pure");
    }

    /// @dev Eyebrow N°17 => Thick Pure
    function item_17() public pure returns (string memory) {
        return base(thick("FFEDED"), "Thick Pure");
    }

    /// @dev Eyebrow N°18 => Electric Pure
    function item_18() public pure returns (string memory) {
        return base(electric("FFEDED"), "Electric Pure");
    }

    /// @dev Eyebrow N°19 => Robot Pure
    function item_19() public pure returns (string memory) {
        return base(robot("FFEDED"), "Robot Pure");
    }

    /// @dev Eyebrow N°20 => Tomoe Pure
    function item_20() public pure returns (string memory) {
        return base(tomoe("FFEDED"), "Tomoe Pure");
    }

    /// @dev Eyebrow N°21 => Tomoe Kin
    function item_21() public pure returns (string memory) {
        return
            base(
                '<linearGradient id="Tomoe_Gold_Gradient" gradientUnits="userSpaceOnUse" x1="215.6498" y1="-442.1553" x2="232" y2="-442.1553" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7E394" /><stop offset="1" style="stop-color:#FF9B43" /></linearGradient><path display="inline"  fill="url(#Tomoe_Gold_Gradient)" d="M232,168.9c-6.7-3.4-11.3-1.9-12.8-1.2c-0.1,0-0.3,0.1-0.4,0.1c-2.6,1-3.9,4.1-2.7,6.6c1,2.6,4.1,3.9,6.6,2.7c2.6-1,3.9-4.1,2.7-6.6c0-0.1-0.1-0.2-0.1-0.2C228.1,168.4,232,168.9,232,168.9z M221.4,174.1c-0.9,0.3-1.8,0-2.2-0.9c-0.3-0.9,0-1.8,0.9-2.2c0.9-0.3,1.8,0,2.2,0.9C222.7,172.7,222.2,173.7,221.4,174.1z"  /><linearGradient id="SVGID_00000169552172318176501370000006213919017808816827_" gradientUnits="userSpaceOnUse" x1="171" y1="-442.5519" x2="187.1496" y2="-442.5519" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7E394" /><stop offset="1" style="stop-color:#FF9B43" /></linearGradient><path display="inline"  fill="url(#SVGID_00000169552172318176501370000006213919017808816827_)" d="M184.2,168.3c-0.9-0.5-5.7-2.8-13.2,1c0,0,3.8-0.5,6.6,1.3c-0.1,0.1-0.1,0.2-0.2,0.3c-1.2,2.5,0.1,5.6,2.7,6.6c2.5,1.2,5.6-0.1,6.6-2.7C187.9,172.4,186.7,169.4,184.2,168.3z M183.8,173.6c-0.4,0.9-1.3,1.2-2.2,0.9c-0.9-0.4-1.4-1.4-0.9-2.2c0.4-0.9,1.3-1.2,2.2-0.9C183.8,171.8,184.1,172.7,183.8,173.6z"  />',
                "Tomoe Kin"
            );
    }

    function electric(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline"  fill="#',
                    color,
                    '" d="M216,176.7c14.2-2.2,47-5.6,50.4-6.6l-14.8-0.7l17.4-9.1c-17.8,7.7-37.5,12.9-56.3,13.3C213.1,174.8,214.6,176.1,216,176.7z"  /><path display="inline"  fill="#',
                    color,
                    '" d="M186.7,176.7c-12.8-2.1-44.8-5.3-48-6.3l13.5-0.9l-15.4-8.8c15.9,7.4,33.7,11.9,49,13.2C186.1,175.2,186.5,175.5,186.7,176.7z"  />'
                )
            );
    }

    function robot(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle display="inline"  fill="#',
                    color,
                    '" cx="184.1" cy="170" r="5.5"  /><circle display="inline"  fill="#',
                    color,
                    '" cx="217" cy="169.8" r="5.5"  />'
                )
            );
    }

    function kitsune(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline"  fill="#',
                    color,
                    '" d="M238.3,166.9c-12.3-3.9-19-1.1-21.3,0.2c-0.1,0-0.2,0.1-0.3,0.2c-0.3,0.1-0.5,0.4-0.6,0.4l0,0l0,0l0,0c-0.9,0.8-1.6,2-1.6,3.3c-0.2,2.7,1.9,5,4.6,5.2c2.7,0.2,5-1.9,5.2-4.6c0.1-0.3,0-0.6,0-1C228.9,166.5,238.3,166.9,238.3,166.9z"  /><path display="inline"  fill="#',
                    color,
                    '" d="M162.6,166.8c12.3-3.9,19-1,21.3,0.3c0.1,0,0.2,0.1,0.3,0.2c0.3,0.1,0.5,0.4,0.6,0.4l0,0l0,0l0,0c0.9,0.8,1.6,2,1.6,3.3c0.2,2.7-1.9,5-4.6,5.2c-2.7,0.2-5-1.9-5.2-4.6c-0.1-0.3,0-0.6,0-1C172,166.5,162.6,166.8,162.6,166.8z"  />'
                )
            );
    }

    function slayer(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline" fill="#',
                    color,
                    '" d="M217.3,168.6c-0.8,1.5-4.8,12.6,9.4,9.9c0,0,9.6-4.5,12.5-8.1c0,0-6.7,0.6-8.1,1.5c0,0,7.2-3.2,8.5-6.7c0,0-11.4,2.1-12,3.9c0,0,2.7-4.7,4.2-5.3s-7.6,1.4-8.5,3.5c-0.9,2.2,0.5-5.6,2.1-6.1C227,160.7,220.2,163,217.3,168.6z"/> <path display="inline" fill="#',
                    color,
                    '" d="M186.6,168.5c0.8,1.5,4.8,12.6-9.4,9.9c0,0-9.6-4.5-12.5-8.1c0,0,6.7,0.6,8.1,1.5c0,0-7.2-3.2-8.5-6.7c0,0,11.4,2.1,12,3.9c0,0-2.7-4.7-4.2-5.3s7.6,1.4,8.5,3.5c0.9,2.2-0.5-5.6-2.1-6.1C176.9,160.7,183.9,162.9,186.6,168.5z"/>'
                )
            );
    }

    function tomoe(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g display="inline"> <path  fill="#',
                    color,
                    '" d="M218.6,168c0,0,5-3.3,13.4,0.9c0,0-4-0.5-6.8,1.4"/> <path  fill="#',
                    color,
                    '" d="M218.8,167.8c-2.6,1-3.9,4.1-2.7,6.6c1,2.6,4.1,3.9,6.6,2.7 c2.6-1,3.9-4.1,2.7-6.6C224.3,168.1,221.4,166.8,218.8,167.8z M221.4,174.1c-0.9,0.3-1.8,0-2.2-0.9c-0.3-0.9,0-1.8,0.9-2.2 c0.9-0.3,1.8,0,2.2,0.9C222.7,172.7,222.2,173.7,221.4,174.1z"/> </g> <g display="inline"> <path  fill="#',
                    color,
                    '" d="M184.4,168.4c0,0-5-3.3-13.4,0.9c0,0,4-0.5,6.8,1.4"/> <path  fill="#',
                    color,
                    '" d="M184,168.2c2.6,1,3.9,4.1,2.7,6.6c-1,2.6-4.1,3.9-6.6,2.7 c-2.6-1-3.9-4.1-2.7-6.6C178.7,168.4,181.5,167.2,184,168.2z M181.6,174.5c0.9,0.3,1.8,0,2.2-0.9c0.3-0.9,0-1.8-0.9-2.2 c-0.9-0.3-1.8,0-2.2,0.9C180.2,173.1,180.7,174.1,181.6,174.5z"/> </g>'
                )
            );
    }

    function thick(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Thick_L" > <path  fill="#',
                    color,
                    '" d="M213.7,173.6c-0.6-1.4,0.1-3.1,1.6-3.5c1.7-0.5,4.3-1.2,7.5-1.7 c1.5-0.3,13.2-4.2,14.4-4.9c0.2,0.9-6.2,4.1-4.9,3.9c7.3-1.2,14.7-2.2,18.1-2c3.6,0.1,6.4,0.4,9,1.2c0.6,0.2,5.3,1.1,5.9,1.4 c0.4,0.2-3-0.1-2.6,0.1c1.9,0.9,3.6,1.9,5.1,3c0,0-28,4.7-40.5,5.3C217.3,176.8,215,176.6,213.7,173.6z"/> </g> <g id="Thick_R" > <path  fill="#',
                    color,
                    '" d="M187.1,173.7c0.6-1.4-0.1-3.1-1.6-3.5c-6.2-1.9-8.9-2-7.3-1.7 c-1.5-0.3-12.4-4.7-13.7-5.3c-0.2,0.9,5.6,4.6,4.5,4.4c-7.1-1.2-14.2-2.2-17.5-2c-3.5,0.1-6.2,0.4-8.7,1.2 c-0.6,0.2-5.1,1.1-5.7,1.4c-0.4,0.2,2.9-0.1,2.5,0.1c-1.8,0.9-3.5,1.9-4.9,3c0,0,27.1,4.7,39.3,5.3 C183.6,176.9,185.9,176.7,187.1,173.7z"/> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Kitsune Blood";
        } else if (id == 2) {
            name = "Kitsune Moon";
        } else if (id == 3) {
            name = "Slayer Blood";
        } else if (id == 4) {
            name = "Slayer Moon";
        } else if (id == 5) {
            name = "Shaved";
        } else if (id == 6) {
            name = "Thick Blood";
        } else if (id == 7) {
            name = "Thick Moon";
        } else if (id == 8) {
            name = "None";
        } else if (id == 9) {
            name = "Electric Blood";
        } else if (id == 10) {
            name = "Electric Moon";
        } else if (id == 11) {
            name = "Robot Blood";
        } else if (id == 12) {
            name = "Robot Moon";
        } else if (id == 13) {
            name = "Tomoe Blood";
        } else if (id == 14) {
            name = "Tomoe Moon";
        } else if (id == 15) {
            name = "Kitsune Pure";
        } else if (id == 16) {
            name = "Slayer Pure";
        } else if (id == 17) {
            name = "Thick Pure";
        } else if (id == 18) {
            name = "Electric Pure";
        } else if (id == 19) {
            name = "Robot Pure";
        } else if (id == 20) {
            name = "Tomoe Pure";
        } else if (id == 21) {
            name = "Tomoe Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="eyebrow"><g id="', name, '">', children, "</g></g>"));
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