pragma solidity 0.4.25;

contract SLoader {
  mapping (address => Package) public packages;

  struct Package{
    bytes32 checksum;
    string uri;
  }

  function registerPackage(bytes32 checksum, string uri) public {
    packages[msg.sender] = Package(checksum, uri);
  }
}