/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ILiquiVault {
    function deposit() payable external;
    function withdraw() external;
    function collect() external;
    
    function users(address) external view returns (uint shares, uint unlockTime);
    function getInfo() external view returns (
        bool active,
        uint minAmount,
        uint maxAmount,
        uint lockPeriod,
        uint rewardMultiplier,
        uint activeCount,
        uint activeShares,
        uint aggCount,
        uint aggShares,
        uint aggRewards
    );
}

contract LiquiVaultProxy is ILiquiVault {

    address sender;
    
    address public owner;
    ILiquiVault public target;
    
    event TargetChanged(address oldTarget, address newTarget);
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user);
    event Collect();
    
    function msgSender() external view returns (address) {
        return sender;
    }
    
    modifier contextual() {
        require(tx.origin == msg.sender, 'only accounts');
        sender = msg.sender;
        _;
        sender = address(0x0);
    }
    
    constructor(address _target) {
        target = ILiquiVault(_target);
        owner = msg.sender;
    }
    
    function setTarget(address _target) public {
        require(msg.sender == owner, 'not authorized');
        target = ILiquiVault(_target);
    }
    
    function users(address user) override external view returns (uint shares, uint unlockTime) {
        return target.users(user);
    }
    
    function getInfo() override external view returns (bool,uint,uint,uint,uint,uint,uint,uint,uint,uint) {
        return target.getInfo();
    }
    
    function deposit() contextual override payable external  {
        target.deposit{ value: msg.value }();
        emit Deposit(msg.sender, msg.value);
    }
    
    function collect() contextual override external  {
        target.collect();
        emit Collect();
    }
    
    function withdraw() contextual override  external  {
        target.withdraw();
        emit Withdraw(msg.sender);
    }
    
}