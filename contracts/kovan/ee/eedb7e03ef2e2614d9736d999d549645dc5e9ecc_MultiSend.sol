// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IStakingRewards {
    function stakeTransferWithBalance(uint256 amount, address useraddress, uint256 lockingPeriod) external;
}

contract MultiSend {
    address public stakingRewardsAddress = 0x9a255391981c4D5c87fa0cbF918ECAA69C3Bb190;
    
    function stakeTransferWithBalance(uint256[] memory amounts, address[] memory userAddresses, uint256[] memory lockingPeriods) external {
        IStakingRewards stakingRewardsContract = IStakingRewards(stakingRewardsAddress);
        
        for (uint256 i = 0; i < userAddresses.length; i++) {
            stakingRewardsContract.stakeTransferWithBalance(amounts[i], userAddresses[i], lockingPeriods[i]);
        }
    }
}

