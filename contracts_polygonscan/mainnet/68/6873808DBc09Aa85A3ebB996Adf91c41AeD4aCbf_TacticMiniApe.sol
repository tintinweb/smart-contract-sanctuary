// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libs/ITactic.sol";

interface IMiniChefV2 {
    function poolLength() external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}

//Polygon: 0x48D446A5571592EC101e59FEb47A0aFdD4A42566
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
    function vaultSharesTotal(address masterchefAddress, uint pid) external override view returns (uint256) {
        (uint256 amount,) = IMiniChefV2(masterchefAddress).userInfo(pid, msg.sender);
        return amount;
    }
    function _emergencyVaultWithdraw(address masterchefAddress, uint pid) external override {
        IMiniChefV2(masterchefAddress).emergencyWithdraw(pid, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

//Tactics are used to interact with a strategy's underlying farm
interface ITactic {
    
    function _vaultDeposit(address masterchefAddress, uint pid, uint256 _amount) external;
    function _vaultWithdraw(address masterchefAddress, uint pid, uint256 _amount) external;
    function _vaultHarvest(address masterchefAddress, uint pid) external;
    function vaultSharesTotal(address masterchefAddress, uint pid) external view returns (uint256);
    function _emergencyVaultWithdraw(address masterchefAddress, uint pid) external;
    
}