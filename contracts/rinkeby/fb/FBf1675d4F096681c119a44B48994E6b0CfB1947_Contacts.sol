/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.4.21 <0.9.0;

contract Contacts {
    uint public count = 0; // state variable
    string public baseURI;  
    address public owner;
    uint256 val = 0;

    struct Contact {
        uint id;
        string name;
        string phone;
    }
    mapping(uint => Contact) public contacts;
  
    constructor(
        string memory _initBaseURI
    ) {
        owner = msg.sender;
        baseURI = _initBaseURI;
        createContact('Zafar Saleem', '123123123');
    }  

    function rand()
        public
        view
        returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty +((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));
        return (seed - ((seed / 1000) * 1000));
    }

  
    function createContact(string memory _name, string memory _phone) public {
        count++;
        contacts[count] = Contact(count, _name, _phone);
    }
}