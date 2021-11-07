/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Locker {
    
    address _tokenAddress;
    address withdrawalAddress;
    uint256 day = 86400;
    uint256 tokenAmount;
    uint256 unlockTime = 0;
    uint256 addDays;
    bool withdrawn;

    event TokensLocked(address indexed tokenAddress, address indexed sender, uint256 amount, uint256 unlockTime);
    event TokensWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);

    constructor () {
    }

    function lockTokens(uint256 _amount, uint256 _daysLocked, address tokenAddress) external payable {
        unlockTime = block.timestamp + (_daysLocked * day);
        _tokenAddress = tokenAddress;
        require(_amount > 0, 'Tokens amount must be greater than 0');
        require(_daysLocked > 0, 'Days locked must be greater than 0');
        require(unlockTime > block.timestamp, 'Unlock time must be in future');

        require(IBEP20(_tokenAddress).approve(address(this), _amount), 'Failed to approve tokens');
        require(IBEP20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), 'Failed to transfer tokens to locker');
        
        emit TokensLocked(_tokenAddress, msg.sender, _amount, unlockTime);
    }

    function withdrawTokens() external payable {
        require(block.timestamp >= unlockTime, 'Tokens are locked');
        require(!withdrawn, 'Tokens already withdrawn');

        uint256 amount = tokenAmount;

        require(IBEP20(_tokenAddress).transfer(msg.sender, amount), 'Failed to transfer tokens');

        withdrawn = true;
        
        emit TokensWithdrawn(_tokenAddress, msg.sender, amount);
    }

    function extendLock(uint256 _extendLockTime) external {
        addDays = _extendLockTime * day;
        require(addDays > 0 , "Cannot set an unlock time in past!");
        unlockTime = unlockTime + addDays;
    }

    function getLockedTokenBalance() view public returns (uint256){
        return IBEP20(_tokenAddress).balanceOf(address(this));
    }

    function getDaysUntilUnlock() view public returns (uint256){
        return ((block.timestamp - unlockTime) / day);
    }

    function getTimeInSecondsUntilUnlock() view public returns (uint256){
        return (unlockTime);
    }
}