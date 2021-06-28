/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract AgoraTimelockTest {

    // For timelock
    struct LockedItem {
        uint256 expires;
        uint256 amount;
    }
    mapping(address => LockedItem[]) public timelocks;
    uint256 public lockInterval = 1;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    
    function depositMany(uint256 _times) external {
        for (uint i = 0; i < _times; i++) {
            deposit(1);
        }
    }

    function deposit(uint256 _amount) public {
        LockedItem memory timelockData;
        timelockData.expires = block.timestamp + lockInterval * 1 minutes;
        timelockData.amount = _amount;
        timelocks[msg.sender].push(timelockData);
        emit Deposit(msg.sender, _amount);
    }

    function getLockedAmount(address _investor) public returns (uint256) {
        uint256 lockedAmount = 0;
        LockedItem[] storage usersLocked = timelocks[_investor];
        int256 usersLockedLength = int256(usersLocked.length);
        uint256 blockTimestamp = block.timestamp;
        for(int256 i = 0; i < usersLockedLength; i++) {
            if (usersLocked[uint256(i)].expires <= blockTimestamp) {
                // Expired locks, remove them
                usersLocked[uint256(i)] = usersLocked[uint256(usersLockedLength) - 1];
                usersLocked.pop();
                usersLockedLength--;
                i--;
            } else {
                // Still not expired, count it in
                lockedAmount += usersLocked[uint256(i)].amount;
            }
        }
        return lockedAmount;
    }

}