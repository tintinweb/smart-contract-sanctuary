/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity ^0.8.0;//1. Enter solidity version here

//2. Create contract here
contract HelloHse{
    
    mapping (address => Student) public students;
    
    struct Student {
        uint mark;
        uint balance;
        string name;
        string surname;
    }
    
    address public admin;
    
    constructor() {
        admin = msg.sender;
    }
    
    
    function createStudent(address studentAddres, uint _mark, uint _balance, string memory _name, string memory _surname) public {
        Student memory newStudent = Student(_mark, _balance, _name, _surname);
        students[studentAddres] = newStudent;
    }
    
    
    function changeMark(address student, uint newMark) onlyAdmin public {
        students[student].mark = newMark;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin");
        _;
    }
    
    
}