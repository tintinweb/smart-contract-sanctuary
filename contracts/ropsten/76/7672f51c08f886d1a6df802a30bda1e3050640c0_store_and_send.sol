pragma solidity ^0.4.24;
contract store_and_send {
   uint amount;
   address public recipient;
  function store_ETH_to_contract() payable public {
        }
  function send_ETH_from_contract(address _recipient) public{
      amount=1;
      recipient=_recipient;
  recipient.transfer(amount);   
  }
}