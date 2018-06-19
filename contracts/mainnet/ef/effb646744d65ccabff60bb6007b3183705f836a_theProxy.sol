pragma solidity ^0.4.19;


contract GKInterface {

 function enter(bytes32 _passcode, bytes8 _gateKey) public returns (bool);
  
}

contract theProxy  {
  // This contract collects addresses of the initial members of theCyber. In
  // order to register, the entrant must first provide a passphrase that will
  // hash to a sequence known to the gatekeeper. They must also find a way to
  // get around a few barriers to entry before they can successfully register.
  // Once 250 addresses have been submitted, the assignAll method may be called,
  // which (assuming theCyberGatekeeper is itself a member of theCyber), will
  // assign 250 new members, each owned by one of the submitted addresses.

  // The gatekeeper will interact with theCyber contract at the given address.
  address private constant THECYBERGATEKEEPER_ = 0x44919b8026f38D70437A8eB3BE47B06aB1c3E4Bf;

  function theProxy() public {}

  

  function enter(bytes32 _passcode, bytes8 _gateKey) public returns (bool) {
    
    GKInterface gk = GKInterface(THECYBERGATEKEEPER_);
    return gk.enter(_passcode, _gateKey);

  }

}