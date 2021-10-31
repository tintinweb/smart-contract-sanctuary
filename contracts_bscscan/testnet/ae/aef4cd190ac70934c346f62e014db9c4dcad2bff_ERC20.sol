/**
 *Submitted for verification at BscScan.com on 2021-10-30
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

contract ERC20 {
    uint256 public decimals;
}

contract XetaRealityLPLock {
    IERC20 private token;
    uint256 decimals;
    uint256 public lockedUntil = 0;
    address private tokenOwner;
    address private tokenAddress = 0xD6675f3db1B9fF04C55917D220648499E5c1a0A5;
    
    modifier onlyOwner() {
        require(msg.sender == tokenOwner, "Only contract owner can execute this");
        _;
    }
    
    constructor() {
        tokenOwner = msg.sender;
        token = IERC20(tokenAddress);
        decimals = ERC20(tokenAddress).decimals();
    }
    
    function lock(uint256 amount, uint256 until) public onlyOwner {
        require(token.balanceOf(tokenOwner) >= amount, "Amount larger than balance");
        require(token.allowance(tokenOwner, address(this)) >= amount, "Allowance must be larger than amount");
        require(until >= lockedUntil, "Relocking only allowed beyond current lock period");
        token.transferFrom(tokenOwner, address(this), amount);
        lockedUntil = until;
    }
    
    function unlock(uint256 amount) public onlyOwner {
        require(lockedAmount() > 0, "No locked amount");
        require(lockedAmount() >= amount, "Unlock amount larger than locked amount");
        require(block.timestamp > lockedUntil, "Locked period has not expired yet");
        token.transfer(tokenOwner, amount);
    }

    function lockedAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}