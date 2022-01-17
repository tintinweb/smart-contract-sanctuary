/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MemberRegistration {
    
    struct Member {
        string name;
        uint age;
        address id;
    }

    // An array of 'Member' structs
    Member[] public members;

    function addMember(string memory _name, uint _age, address _id) public returns(uint _member_id) {
        members.push(Member(_name, _age, _id));
        uint member_id = members.length;
        return member_id;
    }

    // update name
    function updatename(address _id, uint _member_id, string memory _name) public {
        require(msg.sender == _id, "You are not authorized to update.");
        Member storage member = members[_member_id-1];
        member.name = _name;
    }

    // update age
    function updateage(address _id, uint _member_id, uint _age) public {
        require(msg.sender == _id, "You are not authorized to update.");
        Member storage member = members[_member_id-1];
        member.age = _age;
    }

}