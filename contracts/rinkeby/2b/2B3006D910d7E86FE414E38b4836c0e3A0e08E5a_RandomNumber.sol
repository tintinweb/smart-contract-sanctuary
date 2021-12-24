/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.4.21 <0.9.0;

contract RandomNumber {
    uint public count = 0; // state variable
    string public baseURI;  
    address public owner;
    uint256 public initialNumber = 9999;
    uint256 val = 0;

    event RandomEvent(address sender, uint value);
    event ControlledEvent(address sender, uint value);

    struct Contact {
        uint id;
        string name;
        string phone;
    }

    mapping(uint => Contact) public contacts;
    mapping(uint256 => address) public transactions;
  
    constructor(
        string memory _initBaseURI        
    ) {
        owner = msg.sender;
        baseURI = _initBaseURI;
        createContact('Zafar Saleem', '123123123');
    }

    function createRandom(uint number) public {
        emit RandomEvent(msg.sender, uint(keccak256(abi.encodePacked(initialNumber++))) % number);
        emit ControlledEvent(msg.sender, 12345);
    }

    function rand()
        public
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty +((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));
        val = (seed - ((seed / 1000) * 1000)) * 100 / 100;        
    }

  
    function createContact(string memory _name, string memory _phone) public {
        count++;
        contacts[count] = Contact(count, _name, _phone);
    }
}