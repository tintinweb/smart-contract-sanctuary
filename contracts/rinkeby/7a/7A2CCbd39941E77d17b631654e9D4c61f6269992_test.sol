pragma solidity >=0.4.22 <0.9.0;

contract test {
  address private owner = msg.sender;

  function test2() public view returns(address){
    return (owner);
  }
}