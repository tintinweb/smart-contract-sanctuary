/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity >=0.4.22 <0.7.1;
pragma experimental ABIEncoderV2;

interface BettingContractInterface {
    
    enum Status {
        Unknown,    // So that we don't have Open == 0 but Open == 1 
        Open, 
        Paid,
        Cancelled,  // TODO Implement me
        Refunded
    }

    struct Stake {
        string matchId;
        uint amount;
        uint outcomeType;
        uint outcome;
        uint[] odds; 
        uint[] availableAmounts;
        uint timestamp;
        Status status; 
        uint payout;
        address payable delegate;
    }

    struct Bet {
        uint[] stakeIds; 
        uint[] amounts;
        uint resultBet;
        uint timestamp;
        Status status; 
        uint payout;
        address payable delegate;
    }

    function getStakeById(uint stakeId) external view returns (Stake memory);
    function stakesCount() external view returns (uint);
    
    function getBetById(uint betId) external view returns (Bet memory);
    function betsCount() external view returns (uint);
}

contract RaffleContract {

    BettingContractInterface bettingContractInterface; 

    constructor(address contractAddress) public payable {
        bettingContractInterface = BettingContractInterface(contractAddress);
    }

    // TODO Limit time 
    function getWinner() external view returns (uint) {
        uint totalPayout; 

        for (uint i = 1; i <= bettingContractInterface.betsCount(); i++) {
            BettingContractInterface.Bet memory bet = bettingContractInterface.getBetById(i);
            totalPayout += bet.payout;
        }
        for (uint i = 1; i <= bettingContractInterface.stakesCount(); i++) {
            BettingContractInterface.Stake memory stake = bettingContractInterface.getStakeById(i);
            totalPayout += stake.payout;
        }

        return totalPayout;
    }

}