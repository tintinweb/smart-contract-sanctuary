/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity ^0.8.9;

// ================================================================
//   Abstract Contract StorePatientsInterface
//// @title Abstract contract to implement functions used by the StorePatients contract
// ================================================================
abstract contract StorePatientsInterface {
    function addPatient(string memory _id, string memory _data) public virtual;
    function updatePatientDataByIndex(uint256 _index, string memory _data) public virtual;
    function updatePatientDataByID(string memory _id, string memory _data) public virtual;
    function getPatientByIndex(uint _index) public view virtual returns (string memory id, string memory data);
    function getPatientByID(string memory _id) public view virtual returns (string memory id, string memory data);
    function checkPatientByID(string memory _id) public view virtual returns (bool exists);
}

// ================================================================
//   Store Patients Contract
//// @title Main contract for storing patient data. Implements StorePatientsInterface
// ================================================================
contract StorePatients is StorePatientsInterface{
    
    // Keep track of the number of patients
    uint patientCount = 0;
    
    // Struct to store patient data
    struct Patient{
        string id;
        string data;
    }
    
    // Mapping to store the structs containing patient data
    mapping(uint => Patient) public patients;
    
    // ================================================================
    //   Add Patient
    //// @notice Add a patient to the patients mapping
    //// @param _id (int256) The ID of the patient to be added
    //// @param _data (string memory) The data to be stored in the struct
    // ================================================================
    function addPatient(string memory _id, string memory _data) public override{
        Patient memory newPatient = Patient(_id, _data);
        patients[patientCount] = newPatient;
        patientCount += 1;
    }
    
    // ================================================================
    //   Update Patient Data by Index
    //// @notice Update a patients data by Index
    //// @param _index (int256) The Index of the patient to be updated
    //// @param _data (string memory) The data to be stored in the struct
    // ================================================================
    function updatePatientDataByIndex(uint256 _index, string memory _data) public override {
        patients[_index].data = _data;
    }
    
    // ================================================================
    //   Update Patient Data by ID
    //// @notice Update a patients data by ID
    //// @param _id (int) The ID of the patient to be updated
    //// @param _data (string memory) The data to be stored in the struct
    // ================================================================
    function updatePatientDataByID(string memory _id, string memory _data) public override {
        for(uint i = 0; i < patientCount; i++) {
            if ((keccak256(abi.encodePacked(patients[i].id))) == (keccak256(abi.encodePacked(_id)))) {
                patients[i].data = _data;
            }
        }
    }
    
    // ================================================================
    //   Get Patient by Index
    //// @notice Get and return a patient by Index
    //// @param _index (uint) The index of the user to be returned
    //// @return (int) Returns the ID of the patient
    //// @return (string memory) Returns the data of the patient
    // ================================================================
    function getPatientByIndex(uint _index) public view override returns(string memory id, string memory data) {
        return (patients[_index].id, patients[_index].data);
    }
    
        // ================================================================
    //   Get Patient by ID
    //// @notice Get and return a patient by ID
    //// @param _id (int) The ID of the user to be returned
    //// @return (int) Returns the ID of the patient
    //// @return (string memory) Returns the data of the patient
    // ================================================================
    function getPatientByID(string memory _id) public view override returns (string memory id, string memory data) {
        for(uint i = 0; i < patientCount; i++) {
            if (((keccak256(abi.encodePacked(patients[i].id))) == (keccak256(abi.encodePacked(_id))))) {
                return (patients[i].id, patients[i].data);
            }
        }
    }

    function checkPatientByID(string memory _id) public view override returns (bool exists){
        for(uint i = 0; i < patientCount; i++) {
            if (((keccak256(abi.encodePacked(patients[i].id))) == (keccak256(abi.encodePacked(_id))))) {
                return true;
            }
        }
        return false;
    }
}