/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
contract storeData{
    string public name;
    uint public age;
    address public permanentAddress;
    function setName(string memory _name)public {
        name = _name;
    }
    function getName() public view returns(string memory){
        return name;
    }
    function setAge(uint _age)public {
        age = _age;
    }
    function getAge()public view returns(uint){
        return age;
    }
    function setAddress(address _permanentAddress) public{
        permanentAddress = _permanentAddress;
    }
    function getAddress()public view returns(address){
        return permanentAddress;
    }
}