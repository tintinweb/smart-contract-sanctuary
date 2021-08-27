/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.8.0;

abstract contract EtherRock {
    function buyRock (uint rockNumber) virtual public payable;
    function sellRock (uint rockNumber, uint price) virtual public;
    function giftRock (uint rockNumber, address receiver) virtual public;
}

contract RockMinter {
  EtherRock rocks = EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);

  function buy(uint256 id) public  {
    rocks.buyRock(id);
    rocks.sellRock(id, type(uint256).max);
    rocks.giftRock(id, msg.sender);
  }
}