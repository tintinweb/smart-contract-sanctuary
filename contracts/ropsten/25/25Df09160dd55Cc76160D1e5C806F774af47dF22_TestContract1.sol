pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x4adF8b36627c7b4fD12ccf681ca9E7a4Ef196310";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}