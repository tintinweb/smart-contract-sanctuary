pragma solidity ^0.4.18;
import './StandardToken.sol';

contract ExampleToken is StandardToken {
  string public name = "ExampleToken"; 
  string public symbol = "EXT";
  uint public decimals = 18;
  uint public INITIAL_SUPPLY = 10000000000 * (10 ** decimals);
  uint256 public totalSupply;

  function ExampleToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}