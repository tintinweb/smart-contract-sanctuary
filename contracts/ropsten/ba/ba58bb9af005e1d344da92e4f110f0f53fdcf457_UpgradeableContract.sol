// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract UpgradeableContract is Initializable {
    string public name;

    function initialize() public initializer {
        name = "name";
    }

    function setName(string memory name_) public {
        name = name_;
    }
}