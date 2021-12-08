pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x477a0572783ecEAb7D83C8aacb0936BC3880baf5";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}