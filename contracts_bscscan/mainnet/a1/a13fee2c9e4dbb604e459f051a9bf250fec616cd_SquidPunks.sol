// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "ERC721URIStorage.sol";

contract SquidPunks is ERC721URIStorage {
    uint public counter;

    constructor() ERC721("SquidPunks", "SPunks") {
        counter = 1;
    }

    function createNFTs (string memory tokenURI) public returns (uint){
        uint tokenId = counter;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        counter ++;

        return tokenId;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "You are not the owner nor approved!");
        super._burn(tokenId);
    }
}