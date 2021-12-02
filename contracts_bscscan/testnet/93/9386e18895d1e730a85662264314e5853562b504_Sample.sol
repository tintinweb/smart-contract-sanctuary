/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Sample {

  string _data;

  function getData() public view returns(string memory) {

    return _data;

  }

  function setData() public {

   _data = "Hello, this is a smart contract written in solidity and stored on the blockchain";

  }

}