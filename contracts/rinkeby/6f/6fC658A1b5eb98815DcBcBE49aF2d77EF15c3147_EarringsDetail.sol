// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Earrings SVG generator
library EarringsDetail {
    /// @dev Earrings N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Earrings N°2 => Circle
    function item_2() public pure returns (string memory) {
        return base(circle("000000"));
    }

    /// @dev Earrings N°3 => Circle Silver
    function item_3() public pure returns (string memory) {
        return base(circle("C7D2D4"));
    }

    /// @dev Earrings N°4 => Ring
    function item_4() public pure returns (string memory) {
        return base(ring("000000"));
    }

    /// @dev Earrings N°5 => Circle Gold
    function item_5() public pure returns (string memory) {
        return base(circle("FFDD00"));
    }

    /// @dev Earrings N°6 => Ring Gold
    function item_6() public pure returns (string memory) {
        return base(ring("FFDD00"));
    }

    /// @dev Earrings N°7 => Heart
    function item_7() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M284.3,247.9c0.1,0.1,0.1,0.1,0.2,0.1s0.2,0,0.2-0.1l3.7-3.8c1.5-1.6,0.4-4.3-1.8-4.3c-1.3,0-1.9,1-2.2,1.2c-0.2-0.2-0.8-1.2-2.2-1.2c-2.2,0-3.3,2.7-1.8,4.3L284.3,247.9z"/>',
                        '<path d="M135,246.6c0,0,0.1,0.1,0.2,0.1s0.1,0,0.2-0.1l3.1-3.1c1.3-1.3,0.4-3.6-1.5-3.6c-1.1,0-1.6,0.8-1.8,1c-0.2-0.2-0.7-1-1.8-1c-1.8,0-2.8,2.3-1.5,3.6L135,246.6z"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°8 => Gold
    function item_8() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M298.7,228.1l-4.7-1.6c0,0-0.1,0-0.1-0.1v-0.1c2.8-2.7,7.1-17.2,7.2-17.4c0-0.1,0.1-0.1,0.1-0.1l0,0c5.3,1.1,5.6,2.2,5.7,2.4c-3.1,5.4-8,16.7-8.1,16.8C298.9,228,298.8,228.1,298.7,228.1C298.8,228.1,298.8,228.1,298.7,228.1z" style="fill: #fff700;stroke: #000;stroke-miterlimit: 10;stroke-width: 0.75px"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°9 => Circle Diamond
    function item_9() public pure returns (string memory) {
        return base(circle("AAFFFD"));
    }

    /// @dev Earrings N°10 => Drop Heart
    function item_10() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        drop(true),
                        '<path fill="#F44336" d="M285.4,282.6c0.1,0.1,0.2,0.2,0.4,0.2s0.3-0.1,0.4-0.2l6.7-6.8c2.8-2.8,0.8-7.7-3.2-7.7c-2.4,0-3.5,1.8-3.9,2.1c-0.4-0.3-1.5-2.1-3.9-2.1c-4,0-6,4.9-3.2,7.7L285.4,282.6z"/>',
                        drop(false),
                        '<path fill="#F44336" d="M134.7,282.5c0.1,0.1,0.2,0.2,0.4,0.2s0.3-0.1,0.4-0.2l6.7-6.8c2.8-2.8,0.8-7.7-3.2-7.7c-2.4,0-3.5,1.8-3.9,2.1c-0.4-0.3-1.5-2.1-3.9-2.1c-4,0-6,4.9-3.2,7.7L134.7,282.5z"/>'
                    )
                )
            );
    }

    /// @dev Earrings N11 => Ether
    function item_11() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path d="M285.7,242.7l-4.6-2.2l4.6,8l4.6-8L285.7,242.7z"/>',
                        '<path d="M289.8,238.9l-4.1-7.1l-4.1,7.1l4.1-1.9L289.8,238.9z"/>',
                        '<path d="M282,239.9l3.7,1.8l3.8-1.8l-3.8-1.8L282,239.9z"/>',
                        '<path d="M134.5,241.8l-3.4-1.9l3.7,7.3l2.8-7.7L134.5,241.8z"/>',
                        '<path d="M137.3,238l-3.3-6.5l-2.5,6.9l2.8-2L137.3,238z"/>',
                        '<path d="M131.7,239.2l2.8,1.5l2.6-1.8l-2.8-1.5L131.7,239.2z"/>'
                    )
                )
            );
    }

    /// @dev Earrings N°12 => Drop Ether
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        drop(true),
                        '<path d="M285.7,279.7l-4.6-2.2l4.6,8l4.6-8L285.7,279.7z"/>',
                        '<path d="M289.8,275.9l-4.1-7.1l-4.1,7.1l4.1-1.9L289.8,275.9z"/>',
                        '<path d="M282,276.9l3.7,1.8l3.8-1.8l-3.8-1.8L282,276.9z"/><path d="M282,276.9l3.7,1.8l3.8-1.8l-3.8-1.8L282,276.9z"/>',
                        drop(false),
                        '<path d="M135.1,279.7l-4-2.2l4,8l4-8L135.1,279.7z"/>',
                        '<path d="M138.7,275.9l-3.6-7.1l-3.6,7.1l3.6-1.9L138.7,275.9z"/>',
                        '<path d="M131.8,276.9l3.3,1.8l3.3-1.8l-3.3-1.8L131.8,276.9z"/>'
                    )
                )
            );
    }

    /// @dev earring drop
    function drop(bool right) private pure returns (string memory) {
        return
            string(
                right
                    ? abi.encodePacked(
                        '<circle cx="285.7" cy="243.2" r="3.4"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="285.7" y1="243.2" x2="285.7" y2="270.2"/>'
                    )
                    : abi.encodePacked(
                        '<ellipse cx="135.1" cy="243.2" rx="3" ry="3.4"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="135.1" y1="243.2" x2="135.1" y2="270.2"/>'
                    )
            );
    }

    /// @dev Generate circle SVG with the given color
    function circle(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<ellipse fill="#',
                    color,
                    '" stroke="#000000" cx="135.1" cy="243.2" rx="3" ry="3.4"/>',
                    '<ellipse fill="#',
                    color,
                    '" stroke="#000000" cx="286.1" cy="243.2" rx="3.3" ry="3.4"/>'
                )
            );
    }

    /// @dev Generate ring SVG with the given color
    function ring(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="none" stroke="#',
                    color,
                    '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M283.5,246c0,0-4.2,2-3.1,6.1c1,4.1,5.1,3.6,5.4,3.5s3.1-0.9,3-5"/>',
                    '<path fill="none" stroke="#',
                    color,
                    '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" d="M134.3,244.7c0,0-4.2,2-3.1,6.1c1,4.1,5.1,3.6,5.4,3.5c0.3-0.1,3.1-0.9,3-5"/>'
                )
            );
    }

    /// @notice Return the earring name of the given id
    /// @param id The earring Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Circle";
        } else if (id == 3) {
            name = "Circle Silver";
        } else if (id == 4) {
            name = "Ring";
        } else if (id == 5) {
            name = "Circle Gold";
        } else if (id == 6) {
            name = "Ring Gold";
        } else if (id == 7) {
            name = "Heart";
        } else if (id == 8) {
            name = "Gold";
        } else if (id == 9) {
            name = "Circle Diamond";
        } else if (id == 10) {
            name = "Drop Heart";
        } else if (id == 11) {
            name = "Ether";
        } else if (id == 12) {
            name = "Drop Ether";
        }
    }

    /// @dev The base SVG for the earrings
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Earrings">', children, "</g>"));
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

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}