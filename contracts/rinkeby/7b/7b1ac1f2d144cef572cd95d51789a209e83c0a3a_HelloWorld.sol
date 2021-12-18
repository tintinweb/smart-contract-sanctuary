/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract HelloWorld {
          uint256 version = 1; //slot 0
        string wellcomeString="hello 1"; //slot 0
    
    function getData() public view returns (string memory) {
        return wellcomeString;
    }

    function setData(string memory newData) public{
        wellcomeString=newData;
          }
    
}