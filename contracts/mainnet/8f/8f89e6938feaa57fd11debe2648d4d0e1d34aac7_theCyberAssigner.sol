pragma solidity ^0.4.19;


contract theCyberInterface {
  // The contract may call a few methods on theCyber once it is itself a member.
  function newMember(uint8 _memberId, bytes32 _memberName, address _memberAddress) public;
  function getMembershipStatus(address _memberAddress) public view returns (bool member, uint8 memberId);
  function getMemberInformation(uint8 _memberId) public view returns (bytes32 memberName, string memberKey, uint64 memberSince, uint64 inactiveSince, address memberAddress);
}


contract theCyberGatekeeperTwoInterface {
  // The contract may read the entrants from theCyberGatekeeperTwo.
  function entrants(uint256 i) public view returns (address);
  function totalEntrants() public view returns (uint8);
}


contract theCyberAssigner {
  // This contract supplements the second gatekeeper contract at the address
  // 0xbB902569a997D657e8D10B82Ce0ec5A5983C8c7C. Once enough members have been
  // registered with the gatekeeper, the assignAll() method may be called,
  // which (assuming theCyberAssigner is itself a member of theCyber), will
  // try to assign a membership to each of the submitted addresses.

  // The assigner will interact with theCyber contract at the given address.
  address private constant THECYBERADDRESS_ = 0x97A99C819544AD0617F48379840941eFbe1bfAE1;

  // the assigner will read the entrants from the second gatekeeper contract.
  address private constant THECYBERGATEKEEPERADDRESS_ = 0xbB902569a997D657e8D10B82Ce0ec5A5983C8c7C;

  // There can only be 128 entrant submissions.
  uint8 private constant MAXENTRANTS_ = 128;

  // The contract remains active until all entrants have been assigned.
  bool private active_ = true;

  // Entrants are assigned memberships based on an incrementing member id.
  uint8 private nextAssigneeIndex_;

  function assignAll() public returns (bool) {
    // The contract must still be active in order to assign new members.
    require(active_);

    // Require a large transaction so that members are added in bulk.
    require(msg.gas > 6000000);

    // All entrants must be registered in order to assign new members.
    uint8 totalEntrants = theCyberGatekeeperTwoInterface(THECYBERGATEKEEPERADDRESS_).totalEntrants();
    require(totalEntrants >= MAXENTRANTS_);

    // Initialize variables for checking membership statuses.
    bool member;
    address memberAddress;

    // The contract must be a member of theCyber in order to assign new members.
    (member,) = theCyberInterface(THECYBERADDRESS_).getMembershipStatus(this);
    require(member);
    
    // Pick up where the function last left off in assigning new members.
    uint8 i = nextAssigneeIndex_;

    // Loop through entrants as long as sufficient gas remains.
    while (i < MAXENTRANTS_ && msg.gas > 200000) {
      // Find the entrant at the given index.
      address entrant = theCyberGatekeeperTwoInterface(THECYBERGATEKEEPERADDRESS_).entrants(i);

      // Determine whether the entrant is already a member of theCyber.
      (member,) = theCyberInterface(THECYBERADDRESS_).getMembershipStatus(entrant);

      // Determine whether the target membership is already owned.
      (,,,,memberAddress) = theCyberInterface(THECYBERADDRESS_).getMemberInformation(i + 1);
      
      // Ensure that there was no member found with the given id / address.
      if ((entrant != address(0)) && (!member) && (memberAddress == address(0))) {
        // Add the entrant as a new member of theCyber.
        theCyberInterface(THECYBERADDRESS_).newMember(i + 1, bytes32(""), entrant);
      }

      // Move on to the next entrant / member id.
      i++;
    }

    // Set the index where the function left off; set as inactive if finished.
    nextAssigneeIndex_ = i;
    if (nextAssigneeIndex_ >= MAXENTRANTS_) {
      active_ = false;
    }

    return true;
  }

  function nextAssigneeIndex() public view returns(uint8) {
    // Return the current assignee index.
    return nextAssigneeIndex_;
  }

  function maxEntrants() public pure returns(uint8) {
    // Return the total number of entrants allowed by the gatekeeper.
    return MAXENTRANTS_;
  }
}