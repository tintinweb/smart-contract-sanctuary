pragma solidity ^0.4.0;
contract theCyberGatekeeper {
  function enter(bytes32 _passcode, bytes8 _gateKey) public {}
}

contract GateProxy {
    function enter(bytes32 _passcode, bytes8 _gateKey, uint16 _gas) public {
        theCyberGatekeeper(0x44919b8026f38D70437A8eB3BE47B06aB1c3E4Bf).enter.gas(_gas)(_passcode, _gateKey);
    }
}