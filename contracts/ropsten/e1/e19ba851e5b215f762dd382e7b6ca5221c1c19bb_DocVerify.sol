/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.11;

contract DocVerify {
   
    address public creator;
    uint public numDocuments;
    string Documentname;
    string hash;
    function newdocument(string Documentname,string hash) public  returns (bool success){ 
        Documentname = Documentname;
        hash = hash;
        return success;
    }

    
}