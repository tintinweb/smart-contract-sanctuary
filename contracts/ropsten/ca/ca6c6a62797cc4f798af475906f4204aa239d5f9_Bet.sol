/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

contract Bet {
    enum Status {Open, Locked, Closed}
    
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
      require(status == Status.Open, 'Bet is not open');
      require(player == msg.sender, 'Sender is not player.');
      require(amount == msg.value, 'Amount not the one expected.');
    
      status = Status.Locked;
      headOrTails = _headOrTails;
    }
        
    function complete(bool _headOrTails) public {
      require(casino == msg.sender, 'Only the owner can complete the bet.');
      require(status == Status.Locked, 'Bet is not locked.');
      status = Status.Closed;
    
      if(headOrTails == _headOrTails) {
        player.transfer(address(this).balance);
      } else {
        assert(casino.send(address(this).balance));
      }
    }
}