pragma solidity ^0.4.0;
contract SimpleRegistry {
  event LogRegister(bytes32 key, string value);
  mapping (bytes32 => string) public registry;

  function register(bytes32 key, string value) {
    registry[key] = value;
    LogRegister(key, value);
  }

  function get(bytes32 key) public constant returns(string) {
    return registry[key];
  }

}