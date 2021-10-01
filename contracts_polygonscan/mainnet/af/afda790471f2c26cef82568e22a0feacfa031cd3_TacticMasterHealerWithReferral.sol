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

interface IMasterchef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _address) external view returns (uint256, uint256);
    function harvest(uint256 _pid, address _to) external;
}

//Polygon: 0x669eCb003c650e8BAC8a4D930c7aFFE44579Ba52
contract TacticMasterHealer is ITactic {
    
    function _vaultDeposit(address masterchefAddress, uint pid, uint256 _amount) external virtual override {
        IMasterchef(masterchefAddress).deposit(pid, _amount);
    }
    
    function _vaultWithdraw(address masterchefAddress, uint pid, uint256 _amount) external override {
        IMasterchef(masterchefAddress).withdraw(pid, _amount);
    }
    
    function _vaultHarvest(address masterchefAddress, uint pid) external override {
        IMasterchef(masterchefAddress).withdraw(pid, 0);
    }
    
    function vaultSharesTotal(address masterchefAddress, uint pid, address strategyAddress) external override view returns (uint256) {
        (uint256 amount,) = IMasterchef(masterchefAddress).userInfo(pid, strategyAddress);
        return amount;
    }
    
    function _emergencyVaultWithdraw(address masterchefAddress, uint pid) external override {
        IMasterchef(masterchefAddress).emergencyWithdraw(pid);
    }
    
}

interface IMasterchefWithReferral {
    function deposit(uint256 _pid, uint256 _amount, address referrer) external;
}

contract TacticMasterHealerWithReferral is TacticMasterHealer {
    
    function _vaultDeposit(address masterchefAddress, uint pid, uint256 _amount) external override {
        IMasterchefWithReferral(masterchefAddress).deposit(pid, _amount, address(0));
    }
}