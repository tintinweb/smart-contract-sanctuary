/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity >=0.5.0 <0.7.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function hello() public pure returns (string memory) {
        return "Hello World!";
    }
}