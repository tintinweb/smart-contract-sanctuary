//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ListAddressContract {
  mapping(bytes32 => address) public mapMasterERC20;

  function setContractAddress(string[] memory key, address addressContract)
    public
    virtual
  {
    bytes32[] memory _types = new bytes32[](key.length);
    for (uint256 index = 0; index < key.length; index++) {
      _types[index] = keccak256(abi.encodePacked(key[index]));
    }
    bytes32 _key = keccak256(abi.encodePacked(_types));
    mapMasterERC20[_key] = addressContract;
  }

  function getContractAddress(string[] memory key)
    public
    view
    returns (address)
  {
    bytes32[] memory _types = new bytes32[](key.length);
    for (uint256 index = 0; index < key.length; index++) {
      _types[index] = keccak256(abi.encodePacked(key[index]));
    }
    bytes32 _key = keccak256(abi.encodePacked(_types));
    return mapMasterERC20[_key];
  }
}