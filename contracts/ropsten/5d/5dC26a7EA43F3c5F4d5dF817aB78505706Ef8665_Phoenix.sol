/**
 *Submitted for verification at Etherscan.io on 2018-02-12
*/

pragma solidity ^0.4.18;

contract Phoenix {
    // If round last more than a year - cancel is activated
    uint private MAX_ROUND_TIME = 365 days;
    
    uint private totalCollected;
    uint private currentRound;
    uint private currentRoundCollected;
    uint private prevLimit;
    uint private currentLimit;
    uint private currentRoundStartTime;

    // That structure describes current user Account    
    // moneyNew - invested money in currentRound
    // moneyHidden - invested in previous round and not profit yet
    // profitTotal - total profit of user account (it never decreases)
    // profitTaken - profit taken by user
    // lastUserUpdateRound - last round when account was updated
    struct Account {
        uint moneyNew;
        uint moneyHidden;
        uint profitTotal;
        uint profitTaken;

        uint lastUserUpdateRound;
    }
    
    mapping (address => Account) private accounts;


    function Phoenix() public {
        totalCollected = 0;
        currentRound = 0;
        currentRoundCollected = 0;
        prevLimit = 0;
        currentLimit = 100e18;
        currentRoundStartTime = block.timestamp;
    }
    
    function Start() public {
        totalCollected = 0;
        currentRound = 0;
        currentRoundCollected = 0;
        prevLimit = 0;
        currentLimit = 100e18;
        currentRoundStartTime = block.timestamp;
    }
    // This function increments round to next:
    // - it sets new currentLimit (round)using sequence:
    //      100e18, 200e18, 4 * currentLImit - 2 * prevLimit
    function iterateToNextRound() private {
        currentRound++;
        uint tempcurrentLimit = currentLimit;
        
        if(currentRound == 1) {
            currentLimit = 200e18;
        }
        else {
            currentLimit = 4 * currentLimit - 2 * prevLimit;
        }
        
        prevLimit = tempcurrentLimit;
        currentRoundStartTime = block.timestamp;
        currentRoundCollected = 0;
    }
    
    // That function calculates profit update for user
    // - if increments from last calculated round to current round and 
    //   calculates current user Account state
    // - algorithm:
    function calculateUpdateProfit(address user) private view returns (Account) {
        Account memory acc = accounts[user];
        
        for(uint r = acc.lastUserUpdateRound; r < currentRound; r++) {
            acc.profitTotal *= 2;

            if(acc.moneyHidden > 0) {
                acc.profitTotal += acc.moneyHidden * 2;
                acc.moneyHidden = 0;
            }
            
            if(acc.moneyNew > 0) {
                acc.moneyHidden = acc.moneyNew;
                acc.moneyNew = 0;
            }
        }
        
        acc.lastUserUpdateRound = currentRound;
        return acc;
    }
    
    // Here we calculate profit and update it for user
    function updateProfit(address user) private returns(Account) {
        Account memory acc = calculateUpdateProfit(user);
        accounts[user] = acc;
        return acc;
    }

    // That function returns canceled status.
    // If round lasts for more than 1 year - cancel mode is on
    function canceled() public view returns(bool isCanceled) {
        return block.timestamp >= (currentRoundStartTime + MAX_ROUND_TIME);
    }
    
    // Fallback function for handling money sending directly to contract
    function () public payable {
        require(!canceled());
        deposit();
    }

    // Function for calculating and updating state during user money investment
    // - first of all we update current user state using updateProfit function
    // - after that we handle situation of investment that makes 
    //   currentRoundCollected more than current round limit. If that happen, 
    //   we set moneyNew to totalMoney - moneyPartForCrossingRoundLimit.
    // - check crossing round limit in cycle for case when money invested are 
    //   more than several round limit
    function deposit() public payable {
        require(!canceled());
        
        updateProfit(msg.sender);

        uint money2add = msg.value;
        totalCollected += msg.value;
        while(currentRoundCollected + money2add >= currentLimit) {
            accounts[msg.sender].moneyNew += currentLimit - 
                currentRoundCollected;
            money2add -= currentLimit - currentRoundCollected;

            iterateToNextRound();
            updateProfit(msg.sender);
        }
        
        accounts[msg.sender].moneyNew += money2add;
        currentRoundCollected += money2add;
    }
    
    // Returns common information about round
    // totalCollectedSum - total sum, collected in all rounds
    // roundCollected - sum collected in current round
    // currentRoundNumber - current round number
    // remainsCurrentRound - how much remains for round change
    function whatRound() public view returns (uint totalCollectedSum, 
            uint roundCollected, uint currentRoundNumber, 
            uint remainsCurrentRound) {
        return (totalCollected, currentRoundCollected, currentRound, 
            currentLimit - currentRoundCollected);
    }

    // Returns current user account state
    // profitTotal - how much profit is collected during all rounds
    // profitTaken - how much profit was taken by user during all rounds
    // profitAvailable (= profitTotal - profitTaken) - how much profit can be 
    //    taken by user
    // investmentInProgress - how much money are not profit yet and are invested
    //    in current or previous round
    function RoundStartTime() public view returns (uint profitTotal) {
        return (currentRoundStartTime);
    }

    function myAccount() public view returns (uint profitTotal, 
            uint profitTaken, uint profitAvailable, uint investmentInProgress) {
        var acc = calculateUpdateProfit(msg.sender);
        return (acc.profitTotal, acc.profitTaken, 
                acc.profitTotal - acc.profitTaken, 
                acc.moneyNew + acc.moneyHidden);
    }

    // That function handles cancel state. In that case:
    // - transfer all invested money in current round
    // - transfer all user profit except money taken
    // - remainder of 100 ETH is left after returning all invested in current
    //      round and all profit. Transfer it to users that invest money in 
    //      previous round. Total investment in previous round = prevLimit.
    //      So percent of money return = 100 ETH / prevLimit
    function payback() private {
        require(canceled());

        var acc = accounts[msg.sender];
        uint hiddenpart = 0;
        if(prevLimit > 0) {
            hiddenpart = (acc.moneyHidden * 100e18) / prevLimit;
        }
        uint money2send = acc.moneyNew + acc.profitTotal - acc.profitTaken + 
            hiddenpart;
        if(money2send > this.balance) {
            money2send = this.balance;
        }
        acc.moneyNew = 0;
        acc.moneyHidden = 0;
        acc.profitTaken = acc.profitTotal;

        msg.sender.transfer(money2send);
    }

    // Function for taking all profit
    // If round is canceled than do a payback (see above)
    // Calculate money left on account = (profitTotal - profitTaken)
    // Increase profitTaken by money left on account
    // Transfer money to user
    function takeProfit() public {
        Account memory acc = updateProfit(msg.sender);

        if(canceled()) {
            payback();
            return;
        }

        uint money2send = acc.profitTotal - acc.profitTaken;
        acc.profitTaken += money2send;
        accounts[msg.sender] = acc;

        if(money2send > 0) {
            msg.sender.transfer(money2send);
        }
    }

    
}