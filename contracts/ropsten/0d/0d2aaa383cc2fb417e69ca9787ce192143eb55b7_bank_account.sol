/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

 //account set up
 struct users{
        address user1; //account holder 1
        address user2; //account holder 2
        address user3; //account holder 3
        uint acc_balance; //balance of the account
    }
    
 //proposal records per member with address receiver
    struct my_Proposal{
        uint amount; //amount to send
        bool vote; //has voted or not
        address receiver; //receiver of the transfer
        uint id; //account number of a receiver
        uint votes; // number of votes of the proposal
    }
 
    //proposal records per account with address receiver
    struct acc_Proposal{
        
        address sender; //the proposer
        address receiver; //the receiver of the transfer
        
        uint receiver_id; //account number of a receiver
        uint amount; //the amount to send
        uint votes; //number of votes of the proposal
    }
  
    
contract bank_account {
   
    
       address public minter;  //the bank account owner
       mapping (uint => uint) public balances; //map each account number to their balances
       mapping(address => uint) public id; //map each member to their account number
       mapping(address => my_Proposal)  my_proposal; //map each member by their recorded proposal with address receiver
       mapping(uint => acc_Proposal) public acc_proposal; //map each account number by their recorded proposal with address receiver
       
       users[] public accounts;
       uint num_accounts;

    // Constructor code is only run when the contract
    // is created
     constructor() {
        minter = msg.sender; //set the owner as the deployer
        accounts.push(); //initialize the array accounts
        num_accounts=0; //no account yet
        }
        
        //Create new account
        
        function CreateAccount (address _user1, address _user2, address _user3, uint amount) public {
              require (msg.sender==minter, "Only minter can call this.");   //Only the owner can create
              require(id[_user1]==0 && id[_user2]==0 &&id[_user3]==0);      //all of the new members doesn't have account 
              require(_user1!=_user2 && _user1!=_user3 && _user2!=_user3);  //different three holders
              require(amount < 1e60);                                       //maximum money that the account could hold
              num_accounts+=1;                                              //increase number of accounts, since a new one will be created
              id[_user1]=num_accounts;                                       // 3 holders have the same account number
              id[_user2]=num_accounts;
              id[_user3]=num_accounts;
              accounts.push();
              accounts[num_accounts].user1=_user1;
              accounts[num_accounts].user2=_user2;
              accounts[num_accounts].user3=_user3;
              accounts[num_accounts].acc_balance+=amount;
              balances[num_accounts]+=amount;
        }
        
        //propose a transaction with an address of a member of an account
         function Propose_transfer(address receiver, uint amount) public{
            require( id[msg.sender] > 0);                            //receiver and sender must have an account
            require( id[msg.sender] <= num_accounts);
            require( id[receiver] > 0);
            require( id[receiver] <= num_accounts);
            require(accounts[id[msg.sender]].acc_balance >= amount); //account balance of the sender need to be higher than the amount he wanna send
            my_proposal[msg.sender].vote=true;                      // the sender has voted his proposal
            my_proposal[msg.sender].votes=1;                        //the proposal has 1 vote
            my_proposal[msg.sender].amount=amount;                  //set the amount and the receiver of the proposal
            my_proposal[msg.sender].receiver=receiver;
            my_proposal[msg.sender].id=id[receiver];
            acc_proposal[id[msg.sender]].votes=1;                   //record number of votes as 1, amount, the sender  and the receiver in the account proposal
            acc_proposal[id[msg.sender]].amount=amount;
            acc_proposal[id[msg.sender]].sender=msg.sender;
            acc_proposal[id[msg.sender]].receiver=receiver;
            acc_proposal[id[msg.sender]].receiver_id=id[receiver];
            
            }
            
            //propose transaction with an account number
              function Propose_transfer(uint _id, uint amount) public{
               require( id[msg.sender] > 0);                            //receiver and sender must have an account
            require( id[msg.sender] <= num_accounts);
            require( _id > 0);
            require( _id <= num_accounts);
            require(accounts[id[msg.sender]].acc_balance >= amount); //account balance of the sender need to be higher than the amount he wanna send
            my_proposal[msg.sender].vote=true;                      // the sender has voted his proposal
            my_proposal[msg.sender].votes=1;                        //the proposal has 1 vote
            my_proposal[msg.sender].amount=amount;                  //set the amount and the receiver of the proposal
            my_proposal[msg.sender].id=_id;
            my_proposal[msg.sender].receiver=accounts[_id].user1;
            acc_proposal[id[msg.sender]].votes=1;                   //record number of votes as 1, amount, the sender  and the receiver in the account proposal
            acc_proposal[id[msg.sender]].amount=amount;
            acc_proposal[id[msg.sender]].sender=msg.sender;
            acc_proposal[id[msg.sender]].receiver_id=_id;
            acc_proposal[id[msg.sender]].receiver=accounts[_id].user1;
            
            }
            
      //to approve a proposed transaction
        function Transfer_approval() public {
            require( id[msg.sender] > 0);               //approver must have an account
            require( id[msg.sender] <= num_accounts);
            require( my_proposal[msg.sender].vote == false);   //approver hasn't already voted 
            acc_proposal[id[msg.sender]].votes+=1;              // increase the number of votes of the proposal in the account proposal and proposer's proposal
            my_proposal[acc_proposal[id[msg.sender]].sender].votes+= 1; 
            my_proposal[msg.sender].vote=true;         //record that the approver has been voted
        }
        
        //to execute a proposed transaction for an address receiver
        function Transfer_funds() public  {
             require( id[msg.sender] > 0);             //the sender must have an account
            require( id[msg.sender] <= num_accounts);
            require(my_proposal[msg.sender].votes>=2);  //the number of votes of the proposer must at least be 2
            accounts[ id[msg.sender] ].acc_balance -= acc_proposal[id[msg.sender]].amount;          //reduce the account balance of the sender by the sended amount
            accounts[ id[acc_proposal[id[msg.sender]].receiver] ].acc_balance += acc_proposal[id[msg.sender]].amount; //increase the account balance of the receiver by the sended amount
            balances[id[msg.sender]]=accounts[ id[msg.sender] ].acc_balance;      //record the new balances
            balances[id[acc_proposal[id[msg.sender]].receiver]]= accounts[ id[acc_proposal[id[msg.sender]].receiver] ].acc_balance;
            my_proposal[msg.sender].votes =0;     //reinitiate the proposal statutes
            my_proposal[msg.sender].amount =0;
            my_proposal[msg.sender].vote =false;
            my_proposal[msg.sender].receiver =address(0);
            my_proposal[msg.sender].id =0;
            acc_proposal[id[msg.sender]].votes =0;
            acc_proposal[id[msg.sender]].receiver =address(0);
            acc_proposal[id[msg.sender]].receiver_id=0;
            acc_proposal[id[msg.sender]].amount =0;
            acc_proposal[id[msg.sender]].sender =address(0);
            
            }
      
            //to view the latest proposal statutes (need to send one proposal at a time otherwise it will overwritten)
         function My_proposal() external view returns (uint  amount,  address receiver,  uint  receiver_id,uint votes, bool voted) {
            require( id[msg.sender] > 0);     
            require( id[msg.sender] <= num_accounts);
           amount= my_proposal[msg.sender].amount;
           votes= my_proposal[msg.sender].votes;
           receiver= my_proposal[msg.sender].receiver;
           receiver_id= my_proposal[msg.sender].id;
           voted= my_proposal[msg.sender].vote;
           
         }
}