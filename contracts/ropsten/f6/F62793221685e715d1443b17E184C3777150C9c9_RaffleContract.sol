/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity >=0.4.22 <0.7.1;
pragma experimental ABIEncoderV2;

interface BettingContractInterface {
    
    enum Status {
        Unknown,
        Open, 
        Paid,
        Cancelled,
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

    function getUserStakes(address userAddress) external view returns (uint[] memory);
    function getUserBets(address userAddress) external view returns (uint[] memory);
}

contract RaffleContract {

    BettingContractInterface bettingContractInterface; 

    constructor(address contractAddress) public payable {
        bettingContractInterface = BettingContractInterface(contractAddress);
    }

    // TODO Initialize with which length? 
    struct HashMap2 {
        uint[] payments; 
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

    // 
    // This contract is specific for the first round of our test run, therefore 
    // only bets and stakes between the following timestamps will be taken into account
    // 
    uint timestampFrom = 1621116000; // 16.05.2021 12:00 AM Local Time
    uint timestampTo   = 1621807140; // 23.05.2021 11:59 PM Local Time

    // 
    // The current winner - the address having the most profits from staking
    // 
    function getStakesWinner() external view returns (address, uint) {
        uint stakesCount = bettingContractInterface.stakesCount();

        HashMap2 memory hashMap;
        hashMap.payments = new uint[](stakesCount);
        hashMap.payouts = new uint[](stakesCount);
        hashMap.users = new address[](stakesCount);
        
        for (uint i = 1; i <= stakesCount; i++) {
            BettingContractInterface.Stake memory stake = bettingContractInterface.getStakeById(i);
            if (stake.timestamp > timestampFrom && stake.timestamp < timestampTo && stake.payout > 0) {
                uint userId = getUserId(stake.delegate, hashMap);
                if (userId == 0) {
                    hashMap.length++;
                    hashMap.users[hashMap.length] = stake.delegate;
                    userId = hashMap.length;
                }
                hashMap.payments[userId] += stake.amount;
                hashMap.payouts[userId] += stake.payout;
            }
        }

        // Find the winner
        uint winnerProfit;
        address winner;
        for (uint i = 1; i <= hashMap.length; i++) {
            address userAddress = hashMap.users[i];
            uint userPayment = hashMap.payments[i];
            uint userPayout = hashMap.payouts[i];
            if (userPayout > userPayment) {
                uint userProfit = userPayout - userPayment; 
                if (userProfit > winnerProfit) {
                    winnerProfit = userProfit;
                    winner = userAddress; 
                }
            }
        }

        return (winner, winnerProfit);
    }

    // 
    // The current winner - the address having the most profits from betting
    // 
    function getBetsWinner() external view returns (address, uint) {
        uint betsCount = bettingContractInterface.betsCount(); 

        HashMap2 memory hashMap;
        hashMap.payments = new uint[](betsCount);
        hashMap.payouts = new uint[](betsCount);
        hashMap.users = new address[](betsCount);
        
        for (uint i = 1; i <= betsCount; i++) {
            BettingContractInterface.Bet memory bet = bettingContractInterface.getBetById(i);
            if (bet.timestamp > timestampFrom && bet.timestamp < timestampTo && bet.payout > 0) {
                uint userId = getUserId(bet.delegate, hashMap);
                if (userId == 0) {
                    hashMap.length++;
                    hashMap.users[hashMap.length] = bet.delegate;
                    userId = hashMap.length;
                }
                for (uint j = 0; j < bet.amounts.length; j++) {
                    hashMap.payments[userId] += bet.amounts[j];
                }
                hashMap.payouts[userId] += bet.payout;
            }
        }

        // Find the winner
        uint winnerProfit;
        address winner;
        for (uint i = 1; i <= hashMap.length; i++) {
            address userAddress = hashMap.users[i];
            uint userPayment = hashMap.payments[i];
            uint userPayout = hashMap.payouts[i];
            if (userPayout > userPayment) {
                uint userProfit = userPayout - userPayment; 
                if (userProfit > winnerProfit) {
                    winnerProfit = userProfit;
                    winner = userAddress; 
                }
            }
        }

        return (winner, winnerProfit);
    }

    // 
    // Verify your current profit from staking
    // 
    function getStakesProfit(address userAddress) external view returns (uint) {
        uint[] memory userStakeIds = bettingContractInterface.getUserStakes(userAddress);

        uint payment; 
        uint payout; 

        for (uint i = 1; i <= userStakeIds.length; i++) {
            BettingContractInterface.Stake memory stake = bettingContractInterface.getStakeById(userStakeIds[i]);
            if (stake.timestamp > timestampFrom && stake.timestamp < timestampTo && stake.payout > 0) {
                payment += stake.amount;
                payout += stake.payout;
            }
        }

        uint profit = 0;
        if (payout > payment) {
            profit = payout - payment;
        }
        return profit;
    }

    // 
    // Verify your current profit from betting
    // 
    function getBetsProfit(address userAddress) external view returns (uint) {
        uint[] memory userBetIds = bettingContractInterface.getUserBets(userAddress); 

        uint payment; 
        uint payout; 
        
        for (uint i = 1; i <= userBetIds.length; i++) {
            BettingContractInterface.Bet memory bet = bettingContractInterface.getBetById(userBetIds[i]);
            if (bet.timestamp > timestampFrom && bet.timestamp < timestampTo && bet.payout > 0) {
                for (uint j = 0; j < bet.amounts.length; j++) {
                    payment += bet.amounts[j];
                }
                payout += bet.payout;
            }
        }

        uint profit = 0;
        if (payout > payment) {
            profit = payout - payment;
        }
        return profit;
    }

}