/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract documentos {
    address private owner;
    struct documentDATA {
        string hash;
        string filename;
    }
    documentDATA [] public documents;
    
    function addDocument(string calldata _hash, string calldata _filename) public{
        documents.push(documentDATA(_hash, _filename));
    }
    
    
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    
}