// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.25;

interface IERC1155 {
  function safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes data
  ) external;
}
contract StandoffNFT_5 {
  address public owner;
  uint256 public TOKEN_ID = 4;
  IERC1155 public collection;

  function constructor(IERC1155 _collection) {
    owner = msg.sender;
    collection = _collection;
  }

  function transfer() external {
    require(owner == msg.sender, "only owner can transfer NFT");
    collection.safeTransferFrom(address(this), msg.sender, TOKEN_ID, 1, "");
  }

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }
}