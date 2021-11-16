/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity 0.4.24;



//-----------------Simple Test----------------
contract SimpleTest {

 mapping(address => uint) balances;

  string public constant name="SimpleCoin";
  string public constant symbol="ST";
  uint8 public constant decimals=19;
  uint public totalSupply;

  uint256 public constant INITIAL_SUPPLY=10000000000000000000; // 10^19

  function SimpleTest1() public{
   totalSupply=INITIAL_SUPPLY;
   balances[msg.sender]=INITIAL_SUPPLY;
  }
}