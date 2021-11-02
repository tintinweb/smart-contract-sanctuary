// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract PPPandasV2 is Ownable, ERC721Enumerable {
    
    constructor()
        ERC721("PPPandas", "PPP") {
        _safeMint(msg.sender, 1);
    }
    
    //mint 
    function mint(address _address, uint _id) external {
        _safeMint(_address, _id);
    }
}