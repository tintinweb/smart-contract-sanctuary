pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    // Release progress
    uint public percent;
    mapping(address => uint256) public percentOf;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event RewardToken(address backer, uint amount, uint percent);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint weiCostOfEachToken,
        address addressOfTokenUsedAsReward,
        uint initPercent
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken * 1 wei;
        tokenReward = token(addressOfTokenUsedAsReward);
        percent = initPercent;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
        if (crowdsaleClosed) {
            uint amount2 = balanceOf[msg.sender];
            uint rewardPercent = percent - percentOf[msg.sender];
            require(amount2 > 0 && rewardPercent > 0);
            percentOf[msg.sender] = percent;
            // Release percent of reward token
            uint rewardAmount2 = amount2 * 10**18 * rewardPercent / price / 100;
            tokenReward.transfer(msg.sender, rewardAmount2);
            RewardToken(msg.sender, rewardAmount2, rewardPercent);
        } else {
            uint amount = msg.value;
            balanceOf[msg.sender] += amount;
            amountRaised += amount;
            percentOf[msg.sender] = percent;
            // Release init percent of reward token
            uint rewardAmount = amount * 10**18 * percent / price / 100;
            tokenReward.transfer(msg.sender, rewardAmount);
            FundTransfer(msg.sender, amount, true);
            RewardToken(msg.sender, rewardAmount, percent);
        }
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
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
    function safeWithdrawal() afterDeadline {
        require(crowdsaleClosed);

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
    
    /**
     * Release 10% of reward token
     *
     * Release 10% of reward token when beneficiary call this function.
     */
    function releaseTenPercent() afterDeadline {
        require(crowdsaleClosed);

        require(percent <= 90);
        if (fundingGoalReached && beneficiary == msg.sender) {
            percent += 10;
        }
    }
}