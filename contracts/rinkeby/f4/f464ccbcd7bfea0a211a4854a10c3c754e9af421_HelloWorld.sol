/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract HelloWorld {
        string wellcomeString="hello 1"; //slot 0
    
    function getData() public view returns (string memory) {
        return wellcomeString;
    }

    function setData(string memory newData) public{
        wellcomeString=newData;
          }
    
}