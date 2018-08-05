pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address tokenOwner) external;
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

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FundingGoalReached(bool reached);
    event TransferTokens(address receiver, uint tokens);

    /**
     * Constructor function
     *
     * Setup the owner
     */
     constructor (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
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
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function balanceOfCall(address tokenOwner) public returns(uint) {
        tokenReward.balanceOf(tokenOwner);
    }

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
        emit FundingGoalReached(fundingGoalReached);
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
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                   //Hole Tokens zur&#252;ck
                   tokenReward.transfer(address(msg.sender), balanceOf[msg.sender] * price);
                   balanceOf[msg.sender] = 0;
                   emit FundTransfer(address(msg.sender), balanceOf[msg.sender] * price, false);
                   
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        //Token Transfer muss bearbeitet werden - token transfer auch wenn Crowdfunding fehlschl&#228;gt und r&#252;ckerstattung eintritt
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
               tokenReward.transfer(beneficiary, address(this).balance);
               emit FundTransfer(beneficiary, address(this).balance, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
                emit FundingGoalReached(fundingGoalReached);
            }
        }
        
        if(balanceOfCall(address(this)) > 0) {
            //Schicke restliche Tokens zur&#252;ck
            tokenReward.transfer(beneficiary, balanceOfCall(address(this)));
            emit TransferTokens(beneficiary, balanceOfCall(address(this)));    
        }
    }
}