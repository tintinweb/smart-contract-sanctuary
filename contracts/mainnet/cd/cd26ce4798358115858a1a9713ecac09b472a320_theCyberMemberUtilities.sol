pragma solidity ^0.4.19;


contract ERC20 {
  // We want to be able to recover & donate any tokens sent to the contract.
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
}


contract theCyberInterface {
  // The utility contract can call the following methods of theCyber.
  function newMember(uint8 _memberId, bytes32 _memberName, address _memberAddress) public;
  function proclaimInactive(uint8 _memberId) public;
  function heartbeat() public;
  function revokeMembership(uint8 _memberId) public;
  function getMembershipStatus(address _memberAddress) public view returns (bool member, uint8 memberId);
  function getMemberInformation(uint8 _memberId) public view returns (bytes32 memberName, string memberKey, uint64 memberSince, uint64 inactiveSince, address memberAddress);
  function maxMembers() public pure returns(uint16);
  function inactivityTimeout() public pure returns(uint64);
  function donationAddress() public pure returns(address);
}


contract theCyberMemberUtilities {
  // This contract provides a set of helper functions that members of theCyber
  // may call in order to perform more advanced operations. In order to interact
  // with theCyber, the contract must first be assigned as a member.

  event MembershipStatusSet(bool isMember, uint8 memberId);
  event FundsDonated(uint256 value);
  event TokensDonated(address tokenContractAddress, uint256 value);

  // Set the address and interface of theCyber.
  address private constant THECYBERADDRESS_ = 0x97A99C819544AD0617F48379840941eFbe1bfAE1;
  theCyberInterface theCyber = theCyberInterface(THECYBERADDRESS_);

  // Set up variables for checking the contract&#39;s membership status.
  bool private isMember_;
  uint8 private memberId_;

  // The max members, inactivity timeout, and the donation address are pulled
  // from theCyber inside the constructor function.
  uint16 private maxMembers_;
  uint64 private inactivityTimeout_;
  address private donationAddress_;

  // Batch operations on all members utilize incrementing member ids.
  uint8 private nextInactiveMemberIndex_;
  uint8 private nextRevokedMemberIndex_;

  // Methods of the utility contract can only be called by a valid member.
  modifier membersOnly() {
    // Only allow transactions originating from a valid member address.
    bool member;
    (member,) = theCyber.getMembershipStatus(msg.sender);
    require(member);
    _;
  }

  // In the constructor function, set up the max members, the inactivity
  // timeout, and the donation address.
  function theCyberMemberUtilities() public {
    // Set the maximum number of members.
    maxMembers_ = theCyber.maxMembers();

    // Set the inactivity timeout.
    inactivityTimeout_ = theCyber.inactivityTimeout();

    // Set the donation address.
    donationAddress_ = theCyber.donationAddress();

    // Set the initial membership status to false.
    isMember_ = false;

    // Start the inactive member index at 0.
    nextInactiveMemberIndex_ = 0;

    // Start the revoked member index at 0.
    nextRevokedMemberIndex_ = 0;
  }

  // Set the member id of the utility contract prior to calling batch methods.
  function setMembershipStatus() public membersOnly {
    // Set the membership status and member id of the utility contract.
    (isMember_,memberId_) = theCyber.getMembershipStatus(this);

    // Log the membership status of the utility contract.
    MembershipStatusSet(isMember_, memberId_);
  }

  // The utility contract must be able to heartbeat if it is marked as inactive.
  function heartbeat() public membersOnly {
    // Heartbeat the utility contract.
    theCyber.heartbeat();
  }

  // Revoke a membership and immediately assign the membership to a new member.
  function revokeAndSetNewMember(uint8 _memberId, bytes32 _memberName, address _memberAddress) public membersOnly {
    // Revoke the membership (provided it has been inactive for long enough).
    theCyber.revokeMembership(_memberId);

    // Assign a new member to the membership (provided the new member is valid).
    theCyber.newMember(_memberId, _memberName, _memberAddress);
  }

  // Mark all members (except this contract & msg.sender) as inactive.
  function proclaimAllInactive() public membersOnly returns (bool complete) {
    // The utility contract must be a member (and therefore have a member id).
    require(isMember_);

    // Get the memberId of the calling member.
    uint8 callingMemberId;
    (,callingMemberId) = theCyber.getMembershipStatus(msg.sender);

    // Initialize variables for checking the status of each membership.
    uint64 inactiveSince;
    address memberAddress;
    
    // Pick up where the function last left off in assigning new members.
    uint8 i = nextInactiveMemberIndex_;

    // make sure that the loop triggers at least once.
    require(msg.gas > 175000);

    // Loop through members as long as sufficient gas remains.
    while (msg.gas > 170000) {
      // Make sure that the target membership is owned and active.
      (,,,inactiveSince,memberAddress) = theCyber.getMemberInformation(i);
      if ((i != memberId_) && (i != callingMemberId) && (memberAddress != address(0)) && (inactiveSince == 0)) {
        // Mark the member as inactive.
        theCyber.proclaimInactive(i);
      }
      // Increment the index to point to the next member id.
      i++;

      // exit once the index overflows.
      if (i == 0) {
        break;
      }
    }

    // Set the index where the function left off.
    nextInactiveMemberIndex_ = i;
    return (i == 0);
  }

  // Allow members to circumvent the safety measure against self-inactivation.
  function inactivateSelf() public membersOnly {
    // Get the memberId of the calling member.
    uint8 memberId;
    (,memberId) = theCyber.getMembershipStatus(msg.sender);

    // Inactivate the membership (provided it is not already marked inactive).
    theCyber.proclaimInactive(memberId);
  }

  // Revoke all memberships (except those of the utility contract & msg.sender)
  // that have been inactive for longer than the inactivity timeout.
  function revokeAllVulnerable() public membersOnly returns (bool complete) {
    // The utility contract must be a member (and therefore have a member id).
    require(isMember_);

    // Get the memberId of the calling member.
    uint8 callingMemberId;
    (,callingMemberId) = theCyber.getMembershipStatus(msg.sender);

    // Initialize variables for checking the status of each membership.
    uint64 inactiveSince;
    address memberAddress;
    
    // Pick up where the function last left off in assigning new members.
    uint8 i = nextRevokedMemberIndex_;

    // make sure that the loop triggers at least once.
    require(msg.gas > 175000);

    // Loop through members as long as sufficient gas remains.
    while (msg.gas > 175000) {
      // Make sure that the target membership is owned and inactive long enough.
      (,,,inactiveSince,memberAddress) = theCyber.getMemberInformation(i);
      if ((i != memberId_) && (i != callingMemberId) && (memberAddress != address(0)) && (inactiveSince != 0) && (now >= inactiveSince + inactivityTimeout_)) {
        // Revoke the member.
        theCyber.revokeMembership(i);
      }
      // Increment the index to point to the next member id.
      i++;

      // exit once the index overflows.
      if (i == 0) {
        break;
      }
    }

    // Set the index where the function left off.
    nextRevokedMemberIndex_ = i;
    return (i == 0);
  }

  // Allow members to circumvent the safety measure against self-revokation.
  function revokeSelf() public membersOnly {
    // Get the memberId of the calling member.
    uint8 memberId;
    (,memberId) = theCyber.getMembershipStatus(msg.sender);

    // Revoke the membership (provided it has been inactive for long enough).
    theCyber.revokeMembership(memberId);
  }

  // The contract is not payable by design, but could end up with a balance as
  // a recipient of a selfdestruct / coinbase of a mined block.
  function donateFunds() public membersOnly {
    // Log the donation of any funds that have made their way into the contract.
    FundsDonated(this.balance);

    // Send all available funds to the donation address.
    donationAddress_.transfer(this.balance);
  }

  // We also want to be able to access any tokens that are sent to the contract.
  function donateTokens(address _tokenContractAddress) public membersOnly {
    // Make sure that we didn&#39;t pass in the current contract address by mistake.
    require(_tokenContractAddress != address(this));

    // Log the donation of any tokens that have been sent into the contract.
    TokensDonated(_tokenContractAddress, ERC20(_tokenContractAddress).balanceOf(this));

    // Send all available tokens at the given contract to the donation address.
    ERC20(_tokenContractAddress).transfer(donationAddress_, ERC20(_tokenContractAddress).balanceOf(this));
  }

  // The donation address for lost ether / ERC20 tokens should match theCyber&#39;s.
  function donationAddress() public view returns(address) {
    return donationAddress_;
  }
}