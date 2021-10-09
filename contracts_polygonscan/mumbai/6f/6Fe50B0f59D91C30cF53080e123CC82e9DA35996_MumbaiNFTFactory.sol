// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ChildMintableERC721.sol";

contract MumbaiNFTFactory is NativeMetaTransaction, ContextMixin {

  address public constant CHILD_CHAIN_MANAGER_PROXY = 0xb5505a6d998549090530911180f38aC5130101c6;

  constructor() {
    _initializeEIP712("KoNFTFactory");
  }

  function deployERC721(string memory _token, string memory _trigram) external returns (ChildMintableERC721) {
    return new ChildMintableERC721(_token, _trigram, CHILD_CHAIN_MANAGER_PROXY, msgSender());
  }
}