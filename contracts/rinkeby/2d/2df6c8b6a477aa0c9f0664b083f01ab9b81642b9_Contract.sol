/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
contract Contract {
    struct Doc{
        uint DocumentID;
        string Hash;
    }
    mapping(uint => Doc) public Docs;
    uint [] public DocAcct;
  
    function setDocHash(uint _docID, string memory _hash) public {
        Doc storage objDoc = Docs[_docID];
        objDoc.DocumentID = _docID;
        objDoc.Hash = _hash;
        DocAcct.push(_docID);
    }        
    function getDocs() view public returns (uint[] memory ){
      return DocAcct;
    }
    function getDoc(uint _docID) view public returns (uint ,string memory){
      return (Docs[_docID].DocumentID,Docs[_docID].Hash);
    }
}