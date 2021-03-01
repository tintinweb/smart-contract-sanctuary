/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.7.4;

interface Bank{
    function create_new_account(address user0) external;
    function transfer_funds(address, uint) external;
    function transfer_funds(uint receiver_id, uint amount) external;
    function view_account_balance(uint256) external view returns(uint); 
}

struct Account{
    address account_holder;
    uint account_balance;
}

contract Bank_Accounts is Bank{
    /*Need to specify that Bank_Accounts uses the interface Bank.*/
    address public BANK_OWNER;
    uint number_of_accounts;
    Account[] accountLedger;

    mapping(address => uint256) public id;


    constructor()
    { 
        BANK_OWNER = msg.sender;

        number_of_accounts = 3;
        accountLedger.push();
    }

    function create_new_account(address user0) external override
    {
        require(msg.sender == BANK_OWNER);
        require(id[user0] == 0);
        
        number_of_accounts += 3;
        id[user0] = number_of_accounts;
      
        accountLedger.push();
 
        accountLedger[ number_of_accounts ].account_holder = user0;
        accountLedger[ number_of_accounts ].account_balance = 500;
    }
    
    function transfer_funds(address receiver, uint amount) external override
    {
        require( id[msg.sender] > 0);
        require( id[msg.sender] <= number_of_accounts);
        
        require( id[receiver] > 0);
        require( id[receiver] <= number_of_accounts);
        
        require(accountLedger[ id[msg.sender] ].account_balance >= amount);

        accountLedger[ id[msg.sender] ].account_balance -= amount;
        accountLedger[ id[receiver] ].account_balance += amount;
    }
    
    function transfer_funds(uint receiver_id, uint amount) external override
    {
        require( id[msg.sender] > 0);
        require( id[msg.sender] <= number_of_accounts);
        
        require( receiver_id > 0);
        require( receiver_id <= number_of_accounts);
       
        require(accountLedger[ id[msg.sender] ].account_balance >= amount);

        accountLedger[ id[msg.sender] ].account_balance -= amount;
        accountLedger[ receiver_id ].account_balance += amount;
    }    
    
    function view_account_balance(uint256 account) external view override returns(uint amt)
    {
        require( account > 0);
        require( account <= number_of_accounts);
        
        amt = accountLedger[ account ].account_balance;
    }

    
}