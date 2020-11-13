
/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity >=0.7;

import "./MultiSig.sol";

contract MultiSigFactory {

  event ContractCreated(address contractAddress, string typeName);

  function create(address owner) public returns (address) {
    address instance = address(new MultiSig(owner));
    emit ContractCreated(instance, "MultiSig");
    return instance;
  }

  function predict(address owner, bytes32 salt) public view returns (address) {
    return address(uint(keccak256(abi.encodePacked(byte(0xff), address(this), salt,
            keccak256(abi.encodePacked(type(MultiSig).creationCode, owner))
        ))));
  }

  function create(address owner, bytes32 salt) public returns (address) {
    address instance = address(new MultiSig{salt: salt}(owner));
    emit ContractCreated(instance, "MultiSig");
    return instance;
  }
}