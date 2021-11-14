// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Nose SVG generator
library NoseDetail {
    /// @dev Nose N°1 => Kitsune Blood
    function item_1() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#B50D5E" stroke="#B50D5E" stroke-miterlimit="10" d="M193.2,224.9c5.1,0.6,10.3,1,16.4,0c0.4-0.1,0.7,0.5,0.3,0.8l-7.4,5.9c-0.5,0.4-1.3,0.4-1.8,0l-7.9-6C192.5,225.4,192.7,224.8,193.2,224.9z"  />',
                "Kitsune Blood"
            );
    }

    /// @dev Nose N°2 => Kitsune Moon
    function item_2() public pure returns (string memory) {
        return
            base(
                '<path display="inline" stroke="#000000" stroke-miterlimit="10" d="M193.2,224.9c5.1,0.6,10.3,1,16.4,0c0.4-0.1,0.7,0.5,0.3,0.8l-7.4,5.9c-0.5,0.4-1.3,0.4-1.8,0l-7.9-6C192.5,225.4,192.7,224.8,193.2,224.9z"  />',
                "Kitsune Moon"
            );
    }

    // @dev Nose N°3 => None
    function item_3() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Nose N°4 => Kitsune Pure
    function item_4() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FFEDED" stroke="#FFEDED" stroke-miterlimit="10" d="M193.2,224.9c5.1,0.6,10.3,1,16.4,0c0.4-0.1,0.7,0.5,0.3,0.8l-7.4,5.9c-0.5,0.4-1.3,0.4-1.8,0l-7.9-6C192.5,225.4,192.7,224.8,193.2,224.9z"  />',
                "Kitsune Pure"
            );
    }

    /// @dev Nose N°5 => Nosetril
    function item_5() public pure returns (string memory) {
        return
            base(
                '<path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M196.4,229.2c-0.4,0.3-2.1-0.9-4.1-2.5c-1.9-1.6-3-2.7-2.6-2.9c0.4-0.3,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2z"  /><path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M206.5,228.7c0.3,0.4,2.2-0.3,4.2-1.7c2-1.5,3.5-2,3.2-2.4s-2.5-0.7-4.5,0.7C207.4,226.9,206.1,228.2,206.5,228.7z"  />',
                "Nosetril"
            );
    }

    /// @dev Nose N°6 => Akuma
    function item_6() public pure returns (string memory) {
        return
            base(
                '<path opacity="0.5" stroke="#000000" stroke-miterlimit="10" enable-background="new    " d="M191.6,224.5c6.1,1,12.2,1.7,19.8,0.4l-8.9,6.8c-0.5,0.4-1.3,0.4-1.8,0L191.6,224.5z"  /><path stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M196.4,229.2c-0.4,0.3-2.1-0.9-4.1-2.5c-1.9-1.6-3-2.7-2.6-2.9c0.4-0.3,2.5,0,4.2,1.8C195.4,227.2,196.8,228.8,196.4,229.2z"  /><path stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M206.5,228.7c0.3,0.4,2.2-0.3,4.2-1.7c2-1.5,3.5-2,3.2-2.4s-2.5-0.7-4.5,0.7C207.4,226.9,206.1,228.2,206.5,228.7z"  />',
                "Akuma"
            );
    }

    /// @dev Nose N°7 => Human
    function item_7() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M193.5,190.1c1.5,9,1.7,18.4-0.7,27.3h-0.1C193.2,208.2,194.4,199.2,193.5,190.1L193.5,190.1z" /></g><path display="inline" opacity="0.56" enable-background="new    " d="M198.6,231.3l-8.2-3.6c-0.4-0.2-0.5-0.7-0.2-1.1l3.3-3.4c0.4-0.4,1-0.5,1.6-0.3l13.2,4.8c0.6,0.2,0.6,1.1-0.1,1.4l-9.1,2.5C199,231.5,198.8,231.5,198.6,231.3z"  />',
                "Human"
            );
    }

    /// @dev Nose N°8 => Bleeding
    function item_8() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M193.5,190.1c1.5,9,1.7,18.4-0.7,27.3h-0.1C193.2,208.2,194.4,199.2,193.5,190.1L193.5,190.1z" /></g><path display="inline" opacity="0.56" enable-background="new    " d="M198.6,231.3l-8.2-3.6c-0.4-0.2-0.5-0.7-0.2-1.1l3.3-3.4c0.4-0.4,1-0.5,1.6-0.3l13.2,4.8c0.6,0.2,0.6,1.1-0.1,1.4l-9.1,2.5C199,231.5,198.8,231.5,198.6,231.3z"  /><g display="inline" ><path fill="#E90000" d="M204.7,242c0.7-0.3,1.1,0,1.1,0.7C204.2,243.4,201.3,243.5,204.7,242z" /><path fill="#FF0000" d="M205,229.5c0.5,3.1-1.1,6.4-0.1,9.6c0.8,1.6-0.6,2.9-2.2,3.1c-1.4-3.4,1.7-7.8,0.3-11.4C202.2,229.5,204.7,228.3,205,229.5z" /></g>',
                "Bleeding"
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Akuma";
        } else if (id == 2) {
            name = "Human";
        } else if (id == 3) {
            name = "Kitsune Blood";
        } else if (id == 4) {
            name = "Kitsune Moon";
        } else if (id == 5) {
            name = "Nosetril";
        } else if (id == 6) {
            name = "Kitsune Pure";
        } else if (id == 7) {
            name = "None";
        } else if (id == 8) {
            name = "Bleeding";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="nose"><g id="', name, '">', children, "</g></g>"));
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