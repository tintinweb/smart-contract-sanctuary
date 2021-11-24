// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LuuLawson is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter ID; // initially 0

    uint256 public price;
    string[] private metadata;
    constructor(string[] memory links, uint256 _price) ERC721("Luu + Lawson", "LUULAW"){
        price = _price;
        metadata = links;
    }

    function addLinks(string[] memory links) public onlyOwner {
        for(uint256 i = 0; i < links.length; i++) {
            metadata.push(links[i]);
        }
    }

    function buy() public payable {
        require(Counters.current(ID) < metadata.length, "Sold out");
        require(msg.value == price, "Incorrect amount of ETH sent");
        
        
        // Pay contract owner
        (bool success,) = owner().call{value: msg.value}("");
        require(success, "Transfer failed");
        uint256 currID = Counters.current(ID);
        _tokenURI[currID] = metadata[currID];
        
        // Increment ID counter
        Counters.increment(ID);
        
        // Mint NFT to user wallet
        _mint(_msgSender(), currID);
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

}