/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0
// Metamask account on the reopsten test network:
// 0xF56F7eC4f9480A8d1322F28a9CCf93Cff60ba7BF
pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title JointAccount
 * @dev Implements voting process along with vote delegation
 */
contract JointAccount {
   
    
    uint[3][3] public votes;
    mapping(address => uint) public voter_addresses;
    
    // for ballot example
    //["0x6332000000000000000000000000000000000000000000000000000000000000","0x6333000000000000000000000000000000000000000000000000000000000000"]
    // for this example when clicking deploy
    //["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
    constructor (
        //address[] memory bank_accounts
        ) {
        for (uint i = 0; i < 3; i++) {
            for (uint j = 0; j < 3; j++) {
                votes[i][j] = 0;
            }
            
            //voter_addresses[bank_accounts[i]] = i;
        }
        
    }
    
    //TODO: make sure to verify amount
    /**
     * @dev Set account to index of one of three indexes 0, 1 , or 2
     * @param bank_account to set index of
     * @param index that account is to be set to
     */
    function setAccountIndex(address bank_account,uint index) public {
        //require(!sender.voted, "Already voted.");
        //voters[msg.sender][account] = currentVote;
        require(index == 0 || index == 1 || index == 2,"index must be 1, 2, and 3");
        voter_addresses[bank_account] = index;
    }
    
   
    //TODO: make sure to verify amount
    /**
     * @dev Give your vote 
     * @param account account to for funds vote
     * @param currentVote true false vote
     */
    function vote(address account,bool currentVote) public {
        //require(!sender.voted, "Already voted.");
        //voters[msg.sender][account] = currentVote;
        if(currentVote == false)
            votes[voter_addresses[msg.sender]][voter_addresses[account]] = 0;
        else
            votes[voter_addresses[msg.sender]][voter_addresses[account]] = 1;
    }
    
    /** 
     * @dev Sends money if 2/3 majority is achieved
     */
    function transferWithMajority(address payable account) public payable 
    {
        uint vote_count = 0;
        for (uint i = 0; i < 3; i++) {
            vote_count += votes[i][voter_addresses[msg.sender]];
        }
        
        if(vote_count >= 2){
            account.transfer(msg.value);
        }else{
            revert();
        }
        
    }
    

}