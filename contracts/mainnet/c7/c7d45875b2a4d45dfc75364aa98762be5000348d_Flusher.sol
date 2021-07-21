/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface RegistryInterface {
  function signer(address) external view returns (bool);
  function isConnector(address[] calldata) external view returns (bool);
}

contract Flusher {
  event LogCast(address indexed sender, uint value);

  RegistryInterface public constant registry = RegistryInterface(address(0)); // TODO - Change while deploying.

  function spell(address _target, bytes memory _data) internal {
    require(_target != address(0), "target-invalid");
    assembly {
      let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
      switch iszero(succeeded)
        case 1 {
            let size := returndatasize()
            returndatacopy(0x00, 0x00, size)
            revert(0x00, size)
        }
    }
  }

  function cast(address[] calldata _targets, bytes[] calldata _datas) external payable {
    require(registry.signer(msg.sender), "not-signer");
    require(_targets.length == _datas.length , "invalid-array-length");
    require(registry.isConnector(_targets), "not-connector");
    for (uint i = 0; i < _targets.length; i++) {
        spell(_targets[i], _datas[i]);
    }
    emit LogCast(msg.sender, msg.value);
  }

  receive() external payable {}
}