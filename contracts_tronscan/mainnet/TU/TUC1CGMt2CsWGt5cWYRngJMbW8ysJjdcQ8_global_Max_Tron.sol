//SourceUnit: vtrust.sol

pragma solidity >= 0.5.0;

contract global_Max_Tron {
  int public sum = 0;
  
  function add (int x, int y) public {
    sum = x + y;
  }
}