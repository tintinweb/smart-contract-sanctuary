/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity 0.6.1;


contract CheckIn {

    mapping (address => string) public names;
    mapping (address => uint256) public studentsId;
    
    event SetStudent(address indexed student, uint256 id);

    function checkIn(string memory name) public {
        names[msg.sender] = name;
    }

    function getStudent(address student) public view returns (string memory){
        return names[student];
    }
    
    function checkIn2(address student, uint256 id) public {
        studentsId[student] = id;
        
        emit SetStudent(student, id);
    }
}