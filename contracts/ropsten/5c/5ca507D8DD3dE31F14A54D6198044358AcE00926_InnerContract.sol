pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x9a0B23F4DE5EeB7cc1d6b5001859d1A337f50ffc";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}