/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract HelloWorld {

    string helloVar;
    
    function setHello(string memory varHello) public {
        helloVar = varHello;
    }


    function helloWorld() public view returns(string memory) {
        return helloVar;
    }
}