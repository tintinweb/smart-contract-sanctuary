/**
 *Submitted for verification at polygonscan.com on 2021-12-10
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract MedicalChain{

    mapping(address=>Doctor) DoctorInfo;
    mapping(address=>Patient) PatientInfo;
    mapping(address=> mapping(address => HealthRecords)) HealthInfo;
    mapping (address => mapping (address => uint)) private patientToDoctor;



    event DrDetailsAdded(address admin, address doctor);
    event HealthRecordsAdded(address dr, address patient);
    event GrantAccessToDr(address dr, address patient);

    modifier OnlyOwner(){
        require(msg.sender == owner,"ONLY ADMIN IS ALLOWED");
        _;
    }
    
    modifier Only_Doctors{
        require(DoctorInfo[msg.sender].state == true,"REGISTERED DOCTORS ONLY");
        _;
    }
    
    modifier Only_Patients{
        require(PatientInfo[msg.sender].state == true,"REGISTERED PATIENTS ONLY");
        _;
    }
    
    address owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    struct Doctor{
        bool state; // To check whether the doctor is registered or not
        address dr_Id; // Address of doctor
        string d_Name; // Name of doctor
    }
    
    struct Patient{
        bool state; // To check whether patient is genuine
        address pa_Id; // Address of registered patient
        string pa_Name; // Name of Patient Name
        string[] pa_Records; // Used to store the prescription records of corresponding patients
    }
    
    struct PrescriptionDetails{
        string prescription; // prescription details of patient given by doctor
    }
    
    struct HealthRecords{
        Doctor d;
        Patient p;
        PrescriptionDetails pre;
        string[] records; // Used to store prescription records of patient w.r.t doctor
    }
    

    
    // Function to add Doctor details, done by admin only
    function setDoctorDetails(bool _state,address _drId,string memory _name) public OnlyOwner {
        DoctorInfo[_drId] = Doctor(_state,_drId,_name);
        emit DrDetailsAdded(msg.sender, _drId);
    }
    
    
    
    // Function to get Doctor details for admin
    function getDoctorDetails(address _Id) public OnlyOwner view returns(bool _state,address _drId,string memory _name){
        _state = DoctorInfo[_Id].state;
        _drId = DoctorInfo[_Id].dr_Id;
        _name = DoctorInfo[_Id].d_Name;
    }
    
    
    
    // Function to add HealthRecords of patients, done by registered doctors only
    function setHealthRecordsDetails(string memory _paName, address _paId, string memory _prescription) public Only_Doctors{
        
        HealthInfo[msg.sender][_paId].d.d_Name = DoctorInfo[msg.sender].d_Name; 
        HealthInfo[msg.sender][_paId].d.dr_Id = DoctorInfo[msg.sender].dr_Id;
        HealthInfo[msg.sender][_paId].p.state = true;
        HealthInfo[msg.sender][_paId].p.pa_Id = _paId;
        HealthInfo[msg.sender][_paId].p.pa_Name = _paName;
        HealthInfo[msg.sender][_paId].pre.prescription = _prescription;
        HealthInfo[msg.sender][_paId].records.push(_prescription);
        PatientInfo[_paId].pa_Records.push(_prescription);
        setPatientDetails(HealthInfo[msg.sender][_paId].p.state,HealthInfo[msg.sender][_paId].p.pa_Id,HealthInfo[msg.sender][_paId].p.pa_Name,PatientInfo[_paId].pa_Records);
        emit HealthRecordsAdded(msg.sender, _paId);
    }
    
    
    
    // Function to add Patient details, done by registered doctors only
    function setPatientDetails(bool _state,address _paId,string memory _paName,string[] memory _paRecords) public Only_Doctors{
        PatientInfo[_paId] = Patient(_state,_paId,_paName,_paRecords);
    }
    
    
    
    // Function to get Patient details
    function getPatientDetails(address _Id) public view returns(bool _state,address _paId,string memory _paName,string[] memory _paRecords){
       require(PatientInfo[msg.sender].state == true || patientToDoctor[_Id][msg.sender] == 1,"PATIENTS OR ACCESS_GRANTED_DOCTORS ONLY");
        _state = PatientInfo[_Id].state;
        _paId = PatientInfo[_Id].pa_Id;
        _paName = PatientInfo[_Id].pa_Name;
        _paRecords = PatientInfo[_Id].pa_Records;
        
    }
    
    
    
    // Function to get HealthRecords only for registered patients
    function getHealthRecords(address _dr) Only_Patients public view returns(string memory _drName, address _drId, string memory _paName, address _paId,string memory _prescription,string[] memory _rec) {
        _drName = HealthInfo[_dr][msg.sender].d.d_Name;
        _drId = HealthInfo[_dr][msg.sender].d.dr_Id;
        _paName = HealthInfo[_dr][msg.sender].p.pa_Name;
        _paId = HealthInfo[_dr][msg.sender].p.pa_Id;
        _prescription = HealthInfo[_dr][msg.sender].pre.prescription;
        _rec = HealthInfo[_dr][msg.sender].records;
    }



    // Function to grant access to doctor ,so that the doctors with access can view the corresponding patients HealthRecords
    function grantAccessToDoctor(address doctor_id,uint access) public Only_Patients{
    	patientToDoctor[msg.sender][doctor_id] = access;
        emit GrantAccessToDr(doctor_id,msg.sender);
      }
  	
  	
  	
  	// Function to get HealthRecords only for registered Doctors
  	function getHealthRecordsForDoctor(address _paId) public Only_Doctors view returns(string memory _drName, address _drId, string memory _paName, address _pId,string memory _prescription,string[] memory _rec){
		require(patientToDoctor[_paId][msg.sender] == 1,"DR ACCESS NOT GRANTED");
		_drName = HealthInfo[msg.sender][_paId].d.d_Name;
        _drId = HealthInfo[msg.sender][_paId].d.dr_Id;
        _paName = HealthInfo[msg.sender][_paId].p.pa_Name;
        _pId = HealthInfo[msg.sender][_paId].p.pa_Id; 
        _prescription = HealthInfo[msg.sender][_paId].pre.prescription;
        _rec = HealthInfo[msg.sender][_paId].records;
	}

}