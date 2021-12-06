/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Student  // Custom data types just like object
{
    uint roll;
    string name;
}

contract Intro {
    string public name;
    uint public age;
    bytes public b2="ab";

    // Enum Part
    enum userPermissions{user,admin}
    userPermissions public user; // default 0 | user 
    Student public s1;

    // Storage And Memory
    string[] public people=["Jawad","Immad","Fawad"];

    //Address to send Ether
    address payable accountToTransfer= payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);

    // constructor(string memory newName)
    // {
    //     name=newName;
    //     //age=24;
    //     s1.roll= 1;
    //     s1.name= "Jawad";
    // }

    function getName() view public returns(string memory)
    {
        return name;
    }
    /*
    
    function getAge() view public returns(uint)
    {
        return age;
    }
    */
    function setAge(uint newAge) public
    {
        age=newAge;
    }
    function setName(string memory newName ) public
    {
        name= newName;
    }

    function pureFunction () public pure returns(uint){
        uint num = 10;
        return num;
    }

    function getElement(uint i) view public returns(bytes1) // Get element form Bytes array using index
    {
        return b2[i];
    }

    function pushElement() public // Push element to Bytes array
    {
        b2.push("c");
    }

    function condition(int a) public pure returns (string memory) // If else Intro
    {
        string memory val;
        if(a>0){
            val= "Greater than 0";
        }else if (a<0){
            val= "Less than 0";
        }else {
            val= "Value is 0";
        }
        return val;
    }   

    function editStudent(uint _roll, string memory _name) public // Edit s1 Student
    {
        Student memory newStudent = Student({
            roll : _roll,
            name : _name
        });
        s1 = newStudent;
    }

    function makeUserAdmin() public // Make user admin
    {
        user= userPermissions.admin;
    }

    function makeAdminUser() public // Make admin user
    {
        user= userPermissions.user;
    }

    // Storage And Memory

    // Memory Function
    function mem() public view
    {
        string[] memory p1=people; // state value cannot be changed by memory keyword
        p1[0]="Pokemon Memory"; 
    }

    // Storage Function
    function stor() public
    {
        string[] storage p1=people; // state value can be changed by storage keyword
        p1[0]="Pokemon"; 
    }

    // Available global variables
    // Other Global variable can be seen here "https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html"
    // Get block information
    function getBlockInfo() public view returns(uint block_no,uint timestamp, address msgSender)
    {
        return(block.number,block.timestamp,msg.sender);
    }

    // Get Ether in Contract
    function getEtherInContract() public payable
    {}

    // Get balance of contract 
    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    // Transfer Ether to any account
    // Before sending ether to account. We should transfer ether to this contract.
    // Otherwise it won't work
    function sendEtherToAccount() public
    {
        accountToTransfer.transfer(5 ether);
    }
}