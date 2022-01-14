//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dENS {
  address public owner = msg.sender;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  struct nameToETHAddress {
    string name;
    address ethAddress;
  }

  nameToETHAddress[] nametoethaddress;

  mapping(string => address) public nameToAddressMapping;

  function registerName(string memory _name, address _address)
    public
    onlyOwner
  {
    require(msg.sender == owner);
    nametoethaddress.push(
      nameToETHAddress({ name: _name, ethAddress: _address })
    );
    nameToAddressMapping[_name] = _address;
  }
}