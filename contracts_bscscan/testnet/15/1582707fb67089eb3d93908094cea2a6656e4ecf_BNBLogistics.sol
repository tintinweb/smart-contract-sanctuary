/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BNBLogistics {
    //Axie Infinity Pool 0x9907F21Bc27E3736C05eFcaEB8e49ecE330BFbfD
    //ForexMarket Pool 0x6E22A46162c9704EcCEbefB1FeE80f649500d47C
    //Crypto Market Pool 0x86bfAa65c20111d10cF91F8E436B63fD7541c978
    address[] public stakePools = [0x9907F21Bc27E3736C05eFcaEB8e49ecE330BFbfD, 0x6E22A46162c9704EcCEbefB1FeE80f649500d47C, 0x86bfAa65c20111d10cF91F8E436B63fD7541c978];

    constructor() {
        
    }
    
    function stakeBNB(uint8 stakePoolIndex, uint8 stakeDuration) payable public {
        if(stakePoolIndex == 0) {
            if(stakeDuration == 0) {
                require (msg.value >= (5 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[0]).transfer(msg.value);
            }else if(stakeDuration == 1) {
                require (msg.value >= (10 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[0]).transfer(msg.value);
            }else if(stakeDuration == 2) {
                require (msg.value >= (10 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[0]).transfer(msg.value);                
            }else{
                require(stakeDuration < 3, "Invalid stake duration");
            }
        }
        else if(stakePoolIndex == 1) {
            if(stakeDuration == 0) {
                require (msg.value >= (15 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[1]).transfer(msg.value);
            }else if(stakeDuration == 1) {
                require (msg.value >= (20 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[1]).transfer(msg.value);
            }else if(stakeDuration == 2) {
                require (msg.value >= (25 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[1]).transfer(msg.value);                
            }else{
                require(stakeDuration < 3, "Invalid stake duration");
            }                        
        }
        else if(stakePoolIndex == 2) {
            if(stakeDuration == 0) {
                require (msg.value >= (25 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[2]).transfer(msg.value);
            }else if(stakeDuration == 1) {
                require (msg.value >= (30 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[2]).transfer(msg.value);
            }else if(stakeDuration == 2) {
                require (msg.value >= (35 / 100) * 1 ether, "Minimum amount not met");
                payable(stakePools[2]).transfer(msg.value);                
            }else{
                require(stakeDuration < 3, "Invalid stake duration");
            }            
        }
        else {
            require(stakePoolIndex < 3, "Invalid stake pool");
        }
    }     

}