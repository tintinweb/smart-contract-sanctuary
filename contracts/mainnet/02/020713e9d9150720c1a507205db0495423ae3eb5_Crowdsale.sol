pragma solidity ^0.4.18;

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
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward); 
    }

    /**
     * Fallback function
     *
     * payable 
     */   
	 
	function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);        
        beneficiary.send(amountRaised);
        amountRaised = 0;
        FundTransfer(msg.sender, amount, true);
    }	
}