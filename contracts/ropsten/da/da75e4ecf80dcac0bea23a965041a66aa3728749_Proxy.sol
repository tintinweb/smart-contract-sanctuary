/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract Proxy {
  bytes32 private constant _ADMIN_SLOT =      0x62e8875e08e2bc7c826b06779774f01ef34f624f260eb50d554cfe1b2dc382d5;
  bytes32 private constant _IMPLEMENTATION_SLOT = 0x1c7a3efabe7db367994ac205a2b0b35c3846189285e89a4008dec4726d6fb681;
 
  
  constructor() {
    bytes32 slot = _ADMIN_SLOT;
    address _admin = msg.sender;
    assembly {
      sstore(slot, _admin)
    }
  }

  function admin() public view returns (address adm) {
    bytes32 slot = _ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  function implementation() public view returns (address impl) {
    bytes32 slot = _IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  function upgrade(address newImplementation) external {
    require(msg.sender == admin(), 'admin only');
    bytes32 slot = _IMPLEMENTATION_SLOT;
    assembly {
      sstore(slot, newImplementation)
    }
  }

  receive() external payable {
    
  }

  fallback() external payable {
    assembly {
      let _target := sload(_IMPLEMENTATION_SLOT)
      calldatacopy(0x0, 0x0, calldatasize())
      let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
      returndatacopy(0x0, 0x0, returndatasize())
      switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
    }
  }
}