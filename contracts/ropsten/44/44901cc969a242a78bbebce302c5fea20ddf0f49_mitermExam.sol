/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.4.20;

contract mitermExam {
    
    address public owner;
    
    constructor() public {
        owner=msg.sender;
    }
    
    uint public size; 
    
    struct students {
        uint studentID;
        string studentName;
        string studentEmail;
        string programmeOfStudy;
    }
    
    students[] studentsRecords;

    function registerStudent(uint _studentID, string _studentName, string _studentEmail, string _programmeOfStudy) public {
        require(msg.sender==owner);
        size = studentsRecords.length++;
        studentsRecords[studentsRecords.length-1].studentID = _studentID;
        studentsRecords[studentsRecords.length-1].studentName = _studentName;
        studentsRecords[studentsRecords.length-1].studentEmail = _studentEmail;
        studentsRecords[studentsRecords.length-1].programmeOfStudy = _programmeOfStudy;
    }

    function searchStudent(uint _studentID) public constant returns(uint, string, string, string){
        uint index =0;
        for (uint i=0; i<=size; i++){
                if (studentsRecords[i].studentID == _studentID){
                    index=i;
                }
            }
        return (studentsRecords[index].studentID, studentsRecords[index].studentName, studentsRecords[index].studentEmail, studentsRecords[index].programmeOfStudy);
    }
   
}