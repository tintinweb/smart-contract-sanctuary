pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

contract MedicalPrescriptionContract {
    
    struct RegulatoryAuthority {
        string name;
        bool isValid;
    }
    
    struct Physician {
        uint license;
        string name;
        string lastname;
        bytes32 signature;
        int[] prescriptionsCode;
        bool isValid;
    }
    
    struct Pharmacist {
        string name;
        bool isValid;
    }
    
    struct Patient {
        string name;
        string lastname;
        string affiliateNumber;
        uint sex;
        uint birthDay;
        int[] prescriptionsCode;
        bool isValid;
    }
    
    struct DataAnalyzer {
        string name;
        bool isValid;
    }
    
    struct Prescription {
        address physicianAddress;
        address patientAddress;
        string[] drugs;
        string diagnosis;
        uint date;
        string place;
        bytes32 signature;
        PrescriptionStatus status;
        bool isValid;
    }
    
    enum PrescriptionStatus {CREATED, DELIVERED}
    
    address owner;
    mapping(address => RegulatoryAuthority) regulatoryAuthorities;
    mapping(address => Physician) physicians;
    mapping(address => Patient) patients;
    mapping(address => Pharmacist) pharmacists;
    mapping(int => Prescription) prescriptions;
    int prescriptionsLength;
    mapping(address => DataAnalyzer) dataAnalyzers;
    
    constructor() public {
        owner = msg.sender;
        prescriptionsLength = 0;
    }
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    
    modifier onlyRegulatoryAuthority {
        require(
            regulatoryAuthorities[msg.sender].isValid,
            "Only Regulatory Authority can call this function."
        );
        _;
    }
    
    modifier onlyPhysician {
        require(
            physicians[msg.sender].isValid,
            "Only Physicians can call this function."
        );
        _;
    }
    
    modifier onlyPhysiciansOrPatientsOrPharmacists {
        require(
            physicians[msg.sender].isValid || patients[msg.sender].isValid || pharmacists[msg.sender].isValid,
            "Only Physicians, Patients or Pharmacists can call this function."
        );
        _;
    }
    
    function addRegulatoryAuthority(address _regulatoryAuthority, string memory _name) public onlyOwner returns (bool success) {
        if (regulatoryAuthorities[_regulatoryAuthority].isValid) return false;
        regulatoryAuthorities[_regulatoryAuthority].name = _name;
        regulatoryAuthorities[_regulatoryAuthority].isValid = true;
        return true;
    }
    
    function getRegulatoryAuthorities(address _regulatoryAuthority) public view onlyOwner returns(bool success, string memory name){
        return (regulatoryAuthorities[_regulatoryAuthority].isValid, regulatoryAuthorities[_regulatoryAuthority].name);
    }
    
    function addPhysician(address _physician, uint _license, string memory _name, string memory _lastname, bytes32 _signature) public onlyRegulatoryAuthority returns (bool success) {
        if (physicians[_physician].isValid) return false;
        physicians[_physician].license = _license;
        physicians[_physician].name = _name;
        physicians[_physician].lastname = _lastname;
        physicians[_physician].signature = _signature;
        physicians[_physician].isValid = true;
        return true;
    }
    
    function getPhysician(address _physician) public view returns(bool success, uint _license, string memory physicianName, string memory physicianLastname) {
        return (physicians[_physician].isValid,
            physicians[_physician].license,
            physicians[_physician].name,
            physicians[_physician].lastname
        );
    }
    
    function addPatient(address _patient, string memory _name, string memory _lastname, string memory _affiliateNumber, uint _sex, uint _birthDay) public onlyPhysician returns (bool success) {
        if (patients[_patient].isValid) return false;
        patients[_patient].name = _name;
        patients[_patient].lastname = _lastname;
        patients[_patient].affiliateNumber = _affiliateNumber;
        patients[_patient].sex = _sex;
        patients[_patient].birthDay = _birthDay;
        patients[_patient].isValid = true;
        return true;
    }
    
    function addPharmacist(address _pharmacist, string memory _name) public onlyRegulatoryAuthority returns (bool success) {
        if (pharmacists[_pharmacist].isValid) return false;
        pharmacists[_pharmacist].name = _name;
        pharmacists[_pharmacist].isValid = true;
        return true;
    }
    
    function addDataAnalyzer(address _dataAnalyzer, string memory _name) public onlyRegulatoryAuthority returns (bool success) {
        if (dataAnalyzers[_dataAnalyzer].isValid) return false;
        dataAnalyzers[_dataAnalyzer].name = _name;
        dataAnalyzers[_dataAnalyzer].isValid = true;
        return true;
    }
    
    function generatePresciptionCode(int index) private returns (int) {
        //generate hash
        return index;
    }

    function createPresciption(address _patient, string[] memory _drugs, string memory _diagnosis, uint _date, string memory _place) public onlyPhysician returns (bool success, int prescriptionCode)  {
        int code = generatePresciptionCode(prescriptionsLength);
        
        if (prescriptions[code].isValid || !patients[_patient].isValid) return (false, -1);
        
        prescriptions[code].physicianAddress = msg.sender;
        prescriptions[code].patientAddress = _patient;
        prescriptions[code].drugs = _drugs;
        prescriptions[code].diagnosis = _diagnosis;
        prescriptions[code].date = _date;
        prescriptions[code].place = _place;
        prescriptions[code].signature = physicians[msg.sender].signature;
        prescriptions[code].status = PrescriptionStatus.CREATED;
        prescriptions[code].isValid = true;
        
        physicians[msg.sender].prescriptionsCode.push(code);
        patients[_patient].prescriptionsCode.push(code);
        
        prescriptionsLength += 1;
        return (true, code);
    }
    
    function getPresciption(int _prescriptionCode) public onlyPhysiciansOrPatientsOrPharmacists returns (bool success, address physicianAddress, address patientAddress, string[] memory drugs, string memory diagnosis, uint date, string memory place, bytes32 signature, uint status)  {
        Prescription memory prescription = prescriptions[_prescriptionCode];
        
        //physicians can only get their own prescription
        if(physicians[msg.sender].isValid) {
            require(msg.sender == prescription.physicianAddress, "You only can get your own prescription");
        }

        //patients can only get their own prescription
        if(patients[msg.sender].isValid) {
            require(msg.sender == prescription.patientAddress, "You only can get your own prescription");
        }
        
        //delivered to Pharmacists
        if(pharmacists[msg.sender].isValid) {
            prescriptions[_prescriptionCode].status = PrescriptionStatus.DELIVERED;
            prescription.status = PrescriptionStatus.DELIVERED;
        }
        
        return (prescription.isValid, 
            prescription.physicianAddress,
            prescription.patientAddress,
            prescription.drugs,
            prescription.diagnosis,
            prescription.date,
            prescription.place,
            prescription.signature,
            uint(prescription.status)
        );
    }

}