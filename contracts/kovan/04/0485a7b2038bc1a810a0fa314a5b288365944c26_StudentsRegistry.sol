/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// File: contracts/IStudentsRegistry.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IStudentsRegistry {
    function isStudent(address studentAddress) external view returns(bool);
}


contract StudentsRegistry is IStudentsRegistry{
    
    mapping(address => bool) students;
    
    uint256 public maxRegisterTime;
    address owner;
    
    event NewStudent(address indexed student);
    event StudentRemoved(address indexed student);
    event OwnerTransfer(address indexed newOwner);
    
    constructor(uint256 _maxRegisterTime){
        maxRegisterTime = _maxRegisterTime;
        owner = msg.sender;
        emit OwnerTransfer(owner);
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender, "Not authorized");
        _;
    }
    
    function changeRegisterTime(uint256 _maxRegisterTime) public onlyOwner{
        maxRegisterTime = _maxRegisterTime;
    }
    
    function transferOwner(address newOwner) public onlyOwner{
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
        emit OwnerTransfer(newOwner);
    }
    
    
    function addStudent(address studentAddress) public onlyOwner{
        students[studentAddress] = true;
        emit NewStudent(studentAddress);
    }
    
    function removeStudent(address studentAddress) public onlyOwner{
        students[studentAddress] = false;
        emit StudentRemoved(studentAddress);
    }
    
    function register() public {
        require(block.timestamp <= maxRegisterTime, "You cannot register anymore");
        students[msg.sender] = true;
        emit NewStudent(msg.sender);
    }
    
    function isStudent(address studentAddress) public override view returns(bool){
        return students[studentAddress];
    }
    
}