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
  ) external payable {
    CommunityFund communityFund = (new CommunityFund){ value: msg.value }( 
      msg.sender, name, requiredNbOfParticipants, recurringAmount, startDate, duration
    );
    address communityFundAddress = address(communityFund);

    communityFunds.push(communityFundAddress);
    emit CommunityFundCreated(communityFundAddress);
  }

  function getCommunityFunds() external view returns (address[] memory) {
    return communityFunds;
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
    bool collateral;
  }

  mapping (address => Participant) public participants;
  address[] public allParticipants;

  constructor(
    address _from,
    string memory _name,
    uint _requiredNbOfParticipants,
    uint _recurringAmount,
    uint _startDate,
    uint _duration
  ) payable {
    require(block.timestamp < _startDate, "start date of the fund must be in the future!");
    require((msg.value == 0) || (msg.value >= _recurringAmount * _duration * 120 / 100), "not enough collateral");

    name = _name;

    requiredNbOfParticipants = _requiredNbOfParticipants;
    recurringAmount          = _recurringAmount;
    duration                 = _duration;
    startDate                = _startDate;

    if (msg.value > 0) {
      participants[_from].balance   += msg.value;
      participants[_from].collateral = true;

      allParticipants.push(_from);
    }
  }

  function deposit() external payable {
    require(participants[msg.sender].collateral == true, "collateral required");
    require(msg.value == recurringAmount, "please deposit exact amount");

    // -- TODO: only allow for one deposit per month.
  
    participants[msg.sender].balance += msg.value;
  }

  function collateral() external payable {
    require(block.timestamp < startDate, "collateral must be committed before the funds starts");
    require(allParticipants.length < requiredNbOfParticipants, "max participants reached");
    require(participants[msg.sender].collateral == false, "collateral already locked");
    require(msg.value >= recurringAmount * duration * 120 / 100, "minimum collateral required");

    participants[msg.sender].balance   += msg.value;
    participants[msg.sender].collateral = true;

    allParticipants.push(msg.sender);
  }

  function getAllParticipants() external view returns (address[] memory) {
    return allParticipants;
  }
}