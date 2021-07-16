/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IProxy{
    function upgradeTo(address newImplementation) external;
}

contract Upgrade_TimeLock {
    address public owner;
    IProxy public proxy;
    uint256 public doTime;
    address public newImplementation;
    
    constructor(address _addr) public {
        owner = msg.sender;
        proxy = IProxy(_addr);
    }
    
    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }
    
    function upgrade(address _impl) public {
        require(msg.sender == owner);
        newImplementation = _impl;
        doTime = now + (12 * 3600);
    }
    
    function doUpgrade() public {
        require(msg.sender == owner && now >= doTime);
        proxy.upgradeTo(newImplementation);
        doTime = 1e18;
    }
}