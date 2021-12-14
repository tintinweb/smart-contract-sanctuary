/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract HelloWorld {
    address owner; //slot 0
    string helllo="say helllo"; // slot 1
    string wellcomeString="hello 1"; //slot 2
    
    function getData() public view returns (string memory) {
        return wellcomeString;
    }

    function setData(string memory newData) public{
        wellcomeString=newData;
        helllo=newData;
    }
    
}