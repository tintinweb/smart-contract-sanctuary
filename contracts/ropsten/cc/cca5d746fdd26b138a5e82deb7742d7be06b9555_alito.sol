/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract alito {
    address private owner;
    struct documentDATA {
        string hash;
        string filename;
        string date;
    }
    documentDATA [] private documents;
    
    function addDocument(string calldata _hash, string calldata _filename, string calldata _date) public{
        documents.push(documentDATA(_hash, _filename, _date));
    }
    
    function getDocument() public view returns (documentDATA[] memory) {
        return documents;
    }
    
    function Orden() public view returns(uint256) {
        return documents.length;    
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    
}