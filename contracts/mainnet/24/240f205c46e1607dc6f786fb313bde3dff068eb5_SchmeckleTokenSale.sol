pragma solidity ^0.4.15;

contract token { function transfer(address receiver, uint amount); }

contract SchmeckleTokenSale {
  int public currentStage;
  uint public priceInWei;
  uint public availableTokensOnCurrentStage;
  token public tokenReward;
  event SaleStageUp(int newSaleStage, uint newTokenPrice);

  address beneficiary;
  uint decimalBase;
  uint totalAmount;

  function SchmeckleTokenSale() {
      beneficiary = msg.sender;
      priceInWei = 100 szabo;
      decimalBase = 1000000000000000000;
      tokenReward = token(0xD7a1BF3Cc676Fc7111cAD65972C8499c9B98Fb6f);
      availableTokensOnCurrentStage = 538000;
      totalAmount = 0;
      currentStage = -3;
  }

  function () payable {
      uint amount = msg.value;

      if (amount < 1 finney) revert();

      uint tokens = amount * decimalBase / priceInWei;

      if (tokens > availableTokensOnCurrentStage * decimalBase) revert();

      if (currentStage > 21) revert();

      totalAmount += amount;
      availableTokensOnCurrentStage -= tokens / decimalBase + 1;
      if (totalAmount >= 3 ether && currentStage == -3) {
          currentStage = -2;
          priceInWei = 500 szabo;
          SaleStageUp(currentStage, priceInWei);
      }
      if (totalAmount >= 42 ether && currentStage == -2) {
          currentStage = -1;
          priceInWei = 1000 szabo;
          SaleStageUp(currentStage, priceInWei);
      }
      if (availableTokensOnCurrentStage < 1000 && currentStage >= 0) {
          currentStage++;
          priceInWei = priceInWei * 2;
          availableTokensOnCurrentStage = 1000000;
          SaleStageUp(currentStage, priceInWei);
      }

      tokenReward.transfer(msg.sender, tokens);
  }

  modifier onlyBeneficiary {
      if (msg.sender != beneficiary) revert();
      _;
  }

 function withdraw(address recipient, uint amount) onlyBeneficiary {
      if (recipient == 0x0) revert();
      recipient.transfer(amount);
 }

 function launchSale() onlyBeneficiary () {
      if (currentStage > -1) revert();
      currentStage = 0;
      priceInWei = priceInWei * 2;
      availableTokensOnCurrentStage = 2100000;
      SaleStageUp(currentStage, priceInWei);
 }
}