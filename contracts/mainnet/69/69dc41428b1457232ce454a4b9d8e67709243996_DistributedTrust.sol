pragma solidity ^0.4.20;

contract Pointer {
    uint256 public pointer;

    function bumpPointer() internal returns (uint256 p) {
        return pointer++;
    }
}

contract DistributedTrust is Pointer {

    mapping(uint256 => Fact) public facts;
    mapping(uint256 => mapping(address => bool)) public validations;

    event NewFact(uint256 factIndex, address indexed reportedBy, string description, string meta);
    event AttestedFact(uint256 indexed factIndex, address validator);

    struct Fact {
        address reportedBy;
        string description;
        string meta;
        uint validationCount;
    }

    modifier factExist(uint256 factIndex) {
        assert(facts[factIndex].reportedBy != 0);
        _;
    }

    modifier notAttestedYetBySigner(uint256 factIndex) {
        assert(validations[factIndex][msg.sender] != true);
        _;
    }

    // "Olivia Marie Fraga Rolim. Born at 2018-04-03 20:54:00 BRT, in the city of Rio de Janeiro, Brazil", 
    // "ipfs://QmfD5tpeF8UpHZMnSVq3qNPVNwd8JNfF4g8L3UFVUfkiRK"
    function newFact(string description, string meta) public {
        uint256 factIndex = bumpPointer();
     
        facts[factIndex] = Fact(msg.sender, description, meta, 0);
        attest(factIndex);
        
        NewFact(factIndex, msg.sender, description, meta);
    }

    function attest(uint256 factIndex) factExist(factIndex) notAttestedYetBySigner(factIndex) public returns (bool) {
        validations[factIndex][msg.sender] = true;
        facts[factIndex].validationCount++;
        
        AttestedFact(factIndex, msg.sender);
        return true;
    }
    
    function isTrustedBy(uint256 factIndex, address validator) factExist(factIndex) view public returns (bool isTrusted) {
        return validations[factIndex][validator];
    }

}