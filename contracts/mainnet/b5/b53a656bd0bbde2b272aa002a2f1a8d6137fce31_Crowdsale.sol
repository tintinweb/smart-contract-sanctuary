pragma solidity ^0.4.2;
interface token {
   function transfer (address receiver, uint amount) public;
}
contract Crowdsale {
   address public beneficiary;
   uint public fundingGoal;
   uint public amountRaised;
   uint public currentBalance;
   uint public deadline;
   uint public bonusPhaseOneDeadline;
   uint public bonusPhaseTwoDeadline;
   uint public bonusPhaseThreeDeadline;
   uint public price;
   uint public phaseOneBonusPercent;
   uint public phaseTwoBonusPercent;
   uint public phaseThreeBonusPercent;
   uint public remainingTokens;
   token public tokenReward;
   mapping(address => uint256) public balanceOf;
   bool public crowdsaleClosed = false;
   event GoalReached(address recipient, uint totalAmountRaised);
   event FundTransfer(address backer, uint amount, bool isContribution);
   function Crowdsale(
       address ifSuccessfulSendTo,
       uint fundingGoalInEthers,
       uint durationInMinutes,
       address addressOfTokenUsedAsReward,
       uint phaseOneDuration,
       uint phaseTwoDuration,
       uint phaseThreeDuration,
       uint additionalBonusTokens
   ) public {
       beneficiary = ifSuccessfulSendTo;
       fundingGoal = fundingGoalInEthers * 1 ether;
       deadline = now + durationInMinutes * 1 minutes;
       bonusPhaseOneDeadline = now + phaseOneDuration * 1 minutes;
       bonusPhaseTwoDeadline = now + phaseTwoDuration * 1 minutes;
       bonusPhaseThreeDeadline = now + phaseThreeDuration * 1 minutes;
       price = 0.0002 * 1 ether;
       tokenReward = token(addressOfTokenUsedAsReward);
       currentBalance = 0;
       remainingTokens = (5000 * fundingGoalInEthers * 10 ** uint256(8)) + (additionalBonusTokens * 10 ** uint256(8));
       phaseOneBonusPercent = 40;
       phaseTwoBonusPercent = 35;
       phaseThreeBonusPercent = 30;
   }
   function () public payable {
       require(!crowdsaleClosed);
       require(now < deadline);
       uint amount = msg.value;
       if (msg.sender != beneficiary) {
           require(msg.value >= 1 ether);
           amountRaised += amount;
           uint tokens = uint(amount * 10 ** uint256(8) / price);
           if (now < bonusPhaseOneDeadline) {
               tokens += ((phaseOneBonusPercent * tokens)/100 );
           } else if (now < bonusPhaseTwoDeadline) {
               tokens += ((phaseTwoBonusPercent * tokens)/100);
           } else if (now < bonusPhaseThreeDeadline) {
               tokens += ((phaseThreeBonusPercent * tokens)/100);
           }
           balanceOf[msg.sender] += tokens;
           remainingTokens -= tokens;
           tokenReward.transfer(msg.sender, tokens);
           FundTransfer(msg.sender, amount, true);
       }
       currentBalance += amount;
   }
   function checkGoalReached() public {
       require(beneficiary == msg.sender);
       crowdsaleClosed = true;
   }
   function safeWithdrawal(uint amountInWei) public {
       require(beneficiary == msg.sender);
       if (beneficiary.send(amountInWei)) {
           FundTransfer(beneficiary, amountInWei, false);
           currentBalance -= amountInWei;
       }
   }
   function withdrawUnsold() public {
       require(msg.sender == beneficiary);
       require(remainingTokens > 0);
       tokenReward.transfer(msg.sender, remainingTokens);
   }
}