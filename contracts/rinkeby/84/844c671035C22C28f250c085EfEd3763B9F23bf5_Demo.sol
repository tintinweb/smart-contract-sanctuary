/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.8.0;

contract Demo {
    uint storedData;

    function set(uint x) public {
      storedData = x;
    }

    function get() public view returns (uint) {
      return (storedData);
    }
}