/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract doctorVerification {

    address private patient;
    mapping(uint256 => bool) private doctor;
    
    event PatientSet(address indexed oldPatient, address indexed newPatient);
    
    modifier isPatient() {
        require(msg.sender == patient, "Caller is not patient");
        _;
    }
    
    constructor() {
        patient = msg.sender;
        emit PatientSet(address(0), patient);
    }
    
    function setDoctor(uint256 id, bool include) public payable {
        require(msg.sender == patient);
        doctor[id] = include;
    }
    
    function queryDoctor(uint256 id) public view returns (bool) {
        return doctor[id];
    }

    function changePatient(address newPatient) public isPatient {
        emit PatientSet(patient, newPatient);
        patient = newPatient;
    }

    function getPatient() external view returns (address) {
        return patient;
    }
}