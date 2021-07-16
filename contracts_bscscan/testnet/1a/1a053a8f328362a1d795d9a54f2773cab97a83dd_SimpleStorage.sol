/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity 0.4.24;

contract SimpleStorage {
    uint storeddata;

    function set(uint x) public {
        storeddata = x;
    }

    function get() public view returns(uint) {
        return storeddata; 
    }
}