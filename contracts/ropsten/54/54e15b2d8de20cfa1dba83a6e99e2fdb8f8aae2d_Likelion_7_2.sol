/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

//young do jang

pragma solidity 0.8.0;

contract Likelion_7_2 {
    bytes32 targetValue;
    bytes32 hash2;
    
    function hash(uint a, uint b) public returns(bytes32) {
        targetValue = keccak256(abi.encodePacked(a,b));
        return targetValue;
    }
    
    function calculation(uint c, bytes32 d) public returns(uint) {
        c = 16;
        d = targetValue;
        
        for(uint i= 1 ; i< 100; i++) {
            hash2 = keccak256(abi.encodePacked(c,d,i));
           
            if(hash2 < targetValue) {
                return i;
            }
            return i;
        }
        
        
        
        
    }
    
    
}