/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// Seo sangcheol

pragma solidity 0.8.1;

contract Likelion_12 {
    
    
    function block() public returns(bytes32) {
        bytes32 hash;
         for(uint i=0; i<3; i++) {
            return keccak256(abi.encodePacked(i));  
        }
    }
    
    function mul(uint a, uint b) public view returns(uint,uint) {
        return (a*b, a**b);
    }
}