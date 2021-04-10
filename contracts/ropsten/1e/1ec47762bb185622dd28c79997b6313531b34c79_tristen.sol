/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.7.0;

contract tristen{
    
    //struct
    struct Doc{
        string Name;
        string Last;
        uint signId;
        string HashId;
    }

    // mapping 
    
    mapping(string => Doc) docs;
    
    // read functions
    function readDocs(string memory _hashId) public view returns (string memory, string memory, uint, string memory){
        Doc storage d = docs[_hashId];
        return(d.Name,
        d.Last, 
        d.signId,
        d.HashId );
    }
    
    
    // write fuctions
    function writeDoc(string memory _name , string memory _lastName, uint _signId, string memory _hashId) public{
        Doc storage d = docs[_hashId];
        d.Name = _name;
        d.Last = _lastName;
        d.signId = _signId;
        d.HashId = _hashId;
        
    }
}