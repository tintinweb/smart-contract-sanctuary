pragma solidity ^0.4.23;

contract Forward {

  address public destinationAddress;
  event LogForwarded(address indexed sender, uint amount);
  event LogFlushed(address indexed sender, uint amount);

  function constuctor() public {
    destinationAddress = msg.sender;
  }

  function() payable public {
    emit LogForwarded(msg.sender, msg.value);
    destinationAddress.transfer(msg.value);
  }

  function flush() public {
    emit LogFlushed(msg.sender, address(this).balance);
    destinationAddress.transfer(address(this).balance);
  }

}