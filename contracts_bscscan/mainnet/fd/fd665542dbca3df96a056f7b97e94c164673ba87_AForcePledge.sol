/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TokenTransfer {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
}

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "No permissions");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract AForcePledge is Owned {
    TokenTransfer private tokenTransfer;
    
    event Pledge(address indexed sender, address tokenOneAddress, uint256 amountOne, address tokenTwoAddress, uint256 amountTwo);
    
    constructor() {
    }
    
    function pledgeOne(address tokenAddress, uint256 amount) external returns (bool) {
        require(amount > 0, "Pledge quantity must be greater than 0");
        tokenTransfer = TokenTransfer(tokenAddress);
        tokenTransfer.transferFrom(msg.sender, address(this), amount);
        emit Pledge(msg.sender, tokenAddress, amount, address(0), 0);
        return true;
    }
    
    function pledgeTwo(address tokenOneAddress, uint256 amountOne, address tokenTwoAddress, uint256 amountTwo) external returns (bool) {
        require(amountOne > 0, "Pledge one quantity must be greater than 0");
        require(amountTwo > 0, "Pledge two quantity must be greater than 0");
        tokenTransfer = TokenTransfer(tokenOneAddress);
        tokenTransfer.transferFrom(msg.sender, address(this), amountOne);
        tokenTransfer = TokenTransfer(tokenTwoAddress);
        tokenTransfer.transferFrom(msg.sender, address(this), amountTwo);
        emit Pledge(msg.sender, tokenOneAddress, amountOne, tokenTwoAddress, amountTwo);
        return true;
    }
    
    function withdrawalToken(address tokenAddress, address recipient, uint256 amount) external onlyOwner returns (bool) {
        tokenTransfer = TokenTransfer(tokenAddress);
        tokenTransfer.transfer(recipient, amount);
        return true;
    }
}