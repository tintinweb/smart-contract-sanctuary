/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// File: IStudentsRegistry.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IStudentsRegistry {
    function isStudent(address student) external view returns(bool);
}
// File: StudentsRegistry.sol

pragma solidity >=0.7.0 <0.9.0;


contract StudentsRegistry is IStudentsRegistry{
    
    address owner;
    uint256 maxRegisterTime;
    mapping(address => bool) students;

    event NewStudent(address indexed student);
    event StudentRemoved(address indexed student);
    event OwnerTransfer(address indexed newOwner);
    
    constructor(uint256 _maxRegisterTime){
        owner = msg.sender;
        maxRegisterTime = _maxRegisterTime;
        emit OwnerTransfer(owner);
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
        emit OwnerTransfer(owner);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Not Authorized");
        _;
    }
    
    function addStudent(address studentAddress) public onlyOwner{
        students[studentAddress] = true;
        emit NewStudent(studentAddress);
    }
    
    
    function removeStudent(address studentAddress) public onlyOwner{
        students[studentAddress] = false;
        emit StudentRemoved(studentAddress);
    }
    
    function changeRegisterTime(uint256 _maxRegisterTime) public onlyOwner{
        maxRegisterTime = _maxRegisterTime;
    }
    
    function register() public{
        require(block.timestamp <= maxRegisterTime, "You cannot register anymore");
        students[msg.sender] = true;
        emit NewStudent(msg.sender);
    }
    
    function isStudent(address student) public override view returns(bool){
        return students[student];
    }
    
}