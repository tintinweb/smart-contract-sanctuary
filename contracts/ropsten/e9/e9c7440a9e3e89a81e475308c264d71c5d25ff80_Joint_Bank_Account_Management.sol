/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

pragma solidity ^0.7.4;

struct Account{

    address account_holder_1;
    address account_holder_2;
    address account_holder_3;
    uint account_balance;
    uint signatures_for_transfer;
}

contract Joint_Bank_Account_Management{
    
    
    address public BANK_OWNER;
    uint public number_of_accounts;
    Account[] accountLedger; 

    mapping(address => uint256) public id;

    constructor(){ 
        BANK_OWNER = msg.sender;
        /* msg.sender is the address of the user that called
        this function.*/
        
        /*Banks initialize with no accounts*/
        number_of_accounts = 0;
        accountLedger.push();
    }
    
    modifier onlyOwner {
        require(BANK_OWNER == msg.sender);
       _;
    }
    
    modifier hasAccount {
        require( id[msg.sender] > 0);
        require( id[msg.sender] <= number_of_accounts);
        _;
   }
   

    function Create_New_Account(address user0, address user1, address user2) onlyOwner public
    {
        require(id[user0] == 0);
        /*Checks to see if user0 has an account. Solidity defaults
        integers at 0.*/

        number_of_accounts += 1;
                                        /*increments number_of_accounts since we are adding a new account.*/
        id[user0] = number_of_accounts; /*define the account number for user0.*/
        id[user1] = number_of_accounts;
        id[user2] = number_of_accounts;
        
        accountLedger.push();
        /*Recall that accountLedger is a dynamic array.
        To create a new entry in the dynamic array, we use accountLedger.push()
        
        At this point, the new entry's variables are default values.
        Usually the default values are 0.
        
        In the constructor we saw our first useage of .push(). Why?
        Since Solidity defaults values to 0, 
        id[unknown address] = 0 by default.
        That means, a user that does not have an account will always
        be able to access the Account[0] if we allowed it to be a valid 
        account!
        */
        
        accountLedger[ number_of_accounts ].account_holder_1 = user0;
        accountLedger[ number_of_accounts ].account_holder_2 = user1;
        accountLedger[ number_of_accounts ].account_holder_3 = user2;
        accountLedger[ number_of_accounts ].account_balance = 500;
    }
    
    function Approve_Transfer(address user1, address user2) public {//Gets signatures from account holders for transfers
        
        accountLedger[id[user1]].signatures_for_transfer = 0;
        accountLedger[id[user2]].signatures_for_transfer = 0;
       
        require(user1 != user2,
                "Must have two seperate signatures");
        
        if(accountLedger[id[user1]].account_holder_1 == user1 ||
           accountLedger[id[user1]].account_holder_2 == user1 ||
           accountLedger[id[user1]].account_holder_3 == user1) accountLedger[id[user1]].signatures_for_transfer++;
        
        if(accountLedger[id[user1]].account_holder_1 == user2 ||
           accountLedger[id[user1]].account_holder_2 == user2 ||
           accountLedger[id[user1]].account_holder_3 == user2) accountLedger[id[user1]].signatures_for_transfer++;
    }
    
    function Transfer_Funds(address sender, address receiver, uint amount) hasAccount public
    /*Transfers funds from sender to the account (by address) of their choice for a 
    specified amount.*/
    {
        require((accountLedger[id[sender]].account_holder_1 == msg.sender) ||
               (accountLedger[id[sender]].account_holder_2 == msg.sender) ||
               (accountLedger[id[sender]].account_holder_3 == msg.sender) ||
                msg.sender == BANK_OWNER,
                "You are not the owner of the sending account or the bank"); //verifies the user attempting the transfer owns the account
        
        require( id[receiver] > 0);
        require( id[receiver] <= number_of_accounts);
        /* Verifes that the receiver's address has an associated account.
        Again, if receiver does not, then id[receiver] = 0.
        */
        
        require(accountLedger[id[sender]].signatures_for_transfer == 2,
                "Account not approved for transfer. Signatures required.");
        
        require(accountLedger[ id[sender]].account_balance >= amount,
                "insufficient funds");
        /*Verifies that the sender (account accessing this function)
        has a sufficient balance to send the amount.
        If not, halt.*/

        accountLedger[ id[sender] ].account_balance -= amount;
        accountLedger[ id[receiver] ].account_balance += amount;
        
        accountLedger[id[sender]].signatures_for_transfer = 0;
    }
    
    
    function View_Account_Balance(address user) public view returns(uint amt){
        amt = accountLedger[id[user]].account_balance;
    }
    /* Allows any address (whether they have an account or not) to view
    a specific account's balance.
    */
}