// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FullERC721.sol";

contract PToken is ERC721Enumerable, ReentrancyGuard, Ownable {
    
      function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = "test1";
        parts[2] = '</text><text x="10" y="40" class="base">';
        parts[3] = "test2";
        parts[4] = '</text><text x="10" y="60" class="base">';
        parts[5] = "test3";
        parts[6] = '</text><text x="10" y="80" class="base">';
        parts[7] = "test4";
        parts[8] = '</text><text x="10" y="100" class="base">';
        parts[9] = "test5";
        parts[10] = '</text><text x="10" y="120" class="base">';
        parts[11] = "test6";
        parts[12] = '</text><text x="10" y="140" class="base">';
        parts[13] = "test7";
        parts[14] = '</text><text x="10" y="160" class="base">';
        parts[15] = "test8";
        parts[16] = '</text></svg>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', Strings.toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        _safeMint(_msgSender(), tokenId);
    }
    
    constructor() ERC721("PToken", "PTOKEN") Ownable() {}
    
}