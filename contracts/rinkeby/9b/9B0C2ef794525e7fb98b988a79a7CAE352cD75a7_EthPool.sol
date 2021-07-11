// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './Stoppable.sol';

contract EthPool is Stoppable {
  uint public minimumDeposit;
  uint numberOfParticipants;

  mapping(uint => Participant) participants;
  mapping(address => uint) addressToParticipant;

  event NewDeposit(address indexed _depositedFrom, uint _value);
  event NewWithdrawal(address indexed _withdrawedBy, uint _value);
  event NewReward(uint _value);

  struct Participant{
    address participantAddress;
    uint balance;
  }

  constructor(address _owner, uint _minimumDeposit) {
    if(_owner == address(0x0)){
      owner = _owner;
    } else {
      owner = msg.sender;
    }
    minimumDeposit = _minimumDeposit;
    numberOfParticipants = 0;
  }

  function depositFunds() payable public onlyWhenOperational {
    require(msg.value >= minimumDeposit, 'Attempted deposit is lower than minimum deposit allowed');
    uint participantId = createOrRetrieveParticipant(msg.sender);
    participants[participantId].balance += msg.value;
    emit NewDeposit(msg.sender, msg.value);
  }

  function withdrawFunds() public {
    Participant storage participant = participants[addressToParticipant[msg.sender]];
    require(participant.participantAddress == msg.sender, 'You are not a participant in the pool');
    require(participant.balance > 0, 'Balance should be greater than 0');
    emit NewWithdrawal(msg.sender, participant.balance);
    payable(msg.sender).transfer(participant.balance);
    participant.balance = 0;
  }

  function changeMinimumDeposit(uint _minimumDeposit) public onlyTeamMember {
    minimumDeposit = _minimumDeposit;
  }

  function depositReward() payable public onlyTeamMember {
    uint contractBalance = address(this).balance;
    for(uint i = 0; i < numberOfParticipants; i++){
      participants[i].balance += msg.value * participants[i].balance / (contractBalance - msg.value);
    }
    emit NewReward(msg.value);
  }

  function createOrRetrieveParticipant(address _address) internal returns(uint _participantId) {
    if(addressToParticipant[_address] == 0 && participants[0].participantAddress != _address){
      addressToParticipant[_address] = numberOfParticipants;
      participants[numberOfParticipants].participantAddress = _address;
      numberOfParticipants++;
    }
    return addressToParticipant[_address];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract PoolAccess {
  address owner;
  mapping(address => bool) teamMember;

  constructor() {}

  event OwnershipTransfer(address _previousOwner, address _newOwner);
  event TeamMembershipChange(address _teamMember, bool _permission);

  modifier onlyOwner {
    require(msg.sender == owner, 'Can only be called by the owner');
    _;
  }

  modifier onlyTeamMember {
    require(teamMember[msg.sender], 'Can only be called by a team member');
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    owner = _newOwner;
    emit OwnershipTransfer(msg.sender, _newOwner);
  }

  function changeTeamMemberPermission(address _teamMember, bool _permission) public onlyOwner {
    require(teamMember[_teamMember] != _permission, 'This team member already has this permission');
    teamMember[_teamMember] = _permission;
    emit TeamMembershipChange(_teamMember, _permission);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './PoolAccess.sol';

contract Stoppable is PoolAccess {
  bool public isStopped;

  constructor() {
    isStopped = false;
  }

  event EmergencyStop(address _initiator, string _reason);
  event StartOfOperation(address _initiator, string _notice);

  modifier onlyWhenOperational{
    require(!isStopped, 'Operation of the smart contract is halted');
    _;
  }

  modifier onlyWhenStopped{
    require(isStopped, 'This smart contract is currently operational');
    _;
  }

  function stopOperation(string memory _reason) public onlyWhenOperational onlyTeamMember {
    isStopped = true;
    emit EmergencyStop(msg.sender, _reason);
  }

  function resumeOperation(string memory _notice) public onlyWhenStopped onlyTeamMember {
    isStopped = false;
    emit StartOfOperation(msg.sender, _notice);
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}