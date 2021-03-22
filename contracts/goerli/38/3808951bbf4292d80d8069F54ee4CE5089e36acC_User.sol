/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity <=0.8.2;

contract User{
    uint public userCount;
    
    struct Person{
        uint id;
        string name;
        address addr;
    }
    mapping(address => bool) userExists;
    mapping(uint => address) idToAddress;
    mapping(address => uint) addressToId;
    mapping(address => Person) people;
   
    function addPerson(string memory _name, address _addr) public{
        require(userExists[_addr]==false);
        userCount++;
        idToAddress[userCount] = _addr;
        addressToId[_addr] = userCount;
        people[_addr] = Person({
            id: userCount,
            name: _name,
            addr: _addr
        });
        userExists[_addr] = true;
    }
    
    function getPerson(address _addr) public view returns(uint,string memory,address){
        return(people[_addr].id,people[_addr].name,people[_addr].addr);
    }
    
    function getPersonByID(uint _id) public view returns(uint,string memory,address){
        address _addr = idToAddress[_id];
        return(people[_addr].id,people[_addr].name,people[_addr].addr);
    }
}