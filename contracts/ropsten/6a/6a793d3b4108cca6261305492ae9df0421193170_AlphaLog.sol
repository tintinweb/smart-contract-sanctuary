// This code is modified from smart contract of ARTIFACTS
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
contract AlphaLog is Owned {
  struct Website {
    address web_addr;
    string web_name;
    bool is_authorized;
  }
  struct Alpha {
    address web_addr;
    string data_id;
    string entity;
    bytes32 data_hash;
    bool isValue;
  }
  
  mapping (address => Website) public websites;
  
  uint public counter;
  mapping (bytes32 => Alpha) public alpha;

  function addWebsite(address id, string name) public onlyOwner {
    websites[id] = Website(id, name, true);
  }
  function deleteWebsite(address id) public onlyOwner {
    delete websites[id];
  }

  function addAlpha(string art_id, string entity, bytes32 hash) public returns (uint) {
    require(websites[msg.sender].is_authorized);
    require(!alpha[hash].isValue);

    counter++;
    alpha[hash] = Alpha(msg.sender, art_id, entity, hash, true);
    return counter;
  }
}