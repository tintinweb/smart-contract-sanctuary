/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity ^0.5.0;


contract Randomizer {
    
    uint256 value = 100;
     
     function returnValue() external view returns(bytes32) {
         return bytes32(value);
     }
}