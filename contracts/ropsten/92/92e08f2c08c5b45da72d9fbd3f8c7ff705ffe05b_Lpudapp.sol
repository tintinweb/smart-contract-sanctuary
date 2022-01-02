/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.8.9;

contract Lpudapp {
  address gip;
  address ent;
  bytes32 public registerId;
  bytes32 public digest;

  int16 public completed;
  event gipSet(address gip, uint timestamp);
  event entSet(address ent, uint timestamp);
  event completedChanged(int16 completed, uint timestamp);

  constructor (bytes32 _registerId, bytes32 _digest) {
    gip = msg.sender;
    registerId = _registerId;
    digest = _digest;
    completed = -1;

    emit gipSet(gip, block.timestamp);
    emit completedChanged(completed, block.timestamp);
  }

  function setEnt(address _ent) public {
    if (msg.sender != gip) {
      revert('1');
    }
    else if (completed != -1) {
      revert('2');
    }

    ent = _ent;
    
    completed = 0;

    emit completedChanged(completed, block.timestamp);
  }

  function update(int16 _completed) public {
    if (msg.sender == gip ) {
      if (
          (completed == -1 && _completed == 0) ||
          (completed == -100 && _completed == -128) ||
          (completed == -200 && _completed == -256)
      ) {
        completed = _completed;
      }
      else {
        revert('3');
      }
    }
    else if (msg.sender == ent ) {
      if (
          (completed >= 0 && _completed > completed) ||
          (completed >= 0 && _completed == -100) ||
          (completed > 0 && _completed == -200)
      ) {
        completed = _completed;
      }
      else {
        revert('4');
      }
    }
    else {
      revert('5');
    }

    emit completedChanged(completed, block.timestamp);
  }

  function read () public view returns (address, address, bytes32, bytes32, int16) {

    return (gip, ent, registerId, digest, completed);
  } 

}