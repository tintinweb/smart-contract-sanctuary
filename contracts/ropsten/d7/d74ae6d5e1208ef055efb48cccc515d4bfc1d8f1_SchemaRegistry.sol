pragma solidity ^0.4.24;

// imported contracts/proposals/OCP-IP-9/ISchemaRegistry.sol
contract ISchemaRegistry {
  event SchemaAdded(bytes32 hash, uint256 updatedAtUtcSec);
  function hashSchema(string name, string definition) public pure returns(bytes32);
  function addSchema(string name, string definition) public;
  function hasSchema(bytes32 hash) public view returns(bool);
  function name(bytes32 hash) public view returns(string);
  function definition(bytes32 hash) public view returns(string);
}

contract SchemaRegistry is ISchemaRegistry {
  struct Props {
    string name;
    string definition;
  }
  mapping(bytes32 => bool) private _hasSchema;
  mapping(bytes32 => Props) private _schema;
  function hashSchema(string, string definition) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(definition));
  }
  function addSchema(string name, string definition) public {
    bytes32 hash = hashSchema(name, definition);
    require(!_hasSchema[hash]);
    _hasSchema[hash] = true;
    _schema[hash] = Props({
      name: name,
      definition: definition
    });
    emit SchemaAdded(hash, now); // solhint-disable-line not-rely-on-time
  }
  function hasSchema(bytes32 hash) public view returns(bool) {
    return _hasSchema[hash];
  }
  function name(bytes32 hash) public view returns(string) {
    require(_hasSchema[hash]);
    return _schema[hash].name;
  }
  function definition(bytes32 hash) public view returns(string) {
    require(_hasSchema[hash]);
    return _schema[hash].definition;
  }
}