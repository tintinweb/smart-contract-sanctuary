/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint x;

    function set(uint newValue) public {
        x = newValue;
    }
    
    function get() public returns (uint) {
        return x;
    }
}