/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.5.0;

interface token{
    function transfer(address _to,uint amount)external;
}

contract ICO{
    address payable public beneficiary;
    uint public fundingGoal;
    uint public deadline;
    uint public price;
    token public tokenReward;
    uint public fundAmount;
    
    mapping(address => uint) public balanceOf;
    
    event FundTransfer(address backer,uint amount);
    event GoalReached(bool success);
    
    constructor(uint fundingGoalInEthers,uint durationInMinutes,uint etherCostofEachToken,address addressOfToken) public {
        beneficiary = msg.sender;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes; 
        price = etherCostofEachToken * 1 ether;
        tokenReward = token(addressOfToken);
    }
    
    function() external payable{
        require(now < deadline);
        
        uint amount =msg.value;
        balanceOf[msg.sender]+=amount;
        fundAmount+=amount;
        
        uint tokenAmount = amount/price;
        tokenReward.transfer(msg.sender,tokenAmount);
        emit FundTransfer(msg.sender,amount);
    }
        
    modifier afterDDL(){
        require(now >= deadline);
        _;
    }
    
    function withdraw() public afterDDL{
        require(now>=deadline);
        
        if(fundAmount>=fundingGoal){
            if(beneficiary == msg.sender){
                beneficiary.transfer(fundAmount);
            }
        }
        else{
            uint amount = balanceOf[msg.sender];
            if(amount>0){
                msg.sender.transfer(amount);
                balanceOf[msg.sender] = 0;
            }
        }
    }
    
    function checkGoalReached()public afterDDL{
        if(fundAmount >= fundingGoal){
            emit GoalReached(true);
        }
    }
    
}