/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Deposit {

    address _masterAddress;

    struct _member {
        string memberName;
        address memberAddress;
        uint memberMoneyAmount;
    }

    _member[] _listMember;

    event NewDepositCome(address _address, uint _value, string _name); 

    constructor() {
        _masterAddress = msg.sender;
    }

    function getMemberLength() public view returns(uint){
        return _listMember.length;
    }

    function getMember(uint index) public view returns(string memory, address, uint){
        require(index < _listMember.length, "[0] Member does not exist!");
        _member memory tmp = _listMember[index];
        return (tmp.memberName,tmp.memberAddress,tmp.memberMoneyAmount);
    }

    function deposit(string memory _memberName) public payable{
        require(msg.value > 0, "[1] Amount must be larger than 0");
        _listMember.push(_member(_memberName,msg.sender,msg.value));
        emit NewDepositCome(msg.sender,msg.value,_memberName);
    }

    function withdraw() public {
        require(_masterAddress == msg.sender, "[2] you are not allowed to withdraw");
        payable(_masterAddress).transfer(address(this).balance);
    }
}