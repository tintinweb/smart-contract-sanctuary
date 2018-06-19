pragma solidity ^0.4.23;

// File: contracts/LegalDocument.sol

/**
 * @title LegalDocument
 * @dev Basic version of a legal contract, allowing the owner to save a legal document and associate the governing law
 * contact information.
 */
contract LegalDocument {

    string public documentIPFSHash;
    string public governingLaw;

    /**
      * @dev Constructs a document
      * @param ipfsHash The IPFS hash to the human readable legal contract.
      * @param law The governing law
      */
    constructor(string ipfsHash, string law) public {
        documentIPFSHash = ipfsHash;
        governingLaw = law;
    }

}