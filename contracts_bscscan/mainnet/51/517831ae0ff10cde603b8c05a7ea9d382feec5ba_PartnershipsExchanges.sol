/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

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

contract PartnershipsExchanges {
    IERC20 private token;
    uint256 public VestingedUntil = 0;
    address private tokenOwner;
    address private tokenAddress = 0x0405e9103ADb7B8Df0d4a0bB082d6E7F98D0C0bB;
    
    modifier onlyOwner() {
        require(msg.sender == tokenOwner, "Only contract owner can execute this");
        _;
    }
    
    constructor() {
        tokenOwner = msg.sender;
        token = IERC20(tokenAddress);
    }
    
    function Vesting(uint256 amount, uint256 until) public onlyOwner {
        require(token.balanceOf(tokenOwner) >= amount, "Amount larger than balance");
        require(token.allowance(tokenOwner, address(this)) >= amount, "Allowance must be larger than amount");
        require(until >= VestingedUntil, "ReVestinging only allowed beyond current Vesting period");
        token.transferFrom(tokenOwner, address(this), amount);
        VestingedUntil = until;
    }
    
    function unVesting(uint256 amount) public onlyOwner {
        require(VestingedAmount() > 0, "No Vestinged amount");
        require(VestingedAmount() >= amount, "UnVesting amount larger than Vestinged amount");
        require(block.timestamp > VestingedUntil, "Vestinged period has not expired yet");
        token.transfer(tokenOwner, amount);
    }

    function VestingedAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}