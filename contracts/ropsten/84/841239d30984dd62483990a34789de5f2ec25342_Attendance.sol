/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity 0.8.6;

contract Attendance {
    
    uint public admitBlock;
    
    struct Student {
        uint eName;
        address studentId;
        uint checkTime;
    }

    Student[] students;


    mapping(address => mapping(uint => uint)) studentCount;
    
    function attendStart() public {
        admitBlock = block.number;
    }
    
    function attend(string memory _studentName) public {
        // get current time & block numer
        uint checkTime = block.timestamp - (block.timestamp % 1000);
        uint currentBlock = block.number;
        
        // check double attending
        require(studentCount[msg.sender][checkTime] == 0 && admitBlock + 66 > currentBlock);
        
        // user name encrpyt
        uint eName = getEncrpytedName(_studentName);
        students.push(Student(eName, msg.sender, checkTime));
        
        // * need check index method 
        studentCount[msg.sender][checkTime]++;
    }

    function getEncrpytedName(string memory _str) public pure returns (uint) {
        uint name = uint(keccak256(abi.encodePacked(_str)));
        return name % 1000;
    }

    function getStudent() public returns (Student[] memory ){
        return students;
    }
}