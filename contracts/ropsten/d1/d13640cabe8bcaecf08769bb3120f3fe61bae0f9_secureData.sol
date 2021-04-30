/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity 0.6.0;

contract secureData{
    
    // address myAddress;
    mapping(address => database) public myDatabase;
    
    struct database{
        address addressID;
        string hash;
        string fullName;
    }
    
    function addData(string memory hash, string memory fullName) public {
        address myAddress = msg.sender;
        myDatabase[myAddress] = database(myAddress,hash,fullName);
    }
    
}