pragma solidity ^0.4.25;

contract HSE_students {
  struct Student {
    address addr;
    string name;
  }
  
  string public constant name = "HSE students";
  string public constant symbol = "hse";
  mapping(address => bool) internal b_students;
  mapping(address => uint) public addr_to_int;
  mapping(uint => address) public int_to_addr;
  mapping(uint => Student) public students;
  Student internal student;
  uint32 public n_students = 0;
  
  function enterYourName(string _name) public {
    require(keccak256(_name) != keccak256(""));
    student.addr = msg.sender;
    student.name = _name;
    if (b_students[msg.sender] == false) {
        students[n_students] = student;
        addr_to_int[msg.sender] = n_students;
        int_to_addr[n_students] = msg.sender;
        n_students++;
        b_students[msg.sender] = true;
    } else {
        uint student_no = addr_to_int[msg.sender];
        students[student_no] = student;
    }
  }

}