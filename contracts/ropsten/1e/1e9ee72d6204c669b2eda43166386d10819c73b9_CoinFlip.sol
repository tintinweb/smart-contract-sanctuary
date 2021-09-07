/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity 0.4.24;

contract CoinFlip {
  address public player1;
  bytes32 public player1Commitment;

  uint256 public betAmount;

  address public player2;
  bool public player2Choice;

  uint256 public expiration = 2**256-1;

  constructor(bytes32 commitment) public payable {
    player1 = msg.sender;
    player1Commitment = commitment;
    betAmount = msg.value;
  }

  function cancel() public {
    require(msg.sender == player1);
    require(player2 == 0);

    betAmount = 0;
    msg.sender.transfer(address(this).balance);
  }

  function takeBet(bool choice) public payable {
    require(player2 == 0);
    require(msg.value == betAmount);

    player2 = msg.sender;
    player2Choice = choice;

    expiration = now + 24 hours;
  }

  function reveal(bool choice, uint256 nonce) public {
    require(player2 != 0);
    require(now < expiration);

    require(keccak256(abi.encodePacked(choice, nonce)) == player1Commitment);

    if (player2Choice == choice) {
      player2.transfer(address(this).balance);
    } else {
      player1.transfer(address(this).balance);
    }
  }

  function claimTimeout() public {
    require(now >= expiration);

    player2.transfer(address(this).balance);
  }
}