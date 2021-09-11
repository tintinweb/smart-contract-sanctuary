/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.8.0;

contract SimpleStorage {
    string value;

    function set(string memory x) public {
        value = x;
    }

    function get() public view returns (string memory) {
        return value;
    }
}