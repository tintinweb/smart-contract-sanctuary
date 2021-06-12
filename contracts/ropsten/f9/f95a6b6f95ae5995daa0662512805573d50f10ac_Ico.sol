/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount) external ;
}

contract Ico {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;

    uint public deadline;
    uint public price;
    token public tokenReward;

    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);


    constructor (
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = msg.sender;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
    }


    function () public payable {
        require(!crowdsaleClosed);

        uint amount = msg.value;  // wei
        balanceOf[msg.sender] += amount;

        amountRaised += amount;

        tokenReward.transfer(msg.sender, amount / price);

        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() {
        if (now >= deadline) {
            _;
        }
    }


    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    function safeWithdrawal() public afterDeadline {

        if (amountRaised < fundingGoal) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
            }
        }

        if (fundingGoal <= amountRaised && beneficiary == msg.sender) {
            beneficiary.transfer(amountRaised);
            emit FundTransfer(beneficiary, amountRaised, false);
        }
    }
}