/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-20
*/

pragma solidity 0.7.4;
pragma experimental  ABIEncoderV2;

contract SureRx {
    string public name;

    uint public patientCount= 0; 

    
    mapping(uint => Patient) private  patients;

    

   
   address public Owner;
	
    struct Patient {
        uint id;
        uint SSN;
        string patientName;
	    string patientGender;
	    string patientDOB;
        //string patientContNum;
	    string consultedPrescriber;
	    string bloodPressure;
	    string medicationCurrentlyTaken;
	    string visitdate;
	    uint temprature;
	    uint height;
	    uint weight;
	    
        }

   
     
    modifier onlyOwner {
        require(msg.sender == Owner, "Only Owner can perform this!");
        _;
    }
    
    constructor() public {
        name = "SuperSecure Contract";
        Owner = msg.sender;
    }
    
  function patient(uint  _patient)  public view  returns (uint id,uint SSN,
        string[7] memory,uint temprature,uint height,uint weight)
        {
        if(msg.sender == Owner)
            return (
            patients[_patient].id,
            patients[_patient].SSN,
            [patients[_patient].patientName,
            patients[_patient].patientGender,
            patients[_patient].patientDOB,
            patients[_patient].consultedPrescriber,
            patients[_patient].bloodPressure,
            patients[_patient].medicationCurrentlyTaken,
            patients[_patient].visitdate],
            patients[_patient].temprature,
            patients[_patient].height,
            patients[_patient].weight);
        else{
            return(0,0,['','','','','','',''],0,0,0);
        }
	        
	    } 
    
    function setPatient(uint _ssn,string memory _patientName, string memory _patientGender, string memory _patientDOB,
    string memory _bloodPressure,string memory _medicationCurrentlyTaken,
    string memory _visitdate,string memory _consultedPrescriber,uint _temprature,uint _height,uint _weight) onlyOwner public {
	patientCount++;
        patients[patientCount] = Patient(patientCount,_ssn, _patientName, _patientGender, _patientDOB,
        _bloodPressure,_medicationCurrentlyTaken,_visitdate,_consultedPrescriber,_temprature,
        _height,_weight);
    }
	
}