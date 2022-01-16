//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dENS2_1 {
  address public owner = msg.sender;
  uint256 indexCount;

  modifier isOwner() {
    require(msg.sender == owner, "Only Owner can send transaction!");
    _;
  }

  struct nameToAddress {
    string name;
    address ethAddress;
  }

  nameToAddress[] nametoaddress;

  mapping(string => address) public nameToAddressMapping;

  function registerName(string memory _name) public {
    require(
      bytes(readAddressName(msg.sender)).length == 0,
      "Address is already registered!"
    );
    require(
      nameToAddressMapping[_name] == 0x0000000000000000000000000000000000000000,
      "Name already registered!"
    );
    nametoaddress.push(nameToAddress({ name: _name, ethAddress: msg.sender }));
    nameToAddressMapping[_name] = msg.sender;
    indexCount++;
  }

  function readAddressName(address _address)
    public
    view
    returns (string memory)
  {
    for (uint256 i = 0; i < indexCount; i++) {
      if (nametoaddress[i].ethAddress == _address) {
        string memory name = nametoaddress[i].name;
        return name;
      }
    }
  }

  function transferOwnership(address _newOwner) public isOwner {
    owner = _newOwner;
  }
}