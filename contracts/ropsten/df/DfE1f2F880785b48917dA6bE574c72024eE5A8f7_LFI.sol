// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";

contract LFI is ERC20Capped {
    address public governanceAccount;
    address public minter;

    constructor(
        string memory name,
        string memory symbol,
        uint256 cap
    ) ERC20(name, symbol) ERC20Capped(cap) {
        governanceAccount = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "LFI: must be minter");

        _mint(to, amount);
    }

    function setGovernanceAccount(address to) external {
        require(
            msg.sender == governanceAccount,
            "LFI: must be governance account"
        );

        governanceAccount = to;
    }

    function setMinter(address to) external {
        require(
            msg.sender == governanceAccount,
            "LFI: must be governance account"
        );

        minter = to;
    }
}