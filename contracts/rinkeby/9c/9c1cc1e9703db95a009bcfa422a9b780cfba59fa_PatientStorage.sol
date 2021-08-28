/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.8.0;

contract PatientStorage {

    event AddPatientToRepositoryEvent(string contentID);
    
    mapping(address => string) public ownerToPatientCID;

    function addPatientToRepository(string memory _hash) public returns (string memory) {
        ownerToPatientCID[msg.sender] = _hash;
        emit AddPatientToRepositoryEvent(_hash);
        return _hash;
    }

    function retrievePatientFromRepository() public view returns (string memory) {
        return ownerToPatientCID[msg.sender];
    }
}