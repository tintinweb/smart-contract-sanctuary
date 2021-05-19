pragma solidity ^0.4.24;

import './UpgradeabilityProxy.sol';


contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {

  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

  constructor() public {
    setUpgradeabilityOwner(msg.sender);
  }

  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }


  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  function setUpgradeabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }


  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  function upgradeToAndCall(address implementation, bytes data) payable public onlyProxyOwner {
    upgradeTo(implementation);
    require(implementation.delegatecall(data));
}
}