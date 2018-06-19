pragma solidity ^0.4.10;


contract Token { 
    function transfer(address receiver, uint amount);
}


contract TemplateCrowdSale {
    address public beneficiary;
    uint public fundingGoal; 
    uint public amountRaised; 
    uint public deadline; 
    uint public price;
    uint public minAmount = 1 ether;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /* data structure to hold information about campaign contributors */

    /*  at initialization, setup the owner */
    function TemplateCrowdSale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOf10000Token,
        Token addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOf10000Token ;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

    /* The function without name is the default function that is called whenever anyone sends funds to a contract */
    function () payable {
        if (crowdsaleClosed) {
            revert();
        }
        uint amount = msg.value;
        if (amount < minAmount) {
            revert();
        }
        balanceOf[msg.sender] = amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount*10000 / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { 
        require(now >= deadline);
        _;
    }

    /* checks if the goal or time limit has been reached and ends the campaign */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}