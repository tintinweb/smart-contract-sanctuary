pragma solidity 0.5.0;

contract Organization {

    //Basic Organization details
    string public organizationName;
    string public organizationAddress;
    string public registrationNumber;
    string public website;
    string public phoneNumber;
    address public wallet;

    //Employee details
    struct Employee {
        string name;
        string designation;
        bool isActive;
        bool exists;
    }

    //Employees in the organization
    mapping(address => Employee) public employees;

    //Certificate details
    struct Certificate {
        string certificateType;
        string duration;
        bool exists;
    }

    //Certificates in the organization
    mapping(address => Certificate) public certificates;

    //Beneficiary details
    struct Beneficiary {
        string name;
        string phoneNumber;
        bool exists;
    }

    //Beneficiaries in the organization
    mapping(address => Beneficiary) public beneficiaries;

    //Issued Certificate details
    struct IssuedCertificate {
        address beneficiary;
        address certificate;
        address employee;
        string year;
        uint256 createdDate;
        bool isRevoked;
        bool exists;
    }

    //Issued certificate in the organization
    mapping(address => IssuedCertificate) public issuedCertificates;

    //Issued Certificates per Beneficiary
    mapping(address => address[]) public issuedCertificatesPerBeneficiary;

    /**
   * @dev Throws if called by any account other than the Organization Owner.
   */
    modifier onlyOrganizationAdmin() {
        require(msg.sender == wallet, "You are not Organization Owner.");
        _;
    }

    /**
   * @dev Throws if called by any account who is not an employee or organization admin.
   */
    modifier onlyEmployee() {
        require(employees[msg.sender].exists, "You are not Organization Employee.");
        require(employees[msg.sender].isActive, "Your account is not active.");
        _;
    }

    constructor(
        string memory _organizationName,
        string memory _organizationAddress,
        string memory _registrationNumber,
        string memory _website,
        string memory _phoneNumber,
        string memory _employeeName,
        string memory _designation) public {
        organizationName = _organizationName;
        organizationAddress = _organizationAddress;
        registrationNumber = _registrationNumber;
        website = _website;
        phoneNumber = _phoneNumber;
        wallet = msg.sender;
        employees[wallet] = Employee(_employeeName, _designation, true, true);
    }

    event EmployeeAdded(address wallet, string name, string designation);

    function addEmployee(
        address _wallet,
        string memory _name,
        string memory _designation) public onlyOrganizationAdmin {
        require(!employees[_wallet].exists, "This employee is already enrolled.");
        Employee memory employee = Employee(_name, _designation, true, true);
        employees[_wallet] = employee;
        emit EmployeeAdded(_wallet, _name, _designation);
    }

    event EmployeeDeactivated(address wallet);

    function deactivateEmployee(address _employeeWallet) public onlyOrganizationAdmin {
        require(employees[_employeeWallet].exists, "Employee is not enrolled.");
        employees[_employeeWallet].isActive = false;
        emit EmployeeDeactivated(_employeeWallet);
    }

    event EmployeeActivated(address wallet);

    function activateEmployee(address _employeeWallet) public onlyOrganizationAdmin {
        require(employees[_employeeWallet].exists, "Employee is not enrolled.");
        employees[_employeeWallet].isActive = true;
        emit EmployeeActivated(_employeeWallet);
    }

    event CertificateAdded(address wallet, string certificateType, string duration);

    function addCertificate(
        address _wallet,
        string memory _certificateType,
        string memory _duration) public onlyOrganizationAdmin {
        require(!certificates[_wallet].exists, "This Certificate is already added.");
        Certificate memory certificate = Certificate(_certificateType, _duration, true);
        certificates[_wallet] = certificate;
        emit CertificateAdded(_wallet, _certificateType, _duration);
    }

    event BeneficiaryAdded(address wallet, string name, string phoneNumber);

    function addBeneficiary(
        address _wallet,
        string memory _name,
        string memory _phoneNumber) public onlyEmployee {
        require(!beneficiaries[_wallet].exists, "This beneficiary is already added.");
        Beneficiary memory beneficiary = Beneficiary(_name, _phoneNumber, true);
        beneficiaries[_wallet] = beneficiary;
        emit BeneficiaryAdded(_wallet, _name, _phoneNumber);
    }

    event CertificateIssued(address wallet, address beneficiary, address certificate, address issuer);

    function issueCertificate(
        address _wallet,
        address _certificate,
        address _beneficiary,
        string memory _year) public onlyEmployee {
        require(certificates[_certificate].exists, "This Certificate does not exist.");
        require(employees[msg.sender].exists, "This Employee does not exist.");
        require(beneficiaries[_beneficiary].exists, "This Beneficiary does not exist.");

        address[] memory beneficiaryIssuedCertificates = issuedCertificatesPerBeneficiary[_beneficiary];
        if (beneficiaryIssuedCertificates.length != 0) {
            for (uint i = 0; i < beneficiaryIssuedCertificates.length; i++) {
                require(issuedCertificates[beneficiaryIssuedCertificates[i]].certificate != _certificate, "This certificate is already issued to the Beneficiary");
            }
        }
        IssuedCertificate memory issuedCertificate = IssuedCertificate(_beneficiary, _certificate, msg.sender, _year, now, false, true);
        issuedCertificates[_wallet] = issuedCertificate;
        issuedCertificatesPerBeneficiary[_beneficiary].push(_wallet);
        emit CertificateIssued(_wallet, _beneficiary, _certificate, msg.sender);
    }

}