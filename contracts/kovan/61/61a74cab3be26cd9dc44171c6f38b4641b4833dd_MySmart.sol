/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MySmart {
    uint256 public tokenPrice;
    address public owner;
    IERC20 token;

    constructor() {
        owner = msg.sender;
    }

    function setTokenPrice(uint256 price) public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        tokenPrice = price;
    }

    function buyToken() public payable {
        uint256 eth = msg.value;
        uint256 amount = eth / tokenPrice;
        require(amount <= token.balanceOf(address(this)), "Not enough token's amount.");
        token.transfer(msg.sender, amount);
    }

    function sendToken() public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));
    }
}