/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.26;

interface token {
    function transfer(address receiver, uint amount) external ;
}

//Define ICO Contracts
contract Ico {
    address public beneficiary;//Define the beneficiaries of crowdfunding
    uint public fundingGoal;//Define the goal of crowdfunding
    uint public amountRaised;//Define the amount of crowdfunding
    uint public deadline;//Define a deadline
    uint public price;//Define the crowdfunding price
    token public tokenReward;//Defines the number of tokens to send
    mapping(address => uint256) public balanceOf;//Mapping the balance of the participant's account
    bool crowdsaleClosed = false;//Define to turn off crowdfunding and assign false
    event GoalReached(address recipient, uint totalAmountRaised);//Define the events that achieve the goal
    event FundTransfer(address backer, uint amount, bool isContribution);//Define funds transfer events
    
    //Construct the crowdfunding function
    constructor (
        uint fundingGoalInEthers,//Name the target of the crowdfunding as Ethereum
        uint durationInMinutes,//The specified period is in minutes
        uint etherCostOfEachToken,//The price unit for the designated token is Ethereum
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = msg.sender;//The beneficiary is the creator of the contract
        fundingGoal = fundingGoalInEthers * 1 ether;//Assign a value to the crowdfunding target using the price of Ethereum
        deadline = now + durationInMinutes * 1 minutes;//Define a crowdfunding deadline
        price = etherCostOfEachToken * 1 ether;//Define the price at which tokens are settled on Ethereum
        tokenReward = token(addressOfTokenUsedAsReward);//Assign a value to the tokens that need to be exchanged
    }

    /*Define the fallback function to implement the exchange with Ethereum. A user sends a certain amount of 
    Ethereum and gets a certain amount of tokens*/
    function () public payable {
        require(!crowdsaleClosed);//Confirm if the crowdfunding is over and if it is, it cannot be executed
        uint amount = msg.value;  //The amount of Ethereum raised is Amount
        balanceOf[msg.sender] += amount;// Participants' account balances increase accordingly
        amountRaised += amount;//The amount of crowdfunding increases accordingly
        tokenReward.transfer(msg.sender, amount / price);//Return the tokens
        emit FundTransfer(msg.sender, amount, true);//Trigger the event
    }
    modifier afterDeadline() {
        if (now >= deadline) {
            _;
        }
    }

    //A function that defines whether the crowdfunding goal is achieved, and if the goal is achieved, the crowdfunding is turned off
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {//If the amount raised is greater than the target
            emit GoalReached(beneficiary, amountRaised);//Trigger the event
        }
        crowdsaleClosed = true;//Close all the raise
    }

    /*Define the function of crowdfunding failure. If crowdfunding fails, the refund will be given, and the issuer will 
    withdraw the money if crowdfunding succeeds*/
    function safeWithdrawal() public afterDeadline {
        if (amountRaised < fundingGoal) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);//Trigger the event
            }
        }

        if (fundingGoal <= amountRaised && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
            emit FundTransfer(beneficiary, amountRaised, false);//Trigger the event
        }
    }
}