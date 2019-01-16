pragma solidity >=0.4.21 <0.6.0;

contract Add {
  uint sum;

  function Sum() public view returns(uint) {
    return sum;
  }

  function add(uint a, uint b) public {
    sum = a + b;
  }
}