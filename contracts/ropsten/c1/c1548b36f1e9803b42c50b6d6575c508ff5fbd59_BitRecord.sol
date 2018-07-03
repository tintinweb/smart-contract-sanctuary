pragma solidity ^0.4.19;
contract BitRecord {
    struct Fact {
        address owner;
        string filename;
    }

    mapping(bytes16 => Fact) facts;
    mapping(bytes16 => mapping(address => bool)) signatures;

    function BitRecord() public {}

    function getFact(bytes16 _fact_id) public constant returns (string _filename) {
        _filename = facts[_fact_id].filename;
    }

    function postFact(bytes16 _fact_id, address _owner, string _filename) public {
        facts[_fact_id] = Fact(_owner, _filename);
    }

    function isSigned(bytes16 _fact_id, address _signer) public constant returns (bool _signed){
      if (signatures[_fact_id][_signer] == true){
          return true;
      }else{
          return false;
      }
    }

    function signFact(bytes16 _fact_id) public {
        signatures[_fact_id][msg.sender] = true;
    }
}