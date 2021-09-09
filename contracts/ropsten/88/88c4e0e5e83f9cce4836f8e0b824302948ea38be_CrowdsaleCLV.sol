/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.8.7;

interface token {
    
    function transfer (address receiver, uint amount) external;
    
}

contract CrowdsaleCLV {
    
    
    address public beneficiary;
        uint public fundingGoal;
        uint public amountRaised;
        uint public deadline;
        uint public price;
        token public tokenReward;
        mapping (address => uint256) public balanceOf;
        bool fundingGoalReached = false;
        bool CrowdsaleClosed = false;
        
        event GoalReached (address recipient , uint totalAmountRaised);
        event FundTransfer (address backer, uint amount, bool isContribution);
  
  
   constructor(
       
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostforEachToken,
        address addressOfTokenUsedAsReward
    
       ){
           
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = block.timestamp + durationInMinutes * 1 minutes;
        price = etherCostforEachToken * 1 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
        
        
       }
       
       fallback() external payable {
           
          require(!CrowdsaleClosed);
          uint amount = msg.value;
          balanceOf[msg.sender] += amount;
          amountRaised += amount;
          tokenReward.transfer(msg.sender, amount/price);
        
        
        emit FundTransfer(msg.sender, amount, true);
           
       }
       
       receive() external payable {
        // custom function code
    }
       
       
       
       
       modifier afterDeadline(){
           
           if(block.timestamp >= deadline) _;
           
       }
       
       function checkGoalReached() public afterDeadline {
           if (amountRaised >= fundingGoal){
               fundingGoalReached = true;
               emit GoalReached(beneficiary, amountRaised);
           }
           
           CrowdsaleClosed = true;
       }
       
       function safeWithdrwal() public afterDeadline {
           if(!fundingGoalReached){
               uint amount = balanceOf[msg.sender];
               
              address payable owner = payable (msg.sender);
              //balanceOf[owner] = 0;
              
               balanceOf[msg.sender] = 0;
               
               
               
               
               if(amount > 0){
               if(owner.send(amount)){
               
               // if(payable(owner).send(amount)){
                    
                       emit FundTransfer(msg.sender, amount, false);
                       
                   } else {
                       balanceOf[msg.sender] = amount;
                   }
                   
               }
           }
           
          if (fundingGoalReached && beneficiary == payable (msg.sender)){
              if (payable (beneficiary).send(amountRaised)){
                  emit FundTransfer (beneficiary, amountRaised, false);
                  
              } else {
                  fundingGoalReached = false;
              }
              
          }
           
       }
}