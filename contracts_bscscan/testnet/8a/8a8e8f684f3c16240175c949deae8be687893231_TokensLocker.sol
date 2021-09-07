/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


/// @title Tokens Locker
/// @author FreezyEx (https://github.com/FreezyEx)
/// @dev A smart contract that locks tokens and allow to claim rewards

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokensLocker is Context{

    //receive() external payable {}
    
    IERC20 public token;
    bool public locked;
    
    struct lockDetailsStruct {
        address user;
        uint256 amount;
        uint256 unlockDate;
    }
    
    lockDetailsStruct public lockDetails;
    
    event TokensLocked(address account, IERC20 tokenAddress, uint256 amount, uint256 unlockDate);
    event TokensUnlocked(address account, uint256 amount);
    
    function lockTokens(IERC20 _token, uint256 _amount, uint256 _unlockDate) external {
        require(!locked, "Tokens already locked");
        require((_unlockDate - block.timestamp) >= 12 weeks, "Unlock date must >= 3 months");
        token.transferFrom(msg.sender, address(this), _amount);
        token = _token;
        lockDetails.user = msg.sender;
        lockDetails.amount = _amount;
        lockDetails.unlockDate = _unlockDate;
        locked = true;
        emit TokensLocked(msg.sender, _token, _amount, _unlockDate);
    }
    
    function unlockTokens() external{
        require(locked, "No locked tokens");
        require(msg.sender == lockDetails.user, "You are not a valid user");
        require(block.timestamp > lockDetails.unlockDate, "You must wait unlockDate");
        token.transfer(lockDetails.user, lockDetails.amount);
        locked = false;
        emit TokensUnlocked(msg.sender, lockDetails.amount);
    }
    
    function claimRewards(IERC20 tokenAddress) external{
        require(msg.sender == lockDetails.user, "You are not a valid user");
        require(tokenAddress != token ,"You can't claim locked tokens");
        require(tokenAddress.balanceOf(address(this)) > 0, "Insufficient balance");
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }
    
}