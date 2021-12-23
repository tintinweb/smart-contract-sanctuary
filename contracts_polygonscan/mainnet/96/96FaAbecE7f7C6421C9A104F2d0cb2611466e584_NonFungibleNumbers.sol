/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract NonFungibleNumbers {
    // Get the owner address
    address owner;
    // Make whoever the person that deploys the contract wants the owner
    constructor(address _owner) {owner = _owner;}
    // Create event for each new number minted
    event NewNumber(uint256 number, address minter);
    // Create event for number transfers
    event NumberTransfer(uint256 number, address sender, address receiver);
    // Mapping to check if the number was minted
    mapping(uint256 => bool) numberMinted;
    // Mapping to check numbers owned by a certain address
    mapping(address => uint256[]) ownerToNumbers;
    // Mapping to check who is the owner of a certain number
    mapping(uint256 => address) numberToOwner;
    // Mint price
    uint256 PRICE = 100000000000;
    // Declare total supply
    uint256 totalSupplyNumber = 0;
    // Change owner function
    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }
    // Mint function
    function mint(uint256 _number) public payable {
        // Require that the number isn't minted
        require(numberMinted[_number] != true, "Number already minted.");
        // Require that the price sent is enough
        require(msg.value >= PRICE, "Payment isn't enough, 0.0000001 MATIC required.");
        // Say that the number is minted
        numberMinted[_number] = true;
        // Add the number to the list of numbers owned by that address
        ownerToNumbers[msg.sender].push(_number);
        // Put the minter as the owner of that number
        numberToOwner[_number] = msg.sender;
        // Make total supply go up by 1
        totalSupplyNumber++;
        // Trigger the event of new number mint
        emit NewNumber(_number, msg.sender);
    }
    // Function to remove a certain number from an address array
    function _removeNumberFromOwner(uint256 _number, address _numberOwner) private {
        // Declare the currentIndex variable
        uint256 index;
        // Go into each one of the numbers owned bt that address
        for (uint256 x = 0; x < ownerToNumbers[_numberOwner].length; x++) {
            // If the number is exactly the one that we are searching for, stop
            if (ownerToNumbers[_numberOwner][x] == _number) {
                // The x is the index of the number we are searching for
                index = x;
                break;
            }
        }
        // Make the index of the number we want to remove be the last one
        ownerToNumbers[_numberOwner][index] = ownerToNumbers[_numberOwner][ownerToNumbers[_numberOwner].length - 1];
        // Remove the last index of the array
        ownerToNumbers[_numberOwner].pop();
    }
    // Transfer a number function 
    function transferNumber(uint256 _number, address _numberReceiver) public {
        // Check if the sender owns the number
        require(numberToOwner[_number] == msg.sender, "The number you are trying to transfer isn't yours.");
        // Remove the number from the sender's numbers
        _removeNumberFromOwner(_number, msg.sender);
        // Add the number to the receiver's numbers
        ownerToNumbers[_numberReceiver].push(_number);
        // Make the receiver the owner of the number
        numberToOwner[_number] = _numberReceiver;
        // Trigger the event of a number transfer
        emit NumberTransfer(_number, msg.sender, _numberReceiver);
    }
    // Check who is the owner of a specific number
    function numberOwnedBy(uint256 _number) public view returns (address) {
        return numberToOwner[_number];
    }
    // Check which numbers an address owns
    function addressOwnsNumbers(address _address) public view returns (uint256[] memory) {
        return ownerToNumbers[_address];
    }
    // Check how many numbers an adress owns
    function howManyNumbersOwned(address _address) public view returns (uint256) {
        return ownerToNumbers[_address].length;
    }
    // Check if a certain number is minted
    function isNumberMinted(uint256 _number) public view returns (bool) {
        if(numberMinted[_number] == true) {
            return true;
        } else {
            return false;
        }
    }
    // View total supply
    function totalSupply() public view returns (uint256) {
        return totalSupplyNumber;
    }
    // Get all the money stored in the contract
    function withdraw() public {
        require(msg.sender == owner, "You aren't the owner of this contract.");
        payable(owner).transfer(address(this).balance);
    }
}