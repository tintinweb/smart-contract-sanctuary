/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//ex head count of the morning. immutable and there forever. at nd digit sign and sent to polito. 
// make public and such that can't be changed anymore. 

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

 contract Lessons {
     
     mapping(address => bool) _students; // better than : address[] public _students;
     address[] public _studentsAfternoon;
     address public _teacher;
     event NewStudent(address student);
     
     modifier onlyTeacher() {
         require(msg.sender == _teacher, "you are not the teacher");
         _ ; //call all body of method after having performed the require
     }
     
     constructor() { //inizializziamo il sender as a teacher 
         _teacher = msg.sender;
     }
     
     function addEther() public payable onlyTeacher {
        //  if (msg.sender != _teacher) {
        //      revert("You are not the teacher!");
        //  }
         
         //better version : require
         //require(msg.sender == __teacher, "you are not the teacehr!!!");
     }
     //who is teacher--> like this first one can be. use constructor
    //  function setTeacher(address teacherAddress) public {
    //      _teacher = teacherAddress;
         
    //  }
     
     function addStudent() public {
         //_students.push(msg.sender);
         _students[msg.sender] = true;
     }
     
     function isStudentPresent(address student) public view returns (bool) {
         
        //  for(uint i=0;i<_students.length;i++) { //if first student few cost, if last costs a lot!
        //      if(_students[i]==student){
        //          return true;
        //      }
             
        //  }
        //  return false;
        
        //after mapping
        return _students[student] == true; //non ritorna true ma true? Y/N
         
     }
     
     //how much value contract holds?
     
     function getBalance() public view returns (uint256) {
         return address(this).balance;
     }
     
     
     function addAfternoon() public returns (bool outcome) {
         address student = msg.sender;
         outcome=false;
          //send 0.01 eth to sender of this method. Where does it take eth from? from balance of smart contract. 
         
         //payable(msg.sender).transfer(0.01 ether); //se messo qui chiunque lo prende. Per correggere dopo revert();
         
         if (isStudentPresent(student)){
             _studentsAfternoon.push(student); //push as it is an array 
             payable(msg.sender).transfer(0.01 ether); //messo qui molto meglio
             emit NewStudent(student);
             outcome= true;
         }
         
         revert();
         
     }
     
 }