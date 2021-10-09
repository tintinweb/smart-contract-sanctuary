// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./MintableERC721.sol";

contract GoerliNFTFactory is NativeMetaTransaction, ContextMixin {

  address public constant PREDICATE_PROXY_ADDRESS = 0x56E14C4C1748a818a5564D33cF774c59EB3eDF59;

  constructor() {
    _initializeEIP712("KoNFTFactory");
  }

  function deployERC721(string memory _token, string memory _trigram) external returns (MintableERC721) {
    MintableERC721 gallery = new MintableERC721(_token, _trigram, msgSender());
    gallery.grantRole(gallery.PREDICATE_ROLE(), PREDICATE_PROXY_ADDRESS);
    return gallery;
  }
}