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

  function checksum(address sl_dapp) constant public returns (bytes32) {
    return packages[sl_dapp].checksum;
  }

  function uri(address sl_dapp) constant public returns (string) {
    return packages[sl_dapp].uri;
  }

}