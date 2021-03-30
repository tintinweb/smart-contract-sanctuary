/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.11;

contract DocVerify {
   struct Document {
        address owner;
        uint date;
    }
    address public creator;
    uint public numDocuments;
    mapping(bytes32 => Document) public documentHashMap;
    string owner;
    string series;
    string title;
    function newdocument(bytes32 hash,string owner,string series,string title) public  returns (bool success){ 
         if (documentExists(hash)) {
             success = false;
         }else{
            Document storage d = documentHashMap[hash];
            d.owner = msg.sender;
            d.date = now;
            owner = owner;
            series = series;
            title = title;
            success = true;
         }
        
        return success;
        
    }
    
    function documentExists(bytes32 hash) public  returns (bool exists) {
        if (documentHashMap[hash].date > 0) {
            exists = true;
        } else {
            exists = false;
        }
        return exists;
       
    }
   function getDocument(bytes32 hash) public  returns (uint date, address owner) {
        date = documentHashMap[hash].date;
        owner = documentHashMap[hash].owner;
    }

    function getNumDocs() public  returns (uint numDocs) {
        return numDocuments;
    }
    

    
}