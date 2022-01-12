// SPDX-License-Identifier: lol
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./TokensRecoverable.sol";
import "./Owned.sol";

contract TokenTimelock is Owned, TokensRecoverable {

    using SafeMath for uint256;

    struct Timelock {
        address tokenOwner;
        uint256 amount;
        uint256 lockedTimestamp;
        uint256 claims;
        uint256 timeLocked;
    }

    //uint256 sixMonthsInSeconds = 15552000;
    uint256 sixMonthsInSeconds = 600;
    //test var below
    //uint256 tenMinutesInSeconds = 600;
    
    mapping (address => Timelock) tokenTimelock;

    function claimAvailable(address _token) public view returns (uint256) {
        uint unlockTime = tokenTimelock[_token].lockedTimestamp + tokenTimelock[_token].timeLocked;
        //if the full timelocked amount is up, transfer full balance of tokens to artist
        if (unlockTime <= block.timestamp) {
            return tokenTimelock[_token].amount;
        }

        //if 3 months is up, transfer half the amount to artist only if they havent already claimed
        else if (tokenTimelock[_token].lockedTimestamp + (tokenTimelock[_token].timeLocked.div(2)) <= block.timestamp && block.timestamp < unlockTime) {
            if (tokenTimelock[_token].claims < 1) {
                uint256 halfAmount = tokenTimelock[_token].amount.div(2);
                return halfAmount;
            }
        }
        
    }

    function lockTokens(address _token, address _artist, uint256 _amount) public ownerOnly() {
        require(_amount > 0, 'Amount must be greater than 0');
        require(tokenTimelock[_token].amount == 0, 'Token is already locked');
        tokenTimelock[_token] = Timelock(_artist, _amount, block.timestamp, 0, sixMonthsInSeconds);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function claimTokens(address _token) public {
        require(msg.sender == tokenTimelock[_token].tokenOwner, 'Only token owner can claim tokens');
        require(tokenTimelock[_token].lockedTimestamp + (tokenTimelock[_token].timeLocked.div(2)) <= block.timestamp, 'Token is still locked');
        require(tokenTimelock[_token].amount > 0, 'Token is already claimed');
        
        uint unlockTime = tokenTimelock[_token].lockedTimestamp + tokenTimelock[_token].timeLocked;
        //if the full timelocked amount is up, transfer full balance of tokens to artist
        if (unlockTime <= block.timestamp) {
            
            IERC20(_token).transfer(msg.sender, tokenTimelock[_token].amount);
            //tokenTimelock[_token].amount = 0;
        }

        //if 3 months is up, transfer half the amount to artist only if they havent already claimed
        else if (tokenTimelock[_token].lockedTimestamp + (tokenTimelock[_token].timeLocked.div(2)) <= block.timestamp && block.timestamp < unlockTime) {
            if (tokenTimelock[_token].claims < 1) {
                uint256 halfAmount = tokenTimelock[_token].amount.div(2);
                tokenTimelock[_token] = Timelock(tokenTimelock[_token].tokenOwner, halfAmount, tokenTimelock[_token].lockedTimestamp, 1, tokenTimelock[_token].timeLocked);
                IERC20(_token).transfer(msg.sender, halfAmount);
            }
        }
    }
  
    //Emergency function to unlock tokens
    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return msg.sender == owner; 
    }
}