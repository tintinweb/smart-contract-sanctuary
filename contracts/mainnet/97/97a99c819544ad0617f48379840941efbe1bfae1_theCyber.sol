pragma solidity ^0.4.19;


contract SupportedContract {
  // Members can call any contract that exposes a `theCyberMessage` method.
  function theCyberMessage(string) public;
}


contract ERC20 {
  // We want to be able to recover & donate any tokens sent to the contract.
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
}


contract theCyber {
  // theCyber is a decentralized club. It does not support equity memberships,
  // payment of dues, or payouts to the members. Instead, it is meant to enable
  // dapps that allow members to communicate with one another or that provide
  // arbitrary incentives or special access to the club&#39;s members. To become a
  // member of theCyber, you must be added by an existing member. Furthermore,
  // existing memberships can be revoked if a given member becomes inactive for
  // too long. Total membership is capped and unique addresses are required.

  event NewMember(uint8 indexed memberId, bytes32 memberName, address indexed memberAddress);
  event NewMemberName(uint8 indexed memberId, bytes32 newMemberName);
  event NewMemberKey(uint8 indexed memberId, string newMemberKey);
  event MembershipTransferred(uint8 indexed memberId, address newMemberAddress);
  event MemberProclaimedInactive(uint8 indexed memberId, uint8 indexed proclaimingMemberId);
  event MemberHeartbeated(uint8 indexed memberId);
  event MembershipRevoked(uint8 indexed memberId, uint8 indexed revokingMemberId);
  event BroadcastMessage(uint8 indexed memberId, string message);
  event DirectMessage(uint8 indexed memberId, uint8 indexed toMemberId, string message);
  event Call(uint8 indexed memberId, address indexed contractAddress, string message);
  event FundsDonated(uint8 indexed memberId, uint256 value);
  event TokensDonated(uint8 indexed memberId, address tokenContractAddress, uint256 value);

  // There can only be 256 members (member number 0 to 255) in theCyber.
  uint16 private constant MAXMEMBERS_ = 256;

  // A membership that has been marked as inactive for 90 days may be revoked.
  uint64 private constant INACTIVITYTIMEOUT_ = 90 days;

  // Set the ethereum tip jar (ethereumfoundation.eth) as the donation address.
  address private constant DONATIONADDRESS_ = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;

  // A member has a name, a public key, a date they joined, and a date they were
  // marked as inactive (which is equial to 0 if they are currently active).
  struct Member {
    bool member;
    bytes32 name;
    string pubkey;
    uint64 memberSince;
    uint64 inactiveSince;
  }

  // Set up a fixed array of members indexed by member id.
  Member[MAXMEMBERS_] internal members_;

  // Map addresses to booleans designating that they control the membership.
  mapping (address => bool) internal addressIsMember_;

  // Map addresses to member ids.
  mapping (address => uint8) internal addressToMember_;

  // Map member ids to addresses that own the membership.
  mapping (uint => address) internal memberToAddress_;

  // Most methods of the contract, like adding new members or revoking existing
  // inactive members, can only be called by a valid member.
  modifier membersOnly() {
    // Only allow transactions originating from a designated member address.
    require(addressIsMember_[msg.sender]);
    _;
  }

  // In the constructor function, set up the contract creator as the first
  // member so that other new members can be added.
  function theCyber() public {
    // Log the addition of the first member (contract creator).
    NewMember(0, "", msg.sender);

    // Set up the member: status, name, key, member since & inactive since.
    members_[0] = Member(true, bytes32(""), "", uint64(now), 0);
    
    // Set up the address associated with the member.
    memberToAddress_[0] = msg.sender;

    // Point the address to member&#39;s id.
    addressToMember_[msg.sender] = 0;

    // Grant members-only access to the new member.
    addressIsMember_[msg.sender] = true;
  }

  // Existing members can designate new users by specifying an unused member id
  // and address. The new member&#39;s initial member name should also be supplied.
  function newMember(uint8 _memberId, bytes32 _memberName, address _memberAddress) public membersOnly {
    // Members need a non-null address.
    require(_memberAddress != address(0));

    // Existing members (that have not fallen inactive) cannot be replaced.
    require (!members_[_memberId].member);

    // One address cannot hold more than one membership.
    require (!addressIsMember_[_memberAddress]);

    // Log the addition of a new member: (member id, name, address).
    NewMember(_memberId, _memberName, _memberAddress);

    // Set up the member: status, name, `member since` & `inactive since`.
    members_[_memberId] = Member(true, _memberName, "", uint64(now), 0);
    
    // Set up the address associated with the member id.
    memberToAddress_[_memberId] = _memberAddress;

    // Point the address to the member id.
    addressToMember_[_memberAddress] = _memberId;

    // Grant members-only access to the new member.
    addressIsMember_[_memberAddress] = true;
  }

  // Members can set a name (encoded as a hex value) that will be associated
  // with their membership.
  function changeName(bytes32 _newMemberName) public membersOnly {
    // Log the member&#39;s name change: (member id, new name).
    NewMemberName(addressToMember_[msg.sender], _newMemberName);

    // Change the member&#39;s name.
    members_[addressToMember_[msg.sender]].name = _newMemberName;
  }

  // Members can set a public key that will be used for verifying signed
  // messages from the member or encrypting messages intended for the member.
  function changeKey(string _newMemberKey) public membersOnly {
    // Log the member&#39;s key change: (member id, new member key).
    NewMemberKey(addressToMember_[msg.sender], _newMemberKey);

    // Change the member&#39;s public key.
    members_[addressToMember_[msg.sender]].pubkey = _newMemberKey;
  }

  // Members can transfer their membership to a new address; when they do, the
  // fields on the membership are all reset.
  function transferMembership(address _newMemberAddress) public membersOnly {
    // Members need a non-null address.
    require(_newMemberAddress != address(0));

    // Memberships cannot be transferred to existing members.
    require (!addressIsMember_[_newMemberAddress]);

    // Log transfer of membership: (member id, new address).
    MembershipTransferred(addressToMember_[msg.sender], _newMemberAddress);
    
    // Revoke members-only access for the old member.
    delete addressIsMember_[msg.sender];
    
    // Reset fields on the membership.
    members_[addressToMember_[msg.sender]].memberSince = uint64(now);
    members_[addressToMember_[msg.sender]].inactiveSince = 0;
    members_[addressToMember_[msg.sender]].name = bytes32("");
    members_[addressToMember_[msg.sender]].pubkey = "";
    
    // Replace the address associated with the member id.
    memberToAddress_[addressToMember_[msg.sender]] = _newMemberAddress;

    // Point the new address to the member id and clean up the old pointer.
    addressToMember_[_newMemberAddress] = addressToMember_[msg.sender];
    delete addressToMember_[msg.sender];

    // Grant members-only access to the new member.
    addressIsMember_[_newMemberAddress] = true;
  }

  // As a mechanism to remove members that are no longer active due to lost keys
  // or a lack of engagement, other members may proclaim them as inactive.
  function proclaimInactive(uint8 _memberId) public membersOnly {
    // Members must exist and be currently active to proclaim inactivity.
    require(members_[_memberId].member);
    require(memberIsActive(_memberId));
    
    // Members cannot proclaim themselves as inactive (safety measure).
    require(addressToMember_[msg.sender] != _memberId);

    // Log proclamation of inactivity: (inactive member id, member id, time).
    MemberProclaimedInactive(_memberId, addressToMember_[msg.sender]);
    
    // Set the `inactiveSince` field on the inactive member.
    members_[_memberId].inactiveSince = uint64(now);
  }

  // Members that have erroneously been marked as inactive may send a heartbeat
  // to prove that they are still active, voiding the `inactiveSince` property.
  function heartbeat() public membersOnly {
    // Log that the member has heartbeated and is still active.
    MemberHeartbeated(addressToMember_[msg.sender]);

    // Designate member as active by voiding their `inactiveSince` field.
    members_[addressToMember_[msg.sender]].inactiveSince = 0;
  }

  // If a member has been marked inactive for the duration of the inactivity
  // timeout, another member may revoke their membership and delete them.
  function revokeMembership(uint8 _memberId) public membersOnly {
    // Members must exist in order to be revoked.
    require(members_[_memberId].member);

    // Members must be designated as inactive.
    require(!memberIsActive(_memberId));

    // Members cannot revoke themselves (safety measure).
    require(addressToMember_[msg.sender] != _memberId);

    // Members must be inactive for the duration of the inactivity timeout.
    require(now >= members_[_memberId].inactiveSince + INACTIVITYTIMEOUT_);

    // Log that the membership has been revoked.
    MembershipRevoked(_memberId, addressToMember_[msg.sender]);

    // Revoke members-only access for the member.
    delete addressIsMember_[memberToAddress_[_memberId]];

    // Delete the pointer linking the address to the member id.
    delete addressToMember_[memberToAddress_[_memberId]];
    
    // Delete the address associated with the member id.
    delete memberToAddress_[_memberId];

    // Finally, delete the member.
    delete members_[_memberId];
  }

  // While most messaging is intended to occur off-chain using supplied keys,
  // members can also broadcast a message as an on-chain event.
  function broadcastMessage(string _message) public membersOnly {
    // Log the message.
    BroadcastMessage(addressToMember_[msg.sender], _message);
  }

  // In addition, members can send direct messagees as an on-chain event. These
  // messages are intended to be encrypted using the recipient&#39;s public key.
  function directMessage(uint8 _toMemberId, string _message) public membersOnly {
    // Log the message.
    DirectMessage(addressToMember_[msg.sender], _toMemberId, _message);
  }

  // Members can also pass a message to any contract that supports it (via the
  // `theCyberMessage(string)` function), designated by the contract address.
  function passMessage(address _contractAddress, string _message) public membersOnly {
    // Log that another contract has been called and passed a message.
    Call(addressToMember_[msg.sender], _contractAddress, _message);

    // call the method of the target contract and pass in the message.
    SupportedContract(_contractAddress).theCyberMessage(_message);
  }

  // The contract is not payable by design, but could end up with a balance as
  // a recipient of a selfdestruct / coinbase of a mined block.
  function donateFunds() public membersOnly {
    // Log the donation of any funds that have made their way into the contract.
    FundsDonated(addressToMember_[msg.sender], this.balance);

    // Send all available funds to the donation address.
    DONATIONADDRESS_.transfer(this.balance);
  }

  // We also want to be able to access any tokens that are sent to the contract.
  function donateTokens(address _tokenContractAddress) public membersOnly {
    // Make sure that we didn&#39;t pass in the current contract address by mistake.
    require(_tokenContractAddress != address(this));

    // Log the donation of any tokens that have been sent into the contract.
    TokensDonated(addressToMember_[msg.sender], _tokenContractAddress, ERC20(_tokenContractAddress).balanceOf(this));

    // Send all available tokens at the given contract to the donation address.
    ERC20(_tokenContractAddress).transfer(DONATIONADDRESS_, ERC20(_tokenContractAddress).balanceOf(this));
  }

  function getMembershipStatus(address _memberAddress) public view returns (bool member, uint8 memberId) {
    return (
      addressIsMember_[_memberAddress],
      addressToMember_[_memberAddress]
    );
  }

  function getMemberInformation(uint8 _memberId) public view returns (bytes32 memberName, string memberKey, uint64 memberSince, uint64 inactiveSince, address memberAddress) {
    return (
      members_[_memberId].name,
      members_[_memberId].pubkey,
      members_[_memberId].memberSince,
      members_[_memberId].inactiveSince,
      memberToAddress_[_memberId]
    );
  }

  function maxMembers() public pure returns(uint16) {
    return MAXMEMBERS_;
  }

  function inactivityTimeout() public pure returns(uint64) {
    return INACTIVITYTIMEOUT_;
  }

  function donationAddress() public pure returns(address) {
    return DONATIONADDRESS_;
  }

  function memberIsActive(uint8 _memberId) internal view returns (bool) {
    return (members_[_memberId].inactiveSince == 0);
  }
}