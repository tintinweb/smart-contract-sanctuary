pragma solidity ^0.4.24;
contract store_and_send {
   uint public amount;
   address public recipient;
   uint public balance;
  function I_store_ETH_to_contract() payable public {
        recipient=msg.sender;
        amount=msg.value;
  }
        
  function send_ETH_from_contract_to_me() public{
      balance=address(this).balance;
      if( balance>0){
  recipient.transfer(balance); }  
  }
}