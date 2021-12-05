// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./CommunityFund.sol";

contract CommunityFundFactory {
  address[] public communityFunds;

  event CommunityFundCreated(address communityFundAddress);

  function createCommunityFund(
    string calldata name,
    uint requiredNbOfParticipants,
    uint recurringAmount,
    uint startDate,
    uint duration
  ) external {
    address communityFund = address(new CommunityFund(
      name, requiredNbOfParticipants, recurringAmount, startDate, duration
    ));

    communityFunds.push(communityFund);
    emit CommunityFundCreated(communityFund);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

contract CommunityFund {
  string public name;

  uint public requiredNbOfParticipants;
  uint public recurringAmount;
  uint public startDate;
  uint public duration;

  struct Participant {
    uint balance;
    bool exists;
  }

  mapping (address => Participant) public participants;
  address[] public allParticipants;

  constructor(
    string memory _name,
    uint _requiredNbOfParticipants,
    uint _recurringAmount,
    uint _startDate,
    uint _duration
  ) {
    name = _name;

    requiredNbOfParticipants = _requiredNbOfParticipants;
    recurringAmount          = _recurringAmount;
    duration                 = _duration;
    startDate                = _startDate;
  }

  function deposit() external payable {
    require (
      (allParticipants.length < requiredNbOfParticipants) || 
      (participants[msg.sender].exists = true),
      "max participants reached"
    );
    require (msg.value == recurringAmount, "please deposit exact amount");

    // -- TODO: only allow one deposit per month.

    participants[msg.sender].balance += msg.value;
    participants[msg.sender].exists  =  true;
    allParticipants.push(msg.sender);
  }
}