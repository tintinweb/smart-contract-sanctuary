pragma solidity ^0.4.20;

interface Token {
    function transfer(address _to, uint _value) returns (bool success);
}

contract Crowdsale {

    address public beneficiary;
    uint public softCap;
    uint public hardCap;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;

    bool softCapReached = false;
    bool crowdsaleClosed = false;
    uint softCapInEther =  500 ether;
    uint hardCapInEther =  3200 ether;
    uint priceInEther =  0.0002 ether;
    uint tokenDecimal =  18;
    uint duration = 120 days;
    uint startDate = 1524762900; //unix

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

  
    function Crowdsale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        softCap = softCapInEther;
        hardCap = hardCapInEther;
        deadline = startDate + duration;
        price = priceInEther;
        tokenReward = Token(addressOfTokenUsedAsReward);
    }

  
    function () payable {

        require(!crowdsaleClosed);
        require(hardCap >= amountRaised);

        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * 10 ** uint256(tokenDecimal) / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

  
    function checkGoalReached() afterDeadline {
        if (amountRaised >= softCap){
            softCapReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    
    function safeWithdrawal() afterDeadline {

        if (!softCapReached) {
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

        if (softCapReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                softCapReached = false;
            }
        }
    }
}