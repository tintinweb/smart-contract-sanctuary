/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract BaseUrl{

    struct token{
        string name;
        uint id;
        string url;    
    }
   
    uint public ID=0;
    mapping(uint=>token)public tokenIds;

    function tokenIdUrl(string memory _name,uint _id, string memory _url)public{
        ID += 1;
        tokenIds[ID].name = _name;
        tokenIds[ID].id = _id;
        tokenIds[ID].url = _url;
    }
    
}