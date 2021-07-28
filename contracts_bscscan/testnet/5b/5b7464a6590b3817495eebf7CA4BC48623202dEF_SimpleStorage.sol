/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.8.0;

contract SimpleStorage {
  uint public data;

  function updateData(uint _data) external {
    data = _data;
  }

  function readData() external view returns(uint) {
    return data;
  }
}