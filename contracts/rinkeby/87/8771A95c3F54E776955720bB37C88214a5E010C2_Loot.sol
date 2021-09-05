// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Loot {

    //function mint(address to, uint256 tokenId) public {}
    function balanceOf(address owner) external view returns (uint256 balance) {}
    function ownerOf(uint256 tokenId) external view returns (address owner){}
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external{}
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external{}
    function approve(address to, uint256 tokenId) external{}
    function getApproved(uint256 tokenId) external view returns (address operator){}
    function setApprovalForAll(address operator, bool _approved) external{}
    function isApprovedForAll(address owner, address operator) external view returns (bool){}
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external{}



}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}