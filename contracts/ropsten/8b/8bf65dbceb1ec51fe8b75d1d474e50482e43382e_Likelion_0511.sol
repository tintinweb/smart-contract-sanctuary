/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// Ko Eun NA

pragma solidity 0.8.0;

contract Likelion_0511 {
    
    bytes32 hash;
    function hashing(uint a, uint b) public{
        hash = keccak256(abi.encodePacked(a, b));
    }
    
    function matching() public view returns(uint, uint, uint, uint) {
        for(uint a=0;a<10;a++) {
            for(uint b=0; b<10; b++) {
                bytes32 password = keccak256(abi.encodePacked(a, b));
                if(password == hash) {
                    return(2, 4, a, b);
                }
            }
        }
        return(404, 404, 404, 404);
    }
}