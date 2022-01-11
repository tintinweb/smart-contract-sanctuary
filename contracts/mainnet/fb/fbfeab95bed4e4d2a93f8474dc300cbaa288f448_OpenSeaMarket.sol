/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// File: contracts/LooksRareMarket.sol



pragma solidity ^0.8.6;

contract OpenSeaMarket {
  bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
  bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  constructor(address initialImpl, address initialAdmin) {
    assembly {
      sstore(_ADMIN_SLOT, initialAdmin)
      sstore(_IMPLEMENTATION_SLOT, initialImpl)
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

  function changeAdmin(address newAdmin) external {
    require(msg.sender == admin(), 'admin only');
    bytes32 slot = _ADMIN_SLOT;
    assembly {
      sstore(slot, newAdmin)
    }
  }
  function upgrade(address newImplementation) external {
    require(msg.sender == admin(), 'admin only');
    bytes32 slot = _IMPLEMENTATION_SLOT;
    assembly {
      sstore(slot, newImplementation)
    }
  }

  fallback() external payable {
    assembly {
        let _target := sload(_IMPLEMENTATION_SLOT)
        calldatacopy(0x0, 0x0, calldatasize())
        let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
        returndatacopy(0x0, 0x0, returndatasize())
        switch result case 0 {revert(0, 0)} default {return (0, returndatasize())
        }
    }
  }

  receive() external payable {
    assembly {
        let _target := sload(_IMPLEMENTATION_SLOT)
        calldatacopy(0x0, 0x0, calldatasize())
        let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
        returndatacopy(0x0, 0x0, returndatasize())
        switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}