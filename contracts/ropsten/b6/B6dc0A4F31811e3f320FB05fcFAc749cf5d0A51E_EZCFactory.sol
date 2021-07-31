/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;



// File: masterFactory.sol

contract EZCFactory {
  address[] public allFactories;

  address public owner;

  event ContractAdded(address indexed addedContract, uint256 numContracts);

  constructor() {
      owner = msg.sender;
  }

  function factoryCount() external view returns (uint) {
    return allFactories.length;
  }

  function addFactory(address factoryAddress) external {
    require(msg.sender == owner);

    allFactories.push(factoryAddress);

    emit ContractAdded(factoryAddress, allFactories.length);
  }
}