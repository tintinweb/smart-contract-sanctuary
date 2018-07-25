/**
 * @title Certificate Library
 *  ░V░e░r░i░f░i░e░d░ ░O░n░ ░C░h░a░i░n░
 * Visit https://verifiedonchain.com/
 */
pragma solidity 0.4.24;

library CertificateLibrary {
    struct Document {
        bytes ipfsHash;
        bytes32 transcriptHash;
        bytes32 contentHash;
    }
    
    /**
     * @notice Add Certification to a student
     * @param _contentHash - Hash of the document
     * @param _ipfsHash - IPFS Hash of the document
     * @param _transcriptHash - Transcript Hash of the document
     **/
    function addCertification(Document storage self, bytes32 _contentHash, bytes _ipfsHash, bytes32 _transcriptHash) public {
        self.ipfsHash = _ipfsHash;
        self.contentHash= _contentHash;
        self.transcriptHash = _transcriptHash;
    }
    
    /**
     * @notice Validate Certification to a student
     * @param _ipfsHash - IPFS Hash of the document
     * @param _contentHash - Content Hash of the document
     * @param _transcriptHash - Transcript Hash of the document
     * @return Returns true if validation is successful
     **/
    function validate(Document storage self, bytes _ipfsHash, bytes32 _contentHash, bytes32 _transcriptHash) public view returns(bool) {
        bytes storage ipfsHash = self.ipfsHash;
        bytes32 contentHash = self.contentHash;
        bytes32 transcriptHash = self.transcriptHash;
        return contentHash == _contentHash && keccak256(ipfsHash) == keccak256(_ipfsHash) && transcriptHash == _transcriptHash;
    }
    
    /**
     * @notice Validate IPFS Hash alone of a student
     * @param _ipfsHash - IPFS Hash of the document
     * @return Returns true if validation is successful
     **/
    function validateIpfsDoc(Document storage self, bytes _ipfsHash) public view returns(bool) {
        bytes storage ipfsHash = self.ipfsHash;
        return keccak256(ipfsHash) == keccak256(_ipfsHash);
    }
    
    /**
     * @notice Validate Content Hash alone of a student
     * @param _contentHash - Content Hash of the document
     * @return Returns true if validation is successful
     **/
    function validateContentHash(Document storage self, bytes32 _contentHash) public view returns(bool) {
        bytes32 contentHash = self.contentHash;
        return contentHash == _contentHash;
    }
    
    /**
     * @notice Validate Content Hash alone of a student
     * @param _transcriptHash - Transcript Hash of the document
     * @return Returns true if validation is successful
     **/
    function validateTranscriptHash(Document storage self, bytes32 _transcriptHash) public view returns(bool) {
        bytes32 transcriptHash = self.transcriptHash;
        return transcriptHash == _transcriptHash;
    }
}