/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity ^0.8.11;

contract SimpleStorage {
    string storedData;

    function set(string memory x) public {
        storedData = x;
    }

    function get() public view returns (string memory) {
       return storedData;
    }
}