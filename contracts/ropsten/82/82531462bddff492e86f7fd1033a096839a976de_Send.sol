pragma solidity ^0.4.24;

contract Send {
  function ForceSend(address recipient) payable public {
    selfdestruct(recipient);
  }
}