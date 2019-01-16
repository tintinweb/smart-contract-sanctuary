pragma solidity ^0.4.24;

contract Debugging {
    uint public originalBalance = 2500000 * 10**18; // 2 500 000 tokens
    uint public currentBalance = originalBalance;
    uint public alreadyTransfered = 0;
    uint public startDateOfPayments = 1554069600; //From 01 Apr 2019, 00:00:00
    uint public endDateOfPayments = 1569880800; //From 01 Oct 2019, 00:00:00
    uint public periodOfOnePayments = 24 * 60 * 60; // 1 day in seconds
    uint public daysOfPayments = (endDateOfPayments - startDateOfPayments) / periodOfOnePayments; // 183 days
    uint public limitPerPeriod = originalBalance / daysOfPayments;

    uint public nowTime = 1554069500;
    uint public tokensToSent = 0;
    uint currentPeriod;
    uint currentLimit;
    uint unsealedAmount;
    
    function resetAllData() public {
        originalBalance = 2500000 * 10**18; // 2 500 000 tokens
        currentBalance = originalBalance;
        alreadyTransfered = 0;
        startDateOfPayments = 1554069600; //From 01 Apr 2019, 00:00:00
        endDateOfPayments = 1569880800; //From 01 Oct 2019, 00:00:00
        periodOfOnePayments = 24 * 60 * 60; // 1 day in seconds
        daysOfPayments = (endDateOfPayments - startDateOfPayments) / periodOfOnePayments; // 183 days
        limitPerPeriod = originalBalance / daysOfPayments;
    
        nowTime = 1554069500;
        tokensToSent = 0;
        currentPeriod = 0;
        currentLimit = 0;
        unsealedAmount = 0;
    }
    
    function setNowTime(uint newTime) public {
        nowTime = newTime;
    }
    
    function countCurrentPayment() public {
        currentPeriod = (nowTime - startDateOfPayments) / periodOfOnePayments;   
        currentLimit = currentPeriod * limitPerPeriod;						 
        unsealedAmount = currentLimit - alreadyTransfered;					 
        if (unsealedAmount > 0) {												 
          if (currentBalance >= unsealedAmount) {								 
            tokensToSent = unsealedAmount;
            alreadyTransfered += unsealedAmount;
            currentBalance -= unsealedAmount;
          } else {
            tokensToSent = currentBalance;
            alreadyTransfered += currentBalance;
            currentBalance -= currentBalance;
          }
        }
    }
}