/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ERC20Manager {
    function _transfer(IERC20 token, address recipient, uint256 amount) internal returns (bool) {
        return token.transfer(recipient, amount);
    }
    
    function _approveSpender(IERC20 token, address spender, uint256 amount) internal {
        token.approve(spender, amount);
    }
    
    function _transferFrom(IERC20 token, address sender, address recipient, uint256 amount) internal returns (bool) {
        return token.transferFrom(sender, recipient, amount);
    }
}

contract Owned {
    
    address private _owner;
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    constructor() {
        _owner = msg.sender;
    }
}

contract Wallet is Owned, ERC20Manager {
    
    event IncomingETH(address indexed from, uint256 value);
    
    receive() external payable {
        emit IncomingETH(msg.sender, msg.value);
    }
    
    function remove() external onlyOwner {
        selfdestruct(msg.sender);
    }
    
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        recipient.transfer(amount);
    }
    
    function transfer(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        _transfer(token, recipient, amount);
    }
    
    function approveSpender(IERC20 token, address spender, uint256 amount) external onlyOwner {
        _approveSpender(token, spender, amount); 
    }
    
    function transferFrom(IERC20 token, address sender, address recipient, uint256 amount) external onlyOwner {
        _transferFrom(token, sender, recipient, amount);
    }
    
}