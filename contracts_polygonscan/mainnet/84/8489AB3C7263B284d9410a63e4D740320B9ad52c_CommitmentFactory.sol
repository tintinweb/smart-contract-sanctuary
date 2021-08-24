// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Commitment.sol";

contract CommitmentFactory {
  Commitment[] public commitments;
  
  event CommitmentCreated(address commitmentAddress);
  
  mapping(address => address[]) commitmentsCreated;
  mapping(address => address[]) commitmentsReceived;
  
  function createCommitment(address _receiver, address _token, uint _amount, uint _days, bool _revokable) public {
      Commitment commitment = new Commitment(_receiver, _token, _amount, _days, _revokable);
      commitments.push(commitment);
      commitmentsCreated[msg.sender].push(address(commitment));
      commitmentsReceived[_receiver].push(address(commitment));
      emit CommitmentCreated(address(commitment));
  }
  
  function showCommitmentsCreated(address _address) public view returns(address [] memory) {
      return commitmentsCreated[_address];
  }
  
  function showCommitmentsReceivable(address _address) public view returns(address [] memory) {
      return commitmentsReceived[_address];
  }
}