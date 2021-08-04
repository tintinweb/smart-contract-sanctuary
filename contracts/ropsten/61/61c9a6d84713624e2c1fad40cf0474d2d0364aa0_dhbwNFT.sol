// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./OZ-ERC721.sol";

contract dhbwNFT is ERC721 {
    address private owner;
    constructor() ERC721 ("DHBW-NFT", "DHBW"){
        owner = msg.sender;
        _safeMint(owner, 0, "2021");
    }
    function mint(address to, uint256 tokenId, bytes memory data) public virtual {
        require(msg.sender == owner);
        _safeMint(to, tokenId, data);
    }
}