/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ILiquiFarm {
    
    function deposit() payable external;
    function compound() external;
    function withdraw() external;
    function claim() external;

    function users(address) external view returns (uint managed, uint joined, uint w, uint c, uint r, uint b);
    function usersCount () external view returns (uint);
    function farmers(uint) external view returns (address);
    function velocity() external view returns (uint deltaCake, uint deltaSeconds);
    function reserves() external view returns (uint totalSupply, string memory symbol1, uint112 reserve1, string memory symbol2, uint112 reserve2);
    function estimateCake(uint bei) external view returns (uint cei);
    function estimateBnb(uint cei) external view returns (uint bei);
    function estimateClaims(address user) external view returns (uint cei);
    function liquiLP() external view returns(uint);
    function totalLiquidity() external view returns(uint);
    function collectibles() external view returns (uint bei, uint cei, uint total);
}

contract LiquiProxy is ILiquiFarm {

    address sender;
    
    address public owner;
    ILiquiFarm public target;
    
    function msgSender() public view returns (address) {
        return sender;
    }
    
    modifier contextual() {
        sender = msg.sender;
        _;
    }
    
    constructor(address _target) {
        target = ILiquiFarm(_target);
        owner = msg.sender;
    }
    
    function setTarget(address _target) public {
        require(msg.sender == owner, 'not authorized');
        target = ILiquiFarm(_target);
    }
    
    // LiquiProxy
    function deposit() contextual override payable external  {
        target.deposit{ value: msg.value }();
    }
    
    function compound() contextual override external  {
        target.compound();
    }
    
    function withdraw() contextual override  external  {
        target.withdraw();
    }
    
    function claim() contextual override  external  {
        target.claim();
    }
    
    function users(address user) override external view returns (uint managed, uint joined, uint w, uint c, uint r, uint b) {
        return target.users(user);
    }
    
    function usersCount () override external view returns (uint) {
        return target.usersCount();
    }
    
    function farmers(uint index) override external view returns(address) {
        return target.farmers(index);
    }

    function velocity() override external view returns (uint deltaCake, uint deltaSeconds) {
        return target.velocity();
    }
    
    function reserves() override external view returns (uint totalSupply, string memory symbol1, uint112 reserve1, string memory symbol2, uint112 reserve2) {
        return target.reserves();
    }
    
    function liquiLP() override external view returns(uint) {
        return target.liquiLP();
    }
    
    function totalLiquidity() override external view returns(uint) {
        return target.totalLiquidity();
    }

    function estimateCake(uint bei) override external view returns (uint cei) {
        return target.estimateCake(bei);
    }
    
    function estimateBnb(uint cei) override external view returns (uint bei) {
        return target.estimateBnb(cei);
    }
    
    function estimateClaims(address user) override external view returns (uint cei) {
        return target.estimateClaims(user);
    }
    
    function collectibles() override external view returns (uint bei, uint cei, uint total) {
        return target.collectibles();
    }
}