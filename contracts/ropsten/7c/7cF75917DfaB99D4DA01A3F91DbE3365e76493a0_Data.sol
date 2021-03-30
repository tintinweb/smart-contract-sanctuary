/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.5.0;
contract Data {
  string public data;
  constructor ()public{
    data = "";
  }
  function setData(string memory str) public{
    data = str;
  }
  function getData() public view returns (string memory) {
    return data;
  }
}