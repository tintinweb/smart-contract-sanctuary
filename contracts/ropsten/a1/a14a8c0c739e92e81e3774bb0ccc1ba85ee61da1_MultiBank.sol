/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title MultiBank
 * This contract was inspired by the 3_Ballot.sol provided by remix (default implementation)
 * This was a collaboration between Carson Wood, Kavin Shah, and Scott Driggers
 * We also referenced solidity-by-example.org for syntax related to sending funds
 *
 * We know that there are race conditions in our code, but this is beyond the scope of this problem.
 */
contract MultiBank {

    struct Account{
        uint256 id;
        address user1;
        address user2;
        address user3;
        uint256 bal;
    }

    struct Proposal {
        address author; 
        address payable receiver;   
        uint256 amount; 
        uint256 account;
    }
    
    Account [] accounts;
    Proposal[] proposals;
   
    constructor(){}
   
   function create_account(uint256 account_id, address u1, address u2, address u3) public{
       for(uint i = 0; i < accounts.length; i++) {
            require(account_id != accounts[i].id, "Account ID already taken"); 
       }
       accounts.push(
           Account({
                id: account_id,
                user1: u1,
                user2: u2,
                user3: u3,
                bal: 0
           })
           );
   }
   
    function deposit(uint256 account_id) public payable {
        for(uint i = 0; i < accounts.length; i++){
            if (account_id == accounts[i].id){
                accounts[i].bal += msg.sender.balance;
            }
        }
    }
   
    function removeProposal(address r, uint256 a, uint256 account_id) public {
        for(uint j = 0; j < proposals.length; j++){
            if(proposals[j].receiver == r && proposals[j].amount == a && proposals[j].account == account_id){
                require(proposals[j].author == msg.sender, "Cannot remove other authors proposals");
                proposals[j] = proposals[proposals.length-1];
                proposals.pop();
                return;
            }
        }
        require(false, "No proposal found");
    }

    function addProposal(address payable r, uint256 a, uint256 account_id) public {
        bool acc_exists = false;
        uint acc_index = 0;
        for (uint i=0; i<accounts.length; i++){
            if (account_id == accounts[i].id){
                require(msg.sender == accounts[i].user1 || msg.sender == accounts[i].user2 || msg.sender == accounts[i].user3, "Has no right to propose");
                acc_exists = true;
                acc_index = i;
            }
        }
        require(acc_exists, "Account does not exist");
        
        for (uint j = 0; j < proposals.length; j++){
            if (proposals[j].receiver == r && proposals[j].amount == a && proposals[j].account == account_id){
                require(proposals[j].author != msg.sender, "Already submitted this proposal");
                require(a <= accounts[acc_index].bal, "Insufficient funds");
                (bool success,) = r.call{value: a}("");
                require(success, "Failed to send Ether");
                accounts[acc_index].bal += -a;
                
                proposals[j] = proposals[proposals.length-1];
                proposals.pop();
                return;
            }
        }
        
        proposals.push(
            Proposal({
                author: msg.sender,
                receiver: r,
                amount: a,
                account: account_id
            })
        );

    }
}