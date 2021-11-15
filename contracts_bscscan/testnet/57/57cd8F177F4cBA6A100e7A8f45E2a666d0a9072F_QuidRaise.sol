// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract QuidRaise {
    string public name = "Quid Raise";

    function getName() public view returns (string memory) {
        return name;
    }
}

