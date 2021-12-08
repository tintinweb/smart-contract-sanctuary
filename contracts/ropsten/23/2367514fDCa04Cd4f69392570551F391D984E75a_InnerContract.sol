pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x0C9Fd5e6c484108321887d7bA7dF18De4B596299";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}