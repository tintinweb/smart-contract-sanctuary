/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract CamundaCloud {
  string internal constant HASH_EXISTS = 'Hash for given ID already exists';

  struct CamundaCloudHash {
    string ccHash;
    // this looks funny right? this is because in EVM mappings have an entry FOR EVERY key. so we need to flag if this is really set or not ;-)
    bool isValue;
  }

  // instances id --> hash
  mapping(string => CamundaCloudHash) public hashes;
  address public manager;

  // making sure only the contract creator can register new hashes
  modifier restricted() {
    require(msg.sender == manager);
    _;
  }

  // there is no such thing as map.contains(key) in EVM :) hence the funny isValue thingy
  function hashExists(string memory uuid) private view returns (bool) {
    return hashes[uuid].isValue;
  }

  constructor() {
    // manager is used for the restriced function above
    manager = msg.sender;
  }

  function add(string memory uuid, string memory ccHash) public restricted {
    // fail as soon as there is a hash present (note this is a view function so it does not spend gas)
    require(!hashExists(uuid), HASH_EXISTS);

    // allocate some EVM disk space, assign it to the mapping
    CamundaCloudHash storage newCcHash = hashes[uuid];
    // set content (this burns some gas!)
    newCcHash.ccHash = ccHash;
    newCcHash.isValue = true;
  }
}