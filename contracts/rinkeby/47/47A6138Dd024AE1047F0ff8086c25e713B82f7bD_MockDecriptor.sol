// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Base64} from '../utils/Base64.sol';
import {IDescriptor} from '../IDescriptor.sol';

contract MockDecriptor is IDescriptor {
  // using Base64 for string;

  // Metadata example: {"attributes":[{"trait_type":"base","value":"ape"},{"trait_type":"neck","value":"high neck"},{"trait_type":"facial hair","value":"nope"},{"trait_type":"earrings","value":"golden"},{"trait_type":"head","value":"kangaroo hat"},{"trait_type":"glasses","value":"nope"},{"trait_type":"lipstick","value":"nope"},{"trait_type":"smoking","value":"nope"},{"display_type":"number","trait_type":"generation","value":1}],"description":"Decentralists collector's edition: A set of unique and original 8000 pixel-art outsiders leading the crypto revolution.","image":"<svg xmlns='http://www.w3.org/2000/svg' shape-rendering='crispEdges' viewBox='0 -.5 24 24'><path stroke='#000' d='M9 5h7M8 6h1m7 0h1M7 7h1m9 0h1M7 8h1m9 0h1M7 9h1m9 0h1M7 10h1m9 0h1M6 11h2m9 0h1M6 12h1m3 0h1m4 0h1m1 0h1M6 13h1m10 0h1M6 14h2m4 0h1m1 0h1m2 0h1M7 15h1m9 0h1M7 16h1m9 0h1M7 17h1m1 0h1m1 0h5m1 0h1M7 18h1m1 0h1m7 0h1M7 19h1m2 0h1m5 0h1M7 20h1m3 0h5m-9 1h1m3 0h1m-5 1h1m3 0h1m-5 1h1m3 0h1'/><path stroke='#362409' d='M9 6h7M8 7h9M8 8h9M8 9h2m3 0h2m-7 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h2m-2 1h3m5 0h1m-9 1h2m-2 1h1m-1 1h1m-1 1h2m-2 1h3m-3 1h3m-3 1h3m-3 1h3'/><path stroke='#a48b73' d='M10 9h3m2 0h2m-8 1h8m-8 1h1m2 0h3m-8 1h1m1 0h1m2 0h3m-8 1h1m1 0h8m-7 1h2m1 0h1m1 0h2m-6 1h5m-6 1h7m-7 1h1m5 0h1m-7 1h7m-6 1h5'/><path stroke='#887360' d='M10 11h2m3 0h2'/><path stroke='#ceaf92' d='M11 12h1m4 0h1'/><path stroke='#000' d='M8 22h4m-4 1h4'/><path stroke='#ffcd00' d='M6 14h1'/><path stroke='#000' d='M9 4h7M8 5h5m1 0h3M7 6h5m2 0h4M6 7h12M5 8h13M5 9h2'/><path stroke='#fff' d='M13 5h1m-2 1h2'/></svg>","name":"Decentralist #0001"}
  string public constant svg1 =
    "<svg xmlns='http://www.w3.org/2000/svg' shape-rendering='crispEdges' viewBox='0 -.5 24 24'><path stroke='#000' d='M9 5h7M8 6h1m7 0h1M7 7h1m9 0h1M7 8h1m9 0h1M7 9h1m9 0h1M7 10h1m9 0h1M6 11h2m9 0h1M6 12h1m3 0h1m4 0h1m1 0h1M6 13h1m10 0h1M6 14h2m4 0h1m1 0h1m2 0h1M7 15h1m9 0h1M7 16h1m9 0h1M7 17h1m1 0h1m1 0h5m1 0h1M7 18h1m1 0h1m7 0h1M7 19h1m2 0h1m5 0h1M7 20h1m3 0h5m-9 1h1m3 0h1m-5 1h1m3 0h1m-5 1h1m3 0h1'/><path stroke='#362409' d='M9 6h7M8 7h9M8 8h9M8 9h2m3 0h2m-7 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h2m-2 1h3m5 0h1m-9 1h2m-2 1h1m-1 1h1m-1 1h2m-2 1h3m-3 1h3m-3 1h3m-3 1h3'/><path stroke='#a48b73' d='M10 9h3m2 0h2m-8 1h8m-8 1h1m2 0h3m-8 1h1m1 0h1m2 0h3m-8 1h1m1 0h8m-7 1h2m1 0h1m1 0h2m-6 1h5m-6 1h7m-7 1h1m5 0h1m-7 1h7m-6 1h5'/><path stroke='#887360' d='M10 11h2m3 0h2'/><path stroke='#ceaf92' d='M11 12h1m4 0h1'/><path stroke='#000' d='M8 22h4m-4 1h4'/><path stroke='#ffcd00' d='M6 14h1'/><path stroke='#000' d='M9 4h7M8 5h5m1 0h3M7 6h5m2 0h4M6 7h12M5 8h13M5 9h2'/><path stroke='#fff' d='M13 5h1m-2 1h2'/></svg>";
  string public constant svg2 =
    "<svg xmlns='http://www.w3.org/2000/svg' shape-rendering='crispEdges' viewBox='0 -.5 24 24'><path stroke='#000' d='M9 7h6M8 8h1m6 0h1M7 9h1m8 0h1M5 10h1m1 0h1m8 0h1M5 11h3m8 0h1M5 12h1m10 0h1M6 13h1m9 0h1M6 14h2m8 0h1M7 15h1m8 0h1M7 16h1m4 0h1m3 0h1M7 17h1m8 0h1M7 18h1m8 0h1m-9 1h1m6 0h1m-8 1h1m1 0h1m3 0h1m-7 1h1m2 0h3m-6 1h1m3 0h1m-5 1h1m3 0h1'/><path stroke='#edebe6' d='M9 8h6M8 9h1m1 0h6m-8 1h8m-8 1h8M6 12h3m2 0h3m-7 1h2m2 0h3m-6 1h1m1 0h4m1 0h1m-8 1h8m-8 1h4m1 0h3m-8 1h8m-8 1h3m3 0h2m-7 1h2m1 0h3m-6 1h1m2 0h2m-5 1h2m-2 1h3m-3 1h3'/><path stroke='#fffddd' d='M9 9h1'/><path stroke='#b8ab9d' d='M9 12h2m3 0h2m-7 2h1m4 0h1'/><path stroke='#e20015' d='M9 13h1m4 0h1m-4 5h1m-1 1h1m-1 1h1'/><path stroke='#f7b8a0' d='M10 13h1m4 0h1'/><path stroke='#6c1006' d='M12 18h1'/><path stroke='#fff' d='M13 18h1'/><path stroke='#00fdff' d='M9 22h3'/><path stroke='#00fdff' d='M6 14h1'/><path stroke='#ffe300' d='M10 5h4M8 6h8M7 7h10M7 8h10M7 9h11M7 10h2m4 0h1m1 0h3M6 11h2m8 0h2M6 12h2m8 0h2M6 13h1m9 0h2m-2 1h2m-2 1h3m-3 1h3m-3 1h3m-3 1h3m-3 1h3m-4 1h4m-5 1h5m-5 1h3'/><path stroke='#bfbfbf' d='M20 10h1m-2 1h3m-3 1h3m-2 1h1m-1 5h1'/><path stroke='#cbcbcb' d='M20 15h1'/><path stroke='#000' d='M15 17h6m-7 1h1m0 1h6'/><path stroke='#ff9000' d='M15 18h1'/><path stroke='#fff' d='M16 18h4'/></svg>";
  string public constant svg3 =
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 -0.5 24 24' shape-rendering='crispEdges'><path stroke='#000000' d='M9 5h7M8 6h1M16 6h1M7 7h1M17 7h1M7 8h1M17 8h1M7 9h1M17 9h1M5 10h3M17 10h1M5 11h1M17 11h1M5 12h1M17 12h1M6 13h1M17 13h1M6 14h2M17 14h1M7 15h1M13 15h1M17 15h1M7 16h1M17 16h1M7 17h1M12 17h3M17 17h1M7 18h1M17 18h1M7 19h1M16 19h1M7 20h1M11 20h5M7 21h1M11 21h1M7 22h1M11 22h1M7 23h1M11 23h1' /><path stroke='#98ffed' d='M9 6h7M8 7h2M11 7h6M8 8h1M10 8h7M8 9h9M8 10h9M6 11h4M12 11h3M6 12h4M12 12h3M7 13h10M8 14h9M8 15h5M14 15h3M8 16h9M8 17h4M15 17h2M8 18h9M8 19h8M8 20h3M8 21h3M8 22h3M8 23h3' /><path stroke='#fffddd' d='M10 7h1M9 8h1' /><path stroke='#5e9e94' d='M10 11h2M15 11h2' /><path stroke='#2b82a5' d='M10 12h1M15 12h1' /><path stroke='#bffcff' d='M11 12h1M16 12h1' /><path stroke='#000' d='M8 22h4m-4 1h4'/><path stroke='#000' d='M11 19h6m-5 1h4m-3 1h3m-2 1h1'/><path stroke='#ffcd00' d='M6 14h1'/><path stroke='#d7d7d7' d='M9 4h7M8 5h5m1 0h3M7 6h5m2 0h4M7 7h11M6 9h13M5 10h15'/><path stroke='#001032' d='M13 5h1m-2 1h2M7 8h11'/><path stroke='#000' d='M5 11h1m12 0h1'/><path stroke='#000' d='M10 9h2m4 0h2m-9 1h2m1 0h1m2 0h2m1 0h1M7 11h12M9 12h4m2 0h4m-9 1h2m4 0h2'/><path stroke='#fff' d='M11 10h1m5 0h1'/></svg>";

  string public constant name1 = 'Name #0001';
  string public constant name2 = 'Name #0002';
  string public constant name3 = 'Name #0003';

  string public constant description = 'My description of the token';

  function tokenURI(uint256 tokenId, uint256[] memory attributes)
    external
    view
    override
    returns (string memory)
  {
    return constructTokenURI(tokenId);
  }

  function constructTokenURI(uint256 tokenId) public view returns (string memory) {
    string memory image = generateSVGImage(tokenId);

    string memory nameToUse = name1;
    uint256 indexToUse = (tokenId % 3) + 1;
    if (indexToUse == 2) {
      nameToUse = name2;
    } else if (indexToUse == 3) {
      nameToUse = name3;
    }

    // prettier-ignore
    return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', nameToUse, '", "description":"', description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
  }

  function generateSVGImage(uint256 tokenId) public pure returns (string memory) {
    string memory svgToUse = svg1;
    uint256 indexToUse = (tokenId % 3) + 1;
    if (indexToUse == 2) {
      svgToUse = svg2;
    } else if (indexToUse == 3) {
      svgToUse = svg3;
    }
    return Base64.encode(bytes(svgToUse));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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
pragma solidity 0.8.7;

interface IDescriptor {
  function tokenURI(uint256 tokenId, uint256[] memory attributes) external view returns (string memory);

  // event PartsLocked();

  // event DataURIToggled(bool enabled);

  // event BaseURIUpdated(string baseURI);

  // function arePartsLocked() external returns (bool);

  // function isDataURIEnabled() external returns (bool);

  // function baseURI() external returns (string memory);

  // function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

  // function backgrounds(uint256 index) external view returns (string memory);

  // function bodies(uint256 index) external view returns (bytes memory);

  // function accessories(uint256 index) external view returns (bytes memory);

  // function heads(uint256 index) external view returns (bytes memory);

  // function glasses(uint256 index) external view returns (bytes memory);

  // function backgroundCount() external view returns (uint256);

  // function bodyCount() external view returns (uint256);

  // function accessoryCount() external view returns (uint256);

  // function headCount() external view returns (uint256);

  // function glassesCount() external view returns (uint256);

  // function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

  // function addManyBackgrounds(string[] calldata backgrounds) external;

  // function addManyBodies(bytes[] calldata bodies) external;

  // function addManyAccessories(bytes[] calldata accessories) external;

  // function addManyHeads(bytes[] calldata heads) external;

  // function addManyGlasses(bytes[] calldata glasses) external;

  // function addColorToPalette(uint8 paletteIndex, string calldata color) external;

  // function addBackground(string calldata background) external;

  // function addBody(bytes calldata body) external;

  // function addAccessory(bytes calldata accessory) external;

  // function addHead(bytes calldata head) external;

  // function addGlasses(bytes calldata glasses) external;

  // function lockParts() external;

  // function toggleDataURIEnabled() external;

  // function setBaseURI(string calldata baseURI) external;

  // function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

  // function genericDataURI(
  //     string calldata name,
  //     string calldata description,
  //     INounsSeeder.Seed memory seed
  // ) external view returns (string memory);

  // function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
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