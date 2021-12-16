/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManagerItems {

    address impl_;
    address public manager;

    function getTokenURI(uint256 id) external view returns (string memory) {
        if (id == 1) {
            return getPotionsURI();
        }
    }

    function getPotionsURI() public view returns (string memory) {
        string memory svg = Base64.encode(bytes(getPotionSvg()));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Potion", "description":"EtherOrcs Items is a collection of various consumables that aid Orcs and their Allies within the greater EtherOrcs ecosystem.", "image": "data:image/svg+xml;base64,',
                                svg,
                                '","attributes": []}'
                            )
                        )
                    )
                )
            );
    }

    function getPotionSvg() public view returns(string memory) {
       return  '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/><style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';
    }

}



// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
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