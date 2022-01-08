// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

contract TestSequencer {
  struct WorkableJob {
    address job;
    bool canWork;
    bytes args;
  }

  bytes32 public master;
  mapping(address => bool) public jobs;
  address[] public activeJobs;

  event MasterSet(bytes32 indexed _network);
  event AddJob(address indexed _job);
  event RemoveJob(address indexed _job);
  error InvalidFileParam(bytes32 what);
  error NetworkExists(bytes32 network);
  error JobExists(address job);

  function addJob(address job) external {
    if (jobs[job]) revert JobExists(job);

    activeJobs.push(job);
    jobs[job] = true;

    emit AddJob(job);
  }

  function removeJob(uint256 index) external {
    address job = activeJobs[index];
    if (index != activeJobs.length - 1) {
      activeJobs[index] = activeJobs[activeJobs.length - 1];
    }
    activeJobs.pop();
    jobs[job] = false;

    emit RemoveJob(job);
  }

  function setMaster(bytes32 network) external {
    master = network;
    emit MasterSet(network);
  }

  function isMaster(bytes32 network) external view returns (bool) {
    return master == network;
  }
}