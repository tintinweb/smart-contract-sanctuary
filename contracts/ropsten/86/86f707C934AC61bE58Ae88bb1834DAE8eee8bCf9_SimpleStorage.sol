/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity >=0.5.8;

contract SimpleStorage {
    uint256 storedData;

    function set(uint256 x) public {
        storedData = x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}