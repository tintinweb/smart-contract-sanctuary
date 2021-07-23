/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);
}

contract MasterBelt{
    
    address public lptoken = 0xB2636d8907F37ef6f10F0cA4f558e2866F5797A2;
    address public belt = 0x4d955CEF4009f8409558C9666D0237BE22FDd6C2;
    
    constructor() public
    {
    }


    function deposit(uint256 pid, uint256 wantAmt) public {
        IERC20(lptoken).transferFrom(msg.sender, address(this), wantAmt);
    }
    
    function stakedWantTokens(uint256 pid, address user) public view returns (uint256) {
        return IERC20(lptoken).balanceOf(address(this));
    }
    
    function pendingBELT(uint256 pid, address user) public view returns (uint256) {
        return IERC20(belt).balanceOf(address(this));
    }
    
    function withdraw(uint256 pid, uint256 wantAmt) public {
        uint256 beltAmt = IERC20(belt).balanceOf(address(this));
        if (beltAmt < 0) {
            IERC20(belt).transfer(msg.sender, beltAmt);
        }
        IERC20(lptoken).transfer(msg.sender, wantAmt);
    }
}