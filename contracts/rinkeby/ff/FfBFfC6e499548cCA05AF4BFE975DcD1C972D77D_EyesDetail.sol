// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./Eyes/EyesParts1.sol";
import "./Eyes/EyesParts2.sol";

/// @title Eyes SVG generator
library EyesDetail {
    /// @dev Eyes N°1 => Happy
    function item_1() public pure returns (string memory) {
        return base(EyesParts2.item_5(), "Happy");
    }

    /// @dev Eyes N°2 => Feels
    function item_2() public pure returns (string memory) {
        return base(EyesParts2.item_4(), "Feels");
    }

    /// @dev Eyes N°3 => Pupils Blood
    function item_3() public pure returns (string memory) {
        return base(EyesParts1.item_11(), "Pupils Blood");
    }

    /// @dev Eyes N°4 => Spiral
    function item_4() public pure returns (string memory) {
        return base(EyesParts1.item_10(), "Spiral");
    }

    /// @dev Eyes N°5 => Pupils Moon
    function item_5() public pure returns (string memory) {
        return base(EyesParts1.item_9(), "Pupils Moon");
    }

    /// @dev Eyes N°6 => Rip
    function item_6() public pure returns (string memory) {
        return base(EyesParts2.item_9(), "Rip");
    }

    /// @dev Eyes N°7 => Pupils pure
    function item_7() public pure returns (string memory) {
        return base(EyesParts1.item_15(), "Pupils Pure");
    }

    /// @dev Eyes N°8 => Akuma
    function item_8() public pure returns (string memory) {
        return base(EyesParts1.item_8(), "Akuma");
    }

    /// @dev Eyes N°9 => Scribble
    function item_9() public pure returns (string memory) {
        return base(EyesParts2.item_8(), "Scribble");
    }

    /// @dev Eyes N°10 => Arrow
    function item_10() public pure returns (string memory) {
        return base(EyesParts2.item_7(), "Arrow");
    }

    /// @dev Eyes N°11 => Globes
    function item_11() public pure returns (string memory) {
        return base(EyesParts1.item_7(), "Globes");
    }

    /// @dev Eyes N°12 => Stitch
    function item_12() public pure returns (string memory) {
        return base(EyesParts1.item_6(), "Stitch");
    }

    /// @dev Eyes N°13 => Closed
    function item_13() public pure returns (string memory) {
        return base(EyesParts2.item_6(), "Closed");
    }

    /// @dev Eyes N°14 => Kitsune
    function item_14() public pure returns (string memory) {
        return base(EyesParts1.item_13(), "Kitsune");
    }

    /// @dev Eyes N°15 => Moon
    function item_15() public pure returns (string memory) {
        return base(EyesParts1.item_12(), "Moon");
    }

    /// @dev Eyes N°16 => Shine
    function item_16() public pure returns (string memory) {
        return base(EyesParts1.item_5(), "Shine");
    }

    /// @dev Eyes N°17 => Shock
    function item_17() public pure returns (string memory) {
        return base(EyesParts1.item_14(), "Shock");
    }

    /// @dev Eyes N°18 => Tomoe Blood
    function item_18() public pure returns (string memory) {
        return base(EyesParts1.item_4(), "Tomoe Blood");
    }

    /// @dev Eyes N°19 => Stitched
    function item_19() public pure returns (string memory) {
        return base(EyesParts2.item_3(), "Stitched");
    }

    /// @dev Eyes N°20 => Tomoe Pure
    function item_20() public pure returns (string memory) {
        return base(EyesParts1.item_3(), "Tomoe Pure");
    }

    /// @dev Eyes N°21 => Pupils Pure-Blood
    function item_21() public pure returns (string memory) {
        return base(EyesParts1.item_2(), "Pupils Pure-Blood");
    }

    /// @dev Eyes N°22 => Dubu
    function item_22() public pure returns (string memory) {
        return base(EyesParts2.item_1(), "Dubu");
    }

    /// @dev Eyes N°23 => Moon Kin
    function item_23() public pure returns (string memory) {
        return base(EyesParts1.item_1(), "Moon Kin");
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Happy";
        } else if (id == 2) {
            name = "Feels";
        } else if (id == 3) {
            name = "Pupils Blood";
        } else if (id == 4) {
            name = "Spiral";
        } else if (id == 5) {
            name = "Pupils Moon";
        } else if (id == 6) {
            name = "Rip";
        } else if (id == 7) {
            name = "Pupils Pure";
        } else if (id == 8) {
            name = "Akuma";
        } else if (id == 9) {
            name = "Scribble";
        } else if (id == 10) {
            name = "Arrow";
        } else if (id == 11) {
            name = "Globes";
        } else if (id == 12) {
            name = "Stitch";
        } else if (id == 13) {
            name = "Closed";
        } else if (id == 14) {
            name = "Kitsune";
        } else if (id == 15) {
            name = "Moon";
        } else if (id == 16) {
            name = "Shine";
        } else if (id == 17) {
            name = "Shock";
        } else if (id == 18) {
            name = "Tomoe Blood";
        } else if (id == 19) {
            name = "Stitched";
        } else if (id == 20) {
            name = "Tomoe Pure";
        } else if (id == 21) {
            name = "Pupils Pure-Blood";
        } else if (id == 22) {
            name = "Dubu";
        } else if (id == 23) {
            name = "Moon Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="eyes"><g id="', name, '">', children, "</g></g>"));
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
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyes SVG generator
library EyesParts1 {
    /// @dev Eyes N°23 => Moon Gold
    function item_1() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<linearGradient id="Moon Aka" gradientUnits="userSpaceOnUse" x1="234.5972" y1="-460.8015" x2="246.3069" y2="-460.8015" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path id="Moon Aka" display="inline" fill="url(#Moon_Aka_00000152984819707226930020000004625877956111571090_)" d="M246.3,190.5c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4c-2.6-0.1-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C243.6,196.2,246.2,193.7,246.3,190.5z"  /><linearGradient id="Moon Aka" gradientUnits="userSpaceOnUse" x1="157.8972" y1="-461.0056" x2="169.6069" y2="-461.0056" gradientTransform="matrix(1 0 0 -1 0 -270)" ><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.5259" style="stop-color:#F7EC94" /><stop offset="1" style="stop-color:#FF9121" /></linearGradient><path id="Moon Aka" display="inline" fill="url(#Moon_Aka_00000178206716264067794300000007095126762428803473_)" d="M169.6,190.7c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4s-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C166.8,196.5,169.5,194,169.6,190.7z"  />'
                )
            );
    }

    /// @dev Eyes N°21 => Pupils White-Red
    function item_2() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" fill="#FFEDED" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" fill="#B50D5E" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    /// @dev Eyes N°20 => Tomoe White
    function item_3() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g display="inline" ><g><path  fill="#FFDAEA" d="M241.3,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#FFDAEA" d="M241.3,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C239.9,194.8,241,194.3,241.3,193.4z M239.1,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C239.1,193.3,239.1,193,239.1,192.7z" /></g><g><path  fill="#FFDAEA" d="M242.5,186.6c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#FFDAEA" d="M242.5,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C244.4,187.1,243.6,186.4,242.5,186.6z M243.1,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6s0.6,0.1,0.6,0.4C243.6,188.5,243.3,188.8,243.1,188.9z" /></g><g><path  fill="#FFDAEA" d="M235.5,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#FFDAEA" d="M235.2,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1C234.6,187.9,234.6,188.9,235.2,189.7z M236.8,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C236.3,187.7,236.7,187.7,236.8,187.9z" /></g></g><g display="inline" ><g><path  fill="#FFDAEA" d="M165.4,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#FFDAEA" d="M165.4,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C164.1,194.8,165.1,194.4,165.4,193.4z M163.3,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C163.3,193.3,163.1,193,163.3,192.7z" /></g><g><path  fill="#FFDAEA" d="M166.7,186.7c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#FFDAEA" d="M166.7,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C168.4,187.1,167.7,186.5,166.7,186.6z M167.2,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6c0.3,0,0.6,0.1,0.6,0.4C167.7,188.6,167.5,188.8,167.2,188.9z" /></g><g><path  fill="#FFDAEA" d="M159.6,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#FFDAEA" d="M159.4,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1S158.7,189,159.4,189.7z M160.9,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C160.4,187.8,160.7,187.8,160.9,187.9z" /></g></g>'
                )
            );
    }

    /// @dev Eyes N°18 => Tomoe Red
    function item_4() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g display="inline" ><g><path  fill="#E31466" d="M241.3,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#E31466" d="M241.3,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C239.9,194.8,241,194.3,241.3,193.4z M239.1,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C239.1,193.3,239.1,193,239.1,192.7z" /></g><g><path  fill="#E31466" d="M242.5,186.6c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#E31466" d="M242.5,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C244.4,187.1,243.6,186.4,242.5,186.6z M243.1,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6s0.6,0.1,0.6,0.4C243.6,188.5,243.3,188.8,243.1,188.9z" /></g><g><path  fill="#E31466" d="M235.5,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#E31466" d="M235.2,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1C234.6,187.9,234.6,188.9,235.2,189.7z M236.8,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C236.3,187.7,236.7,187.7,236.8,187.9z" /></g></g><g display="inline" ><g><path  fill="#E31466" d="M165.4,193.3c0,0-0.3,2-3.2,3.2c0,0,1-0.9,1.1-2.1" /><path  fill="#E31466" d="M165.4,193.4c0.3-0.9-0.2-1.9-1-2.2c-0.9-0.3-1.9,0.2-2.2,1c-0.3,0.9,0.2,1.9,1,2.2C164.1,194.8,165.1,194.4,165.4,193.4z M163.3,192.7c0.1-0.3,0.4-0.4,0.7-0.4c0.3,0.1,0.4,0.4,0.4,0.7c-0.1,0.3-0.4,0.4-0.7,0.4C163.3,193.3,163.1,193,163.3,192.7z" /></g><g><path  fill="#E31466" d="M166.7,186.7c0,0,1.9-0.7,4.4,1.3c0,0-1.3-0.4-2.4,0" /><path  fill="#E31466" d="M166.7,186.6c-0.9,0.1-1.6,1-1.4,2c0.1,0.9,1,1.6,2,1.4c0.9-0.1,1.6-1,1.4-2C168.4,187.1,167.7,186.5,166.7,186.6z M167.2,188.9c-0.3,0-0.6-0.1-0.6-0.4c0-0.3,0.1-0.6,0.4-0.6c0.3,0,0.6,0.1,0.6,0.4C167.7,188.6,167.5,188.8,167.2,188.9z" /></g><g><path  fill="#E31466" d="M159.6,189.7c0,0-1.8-1-1.7-4.3c0,0,0.4,1.3,1.5,1.9" /><path  fill="#E31466" d="M159.4,189.7c0.7,0.6,1.8,0.6,2.4-0.1c0.6-0.7,0.6-1.8-0.1-2.4c-0.7-0.6-1.8-0.6-2.4,0.1S158.7,189,159.4,189.7z M160.9,187.9c0.2,0.2,0.2,0.5,0.1,0.8c-0.2,0.2-0.5,0.2-0.8,0.1c-0.2-0.2-0.2-0.5-0.1-0.8C160.4,187.8,160.7,187.8,160.9,187.9z" /></g></g>'
                )
            );
    }

    /// @dev Eyes N°16 => Shine
    function item_5() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M164.1,182.5c1.4,7,1.4,6.9,8.3,8.3c-7,1.4-6.9,1.4-8.3,8.3c-1.4-7-1.4-6.9-8.3-8.3C162.8,189.4,162.7,189.5,164.1,182.5z"  /><path display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M238.7,182.3c1.4,7,1.4,6.9,8.3,8.3c-7,1.4-6.9,1.4-8.3,8.3c-1.4-7-1.4-6.9-8.3-8.3C237.4,189.2,237.3,189.2,238.7,182.3z"  />'
                )
            );
    }

    /// @dev Eyes N°12 => Stitch Eyes
    function item_6() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g id="Strip"> <path d="M231.3,188.2s1-3.2,2.6-.9a30.48,30.48,0,0,1-.6,9.2s-.9,2-1.5-.5C231.3,193.3,232.3,193,231.3,188.2Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M239.4,187.7s1-3.1,2.5-.9a28.56,28.56,0,0,1-.6,8.9s-.9,1.9-1.4-.5S240.5,192.4,239.4,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M245.9,187.7s.9-2.7,2.2-.8a26.25,26.25,0,0,1-.5,7.7s-.8,1.7-1.1-.4S246.9,191.8,245.9,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M251.4,187.4s.8-2.4,2-.7a21.16,21.16,0,0,1-.5,6.9s-.7,1.5-1-.4C251.4,191.2,252.1,191,251.4,187.4Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g> <g id="Strip-2" > <path d="M173.2,187.9s-1-3.1-2.5-.9a27.9,27.9,0,0,0,.6,8.8s.9,1.9,1.4-.5S172.2,192.5,173.2,187.9Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M165.4,187.7s-1-3.1-2.5-.9a28.56,28.56,0,0,0,.6,8.9s.9,1.9,1.4-.5S164.4,192.4,165.4,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M158.9,187.7s-.9-2.7-2.2-.8a26.25,26.25,0,0,0,.5,7.7s.8,1.7,1.1-.4C158.9,192,158.1,191.8,158.9,187.7Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> <path d="M153.4,187.4s-.8-2.4-2-.7a21.16,21.16,0,0,0,.5,6.9s.7,1.5,1-.4C153.4,191.2,152.6,191,153.4,187.4Z" transform="translate(-0.4)" fill="#fff" stroke="#000" stroke-miterlimit="10" stroke-width="0.75"/> </g>'
                )
            );
    }

    /// @dev Eyes N°11 => Globes
    function item_7() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse fill="#FFFFFF" cx="244.6" cy="184.5" rx="4.1" ry="0.9"  /><ellipse fill="#FFFFFF" cx="154.6" cy="184.5" rx="4.1" ry="0.9"  />'
                )
            );
    }

    /// @dev Eyes N°8 => Akuma Eye
    function item_8() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path display="inline" fill="#FFFFFF" d="M246.5,192h-13c-0.7,0-1.3-0.5-1.3-1.3l0,0c0-0.7,0.5-1.3,1.3-1.3h13c0.7,0,1.3,0.5,1.3,1.3l0,0C247.8,191.3,247.1,192,246.5,192z"  /><path display="inline" fill="#FFFFFF" d="M169.9,192h-13c-0.7,0-1.3-0.5-1.3-1.3l0,0c0-0.7,0.5-1.3,1.3-1.3h13c0.7,0,1.3,0.5,1.3,1.3l0,0C171.1,191.3,170.5,192,169.9,192z"  />'
                )
            );
    }

    /// @dev Eyes N°19 => Pupils Kuro
    function item_9() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    /// @dev Eyes N°4 => Spiral
    function item_10() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<g display="inline" ><path fill="#FFFFFF" d="M238.1,191.2c0.2-0.8,0.6-1.8,1.4-2.4c0.4-0.3,0.9-0.5,1.4-0.4s0.9,0.4,1.3,0.8c0.5,0.8,0.6,1.9,0.6,2.8c0,0.9-0.4,2-1.1,2.7s-1.8,1.1-2.8,1s-1.9-0.7-2.6-1.3c-0.7-0.5-1.5-1.3-2-2.1s-0.8-1.9-0.7-2.9s0.5-2,1.1-2.7s1.5-1.4,2.3-1.8c1.8-0.8,3.8-1,5.5-0.6c0.9,0.2,1.9,0.5,2.6,1.1c0.7,0.6,1.3,1.6,1.4,2.5c0.3,1.9-0.3,3.9-1.5,5.1c1-1.5,1.5-3.3,1-5c-0.2-0.8-0.6-1.6-1.4-2.1c-0.6-0.5-1.5-0.8-2.3-0.9c-1.7-0.2-3.5,0-5,0.7s-2.8,2.1-2.9,3.6c-0.2,1.6,0.9,3.1,2.3,4.2c0.7,0.5,1.4,1,2.2,1.1c0.7,0.1,1.6-0.2,2.2-0.7s0.9-1.4,1-2.2s0-1.8-0.4-2.4c-0.2-0.3-0.5-0.6-0.8-0.7c-0.4-0.1-0.8,0-1.1,0.2C238.9,189.6,238.4,190.4,238.1,191.2z" /></g><g display="inline" ><path fill="#FFFFFF" d="M161.7,189.8c0.7-0.4,1.7-0.8,2.6-0.7c0.4,0,0.9,0.3,1.3,0.7c0.3,0.4,0.3,0.9,0.2,1.5c-0.2,0.9-0.8,1.8-1.6,2.4c-0.7,0.6-1.7,1.1-2.7,1c-1,0-2.1-0.4-2.7-1.3c-0.7-0.8-0.8-1.9-1-2.7c-0.1-0.9-0.1-1.9,0.1-2.9c0.2-0.9,0.7-1.9,1.6-2.5c0.8-0.6,1.8-1,2.8-1c0.9-0.1,2,0.1,2.8,0.4c1.8,0.6,3.3,1.9,4.4,3.4c0.5,0.7,0.9,1.7,1,2.7c0.1,0.9-0.2,2-0.8,2.7c-1.1,1.6-2.9,2.5-4.7,2.6c1.8-0.3,3.4-1.4,4.3-2.8c0.4-0.7,0.6-1.6,0.5-2.4c-0.1-0.8-0.5-1.6-1-2.3c-1-1.4-2.5-2.5-4.1-3s-3.4-0.5-4.7,0.5s-1.6,2.8-1.4,4.5c0.1,0.8,0.2,1.7,0.7,2.3c0.4,0.6,1.3,0.9,2,1c0.8,0,1.6-0.2,2.3-0.8c0.6-0.5,1.3-1.3,1.5-2c0.1-0.4,0.1-0.8-0.1-1.1c-0.2-0.3-0.5-0.6-0.9-0.6C163.3,189.1,162.5,189.4,161.7,189.8z" /></g>'
                )
            );
    }

    /// @dev Eyes N°3 => Pupils Red
    function item_11() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" fill="#E31466" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" fill="#E31466" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    /// @dev Eyes N°2 => Moon
    function item_12() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path id="Moon Aka" display="inline" fill="#FFEDED" d="M246.3,190.5c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4c-2.6-0.1-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C243.6,196.2,246.2,193.7,246.3,190.5z"  /><path id="Moon Aka" display="inline" fill="#FFEDED" d="M169.6,190.7c0.1-2-0.9-3.8-2.4-4.9c0.7,0.8,1.3,1.9,1.1,3.1c-0.1,2.5-2.2,4.4-4.7,4.4s-4.6-2.1-4.5-4.6c0-1.1,0.5-2.3,1.4-3c-1.6,1-2.6,2.8-2.6,4.7c-0.1,3.2,2.5,5.9,5.7,5.9C166.8,196.5,169.5,194,169.6,190.7z"  />'
                )
            );
    }

    /// @dev Eyes N°1 => Kitsune Eye
    function item_13() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<path display="inline"  fill="#FFFFFF" d="M238.6,181c0,0-4.7,7.9,0,18.7C238.6,199.6,243.2,191.2,238.6,181z"  /><path display="inline"  fill="#FFFFFF" d="M165.3,181c0,0-4.7,7.9,0,18.7C165.3,199.6,169.9,191.2,165.3,181z"  />'
                )
            );
    }

    /// @dev Eyes N°17 => shock
    function item_14() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<circle  fill="#FFFFFF" cx="239.5" cy="190.8" r="1.4"/> <circle  fill="#FFFFFF" cx="164.4" cy="191.3" r="1.4"/>'
                )
            );
    }

    /// @dev Eyes N°7 => Pupils Pure
    function item_15() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    eyes,
                    '<ellipse display="inline" fill="#FFEDED" cx="239.1" cy="189.9" rx="5.7" ry="7.3"  /><ellipse display="inline" fill="#FFEDED" cx="164.4" cy="190.2" rx="5.7" ry="7.3"  />'
                )
            );
    }

    string internal constant eyes =
        '<g id="No_Fill"> <g> <path stroke="#000000" stroke-miterlimit="10" d="M219.1,197.3c0,0,3.1-22.5,37.9-15.5C257.1,181.7,261,208.8,219.1,197.3z"/> <g> <path d="M227.3,182.1c-1,0.5-1.9,1.3-2.7,2s-1.6,1.6-2.3,2.3c-0.7,0.8-1.5,1.7-2.1,2.5l-1,1.4c-0.3,0.4-0.6,0.9-1,1.4 c0.2-0.5,0.4-1,0.6-1.6c0.2-0.5,0.5-1,0.8-1.6c0.6-0.9,1.3-2,2.1-2.8s1.7-1.7,2.6-2.3C225,182.7,226.1,182.2,227.3,182.1z"/> </g> <g> <path d="M245.4,200.9c1.3-0.2,2.5-0.5,3.6-1s2.2-1,3.2-1.8c1-0.7,1.9-1.6,2.7-2.5s1.6-2,2.3-3c-0.3,1.3-0.8,2.5-1.7,3.5 c-0.7,1-1.7,2.1-2.8,2.8c-1,0.7-2.3,1.4-3.5,1.7C248,201,246.7,201.2,245.4,200.9z"/> </g> </g> <g> <path stroke="#000000" stroke-miterlimit="10" d="M183.9,197.3c0,0-3.1-22.5-37.9-15.5C146,181.7,142,208.8,183.9,197.3z"/> <g> <path d="M175.8,182.1c1,0.5,1.9,1.3,2.7,2s1.6,1.6,2.3,2.3c0.7,0.8,1.5,1.7,2.1,2.5l1,1.4c0.3,0.4,0.6,0.9,1,1.4 c-0.2-0.5-0.4-1-0.6-1.6c-0.2-0.5-0.5-1-0.8-1.6c-0.6-0.9-1.3-2-2.1-2.8s-1.7-1.7-2.6-2.3 C178.1,182.7,176.9,182.2,175.8,182.1z"/> </g> <g> <path d="M157.6,200.9c-1.3-0.2-2.5-0.5-3.6-1s-2.2-1-3.2-1.8c-1-0.7-1.9-1.6-2.7-2.5s-1.6-2-2.3-3c0.3,1.3,0.8,2.5,1.7,3.5 c0.7,1,1.7,2.1,2.8,2.8c1,0.7,2.3,1.4,3.5,1.7C155,201,156.5,201.2,157.6,200.9z"/> </g> </g> </g> <g id="Shadow" opacity="0.43"> <path opacity="0.5" enable-background="new " d="M218.3,191.6c0,0,4.6-10.8,19.9-13.6c0,0-12.2,0-16.1,2.8 C218.9,183.8,218.3,191.6,218.3,191.6z"/> </g> <g id="Shadow_00000029025467326919416900000002242143269665406345_" opacity="0.43"> <path opacity="0.5" enable-background="new " d="M184.9,191.3c0,0-4.8-10.6-20.1-13.4c0,0,12.4-0.2,16.3,2.6 C184.4,183.6,184.9,191.3,184.9,191.3z"/> </g>';

    //string internal constant eyes = '<g display="inline" ><ellipse  fill="#FFFFFF" cx="235.4" cy="190.9" rx="13.9" ry="16.4" /><path d="M221.3,190.9c0,4,1.1,8.1,3.5,11.4c1.2,1.7,2.8,3.1,4.6,4.1s3.8,1.6,5.9,1.6s4.1-0.6,5.8-1.7c1.8-1,3.3-2.4,4.6-4c2.4-3.2,3.7-7.2,3.8-11.2s-1.1-8.2-3.6-11.5c-1.2-1.7-2.9-3-4.7-4s-3.8-1.6-5.9-1.6s-4.2,0.5-5.9,1.6c-1.8,1-3.3,2.4-4.6,4.1C222.3,182.9,221.3,186.8,221.3,190.9z M221.4,190.9c0-2,0.3-4,1-5.8c0.6-1.9,1.7-3.5,2.9-5.1c2.4-3,6-5,10-5c3.9,0,7.4,2,9.9,5.1c2.4,3,3.6,6.9,3.7,10.8c0.1,3.8-1.1,8-3.5,11c-2.4,3.1-6.2,5.1-10.1,5c-3.8,0-7.5-2.1-10-5.1C223,198.8,221.4,194.8,221.4,190.9z" /></g><g display="inline" ><ellipse  fill="#FFFFFF" cx="165.8" cy="191.2" rx="13.9" ry="16.4" /><path d="M179.5,191.2c0,4-1.1,8.1-3.5,11.4c-1.2,1.7-2.8,3.1-4.6,4.1s-3.8,1.6-5.9,1.6c-2.1,0-4.1-0.6-5.8-1.7c-1.8-1-3.3-2.4-4.6-4c-2.4-3.2-3.7-7.2-3.8-11.2s1.1-8.2,3.6-11.5c1.2-1.7,2.9-3,4.7-4s3.8-1.6,5.9-1.6c2.1,0,4.2,0.5,5.9,1.6c1.8,1,3.3,2.4,4.6,4.1C178.5,183.2,179.5,187.2,179.5,191.2z M179.5,191.2c0-2-0.3-4-1-5.8c-0.6-1.9-1.7-3.5-2.9-5.1c-2.4-3-6-5-10-5c-3.9,0-7.4,2-9.9,5.1c-2.4,3-3.6,6.9-3.7,10.8c-0.1,3.8,1.1,8,3.5,11c2.4,3.1,6.2,5.1,10.1,5c3.8,0,7.5-2.1,10-5.1C178.3,199.2,179.5,195.1,179.5,191.2z" /></g>';
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Eyes SVG generator
library EyesParts2 {
    /// @dev Eyes N°22 => Dubu
    function item_1() public pure returns (string memory) {
        return
            '<g> <path d="M243.2,185.8c-2.2-1.3-4.6-2.3-7-2.8c-1.2-0.3-2.4-0.4-3.6-0.4c-1.2,0-2.4,0.1-3.2,0.6c-0.4,0.2-0.5,0.5-0.5,0.9 c0,0.5,0.3,1,0.6,1.5c0.7,1,1.6,1.9,2.6,2.7c2,1.6,4.3,2.7,6.7,3.8l3.4,1.5l-3.7-0.4c-2.5-0.3-5-0.5-7.3-0.4 c-0.6,0.1-1.1,0.2-1.6,0.3c-0.4,0.2-0.7,0.4-0.7,0.5s0,0.5,0.3,0.9s0.6,0.8,1.1,1.2c1.7,1.5,3.9,2.7,6.1,3.4 c2.3,0.7,4.8,0.9,7-0.2h0.1v0.1c-0.9,0.9-2.2,1.4-3.5,1.7c-1.3,0.2-2.7,0.2-4-0.1c-2.6-0.5-5.1-1.6-7.2-3.3c-0.5-0.4-1-1-1.4-1.6 l-0.3-0.5c-0.1-0.2-0.2-0.4-0.2-0.6c-0.1-0.4-0.2-1,0-1.5c0.1-0.3,0.2-0.5,0.4-0.7c0.1-0.2,0.3-0.4,0.5-0.5 c0.2-0.2,0.4-0.2,0.6-0.3c0.2-0.1,0.4-0.2,0.6-0.2c0.7-0.2,1.4-0.3,2.1-0.3c2.7-0.1,5.2,0.5,7.7,1.1l-0.4,1.1l-1.7-1 c-0.6-0.3-1.1-0.7-1.6-1.1l-1.6-1.1c-0.5-0.4-1.1-0.7-1.6-1.1c-1.1-0.8-2.1-1.6-3-2.6c-0.4-0.5-0.9-1.1-1.1-2 c-0.1-0.4-0.1-0.9,0.1-1.3c0.2-0.4,0.5-0.8,0.8-1.1c1.4-1,2.9-1.1,4.2-1.1c1.4,0,2.7,0.3,4,0.7c2.6,0.8,4.9,2.2,6.7,4.1v0.1 C243.3,185.8,243.3,185.8,243.2,185.8z"/> </g> <g> <path d="M171.1,185.8c-2.2-1.3-4.6-2.3-7-2.8c-1.2-0.3-2.4-0.4-3.6-0.4c-1.2,0-2.4,0.1-3.2,0.6c-0.4,0.2-0.5,0.5-0.5,0.9 c0,0.5,0.3,1,0.6,1.5c0.7,1,1.6,1.9,2.6,2.7c2,1.6,4.3,2.7,6.7,3.8l3.4,1.5l-3.7-0.4c-2.5-0.3-5-0.5-7.3-0.4 c-0.6,0.1-1.1,0.2-1.6,0.3c-0.4,0.2-0.7,0.4-0.7,0.5s0,0.5,0.3,0.9s0.6,0.8,1.1,1.2c1.7,1.5,4.9,2.7,7.1,3.4 c2.3,0.7,3.8,0.9,6-0.2h0.1v0.1c-0.9,0.9-2.2,1.4-3.5,1.7c-1.3,0.2-2.7,0.2-4-0.1c-2.6-0.5-5.1-1.6-7.2-3.3c-0.5-0.4-1-1-1.4-1.6 l-0.3-0.5c-0.1-0.2-0.2-0.4-0.2-0.6c-0.1-0.4-0.2-1,0-1.5c0.1-0.3,0.2-0.5,0.4-0.7c0.1-0.2,0.3-0.4,0.5-0.5 c0.2-0.2,0.4-0.2,0.6-0.3c0.2-0.1,0.4-0.2,0.6-0.2c0.7-0.2,1.4-0.3,2.1-0.3c2.7-0.1,5.2,0.5,7.7,1.1l-0.4,1.1l-1.7-1 c-0.6-0.3-1.1-0.7-1.6-1.1l-1.6-1.1c-0.5-0.4-1.1-0.7-1.6-1.1c-1.1-0.8-2.1-1.6-3-2.6c-0.4-0.5-0.9-1.1-1.1-2 c-0.1-0.4-0.1-0.9,0.1-1.3c0.2-0.4,0.5-0.8,0.8-1.1c1.4-1,2.9-1.1,4.2-1.1c1.4,0,2.7,0.3,4,0.7c2.6,0.8,4.9,2.2,6.7,4.1v0.1 C171.2,185.8,171.2,185.8,171.1,185.8z"/> </g>';
    }

    /// @dev Eyes N°19 => Stitched
    function item_3() public pure returns (string memory) {
        return
            '<g display="inline" ><g><path d="M223.8,191.2c1.6,0.1,3.1,0.2,4.7,0.2c1.6,0.1,3.1,0.1,4.7,0c3.1,0,6.4-0.1,9.5-0.3c3.1-0.1,6.4-0.4,9.5-0.6l9.5-0.8c-1.6,0.3-3.1,0.5-4.7,0.8c-1.6,0.2-3.1,0.4-4.7,0.6c-3.1,0.4-6.4,0.6-9.5,0.8c-3.1,0.1-6.4,0.2-9.5,0.1C230,192,226.9,191.9,223.8,191.2z" /></g><g id="Strip_00000145047919819781265440000015374262668379115410_"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M231.3,188.2c0,0,1-3.2,2.6-0.9c0,0,0.5,4.9-0.6,9.2c0,0-0.9,2-1.5-0.5C231.3,193.3,232.3,193,231.3,188.2z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M239.4,187.7c0,0,1-3.1,2.5-0.9c0,0,0.5,4.7-0.6,8.9c0,0-0.9,1.9-1.4-0.5C239.4,192.7,240.5,192.4,239.4,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M245.9,187.7c0,0,0.9-2.7,2.2-0.8c0,0,0.4,4.1-0.5,7.7c0,0-0.8,1.7-1.1-0.4C246.1,192,246.9,191.8,245.9,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M251.4,187.4c0,0,0.8-2.4,2-0.7c0,0,0.4,3.6-0.5,6.9c0,0-0.7,1.5-1-0.4C251.4,191.2,252.1,191,251.4,187.4z" /></g></g><g display="inline" ><g><path d="M145.3,189.9c1.6,0.3,3,0.6,4.6,0.8s3.1,0.4,4.7,0.5c3.1,0.2,6.3,0.3,9.4,0.3s6.3-0.1,9.4-0.3c3.1-0.2,6.3-0.5,9.4-0.7c-1.6,0.3-3.1,0.5-4.7,0.8c-1.6,0.2-3.1,0.4-4.7,0.5c-1.6,0.1-3.1,0.3-4.7,0.3c-1.6,0.1-3.1,0.1-4.7,0.1c-3.1,0-6.3-0.1-9.4-0.5C151.4,191.3,148.2,190.9,145.3,189.9z" /></g><g id="Strip_00000020356765003249034850000016175079805633892000_"><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M173.2,187.9c0,0-1-3.1-2.5-0.9c0,0-0.5,4.7,0.6,8.8c0,0,0.9,1.9,1.4-0.5C173.1,192.8,172.2,192.5,173.2,187.9z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M165.4,187.7c0,0-1-3.1-2.5-0.9c0,0-0.5,4.7,0.6,8.9c0,0,0.9,1.9,1.4-0.5C165.4,192.7,164.4,192.4,165.4,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M158.9,187.7c0,0-0.9-2.7-2.2-0.8c0,0-0.4,4.1,0.5,7.7c0,0,0.8,1.7,1.1-0.4C158.9,192,158.1,191.8,158.9,187.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M153.4,187.4c0,0-0.8-2.4-2-0.7c0,0-0.4,3.6,0.5,6.9c0,0,0.7,1.5,1-0.4C153.4,191.2,152.6,191,153.4,187.4z" /></g></g>';
    }

    /// @dev Eyes N°15 => Feels
    function item_4() public pure returns (string memory) {
        return
            '<g id="Eye_right"> <path d="M255.4,188.58c.65.72,1.18-.46,1.15.24-.08-.5-1.71,1.54-2.55,1l-.61.58c.45.82,1-.16,1,.44-.07-.51-1.59,1.13-2.44.6a21.79,21.79,0,0,1-11.26,4.05c-7.84.48-15.72-2.74-19.81-8.61,5.52,4,12.3,4.61,19.56,4.1,6.49-.54,12.93-1.09,17.25-5.11A5.22,5.22,0,0,1,255.4,188.58Z" transform="translate(-0.4)"/> <path d="M248.81,196a21.83,21.83,0,0,1-3.53,1.18,23.26,23.26,0,0,1-3.63.58c-1.12.08-2.56.1-3.7.08a14.12,14.12,0,0,1-3.6-.53h0c1.16.12,2.51.2,3.65.22a21.71,21.71,0,0,0,3.61-.07,22.4,22.4,0,0,0,3.64-.48c1.19-.29,2.28-.57,3.56-1Z" transform="translate(-0.4)"/> <path d="M233,197.34c-1-.5-2.25-.86-3.35-1.44a32.25,32.25,0,0,0-3.34-1.43,7,7,0,0,0,1.44.94,5.63,5.63,0,0,0,1.62.72,8.25,8.25,0,0,0,1.71.62A7.49,7.49,0,0,0,233,197.34Z" transform="translate(-0.4)"/> </g> <g id="Eye_left" > <path d="M148.17,188.24c-.64.72-1.18-.46-1.15.24.08-.5,1.71,1.54,2.55,1l.61.58c-.45.82-1-.16-1,.44.08-.51,1.59,1.13,2.44.6a21.79,21.79,0,0,0,11.27,4.05c7.83.48,15.71-2.74,19.8-8.61-5.52,4-12.3,4.61-19.56,4.1-6.49-.54-12.93-1.09-17.25-5.12A5.21,5.21,0,0,0,148.17,188.24Z" transform="translate(-0.4)"/> <path d="M170,197a21.46,21.46,0,0,1-3.67.6,22.49,22.49,0,0,1-3.67,0c-1.12-.1-2.55-.3-3.67-.5a14,14,0,0,1-3.47-1.1h0c1.12.3,2.45.6,3.57.8a21.91,21.91,0,0,0,3.57.5,22.51,22.51,0,0,0,3.67.1c1.23-.1,2.35-.2,3.67-.4Z" transform="translate(-0.4)"/> <path d="M174,195.68c.92-.6,2.14-1.1,3.16-1.8a32.35,32.35,0,0,1,3.16-1.8,6.71,6.71,0,0,1-1.32,1.1,5.62,5.62,0,0,1-1.53.9,8.23,8.23,0,0,1-1.63.8A7,7,0,0,1,174,195.68Z" transform="translate(-0.4)"/> </g>';
    }

    /// @dev Eyes N°14 => Happy
    function item_5() public pure returns (string memory) {
        return
            '<g id="Eye_right" > <path d="M255.4,191.94c.65-.72,1.18.46,1.15-.24-.08.5-1.71-1.54-2.55-1l-.61-.58c.45-.82,1,.16,1-.44-.07.51-1.59-1.13-2.44-.6A21.79,21.79,0,0,0,240.64,185c-7.84-.48-15.72,2.74-19.81,8.61,5.52-4,12.3-4.61,19.56-4.1,6.49.54,12.93,1.09,17.25,5.11A5.22,5.22,0,0,0,255.4,191.94Z" transform="translate(-0.4)"/> <path d="M232.53,181.2a21.63,21.63,0,0,1,3.67-.6,22.49,22.49,0,0,1,3.67,0c1.12.1,2.55.3,3.67.5a14,14,0,0,1,3.47,1.1h0c-1.12-.3-2.45-.6-3.57-.8a21.91,21.91,0,0,0-3.57-.5,22.51,22.51,0,0,0-3.67-.1c-1.22.1-2.35.2-3.67.4Z" transform="translate(-0.4)"/> <path d="M228.55,182.5c-.92.6-2.14,1.1-3.16,1.8a32.35,32.35,0,0,1-3.16,1.8,7,7,0,0,1,1.32-1.1,5.62,5.62,0,0,1,1.53-.9,8.23,8.23,0,0,1,1.63-.8A7,7,0,0,1,228.55,182.5Z" transform="translate(-0.4)"/> </g> <g id="Eye_left" > <path d="M148.17,192.28c-.64-.72-1.18.46-1.15-.24.08.5,1.71-1.54,2.55-1l.61-.58c-.45-.82-1,.16-1-.44.08.51,1.59-1.13,2.44-.6a21.79,21.79,0,0,1,11.27-4c7.83-.48,15.71,2.74,19.8,8.61-5.52-4-12.3-4.61-19.56-4.1-6.49.54-12.93,1.09-17.25,5.11A5.22,5.22,0,0,1,148.17,192.28Z" transform="translate(-0.4)"/> <path d="M171,181.54a21.46,21.46,0,0,0-3.67-.6,22.49,22.49,0,0,0-3.67,0c-1.12.1-2.55.3-3.67.5a14,14,0,0,0-3.47,1.1h0c1.12-.3,2.45-.6,3.57-.8a21.91,21.91,0,0,1,3.57-.5,22.51,22.51,0,0,1,3.67-.1c1.23.1,2.35.2,3.67.4Z" transform="translate(-0.4)"/> <path d="M175,182.84c.92.6,2.14,1.1,3.16,1.8a32.35,32.35,0,0,0,3.16,1.8,6.71,6.71,0,0,0-1.32-1.1,5.62,5.62,0,0,0-1.53-.9,8.23,8.23,0,0,0-1.63-.8A7,7,0,0,0,175,182.84Z" transform="translate(-0.4)"/> </g>';
    }

    /// @dev Eyes N°13 => Closed
    function item_6() public pure returns (string memory) {
        return
            '<g display="inline" ><path d="M219,191.1c1.7-0.5,3.3-0.7,5-0.9s3.3-0.3,5-0.3s3.4,0.3,5.1,0.2c1.7,0,3.4-0.2,5-0.5c1.7-0.3,3.3-0.5,5-0.7s3.4-0.3,5-0.4c3.4-0.1,6.7,0,10.1,0.4c0.1,0,0.1,0.1,0.1,0.1s0,0.1-0.1,0.1c-3.3,0.8-6.7,1.2-10,1.5c-1.7,0.1-3.4,0.1-5,0.1c-1.7,0-3.4,0-5.1-0.1c-1.7-0.1-3.4-0.1-5,0c-1.7,0.1-3.3,0.6-5,0.8s-3.4,0.2-5,0.2c-1.7,0-3.4-0.1-5.1-0.4C218.9,191.3,218.9,191.2,219,191.1C218.9,191.1,219,191.1,219,191.1z" /></g><g display="inline" ><path d="M180.5,191.3c-1.5,0.3-3,0.4-4.5,0.5c-1.5,0-3,0-4.5-0.1c-1.5-0.2-3-0.6-4.5-0.7c-1.5-0.1-3-0.1-4.5,0s-3,0.2-4.5,0.2s-3,0-4.5-0.1c-3-0.2-6-0.6-9-1.3c-0.1,0-0.1-0.1-0.1-0.1s0-0.1,0.1-0.1c3-0.5,6.1-0.6,9.1-0.6c1.5,0,3,0.2,4.5,0.3s3,0.3,4.5,0.6s3,0.4,4.5,0.4s3-0.3,4.5-0.3c1.5-0.1,3,0.1,4.5,0.2c1.5,0.2,3,0.4,4.5,0.9C180.6,191.1,180.6,191.2,180.5,191.3C180.6,191.3,180.5,191.3,180.5,191.3z" /></g>';
    }

    /// @dev Eyes N°10 => Arrow
    function item_7() public pure returns (string memory) {
        return
            '<g display="inline" ><path d="M254.5,182.3c-2.6,1.1-5.2,1.9-7.9,2.7c-2.6,0.8-5.3,1.6-8,2.1c-2.7,0.6-5.5,1-8.2,1.6s-5.3,1.4-8,2.3v-1.1c2.8,0.3,5.6,0.6,8.3,1.2c2.7,0.5,5.5,1.1,8.2,2c2.7,0.8,5.3,1.8,7.9,2.9c2.6,1.1,5.1,2.4,7.4,3.9l-0.1,0.2c-2.7-0.9-5.3-1.8-7.9-2.6c-2.6-0.8-5.3-1.6-7.9-2.4c-2.6-0.8-5.3-1.5-8-2.2l-8.1-1.9h-0.1c-0.3-0.1-0.5-0.4-0.4-0.6c0.1-0.2,0.2-0.4,0.4-0.4c2.7-0.5,5.4-1.1,8.1-1.9c2.7-0.8,5.3-1.7,7.9-2.6c2.6-0.8,5.3-1.4,8-2s5.4-1.1,8.2-1.4L254.5,182.3z" /></g><g display="inline" ><path d="M149.3,182.1c2.8,0.3,5.5,0.8,8.2,1.4c2.7,0.6,5.4,1.2,8,2l3.9,1.3c1.3,0.4,2.6,0.9,4,1.2c2.7,0.8,5.4,1.3,8.1,1.8c0.3,0.1,0.5,0.4,0.5,0.7c0,0.2-0.2,0.4-0.4,0.4h-0.1l-7.8,2c-2.6,0.7-5.1,1.5-7.7,2.2c-2.6,0.7-5.1,1.5-7.6,2.3c-2.6,0.8-5.1,1.7-7.6,2.5l-0.1-0.2c2.3-1.4,4.7-2.7,7.2-3.8s5-2.1,7.6-2.9c2.6-0.8,5.2-1.5,7.9-2c2.6-0.6,5.3-1,8-1.3v1.1c-2.6-0.9-5.3-1.7-8-2.3c-1.3-0.3-2.7-0.6-4.1-0.8l-4.1-0.8c-2.7-0.6-5.4-1.3-8-2.1S151.9,183.1,149.3,182.1L149.3,182.1z" /></g>';
    }

    /// @dev Eyes N°9 => Scribble
    function item_8() public pure returns (string memory) {
        return
            '<polyline display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="225.3,188.1 256.3,188.1 225.3,192.5 254.5,192.5 226.9,196 251.4,196 "  /><polyline display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" points="148.1,188.1 179,188.1 148.1,192.5 177.3,192.5 149.5,196 174,196 "  />';
    }

    /// @dev Eyes N°6 => Rip
    function item_9() public pure returns (string memory) {
        return
            '<line x1="230.98" y1="182.49" x2="248.68" y2="200.19" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/> <line x1="230.47" y1="200.87" x2="248.67" y2="183.17" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/> <line x1="155.53" y1="182.66" x2="173.23" y2="200.36" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/> <line x1="154" y1="200.7" x2="172.2" y2="183" fill="none" stroke="#000" stroke-linecap="square" stroke-miterlimit="10" stroke-width="3"/>';
    }
}