/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.7.4;

struct Account{
    address account_holder1;
    address account_holder2;
    address account_holder3;
    uint account_balance;
}

contract Bank_Accounts{
    
    address public BANK_OWNER;
    uint number_of_accounts;
    Account[] accountLedger;
    
    mapping(address => uint256) public id;
    
    constructor()
    {
        BANK_OWNER = msg.sender;
        
        number_of_accounts = 0;
        accountLedger.push();
    }
    
    modifier onlyOwner {
        require (BANK_OWNER == msg.sender);
        _;
    }
    
    modifier hasAccount {
        require (id[msg.sender] > 0);
        require (id[msg.sender] <= number_of_accounts);
        _;
    }
    
    function create_new_account(address user0) onlyOwner public
    {
        require (id[user0] == 0);
        
        number_of_accounts += 1;
        
        id[user0] = number_of_accounts;
        
        accountLedger.push();
        accountLedger[ number_of_accounts ].account_holder1 = user0;
        accountLedger[ number_of_accounts ].account_holder2 = user0;
        accountLedger[ number_of_accounts ].account_holder3 = user0;
        accountLedger[ number_of_accounts ].account_balance = 500;
    }
    
    function transfer_funds(address receiver, uint amount, bool vote1, bool vote2, bool vote3) hasAccount public
    {
        require( id[receiver] > 0);
        require( id[receiver] <= number_of_accounts);
        
        require(accountLedger[ id[msg.sender] ].account_balance >= amount);
        
        //the 3 votes are inputs from the 3 account holders
        //if the majority vote yes, then the fund transfer goes through
        
        uint intVote1 = vote1 ? 1 : 0;
        uint intVote2 = vote2 ? 1 : 0;
        uint intVote3 = vote3 ? 1 : 0;
        
        if(intVote1 + intVote2 + intVote3 >= 2){
            accountLedger[ id[msg.sender] ].account_balance -= amount;
            accountLedger[ id[receiver] ].account_balance += amount;
        }
    }
    
    function transfer_funds(uint receiver_id, uint amount, bool vote1, bool vote2, bool vote3) hasAccount public
    {
        require( receiver_id > 0);
        require( receiver_id <= number_of_accounts);
        
        require(accountLedger[ id[msg.sender] ].account_balance >= amount);
        
        uint intVote1 = vote1 ? 1 : 0;
        uint intVote2 = vote2 ? 1 : 0;
        uint intVote3 = vote3 ? 1 : 0;
        
        if(intVote1 + intVote2 + intVote3 >= 2){
            accountLedger[ id[msg.sender] ].account_balance -= amount;
            accountLedger[ receiver_id ].account_balance += amount;
        }
    }
    
    function view_account_balance(uint256 account) public
    view returns(uint amt)
    {
        require( account > 0);
        require( account <= number_of_accounts);
        
        amt = accountLedger[ account ].account_balance;
    }
    
}