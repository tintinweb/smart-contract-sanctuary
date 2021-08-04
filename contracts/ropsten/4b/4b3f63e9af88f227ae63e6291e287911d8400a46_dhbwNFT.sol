// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "./OZ-ERC721.sol";

contract dhbwNFT is ERC721 {
    constructor() ERC721 ("DHBW-NFT", "DHBW"){
        _safeMint(msg.sender, 0, "2021");
    }
}