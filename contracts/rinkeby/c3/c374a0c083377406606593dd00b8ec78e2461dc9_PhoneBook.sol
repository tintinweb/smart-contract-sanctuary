/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Phone book
 * @dev A place where people can publusg a name and age for their own address
 */
contract PhoneBook {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }



    struct Person {
        uint age;
        bytes32 name;   // short name (up to 32 bytes)
    }

    mapping(address => Person) public persons;

    /** 
     * @dev Add / change name and age in the address book. Can only be added or changed by the owner of the address
     */
    function setNameAndAge(address _addr, bytes32 _name, uint _age) public {
        require(
            msg.sender == _addr,
            "You can only set name and age for your own address."
        );
        persons[_addr].name = _name;
        persons[_addr].age = _age;
    }

    /** 
     * @dev Retrieve name and age for a given address
     */
    function getNameAndAge(address _addr) public view returns (bytes32, uint) {
        Person storage p = persons[_addr];
        return (p.name, p.age);
    }
}