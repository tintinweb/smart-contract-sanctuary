pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract TMONEYsale{
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public priceT1;
    uint public priceT2;
    uint public priceT3;
    uint public priceT4;
    uint public startDate;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    constructor() public {


	    address ifSuccessfulSendTo = 0xb2769a802438C39f01C700D718Aea13754C7D378;
        uint fundingGoalInEthers = 800;
        uint durationInMinutes = 102480;
        uint weiCostOfEachToken = 213000000000000;
        address addressOfTokenUsedAsReward = 0x66d544B100966F99A72734c7eB471fB9556BadFd;
	
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        priceT1 = weiCostOfEachToken + 26000000000000;
        priceT2 = weiCostOfEachToken + 26000000000000;
        priceT3 = weiCostOfEachToken + 26000000000000;
        priceT4 = weiCostOfEachToken + 26000000000000;
        tokenReward = token(addressOfTokenUsedAsReward);
        
        startDate = now;
    }
    

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        
        uint price = priceT1;
        if (startDate + 7 days <= now)
            price = priceT4;
        else if (startDate + 14 days <= now)
            price = priceT3;
        else if (startDate + 90 days <= now)
            price = priceT2;  
        
        tokenReward.transfer(msg.sender, amount / price * 1 ether);
       emit FundTransfer(msg.sender, amount, true);
        
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}