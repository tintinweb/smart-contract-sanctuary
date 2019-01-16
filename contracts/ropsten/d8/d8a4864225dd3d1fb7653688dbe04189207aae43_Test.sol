pragma solidity ^0.4.24;
contract Test {

   address[] public investors;
   mapping(address => uint256) public balances;

   function saveAddress() payable public {
       investors.push(msg.sender);
       balances[msg.sender] = msg.value;
   }
}