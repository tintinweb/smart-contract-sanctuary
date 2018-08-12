pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address tokenOwner) external constant returns(uint);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public ethBalanceOf;
    mapping(address => uint256) public tokenOf;
    mapping(uint => address) public tokenOwner;
    uint totalOwner;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FundingGoalReached(bool reached);
    event SafeTokensFor(address tokenOwner, uint tokens);
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
        price = price / 1000;
        tokenReward = token(addressOfTokenUsedAsReward);
        
        totalOwner = 0;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     * Send tokens later and safe the buyer
     */
    function () payable public {
        require(!crowdsaleClosed);
        require(msg.value > 0);
        uint amount = msg.value;
        ethBalanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenOf[msg.sender] = amount / price;
        totalOwner++;
        tokenOwner[totalOwner] = msg.sender;
        emit SafeTokensFor(msg.sender, amount / price);
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
        emit FundingGoalReached(fundingGoalReached);
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has  been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = ethBalanceOf[msg.sender];
            ethBalanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    ethBalanceOf[msg.sender] = amount;
                }
            }
        }
        
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
                emit FundingGoalReached(fundingGoalReached);
            }
        }
    }
    /**
     * 
     * Send Tokens after a successful ICO to the buyers
     * 
     */
    function sendTokens() public afterDeadline{
        require(fundingGoalReached);
            for(uint i = 0; i <= totalOwner; i++) {
                tokenReward.transfer(tokenOwner[i], tokenOf[tokenOwner[i]]);
                emit FundTransfer(tokenOwner[i], tokenOf[tokenOwner[i]], true);
                tokenOf[tokenOwner[i]] = 0;
                tokenOwner[i] = 0;
            }
            totalOwner = 0;
    }
    /**
     * 
     * Get the Tokens back from the Crowdsale Contract, after the ICO
     * 
     */
    function getTokensBack() public afterDeadline {
        uint amountToken = tokenReward.balanceOf(address(this));
        if(amountToken > 0) {
            //Schicke restliche Tokens zur&#252;ck
            tokenReward.transfer(beneficiary, amountToken);
            emit TransferTokens(beneficiary, amountToken);
        }
    }
}