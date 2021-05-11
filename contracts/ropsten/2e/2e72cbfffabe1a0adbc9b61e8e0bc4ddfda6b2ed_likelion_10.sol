/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// GyungHwan Lee

pragma solidity 0.8.0;

contract likelion_10 {
    bytes32 hash;
    uint c = 2;
    uint d = 9;
    uint e = 0;
    uint f = 4;
    
    function hashing(uint a, uint b) public {
        hash = keccak256(abi.encodePacked(a, b, c, d));
    }
    
    function matching() public view returns(bool, uint, uint) {
        for(uint a=0; a<10; a++) {
          for(uint b=0; b<10; b++) {
            bytes32 password = keccak256(abi.encodePacked(e, f, a, b));
            if(password == hash) {
                return(true, a, b);
            }
          }
        }
        
        return(false, 404, 404);
    }
}