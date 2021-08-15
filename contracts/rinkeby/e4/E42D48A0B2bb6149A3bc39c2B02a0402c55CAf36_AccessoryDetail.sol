// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Accessory SVG generator
library AccessoryDetail {
    /// @dev Accessory N°1 => Nothing
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Accessory N°2 => Glasses
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<circle opacity="0.62" fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" cx="161.5" cy="201.7" r="23.9"/>',
                        '<circle opacity="0.62" fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" cx="232.9" cy="201.7" r="23.9"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="256.8" y1="201.7" x2="292.6" y2="198.5"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M185.5,201.7c0,0,14.7-3.1,23.5,0"/>',
                        '<line fill="none" stroke="#000000" stroke-miterlimit="10" x1="137.6" y1="201.7" x2="129.2" y2="198.5"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°3 => Saiki
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<polygon opacity="0.68" fill="#7FFF35" points="126,189.5 185.7,191.8 188.6,199.6 184.6,207.4 157.3,217.9 128.6,203.7"/>',
                        '<polygon opacity="0.68" fill="#7FFF35" points="265.7,189.5 206.7,191.8 203.8,199.6 207.7,207.4 234.8,217.9 263.2,203.7"/>',
                        '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.5,195.7 191.8,195.4 187,190.9 184.8,192.3 188.5,198.9 183,206.8 187.6,208.3 193.1,201.2 196.5,201.2"/>',
                        '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.4,195.7 201.1,195.4 205.9,190.9 208.1,192.3 204.4,198.9 209.9,206.8 205.3,208.3 199.8,201.2 196.4,201.2"/>',
                        '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="123.8,189.5 126.3,203 129.2,204.4 127.5,189.5"/>',
                        '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="265.8,189.4 263.3,203.7 284.3,200.6 285.3,189.4"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°4 => Horns
    function item_4() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" d="M257.7,96.3c0,0,35-18.3,46.3-42.9c0,0-0.9,37.6-23.2,67.6C269.8,115.6,261.8,107.3,257.7,96.3z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" d="M162,96.7c0,0-33-17.3-43.7-40.5c0,0,0.9,35.5,21.8,63.8C150.6,114.9,158.1,107.1,162,96.7z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°5 => Halo
    function item_5() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F6FF99" stroke="#000000" stroke-miterlimit="10" d="M136,67.3c0,14.6,34.5,26.4,77,26.4s77-11.8,77-26.4s-34.5-26.4-77-26.4S136,52.7,136,67.3L136,67.3z M213,79.7c-31.4,0-56.9-6.4-56.9-14.2s25.5-14.2,56.9-14.2s56.9,6.4,56.9,14.2S244.4,79.7,213,79.7z"/>'
                    )
                )
            );
    }

    /// @notice Return the accessory name of the given id
    /// @param id The accessory Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Nothing";
        } else if (id == 2) {
            name = "Glasses";
        } else if (id == 3) {
            name = "Saiki";
        } else if (id == 4) {
            name = "Horns";
        } else if (id == 5) {
            name = "Halo";
        }
    }

    /// @dev The base SVG for the accessory
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Accessory">', children, "</g>"));
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