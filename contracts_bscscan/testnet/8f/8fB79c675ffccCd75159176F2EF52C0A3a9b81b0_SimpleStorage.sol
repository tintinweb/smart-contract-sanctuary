/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

pragma solidity ^0.7.6;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}