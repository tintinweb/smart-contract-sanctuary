/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity >=0.8.1 <0.9.0;

contract FirstStorage {
    uint storedData;
    
    function set(uint x) public {
        storedData = x;
    }
    
    function get() public view returns (uint) {
        return storedData;
    }
}