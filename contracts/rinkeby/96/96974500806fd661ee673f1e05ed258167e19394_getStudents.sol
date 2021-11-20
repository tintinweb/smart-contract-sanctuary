/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.6;

 interface get_interface {
     function getStudentsList() external view returns (string[] memory stdents); 
}
contract getStudents{
    
 address student_contract=0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
 
  
    
  function success_done_count() public view returns(uint) {
  string[] memory students =get_interface(student_contract).getStudentsList();
  uint lengt=students.length;
  return lengt;
  }  
  
  function names_on_list(uint number) public view returns(string memory) {
  string[] memory students =get_interface(student_contract).getStudentsList();
  string memory student=students[number-1];
  return student;
  }  
  
}