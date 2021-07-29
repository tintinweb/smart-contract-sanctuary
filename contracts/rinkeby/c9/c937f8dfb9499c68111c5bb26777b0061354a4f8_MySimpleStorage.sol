/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity >=0.5.0 <0.7.0;

contract MySimpleStorage {
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