/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.7.0;

contract SimpleStorage456 {
    uint storedData;
    uint storedData2;
    
    function set(uint x) public {
        storedData = x;
        storedData2 = x;
    }
    
    function get() public view returns (uint) {
        return storedData;
    }
}