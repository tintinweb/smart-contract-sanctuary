/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity >=0.4.22 <0.7.1;
pragma experimental ABIEncoderV2;

interface ContractInterface {
    
    enum Status { Unknown, Open, Paid, Cancelled, Refunded }

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

    function getUserStakes(address userAddress) external view returns (uint[] memory);
    function getUserBets(address userAddress) external view returns (uint[] memory);
}

contract Raffle {

    ContractInterface contractInterface; 

    constructor(address contractAddress) public payable {
        contractInterface = ContractInterface(contractAddress);
    }

    struct HashMap {
        address[] users;
        uint[] activities;
        uint length;
    }

    function getUserId(address userAddress, HashMap memory hashMap) private view returns (uint) {
        for (uint i = 1; i <= hashMap.length; i++) { 
            if (hashMap.users[i] == userAddress) {
                return i; 
            }
        }
        return 0;
    }

    // 
    // This contract is specific for the first round of our test run, therefore 
    // only bets and stakes between the following timestamps will be taken into account
    // 
    uint timestampFrom = 1621116000; // 16.05.2021 12:00 AM Local Time
    uint timestampTo   = 1621807140; // 23.05.2021 11:59 PM Local Time

    // 
    // Current winner - the address having the highest staking activity
    // 
    function getStakesWinner() external view returns (address, uint) {
        uint stakesCount = contractInterface.stakesCount();

        HashMap memory hashMap;
        hashMap.activities = new uint[](stakesCount);
        hashMap.users = new address[](stakesCount);
        
        for (uint i = 1; i <= stakesCount; i++) {
            ContractInterface.Stake memory stake = contractInterface.getStakeById(i);
            if (stake.timestamp > timestampFrom && stake.timestamp < timestampTo) {
                uint userId = getUserId(stake.delegate, hashMap);
                if (userId == 0) {
                    hashMap.length++;
                    hashMap.users[hashMap.length] = stake.delegate;
                    userId = hashMap.length;
                }
                hashMap.activities[userId] += 1;
            }
        }

        // 
        // Find the winner
        // 
        uint winnerActivity; 
        address winner;
        for (uint i = 1; i <= hashMap.length; i++) {
            address userAddress = hashMap.users[i];
            uint userActivity = hashMap.activities[i];

            if (userActivity > winnerActivity) {
                winnerActivity = userActivity;
                winner = userAddress; 
            }
        }

        return (winner, winnerActivity);
    }

    // 
    // Current winner - the address having the highest betting activity
    // 
    function getBetsWinner() external view returns (address, uint) {
        uint betsCount = contractInterface.betsCount(); 

        HashMap memory hashMap;
        hashMap.activities = new uint[](betsCount);
        hashMap.users = new address[](betsCount);
        
        for (uint i = 1; i <= betsCount; i++) {
            ContractInterface.Bet memory bet = contractInterface.getBetById(i);
            if (bet.timestamp > timestampFrom && bet.timestamp < timestampTo) {
                uint userId = getUserId(bet.delegate, hashMap);
                if (userId == 0) {
                    hashMap.length++;
                    hashMap.users[hashMap.length] = bet.delegate;
                    userId = hashMap.length;
                }
                hashMap.activities[userId] += 1;
            }
        }

        // 
        // Find the winner
        //
        uint winnerActivity; 
        address winner;
        for (uint i = 1; i <= hashMap.length; i++) {
            address userAddress = hashMap.users[i];
            uint userActivity = hashMap.activities[i];

            if (userActivity > winnerActivity) {
                winnerActivity = userActivity;
                winner = userAddress; 
            }
        }

        return (winner, winnerActivity);
    }

    // 
    // Verify your current staking activity
    // 
    function getStakesActivity(address userAddress) external view returns (uint) {
        uint[] memory userStakeIds = contractInterface.getUserStakes(userAddress);
        uint activity;

        for (uint i = 0; i < userStakeIds.length; i++) {
            ContractInterface.Stake memory stake = contractInterface.getStakeById(userStakeIds[i]);
            if (stake.timestamp > timestampFrom && stake.timestamp < timestampTo) {
                activity += 1;
            }
        }

        return activity;
    }

    // 
    // Verify your current betting activity
    // 
    function getBetsActivity(address userAddress) external view returns (uint) {
        uint[] memory userBetIds = contractInterface.getUserBets(userAddress); 
        uint activity; 
        
        for (uint i = 0; i < userBetIds.length; i++) {
            ContractInterface.Bet memory bet = contractInterface.getBetById(userBetIds[i]);
            if (bet.timestamp > timestampFrom && bet.timestamp < timestampTo) {
                activity += 1;
            }
        }

        return activity;
    }

}