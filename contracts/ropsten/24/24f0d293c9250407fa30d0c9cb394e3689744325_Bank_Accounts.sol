/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

/*
Author: Marvin Jones
File: Bank_Account_fin.sol
Class: MATH 9850
Homework 3 - Problem 1

Assumption: The only assumption that this contract
makes is that each account can only have a single
transfer proposal at a time.
*/

    /* For testing purposes: (JavaScript VM)
    0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,1`
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,2
    0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,3
    0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,4
    0x617F2E2fD72FD9D5503197092aC168c91465E7f2,5
    0x17F6AD8Ef982297579C203069C1DbfFE4348c372,6
    0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,7
    0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,8
    */

pragma solidity ^0.7.4;

struct Account{
    uint256 account_holder1;
    uint256 account_holder2;
    uint256 account_holder3;
    uint8   account_salt;
    
    uint account_balance;
    
    Proposal proposed_transfer;
}

struct Proposal{
/*Contains all of the data associated for
a transfer proposal.*/
    uint256 recipient; //Account number for funds to be sent to.
    uint transfer_amount;

    uint vote_count;
    bool[4] voted;
    /* Voting: True = in favor, False = against.*/
}

contract Bank_Accounts{ //is Bank{
    
    address public BANK_OWNER;
    uint VOTE_APPROVAL_THRESHOLD = 2;
    
    uint number_of_accounts;
    uint number_of_users;
    
    Account[] accountLedger;
    
    mapping(address => uint256) public user_number;
    mapping(bytes32 => uint256) private account_holder_order;
    mapping(bytes32 => uint256) private account_id;
    
    /*
        Each address is given a unique user number using mapping user_number.
        
        Each Account has 3 users. account_holder_order specifies the of
        the account holders for that account (with the given salt).
        Note account_holder_order[ hash(user_number,salt)] returns
        the order for that account.
        
        Each Account is assigned an account number. This number is assigned
        by account_holder_order[hash(user_number1, user_number2, user_number3, salt)].
    */

    
    constructor(){ 
        BANK_OWNER = msg.sender;
        
        /*Banks initialize with no accounts. The 0th position 
        must be avoided.*/
        number_of_accounts = 0;
        number_of_users = 0;
        accountLedger.push();
    }
    
    modifier onlyOwner {
        require(BANK_OWNER == msg.sender);
        _;
    }
    
    modifier hasAccount
    {
        /*Verifies that the uint256 corresponding to 
        an address (under the id mapping) is within
        the range of [1..number_of_accounts]*/
        require( user_number[msg.sender] > 0);
        require( user_number[msg.sender] <= number_of_users);
        _;
   }
   
    /* BANK_OWNER is the only address that has the authority to create a new account.
    Requires: distinct addresses for account holders (user0, user1, user2).
              starting balance amount.*/
              /*
              Distinct account?
              Distinct users
              */
    function create_new_account(address user1, address user2, address user3, uint8 salt, uint amount) onlyOwner public 
    {
        /*Verifies all 3 user addresses are distinct*/
        require(user1 != user2, "Account cannot be created: repeated user address");
        require(user1 != user3, "Account cannot be created: repeated user address");
        require(user2 != user3, "Account cannot be created: repeated user address");
        
        /* Checks to see if the user addresses are already known
        to the Bank; that is, user_number[user] != 0.*/
        if(user_number[user1] == 0) //user_number[user1] has not been initialized by the Bank.
        {
            number_of_users += 1;
            user_number[ user1 ] = number_of_users;    
        }
        
        if(user_number[user2] == 0) //user_number[user2] has not been initialized by the Bank.
        {
            number_of_users += 1;
            user_number[ user2 ] = number_of_users;    
        }
        
        if(user_number[user3] == 0) //user_number[user3] has not been initialized by the Bank.
        {
            number_of_users += 1;
            user_number[ user3 ] = number_of_users;    
        }        

        /*Verifies this is in fact a new account. This group of users and salt have not
        been used together before.*/
        require( account_id[ keccak256(abi.encodePacked(user_number[user1], 
                user_number[user2], user_number[user3], salt))] == 0,
                "Account cannot be created: these user addresses and salt already exist in the system.");
   
        /*At this point it, we are confident that the Account associated to
        user1, user2, user3 and the salt is unique to the Bank. We will now
        add it to the system.*/
        number_of_accounts += 1;

        account_holder_order[ keccak256(abi.encodePacked(user1, salt) )] = 1;  
        account_holder_order[ keccak256(abi.encodePacked(user2, salt) )] = 2;
        account_holder_order[ keccak256(abi.encodePacked(user3, salt) )] = 3;
      
        account_id[ keccak256(abi.encodePacked(user_number[user1], user_number[user2],
            user_number[user3], salt))] = number_of_accounts;
      
        /*Creates a new entry to accountLedger - critical 
        for dynamic array.*/
        accountLedger.push(); 
        accountLedger[ number_of_accounts ].account_holder1 = user_number[ user1 ];
        accountLedger[ number_of_accounts ].account_holder2 = user_number[ user2 ];
        accountLedger[ number_of_accounts ].account_holder3 = user_number[ user3 ];
        accountLedger[ number_of_accounts ].account_salt = salt;
        accountLedger[ number_of_accounts ].account_balance = amount;
    }
    
    /*Proposes a new transaction from one account to another.
    This function verifies that each address is that of ones that are account holders
    of _sender.
    Does not check to see if proposed transaction exceeds balance (this check is
    performed when the transfer is approved), and
    does not check to see if the proposed transaction would be the same account
    paying itself.
    
    _receiver is the account number of the account that msg.sender wishes to 
    propose the trasnfer to.*/
    function propose_new_transaction(uint256 _sender, uint256 _receiver, uint amount) hasAccount public
    {
        uint256 acc_holder = account_holder_order[ keccak256(abi.encodePacked(msg.sender, 
                    accountLedger[_sender].account_salt))];
        
        /*Verifies that msg.sender is one of the account holders for the
        given account number (accNUM).*/
        require( (accountLedger[_sender].account_holder1 == acc_holder) ||
                 (accountLedger[_sender].account_holder2 == acc_holder) ||
                 (accountLedger[_sender].account_holder3 == acc_holder),
                 "Proposed transaction error: This address is not associated with the _sender account.");
                
        /*Verifies that _receiver account number is valid. */
        require( (0 < _receiver) && (_receiver <= number_of_accounts),
                "Proposed transaction error: invalid account number.");
                
        /*Resets proposed transaction votes information*/   
        accountLedger[ _sender ].proposed_transfer.voted[1] = false;
        accountLedger[ _sender ].proposed_transfer.voted[2] = false;
        accountLedger[ _sender ].proposed_transfer.voted[3] = false;
        
        accountLedger[ _sender ].proposed_transfer.recipient = _receiver;
        accountLedger[ _sender ].proposed_transfer.transfer_amount = amount;
        
        accountLedger[ _sender ].proposed_transfer.voted[ acc_holder ] = true;
        accountLedger[ _sender ].proposed_transfer.vote_count = 1;
    }
    
    /*Account holder (msg.sender) votes for the proposed transfer associated to their account.
    This function veries that msg.sender is an accountholder for accNUM, and
    then votes for the proposal.*/
    function approve_transaction(uint256 accNUM) hasAccount public
    {
        uint256 acc_holder = account_holder_order[ keccak256(abi.encodePacked(msg.sender, 
                    accountLedger[accNUM].account_salt))];
        
        /*Verifies that msg.sender is one of the account holders for the
        given account number (accNUM).*/
        require( (accountLedger[accNUM].account_holder1 == acc_holder) ||
                 (accountLedger[accNUM].account_holder2 == acc_holder) ||
                 (accountLedger[accNUM].account_holder3 == acc_holder),
                 "Approve_transaction error: This address is not associated with the requested account.");
        
        /* Verifies msg.sender is not double voting. */
        require(accountLedger[ accNUM ].proposed_transfer.voted[ acc_holder ] != true,
                "Approve_transaction error: This account holder has already voted for this proposed transaction.");
                 
        accountLedger[ accNUM ].proposed_transfer.voted[ acc_holder ] = true;        
        accountLedger[ accNUM ].proposed_transfer.vote_count +=1; 
        
        make_transfers( accNUM );
    }
    
    /*accNUM is the account that the transfer is from.*/
    function make_transfers(uint256 accNUM ) private
    {
        require(accountLedger[ accNUM ].proposed_transfer.vote_count >= VOTE_APPROVAL_THRESHOLD);
        require(accountLedger[ accNUM ].account_balance >=
            accountLedger[ accNUM ].proposed_transfer.transfer_amount,
            "Transfer failed. Insufficient funds.");

        uint withdraw;        
        withdraw = accountLedger[ accNUM ].proposed_transfer.transfer_amount;
        accountLedger[ accNUM ].proposed_transfer.transfer_amount = 0;
   
        accountLedger[ accNUM ].account_balance -= withdraw;
        accountLedger[ accountLedger[ accNUM ].proposed_transfer.recipient ].account_balance += withdraw;
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