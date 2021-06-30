/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20{

    function transfer(address recipient, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    
    function balanceOf(address account) external view returns (uint256);
    
    function _burn(address account, uint256 amount) external;
    
}

interface swapInterface{

    function swap(address addr) external;

    function withdraw(uint256 amount) external;
    
    event Swap(address indexed user, uint256 amount);
    
}

contract swapContract is swapInterface {

    IERC20 oldToken;
    IERC20 newToken;
    address _owner;
    
    constructor(address oldOne, address newOne){
        oldToken = IERC20(oldOne);
        newToken = IERC20(newOne);
        _owner = msg.sender;
    }

    function swap(address addr) external override {
        uint256 balanceOfUser = oldToken.balanceOf(addr);
        uint256 balanceOfSwap = newToken.balanceOf(address(this));
        require(balanceOfUser > 0, "SWAP: balance Of User exceeds balance");
        require(balanceOfSwap >= balanceOfUser, "SWAP: balance of swap exceeds balance");
        oldToken._burn(addr, balanceOfUser);
        newToken.transfer(addr, balanceOfUser);
        emit Swap(addr, balanceOfUser);
    }

    function withdraw(uint256 amount) external override {
        require(msg.sender == _owner);
        newToken.transfer(msg.sender, amount);
    }
    
}