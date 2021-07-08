/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StoreLockedToken{
    IERC20 token;
    address delegate;

    constructor(address _token, address _delegate) {
        token = IERC20(_token);
        delegate = _delegate;
    }

    modifier onlyOwner() {
        require(msg.sender == delegate);
        _;
    }

    function withdrawToken() onlyOwner external payable {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}