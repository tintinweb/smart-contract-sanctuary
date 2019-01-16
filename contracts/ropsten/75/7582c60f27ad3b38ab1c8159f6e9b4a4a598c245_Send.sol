pragma solidity ^0.4.24;

contract Send {
    address public recipient;
  function ForceSend(address _recipient) payable public {
      recipient=_recipient;
  }
}