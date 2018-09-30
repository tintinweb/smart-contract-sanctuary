pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract CrowdTmoney5 {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public startDate;
    uint public bonusEnds;
    uint public endDate;
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
    function CrowdTmoney5() public {


	    address ifSuccessfulSendTo = 0xb2769a802438C39f01C700D718Aea13754C7D378;
        uint fundingGoalInEthers = 2000;
        uint durationInMinutes = 10;
        uint weiCostOfEachToken = 2130000000000000;
        address addressOfTokenUsedAsReward = 0x308572F3d158e92264Adc364d1e83360b5C158aF;
	
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken;
        tokenReward = token(addressOfTokenUsedAsReward);
        bonusEnds = now + 1 weeks;
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
        tokenReward.transfer(msg.sender, amount / price);
       emit FundTransfer(msg.sender, amount, true);
       
   //            require(now >= startDate && now <= endDate);
   //     uint tokens;
   //     if (now <= bonusEnds) {
   //         tokens = msg.value * 4691;
   //     } else {
   //         tokens = msg.value * 4444;
      //  }
        
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