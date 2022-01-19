/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity >=0.5.0 <0.7.0;
contract ExampleCoin {
   address public minter;

   mapping (address => uint) public balances;
   
   event Sent(address from, address to, uint amount);

   constructor() public {
      minter = msg.sender;
   }

   function mint(address receiver, uint amount) public {
      balances[receiver] += amount;
   }

   function send(address received, uint amount) public {
      require(amount <= balances[msg.sender], "Insufficient balance.");
      balances[msg.sender] -= amount;
      balances[received] += amount;
      emit Sent(msg.sender, received, amount);
   }
}