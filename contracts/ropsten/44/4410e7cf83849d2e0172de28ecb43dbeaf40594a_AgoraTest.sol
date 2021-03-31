/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract AgoraTest {

    // For timelock
    struct LockedItem {
        uint256 expires;
        uint256 amount;
    }
    mapping(address => LockedItem[]) public timelocks;
    uint256 public lockInterval = 10;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);

    function deposit(uint256 _amount) external {
        LockedItem memory timelockData;
        timelockData.expires = block.timestamp + lockInterval * 1 minutes;
        timelockData.amount = _amount;
        timelocks[msg.sender].push(timelockData);
        emit Deposit(msg.sender, _amount);
    }

    function getLockedAmount(address _investor) public returns (uint256) {
        uint256 lockedAmount = 0;
        LockedItem[] storage usersLocked = timelocks[_investor];
        uint256 usersLockedLength = usersLocked.length;
        uint256 blockTimestamp = block.timestamp;
        for(uint256 i = 0; i < usersLockedLength; i++) {
            if (usersLocked[i].expires <= blockTimestamp) {
                // Expired locks, remove them
                usersLocked[i] = usersLocked[usersLockedLength - 1];
                usersLocked.pop();
                usersLockedLength--;
                i--;
            } else {
                // Still not expired, count it in
                lockedAmount += usersLocked[i].amount;
            }
        }
        return lockedAmount;
    }

}