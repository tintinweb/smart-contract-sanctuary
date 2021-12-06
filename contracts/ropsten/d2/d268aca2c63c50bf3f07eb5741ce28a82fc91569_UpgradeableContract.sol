// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract UpgradeableContract is Initializable {
    string public name;
    string public greeting;

    function initialize() public initializer {
        name = "name";
    }

    function setGreeting(string memory greeting_) public {
        greeting = greeting_;
    }

    function setName(string memory name_) public {
        name = name_;
    }
}