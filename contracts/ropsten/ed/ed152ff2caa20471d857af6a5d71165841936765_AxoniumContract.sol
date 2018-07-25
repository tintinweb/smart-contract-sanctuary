pragma solidity ^0.4.23;

/**
 * @title AxoniumContract
*/
contract AxoniumContract {
    
    // Owner of the Axonium contract
    address public owner;

    // Patient Health Data Object
    struct PatientHealthData {
        string reference;
        string hashAddress;
        uint updateTime;
    }
    
    mapping(address => PatientHealthData) public healthDatas;
    
    event UpdatedPatientHealthData(address patient, uint updateTime);
    
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // Constructor
    // @notice Create AxoniumContract
    constructor() public {
        owner = msg.sender;
    }
    
    // @notice Add patient health data
    // @param _reference The reference number of patient
    // @param _hash The IPFS hash address of health data
    // @param _updateTime The update time in uint
    // @return the transaction address and send the event as UpdatedPatientHealthData
    function updatePatientHealthData(string _reference, string _hash, uint _updateTime) public {
        PatientHealthData storage patient = healthDatas[msg.sender];
        patient.reference = _reference;
        patient.hashAddress = _hash;
        patient.updateTime = _updateTime;
        
        emit UpdatedPatientHealthData(msg.sender, _updateTime);
    }
    
    // Get health data of patient by public address
    function getPatientHealthData(address _patient) view public returns (string, string, uint)  {
        return (healthDatas[_patient].reference, healthDatas[_patient].hashAddress, healthDatas[_patient].updateTime);
    }
}