/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool success);
    function balanceOf(address account) external view returns (uint256 balance);
}

contract MultiSend {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        assert(msg.sender == owner);
        owner = newOwner;
    }

    function multiSend(address token, address[] calldata accounts, uint256[] calldata amounts) external {
        assert(msg.sender == owner);

        uint256 count = accounts.length;

        for (uint256 i; i < count; ++i) {
           assert(IERC20(token).transfer(accounts[i], amounts[i]));
        }

        uint256 remaining = IERC20(token).balanceOf(address(this));

        if (remaining == uint256(0)) return;

        assert(IERC20(token).transfer(msg.sender, remaining));
    }
}