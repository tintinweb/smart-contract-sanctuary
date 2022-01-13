//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// The purpose of this contract is to keep a separate history of all Recruitments, so if we have to change the master Recruiting contract we still have the history separate.
// This should only track how many times a Raider has recruited, when they last recruited, and who they recruited

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract RecruitingHistory is Ownable, Pausable {
  using SafeMath for uint;

  mapping(uint => uint) public raiderLastRecruitedTime;
  mapping(uint => uint) public raiderRecruitingCount;
  mapping(uint => uint) public whoRecruited;
  mapping(uint => uint) public whenRaiderWasRecruited;
  mapping(uint => uint) public gen10Recruitments;

  mapping(address => bool) public approvedUpdater;

  // ----------- MODIFIERS ----------

  modifier onlyApproved() {
    require(approvedUpdater[msg.sender] == true, "You can't do this!");
    _;
  }

  // ----------- CORE FUNCTIONS ----------
  
  function updateRecruitedTime(uint _raiderId, uint _time) external onlyApproved {
    raiderLastRecruitedTime[_raiderId] = _time;
  }

  function addRecruitedCount(uint _raiderId) external onlyApproved {
    raiderRecruitingCount[_raiderId] = raiderRecruitingCount[_raiderId].add(1);
  }

  function logWhoRecruited(uint _recruitId, uint _recruiter) external onlyApproved {
    whoRecruited[_recruitId] = _recruiter;
  }
  
  function logWhenRaiderWasRecruited(uint _recruitId, uint _time) external onlyApproved {
    whenRaiderWasRecruited[_recruitId] = _time;
  }

  function logGen10Recruitment(uint _raiderId) external onlyApproved {
    gen10Recruitments[_raiderId] = gen10Recruitments[_raiderId].add(1);
  }

  // ----------- ADMIN ONLY ----------

  function addApproved(address _address) external onlyOwner {
    approvedUpdater[_address] = true;
  }

  function removeApproved(address _address) external onlyOwner {
    approvedUpdater[_address] = false;
  }

  function changeRecruitedCount(uint _raiderId, uint _count) external onlyOwner {
    raiderRecruitingCount[_raiderId] = _count;
  }

  function changeGen10Recruitments(uint _raiderId, uint _count) external onlyOwner {
    gen10Recruitments[_raiderId] = _count;
  }

}