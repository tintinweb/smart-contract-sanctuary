/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.7.0;

contract WoH {

  mapping(address => uint64) registry;
  address public owner;
  uint64 public submissionDuration = 31557600;

  /**
   * Record the owner of the contract.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @param candidate The address to check for registration.
   * @return Whether a human is registered at the given address.
   */
  function isRegistered(address candidate) external view returns (bool) {
    return block.timestamp - registry[candidate] <= submissionDuration;
  }

  /**
   * @param registrants The address to add to the registry.
   * @param submissionTimes The time the registration was recorded (0 to unregister).
   */
  function register(address[] calldata registrants, uint64[] calldata submissionTimes) public {
    require(msg.sender == owner, "Only owner can register.");
    require(registrants.length == submissionTimes.length, "All registrants need submission times.");
    for (uint i=0; i<submissionTimes.length; i++) {
      registry[registrants[i]] = submissionTimes[i];
    }
  }

  /**
   * @param _submissionDuration New submission duration to set.
   */
  function setSubmissionDuration(uint64 _submissionDuration) public {
    require(msg.sender == owner, "Only owner can change submission duration.");
    submissionDuration = _submissionDuration;
  }

  /**
   * @param _owner Set a new owner.
   */
  function setOwner(address _owner) public {
    require(msg.sender == owner, "Only owner can change owner.");
    owner = _owner;
  }
}