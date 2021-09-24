/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.3 and less than 0.9.0
pragma solidity ^0.8.3;

contract BankContract {
    
    struct client_account {
        int client_id;
        address client_address;
        uint client_balance_in_ether;
    }
    
    client_account[] public clients;
    
    int clientCounter = 0;
    
    // address an variable for the manager
    address payable manager;
    // last interest date of each client
    mapping(address => uint) public interestDate;
    
    
    // constructor() public {
    //     clientCounter = 0;
    // }
    
   
    
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call!");
        _;
    }
    
    modifier onlyClients() {
        bool isClient = false;
        for (uint i = 0; i < clients.length; i ++) {
            if(clients[i].client_address == msg.sender) {
                isClient = true;
                break;
            }
        }
        
        require(isClient, "Only clients can call!");
        _;
        
    }
    
    receive() external payable { }
    
    
    function setManager(address managerAddress) public returns (string memory) {
        manager = payable(managerAddress);
        return "";
    } 
    
    
    function joinAsClient() public payable returns(string memory){
        interestDate[msg.sender] = block.timestamp;
        clients.push(client_account(clientCounter++, msg.sender, address(msg.sender).balance));
        return "";
    }
    
    function deposit() public payable onlyClients {
        payable(address(this)).transfer(msg.value);
    }
    
    // function withdraw(uint amount) public payable onlyClients {
    //     msg.sender.transfer(amount * 1 ether);
    // }
    
    function sendInterest() public payable onlyManager{
        for(uint i = 0; i < clients.length; i ++){
            address initialAddress = clients[i].client_address;
            uint lastInterestDate = interestDate[initialAddress];
            if(block.timestamp < lastInterestDate + 10 seconds){
                revert("It's just been less than 10 seconds!");
            }
            payable(initialAddress).transfer(1 ether);
            interestDate[initialAddress] = block.timestamp;
        }
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
}