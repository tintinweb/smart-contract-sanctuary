/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IDeployer {
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}

contract Deployer {
  IDeployer public immutable deployer;

  constructor(IDeployer _deployer) public {
    // Use EIP-2470 SingletonFactory address by default
    deployer = address(_deployer) == address(0) ? IDeployer(0xa0Ca369E9962AdEbDd506143BAf48C5c0EA31dcE) : _deployer;
    emit Deployed(tx.origin, address(this));
  }

  event Deployed(address indexed sender, address indexed addr);

  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract) {
    createdContract = deployer.deploy(_initCode, _salt);
    require(createdContract != address(0), "Deploy failed");
    emit Deployed(msg.sender, createdContract);
  }
}