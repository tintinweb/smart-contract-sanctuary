//SPDX-License-Identifier: MIT
import "Ownable.sol";
import "SafeMath.sol";

pragma solidity ^0.8.0;

contract FlipContract is Ownable {
    
    using SafeMath for uint256;

    uint public ContractBalance;
    uint public fee;

    event bet(address indexed user, uint indexed bet, uint fee, bool indexed win, uint8 side);
    event funded(address owner, uint funding);

    constructor(uint _fee) 
    payable
    {
        ContractBalance = msg.value;
        fee = _fee;
    }

    // Function to simulate coin flip 50/50 randomnes
    function flip(uint8 side) public payable returns(bool win){
        require(address(this).balance >= msg.value.mul(2), "The contract hasn't enought funds");
        require(msg.value > fee, "The amount of value is too low, has to be bigger than fee");
        require(side == 0 || side == 1, "Incorrect side, needs to be 0 or 1");
        uint calculatedFee = (msg.value/100) * fee;
        if(block.timestamp % 2 == side){
            ContractBalance -= msg.value - calculatedFee;
            payable(msg.sender).transfer((msg.value * 2) - calculatedFee);
            win = true;
        }
        else{
            ContractBalance += msg.value;
            win = false;
        }
        emit bet(msg.sender, msg.value, calculatedFee, win, side);
    }
    // Function to Withdraw Funds
    function withdrawAll() public onlyOwner returns(uint){
        payable(msg.sender).transfer(address(this).balance);
        assert(address(this).balance == 0);
        return address(this).balance;
    }
    // Function to get the Balance of the Contract
    function getBalance() public view returns (uint) {
        return ContractBalance;
    }
    // Fund the Contract
    function fundContract() public payable onlyOwner {
        require(msg.value != 0);
        ContractBalance = ContractBalance.add(msg.value);
        emit funded(msg.sender, msg.value);
        assert(ContractBalance == address(this).balance);
    }
    //Set fee to flip coin
    function setFee(uint _fee) public onlyOwner {
        fee = _fee;
    }
}