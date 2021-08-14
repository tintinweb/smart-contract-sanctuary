/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract alito {
    address private owner;
    struct documentDATA {
        string hash;
        string filename;
    }
    documentDATA [] public documents;
    
    function addDocument(string calldata _hash, string calldata _filename) public{
        documents.push(documentDATA(_hash, _filename));
    }
    
    function getDocument() public view returns (documentDATA[] memory) {
        return documents;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    
}