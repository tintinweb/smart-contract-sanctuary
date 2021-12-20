/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract HelloWorld {

    string lastText = "Hello Andre";

    function getString() public view returns(string memory) {
        return lastText;
    }

    function setString(string memory text) public {
        lastText = text;
    }

}