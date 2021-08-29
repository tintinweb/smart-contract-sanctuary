// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Mecenas.sol";


contract MecenasFactory {

uint public counterpools;
Mecenas[] public pools;
address[] public markets;
address[] public tokens;


mapping(address => Mecenas[]) public ownerPools;
mapping(address => address[]) public ownerMarkets;
mapping(address => address[]) public ownerUnderlying;

event ChildCreated(address childAddress, address yield, address underlying, address owner);


    function newMecenasPool(address _yield, address _underlying) external {
        require(msg.sender != address(0));
        require(_yield != address(0));
        require(_underlying != address(0));
        
        counterpools++;
        Mecenas newpool = new Mecenas(msg.sender, _yield, _underlying);
        pools.push(newpool);
        markets.push(_yield);
        tokens.push(_underlying);
        
        ownerPools[msg.sender].push(newpool);
        ownerMarkets[msg.sender].push(_yield);
        ownerUnderlying[msg.sender].push(_underlying);
        
        
        emit ChildCreated(address(newpool), _yield, _underlying, msg.sender);
        
    }
    
    function getOwnerPools(address _account) external view returns (Mecenas[] memory) {
      return ownerPools[_account];
        
    } 
    
    function getOwnerMarkets(address _account) external view returns (address[] memory) {
      return ownerMarkets[_account];
        
    }
    
    function getOwnerUnderlying(address _account) external view returns (address[] memory) {
      return ownerUnderlying[_account];
        
    }
    
    
    function getTotalPools() external view returns (Mecenas[] memory) {
      return pools;
    }

    
    function getTotalMarkets() external view returns (address[] memory) {
      return markets;
    }
    
    
    function getTotalUnderlying() external view returns (address[] memory) {
      return tokens;
    }


}