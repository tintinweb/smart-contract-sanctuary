pragma solidity 0.4.25;

/**
 * @notice Declares a contract that can have an owner.
 */
contract OwnedI {
    event LogOwnerChanged(address indexed previousOwner, address indexed newOwner);

    function getOwner()
        view public
        returns (address);

    function setOwner(address newOwner)
        public
        returns (bool success); 
}

/**
 * @notice Defines a contract that can have an owner.
 */
contract Owned is OwnedI {
    /**
     * @dev Made private to protect against child contract setting it to 0 by mistake.
     */
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier fromOwner {
        require(msg.sender == owner);
        _;
    }

    function getOwner()
        view public
        returns (address) {
        return owner;
    }

    function setOwner(address newOwner)
        fromOwner public
        returns (bool success) {
        require(newOwner != 0);
        if (owner != newOwner) {
            emit LogOwnerChanged(owner, newOwner);
            owner = newOwner;
        }
        success = true;
    }
}

contract WithBeneficiary is Owned {
    /**
     * @notice Address that is forwarded all value.
     * @dev Made private to protect against child contract setting it to 0 by mistake.
     */
    address private beneficiary;
    
    event LogBeneficiarySet(address indexed previousBeneficiary, address indexed newBeneficiary);

    constructor(address _beneficiary) payable public {
        require(_beneficiary != 0);
        beneficiary = _beneficiary;
        if (msg.value > 0) {
            asyncSend(beneficiary, msg.value);
        }
    }

    function asyncSend(address dest, uint amount) internal;

    function getBeneficiary()
        view public
        returns (address) {
        return beneficiary;
    }

    function setBeneficiary(address newBeneficiary)
        fromOwner public
        returns (bool success) {
        require(newBeneficiary != 0);
        if (beneficiary != newBeneficiary) {
            emit LogBeneficiarySet(beneficiary, newBeneficiary);
            beneficiary = newBeneficiary;
        }
        success = true;
    }

    function () payable public {
        asyncSend(beneficiary, msg.value);
    }
}

contract WithFee is WithBeneficiary {
    // @notice Contracts asking for a confirmation of a certification need to pass this fee.
    uint256 private queryFee;

    event LogQueryFeeSet(uint256 previousQueryFee, uint256 newQueryFee);

    constructor(
            address beneficiary,
            uint256 _queryFee) public
        WithBeneficiary(beneficiary) {
        queryFee = _queryFee;
    }

    modifier requestFeePaid {
        require(queryFee <= msg.value);
        asyncSend(getBeneficiary(), msg.value);
        _;
    }

    function getQueryFee()
        view public
        returns (uint256) {
        return queryFee;
    }

    function setQueryFee(uint256 newQueryFee)
        fromOwner public
        returns (bool success) {
        if (queryFee != newQueryFee) {
            emit LogQueryFeeSet(queryFee, newQueryFee);
            queryFee = newQueryFee;
        }
        success = true;
    }
}

/*
 * @notice Base contract supporting async send for pull payments.
 * Inherit from this contract and use asyncSend instead of send.
 * https://github.com/OpenZeppelin/zep-solidity/blob/master/contracts/PullPaymentCapable.sol
 */
contract PullPaymentCapable {
    uint256 private totalBalance;
    mapping(address => uint256) private payments;

    event LogPaymentReceived(address indexed dest, uint256 amount);

    constructor() public {
        if (0 < address(this).balance) {
            asyncSend(msg.sender, address(this).balance);
        }
    }

    // store sent amount as credit to be pulled, called by payer
    function asyncSend(address dest, uint256 amount) internal {
        if (amount > 0) {
            totalBalance += amount;
            payments[dest] += amount;
            emit LogPaymentReceived(dest, amount);
        }
    }

    function getTotalBalance()
        view public
        returns (uint256) {
        return totalBalance;
    }

    function getPaymentOf(address beneficiary) 
        view public
        returns (uint256) {
        return payments[beneficiary];
    }

    // withdraw accumulated balance, called by payee
    function withdrawPayments()
        external 
        returns (bool success) {
        uint256 payment = payments[msg.sender];
        payments[msg.sender] = 0;
        totalBalance -= payment;
        require(msg.sender.call.value(payment)());
        success = true;
    }

    function fixBalance()
        public
        returns (bool success);

    function fixBalanceInternal(address dest)
        internal
        returns (bool success) {
        if (totalBalance < address(this).balance) {
            uint256 amount = address(this).balance - totalBalance;
            payments[dest] += amount;
            emit LogPaymentReceived(dest, amount);
        }
        return true;
    }
}

// @notice Interface for a certifier database
contract CertifierDbI {
    event LogCertifierAdded(address indexed certifier);

    event LogCertifierRemoved(address indexed certifier);

    function addCertifier(address certifier)
        public
        returns (bool success);

    function removeCertifier(address certifier)
        public
        returns (bool success);

    function getCertifiersCount()
        view public
        returns (uint count);

    function getCertifierStatus(address certifierAddr)
        view public 
        returns (bool authorised, uint256 index);

    function getCertifierAtIndex(uint256 index)
        view public
        returns (address);

    function isCertifier(address certifier)
        view public
        returns (bool isIndeed);
}

contract CertificationDbI {
    event LogCertifierDbChanged(
        address indexed previousCertifierDb,
        address indexed newCertifierDb);

    event LogStudentCertified(
        address indexed student, uint timestamp,
        address indexed certifier, bytes32 indexed document);

    event LogStudentUncertified(
        address indexed student, uint timestamp,
        address indexed certifier);

    event LogCertificationDocumentAdded(
        address indexed student, bytes32 indexed document);

    event LogCertificationDocumentRemoved(
        address indexed student, bytes32 indexed document);

    function getCertifierDb()
        view public
        returns (address);

    function setCertifierDb(address newCertifierDb)
        public
        returns (bool success);

    function certify(address student, bytes32 document)
        public
        returns (bool success);

    function uncertify(address student)
        public
        returns (bool success);

    function addCertificationDocument(address student, bytes32 document)
        public
        returns (bool success);

    function addCertificationDocumentToSelf(bytes32 document)
        public
        returns (bool success);

    function removeCertificationDocument(address student, bytes32 document)
        public
        returns (bool success);

    function removeCertificationDocumentFromSelf(bytes32 document)
        public
        returns (bool success);

    function getCertifiedStudentsCount()
        view public
        returns (uint count);

    function getCertifiedStudentAtIndex(uint index)
        payable public
        returns (address student);

    function getCertification(address student)
        payable public
        returns (bool certified, uint timestamp, address certifier, uint documentCount);

    function isCertified(address student)
        payable public
        returns (bool isIndeed);

    function getCertificationDocumentAtIndex(address student, uint256 index)
        payable public
        returns (bytes32 document);

    function isCertification(address student, bytes32 document)
        payable public
        returns (bool isIndeed);
}

contract CertificationDb is CertificationDbI, WithFee, PullPaymentCapable {
    // @notice Where we check for certifiers.
    CertifierDbI private certifierDb;

    struct DocumentStatus {
        bool isValid;
        uint256 index;
    }

    struct Certification {
        bool certified;
        uint256 timestamp;
        address certifier;
        mapping(bytes32 => DocumentStatus) documentStatuses;
        bytes32[] documents;
        uint256 index;
    }

    // @notice Address of certified students.
    mapping(address => Certification) studentCertifications;
    // @notice The potentially long list of all certified students.
    address[] certifiedStudents;

    constructor(
            address beneficiary,
            uint256 certificationQueryFee,
            address _certifierDb)
            public
            WithFee(beneficiary, certificationQueryFee) {
        require(_certifierDb != 0);
        certifierDb = CertifierDbI(_certifierDb);
    }

    modifier fromCertifier {
        require(certifierDb.isCertifier(msg.sender));
        _;
    }

    function getCertifierDb()
        view public
        returns (address) {
        return certifierDb;
    }

    function setCertifierDb(address newCertifierDb)
        fromOwner public
        returns (bool success) {
        require(newCertifierDb != 0);
        if (certifierDb != newCertifierDb) {
            emit LogCertifierDbChanged(certifierDb, newCertifierDb);
            certifierDb = CertifierDbI(newCertifierDb);
        }
        success = true;
    }

    function certify(address student, bytes32 document) 
        fromCertifier public
        returns (bool success) {
        require(student != 0);
        require(!studentCertifications[student].certified);
        bool documentExists = document != 0;
        studentCertifications[student] = Certification({
            certified: true,
            timestamp: now,
            certifier: msg.sender,
            documents: new bytes32[](0),
            index: certifiedStudents.length
        });
        if (documentExists) {
            studentCertifications[student].documentStatuses[document] = DocumentStatus({
                isValid: true,
                index: studentCertifications[student].documents.length
            });
            studentCertifications[student].documents.push(document);
        }
        certifiedStudents.push(student);
        emit LogStudentCertified(student, now, msg.sender, document);
        success = true;
    }

    function uncertify(address student) 
        fromCertifier public
        returns (bool success) {
        require(studentCertifications[student].certified);
        // You need to uncertify all documents first
        require(studentCertifications[student].documents.length == 0);
        uint256 index = studentCertifications[student].index;
        delete studentCertifications[student];
        if (certifiedStudents.length > 1) {
            certifiedStudents[index] = certifiedStudents[certifiedStudents.length - 1];
            studentCertifications[certifiedStudents[index]].index = index;
        }
        certifiedStudents.length--;
        emit LogStudentUncertified(student, now, msg.sender);
        success = true;
    }

    function addCertificationDocument(address student, bytes32 document)
        fromCertifier public
        returns (bool success) {
        success = addCertificationDocumentInternal(student, document);
    }

    function addCertificationDocumentToSelf(bytes32 document)
        public
        returns (bool success) {
        success = addCertificationDocumentInternal(msg.sender, document);
    }

    function addCertificationDocumentInternal(address student, bytes32 document)
        internal
        returns (bool success) {
        require(studentCertifications[student].certified);
        require(document != 0);
        Certification storage certification = studentCertifications[student];
        if (!certification.documentStatuses[document].isValid) {
            certification.documentStatuses[document] = DocumentStatus({
                isValid:  true,
                index: certification.documents.length
            });
            certification.documents.push(document);
            emit LogCertificationDocumentAdded(student, document);
        }
        success = true;
    }

    function removeCertificationDocument(address student, bytes32 document)
        fromCertifier public
        returns (bool success) {
        success = removeCertificationDocumentInternal(student, document);
    }

    function removeCertificationDocumentFromSelf(bytes32 document)
        public
        returns (bool success) {
        success = removeCertificationDocumentInternal(msg.sender, document);
    }

    function removeCertificationDocumentInternal(address student, bytes32 document)
        internal
        returns (bool success) {
        require(studentCertifications[student].certified);
        Certification storage certification = studentCertifications[student];
        if (certification.documentStatuses[document].isValid) {
            uint256 index = certification.documentStatuses[document].index;
            delete certification.documentStatuses[document];
            if (certification.documents.length > 1) {
                certification.documents[index] =
                    certification.documents[certification.documents.length - 1];
                certification.documentStatuses[certification.documents[index]].index = index;
            }
            certification.documents.length--;
            emit LogCertificationDocumentRemoved(student, document);
        }
        success = true;
    }

    function getCertifiedStudentsCount()
        view public
        returns (uint256 count) {
        count = certifiedStudents.length;
    }

    function getCertifiedStudentAtIndex(uint256 index)
        payable public
        requestFeePaid
        returns (address student) {
        student = certifiedStudents[index];
    }

    /**
     * @notice Requesting a certification is a paying feature.
     */
    function getCertification(address student)
        payable public
        requestFeePaid
        returns (bool certified, uint256 timestamp, address certifier, uint256 documentCount) {
        Certification storage certification = studentCertifications[student];
        return (certification.certified,
            certification.timestamp,
            certification.certifier,
            certification.documents.length);
    }

    /**
     * @notice Requesting a certification confirmation is a paying feature.
     */
    function isCertified(address student)
        payable public
        requestFeePaid
        returns (bool isIndeed) {
        isIndeed = studentCertifications[student].certified;
    }

    /**
     * @notice Requesting a certification document by index is a paying feature.
     */
    function getCertificationDocumentAtIndex(address student, uint256 index)
        payable public
        requestFeePaid
        returns (bytes32 document) {
        document = studentCertifications[student].documents[index];
    }

    /**
     * @notice Requesting a confirmation that a document is a certification is a paying feature.
     */
    function isCertification(address student, bytes32 document)
        payable public
        requestFeePaid
        returns (bool isIndeed) {
        isIndeed = studentCertifications[student].documentStatuses[document].isValid;
    }

    function fixBalance()
        public
        returns (bool success) {
        return fixBalanceInternal(getBeneficiary());
    }
}