/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma abicoder v2;
pragma solidity ^0.7.0;

contract CID {
    
    address public client;
    address public mainContractor;
    address[] public subContractors; //array of subContractor addresses
    struct Task {                   //struct for task details
        string id;
        string description;
        address assignedTo;
        uint amount;
        string dueDate;
        string status;
    }
    mapping(string => Task) public taskList;

    string public constant name = "Construction Industry - Decentralized";
    string public constant symbol = "CID";
    uint8 public constant decimals = 2;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
	client = msg.sender;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
    
    
    function mainContractorRegister() public {
        mainContractor = msg.sender;
    }
    
    function subContractorRegister() public {
        subContractors.push(msg.sender);
    }
    
    function initiateTask(string memory id, string memory description, address assignedTo, uint amount, string memory dueDate) public {
        require(msg.sender == mainContractor);
        taskList[id].id = id;
        taskList[id].description = description;
        taskList[id].assignedTo = assignedTo;
        taskList[id].amount = amount;
        taskList[id].dueDate = dueDate;
        taskList[id].status = "Payment required, yet to begin task";
    }
    
    function approveTransaction(string memory id, uint amount) public payable {
        require(msg.sender == client);
        require(taskList[id].amount == amount);
        // make the Payment
        transfer(mainContractor, amount);
        taskList[id].status = "Payment completed, task pending";
    }
    
    function requestTaskApproval(string memory id) public {
        taskList[id].status = "Request for task verification";
    }
    
    function approveTask(string memory id, uint fees) public payable {
        require(msg.sender == mainContractor);
        taskList[id].status = "Task completed and verified";
        // make the payment to the subContractor
        transfer(taskList[id].assignedTo, fees);
    }
    
    function checkTaskDetails(string memory id) public view returns (string memory, string memory, address, uint, string memory, string memory) {
        return (taskList[id].id, taskList[id].description, taskList[id].assignedTo, taskList[id].amount, taskList[id].dueDate, taskList[id].status);
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}