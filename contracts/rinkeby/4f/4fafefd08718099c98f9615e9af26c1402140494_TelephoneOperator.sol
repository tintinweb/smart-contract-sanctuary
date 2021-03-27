/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-v2-or-later
pragma solidity ^0.8.2;

interface ITelephone {
    function changeOwner(address _owner) external;
}

contract TelephoneOperator {
    function claimOwnership(ITelephone target, address owner) public {
        target.changeOwner(owner);
    }
}