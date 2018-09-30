contract SLoader {
  //function owner(bytes32 node) constant returns(address);
  //function setOwner(bytes32 node, address owner);
  uint8 releaseCount;
  Version[] releases;
  address owner;

  modifier ifOwner {
    if (owner != msg.sender)
      throw;
    _;
  }

  function SLoader() {
    owner = msg.sender;
  }

  function addRelease(bytes32 checksum, string url) ifOwner {
    releases.push(Version(checksum, url));
    releaseCount++;
  }

  function latestReleaseChecksum() constant returns (bytes32) {
    return releases[releaseCount - 1].checksum;
  }

  function latestReleaseUrl() constant returns (string) {
    return releases[releaseCount - 1].url;
  }

  struct Version {
    bytes32 checksum;
    string url;
  }
}