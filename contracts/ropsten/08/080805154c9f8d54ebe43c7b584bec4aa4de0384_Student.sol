/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0;

contract Student {
    string name;
    string fatherName;
    string motherName;
    int rollno;
    int matricMarks;
    int cgpa;
    int age;

    // Father Name 
    // Mother Name
    // MatricMarks 
    // CGPA 
    // Age 


    function setStudentInfo(string memory n, string memory fn, string memory mn, int rn, int mm, int cg, int ag) public {
        name = n;
        rollno = rn;
        fatherName = fn;
        motherName = mn;
        matricMarks = mm;
        cgpa = cg;
        age = ag;
    }

    function getName() public view returns(string memory) {
        return name;
    
    }
    function getfatherName() public view returns(string memory){
        return fatherName;
    }
    function getmotherName() public view returns (string memory){
        return motherName;
    }

    function getRollNo() public view returns(int){
        return rollno;
    }
    function getmatricMarks() public view returns(int){
        return matricMarks;
    }
    function getcgpa() public view returns(int){
        return cgpa;
    }
    function getage() public view returns(int){
        return age;
    }


}