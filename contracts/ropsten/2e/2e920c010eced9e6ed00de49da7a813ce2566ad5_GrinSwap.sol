pragma solidity ^0.4.13;

contract GrinSwap {
  address public sign_address;
  address public receive_address;
  address public refund_address;
  uint public unlock_time;

  constructor(address _sign_address, address _receive_address) public {
    sign_address = _sign_address;
    receive_address = _receive_address;
    refund_address = msg.sender;
    unlock_time = block.timestamp + 24 hours;
  }

  function claim(bytes32 r, bytes32 s, uint8 v) public {
    require(ecrecover("", v, r, s) == sign_address);
    selfdestruct(receive_address);
  }

  function refund() public {
    require(block.timestamp >= unlock_time);
    selfdestruct(refund_address);
  }

  function () external payable {}
}