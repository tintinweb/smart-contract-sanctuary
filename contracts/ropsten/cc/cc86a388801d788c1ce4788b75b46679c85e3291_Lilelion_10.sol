/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//im yuri

pragma solidity 0.8.0;

contract Lilelion_10 {
   bytes32 hash;
    function hashing(uint a, uint b) public{
        hash = keccak256(abi.encodePacked(a, b));
    }
    
    function matching() public view returns(bool, uint, uint) {
        uint a =2; 
        uint b =9;
            bytes32 password = keccak256(abi.encodePacked(a, b));
            if(password == hash) {
                return(true, a, b);
            }
        }
        
        
    }