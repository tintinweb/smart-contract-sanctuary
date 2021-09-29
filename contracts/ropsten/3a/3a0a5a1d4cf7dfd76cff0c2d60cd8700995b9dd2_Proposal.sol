/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

  
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
      

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface ISigmoidGovernance{
    function isActive(bool _contract_is_active) external returns (bool);
    function getClassInfo(uint256 poposal_class) external view returns(uint256 timelock, uint256 minimum_approval, uint256 minimum_vote, uint256 need_architect_veto, uint256 maximum_execution_time, uint256 minimum_execution_interval);
    function getProposalInfo(uint256 poposal_class, uint256 proposal_nonce) external view returns(uint256 timestamp, uint256 total_vote, uint256 approve_vote, uint256 architect_veto, uint256 execution_left, uint256 execution_interval);
    
    function vote(uint256 poposal_class, uint256 proposal_nonce, bool approval, uint256 _amount) external returns(bool);
    function createProposal(uint256 poposal_class, address proposal_address, uint256 proposal_execution_nonce, uint256 proposal_execution_interval) external returns(bool);
    function revokeProposal(uint256 poposal_class, uint256 proposal_nonce, uint256 revoke_poposal_class, uint256 revoke_proposal_nonce) external returns(bool);
    function checkProposal(uint256 poposal_class, uint256 proposal_nonce) external view returns(bool);
    
    function firstTimeSetContract(address SASH_address,address SGM_address, address bank_address, address bond_address, address exchange_address) external returns(bool);
    function InitializeSigmoid() external returns(bool);
    function pauseAll(bool _contract_is_active) external returns(bool);
   
    function updateGovernanceContract(uint256 poposal_class, uint256 proposal_nonce, address new_governance_address) external returns(bool);
    function updateExchangeContract(uint256 poposal_class, uint256 proposal_nonce, address new_exchange_address) external returns(bool);
    function updateBankContract(uint256 poposal_class, uint256 proposal_nonce, address new_bank_address) external returns(bool);
    function updateBondContract(uint256 poposal_class, uint256 proposal_nonce, address new_bond_address) external returns(bool);
    function updateTokenContract(uint256 poposal_class, uint256 proposal_nonce, uint256 new_token_class, address new_token_address) external returns(bool);
    function createBondClass(uint256 poposal_class, uint256 proposal_nonce, uint256 bond_class, string calldata bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch) external returns (bool);
   
    function migratorLP(uint256 poposal_class, uint256 proposal_nonce, address _to, address tokenA, address tokenB) external returns(bool);
    function transferTokenFromGovernance(uint256 poposal_class, uint256 proposal_nonce, address _token, address _to, uint256 _amount) external returns(bool);
    function claimFundForProposal(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_amount,  uint256 SGM_amount) external returns(bool);
    function mintAllocationToken(address _to, uint256 SASH_amount, uint256 SGM_amount) external returns(bool);
    function changeTeamAllocation(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_ppm, uint256 SGM_ppm) external returns(bool);
    function changeCommunityFundSize(uint256 poposal_class, uint256 proposal_nonce, uint256 new_SGM_budget_ppm, uint256 new_SASH_budget_ppm) external returns(bool);
    
    function changeReferralPolicy(uint256 poposal_class, uint256 proposal_nonce, uint256 new_1st_referral_reward_ppm, uint256 new_1st_referral_POS_reward_ppm, uint256 new_2nd_referral_reward_ppm, uint256 new_2nd_referral_POS_reward_ppm, uint256 new_first_referral_POS_Threshold_ppm, uint256 new_second_referral_POS_Threshold_ppm) external returns(bool);
    function claimReferralReward(address first_referral, address second_referral, uint256 SASH_total_amount) external returns(bool);
    function getReferralPolicy(uint256 index) external view returns(uint256);
}

contract Proposal {
    address public gov_address;
    constructor (address dev_address) public {
            gov_address=dev_address;
    }
    function revokeProposal(uint256 poposal_class, uint256 proposal_nonce, uint256 revoke_poposal_class, uint256 revoke_proposal_nonce) public  returns(bool){
        require(ISigmoidGovernance(gov_address).revokeProposal(poposal_class,proposal_nonce,revoke_poposal_class,revoke_proposal_nonce)==true);
        return(true);         
    }

    function createBondClass(uint256 poposal_class, uint256 proposal_nonce, uint256 bond_class, string memory bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch) public  returns(bool){
        require(ISigmoidGovernance(gov_address).createBondClass(poposal_class,proposal_nonce,bond_class,bond_symbol,Fibonacci_number,Fibonacci_epoch)==true);
        return(true);         
    }
    
    function claimFundForProposal(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_amount,  uint256 SGM_amount) public  returns(bool){
        require(ISigmoidGovernance(gov_address).claimFundForProposal(poposal_class,proposal_nonce,_to,SASH_amount,SGM_amount)==true);
        return(true);         
    }
     function changeTeamAllocation(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_ppm, uint256 SGM_ppm) public  returns(bool){
        require(ISigmoidGovernance(gov_address).changeTeamAllocation(poposal_class,proposal_nonce,_to,SASH_ppm,SGM_ppm)==true);
        return(true);         
    }
      function changeCommunityFundSize(uint256 poposal_class, uint256 proposal_nonce, uint256 new_SGM_budget_ppm, uint256 new_SASH_budget_ppm) public  returns(bool){
        require(ISigmoidGovernance(gov_address).changeCommunityFundSize(poposal_class,proposal_nonce,new_SGM_budget_ppm,new_SASH_budget_ppm)==true);
        return(true);         
    }
      function changeReferralPolicy(uint256 poposal_class, uint256 proposal_nonce, uint256 new_1st_referral_reward_ppm, uint256 new_1st_referral_POS_reward_ppm, uint256 new_2nd_referral_reward_ppm, uint256 new_2nd_referral_POS_reward_ppm, uint256 new_first_referral_POS_Threshold_ppm, uint256 new_second_referral_POS_Threshold_ppm) public  returns(bool){
        require(ISigmoidGovernance(gov_address).changeReferralPolicy(poposal_class,proposal_nonce,new_1st_referral_reward_ppm,new_1st_referral_POS_reward_ppm,new_2nd_referral_reward_ppm,new_2nd_referral_POS_reward_ppm,new_first_referral_POS_Threshold_ppm,new_second_referral_POS_Threshold_ppm)==true);
        return(true);         
    }
      function transferTokenFromGovernance(uint256 poposal_class, uint256 proposal_nonce, address _token, address _to, uint256 _amount) public  returns(bool){
        require(ISigmoidGovernance(gov_address).transferTokenFromGovernance(poposal_class,proposal_nonce,_token,_to,_amount)==true);
        return(true);         
    }
      function migratorLP(uint256 poposal_class, uint256 proposal_nonce, address _to, address tokenA, address tokenB) public  returns(bool){
        require(ISigmoidGovernance(gov_address).migratorLP(poposal_class,proposal_nonce,_to,tokenA,tokenB)==true);
        return(true);         
    }
       function updateBondContract(uint256 poposal_class, uint256 proposal_nonce, address new_bond_address) public  returns(bool){
        require(ISigmoidGovernance(gov_address).updateBondContract(poposal_class,proposal_nonce,new_bond_address)==true);
        return(true);         
    }
         function updateBankContract(uint256 poposal_class, uint256 proposal_nonce, address new_bank_address) public  returns(bool){
        require(ISigmoidGovernance(gov_address).updateBankContract(poposal_class,proposal_nonce,new_bank_address)==true);
        return(true);         
    }
          function updateExchangeContract(uint256 poposal_class, uint256 proposal_nonce, address new_exchange_address) public  returns(bool){
        require(ISigmoidGovernance(gov_address).updateExchangeContract(poposal_class,proposal_nonce,new_exchange_address)==true);
        return(true);         
    }
           function updateTokenContract(uint256 poposal_class, uint256 proposal_nonce, uint256 new_token_class, address new_token_address) public  returns(bool){
        require(ISigmoidGovernance(gov_address).updateTokenContract(poposal_class,proposal_nonce,new_token_class,new_token_address)==true);
        return(true);         
    }
             function updateGovernanceContract(uint256 poposal_class, uint256 proposal_nonce, address new_governance_address) public  returns(bool){
        require(ISigmoidGovernance(gov_address).updateGovernanceContract(poposal_class,proposal_nonce,new_governance_address)==true);
        return(true);         
    }
    
}