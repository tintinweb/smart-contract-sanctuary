/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

pragma solidity >= 0.8.5;


/**
 * Contract for handing in my Master's Thesis in Informatics 
 * Allows to transparently verify the original file of the 
 * thesis that was submitted
**/ 
contract MastersThesisHash {
    
    address owner;  // The owner of the contract: The person that verifies his or her Thesis this way
    uint256 thesisHash; // The hash of the thesis
    bool submitted = false;
    event ThesisSubmitted(uint256 _hashReceived);   // This event will be sent out once the hash was received and the thesis was submitted
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * Writes the hash to the contract and finishes the submission
     * @param _hash: The hash of the final file of the ThesisSubmitted
    **/ 
    function submitThesis(uint256 _hash) external {
        require(!submitted, "The thesis was already submitted!");
        require(msg.sender == owner, "You are not the owner");
        thesisHash = _hash;
        emit ThesisSubmitted(_hash);
        submitted = true;
    }
    
    /**
     * Retrieve the hash of the thesisHash
    **/ 
    function getThesisHash() public view returns (uint256) {
        return thesisHash;
    }
}