/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity 0.8.0;

contract Likelion_11 {
    struct student {
    string name;
    }
    uint public count = 0;
    
    student[] students;
    
    function setStudent(string memory _name) public {
        students.push(student(_name));
        count += 1;
    }
    
    function getStudent(string memory _name) public view returns(bool) {
        
    }
}