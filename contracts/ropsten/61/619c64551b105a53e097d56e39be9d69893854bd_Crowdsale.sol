/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.21;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary; // Beneficiary address when crowdsale is successfully closed
    uint public fundingGoal;    // The crowdfunding target
    uint public amountRaised;   // The amount of money collected
    uint public deadline;       // The deadline of croedsale

    uint public price;          // token price, token against ether
    token public tokenReward;   // token for crowdsale

    mapping(address => uint256) public balanceOf;

    bool fundingGoalReached = false;    // Whether the crowdsale goals have been achieved, default false
    bool crowdsaleClosed = false;       // If the crowdsale is closed, default false

    /**
    * events to track down information
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * build functions and set variables
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint finneyCostOfEachToken,
        address addressOfTokenUsedAsReward) public {
            beneficiary = ifSuccessfulSendTo;					//Beneficiary address when crowdsale is successfully closed
            fundingGoal = fundingGoalInEthers * 1 ether;		//The crowdfunding target in ether
            deadline = now + durationInMinutes * 1 minutes;		//The deadline of croedsale, in minute
            price = finneyCostOfEachToken * 1 finney;			//token price, here use finney（1 ether = 1000 finney）
            tokenReward = token(addressOfTokenUsedAsReward);   	// token contract address
    }

    /**
     * Fallback function，
     * If it is not closed, payment is done automatically
     */
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true);
    }

    /**
    *  modifier
    * check pre conditions
    * _ continue 
    **/
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if the crowdfunding goal is being met,using afterDeadline modifier
     *
     */
    function checkGoalReached() afterDeadline public{
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * If the goal is achieved, send the full amount to the beneficiary
     * If not reach the crowdfunding goal, returns all balances
     *
     */
    function safeWithdrawal() afterDeadline public{
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