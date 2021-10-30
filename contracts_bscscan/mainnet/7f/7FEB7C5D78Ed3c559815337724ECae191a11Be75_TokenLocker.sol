//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

contract TokenLocker {
    
    // Locker Unit
    struct Locker {
        uint256 numTokensLocked;
        uint256 lastClaim;
    }
    
    // Data
    address public constant token = 0xF754817A9609cCf288fDc853F17B2B8D7b6F79FF;
    uint256 public constant allowance = 5; // 0.5% per week
    uint256 public constant claimWait = 200000;
    address public constant marketing = 0xE0A243eb9169256936C505a162478f5988A6fb85;
    
    // User -> Locker
    mapping (address => Locker) users;
    
    // events
    event Locked(address from, uint256 numberTokens);
    event Claim(address from, uint256 numTokens);
    
    // claim
    function claim() external {
        
        // number of tokens to unlock
        uint256 numTokens = users[msg.sender].numTokensLocked;
        require(numTokens > 0, 'No Tokens Locked');
        require(users[msg.sender].lastClaim + claimWait <= block.number, 'Not Time To Claim');
        // amount to send back
        uint256 amount = (numTokens * allowance) / 10**3;
        // update times
        users[msg.sender].lastClaim = block.number;
        users[msg.sender].numTokensLocked -= amount;
        // transfer locked tokens to sender
        bool s = IERC20(token).transfer(msg.sender, amount);
        require(s, 'transfer failure');
        emit Claim(msg.sender, numTokens);
    }

    // lock
    function lock(uint256 numberTokens) external {
        
        uint256 diff = _transferInTokens(numberTokens);
        require(diff > 0, 'Zero Tokens Received');
        
        users[marketing].numTokensLocked += diff;
        if (msg.sender == marketing) {
            users[marketing].lastClaim = block.number;
        }
        
        emit Locked(msg.sender, numberTokens);
    }
    
    function getTimeTillClaim(address user) external view returns (uint256) {
        return block.number <= (users[user].lastClaim + claimWait) ? 0 : (block.number - (users[user].lastClaim + claimWait));
    }
    
    function tokensLockedForUser(address user) external view returns (uint256) {
        return users[user].numTokensLocked;
    }
    
    function _transferInTokens(uint256 tokenAmount) internal returns (uint256) {
        uint256 before = IERC20(token).balanceOf(address(this));
        bool success = IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        require(success, 'Failure on Transfer From');
        return IERC20(token).balanceOf(address(this)) - before;
    }
    
}