/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract nftContract{
    
    uint countId;
    
    struct Nft{
        uint id;
        string name;
        string category;
    }
    
    mapping(address => Nft[]) public mapNft;
    
    function insertNft(string memory _name, string memory _category) public {
        mapNft[msg.sender].push(Nft(countId, _name, _category));
        countId++;
    }
    
    function getNft(uint _index) public view returns(uint, string memory, string memory){
        uint id = mapNft[msg.sender][_index].id;
        string memory name = mapNft[msg.sender][_index].name;
        string memory category = mapNft[msg.sender][_index].category;
        return (id, name, category);
    }
    
    
    
    
    
    
}