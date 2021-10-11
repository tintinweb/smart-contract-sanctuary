/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity >=0.4.16 <0.7.0;
contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}