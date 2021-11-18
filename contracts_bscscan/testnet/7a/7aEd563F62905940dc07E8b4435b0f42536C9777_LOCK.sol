/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface PrezaleLockerInterface {
    function changeLockOwner(uint256 lockId, address newowner) external returns(address newLockOwner);
    function getLockInfo(uint256 lockid) external view returns (address owner, uint256 lockId, address token, address lockAddress, address creator, uint256 amount, uint256 amountRemaining, uint256 unlockTimestamp, address pair);
    function withdraw(uint256 lockId, uint256 amount) external;
}
contract LOCK {
    address parentContract;
    address public tokenAddress;
    address public thisLockAddress;
    uint256 public lockid;
    uint256 public lockAmount;
    uint256 public lockedUntil;
    address public withdrawnBy;
    bool public LPLOCK;
    
    constructor(address tokenAddress_, uint lockid_, address parentContract_) public {
         parentContract = parentContract_;
         lockid = lockid_;
         tokenAddress = tokenAddress_;
         (, , , , , uint256 amount,, uint256 unlockTimestamp, address pair) =  PrezaleLockerInterface(parentContract).getLockInfo(lockid);
         LPLOCK = pair != address(0) ? true : false;
         lockAmount = amount;
         lockedUntil = unlockTimestamp;
         thisLockAddress = address(this);
    }
    
    function lockInfo() public view returns (address owner, uint256 lockId, address token, address lockAddress, address creator, uint256 amount, uint256 amountRemaining, uint256 unlockTimestamp, address pair, bool isLpLock) {
        (, lockId, token, lockAddress, creator, amount, amountRemaining,,) = PrezaleLockerInterface(parentContract).getLockInfo(lockid);
         (owner, , , , , ,, unlockTimestamp, pair) = PrezaleLockerInterface(parentContract).getLockInfo(lockid);
        if(pair != address(0)) {
            isLpLock = true;
        }
        return  (owner, lockId, token, lockAddress, creator, amount, amountRemaining, unlockTimestamp, pair, isLpLock);
    }
    function isWithdrawn() public view returns (bool withdrawn) {
           (, , , , , , uint256 amountRemaining,,) = PrezaleLockerInterface(parentContract).getLockInfo(lockid);
           if(amountRemaining == 0) {
               return true;
           } else {
               return false;
           }
    }
    function withdraw() public {
        PrezaleLockerInterface(parentContract).withdraw(lockid, lockAmount);
        withdrawnBy = tx.origin;
    }
    function isUnlocked() public view returns  (bool unlocked) {
        if(block.timestamp > lockedUntil) {
            return true;
        } else {
            return false;
        }
    }
    
    function changeLockOwner(address newowner) public {
        PrezaleLockerInterface(parentContract).changeLockOwner(lockid, newowner);
    }
}