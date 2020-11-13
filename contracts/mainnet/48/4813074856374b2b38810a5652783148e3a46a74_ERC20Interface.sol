// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ERC20Interface {
    function totalSupply() external view returns(uint256);
    function balanceOf(address tokenOwner) external view returns(uint256);
    function allowance(address tokenOwner, address) external view returns(uint256);
    function approve(address spender, uint256 token) external returns(bool);
    function transfer(address to, uint256 tokens) external returns(bool);
    function transferFrom(address from, address to, uint256 tokens) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
