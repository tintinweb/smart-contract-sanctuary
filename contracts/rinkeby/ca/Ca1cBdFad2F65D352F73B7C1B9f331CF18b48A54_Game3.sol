//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game3 {
  event Winner(address winner);

  bytes32 internal constant SECRET_SLOT = keccak256("secret.variable.slot");

  constructor(uint secret) {
    bytes32 slot = SECRET_SLOT;
    assembly {
      sstore(slot, secret)
    }
  }

  function win(uint guess) payable external {
    uint secret;
    bytes32 slot = SECRET_SLOT;
    assembly {
      secret := sload(slot)
    }
    require(guess == secret);
    emit Winner(msg.sender);
  }
}

