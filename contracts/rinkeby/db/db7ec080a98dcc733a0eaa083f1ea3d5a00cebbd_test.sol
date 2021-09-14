/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{
    struct Members{
        uint ID;
        string Name;
        address Account;
        uint256 Balance;
    }
    Members[] public member;
    mapping(string => uint) name2ID;
    mapping(uint => address) ID2Address;
    
    function initMember(uint _index)public{
        member[_index].ID = 1;
        member[_index].Name ="Kom";
        member[_index].Account = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        member[_index].Balance = 0;
        
        name2ID[member[_index].Name]=member[_index].ID;
        ID2Address[member[_index].ID]=member[_index].Account;
    }
    
    function createMember(Members memory _member)public{
        Members memory mb;
        mb.ID = _member.ID;
        mb.Name =_member.Name;
        mb.Account = _member.Account;
        mb.Balance = _member.Balance;
        
        member.push(mb);
        name2ID[_member.Name]=_member.ID;
        ID2Address[_member.ID]=_member.Account;
    }
    
    function getID(string memory _name)public view returns(uint){
        return name2ID[_name];
    }
    
    function getAddress(uint _ID)public view returns(address){
        return ID2Address[_ID];
    }
}