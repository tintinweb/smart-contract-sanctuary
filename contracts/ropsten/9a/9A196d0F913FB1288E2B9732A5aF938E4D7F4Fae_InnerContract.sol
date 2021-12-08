pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x79b10b5E155368E45CFE0db84C2eF3141DA00A18";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}