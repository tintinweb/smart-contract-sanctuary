/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.7.4;
  
  struct Account {
      address account_holder1;
      address account_holder2;
      address account_holder3;
      uint account_balances;
      uint vote;
      bool[4] voted;
      address receiver;
      uint amount;
  }
  
  contract Bank_Accounts {
      address public Bank_Owner;
     /* address member1;
      address member2;
      address member3;*/
      uint number_of_accounts;
      Account[] accountLedger;
      mapping (address => uint256) public id;
      mapping (address => uint256) public order;
      constructor()
      {
          Bank_Owner = msg.sender;
          number_of_accounts = 0;
          accountLedger.push();
      }
      
     modifier onlyOwner{
         require(Bank_Owner == msg.sender);
         _;
     } 
     
     modifier hasAccount{
         require(id[msg.sender] > 0);
         require(id[msg.sender] <= number_of_accounts);
         _;
     }
     
     function create_new_account(address user0, address user1, address user2) onlyOwner public
     {
         require(id[user0] == 0);
         require(id[user1] == 0);
         require(id[user2] == 0);
         number_of_accounts += 1;
         id[user0] = number_of_accounts;
         id[user1] = number_of_accounts;
         id[user2] = number_of_accounts;
         accountLedger.push();
         accountLedger[number_of_accounts].account_holder1 = user0;
         accountLedger[number_of_accounts].account_holder2 = user1;
         accountLedger[number_of_accounts].account_holder3 = user2;
         accountLedger[number_of_accounts].account_balances = 500;
         order[user0] = 1;
         order[user1] = 2;
         order[user2] = 3;
     }
     
     function propose_transfer(address receiver, uint amount) hasAccount public
     {
         require(id[receiver] > 0);
         require(id[receiver] <= number_of_accounts);
         require(accountLedger[id[msg.sender]].account_balances >= amount);
         accountLedger[id[msg.sender]].voted[1] =  false;
         accountLedger[id[msg.sender]].voted[2] =  false;
         accountLedger[id[msg.sender]].voted[3] =  false;
         accountLedger[id[msg.sender]].voted[order[msg.sender]] = true;
         accountLedger[id[msg.sender]].vote = 1;
         accountLedger[id[msg.sender]].receiver = receiver;
         accountLedger[id[msg.sender]].amount = amount;
     }
     
     function approve_transer() hasAccount public
     {
         require(accountLedger[id[msg.sender]].voted[order[msg.sender]] == false);
         accountLedger[id[msg.sender]].vote += 1;
         accountLedger[id[msg.sender]].voted[order[msg.sender]] = true;
     }
     
     function transfer_funds() hasAccount public
     {
         require(id[accountLedger[id[msg.sender]].receiver] > 0);
         require(id[accountLedger[id[msg.sender]].receiver] <= number_of_accounts);
         require(accountLedger[id[msg.sender]].account_balances >= accountLedger[id[msg.sender]].amount);
         require(accountLedger[id[msg.sender]].vote >= 2);
         accountLedger[id[msg.sender]].account_balances -= accountLedger[id[msg.sender]].amount;
         accountLedger[id[accountLedger[id[msg.sender]].receiver]].account_balances += accountLedger[id[msg.sender]].amount;
     }
     
     
     function view_account_balance(uint256 account) public view returns(uint amt)
     {
         require(account > 0);
         require(account <= number_of_accounts);
         amt = accountLedger[account].account_balances;
     }
     
  }