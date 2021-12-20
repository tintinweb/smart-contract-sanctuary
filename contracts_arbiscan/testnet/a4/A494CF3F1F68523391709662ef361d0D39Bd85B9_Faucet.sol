/**
 *Submitted for verification at arbiscan.io on 2021-12-20
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function decimals() external pure returns (uint8);
}

contract Faucet {
    // userAddress => token => timestamp
    mapping(address => mapping(address => uint256)) lastWithdrawTime;

    function withdraw(address token) external {
        uint256 withdrawableTime = lastWithdrawTime[msg.sender][token] + 24*60*60;
        require(block.timestamp >= withdrawableTime, "time limit");
        uint256 amount = 10 * (10**uint256(IERC20(token).decimals()));
        IERC20(token).transfer(msg.sender, amount);
        lastWithdrawTime[msg.sender][token] = block.timestamp;
    }
}