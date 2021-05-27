/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.8.1;

contract Bet {
  event BetLocked(bool playerBet);
  event BetClosed(bool result);

  enum Status { Open, Locked, Closed }

  address payable public casino;
  address payable public player;
  uint256 public amount;
  Status public status;
  bool public headOrTails;

  constructor (address payable _player) payable {
    casino = payable(msg.sender);
    status = Status.Open;
    player = _player;
    amount = msg.value;
  }

  function bet(bool _headOrTails) public payable {
    require(status == Status.Open);
    require(player == msg.sender);
    require(amount == msg.value);

    status = Status.Locked;
    headOrTails = _headOrTails;

    emit BetLocked(headOrTails);
  }

  function complete(bool _headOrTails) public {
    require(casino == msg.sender);
    require(status == Status.Locked);
    status = Status.Closed;

    if (headOrTails == _headOrTails) {
      player.transfer(address(this).balance);
    } else {
      casino.transfer(address(this).balance);
    }

    emit BetClosed(_headOrTails);
  }
}