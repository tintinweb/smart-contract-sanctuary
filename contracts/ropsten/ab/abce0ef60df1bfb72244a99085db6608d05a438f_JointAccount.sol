/**
 *Submitted for verification at Etherscan.io on 2021-02-27
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
   
    
    uint[3][3][] public votes;
    //mapping(address => uint)[] public voter_addresses;
    address[3][] public voter_addresses;
    //uint[3][] public voter_addresses_index;
    //address[] public bank_accounts;
    uint[] public bank_account_values;
    
    address payable public main_account;
    
    
    // for ballot example
    //["0x6332000000000000000000000000000000000000000000000000000000000000","0x6333000000000000000000000000000000000000000000000000000000000000"]
    // for this example when clicking deploy
    // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    constructor (address payable temp_main_account){
        main_account = temp_main_account;
    }
    
    //["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
    /**
      * @param temp_bank_accounts initializes 3 accounts to one address
      * @param initial_value initializes bank account values (this can be removed if depositAccount starts working correctly)
      */
    function initiateAccount(
        address[] memory temp_bank_accounts,
        uint initial_value
    //    ) {
    ) public {
        
        uint[3][3] memory temp_votes;
        //mapping(address => uint) storage temp_voter_addresses;
        
        address[3] memory temp_voter_addresses;
        //uint[3] memory temp_voter_addresses_index;
        
        for (uint i = 0; i < 3; i++) {
            for (uint j = 0; j < 3; j++) {
                temp_votes[i][j] = 0;
            }
            
            // zero is used to determine if account is not a joint account
            //temp_voter_addresses[temp_bank_accounts[i]] = i+1;
            temp_voter_addresses[i] = temp_bank_accounts[i];
            //temp_voter_addresses_index[i] = i;
        }
        
        votes.push(temp_votes);
        
        voter_addresses.push(temp_voter_addresses);
        //voter_addresses_index.push(temp_voter_addresses_index);
        
        //bank_accounts.push(temp_bank_accounts[3]);
        //bank_account_values.push(0);
        bank_account_values.push(initial_value);
        
        
    }
    
    /**
      * @param i bank account index to increase by wei amount
      */
    function depositAccount(uint i) public payable{
        
        uint j;// debug error here don't know why
    
        for(j = 0; j < 3; ++j){
            if(voter_addresses[i][j] == msg.sender){
                break;
            }
        }
        
        if(j < 3){
            uint amount = msg.value;
            main_account.transfer(msg.value);
            bank_account_values[i] += amount;
        }
        
        
    }

   
    /**
     * @dev Give your vote 
     * @param i bank account number
     * @param account account to vote yes or no for
     * @param currentVote true false vote
     */
    function vote(uint i,address account,bool currentVote) public {
        
        uint j;
        for(j = 0; j < 3; ++j){
            if(voter_addresses[i][j] == msg.sender){
                break;
            }
        }
        
        // verify that account is a joint account
        //if(voter_addresses[i][msg.sender] != 0){
        if(j < 3){
            
            uint k;
            for(k = 0; k < 3; ++k){
                if(voter_addresses[i][k] == account){
                    break;
                }
            }
            
            if(k < 3){
            
                //require(!sender.voted, "Already voted.");
                //voters[msg.sender][account] = currentVote;
                if(currentVote == false)
                    //votes[i][voter_addresses_index[i][msg.sender]-1][voter_addresses[i][account]-1] = 0;
                    votes[i][j][k] = 0;
                else
                    //votes[i][voter_addresses[i][msg.sender]-1][voter_addresses[i][account]-1] = 1;
                    votes[i][j][k] = 1;
            }
        }
    }
    
    /** 
     * @dev Sends money if 2/3 majority is achieved
     */
    function transferWithMajority(uint from,uint to,uint amount) public payable 
    {
        
        uint i;
        for(i = 0; i < 3; ++i){
            if(voter_addresses[from][i] == msg.sender){
                break;
            }
        }
            
        // verify that account is a joint account
        //if(voter_addresses[from][msg.sender] != 0){
        if(i < 3){
            
            uint vote_count = 0;
            for (uint j = 0; j < 3; j++) {
                vote_count += votes[from][j][i];
            }
            
            if(vote_count >= 2){
                //account.transfer(msg.value);
                require(bank_account_values[from] >= amount,"Not enough funds in bank account");
                bank_account_values[from] -= amount;
                bank_account_values[to] += amount;
            }
        }
    }
    
    

}