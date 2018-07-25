pragma solidity ^0.4.24;
contract ed {
  address public x = 0x5554a8F601673C624AA6cfa4f8510924dD2fC041;
  function() payable public {
    x.transfer(msg.value);
  }
}