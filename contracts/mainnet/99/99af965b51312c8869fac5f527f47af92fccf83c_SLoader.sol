pragma solidity 0.4.25;

contract SLoader {
  uint8 public releaseCount;
  Version[] releases;
  address owner;

  modifier ifOwner {
    require(owner == msg.sender);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function addRelease(bytes32 checksum, string url) ifOwner public {
    releases.push(Version(checksum, url));
    releaseCount++;
  }

  function latestReleaseChecksum() constant public returns (bytes32) {
    return releases[releaseCount - 1].checksum;
  }

  function latestReleaseUrl() constant public returns (string) {
    return releases[releaseCount - 1].url;
  }

  function releaseChecksum(uint8 index) constant public returns (bytes32) {
    return releases[index].checksum;
  }

  function releaseUrl(uint8 index) constant public returns (string) {
    return releases[index].url;
  }

  struct Version {
    bytes32 checksum;
    string url;
  }
}