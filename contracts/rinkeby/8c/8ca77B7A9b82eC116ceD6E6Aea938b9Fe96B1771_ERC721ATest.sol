// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract ERC721ATest is Ownable, ERC721A{
    
    constructor() ERC721A("ERC721ATest","ERC721AT",10,7000){

    }

    function mint(uint256 quantity)public payable {
        require(totalSupply() + quantity <= 7000,"koleksiyon siniri asildi");
        require(_numberMinted(msg.sender) + quantity <= 10,"en fazla 10 adet mintleyebilirsin");
        _safeMint(msg.sender,quantity);
    }

    function destroy(address payable addr)public{
        
        selfdestruct(addr);
    }

}