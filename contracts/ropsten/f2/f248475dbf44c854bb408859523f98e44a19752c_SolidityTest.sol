/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.5.0;
contract SolidityTest {         
    address public owner;           
    uint public size;           //number of student's added 
    constructor() public{
        owner = msg.sender;         //get owners address
    }

    struct students {           //struct for student's info 
        uint studentID;
        string studentName;
        string studentEmail;
        string programme;
    }

    students[] Students; //declare array structure

    function setStudents(uint _studentID , string memory _studentName , string memory _studentEmail , string memory _programme ) public {            //add user function
        require(msg.sender == owner, 'not the owner');                  // only owner can add user
        size = Students.length++;                                              //go to next 
        Students[Students.length - 1].studentID = _studentID;               //insert id
        Students[Students.length - 1].studentName = _studentName;           //insert name
        Students[Students.length - 1].studentEmail = _studentEmail;         //insert email
        Students[Students.length - 1].programme = _programme;         //insert programme
        
    }

    
    function getStudent(uint index) public view returns(uint, string memory, string memory, string memory) {    //get student's info function
        for (uint i = 0; i <= size; i++){   // check all rows
            if(index == Students[i].studentID){ //target the student's id
                return (Students[i].studentID, Students[i].studentName, Students[i].studentEmail, Students[i].programme); //print students info
            }
        }
    }

  
    
}