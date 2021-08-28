// SPDX-License-Identifier: MIT
// Galaxy Heroes NFT game 
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HeadOfHero is ERC721Enumerable {

    constructor(string memory name_,
        string memory symbol_) ERC721(name_, symbol_)  {
    }

    
    function mint() external {
        require(balanceOf(msg.sender) == 0, "Only one");
        _mint(msg.sender, totalSupply());
    }
    
}