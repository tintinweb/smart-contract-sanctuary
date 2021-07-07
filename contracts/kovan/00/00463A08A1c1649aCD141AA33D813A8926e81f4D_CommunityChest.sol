/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract CommunityChest {
    constructor() {
    }
    event Store(address account, IERC20 token, uint256 amount);
    event Withdraw(address account, IERC20 token, uint256 amount);
    function storeToken(IERC20 token, uint256 amount) external {
        emit Store(msg.sender, token, amount);
        token.transferFrom(msg.sender, address(this), amount);
    }
    function withdrawToken(IERC20 token, uint256 amount) external {
        emit Withdraw(msg.sender, token, amount);
        token.transfer(msg.sender, amount);
    }
}