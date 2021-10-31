/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Create3Factory {

  bytes internal constant PROXY_CHILD_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

  function deploy(bytes32 _salt, bytes memory _creationCode) payable external returns (address proxy) {
    // Creation code
    bytes memory creationCode = PROXY_CHILD_BYTECODE;

    assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    require(proxy != address(0), 'ERR_PROXY');

    (bool success,) = proxy.call{ value: msg.value }(_creationCode);
    require(success, 'ERR_CONTRACT');
  }

}