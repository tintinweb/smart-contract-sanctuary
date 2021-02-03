// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILToken.sol";

contract LDai is ERC20, ILToken {
    address public governanceAccount;
    address public poolAccount;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        governanceAccount = msg.sender;
    }

    function mint(address to, uint256 amount) external override {
        require(msg.sender == poolAccount, "LDai: must be pool account");

        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external override {
        require(msg.sender == poolAccount, "LDai: must be pool account");

        _burn(account, amount);
    }

    function setGovernanceAccount(address to) external {
        require(
            msg.sender == governanceAccount,
            "LDai: must be governance account"
        );

        governanceAccount = to;
    }

    function setPoolAccount(address to) external {
        require(
            msg.sender == governanceAccount,
            "LDai: must be governance account"
        );

        poolAccount = to;
    }

    function _transfer(
        address, /* sender */
        address, /* recipient */
        uint256 /* amount */
    ) internal virtual override {
        // non-transferable between users
        revert("LDai: token is non-transferable");
    }
}