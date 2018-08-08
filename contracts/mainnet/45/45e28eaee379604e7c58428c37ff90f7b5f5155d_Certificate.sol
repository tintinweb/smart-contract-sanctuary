/**
 * @title Certificate Library
 *  ░V░e░r░i░f░i░e░d░ ░O░n░ ░C░h░a░i░n░
 * Visit https://verifiedonchain.com/
 */

pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

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

contract Certificate is Ownable {
    
    using CertificateLibrary for CertificateLibrary.Document;
    
    struct Certification {
        mapping (uint => CertificateLibrary.Document) documents;
        uint16 indx;
    }
    
    mapping (address => Certification) studentCertifications;
    
    event CertificationAdded(address userAddress, uint docIndx);
    
    /**
     * @notice Add Certification to a student
     * @param _student - Address of student
     * @param _contentHash - Hash of the document
     * @param _ipfsHash - IPFS Hash of the document
     * @param _transcriptHash - Transcript Hash of the document
     **/
    function addCertification(address _student, bytes32 _contentHash, bytes _ipfsHash, bytes32 _transcriptHash) public onlyOwner {
        uint currIndx = studentCertifications[_student].indx;
        (studentCertifications[_student].documents[currIndx]).addCertification(_contentHash, _ipfsHash, _transcriptHash);
        studentCertifications[_student].indx++;
        emit CertificationAdded(_student, currIndx);
    }
    
    /**
     * @notice Validate Certification to a student
     * @param _student - Address of student
     * @param _docIndx - Index of the document to be validated
     * @param _contentHash - Content Hash of the document
     * @param _ipfsHash - IPFS Hash of the document
     * @param _transcriptHash - Transcript Hash of the GradeSheet
     * @return Returns true if validation is successful
     **/
    function validate(address _student, uint _docIndx, bytes32 _contentHash, bytes _ipfsHash, bytes32 _transcriptHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validate(_ipfsHash, _contentHash, _transcriptHash);
    }
    
    /**
     * @notice Validate IPFS Hash alone of a student
     * @param _student - Address of student
     * @param _docIndx - Index of the document to be validated
     * @param _ipfsHash - IPFS Hash of the document
     * @return Returns true if validation is successful
     **/
    function validateIpfsDoc(address _student, uint _docIndx, bytes _ipfsHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validateIpfsDoc(_ipfsHash);
    }
    
    /**
     * @notice Validate Content Hash alone of a student
     * @param _student - Address of student
     * @param _docIndx - Index of the document to be validated
     * @param _contentHash - Content Hash of the document
     * @return Returns true if validation is successful
     **/
    function validateContentHash(address _student, uint _docIndx, bytes32 _contentHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validateContentHash(_contentHash);
    }
    
    /**
     * @notice Validate Transcript Hash alone of a student
     * @param _student - Address of student
     * @param _transcriptHash - Transcript Hash of the GradeSheet
     * @return Returns true if validation is successful
     **/
    function validateTranscriptHash(address _student, uint _docIndx, bytes32 _transcriptHash) public view returns(bool) {
        Certification storage certification  = studentCertifications[_student];
        return (certification.documents[_docIndx]).validateTranscriptHash(_transcriptHash);
    }
    
    /**
     * @notice Get Certification Document Count
     * @param _student - Address of student
     * @return Returns the total number of certifications for a student
     **/
    function getCertifiedDocCount(address _student) public view returns(uint256) {
        return studentCertifications[_student].indx;
    }
    
    /**
     * @notice Get Certification Document from DocType
     * @param _student - Address of student
     * @param _docIndx - Index of the document to be validated
     * @return Returns IPFSHash, ContentHash, TranscriptHash of the document
     **/
    function getCertificationDocument(address _student, uint _docIndx) public view onlyOwner returns (bytes, bytes32, bytes32) {
        return ((studentCertifications[_student].documents[_docIndx]).ipfsHash, (studentCertifications[_student].documents[_docIndx]).contentHash, (studentCertifications[_student].documents[_docIndx]).transcriptHash);
    }
    
    /**
     * @param _studentAddrOld - Address of student old
     * @param _studentAddrNew - Address of student new
     * May fail due to gas exceptions
     * ADVICE:
     * Check gas and then send
     **/
    function transferAll(address _studentAddrOld, address _studentAddrNew) public onlyOwner {
        studentCertifications[_studentAddrNew] = studentCertifications[_studentAddrOld];
        delete studentCertifications[_studentAddrOld];
    }
    
    /**
     * @param _studentAddrOld - Address of student old
     * @param _studentAddrNew - Address of student new
     **/
    function transferDoc(uint docIndx, address _studentAddrOld, address _studentAddrNew) public onlyOwner {
        studentCertifications[_studentAddrNew].documents[docIndx] = studentCertifications[_studentAddrOld].documents[docIndx];
        delete studentCertifications[_studentAddrOld].documents[docIndx];
    }
}