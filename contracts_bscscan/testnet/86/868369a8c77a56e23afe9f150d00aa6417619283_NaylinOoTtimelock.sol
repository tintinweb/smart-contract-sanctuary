/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

//SPDX-License-Identifier:MIT 


pragma solidity ^0.6.0;

contract NaylinOoTtimelock {

    address private owner;
    mapping (address => uint256) private balances;
    mapping (address => uint256) private locktime;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function deposit(uint256 lockdays) public payable {
        require(lockdays < 365);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = balance + msg.value;
        if(balance == 0) {
            locktime[msg.sender] += ( now + (lockdays * 1 days) );
        } else {
            locktime[msg.sender] += (lockdays * 1 days);
        }
    }

    function depositSeconds(uint256 lockseconds) public payable {
        require(lockseconds < 24*60*60);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = balance + msg.value;
        if(balance == 0) {
            locktime[msg.sender] += ( now + lockseconds );
        } else {
            locktime[msg.sender] += ( lockseconds );
        }
    }

    function balance() public view returns(uint){
        return balances[msg.sender];
    }

    function delay() public view returns(uint){
        return locktime[msg.sender];
    }

    function withdraw() external {
        require(balances[msg.sender] > 0,"No funds in account");
        require(block.timestamp > locktime[msg.sender],"Too soon to withdraw");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAmount(uint256 amount) external {
        require(balances[msg.sender] >= amount,"Insufficient balance");
        require(block.timestamp > locktime[msg.sender],"Too soon to withdraw");
        balances[msg.sender] -= amount;
        //require(msg.sender.send(amount));
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
    }

    event Sent(address from, address to, uint amount);
    
    function transfer(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

    //contract IsPayable {
    //  function () payable {}

}