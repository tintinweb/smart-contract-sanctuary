//SourceUnit: saft.sol

pragma solidity ^0.6.0;

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract SAFT{

  address payable public owner;

  constructor() public{
    owner = msg.sender;
  }

  function deal()
  public
  payable
  returns (uint)
  {
    require(msg.value >= 0,"Provide more than zero trx");

    uint256 value = msg.value * 2;
    ITRC20(0xC43c34b74c30818976d32827C1899c1fEf12629B).transfer(msg.sender,value);
    return value;
  }

  function removeKty (uint amount)
  public
  returns (bool)
  {
    require(msg.sender == owner,"Prohibited call");
    ITRC20(0xC43c34b74c30818976d32827C1899c1fEf12629B).transfer(owner,amount);
    return true;
  }

  function removeTRX (uint amount)
  public
  returns (bool)
  {
    require(msg.sender == owner,"Prohibited call");
    owner.transfer(amount);
    return true;
  }

}