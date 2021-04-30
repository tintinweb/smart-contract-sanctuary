/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity 0.8.0;

contract class_3_2 {
    struct student {
        string name;
        uint year;
        uint month;
        uint day;
        uint score;
    }

    student[] students;
    
    function setStudent(string memory _name, uint _year, uint _month, uint _day, uint _score) public {
        students.push(student(_name, _year, _month, _day, _score));
    }
    
    function getAverage() public view returns(uint) {
        uint a=0;
        for(uint i=0; i<students.length; i++){
            a=a+students[i].score;
        }
        
        return a/students.length;
    }
}