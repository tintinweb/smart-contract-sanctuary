/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ISPEED {
    function idToAccount(uint tokenID) external view returns(address);
}

contract SpeedUtils {

    ISPEED public SpeedsterContract = ISPEED(0x8C703cc3cc8655490f018bBe88903CA9398AC5B5);

    function getIDFromAccount(address _account) external view returns(uint256 idOfAcc) {
        for(uint i = 1; i <= 25; i++) {
            if(SpeedsterContract.idToAccount(i) == _account) {
                return i;
            }
        }
    }
}