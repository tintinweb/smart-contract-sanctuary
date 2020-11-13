pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Registry.sol";

library Constants {
  IERC1820Registry public constant REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  // keccak256("ERC777TokensSender")
  bytes32 public constant TOKENS_SENDER_INTERFACE_HASH =
  0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

  // keccak256("ERC777TokensRecipient")
  bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH =
  0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  // keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));
  bytes32 public constant ACCEPT_MAGIC =
  0xa2ef4600d742022d532d4747cb3547474667d6f13804902513b2ec01c848f4b4;
}