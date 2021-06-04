/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// Smartcontract for Recording Students' Skills Development

// Compiler version:0.4.20-nightly.2018.1.26+commit.bbad48bb.Emscripten.clang

pragma solidity ^0.4.20;

// owner contract

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// dApps contract

contract studentSkills is owned{
    
    string public dAppPurpose = "Student Skills Records dApp";
    uint256 public size;
    mapping(address => bool) public educators;
    
    struct students {
        address studentAddress;
        uint adaptiveThinking;
        uint collaborationSkills;
        uint communicationSkills;
        uint criticalThinkingSkills;
        uint problemSolvingSkills;
        uint creativitySkills;
        uint managementSkills;
    }
    
    
    students[] studentsSkillsRecords;
 
    
    // add educators
    
    function addEducator(address educatorAddress, bool status) public {
      require(msg.sender==owner);
      educators[educatorAddress] = status;
   }
    
    // add the skills of students
    
    function addStudentSkills(address _studentAddress, uint _adaptiveThinking, uint _collaborationSkills, uint _communicationSkills, uint _criticalThinkingSkills, uint _problemSolvingSkills, uint _creativitySkills, uint _managementSkills) public payable returns(uint) {
        require(educators[msg.sender]==true);
        size = studentsSkillsRecords.length++;
        studentsSkillsRecords[studentsSkillsRecords.length-1].studentAddress = _studentAddress;
        studentsSkillsRecords[studentsSkillsRecords.length-1].adaptiveThinking = _adaptiveThinking;
        studentsSkillsRecords[studentsSkillsRecords.length-1].collaborationSkills = _collaborationSkills;
        studentsSkillsRecords[studentsSkillsRecords.length-1].communicationSkills = _communicationSkills;
        studentsSkillsRecords[studentsSkillsRecords.length-1].criticalThinkingSkills = _criticalThinkingSkills;
        studentsSkillsRecords[studentsSkillsRecords.length-1].problemSolvingSkills = _problemSolvingSkills;
        studentsSkillsRecords[studentsSkillsRecords.length-1].creativitySkills = _creativitySkills;
        studentsSkillsRecords[studentsSkillsRecords.length-1].managementSkills = _managementSkills;
        return studentsSkillsRecords.length;
        }
    
    
    // search for skills using a student address
    
    function searchStudentsSkills(address _searchStudentAddress) public constant returns(address, uint, uint, uint, uint, uint, uint, uint){
    uint index =0;
    for (uint i=0; i<=size; i++){
            if (studentsSkillsRecords[i].studentAddress == _searchStudentAddress){
                index=i;
            }
        }
    return (studentsSkillsRecords[index].studentAddress, studentsSkillsRecords[index].adaptiveThinking, studentsSkillsRecords[index].collaborationSkills, studentsSkillsRecords[index].communicationSkills, studentsSkillsRecords[index].criticalThinkingSkills, studentsSkillsRecords[index].problemSolvingSkills, studentsSkillsRecords[index].creativitySkills, studentsSkillsRecords[index].managementSkills);
    }
    
    
}