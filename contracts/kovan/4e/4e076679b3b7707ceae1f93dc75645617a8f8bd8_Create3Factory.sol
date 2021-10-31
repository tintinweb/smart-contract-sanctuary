/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Create3Factory {

  bytes internal constant PROXY_CHILD_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  function deploy(bytes32 _salt, bytes memory _creationCode) payable external returns (address proxy) {
    // Creation code
    bytes memory creationCode = PROXY_CHILD_BYTECODE;

    assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    require(proxy != address(0), 'ERR_PROXY');

    (bool success,) = proxy.call{ value: msg.value }(_creationCode);
    require(success, 'ERR_CONTRACT');
  }

function addressOf(bytes32 _salt) external view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
  }

}