/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity ^0.8.6;

library MathLibrary {
    
    //function that returns a * b and the requesting address 
    function multiply(uint a, uint b) internal view returns (uint, address) {
        return (a * b, address(this));
    }
}