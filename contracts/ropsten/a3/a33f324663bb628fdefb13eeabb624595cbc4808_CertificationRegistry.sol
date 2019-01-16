pragma solidity ^0.4.24;

// File: contracts/IndividualCertification.sol

/**
  * @title   Individual Certification Contract
  * @author  Rosen GmbH
  *
  * This contract represents the individual certificate.
  */
contract IndividualCertification {
    event HashValueUpdated(bytes32 newB0, bytes32 newB1);
    address public registryAddress;
    bytes32 b0;
    bytes32 b1;

    constructor(bytes32 _b0, bytes32 _b1)
    public
    {
        registryAddress = msg.sender;
        b0 = _b0;
        b1 = _b1;
    }
    function updateHashValue(bytes32 _b0, bytes32 _b1)
    public
    {
        require(msg.sender == registryAddress);
        b0 = _b0;
        b1 = _b1;
        emit HashValueUpdated(_b0, _b1);
    }

    function hashValue()
    public
    view
    returns (bytes32, bytes32)
    {
        return (b0, b1);
    }

    /**
  * Extinguish this certificate.
  *
  * This can be done by the same certifier contract which has created
  * the certificate in the first place only.
  */
    function deleteCertificate() public {
        require(msg.sender == registryAddress);
        selfdestruct(tx.origin);
    }
}

// File: contracts/OrganizationalCertification.sol

/**
  * @title   Certificate Contract
  * @author  Chainstep GmbH
  *
  * Each instance of this contract represents a single certificate.
  */
contract OrganizationalCertification  {

    /**
      * Address of certifier contract this certificate belongs to.
      */
    address public registryAddress;

    string public CompanyName;
    string public Norm;
    string public CertID;
    uint public issued;
    uint public expires;
    string public Scope;
    string public issuingBody;

    /**
      * Constructor.
      *
      * @param _CompanyName Name of company name the certificate is issued to.
      * @param _Norm The norm.
      * @param _CertID Unique identifier of the certificate.
      * @param _issued Timestamp (Unix epoch) when the certificate was issued.
      * @param _expires Timestamp (Unix epoch) when the certificate will expire.
      * @param _Scope The scope of the certificate.
      * @param _issuingBody The issuer of the certificate.
      */
    constructor(
        string _CompanyName,
        string _Norm,
        string _CertID,
        uint _issued,
        uint _expires,
        string _Scope,
        string _issuingBody)
        public
    {
        require(_issued < _expires);

        registryAddress = msg.sender;

        CompanyName = _CompanyName;
        Norm =_Norm;
        CertID = _CertID;
        issued = _issued;
        expires = _expires;
        Scope = _Scope;
        issuingBody = _issuingBody;
    }

    /**
      * Extinguish this certificate.
      *
      * This can be done the same certifier contract which has created
      * the certificate in the first place only.
      */
    function deleteCertificate() public {
        require(msg.sender == registryAddress);
        selfdestruct(tx.origin);
    }

}

// File: contracts/CertificationRegistry.sol

/**
  * @title   Certification Contract
  * @author  Chainstep GmbH
  * @author  Rosen GmbH
  * This contract represents the singleton certificate registry.
  */

contract CertificationRegistry {

    /** @dev Dictionary of all Certificate Contracts issued by the Organization.
             Stores the Organization ID and which Certificates they issued.
             Stores the Certification key derived from the sha(CertID) and stores the
             address where the corresponding Certificate is stored.
             Mapping(organizationID => mapping (certId => certAddress))
             */
    mapping (bytes32 => mapping (bytes32 => address)) public CertificateAddresses;
    mapping (bytes32 => address) public RosenCertificateAddresses;
    //mapping (bytes32 => Certificate) public CertificateAddresses;

    /** @dev Dictionary that stores which addresses are owntrated by Certification administrators and
             which Organization those Certification adminisors belong to
             Mapping(organizationID => mapping(adminAddress => bool))
     */
    mapping (bytes32 => mapping (address => bool)) public CertAdmins;

    /** @dev Dictionary that stores which addresses are owned by ROSEN Certification administrators
             Mapping(adminAddress => bool)
    */
    mapping (address => bool) public RosenCertAdmins;

    /** @dev stores the address of the Global Administrator*/
    address public GlobalAdmin;

    event CertificationSet(string _certID, address _certAdrress);
    event IndividualCertificationSet(string _certID, address _certAdrress);
    event CertificationDeleted(string _certID, address _certAdrress);
    event CertAdminAdded(address _certAdmin);
    event CertAdminDeleted(address _certAdmin);
    event GlobalAdminChanged(address _globalAdmin);

    /**
      * Constructor.
      *
      * The creator of this contract becomes the global administrator.
      */
    constructor() public {
        GlobalAdmin = msg.sender;
    }

    // Functions

    /**
      * Create a new certificate contract.
      * This can be done by an certificate administrator only.
      *
      * @param _CompanyName Name of company name the certificate is issued to.
      * @param _Norm The norm.
      * @param _CertID Unique identifier of the certificate.
      * @param _issued Timestamp (Unix epoch) when the certificate was issued.
      * @param _expires Timestamp (Unix epoch) when the certificate will expire.
      * @param _Scope The scope of the certificate.
      * @param _issuingBody The issuer of the certificate.
      */
    function setCertificate(
        string _CompanyName,
        string _Norm,
        string _CertID,
        uint _issued,
        uint _expires,
        string _Scope,
        string _issuingBody
    )
    public
    onlyRosenCertAdmin
    {
        bytes32 certKey = getCertKey(_CertID);

        OrganizationalCertification orgCert = new OrganizationalCertification(
            _CompanyName,
            _Norm,
            _CertID,
            _issued,
            _expires,
            _Scope,
            _issuingBody);

        RosenCertificateAddresses[certKey] = address(orgCert);
        emit CertificationSet(_CertID, address(orgCert));
    }

    function setIndividualCertificate(string _CertID, bytes32 b0, bytes32 b1, bytes32 _organizationID)
    public
    onlyPrivilegedCertAdmin(_organizationID)
    {
        bytes32 certKey = getCertKey(_CertID);
        IndividualCertification individualCert = new IndividualCertification(b0, b1);
        CertificateAddresses[_organizationID][certKey] = address(individualCert);
        emit IndividualCertificationSet(_CertID, address(individualCert));
    }

    function updateIndividualCertificate(string _CertID, bytes32 b0, bytes32 b1, bytes32 _organizationID)
    public
    onlyPrivilegedCertAdmin(_organizationID)
    {
        bytes32 certKey = getCertKey(_CertID);
        IndividualCertification(CertificateAddresses[_organizationID][certKey]).updateHashValue(b0, b1);
        emit IndividualCertificationSet(_CertID, CertificateAddresses[_organizationID][certKey]);
    }

    /**
      * Delete an existing certificate.
      *
      * This can be done by an certificate administrator only.
      *
      * @param _CertID Unique identifier of the certificate to delete.
      */
    function delOrganizationCertificate(string _CertID) public onlyRosenCertAdmin {
        bytes32 certKey = getCertKey(_CertID);

        OrganizationalCertification(RosenCertificateAddresses[certKey]).deleteCertificate();

        emit CertificationDeleted(_CertID, RosenCertificateAddresses[certKey]);
        delete RosenCertificateAddresses[certKey];
    }
    /**
      * Delete an exisiting certificate.
      *
      * This can be done by an certificate administrator only.
      *
      * @param _CertID Unique identifier of the certificate to delete.
      */
    function delIndividualCertificate(string _CertID, bytes32 _organizationID) public onlyPrivilegedCertAdmin(_organizationID) {
        bytes32 certKey = getCertKey(_CertID);

        IndividualCertification(CertificateAddresses[_organizationID][certKey]).deleteCertificate();

        emit CertificationDeleted(_CertID, CertificateAddresses[_organizationID][certKey]);
        delete CertificateAddresses[_organizationID][certKey];
    }
    /**
      * Register a certificate administrator.
      *
      * This can be done by the global administrator only.
      *
      * @param _CertAdmin Address of certificate administrator to be added.
      */
    function addCertAdmin(address _CertAdmin, bytes32 _organizationID) public onlyGlobalAdmin {
        CertAdmins[_organizationID][_CertAdmin] = true;
        emit CertAdminAdded(_CertAdmin);
    }

    /**
      * Delete a certificate administrator.
      *
      * This can be done by the global administrator only.
      *
      * @param _CertAdmin Address of certificate administrator to be removed.
      */
    function delCertAdmin(address _CertAdmin, bytes32 _organizationID) public onlyGlobalAdmin {
        delete CertAdmins[_organizationID][_CertAdmin];
        emit CertAdminDeleted(_CertAdmin);
    }

    /**
  * Register a ROSEN certificate administrator.
  *
  * This can be done by the global administrator only.
  *
  * @param _CertAdmin Address of certificate administrator to be added.
  */
    function addRosenCertAdmin(address _CertAdmin) public onlyGlobalAdmin {
        RosenCertAdmins[_CertAdmin] = true;
        emit CertAdminAdded(_CertAdmin);
    }

    /**
      * Delete a ROSEN certificate administrator.
      *
      * This can be done by the global administrator only.
      *
      * @param _CertAdmin Address of certificate administrator to be removed.
      */
    function delRosenCertAdmin(address _CertAdmin) public onlyGlobalAdmin {
        delete RosenCertAdmins[_CertAdmin];
        emit CertAdminDeleted(_CertAdmin);
    }

    /**
      * Change the address of the global administrator.
      *
      * This can be done by the global administrator only.
      *
      * @param _GlobalAdmin Address of new global administrator to be set.
      */
    function changeGlobalAdmin(address _GlobalAdmin) public onlyGlobalAdmin {
        GlobalAdmin=_GlobalAdmin;
        emit GlobalAdminChanged(_GlobalAdmin);

    }

    // Constant Functions

    /**
      * Determines the address of a certificate contract.
      *
      * @param _CertID Unique certificate identifier.
      * @return Address of certification contract.
      */
    function getCertAddressByID(string _CertID, bytes32 _organizationID) public view returns (address) {
        return CertificateAddresses[_organizationID][getCertKey(_CertID)];
    }

    /**
      * Determines the address of a certificate contract.
      *
      * @param _CertID Unique certificate identifier.
      * @return Address of certification contract.
      */
    function getOrganizationalCertAddressByID(string _CertID) public view returns (address) {
        return RosenCertificateAddresses[getCertKey(_CertID)];
    }

    /**
      * Derives an unique key from a certificate identifier to be used in the
      * global mapping CertificateAddresses.
      *
      * This is necessary due to certificate identifiers are of type string
      * which cannot be used as dictionary keys.
      *
      * @param _CertID The unique certificate identifier.
      * @return The key derived from certificate identifier.
      */
    function getCertKey(string _CertID) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_CertID));
    }


    // Modifiers

    /**
      * Ensure that only the global administrator is able to perform.
      */
    modifier onlyGlobalAdmin () {
        require(msg.sender==GlobalAdmin);
        _;
    }

    /**
      * Ensure that only a privileged certificate administrator is able to perform.
      */
    modifier onlyPrivilegedCertAdmin(bytes32 organizationID) {
        require(CertAdmins[organizationID][msg.sender] || RosenCertAdmins[msg.sender]);
        _;
    }

    modifier onlyRosenCertAdmin() {
        require(RosenCertAdmins[msg.sender]);
        _;
    }

}