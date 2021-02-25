/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

/*
Author: Marvin Jones
File: bank_accounts.sol
Class: MATH 9850
Homework 3 - Problem 1

Description:
Create a smart contract for managing joint bank accounts. The example
from class handles accounts with one user only. Your contract should
manage accounts with three users. Each account can send out payments
only when the majority (i.e. 2) of the bank account owners agree.

Assumptions:
- The address that deploys the contract is the Bank Owner and CANNOT
    be an account holder.
- One address can only be associated to ONE bank account.
- Each bank account can only ONE transfer proposal at a time.

Implementation choices:
- uint instead of specific uintx types.
*/

    /* For testing purposes:
    0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
    0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    */


/*
This line of code specifies what version of solidity
this code can be compiled using.
This line is critical, and must be paid attention
to when reading codes online.
*/
pragma solidity ^0.7.4;


/*
Commented out since interface cannot have modifiers
*/

/*
interface Bank{
    function create_new_account(address, address, address, uint) onlyOwner public;
    function propose_new_transaction(address, uint) hasAccount public;
    function approve_transaction() hasAccount public;
    function make_transfers() private;
    function view_proposed_transaction(uint256) public view returns(uint256, uint, uint);
    function view_account_balance(uint256) public view returns(uint);
}*/


struct Account{
/* This is all of the data associated
 to a given bank account.*/
 
    address account_holder0;
    address account_holder1;
    address account_holder2;
    
    uint account_balance;
    
    Proposal proposed_transfer;
}

struct Proposal{
/*Contains all of the data associated for
a transfer proposal.*/
    uint256 recipient; //Account number for funds to be sent to.
    uint transfer_amount;

    uint vote_count;
    bool[3] voted;
    /* Voting: True = in favor, False = against.*/
}

contract Bank_Accounts{ //is Bank{
    
    address public BANK_OWNER;
    uint VOTE_APPROVAL_THRESHOLD = 2;
    
    uint number_of_accounts;
    Account[] accountLedger;
    
    /*id associates address (of account holder) to uint to be used in accountLedger*/
    mapping(address => uint256) public id;
    mapping(address => uint8) private account_holder_order;
    
    constructor(){ 
        BANK_OWNER = msg.sender;
        
        /*Banks initialize with no accounts*/
        number_of_accounts = 0;
        accountLedger.push();
    }
    
    /* Modifiers: These can improve security and readability of
    the smart contract.
    Security - less likely to make an error in repetitive code.
    Readability - Makes clear what addresses can call certain functions.
    */
    modifier onlyOwner {
        require(BANK_OWNER == msg.sender);
        _;
    }
    
    modifier hasAccount
    {
        /*Verifies that the uint256 corresponding to 
        an address (under the id mapping) is within
        the range of [1..number_of_accounts]*/
        require( id[msg.sender] > 0);
        require( id[msg.sender] <= number_of_accounts);
        _;
   }
   
    /* BANK_OWNER is the only address that has the authority to create a new account.
    Requires: distinct addresses for account holders (user0, user1, user2).
              starting balance amount.*/
    function create_new_account(address user0, address user1, address user2, uint amount) /*onlyOwner*/ public 
    {
        number_of_accounts += 1;
        
        /*Sets all three account holders' id to correspond
        to the same number_of_accounts*/
        id[user0] = number_of_accounts;
        id[user1] = number_of_accounts;
        id[user2] = number_of_accounts;
      
        account_holder_order[user0] = 0;  
        account_holder_order[user1] = 1;
        account_holder_order[user2] = 2;
      
        /*Creates a new entry to accountLedger - critical 
        for dynamic array.*/
        accountLedger.push(); 
        accountLedger[ number_of_accounts ].account_holder0 = user0;
        accountLedger[ number_of_accounts ].account_holder1 = user1;
        accountLedger[ number_of_accounts ].account_holder2 = user2;
        accountLedger[ number_of_accounts ].account_balance = amount;
    }
    
    /*Proposes a new transaction from one account to another.
    This function verifies that each address is that of ones that are account holders.
    Does not check to see if proposed transaction exceeds balance, and
    does not check to see if the proposed transaction would be the same account
    paying itself.*/
    function propose_new_transaction(address receiver, uint amount) hasAccount public
    {
        /*Verifies the receiver address is an account holder with an 
        existing account. Same code as the modifier hasAccount*/
        require( id[receiver] > 0);
        require( id[receiver] <= number_of_accounts);    
        
        //Resets voted for a new transaction.
        accountLedger[ id[msg.sender] ].proposed_transfer.vote_count = 0;
        
        accountLedger[ id[msg.sender] ].proposed_transfer.voted[0] = false;
        accountLedger[ id[msg.sender] ].proposed_transfer.voted[1] = false;
        accountLedger[ id[msg.sender] ].proposed_transfer.voted[2] = false;
        
        accountLedger[ id[msg.sender] ].proposed_transfer.recipient = id[receiver];
        accountLedger[ id[msg.sender] ].proposed_transfer.transfer_amount = amount;
        
        /*Assumes the account holder that proposes a transaction will vote for it.*/
        accountLedger[ id[msg.sender] ].proposed_transfer.voted[ account_holder_order[msg.sender] ] = true;
        accountLedger[ id[msg.sender] ].proposed_transfer.vote_count = 1;
    }
    
    /*Account holder (msg.sender) votes for the proposed transfer associated to their account.*/
    function approve_transaction() hasAccount public
    {
        /*Verifies that the account holder has not already voted for the proposed transfer.*/
        require(accountLedger[ id[msg.sender] ].proposed_transfer.voted[ account_holder_order[msg.sender] ] == false);
        
        accountLedger[ id[msg.sender] ].proposed_transfer.voted[ account_holder_order[msg.sender] ] = true;        
        accountLedger[ id[msg.sender] ].proposed_transfer.vote_count +=1; 
        
        /*Valid since second vote occurred*/
        make_transfers();
    }
    
    function make_transfers() private
    {
        require(accountLedger[ id[msg.sender] ].proposed_transfer.vote_count >= VOTE_APPROVAL_THRESHOLD);
        require(accountLedger[ id[msg.sender] ].account_balance >= accountLedger[ accountLedger[ id[msg.sender]].proposed_transfer.recipient ].proposed_transfer.transfer_amount);

        uint withdraw;        
        withdraw = accountLedger[ id[msg.sender] ].proposed_transfer.transfer_amount;
        accountLedger[ id[msg.sender] ].proposed_transfer.transfer_amount = 0;
   
        accountLedger[ id[msg.sender] ].account_balance -= withdraw;
        accountLedger[ accountLedger[ id[msg.sender]].proposed_transfer.recipient ].account_balance += withdraw;
    }
    
    function view_proposed_transaction(uint256 account) public view returns(uint256 _to, uint amt, uint _votes)
    {
        require( account > 0);
        require( account <= number_of_accounts);
        
        _to = accountLedger[ account ].proposed_transfer.recipient;
        amt = accountLedger[ account ].proposed_transfer.transfer_amount;
        _votes = accountLedger[ account ].proposed_transfer.vote_count;
    }
    
    function view_account_balance(uint256 account) public view returns(uint amt)
    {
        require( account > 0);
        require( account <= number_of_accounts);
        
        amt = accountLedger[ account ].account_balance;
    }

    
}