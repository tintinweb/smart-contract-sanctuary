/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// File: contracts/AdvStakingProxyFarmer.sol

pragma solidity 0.6.12;


contract AdvStakingProxyFarmer {
    event AwardsAdded (uint256);
    
    function addRewards() public {
        emit AwardsAdded(1);    
    }

}