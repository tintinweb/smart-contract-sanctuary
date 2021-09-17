// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ChildMintableERC721.sol";

interface IChildMintableERC721 {
  function DEFAULT_ADMIN_ROLE() external view returns (uint);
  function grantRole(bytes32 role, address account) external;
}


contract KoNFTFactory is NativeMetaTransaction {
  address public constant CHILD_CHAIN_MANAGER_PROXY_POLYGON = 0xb5505a6d998549090530911180f38aC5130101c6; // Testnet

  constructor() {
    _initializeEIP712("KoNFTFactory");
  }

  function addAdminRole(address _userAddress, address _galleryAddress) external {
    uint DEFAULT_ADMIN_ROLE = IChildMintableERC721(_galleryAddress).DEFAULT_ADMIN_ROLE();
    IChildMintableERC721(_galleryAddress).grantRole(bytes32(DEFAULT_ADMIN_ROLE),_userAddress);
  }

  function deployERC721(string memory _token, string memory _trigram) external returns (ChildMintableERC721) {
    return new ChildMintableERC721(_token, _trigram, CHILD_CHAIN_MANAGER_PROXY_POLYGON);
  }
}