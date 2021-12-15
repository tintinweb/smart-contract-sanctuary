/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract implementationContract{
    address public owner;

    uint256 slotOne;
    uint256 slotTwo;
    uint256 slotThree;

    function setFirstParam(uint256 _slotOne) public{
        slotOne = _slotOne;
    }

    function setSecondParam(uint256 _slotTwo) public{
        slotTwo = _slotTwo;
    }

    function calcRes() public{
        slotThree = slotOne + slotTwo;
    }
}