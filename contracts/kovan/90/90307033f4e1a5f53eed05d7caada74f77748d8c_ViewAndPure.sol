/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.7.6;

contract ViewAndPure {
    uint public x = 1;
    uint public count;
    
    
    // Promise not to modify the state.
    function addToX(uint y) public returns (uint) {
        uint ez = x + y;
        x = ez;
        return ez;
    }

}