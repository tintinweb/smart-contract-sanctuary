/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameContract {

    string private name = "Ire";

    function getName() public view virtual returns (string memory) {
        return name;
    }

    function setName(string memory newName) public
    {
        name = newName;
    }

}