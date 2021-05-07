/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: contracts/IStudentRegistry.sol

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IStudentRegistry {
    function isStudent(address studentAddress) external view returns(bool);
}
// File: contracts/StudentRegistry.sol



contract StudentsRegistry is IStudentRegistry{
    
    mapping(address => bool) students;
    uint256 public maxRegisterTime;
    address owner;
    
    
    event NewStudent(address indexed student); //other apps react to what happen
    event StudentRemoved(address indexed student);
    event OwnerTransfer(address indexed newOwner);
    
    
    constructor(uint256 _maxRegisterTime){ //so user can register only within a time limit. 
        maxRegisterTime = _maxRegisterTime;
        owner = msg.sender;
        emit OwnerTransfer(owner); // to always see who is the owner
    }
    
     modifier onlyOwner(){ //instead of the require inside the changeRegisterTime function
        require(owner == msg.sender, "not authorized");
        _;
    }
    
    function changeRegisterTime(uint256 _maxRegisterTime) public onlyOwner { //to extend deadline, owner only!
        maxRegisterTime=_maxRegisterTime;
    }
    
    
    function removeStudent(address strudentAddress) public onlyOwner {
        students[strudentAddress] = false;
        emit StudentRemoved(strudentAddress);
    }
    
    function addStudent(address strudentAddress) public onlyOwner {
        students[strudentAddress] = true;
        emit NewStudent(strudentAddress);
    }
    
    //to check if address owner or not
    function isStudent(address strudentAddress) public override view returns (bool) { //override as this fun already exists in the interface
        return students[strudentAddress];
    }
    
    function register() public {
        require(block.timestamp <= maxRegisterTime, "You can't register anymore"); //error msg when tx reverted
        students[msg.sender] = true;
        emit NewStudent(msg.sender);
    }
    
    function transerOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid Address"); //safety check. can prevente you to write 0 or wrong param and send the transaciton
        owner=newOwner;
        emit OwnerTransfer(owner);
    }
}