/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.4;

interface Multiplier {
    function updateLockupPeriod(address _user, uint _lockup) external returns(bool);
    function balance(address user) external view returns (uint);
    function lockupPeriod(address user) external view returns (uint);
}

contract MultiplierLock {
    
    Multiplier private multiplier;
    
    event LockupUpdated(address indexed sender, uint term);
    
    constructor(address _multiplier) {
        
        multiplier = Multiplier(_multiplier);
    }
    
    function updateMultiplierLockUp(uint _term) external returns(bool lockUpdated) {
        
        require(multiplier.balance(msg.sender) > 0, "No Multiplier balance to lock");
        
        if (_term > multiplier.lockupPeriod(msg.sender)) multiplier.updateLockupPeriod(msg.sender, _term);
        else revert("cannot reduce current lockup");
        
        emit LockupUpdated(msg.sender, _term);
        return true;
    }
    
}