/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.7;
pragma abicoder v2;

contract Test {
  error SomeCustomError(address addr, uint256 balance);
  mapping (address => uint) _balances;
  function throwIfNotZero(address owner) public view returns (bool) {
    revert SomeCustomError(owner, _balances[owner]);
    return true;
  }
}