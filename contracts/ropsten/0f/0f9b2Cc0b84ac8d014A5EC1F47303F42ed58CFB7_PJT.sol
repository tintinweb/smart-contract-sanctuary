/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PJT {
    constructor() {}
    event SendToken(address indexed from, address indexed to, uint256 value);
    function sendToken(address tokenAddress, address to, uint256 amount) external returns(uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 allow = token.allowance(msg.sender, address(this));
        emit SendToken(msg.sender, to, amount);
        return allow;
    }
    receive() external payable { }
}