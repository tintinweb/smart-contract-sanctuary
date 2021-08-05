/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrescriptionContract {
    address public doctorAddress;

    address public patientAddress;

    struct Prescription {
        string Diagnosis;
        string Medication;
        string Dosage;
    }

    constructor(address _doctorAddress, address _patientAddress) {
        doctorAddress = _doctorAddress;
        patientAddress = _patientAddress;
    }

    event NewPrescription(address doctor, address patient, Prescription prescription);

    /// Your address is not the doctor's address
    error NotAuthorized();

    modifier isTheDoctor(address incomingAddress) {
        if (incomingAddress != doctorAddress) revert NotAuthorized();
        _;
    }

    function createPrescription(Prescription calldata prescription) public isTheDoctor(msg.sender) {
        emit NewPrescription(doctorAddress, patientAddress, prescription);
    }
}