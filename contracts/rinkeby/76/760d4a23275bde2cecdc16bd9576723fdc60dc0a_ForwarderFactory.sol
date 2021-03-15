// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import './Forwarder.sol';
import './CloneFactory.sol';

contract ForwarderFactory is CloneFactory {
  address public implementationAddress;

  event ForwarderCreated(address newForwarderAddress, address parentAddress);

  constructor(address _implementationAddress) {
    implementationAddress = _implementationAddress;
  }

  function createForwarder(address parent, bytes32 salt) external {
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    bytes32 finalSalt = keccak256(abi.encodePacked(parent, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    Forwarder(clone).init(parent);
    emit ForwarderCreated(clone, parent);
  }
}