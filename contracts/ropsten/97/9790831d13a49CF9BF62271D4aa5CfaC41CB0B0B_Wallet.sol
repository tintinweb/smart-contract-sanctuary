/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

contract Wallet {
    
    address owner;
    
    mapping(address => bool) public whiteList;
    mapping(address => uint) public balances;
    mapping(address => uint) public depositLog;
    mapping(address => uint) public withdrawLog;
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() isWhitelisted public payable {
        
        require(msg.value <= 100, "Please do not attack with high stakes such that others can attack as well");
        require(balances[msg.sender] == 0, "You have already deposited, please withdraw first before depositing again");
        require(depositLog[msg.sender] >= withdrawLog[msg.sender], "You have already attacked successfully, please do not attack again");
        
        balances[msg.sender] += msg.value;
        depositLog[msg.sender] += msg.value;
    }
    
    function withdraw() isWhitelisted public {
        
        require(withdrawLog[msg.sender] <= 10 * depositLog[msg.sender], "You have already taken 10 times your deposit, please do not take more");
        withdrawLog[msg.sender] += balances[msg.sender];
        
        payable(msg.sender).call{value: balances[msg.sender]}("");
        
        balances[msg.sender] = 0;
        
    }
    
    function depositOwner() public payable {
        require(msg.sender == owner);
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    
    function addWhiteList(address student) public {
        require(msg.sender == owner);
        whiteList[student] = true;
    }
    
    modifier isWhitelisted() {
        require(whiteList[msg.sender] == true, "You are not in the white list, please contract the organizers to add you to the whitelist");
        _;
    }
}