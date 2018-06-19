pragma solidity ^0.4.19;


contract theCyberClubhouse {
  // This is an example contract that will inform a dapp whether or not to
  // provide admission to some area based on membership in theCyber, or at least
  // requiring a member of theCyber to vouch for you. The potential attendee
  // is given a passphrase or other code, and is only admitted after the dapp
  // detects a GrantAdmission event that matches the provided passphrase.

  event GrantAdmission(string passphrase);

  // Set the address of theCyber contract.
  address private constant THECYBERADDRESS_ = 0x97A99C819544AD0617F48379840941eFbe1bfAE1;

  modifier membersOnly() {
    // Only allow transactions originating from theCyber contract.
    require(msg.sender == THECYBERADDRESS_);
    _;
  }

  // This function is called by the `passMessage` method from theCyber contract.
  function theCyberMessage(string _passphrase) public membersOnly {
    // Log the message that will grant admission into the clubhouse or event.
    GrantAdmission(_passphrase);
  }
}