/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-18
*/

pragma solidity ^0.5.0;

contract Test {   
   
   uint length = 100;
   //uint time = 100;
    function random() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, length)));
    }
    
     function random1() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp + 5, length)));
    }
}