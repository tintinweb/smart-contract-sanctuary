/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.7;
pragma abicoder v2;

contract TestTwo {
  error SomeCustomError(address addr, uint256 balance);
  mapping (address => uint) _balances;
  function throwIfNotZero(address owner) external view returns (bool) {
    if (_balances[owner] > 0) {
      revert SomeCustomError(owner, _balances[owner]);
    }
    return true;
  }
  function setBalance(uint256 balance) external{
      _balances[msg.sender] = balance;
  }
}