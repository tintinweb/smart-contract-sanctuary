// SPDX-License-Identifier: MIT
// Platinum Software Dev Team
// Locker  Beta  version.

pragma solidity ^0.8.4;

import "./Locker.sol";

contract LockerByBlock is Locker {

    function _getAvailableAmountByLockIndex(uint256 _lockIndex) 
        internal 
        view
        override  
        returns(uint256)
    {
        VestingRecord[] memory v = lockerStorage[_lockIndex].vestings;
        uint256 res = 0;
        for (uint256 i = 0; i < v.length; i ++ ) {
            if  (v[i].unlockTime <= block.number && !v[i].isNFT) {
                res += v[i].amountUnlock;
            }
        }
        return res;
    }

}