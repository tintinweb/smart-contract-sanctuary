//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract LockedBoxV4 {
    uint256 private value;
    event ValueChanged(uint256 newValue);
    uint256 private startTime;
    uint256 private constant unixWeek = 604800;
    uint256 private constant unixMinute =  60;
    uint256 public unlockTime;
    
    function init(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
        startTime = startTime + block.timestamp;

        unlockTime = startTime + (unixMinute * 5);

    }

    function checkLock() public view returns (bool, uint256){
        bool isLocked = block.timestamp >= unlockTime;
        uint256 timeTilUnlock;
        if(block.timestamp >= unlockTime){
            timeTilUnlock = 0;
        } else {

            timeTilUnlock = unlockTime - block.timestamp; 
        }
        return (isLocked, timeTilUnlock);
    }

    function checkTime() public view returns (uint256){
        return block.timestamp;
    }



    function retrieve() public view returns (uint256) {
        return value;
    }
    function increment() public returns (uint256){
        value = value + 1;
        emit ValueChanged(value);
        return value;
    }
    function decrement() public returns (uint256){
        value = value - 1;
        emit ValueChanged(value);
        return value;
    }
}

