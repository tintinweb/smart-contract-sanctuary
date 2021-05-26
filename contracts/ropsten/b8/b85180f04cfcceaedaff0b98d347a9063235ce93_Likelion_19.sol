/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//yeong hae
pragma solidity 0.8.0;

contract Likelion_19{
    
    mapping(string => mapping(string => uint)) poll;
    string sugg;
    
    function suggestion(string memory sug) public {
        sugg = sug;
        poll[sug]["approval"] = 0;
        poll[sug]["oppose"] = 0;
    }
    
    function opinion(string memory opin) public{
        require( keccak256(bytes(opin))==keccak256(bytes("approval")) || keccak256(bytes(opin))==keccak256(bytes("oppose")) );
        
        uint apCount = 0;
        uint opCount = 0;
        
        if(keccak256(bytes(opin))==keccak256(bytes("approval"))){
            poll[sugg]["approval"] = apCount + 1;
        }
        else{
            poll[sugg]["oppose"] = opCount + 1;
        }
        
    }
    
}