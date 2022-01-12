/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

/**
 *Submitted for verification at Etherscan.io on 2016-10-19
*/

//! A decentralised registry of 4-bytes signatures => method mappings
//! By Parity Team (Ethcore), 2016.
//! Released under the Apache Licence 2.

pragma solidity ^0.4.1;

contract Owned {
  modifier only_owner {
    if (msg.sender != owner) return;
    _;
  }

  event NewOwner(address indexed old, address indexed current);

  function setOwner(address _new) only_owner { NewOwner(owner, _new); owner = _new; }

  address public owner = msg.sender;
}

contract SignatureReg is Owned {
  // mapping of signatures to entries
  mapping (bytes4 => string) public entries;

  // the total count of registered signatures
  uint public totalSignatures = 0;

  // allow only new calls to go in
  modifier when_unregistered(bytes4 _signature) {
    if (bytes(entries[_signature]).length != 0) return;
    _;
  }

  // dispatched when a new signature is registered
  event Registered(address indexed creator, bytes4 indexed signature, string method);

  // constructor with self-registration
  function SignatureReg() {
    register('register(string)');
  }

  // registers a method mapping
  function register(string _method) returns (bool) {
    return _register(bytes4(sha3(_method)), _method);
  }

  // internal register function, signature => method
  function _register(bytes4 _signature, string _method) internal when_unregistered(_signature) returns (bool) {
    entries[_signature] = _method;
    totalSignatures = totalSignatures + 1;
    Registered(msg.sender, _signature, _method);
    return true;
  }

  // in the case of any extra funds
  function drain() only_owner {
    if (!msg.sender.send(this.balance)) {
      throw;
    }
  }
}