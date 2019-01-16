pragma solidity ^0.4.25;

contract FundsEIF {

  address public destinationAddress;
  event LogForwarded(address indexed sender, uint amount);


  constructor() public {
    destinationAddress = 0x8Fec30D7a55725965A5b419cC6095eeF89bA07B6;
  }

  function ForwardToEIF()  public {
    emit LogForwarded(msg.sender, address(this).balance);
    destinationAddress.transfer(address(this).balance);
  }

}