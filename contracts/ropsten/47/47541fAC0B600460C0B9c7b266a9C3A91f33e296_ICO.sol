/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.5.0;

//set token interface to use the transfer function
interface token{
    function transfer(address _to,uint amount)external;
}

contract ICO{
    address payable public beneficiary;// The beneficiary:(defaults)the contract creator
    uint public fundingGoal;//The funding goal
    uint public deadline;//ico deadline
    uint public price;//? tokens per Ether
    token public tokenReward;
    uint public fundAmount;//The amount of accumulated financing
    
    mapping(address => uint) public balanceOf;
    
    event FundTransfer(address backer,uint amount);//Used to keep records of investor transfers
    event GoalReached(bool success);//Triggered when raised successfully
    
    constructor(uint fundingGoalInEthers,uint durationInMinutes,uint etherCostofEachToken,address addressOfToken) public {
        beneficiary = msg.sender;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes; 
        price = etherCostofEachToken * 1 ether;
        tokenReward = token(addressOfToken);
    }
    
	//fallback function: Triggered passively when receiving ether
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
	
    //Used after the crowdfunding cycle：Founder transfer OR the Investors refund
    function withdraw() public afterDDL{
        require(now>=deadline);
        
        if(fundAmount>=fundingGoal){//Reach funding goal：Founder transfer
            if(beneficiary == msg.sender){
                beneficiary.transfer(fundAmount);
            }
        }
        else{//Fail：Investors refund
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