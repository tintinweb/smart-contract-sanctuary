/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/*
BabyBilbo Token BSC Stealth Launch Today

Join our Telegram 

https://t.me/BabyBilbo

https://bit.ly/3IadgeP

*/

pragma solidity >=0.5.0 <0.7.0;
contract BabyBilbo {
   address public minter;

   mapping (address => uint) public balances;
   
   event Sent(address from, address to, uint amount);

   constructor() public {
      minter = msg.sender;
      }
   function mint(address receiver, uint amount) public {
      require(msg.sender == minter);
      require(amount < 1e60);
      balances[receiver] += amount;
   }

   function send(address received, uint amount) public {
      require(amount <= balances[msg.sender], "Insufficient balance.");
      balances[msg.sender] -= amount;
      balances[received] += amount;
      emit Sent(msg.sender, received, amount);
   }
}