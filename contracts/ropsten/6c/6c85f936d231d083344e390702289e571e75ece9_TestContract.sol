pragma solidity ^0.4.24;

contract TestContract {

  event TestInt(uint256 value);

  constructor() public {
  }

  function testInt(uint256 value)
    public
    returns (uint256)
  {
    emit TestInt(value);

    require (value >= 100, "value < 100");
    return value;
  }

  function () external payable {
  }

}