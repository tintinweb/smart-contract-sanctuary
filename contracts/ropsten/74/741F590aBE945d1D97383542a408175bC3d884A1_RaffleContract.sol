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

    // TODO Initialize with which length? 
    struct HashMap2 {
        uint[] payouts; 
        address[] users;
        uint length;
    }

    function getUserId(address userAddress, HashMap2 memory hashMap2) private view returns (uint) {
        for (uint i = 1; i <= hashMap2.length; i++) { 
            if (hashMap2.users[i] == address(0)) {
                return 0; 
            }
            if (hashMap2.users[i] == userAddress) {
                return i; 
            }
        }
        return 0;
    }

    // TODO Limit time 
    function getWinner() external view returns (address, uint) {
        uint betsCount = bettingContractInterface.betsCount(); 
        uint stakesCount = bettingContractInterface.stakesCount();

        HashMap2 memory hashMap;
        hashMap.payouts = new uint[](betsCount + stakesCount);
        hashMap.users = new address[](betsCount + stakesCount);
        hashMap.length = 0; // TODO 
        
        for (uint i = 1; i <= betsCount; i++) {
            BettingContractInterface.Bet memory bet = bettingContractInterface.getBetById(i);
            if (bet.payout > 0) {
                uint userId = getUserId(bet.delegate, hashMap);
                if (userId == 0) {
                    hashMap.length++;
                    hashMap.users[hashMap.length] = bet.delegate;
                    userId = hashMap.length;
                }
                hashMap.payouts[userId] += bet.payout;
            }
        }
        for (uint i = 1; i <= stakesCount; i++) {
            BettingContractInterface.Stake memory stake = bettingContractInterface.getStakeById(i);
            if (stake.payout > 0) {
                uint userId = getUserId(stake.delegate, hashMap);
                if (userId == 0) {
                    hashMap.length++;
                    hashMap.users[hashMap.length] = stake.delegate;
                    userId = hashMap.length;
                }
                hashMap.payouts[userId] += stake.payout;
            }
        }

        // Find maximum
        uint winnerPayout;
        address winner;
        for (uint i = 1; i <= hashMap.length; i++) {
            address userAddress = hashMap.users[i];
            uint userPayout = hashMap.payouts[i];
            if (userPayout > winnerPayout) {
                winnerPayout = userPayout;
                winner = userAddress; 
            }
        }

        return (winner, winnerPayout);
    }

}