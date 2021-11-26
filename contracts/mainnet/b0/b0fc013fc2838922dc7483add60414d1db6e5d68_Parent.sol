/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Parent {
  event Upgraded(address indexed implementation);
  event ProxyAdminChanged(address);
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
  address public proxyAdmin;

  constructor() {
      proxyAdmin=msg.sender;
      emit ProxyAdminChanged(msg.sender);
  }
  
  function setProxyAdmin(address newProxyAdmin) public onlyProxyAdmin(){
      proxyAdmin=newProxyAdmin;
      emit ProxyAdminChanged(newProxyAdmin);
  }
 
  function getImplementation() public view returns (address impl){
      bytes32 slot = IMPLEMENTATION_SLOT;
      assembly {
          impl := sload(slot)
      }
    }
    
  fallback() external payable {
    address adrs=getImplementation();
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), adrs, 0, calldatasize(), 0, 0)
      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())
      switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }
  modifier onlyProxyAdmin() {
    require(msg.sender==proxyAdmin,"Must be a proxy admin");
    _;
  }

  function isContract(address _addr) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) }
    return (codehash != 0x0 && codehash != accountHash);
  }

  function setImplementation(address newImplementation) public onlyProxyAdmin{
      require(isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");
      require(msg.sender==proxyAdmin);
      bytes32 slot = IMPLEMENTATION_SLOT;
      assembly {
        sstore(slot, newImplementation)
      }
      emit Upgraded(newImplementation);
      (bool success, bytes memory data) = newImplementation.delegatecall(
        abi.encodeWithSignature("initialize()")
      );
  }
}