/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SimpleStorage {
  uint256 storedData;
    
  function get() public view returns (uint) {
    return storedData;
  }

  function set(uint x) public {
    require(x < 500, "too large!");
    storedData = x;
  }

  function double() public {
    storedData *= 2;
  }
}

contract MathTest {
    function multiply(uint a, uint b) public pure returns (uint) {
    return a*b;
  }
}

contract Lottery_v3 {
  // TODO: how to support N people? 
  address address1;
  address address2;
  uint balance1;
  uint balance2;


  function deposit() payable public {
    require(balance2 == 0, "cannot deposit, we already got two players");

    if (balance1 == 0) {
      address1 = msg.sender;
      balance1 = msg.value;
    } else {
      address2 = msg.sender;
      balance2 = msg.value;
    }
  }
  
  // each party can lock some amount
  // the pool gets randomly reassigned with odds
  // proportional to each holder's stake
  function roll() public {
    require(balance2 > 0, "expected two players, got zero or one");

    address winner;
    uint totalBalance = balance1 + balance2;
    uint rand = pseudorandom();
    // 'rand' ranges from 0 to MAX_UINT
    // Because MAX_UINT >> totalBalance, this
    // is approximately correct.
    uint winningTicket = rand % totalBalance;
    
    if (winningTicket < balance1) {
      winner = address1;
    }  
    else {
      winner = address2;
    }
    // notify who won!

    // Send everything, including unsolicited ether donations.
    payable(winner).transfer(address(this).balance);
    balance1 = 0;
    balance2 = 0;    
  }

  // Copied from stackoverflow, https://stackoverflow.com/questions/48848948/how-to-generate-a-random-number-in-solidity
  function pseudorandom() private view returns(uint) {
    return uint(keccak256(
      abi.encodePacked(block.timestamp)
    ));
  } 

}