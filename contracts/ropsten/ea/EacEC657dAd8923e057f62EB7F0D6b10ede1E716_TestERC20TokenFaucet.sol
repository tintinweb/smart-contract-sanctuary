// SPDX-License-Identifier: UNLICENSED
// pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract TestERC20TokenFaucet {
    uint256 threshold;
    address owner;

    constructor(uint256 _threshold) {
        threshold = _threshold;
        owner = msg.sender;
    }

    function withdraw(address token) external {
        uint256 decimals = IERC20(token).decimals();
        uint256 balance = IERC20(token).balanceOf(msg.sender);
        uint256 amount = threshold * (10 ** decimals);
        require(balance < amount, "balance equals or exceeds faucet threshold");
        IERC20(token).transfer(msg.sender, amount);
    }

    function setThreshold(uint256 _threshold) external {
        require(msg.sender == owner, "only callable by owner");
        threshold = _threshold;
    }
}