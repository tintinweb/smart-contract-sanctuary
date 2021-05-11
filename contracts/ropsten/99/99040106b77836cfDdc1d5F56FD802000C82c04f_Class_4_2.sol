/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//daehyuk kim

pragma solidity 0.8.0;

contract Class_4_2 {
    
    bytes32 hash;
    
    string[] word;
    
    function hashing(string memory _word) public{
    
        hash = keccak256(abi.encodePacked(_word)); {
            
            bytes32 word = keccak256(abi.encodePacked(_word));
            
        }
    
    }
    
}