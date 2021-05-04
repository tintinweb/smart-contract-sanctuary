/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// Ko Eun NA

pragma solidity 0.8.0;

contract Likelion6 {
    
    bytes32 hash;
    string[] members;
    
    function member(string memory name) public {
        if (keccak256(bytes(name)) != keccak256(bytes("James"))){
          members.push(name);
        }
    }
    
    function getName(uint i) public view returns(string memory) {
        return members[i];
    }
    
    function hashing(uint id, uint pw) public{
        hash = keccak256(abi.encodePacked(id,pw));
    }
    
    function login(uint id, uint pw) public view returns(bool, string memory){
         for(uint id = 0; id<8; id++){
            for(uint pw = 0; pw<8; pw++){
                bytes32 login = keccak256(abi.encodePacked(id, pw));
                
                if(login == hash) {
                    return(true, "LOGIN");
                }
            }
            
        }
        return(false,"Error");
    }
}