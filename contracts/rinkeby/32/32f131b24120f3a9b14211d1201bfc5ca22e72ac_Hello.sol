/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier:UNLICENED
pragma solidity 0.8.7;
contract Hello {
    string public name = "test helloword!";

    function setName(string memory _name) public {
        name = _name;
    }
}