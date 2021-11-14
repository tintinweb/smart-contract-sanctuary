/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

pragma solidity ^0.5.0;
contract Akupdatez {
  address payable public minter;
  uint public balance;
  event Transfer(address payable indexed _from, address payable indexed _to, uint256 _value);
  mapping (address => uint) public balances;
  constructor() public {
    minter = msg.sender;
  }
  function showSender() public view returns (address)
  {
    return (msg.sender);
  }
  function sendcoin(address payable receiver, uint amount) public {
    receiver.transfer(amount);
  }
}