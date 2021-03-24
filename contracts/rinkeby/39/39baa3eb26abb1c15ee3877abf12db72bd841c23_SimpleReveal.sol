/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract SimpleReveal {
    string private baseUri;

    uint256[] public tokenIds;
    uint256 public tokenCount;

    
    uint256 public constant SALE_START_TIMESTAMP = 1616537970;
    uint256 public constant REVEAL_TIMESTAMP = 1616538930;

    constructor(string memory _baseUri, uint256[] memory _tokenIds) {
        baseUri = _baseUri;
        tokenIds = _tokenIds;
    }

    function tokenUri() public view returns (string memory) {
        return baseUri;
    }

    function tokenUri(uint256 tokenId) public view returns (string memory) {

        if(block.timestamp < REVEAL_TIMESTAMP) {
         return string(abi.encodePacked(tokenUri(), 'coverphoto.json'));
        }

        for (uint i = 0; i < tokenCount; i++) {
            if(tokenIds[i] == tokenId) {
                return string(abi.encodePacked(tokenUri(), tokenIds[i], ".json" ));
                // return baseUri + "/" + tokenIds[i];
            }

        }
        return "";
    }
}