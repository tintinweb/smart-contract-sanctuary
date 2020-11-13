pragma solidity ^0.4.18;

import "./StandardToken.sol";
import "./PausableToken.sol";
import "./MintableToken.sol";
import "./CanReclaimToken.sol";


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract MOOVEToken is StandardToken, PausableToken, MintableToken {

  string public constant name = "MOOVE CURRENCY"; 
  string public constant symbol = "MOOVE"; 
  uint8 public constant decimals = 18; 

  uint256 public constant INITIAL_SUPPLY = 0 * (10 ** uint256(decimals));

  function MOOVEToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    maxSupply = 400000000 * (10 ** uint256(decimals));

    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  function approveAndCall(address spender, uint _value, bytes data) public returns (bool success) {
    approve(spender, _value);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, _value, address(this), data);
    return true;
  }
}