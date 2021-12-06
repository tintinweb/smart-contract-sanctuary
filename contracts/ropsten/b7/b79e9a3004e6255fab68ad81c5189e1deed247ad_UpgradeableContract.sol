// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

abstract contract ParentA is Initializable {
    string public x1;

    function __ParentA_init_unchained() internal initializer {
        x1 = "parent A";
    }
}

abstract contract ParentB is Initializable {
    string public x2;

    function __ParentB_init_unchained() internal initializer {
        x2 = "parent B";
    }
}

contract UpgradeableContract is Initializable, ParentA, ParentB {
    string public name;
    string public greeting;

    function initialize() public initializer {
        name = "name";
        __ParentA_init_unchained();
        __ParentB_init_unchained();
    }

    function setGreeting(string memory greeting_) public {
        greeting = greeting_;
    }

    function setName(string memory name_) public {
        name = name_;
    }
}