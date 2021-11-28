/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherVault {

    mapping (address => uint256) public deposits;
    mapping (address => mapping (address => bool)) public delegates;

    function deposit() external payable {
        require(msg.value > 0, "EtherVault: invalid deposit amount");
        deposits[msg.sender] += msg.value;
    }

    function depositFor(address account) external payable {
        require(msg.value > 0, "EtherVault: invalid deposit amount");
        deposits[account] += msg.value;
    }

    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, msg.sender, amount);
    }

    function withdrawFrom(address sender, address recipient, uint256 amount) external {
        require(delegates[sender][recipient], "EtherVault: unauthorized to withdraw from sender");
        _withdraw(sender, recipient, amount);
    }

    function delegateSpend(address recipient) external {
        delegates[msg.sender][recipient] = true;
    }

    function revokeSpend(address recipient) external {
        delete delegates[msg.sender][recipient];
    }

    function _withdraw(address sender, address recipient, uint256 amount) internal {
        require(deposits[sender] >= amount, "EtherVault: insufficient deposited balance");
        (bool success,) = recipient.call{value: amount}("");
        require(success, "EtherVault: transfer failed");
        if (deposits[sender] > amount) {
            deposits[sender] -= amount;
        } else {
            deposits[sender] = 0;
        }
    }

    receive() external payable {}

}