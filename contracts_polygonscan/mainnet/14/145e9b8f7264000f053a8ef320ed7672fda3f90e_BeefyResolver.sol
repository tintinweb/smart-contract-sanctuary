/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IVault {
    function deposit(uint256 amount) external;
}

interface IStrategy {
    function callReward() external view returns (uint256);
}

interface ITaskTreasury {
    function maxFee() external view returns (uint256);
}


contract BeefyResolver {

    IStrategy constant testStrategy  = IStrategy(0xFa27d93EBE4598C068a7667C9534Dd3E23BC2299);
    ITaskTreasury constant taskTreasury = ITaskTreasury(0xA8a7BBe83960B29789d5CB06Dcd2e6C1DF20581C);
    IVault constant vault = IVault(0xCd414F00d9E4e76f75F5de77DB376cb4ECe2b17f);

    
    function checker() public view returns(bool canExec, bytes memory execData) {
        uint256 gelatoFee = taskTreasury.maxFee();
        uint256 reward = testStrategy.callReward();
        
        if (gelatoFee > reward) return (false, execData);
        
        return (true, abi.encodeWithSelector(IVault.deposit.selector, 0));
    }


}