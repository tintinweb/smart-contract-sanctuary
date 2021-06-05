/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity ^0.4.19;


contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}