// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IStakingRewards {
    function stakeTransferWithBalance(uint256 amount, address useraddress, uint256 lockingPeriod) external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MultiStaking {
    address public stakingRewardsAddress = 0x4fe6A767d1D60456925fF83e810e5329129854CA;
    
    function stakeTransferWithBalance(IERC20 token, uint256[] memory amounts, address[] memory userAddresses, uint256[] memory lockingPeriods) external {
        IStakingRewards stakingRewardsContract = IStakingRewards(stakingRewardsAddress);
        uint256 totalBalance = 0;
        
        for (uint256 i = 0; i < userAddresses.length; i++) {
            totalBalance = totalBalance + amounts[i];
        }
        
        require(token.transferFrom(msg.sender, address(this), totalBalance));
        require(token.approve(stakingRewardsAddress, totalBalance));
        
        for (uint256 i = 0; i < userAddresses.length; i++) {
            stakingRewardsContract.stakeTransferWithBalance(amounts[i], userAddresses[i], lockingPeriods[i]);
        }
    }
    
}

