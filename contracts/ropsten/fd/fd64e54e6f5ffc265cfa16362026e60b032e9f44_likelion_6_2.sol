/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// GyungHwan lee

pragma solidity 0.8.0;

contract likelion_6_2 {
    bytes32 hash;
    uint[] password;
    string[] id;
    
    function pushPassword(uint _password) public {
        password.push(_password);
    }
    
    function pushId(string memory _id) public {
        id.push(_id);
    }

    function hashing(string memory _id, uint _password) public {
        hash = keccak256(abi.encodePacked(_id, _password));
    }
    
    function matching() public view returns(bool, string memory, uint) {
        for(uint i=0; i<id.length; i++) {
          for(uint i=0; i<password.length; i++) {
            bytes32 idpassword = keccak256(abi.encodePacked(id[i], password[i]));
            if(idpassword == hash) {
                return(true, id[i], password[i]);
            }
          }
        }
        
        return(false, "error", 404);
    }
}