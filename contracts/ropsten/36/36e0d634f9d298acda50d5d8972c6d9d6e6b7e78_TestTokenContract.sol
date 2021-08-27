/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract TestTokenContract {
    uint256 number;
    bool isActive;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function setIsActive(bool value) public {
        require(msg.sender == owner, "not authorized.");
        isActive = value;
    }

    function setData(uint256 value) public {
        require(isActive, "contract has not been activated yet");

        number = value;
    }

    function getData() public view returns (uint256) {
        return number;
    }
}