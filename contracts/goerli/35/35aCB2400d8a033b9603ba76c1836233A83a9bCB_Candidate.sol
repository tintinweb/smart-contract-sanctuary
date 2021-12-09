/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.8;

contract Candidate {
    mapping(address => uint) private addressToIndex;
    mapping(address => bytes) private addressToJson;
    mapping(address => bytes) private addressToHash;

    address[] private addresses;
    address private adminAddress;

    constructor() {
        adminAddress = msg.sender;
        addresses.push(msg.sender);
    }
    
    function isAdmin() private view returns(bool senderIsAdmin) {
        return msg.sender == adminAddress;
    }

    function isCandidate(address userAddress) private view returns (bool senderIsCandidate) {
        return msg.sender == userAddress;
    }

    function isAdminOrCandidate(address userAddress) private view returns (bool senderIsAdminOrCandidate) {
        return isAdmin() || isCandidate(userAddress);
    }

    function hasCandidate(address userAddress) public view returns(bool hasIndeed) {
        return (addressToIndex[userAddress] > 0 || userAddress == addresses[0]);
    }

    function reassignAdmin(address newAdminAddress) public returns(bool reassignAdminSuccessful) {
        adminAddress = newAdminAddress;
        return true;
    }

    function getAdmin() public view returns(address fetchedAdminAddress) {
        return adminAddress;
    }

    function createCandidate(address newUserAddress) public returns(bool createCandidateSucceeded) {
        require(isAdmin());
        require(!hasCandidate(newUserAddress));
        addresses.push(newUserAddress);
        addressToIndex[newUserAddress] = addresses.length - 1;
        
        return true;
    }

    function updateCandidate(address userAddress, bytes memory encryptedJson, bytes memory hashOfJson) public returns (bool userUpdated) {
        require(hasCandidate(userAddress));
        require(isAdminOrCandidate(userAddress));
        
        addressToJson[userAddress] = encryptedJson;
        addressToHash[userAddress] = hashOfJson;

        return true;
    }

    function getCandidate(address userAddress) public view returns (bytes memory userEncryptedJson, bytes memory userHashOfJson) {
        require(hasCandidate(userAddress));

        return (
            addressToJson[userAddress],
            addressToHash[userAddress]
        );
    }
}