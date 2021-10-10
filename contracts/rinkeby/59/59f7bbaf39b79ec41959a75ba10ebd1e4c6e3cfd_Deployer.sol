/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// Wrapper around SingletonFactory. Originally from https://github.com/tornadocash/deployer/blob/master/contracts/Deployer.sol
interface IFactory {
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}

contract Deployer {
  IFactory public immutable factory;

  constructor(IFactory _factory) public {
    factory = _factory;
    emit Deployed(tx.origin, address(this));
  }

  event Deployed(address indexed sender, address indexed addr);

  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract) {
    createdContract = factory.deploy(_initCode, _salt);
    require(createdContract != address(0), "Deploy failed");
    emit Deployed(msg.sender, createdContract);
  }
}