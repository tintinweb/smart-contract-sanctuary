/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-10
*/

pragma solidity >=0.4.0 <0.7.0;
contract SimpleStorage {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}