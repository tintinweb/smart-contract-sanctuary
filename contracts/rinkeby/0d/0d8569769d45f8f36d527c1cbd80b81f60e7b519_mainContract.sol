/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity <0.9.0;

contract mainContract{
    struct Stake {
        uint16 bonusPercentage;
        uint40 unlockTimestamp;
        uint128 amount;
        bool withdrawn;
    }
    
    Stake example = Stake(16,16,100,true);
    
    function getStakes() external view returns (Stake memory){
        return example;
    }
}