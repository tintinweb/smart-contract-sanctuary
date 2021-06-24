pragma solidity ^0.5.0;

import "./ERC721Full.sol";
import "./ERC721Holder.sol";
import "./Counters.sol";
//Full 721 function 0.5.17 compiler
contract ERC721FullContract is ERC721Full, ERC721Holder {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory name, 
        string memory symbol,
        string memory baseURI
    ) ERC721Full(name, symbol) public {
        _setBaseURI(baseURI);
    }

    function awardItem(address player, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
    
    
}