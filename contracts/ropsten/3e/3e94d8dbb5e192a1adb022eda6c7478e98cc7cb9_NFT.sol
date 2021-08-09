// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';

contract NFT is ERC721Enumerable{
    
    uint256 tokenId;
    constructor() ERC721("My first NFT", "FNFT") {
        
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }
    
    function PurchaseNFT() public payable {
        require(msg.value == 1000000000000000, "0.1 bnb should be paid");
        tokenId += 1;
        super._safeMint(msg.sender, tokenId);
    }
    
}