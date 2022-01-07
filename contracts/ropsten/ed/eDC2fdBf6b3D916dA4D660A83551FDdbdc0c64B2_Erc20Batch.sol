// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";

struct TransferTask {
    address from;
    address to;
    uint256 amount;
}

contract Erc20Batch {
    IERC20 public immutable token;

    constructor(address _token) {
        require(_token.code.length > 0, "Address is not contract");
        token = IERC20(_token);
    }

    function transfer(TransferTask calldata task) external returns (bool) {
        if (task.from == msg.sender) {
            return token.transfer(task.from, task.amount);
        } else {
            uint256 balance = token.balanceOf(task.from);
            if (balance < task.amount) {
                if (!token.transfer(task.from, task.amount - balance)) {
                    return false;
                }
            }
            return token.transferFrom(task.from, task.to, task.amount);
        }
    }

    function batchTransfer(TransferTask[] calldata tasks) external returns (uint8) {
        require(tasks.length <= 255, "Too many transfers");
        uint8 count = uint8(tasks.length);
        uint8 i = 0;
        for (i; i < count; i++) {
            try this.transfer(tasks[i]) returns (bool success) {
                if (!success) break;
            } catch {
                break;
            }
        }
        return count - i;
    }
}