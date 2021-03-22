/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity >=0.4.22 <0.7.0;

contract a {

    uint256 public storedData;

    function set(uint256 data) public {
        storedData = data;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}