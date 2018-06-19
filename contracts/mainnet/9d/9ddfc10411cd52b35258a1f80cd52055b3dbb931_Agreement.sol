pragma solidity ^0.4.21;


// Problem Statement
// ***1) User A Creates A contract with fields Contract Title Document Title, Version,
//  description (Max 32 Characters) Owner (Your Name or Your organization Name) 
// ParticipantID(with public address) Consent_Details (Max 32 Characters)
// ***2) User B Signs the contract
// ***3) User A can Verify
contract Agreement {
    address private owner;

// A struct named Contract is requred to hold objects
    struct Contract {
        uint id; //0
        bytes32 contractTitle; //1
        bytes32 documentTitle; //2
        bytes32 version; //3
        bytes32 description; //4
        address participant; //5
        bytes32 consent; //6
        bool isSigned; //7
    }

// we need mapping so for contract listing 
    mapping (uint => Contract) public contracts;

// Contract Count holder
    uint public contractCount;
    
    function Agreement () public {
        owner = msg.sender;
    }

// Event when new contract is created to notifiy all clients
    event ContractCreated(uint contractId, address participantId);
// Event when a contract is signed
    event ContractSigned(uint contractId);
    
// A contract can be only added by owner and user must exist;
    function addContract(
        bytes32 contractTitle, bytes32 documentTitle, bytes32 version,
        bytes32 description, address participant, bytes32 consent
        ) public {
        require(owner == msg.sender);
        contractCount += 1;
        contracts[contractCount] = 
        Contract(contractCount, contractTitle, documentTitle, version, description, participant, consent, false);
        emit ContractCreated(contractCount, participant);
    }
    
    function addMultipleContracts(
        bytes32 contractTitle, bytes32 documentTitle, bytes32 version,
        bytes32 description, address[] _participant, bytes32 consent
        ) public {
        require(owner == msg.sender);
        uint arrayLength = _participant.length;
        for (uint i=0; i < arrayLength; i++) {
            contractCount += 1;
            contracts[contractCount] = Contract(
            contractCount, contractTitle, documentTitle,
            version, description, _participant[i], consent, false);
            emit ContractCreated(contractCount, _participant[i]);
        }
    }

// To sign contract id needs to be valid and contract should assigned to participant and should not be signed already
    function signContract( uint id) public {
        require(id > 0 && id <= contractCount);
        require(contracts[id].participant == msg.sender);
        require(!contracts[id].isSigned);
        contracts[id].isSigned = true;
        emit ContractSigned(id);
    }
}