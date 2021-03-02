/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: NONE
/*--------------------------------------------
 hw3 
 Chunpeng Shao
 MATH 9850 SPRING 2021
---------------------------------------------
*/
pragma solidity ^0.7.4;


struct Account{
    address usr0;
    address usr1;
    address usr2;
    uint balance;
    Vote[] votes;
    uint payment_no;
}

struct Vote{
    uint vote0; //each user votes
    uint vote1;
    uint vote2;
    uint vote_total; //see if majority agrees
    uint dst;
    uint amount;
}

contract Bank{
    address public Bank_Owner;
    Account[] accounts;
    uint number_of_account;
    
    mapping(address => uint256) public id;

    constructor(){
        Bank_Owner = msg.sender;
        number_of_account = 0;
        id[msg.sender] = 0;
        accounts.push();
    }
    
    modifier isOwner{
        require(msg.sender == Bank_Owner, "Permission Denied");
        _;
    }
    
    modifier isUser{
        require(id[msg.sender]>2,"Owner Not Allowed");
        require(id[msg.sender]<= number_of_account*3+2, "user unidentified");
        _;
    }
    

    
    //joint account creation
    function create_account(address usr0, address usr1, address usr2) external isOwner returns(uint account_number) {
        accounts.push();
        number_of_account += 1;
        accounts[number_of_account].usr0 = usr0;
        accounts[number_of_account].usr1 = usr1;
        accounts[number_of_account].usr2 = usr2;
        id[usr0] = number_of_account *3 ;
        id[usr1] = number_of_account *3 + 1;
        id[usr2] = number_of_account *3 + 2;
        accounts[number_of_account].balance = 500; //initial balance;
        accounts[number_of_account].payment_no = 0;
        accounts[number_of_account].votes.push();
        
        account_number = number_of_account;
    }
    
    function create_payment(address usr, uint dst, uint amount) external isUser returns(uint acc, uint payment_index){
        require(id[usr]<number_of_account*3+2, "invalid user");
        require(dst < number_of_account, "invalid receiver");
        require(accounts[id[usr]/3].balance >= amount, "insufficient balance");
        acc = id[usr]/3;
        accounts[acc].votes.push();
        accounts[acc].payment_no += 1;
        payment_index = accounts[acc].payment_no;
        if(id[usr]%3 == 0){
            accounts[acc].votes[payment_index].vote0 = 1;
        } else if(id[usr]%3 == 1){
            accounts[acc].votes[payment_index].vote1 = 1;
        } else if(id[usr]%3 == 2){
            accounts[acc].votes[payment_index].vote2 = 1;
        }
        accounts[acc].votes[payment_index].dst = dst;
        accounts[acc].votes[payment_index].amount = amount;
        payment_index = accounts[acc].payment_no;
    }
    
    function vote_payment(address usr, uint payment_index) external isUser {
        require(id[usr]<number_of_account*3+2, "invalid user");
        require(payment_index<=2,"invalid payment index");
        uint acc = id[usr]/3;
        if(id[usr]%3 == 0){
            accounts[acc].votes[payment_index].vote0 = 1;
        } else if(id[usr]%3 == 1){
            accounts[acc].votes[payment_index].vote1 = 1;
        } else if(id[usr]%3 == 2){
            accounts[acc].votes[payment_index].vote2 = 1;
        }
        
        accounts[acc].votes[payment_index].vote_total = 
        accounts[acc].votes[payment_index].vote0 +
        accounts[acc].votes[payment_index].vote1 +
        accounts[acc].votes[payment_index].vote2;
        
        approve_payment(acc,payment_index);
        
    }
    
/*    function execute_payment(uint src, uint dst, uint amount) private{
        accounts[src].balance -= amount;
        accounts[dst].balance += amount;
    }
*/  
    event execute_payment(uint src, uint dst, uint amount);
    
    function approve_payment(uint acc, uint payment_index) private {
        if (accounts[acc].votes[payment_index].vote_total >= 2){
            require(accounts[acc].balance >= accounts[acc].votes[payment_index].amount, "insufficient balance");
            uint dst = accounts[acc].votes[payment_index].dst;
            uint amount = accounts[acc].votes[payment_index].amount;
            
            accounts[acc].balance -= accounts[acc].votes[payment_index].amount;
            accounts[dst].balance += accounts[acc].votes[payment_index].amount;
            emit execute_payment(acc,dst,amount);
        }
    }
    
    
    
    // utils
    function find_account(address usr) external view returns(uint account){
        account = id[usr]/3;
    }
    
    function add_balance(uint account_number, uint add_amount) external isOwner returns(uint balance){
        accounts[account_number].balance += add_amount;
        balance = accounts[account_number].balance;
    }
    
    function getBalance(uint account_number) external view returns(uint balance){
        balance = accounts[account_number].balance;
    }
    
}