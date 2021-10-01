/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Tactics are used to interact with a strategy's underlying farm
interface ITactic {
    
    function _vaultDeposit(address masterchefAddress, uint pid, uint256 _amount) external;
    function _vaultWithdraw(address masterchefAddress, uint pid, uint256 _amount) external;
    function _vaultHarvest(address masterchefAddress, uint pid) external;
    function vaultSharesTotal(address masterchefAddress, uint pid, address strategyAddress) external view returns (uint256);
    function _emergencyVaultWithdraw(address masterchefAddress, uint pid) external;
    
}

interface IMiniChefV2 {
    function poolLength() external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}

contract TacticMiniApe is ITactic {
    
    function _vaultDeposit(address masterchefAddress, uint pid, uint256 _amount) external override {
        IMiniChefV2(masterchefAddress).deposit(pid, _amount, address(this));
    }
    function _vaultWithdraw(address masterchefAddress, uint pid, uint256 _amount) external override {
        IMiniChefV2(masterchefAddress).withdraw(pid, _amount, address(this));
    }
    function _vaultHarvest(address masterchefAddress, uint pid) external override {
        IMiniChefV2(masterchefAddress).harvest(pid, address(this));
    }
    function vaultSharesTotal(address masterchefAddress, uint pid, address strategyAddress) external override view returns (uint256) {
        (uint256 amount,) = IMiniChefV2(masterchefAddress).userInfo(pid, strategyAddress);
        return amount;
    }
    function _emergencyVaultWithdraw(address masterchefAddress, uint pid) external override {
        IMiniChefV2(masterchefAddress).emergencyWithdraw(pid, address(this));
    }
}