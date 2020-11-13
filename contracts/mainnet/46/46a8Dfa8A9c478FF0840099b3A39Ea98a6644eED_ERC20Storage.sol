// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract ERC20Storage {
  // The state variables we care about.
  bytes32 constant DIAMOND_STORAGE_POSITION_ERC20 = keccak256(
    "diamond.standard.diamond.storage.erc20"
  );

  struct TokenStorage {
    string  name;
    string  symbol;
    uint8  decimals;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    uint256   totalSupply;
  }

  // Creates and returns the storage pointer to the struct.
  function erc20Storage() internal pure returns (TokenStorage storage ms) {
    bytes32 position = DIAMOND_STORAGE_POSITION_ERC20;
    assembly {
      ms.slot := position
    }
  }
}
