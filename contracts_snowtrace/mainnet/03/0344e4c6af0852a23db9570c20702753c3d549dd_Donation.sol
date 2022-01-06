/**
 *Submitted for verification at snowtrace.io on 2022-01-06
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
contract Donation {
    address payable owner;
    uint delay = block.timestamp;
    uint i = 0;
    address payable recipient;
    address[] donators;
    mapping (address => uint) private donatorsToNumbers;
    mapping (address => uint) private donatorsToSums;

    constructor() {
        owner = payable(msg.sender);
    }

    function Donate() public payable {
        require(msg.value > 0, "the donation must be greater than 0!");
        donators.push(msg.sender);
        donatorsToNumbers[msg.sender] = i;
        donatorsToSums[msg.sender] = msg.value;
        i++;
    }

    function refundDonation() public payable {
        require(donatorsToSums[msg.sender] > 0, "You are not even donator!");
        donatorsToSums[msg.sender] = 0;
        donators[donatorsToNumbers[msg.sender]] = address(0);
    }

    function WithdrawMoneyTo() public payable onlyOwner 
    {   
        require(recipient != address(0), "Set recipient!");
        recipient.transfer(address(this).balance);
    }

    function getTotalAmountOfDonations() view public returns(uint){
        return address(this).balance;
    }

    function getAllDonators() view public returns(address[] memory) {
        return donators;
    }

    function getMyDonation() view public returns(uint) {
        return donatorsToSums[msg.sender];
    }

    function setRecipient(address payable _recipient) public onlyOwner {
        require(block.timestamp > delay, "It's been less than an hour!");
        delay = block.timestamp + 3600;
        recipient = _recipient;
    }

    function getOwner() view public returns(address) {
        return owner;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Yor're not the owner!");
        _;
    }

}