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
contract OSBLog is Owned {
  struct Website {
    address web_addr;
    string web_name;
    bool is_authorized;
  }
  struct OSB_data {
    address web_addr;
    string data_id;
    string entity;
    bytes32 data_hash;
    bool isValue;
  }
  
  struct Request {
    uint group_size;
    uint approve_cnt;
    uint[] entity_list;
    bool[] approve_state;
    bool is_all_approved;
    address web_addr;
    bool isValue;
  }
  
  
  
  mapping (address => Website) public websites;
  
  uint public counter;
  mapping (bytes32 => OSB_data) public log;

  function addWebsite(address id, string name) public onlyOwner {
    websites[id] = Website(id, name, true);
  }
  function deleteWebsite(address id) public onlyOwner {
    delete websites[id];
  }

  function addLog(string art_id, string entity, bytes32 hash) public returns (uint) {
    require(websites[msg.sender].is_authorized);
    require(!log[hash].isValue);

    counter++;
    log[hash] = OSB_data(msg.sender, art_id, entity, hash, true);
    return counter;
  }
  
  mapping (bytes32 => Request) public Requests;
  function initRequest(uint[] entity_list) public returns (bytes32) {
    require(websites[msg.sender].is_authorized);
    // TODO: calculate req_hash using entity_list
    bytes32 req_hash = keccak256(entity_list, counter);

    require(!Requests[req_hash].isValue);
    counter++;

    uint len = entity_list.length;
    Requests[req_hash] = Request(len, 0, entity_list, new bool[](len), false, msg.sender, true);
    return req_hash;
    
  }
  
  function approveRequest(bytes32 req_hash, uint entity) public returns (bool) {
    require(websites[msg.sender].is_authorized);
    require(msg.sender == Requests[req_hash].web_addr);
    counter++;
    
    for (uint i = 0; i < Requests[req_hash].group_size; ++i) { 
      if (entity == Requests[req_hash].entity_list[i]) {
        if (Requests[req_hash].approve_state[i] == false) {
          Requests[req_hash].approve_state[i] = true;
          Requests[req_hash].approve_cnt += 1;
          if (Requests[req_hash].approve_cnt == Requests[req_hash].group_size) {
            Requests[req_hash].is_all_approved = true;
            return true;
          }
        }
        break;
      }
    }
    return false;
  }
}