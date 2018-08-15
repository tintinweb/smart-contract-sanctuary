pragma solidity ^0.4.21;

// Ownership
contract Owned {
  address public owner;

  function Owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }
  
}

// Proof Of Existence contract
contract ArtifactProofOfExistence is Owned {
  struct Website {
    address web_addr;
    string web_name;
    bool is_authorized;
  }
  struct Artifact {
    address web_addr;
    string art_id;
    string entity;
    bytes32 hash;
    bool isValue;
  }
  
  mapping (address => Website) public websites;
  
  uint public counter;
  mapping (bytes32 => Artifact) public artifacts;

  function addWebsite(address id, string name) public onlyOwner {
    websites[id] = Website(id, name, true);
  }
  
  function addArtifact(string art_id, string entity, bytes32 hash) public returns (uint) {
    require(websites[msg.sender].is_authorized);
    require(!artifacts[hash].isValue);

    counter++;
    artifacts[hash] = Artifact(msg.sender, art_id, entity, hash, true);
    return counter;
  }
}