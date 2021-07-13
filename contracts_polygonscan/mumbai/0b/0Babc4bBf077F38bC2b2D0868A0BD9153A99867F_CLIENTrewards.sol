/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

// SPDX-License-Identifier: UNLICENSED
// @ CLIENTrewards.sol
// version 1.5 (2021.07.11) <(rdp)>
pragma solidity ^0.7.6;
pragma abicoder v2;

contract CLIENTrewards {

    struct Reward {
        uint64 rewardDate;       // (YYYYMMDDHHMMSS)
        // clientAccountId       // Place holder this is the mapping key
        string rewardType;       // initial, rollover, transfer
        string rewardRule;       // uses a "RuleName", contest1, promo2, newcustonly3
        string contributionSym;  // (USD,EUR,GBP,JPY) Not in 'batchRewardProcessor', but discussed
        uint64 contributionAmt;  // contribuiton amount in Fiat
        // rewardFiatSym         // not used because this matches ContributionSym
        uint64 rewardFiatAmt;    // calculated reward ammount in Fiat based on rewardRule
        string rewardCryptoSym;  // Crypto Symbol
        uint64 rewardCryptoAmt;  // Crypto Reward Amount
        int8 txnSign;            // positive or negative transaction sign
     }

    mapping(string => Reward[]) internal rewardList;
    string[] internal rewardAccts;

    int8 credit = -1;
    int8 debit = 1;
        
    function makeRewardTransaction( string memory clientAccountId,
                                uint64 _rewardDate,
                                string memory _rewardType,
                                string memory _rewardRule,
                                string memory _contributionSym,
                                uint64 _contributionAmt,
                                uint64 _rewardFiatAmt,
                                string memory _rewardCryptoSym,
                                uint64 _rewardCryptoAmt ) public {
        Reward memory rewardRecord;
        rewardList[clientAccountId].push(rewardRecord);
        uint txnId = rewardList[clientAccountId].length - 1;
        rewardList[clientAccountId][txnId] = Reward( _rewardDate,
                                                _rewardType,
                                                _rewardRule,
                                                _contributionSym,
                                                _contributionAmt,
                                                _rewardFiatAmt,
                                                _rewardCryptoSym,
                                                _rewardCryptoAmt,
                                                debit);
        rewardAccts.push(clientAccountId);
    }
    
    function redeemRewardTransaction( string memory clientAccountId,
                                uint64 _rewardDate,
                                string memory _rewardType,
                                string memory _rewardRule,
                                string memory _contributionSym,
                                uint64 _contributionAmt,
                                uint64 _rewardFiatAmt,
                                string memory _rewardCryptoSym,
                                uint64 _rewardCryptoAmt ) public {

        Reward memory rewardRecord;
        rewardList[clientAccountId].push(rewardRecord);
        uint txnId = rewardList[clientAccountId].length - 1;
        rewardList[clientAccountId][txnId] = Reward(  _rewardDate,
                                                _rewardType,
                                                _rewardRule,
                                                _contributionSym,
                                                _contributionAmt,
                                                _rewardFiatAmt,
                                                _rewardCryptoSym,
                                                _rewardCryptoAmt,
                                                credit);
        rewardAccts.push(clientAccountId);
    }

    function getRewardAcctIds() external view returns(string[] memory) {
        return rewardAccts;
    }

    function getReward(string calldata clientAccountId) external view returns (Reward[] memory) {
        return (rewardList[clientAccountId]);
    }
    
    function countRewardAccts() external view returns (uint) {
        return rewardAccts.length;
    }
}