//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dENS2 {
  address internal owner = msg.sender;
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

  function registerName(string memory _name, address _address) public isOwner {
    nametoaddress.push(nameToAddress({ name: _name, ethAddress: _address }));
    nameToAddressMapping[_name] = _address;
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