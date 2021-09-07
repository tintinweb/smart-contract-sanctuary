/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.7.0;

contract SimpleStorage123 {
    uint storedData;
    
    function set(uint x) public {
        storedData = x;
    }
    
    function get() public view returns (uint) {
        return storedData;
    }
}