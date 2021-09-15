/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/iCosysCertification.sol

pragma solidity ^0.8.3;


abstract contract iCosysCertificationInterface {
    event LogCertifierChanged(
        address indexed previousCertifier,
        address indexed newCertifier);

    event LogStudentCertified(
        address indexed student, uint timestamp,
        address indexed certifier, string documentHash, string ipfsHash, address certificateId);

    event LogStudentUncertified(
        address indexed certificateAddress, uint timestamp,
        address indexed certifier);

    function getCertifier()
        view public virtual
        returns (address);

    function setCertifier(address newCertifier)
    
        public virtual returns (bool success);

    function certify(address student, string memory documentHash, string memory ipfsHash, address certAddress)
      public  virtual returns (bool status);

    function unCertify(address student)
        public virtual returns (bool success);

    function getCertifiedStudentsCount()
      public virtual view
        returns (uint count);

    function getCertifiedStudentAtIndex(uint index)
        public virtual view
        returns (address student);

    function getCertification(address certificateAddress)
       public virtual view
        returns (bool certified, uint timestamp, address certifier, string memory documentHash, string memory ipfsHash, address studentAddress);

    function isCertified(address certificateAddress)
       public virtual view
        returns (bool isIndeed);

}

contract iCosysCertification is iCosysCertificationInterface, Ownable{

    address private certifier;

    struct Certification {
        bool certified;
        uint256 timestamp;
        address certifier;
        string documentHash;
        string ipfsHash;
        uint256 index;
        address studentAddress;
    }

    mapping(address => Certification) studentCertifications;

    address[] certifiedStudents;

    constructor () payable {
        if (msg.value > 0) {
            revert();
        }
        
        certifier = msg.sender;
    }

    modifier fromCertifier() {
        require(msg.sender == certifier);
        _;
    }

    function getCertifier()
        view public override
        returns (address) {
        return certifier;
    }

    function setCertifier(address newCertifier)
        onlyOwner public override
        returns (bool success) {
        if (newCertifier == address(0)) {
            revert();
        }
        if (certifier != newCertifier) {
            emit LogCertifierChanged(certifier, newCertifier);
            certifier = newCertifier;
        }
        success = true;
    }

    function certify(address student, string memory documentHash, string memory ipfsHash, address certAddress)
        fromCertifier public override
        returns (bool status)
        {
        if (student ==  address(0) || certAddress ==  address(0)) {
            revert();
        }
        uint256 studLen = certifiedStudents.length;
        address certificateId = certAddress;
        studentCertifications[certificateId] = Certification({
            certified: true,
            timestamp: block.timestamp,
            certifier: msg.sender,
            documentHash: documentHash,
            ipfsHash: ipfsHash,
            index: studLen,
            studentAddress: student
        });

        certifiedStudents.push(student);
        emit LogStudentCertified(student, block.timestamp, msg.sender, documentHash, ipfsHash, certificateId);
        status = true;
    }

    

    function unCertify(address certificateAddress)
        fromCertifier public override
        returns (bool success) {
        if (!studentCertifications[certificateAddress].certified) {
            revert();
        }
        studentCertifications[certificateAddress].certified = false;
        emit LogStudentUncertified(certificateAddress, block.timestamp, msg.sender);
        success = true;
    }

    function getCertifiedStudentsCount()
        view public override
        returns (uint256 count) {
        count = certifiedStudents.length;
    }

    function getCertifiedStudentAtIndex(uint256 index)
        view public override
        returns (address student) {
        student = certifiedStudents[index];
    }

    function getCertification(address  certificateAddress)
        view public override
        returns (bool certified, uint256 timestamp, address certifierAdd, string memory documentHash, string memory ipfsHash, address studentAddress) {
        Certification memory certification = studentCertifications[certificateAddress];
        
        return (certification.certified,
            certification.timestamp,
            certification.certifier,
            certification.documentHash,
            certification.ipfsHash,
            certification.studentAddress);
    }

      function getCertificateHash(address  certificateAddress)
        view public
        returns (string memory documentHash) {
        Certification memory certification = studentCertifications[certificateAddress];
        
        return certification.documentHash;
    
    }
    
      function getIpfsHash(address  certificateAddress)
        view public
        returns (string memory ipfsHash) {
        Certification memory certification = studentCertifications[certificateAddress];
        
        return certification.ipfsHash;
    
    }

    function isCertified(address certificateAddress)
        view public override
        returns (bool isCertify) {
        isCertify = studentCertifications[certificateAddress].certified;
    }
}