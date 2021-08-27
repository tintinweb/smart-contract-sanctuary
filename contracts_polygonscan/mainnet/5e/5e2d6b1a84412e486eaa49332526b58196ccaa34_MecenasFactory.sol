// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Mecenas.sol";


contract MecenasFactory {

uint public counterpools;
Mecenas[] public pools;
mapping(address => Mecenas[]) public ownerPools;


event ChildCreated(address childAddress, address yield, address underlying, address owner);


    function newMecenasPool(address _yield, address _underlying) external {
        require(msg.sender != address(0));
        require(_yield != address(0));
        require(_underlying != address(0));
        
        counterpools++;
        Mecenas newpool = new Mecenas(msg.sender, _yield, _underlying);
        pools.push(newpool);
        ownerPools[msg.sender].push(newpool);
        
        emit ChildCreated(address(newpool), _yield, _underlying, msg.sender);
        
    }
    
    function getOwnerPools(address _account) external view returns (Mecenas[] memory) {
      return ownerPools[_account];
        
    } 
    
    function getTotalPools() external view returns (Mecenas[] memory) {
      return pools;
    }

    
}