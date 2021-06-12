/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.4.0;

interface token {
    function transfer(address _to, uint amount) external;
}

contract ICO {
    address public beneficiary = msg.sender;  
    uint public fundingGoal;   
    uint public deadline;      
    uint public price ;   
    uint public funAmount;
    token public tokenReward;


    mapping(address => uint256) public balanceOf;     
    mapping(uint256 => address) public addressList;

    bool public fundingGoalReached = false;  
    bool public crowdsaleClosed = false;   

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount);
    
    constructor (uint fundingGoalInEthers, 
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward) public{
    	require(msg.sender==beneficiary);
    	tokenReward = token(addressOfTokenUsedAsReward);
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
    }
    
     function() public payable{

        require(now<deadline);
        uint amount = msg.value; 
        uint tokenAmount = amount / price;  
        balanceOf[msg.sender] += amount; 
        funAmount += amount; 
        tokenReward.transfer(msg.sender,tokenAmount);
        emit FundTransfer(msg.sender,amount);       
    }
    
    function withDrawal() public{

        require(now >= deadline);

        if (funAmount >= fundingGoal){
            if (beneficiary==msg.sender){
                beneficiary.transfer(funAmount);
                fundingGoalReached = true;
            }

        }else{
            uint amount=balanceOf[msg.sender];
            if (amount>0){
                msg.sender.transfer(amount);
                balanceOf[msg.sender]=0;
            }
        }
        
    }
    
     modifier afterDeadline() {
    if (now >= deadline) _; }
    
    function checkGoalReached() afterDeadline public {
        if (funAmount >= fundingGoal){
            fundingGoalReached = true;
        }

        crowdsaleClosed = true;
}
}