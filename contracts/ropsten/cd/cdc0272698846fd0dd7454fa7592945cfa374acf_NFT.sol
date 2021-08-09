// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';

contract NFT is ERC721Enumerable{
    
    constructor() ERC721("My first NFT", "FNFT") {
        
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }
    
    function payment() public payable {
        require(msg.value == 1000000000000000, "0.1 bnb should be paid");
    }
    
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual override {
        _data = "";
        super._safeMint(to, tokenId, _data);
        payment();
    }
}