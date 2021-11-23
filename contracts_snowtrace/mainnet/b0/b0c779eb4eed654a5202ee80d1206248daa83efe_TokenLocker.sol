pragma solidity 0.8.10;

// SPDX-License-Identifier: UNLICENSED

import "./Ownable.sol";
import "./IERC20.sol";

contract TokenLocker is Ownable {
    mapping(address => LockedToken) public lockedTokens;

    struct LockedToken {
        address tokenAddress;
        uint256 unlocksAt;
    }

    function lock(address tokenAddress, uint256 tokenAmount, uint256 unlocksAt) external onlyOwner {
        require(lockedTokens[tokenAddress].tokenAddress == address(0), "This token is already locked");
        
        //Ensure that lock times are reasonable
        require(unlocksAt >= block.timestamp, "Tokens must unlock after the current time");
        require(unlocksAt <= (block.timestamp + 365 days), "Tokens must unlock a year or less in advance");
        
        IERC20 token = IERC20(tokenAddress);

        //Transfer tokens from the owner to the locker
        uint256 previousAmount = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transferFrom failed");

        //Ensure no tokens were lost due to fees
        uint256 amountReceived = token.balanceOf(address(this)) - previousAmount;
        require(amountReceived == tokenAmount, "Inconsistent token value received, try excluding the locker from fees");

        //Record locked tokens
        lockedTokens[tokenAddress] = LockedToken({
            tokenAddress: tokenAddress,
            unlocksAt: unlocksAt
        });
    }

    function unlock(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);

        //Ensure unlock criteria is met
        require(lockedTokens[tokenAddress].tokenAddress != address(0), "Token is not locked");
        require(block.timestamp >= lockedTokens[tokenAddress].unlocksAt, "Too early to withdraw tokens");

        //Ensure locker holds sufficient tokens
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Insufficient token balance");

        //Transfer tokens back out to locker
        require(token.transfer(msg.sender, amount));
        
        //Delete record of lock
        delete lockedTokens[tokenAddress];
    }
}