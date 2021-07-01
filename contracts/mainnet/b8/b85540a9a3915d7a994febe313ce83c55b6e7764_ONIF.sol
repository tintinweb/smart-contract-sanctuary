// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract ONIF is ERC721URIStorage {
    
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;

    event NewCreateItem(uint256, address);
    
    constructor () ERC721("Onbuff Nft Type 1", "ONIF") {
    }
    
    function exists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }
    
    function mint(string memory contentURI, address creator ) public {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _mint(creator, tokenId);
        _setTokenURI(tokenId, contentURI);
        
        emit NewCreateItem(tokenId, creator);
    }
    

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}