/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.4.0;

contract SimpleStorage {
    
    uint storedData;

    function set(uint x) {
        storedData = x;
    }

    function get() constant returns (uint) {
        return storedData;
    }
    
}