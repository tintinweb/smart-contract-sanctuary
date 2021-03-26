/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.11;

contract DocVerify {
   
    address public creator;
    uint public numDocuments;
    string owner;
    string series;
    string title;
    function newdocument(string hash,string owner,string series,string title) public  returns (bool success){ 
        owner = owner;
        series = series;
        title = title;
        hash = hash;
        return success;
    }

    
}