/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

//Younwoo Noh

pragma solidity 0.8.0;

contract Likelion_7_2 {
    bytes32 hash;
    
    function hashing(uint a, uint b) public {
        hash = keccak256(abi.encodePacked(a, b));
    }
    
    function matching() public view returns(bool, uint, uint) {
        for(uint a=0; a<10; a++) {
            for(uint b=0; b<10; b++) {
                bytes32 password = keccak256(abi.encodePacked(a, b));
                if(password == hash) {
                    return(true, a, b);
                }
            }
        }
        return(false, 404, 404);
    }
}